#!/usr/bin/env python3
"""
ETL de climatología del INSIVUMEH.

Lee una carpeta con:
  - estaciones.csv : catalogo de estaciones, con columnas:
                     Codigo, Nombre, Ubicacion, Latitud, Longitud.
  - un CSV por estación, cuyo NOMBRE DE ARCHIVO es el código de la estación
    (por ejemplo INS090101CV.csv). Cada uno trae la tabla de datos diarios, cuya fila de encabezado empieza con 'Fecha'.

Carga registros en las tablas:
  - clima.estacion (desde estaciones.csv)
  - clima.registro_climatico (mediciones diarias de cada archivo)

Ya que no todas las estaciones tienen todos los sensores, las columnas de medición que no aparezcan en un CSV quedan como NULL en la base.
Columnas desconocidas se ignoran.
Si un archivo de datos no tiene su estación en estaciones.csv, se crea una estación minima (solo el código) y se avisa.

Toda la corrida se registra como UNA sola carga en meta. El código de fuente se define en FUENTE_CODIGO.

Uso:
    python <script>.py --dir data/clima/insivumeh
    python <script>.py # usa CARPETA_POR_DEFECTO
"""

from __future__ import annotations

import argparse
import csv
import logging
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

for _p in Path(__file__).resolve().parents:
    if (_p / "config.py").exists():
        sys.path.insert(0, str(_p))
        break

from config import registrar_carga

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)-7s  %(message)s",
                    datefmt="%H:%M:%S")
log = logging.getLogger("etl.clima")


# Parámetros ---------------------------------------------

FUENTE_CODIGO = "INSIVUMEH_climatologia"
# Carpeta con los CSV, relativa a la raiz del repo.
CARPETA_POR_DEFECTO = "data/clima/insivumeh/2026-06"
# Nombre del catalogo de estaciones dentro de la carpeta.
ARCHIVO_ESTACIONES = "estaciones.csv"

# Mapeo de columnas de medición ------------------------
# clave: nombre de columna en el CSV -> valor: columna en la base.
COLUMNAS_MEDICION = {
    "lluvia": "lluvia",
    "temperatura_maxima": "temperatura_maxima",
    "temperatura_minima": "temperatura_minima",
    "temperatura_media": "temperatura_media",
    "evaporacion_tanque": "evaporacion_tanque",
    "humedad_relativa": "humedad_relativa",
    "brillo_solar": "brillo_solar",
    "nubosidad": "nubosidad",
    "velocidad_viento": "velocidad_viento",
    "direccion_viento": "direccion_viento",
    "presion_atmosferica": "presion_atmosferica",
    "temperatura_suelo_50cm": "temperatura_suelo_50cm",
    "temperatura_suelo_100cm": "temperatura_suelo_100cm",
    "radiacion": "radiacion",
}
DB_MEDICIONES = list(COLUMNAS_MEDICION.values())

# Sentencias SQL -----------------------------------------------------------
SQL_ESTACION = """
    INSERT INTO clima.estacion (codigo, nombre, ubicacion, latitud, longitud, carga_id)
    VALUES (%(codigo)s, %(nombre)s, %(ubicacion)s, %(latitud)s, %(longitud)s, %(carga_id)s)
    ON CONFLICT (codigo) DO UPDATE SET
        nombre = EXCLUDED.nombre, ubicacion = EXCLUDED.ubicacion,
        latitud = EXCLUDED.latitud, longitud = EXCLUDED.longitud,
        carga_id = EXCLUDED.carga_id
    RETURNING id
"""

_cols = ", ".join(DB_MEDICIONES)
_vals = ", ".join(f"%({c})s" for c in DB_MEDICIONES)
_set = ", ".join(f"{c} = EXCLUDED.{c}" for c in DB_MEDICIONES)
SQL_REGISTRO = f"""
    INSERT INTO clima.registro_climatico (estacion_id, fecha, {_cols}, carga_id)
    VALUES (%(estacion_id)s, %(fecha)s, {_vals}, %(carga_id)s)
    ON CONFLICT (estacion_id, fecha) DO UPDATE SET
        {_set}, carga_id = EXCLUDED.carga_id
"""


def _norm(s: str) -> str:
    """Normaliza un encabezado: sin tildes, minúsculas, espacios como '_'."""
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", "_", s.strip().lower())


def _num(v):
    """Convierte a float; None si esta vacío o no es numérico."""
    if v is None:
        return None
    v = str(v).strip().replace(",", ".")
    if v == "" or v.lower() in ("na", "nan", "null", "-", "s/d"):
        return None
    try:
        return float(v)
    except ValueError:
        return None


def _leer_filas(path: Path) -> list:
    """Lee un CSV como UTF-8 o, si falla, Windows-1252/Latin-1."""
    for enc in ("utf-8-sig", "cp1252"):
        try:
            with path.open(newline="", encoding=enc) as f:
                return list(csv.reader(f))
        except UnicodeDecodeError:
            continue
    with path.open(newline="", encoding="latin-1") as f:
        return list(csv.reader(f))
    return None


def _celda(fila, pos, clave):
    """Valor de una columna por nombre normalizado, o None."""
    i = pos.get(clave)
    if i is None or i >= len(fila):
        return None
    v = fila[i].strip()
    return v or None


