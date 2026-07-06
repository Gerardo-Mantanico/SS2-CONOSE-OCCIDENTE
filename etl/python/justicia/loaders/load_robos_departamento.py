"""
load_robos_departamento.py
Loader: Numero de robos y hurtos por departamento (2009-2022)
Fuente: INE/PNC — robos_por_departamento.xlsx
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pandas as pd
from config_justicia import CSV_INE, INE_HEADER_ROW, DEPTO_MAP, FUENTE_INE
from utils import (
    get_logger, get_connection, get_tipo_delito_id,
    clean_int, clean_year, clean_numeric_df, bulk_upsert_estadisticas, print_summary,
)
from validators import validate_departamento

FUENTE = FUENTE_INE


def load(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_robos_depto")
    archivo = archivo or CSV_INE["departamento"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(
            f"Archivo no encontrado: {archivo}\n"
            "Coloca los CSV del INE en data/justicia/INE/"
        )

    # -- 1. EXTRACCION --------------------------------------------------------
    df = pd.read_csv(archivo, header=INE_HEADER_ROW, skipinitialspace=True,
                     encoding="utf-8", dtype=str)
    df.columns = df.columns.astype(str).str.strip()
    df.rename(columns={df.columns[0]: "Año"}, inplace=True)
    df = df[pd.to_numeric(df["Año"], errors="coerce").notna()].copy()
    df["Año"] = df["Año"].apply(clean_year)

    # Normalizar columnas numericas (formato europeo + marcadores nulos)
    df = clean_numeric_df(df, [c for c in df.columns if c != "Año"])

    # -- 2. VALIDACION --------------------------------------------------------
    result = validate_departamento(df, list(DEPTO_MAP.keys()))
    logger.info(result.resumen())
    if not result.es_valido:
        logger.error("Validacion fallida. Carga abortada.")
        sys.exit(1)

    # -- 3. TRANSFORMACION ----------------------------------------------------
    close_conn = conn is None
    if conn is None:
        conn = get_connection()
    tipo_total_id = get_tipo_delito_id(conn, "TOTAL")

    rows   = []
    errors = []

    for _, row in df.iterrows():
        anio = row["Año"]

        for col in df.columns[1:]:
            col_clean = col.strip()
            try:
                cantidad = clean_int(row[col])
            except ValueError as e:
                errors.append(f"Año {anio}, col '{col_clean}': {e}")
                continue

            if col_clean == "República":
                rows.append({
                    "anio": anio, "departamento_id": None,
                    "nombre_departamento": "República",
                    "tipo_delito_id": tipo_total_id,
                    "sexo_id": None, "grupo_edad_id": None,
                    "cantidad": cantidad, "fuente": FUENTE,
                    "archivo_origen": archivo.name,
                    "cargado_por": "ETL load_robos_departamento.py",
                })
            elif col_clean in DEPTO_MAP:
                rows.append({
                    "anio": anio,
                    "departamento_id": DEPTO_MAP[col_clean],
                    "nombre_departamento": col_clean,
                    "tipo_delito_id": tipo_total_id,
                    "sexo_id": None, "grupo_edad_id": None,
                    "cantidad": cantidad, "fuente": FUENTE,
                    "archivo_origen": archivo.name,
                    "cargado_por": "ETL load_robos_departamento.py",
                })
            else:
                errors.append(f"Año {anio}: columna '{col_clean}' no mapeada.")

    # -- 4. CARGA -------------------------------------------------------------
    ins, upd = bulk_upsert_estadisticas(conn, rows, logger)
    if close_conn:
        conn.close()

    print_summary(logger, "Robos por departamento", len(rows), errors)
    return ins, upd


if __name__ == "__main__":
    load()
