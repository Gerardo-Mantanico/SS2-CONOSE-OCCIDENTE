#!/usr/bin/env python3
"""
Configuración y utilidades compartidas del ETL — BD Nacional.

Expone:
  - get_connection(): conexión psycopg2 lista para usar.
  - registrar_carga(...): context manager que registra la ejecución del ETL en
    meta.carga y entrega el carga_id para estampar en las tablas de dominio.

Uso típico en un script ETL:

    from config import registrar_carga

    def main():
        with registrar_carga("INE_CENSO_2018", archivo="data/censo.csv") as carga:
            carga.cur.execute(
                "INSERT INTO demografia.persona (nombre, carga_id) VALUES (%s, %s)",
                ("Juan", carga.id),
            )
            carga.filas_insertadas += carga.cur.rowcount

    if __name__ == "__main__":
        main()

Al salir del bloque:
  - sin error  -> marca la carga 'exitosa' (o 'parcial' si filas_rechazadas > 0)
  - con error  -> marca la carga 'fallida', guarda el error y re-lanza
En ambos casos la fila de meta.carga queda registrada: se hace commit del
registro 'en_proceso' al inicio, así un crash siempre deja rastro.
"""

from __future__ import annotations

import getpass
import os
import sys
from contextlib import contextmanager
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


# --- Carga de .env ------------------------------------------------------------
def _cargar_env() -> None:
    """Busca el .env subiendo desde este archivo hasta la raíz del repo."""
    for parent in Path(__file__).resolve().parents:
        env = parent / ".env"
        if env.exists():
            load_dotenv(env)
            return
    load_dotenv()  # si no se encuentra, confía en el entorno ya presente


_cargar_env()


# --- Conexión -----------------------------------------------------------------
def get_connection():
    """
    Retorna una conexión psycopg2. Usa DATABASE_URL si está definida; si no,
    la arma a partir de las variables DB_*.
    """
    dsn = os.environ.get("DATABASE_URL")
    if dsn:
        conn = psycopg2.connect(dsn)
    else:
        conn = psycopg2.connect(
            host=os.environ.get("DB_HOST", "localhost"),
            port=os.environ.get("DB_PORT", "5432"),
            dbname=os.environ.get("DB_NAME", "bd_nacional"),
            user=os.environ.get("DB_USER", "postgres"),
            password=os.environ.get("DB_PASSWORD", ""),
        )
    # Datos en español: garantizamos UTF-8 sin depender del locale del sistema.
    conn.set_client_encoding("UTF8")
    return conn


# --- Registro de cargas -------------------------------------------------------
class FuenteNoEncontrada(Exception):
    """El código de fuente no existe en meta.fuente."""


class Carga:
    """Estado de una carga en curso: expone el carga_id, el cursor y contadores."""

    def __init__(self, conn, cur, carga_id: int):
        self.conn = conn
        self.cur = cur
        self.id = carga_id
        self.filas_procesadas = 0
        self.filas_insertadas = 0
        self.filas_actualizadas = 0
        self.filas_rechazadas = 0
        self.notas: str | None = None


def _estado_id(cur, nombre: str) -> int:
    cur.execute("SELECT id FROM meta.estado_carga WHERE nombre = %s", (nombre,))
    row = cur.fetchone()
    if row is None:
        raise RuntimeError(
            f"Falta el estado '{nombre}' en meta.estado_carga. "
            "¿se han ejecutado las migraciones de meta?"
        )
    return row[0]


def _nombre_script_por_defecto() -> str:
    """Deriva 'modulo/archivo.py' del script en ejecución."""
    p = Path(sys.argv[0]).resolve()
    return f"{p.parent.name}/{p.name}" if p.name else "desconocido"


def _actualizar_carga(cur, carga: "Carga", estado_id: int) -> None:
    cur.execute(
        """
        UPDATE meta.carga
           SET estado_carga_id    = %s,
               finalizado_en      = now(),
               filas_procesadas   = %s,
               filas_insertadas   = %s,
               filas_actualizadas = %s,
               filas_rechazadas   = %s,
               notas              = %s
         WHERE id = %s
        """,
        (
            estado_id,
            carga.filas_procesadas,
            carga.filas_insertadas,
            carga.filas_actualizadas,
            carga.filas_rechazadas,
            carga.notas,
            carga.id,
        ),
    )


@contextmanager
def registrar_carga(
    codigo_fuente: str,
    *,
    nombre_script: str | None = None,
    archivo: str | None = None,
    hash_archivo: str | None = None,
    ejecutado_por: str | None = None,
):
    """
    Registra una ejecución de ETL en meta.carga y entrega un objeto Carga.

    Falla con FuenteNoEncontrada si `codigo_fuente` no existe: el catálogo de
    fuentes se mantiene curado en data/fuentes.csv (ver el seed en
    etl/python/meta/..._load_fuentes.py), no se crea al vuelo.

    El objeto Carga expone:
      - .id                 -> carga_id, para estampar en las filas de dominio
      - .cur                -> cursor sobre la misma conexión
      - .filas_insertadas / .filas_actualizadas / .filas_rechazadas / .notas
    """
    conn = get_connection()
    cur = conn.cursor()

    # 1) Resolver la fuente. Falla si no existe.
    cur.execute("SELECT id FROM meta.fuente WHERE codigo = %s", (codigo_fuente,))
    row = cur.fetchone()
    if row is None:
        conn.close()
        raise FuenteNoEncontrada(
            f"La fuente '{codigo_fuente}' no existe en meta.fuente. "
            "Agrégala a data/fuentes.csv y corre el seed de fuentes."
        )
    fuente_id = row[0]

    # 2) Insertar la carga en 'en_proceso' y hacer commit para dejar rastro
    #    aunque el proceso se caiga a mitad de camino.
    cur.execute(
        """
        INSERT INTO meta.carga
            (fuente_id, estado_carga_id, nombre_script,
             archivo_fuente, hash_archivo, ejecutado_por)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING id
        """,
        (
            fuente_id,
            _estado_id(cur, "en_proceso"),
            nombre_script or _nombre_script_por_defecto(),
            archivo,
            hash_archivo,
            ejecutado_por or getpass.getuser(),
        ),
    )
    carga = Carga(conn, cur, cur.fetchone()[0])
    conn.commit()

    try:
        yield carga

    except BaseException as exc:
        # Descarta los datos a medias; conserva el registro de la carga fallida.
        conn.rollback()
        carga.notas = (carga.notas + "\n" if carga.notas else "") + f"ERROR: {exc}"
        _actualizar_carga(cur, carga, _estado_id(cur, "fallida"))
        conn.commit()
        raise

    else:
        # Commit conjunto de los datos de dominio + el cierre de la carga.
        nombre_estado = "parcial" if carga.filas_rechazadas > 0 else "exitosa"
        _actualizar_carga(cur, carga, _estado_id(cur, nombre_estado))
        conn.commit()

    finally:
        cur.close()
        conn.close()
