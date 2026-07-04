"""
load_robos_sexo.py
Loader: Numero de robos y hurtos por sexo de la victima (2009-2022)
Fuente: INE/PNC — robos_por_sexo.xlsx
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pandas as pd
from config_justicia import EXCEL_FILES, SHEET_NAME, HEADER_ROW, SEXO_MAP, FUENTE
from utils import (
    get_logger, get_connection, get_tipo_delito_id,
    clean_int, clean_year, bulk_upsert_estadisticas, print_summary,
)
from validators import validate_sexo


def load(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_robos_sexo")
    archivo = archivo or EXCEL_FILES["sexo"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    # -- 1. EXTRACCION --------------------------------------------------------
    df = pd.read_excel(archivo, sheet_name=SHEET_NAME, header=HEADER_ROW)
    df.columns = df.columns.astype(str).str.strip()
    df.rename(columns={df.columns[0]: "Año"}, inplace=True)
    df = df[pd.to_numeric(df["Año"], errors="coerce").notna()].copy()
    df["Año"] = df["Año"].apply(clean_year)

    # -- 2. VALIDACION --------------------------------------------------------
    result = validate_sexo(df)
    logger.info(result.resumen())
    if not result.es_valido:
        logger.error("Validacion fallida. Carga abortada.")
        sys.exit(1)

    # -- 3. TRANSFORMACION ----------------------------------------------------
    close_conn = conn is None
    if conn is None:
        conn = get_connection()
    tipo_total_id = get_tipo_delito_id(conn, "TOTAL")

    rows      = []
    errors    = []
    cols_sexo = [c for c in df.columns if c not in ["Año", "Total"]]

    for _, row in df.iterrows():
        anio = row["Año"]

        # Total nacional sin desagregacion
        try:
            total = clean_int(row.get("Total", 0))
            rows.append({
                "anio": anio, "departamento_id": None,
                "nombre_departamento": "República",
                "tipo_delito_id": tipo_total_id,
                "sexo_id": None, "grupo_edad_id": None,
                "cantidad": total, "fuente": FUENTE,
                "archivo_origen": archivo.name,
                "cargado_por": "ETL load_robos_sexo.py",
            })
        except ValueError as e:
            errors.append(f"Año {anio}, Total: {e}")

        # Registros por sexo
        for col in cols_sexo:
            nombre_sexo = col.strip()
            if nombre_sexo not in SEXO_MAP:
                errors.append(f"Año {anio}: sexo '{nombre_sexo}' no mapeado.")
                continue

            try:
                cantidad = clean_int(row[col])
            except ValueError as e:
                errors.append(f"Año {anio}, sexo '{nombre_sexo}': {e}")
                continue

            rows.append({
                "anio": anio, "departamento_id": None,
                "nombre_departamento": "República",
                "tipo_delito_id": tipo_total_id,
                "sexo_id": SEXO_MAP[nombre_sexo],
                "grupo_edad_id": None,
                "cantidad": cantidad, "fuente": FUENTE,
                "archivo_origen": archivo.name,
                "cargado_por": "ETL load_robos_sexo.py",
            })

    # -- 4. CARGA -------------------------------------------------------------
    ins, upd = bulk_upsert_estadisticas(conn, rows, logger)
    if close_conn:
        conn.close()

    print_summary(logger, "Robos por sexo", len(rows), errors)
    return ins, upd


if __name__ == "__main__":
    load()