def leer_catalogo(path: Path) -> dict:
    """Lee estaciones.csv y retorna {codigo: dict de la estacion}."""
    if not path.exists():
        raise FileNotFoundError(
            f"No se encontro el catalogo de estaciones: {path}. "
            f"Debe existir un '{ARCHIVO_ESTACIONES}' en la carpeta."
        )
    filas = _leer_filas(path)
    if not filas:
        return {}

    pos = {name: i for i, name in enumerate(_norm(c) for c in filas[0])}
    if "codigo" not in pos:
        raise ValueError(f"{path.name}: falta la columna 'Codigo'.")

    catalogo = {}
    for fila in filas[1:]:
        codigo = _celda(fila, pos, "codigo")
        if not codigo:
            continue
        catalogo[codigo] = {
            "codigo": codigo,
            "nombre": _celda(fila, pos, "nombre") or codigo,
            "ubicacion": _celda(fila, pos, "ubicacion"),
            "latitud": _num(_celda(fila, pos, "latitud")),
            "longitud": _num(_celda(fila, pos, "longitud")),
        }
    return catalogo


def leer_datos(path: Path):
    """Retorna (encabezado_normalizado, filas_de_datos) de un CSV de estación."""
    filas = _leer_filas(path)
    idx = next((i for i, fila in enumerate(filas)
                if fila and _norm(fila[0]) == "fecha"), None)
    if idx is None:
        raise ValueError(f"{path.name}: no se encontro la columna 'Fecha'.")
    return [_norm(c) for c in filas[idx]], filas[idx + 1:]


def _repo_root() -> Path:
    for parent in Path(__file__).resolve().parents:
        if (parent / ".env").exists() or (parent / "scripts").is_dir():
            return parent
    return Path.cwd()


# Proceso principal
def cargar_registros(carga, path: Path, estacion_id: int) -> None:
    encabezado, datos = leer_datos(path)
    pos = {name: i for i, name in enumerate(encabezado)}
    fecha_i = pos.get("fecha")
    med_pos = {db: pos[norm] for norm, db in COLUMNAS_MEDICION.items() if norm in pos}

    ok = rechazadas = 0
    for fila in datos:
        if not fila or fecha_i is None or fecha_i >= len(fila):
            continue
        crudo = fila[fecha_i].strip()
        if not crudo:
            continue
        try:
            fecha = datetime.strptime(crudo, "%Y-%m-%d").date()
        except ValueError:
            rechazadas += 1
            continue

        valores = {db: None for db in DB_MEDICIONES}
        for db, i in med_pos.items():
            if i < len(fila):
                valores[db] = _num(fila[i])

        carga.cur.execute(SQL_REGISTRO,
                          {"estacion_id": estacion_id, "fecha": fecha,
                           "carga_id": carga.id, **valores})
        ok += 1

    carga.filas_insertadas += ok
    carga.filas_rechazadas += rechazadas
    faltantes = sorted(set(COLUMNAS_MEDICION.values()) - set(med_pos))
    log.info(f"  {path.name}: {ok} registros"
             + (f", {rechazadas} rechazados" if rechazadas else "")
             + (f", sin sensores: {', '.join(faltantes)}" if faltantes else ""))


def main() -> None:
    parser = argparse.ArgumentParser(description="Carga de climatologia INSIVUMEH.")
    parser.add_argument("--dir", type=Path, default=_repo_root() / CARPETA_POR_DEFECTO,
                        help=f"Carpeta con los CSV (def: {CARPETA_POR_DEFECTO}).")
    args = parser.parse_args()

    carpeta = args.dir.resolve()
    if not carpeta.is_dir():
        raise NotADirectoryError(f"No existe la carpeta: {carpeta}")

    catalogo = leer_catalogo(carpeta / ARCHIVO_ESTACIONES)

    # Archivos de datos: todos los .csv menos el catálogo.
    data_csvs = sorted(p for p in carpeta.glob("*.csv")
                       if p.name.lower() != ARCHIVO_ESTACIONES.lower())
    if not data_csvs:
        log.warning(f"No hay archivos de datos en {carpeta} (aparte de {ARCHIVO_ESTACIONES}).")
        return

    log.info(f"{len(catalogo)} estaciones en catalogo, {len(data_csvs)} archivo(s) de datos "
             f"en {carpeta} (fuente '{FUENTE_CODIGO}')")

    with registrar_carga(FUENTE_CODIGO, archivo=str(carpeta)) as carga:
        # 1. Upsert del catálogo de estaciones.
        ids = {}
        for est in catalogo.values():
            carga.cur.execute(SQL_ESTACION, {**est, "carga_id": carga.id})
            ids[est["codigo"]] = carga.cur.fetchone()[0]

        # 2. Registros: el codigo de estacion es el nombre del archivo.
        for path in data_csvs:
            codigo = path.stem
            if codigo not in ids:
                log.warning(f"  {path.name}: estacion '{codigo}' no esta en "
                            f"{ARCHIVO_ESTACIONES}; se crea con datos minimos.")
                carga.cur.execute(SQL_ESTACION,
                                  {"codigo": codigo, "nombre": codigo, "ubicacion": None,
                                   "latitud": None, "longitud": None, "carga_id": carga.id})
                ids[codigo] = carga.cur.fetchone()[0]
            cargar_registros(carga, path, ids[codigo])

    log.info(f"Listo: {carga.filas_insertadas} registros"
             + (f", {carga.filas_rechazadas} rechazados" if carga.filas_rechazadas else ""))


if __name__ == "__main__":
    main()
