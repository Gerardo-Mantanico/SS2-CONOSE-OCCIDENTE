"""
load_robos_edad_tipo.py
Loaders: robos por grupo de edad y por tipo de delito (2009-2022)
Fuente: INE/PNC
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pandas as pd
from config_justicia import CSV_INE, INE_HEADER_ROW, EDAD_MAP, TIPO_ROBO_MAP, FUENTE_INE
from utils import (
    get_logger, get_connection, get_tipo_delito_id,
    clean_int, clean_year, clean_numeric_df, bulk_upsert_estadisticas, print_summary,
)
from validators import validate_edad, validate_tipo

FUENTE = FUENTE_INE

# Mapa de nombre de grupo de edad -> codigo en BD
_CODIGO_EDAD = {
    "Menor de 15": "MENOR_15", "15-19":    "G15_19",  "20-24": "G20_24",
    "25-29":       "G25_29",   "30-34":    "G30_34",  "35-39": "G35_39",
    "40-44":       "G40_44",   "45-49":    "G45_49",  "50-54": "G50_54",
    "55-59":       "G55_59",   "60 y más": "G60_MAS", "Ignorado": "IGNORADO",
}


# -- LOADER: Robos por grupo de edad ------------------------------------------

def load_edad(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_robos_edad")
    archivo = archivo or CSV_INE["edad"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = pd.read_csv(archivo, header=INE_HEADER_ROW, skipinitialspace=True,
                     encoding="utf-8", dtype=str)
    df.columns = df.columns.astype(str).str.strip()
    df.rename(columns={df.columns[0]: "Año"}, inplace=True)
    df = df[pd.to_numeric(df["Año"], errors="coerce").notna()].copy()
    df["Año"] = df["Año"].apply(clean_year)

    # Normalizar columnas numericas (formato europeo + marcadores nulos)
    df = clean_numeric_df(df, [c for c in df.columns if c != "Año"])

    result = validate_edad(df)
    logger.info(result.resumen())
    if not result.es_valido:
        logger.error("Validacion fallida. Carga abortada.")
        sys.exit(1)

    close_conn = conn is None
    if conn is None:
        conn = get_connection()
    tipo_total_id = get_tipo_delito_id(conn, "TOTAL")

    rows      = []
    errors    = []
    cols_edad = [c for c in df.columns if c not in ["Año", "Total"]]

    for _, row in df.iterrows():
        anio = row["Año"]

        for col in cols_edad:
            nombre_grupo = col.strip()
            if nombre_grupo not in EDAD_MAP:
                errors.append(f"Año {anio}: grupo edad '{nombre_grupo}' no mapeado.")
                continue

            codigo = _CODIGO_EDAD.get(nombre_grupo)
            if not codigo:
                errors.append(f"Año {anio}: sin codigo para '{nombre_grupo}'")
                continue

            try:
                cantidad = clean_int(row[col])
            except ValueError as e:
                errors.append(f"Año {anio}, edad '{nombre_grupo}': {e}")
                continue

            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id FROM justicia.grupo_edad_victima WHERE codigo = %s",
                    (codigo,),
                )
                res = cur.fetchone()
            if not res:
                errors.append(f"justicia.grupo_edad_victima con codigo '{codigo}' no existe.")
                continue

            rows.append({
                "anio": anio, "departamento_id": None,
                "nombre_departamento": "República",
                "tipo_delito_id": tipo_total_id,
                "sexo_id": None, "grupo_edad_id": res[0],
                "cantidad": cantidad, "fuente": FUENTE,
                "archivo_origen": archivo.name,
                "cargado_por": "ETL load_robos_edad_tipo.py",
            })

    ins, upd = bulk_upsert_estadisticas(conn, rows, logger)
    if close_conn:
        conn.close()
    print_summary(logger, "Robos por edad", len(rows), errors)
    return ins, upd


# -- LOADER: Robos por tipo de delito -----------------------------------------

def load_tipo(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_robos_tipo")
    archivo = archivo or CSV_INE["tipo"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = pd.read_csv(archivo, header=INE_HEADER_ROW, skipinitialspace=True,
                     encoding="utf-8", dtype=str)
    df.columns = df.columns.astype(str).str.strip()
    df.rename(columns={df.columns[0]: "Año"}, inplace=True)
    df = df[pd.to_numeric(df["Año"], errors="coerce").notna()].copy()
    df["Año"] = df["Año"].apply(clean_year)

    # Normalizar columnas numericas (formato europeo + marcadores nulos)
    df = clean_numeric_df(df, [c for c in df.columns if c != "Año"])

    result = validate_tipo(df)
    logger.info(result.resumen())
    if not result.es_valido:
        logger.error("Validacion fallida. Carga abortada.")
        sys.exit(1)

    close_conn = conn is None
    if conn is None:
        conn = get_connection()

    rows      = []
    errors    = []
    cols_tipo = [c for c in df.columns if c not in ["Año", "Total"]]

    for _, row in df.iterrows():
        anio = row["Año"]

        for col in cols_tipo:
            nombre_tipo = col.strip()
            if nombre_tipo not in TIPO_ROBO_MAP:
                errors.append(f"Año {anio}: tipo '{nombre_tipo}' no mapeado.")
                continue

            try:
                tipo_id = get_tipo_delito_id(conn, TIPO_ROBO_MAP[nombre_tipo])
            except ValueError as e:
                errors.append(str(e))
                continue

            try:
                cantidad = clean_int(row[col])
            except ValueError as e:
                errors.append(f"Año {anio}, tipo '{nombre_tipo}': {e}")
                continue

            rows.append({
                "anio": anio, "departamento_id": None,
                "nombre_departamento": "República",
                "tipo_delito_id": tipo_id,
                "sexo_id": None, "grupo_edad_id": None,
                "cantidad": cantidad, "fuente": FUENTE,
                "archivo_origen": archivo.name,
                "cargado_por": "ETL load_robos_edad_tipo.py",
            })

    ins, upd = bulk_upsert_estadisticas(conn, rows, logger)
    if close_conn:
        conn.close()
    print_summary(logger, "Robos por tipo", len(rows), errors)
    return ins, upd


if __name__ == "__main__":
    load_edad()
    load_tipo()
