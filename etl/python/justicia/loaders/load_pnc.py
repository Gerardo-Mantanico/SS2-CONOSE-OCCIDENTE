"""
load_pnc.py
Loaders para datos de la Policia Nacional Civil (PNC), anno 2023.
Agrega eventos por anno + departamento + categoria + sexo e inserta
en justicia.estadistica_seguridad.

Fuentes:
    PNC/2023/Victimas.csv   — personas reportadas como victimas
    PNC/2023/Detenidos.csv  — personas detenidas
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pandas as pd
from config_justicia import (
    CSV_PNC,
    SEXO_MAP,
    PNC_VICTIMAS_MAP, PNC_VICTIMAS_FALLBACK,
    PNC_DETENIDOS_MAP, PNC_DETENIDOS_FALLBACK,
    FUENTE_PNC_VIC, FUENTE_PNC_DET,
)
from utils import (
    get_logger, get_connection, get_tipo_delito_id,
    get_departamento_id, bulk_upsert_estadisticas, print_summary,
)


def _cargar_csv_pnc(archivo: Path) -> pd.DataFrame:
    """Lee un CSV de PNC sin filas de cabecera extra."""
    return pd.read_csv(archivo, skipinitialspace=True, encoding="utf-8", low_memory=False)


def _agregar_y_cargar(conn, df: pd.DataFrame, col_anio: str, col_depto: str,
                      col_delito: str, col_sexo: str,
                      delito_map: dict, fallback_codigo: str,
                      fuente: str, archivo_nombre: str,
                      loader_name: str, logger) -> tuple[int, int]:
    """
    Agrupa el DataFrame por anio/depto/delito/sexo, hace los lookups
    necesarios y llama a bulk_upsert_estadisticas.
    """
    rows   = []
    errors = []

    grouped = (
        df[[col_anio, col_depto, col_delito, col_sexo]]
        .fillna("Ignorado")
        .groupby([col_anio, col_depto, col_delito, col_sexo], dropna=False)
        .size()
        .reset_index(name="cantidad")
    )

    for _, row in grouped.iterrows():
        anio       = int(row[col_anio])
        depto_nom  = str(row[col_depto]).strip()
        g_delito   = str(row[col_delito]).strip()
        sexo_nom   = str(row[col_sexo]).strip()
        cantidad   = int(row["cantidad"])

        departamento_id = get_departamento_id(conn, depto_nom)
        if departamento_id is None:
            errors.append(f"Departamento no mapeado: '{depto_nom}'")
            continue

        codigo = delito_map.get(g_delito, fallback_codigo)
        try:
            tipo_delito_id = get_tipo_delito_id(conn, codigo)
        except ValueError as e:
            errors.append(str(e))
            continue

        sexo_id = SEXO_MAP.get(sexo_nom)

        rows.append({
            "anio":                anio,
            "departamento_id":     departamento_id,
            "nombre_departamento": depto_nom,
            "tipo_delito_id":      tipo_delito_id,
            "sexo_id":             sexo_id,
            "grupo_edad_id":       None,
            "cantidad":            cantidad,
            "fuente":              fuente,
            "archivo_origen":      archivo_nombre,
            "cargado_por":         f"ETL {loader_name}",
        })

    ins, upd = bulk_upsert_estadisticas(conn, rows, logger)
    print_summary(logger, loader_name, len(rows), errors)
    return ins, upd


# -- LOADER: PNC Victimas -----------------------------------------------------

def load_victimas(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_pnc_victimas")
    archivo = archivo or CSV_PNC["victimas"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = _cargar_csv_pnc(archivo)
    close_conn = conn is None
    if conn is None:
        conn = get_connection()

    ins, upd = _agregar_y_cargar(
        conn, df,
        col_anio="año_ocu", col_depto="depto_ocu",
        col_delito="g_delitos", col_sexo="sexo_per",
        delito_map=PNC_VICTIMAS_MAP, fallback_codigo=PNC_VICTIMAS_FALLBACK,
        fuente=FUENTE_PNC_VIC, archivo_nombre=archivo.name,
        loader_name="load_pnc_victimas", logger=logger,
    )
    if close_conn:
        conn.close()
    return ins, upd


# -- LOADER: PNC Detenidos ----------------------------------------------------

def load_detenidos(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_pnc_detenidos")
    archivo = archivo or CSV_PNC["detenidos"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = _cargar_csv_pnc(archivo)
    close_conn = conn is None
    if conn is None:
        conn = get_connection()

    ins, upd = _agregar_y_cargar(
        conn, df,
        col_anio="año_ocu", col_depto="depto_ocu",
        col_delito="g_delitos", col_sexo="sexo_per",
        delito_map=PNC_DETENIDOS_MAP, fallback_codigo=PNC_DETENIDOS_FALLBACK,
        fuente=FUENTE_PNC_DET, archivo_nombre=archivo.name,
        loader_name="load_pnc_detenidos", logger=logger,
    )
    if close_conn:
        conn.close()
    return ins, upd


if __name__ == "__main__":
    load_victimas()
    load_detenidos()
