#!/usr/bin/env python3
"""
Seed del catálogo de fuentes (meta.fuente).

Lee data/fuentes.csv y hace UPSERT por 'codigo' (idempotente): puede correrse
las veces que se quiera; inserta las fuentes nuevas y actualiza las existentes.

No es un ETL de dominio: no se registra a sí mismo en meta.carga, solo mantiene
el catálogo. Debe correr ANTES que cualquier ETL de dominio, por eso lleva el
timestamp más bajo del módulo meta.

Ejecutable por su cuenta:
    python etl/python/meta/20260702000000_load_fuentes.py
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

# Permite importar config al correr el script directo, sin importar el CWD.
for _p in Path(__file__).resolve().parents:
    if (_p / "config.py").exists():
        sys.path.insert(0, str(_p))
        break

from config import get_connection


def _ruta_csv() -> Path:
    """Ubica data/fuentes.csv en la raíz del repo."""
    for parent in Path(__file__).resolve().parents:
        cand = parent / "data" / "fuentes.csv"
        if cand.exists():
            return cand
    raise FileNotFoundError("No se encontró data/fuentes.csv en la raíz del repo.")


def _bool(val: str | None):
    if val is None or val.strip() == "":
        return None
    return val.strip().lower() in ("1", "true", "t", "si", "sí", "yes", "y")


def main() -> None:
    csv_path = _ruta_csv()

    with get_connection() as conn:
        with conn.cursor() as cur:
            # Tipos de fuente válidos, para dar un error claro si el CSV trae uno malo.
            cur.execute("SELECT nombre FROM meta.tipo_fuente")
            tipos_validos = {r[0] for r in cur.fetchall()}

            n = 0
            with csv_path.open(encoding="utf-8") as f:
                for fila in csv.DictReader(f):
                    codigo = (fila.get("codigo") or "").strip()
                    if not codigo or codigo.startswith("#"):
                        continue  # ignora filas vacías o comentadas

                    tipo = (fila.get("tipo_fuente") or "").strip()
                    if tipo not in tipos_validos:
                        raise ValueError(
                            f"Fuente '{codigo}': tipo_fuente '{tipo}' inválido. "
                            f"Válidos: {sorted(tipos_validos)}"
                        )

                    cur.execute(
                        """
                        INSERT INTO meta.fuente
                            (codigo, tipo_fuente_id, nombre, institucion, url,
                             descripcion, licencia, activa)
                        VALUES (
                            %(codigo)s,
                            (SELECT id FROM meta.tipo_fuente WHERE nombre = %(tipo)s),
                            %(nombre)s, %(institucion)s, %(url)s,
                            %(descripcion)s, %(licencia)s, COALESCE(%(activa)s, TRUE)
                        )
                        ON CONFLICT (codigo) DO UPDATE SET
                            tipo_fuente_id = EXCLUDED.tipo_fuente_id,
                            nombre         = EXCLUDED.nombre,
                            institucion    = EXCLUDED.institucion,
                            url            = EXCLUDED.url,
                            descripcion    = EXCLUDED.descripcion,
                            licencia       = EXCLUDED.licencia,
                            activa         = EXCLUDED.activa
                        """,
                        {
                            "codigo": codigo,
                            "tipo": tipo,
                            "nombre": (fila.get("nombre") or "").strip(),
                            "institucion": (fila.get("institucion") or "").strip() or None,
                            "url": (fila.get("url") or "").strip() or None,
                            "descripcion": (fila.get("descripcion") or "").strip() or None,
                            "licencia": (fila.get("licencia") or "").strip() or None,
                            "activa": _bool(fila.get("activa")),
                        },
                    )
                    n += 1
        conn.commit()

    print(f"Fuentes procesadas: {n}  (desde {csv_path})")


if __name__ == "__main__":
    main()
