"""
load_mp.py
Loaders para datos del Ministerio Publico (MP), anno 2023.
Agrega eventos por anno + departamento + delito + sexo e inserta
en justicia.estadistica_seguridad.

Fuentes:
    MP/2023/Agraviados.csv  — personas agraviadas (victimas de denuncia)
    MP/2023/Sincidados.csv  — sindicados en denuncias del MP
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pandas as pd
from config_justicia import (
    CSV_MP,
    SEXO_MAP,
    MP_AGRAVIADOS_FALLBACK,
    MP_SINCIDADOS_FALLBACK,
    FUENTE_MP_AGR, FUENTE_MP_SIN,
)
from utils import (
    get_logger, get_connection, get_tipo_delito_id,
    get_departamento_id, bulk_upsert_estadisticas, print_summary,
)


def _cargar_csv_mp(archivo: Path) -> pd.DataFrame:
    """Lee un CSV del MP sin filas de cabecera extra."""
    return pd.read_csv(archivo, skipinitialspace=True, encoding="utf-8", low_memory=False)


def _agregar_y_cargar(conn, df: pd.DataFrame, col_anio: str, col_depto: str,
                      col_delito: str, col_sexo: str,
                      fallback_codigo: str,
                      fuente: str, archivo_nombre: str,
                      loader_name: str, logger) -> tuple[int, int]:
    """
    Agrupa el DataFrame por anio/depto/delito/sexo y carga a estadistica_seguridad.
    En V1 todos los delitos del MP usan el codigo fallback (un codigo por fuente).
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

    # Cache de tipo_delito_id para el codigo fallback (evita query repetida)
    try:
        tipo_delito_id = get_tipo_delito_id(conn, fallback_codigo)
    except ValueError as e:
        logger.error(str(e))
        return 0, 0

    for _, row in grouped.iterrows():
        anio      = int(row[col_anio])
        depto_nom = str(row[col_depto]).strip()
        sexo_nom  = str(row[col_sexo]).strip()
        cantidad  = int(row["cantidad"])

        departamento_id = get_departamento_id(conn, depto_nom)
        if departamento_id is None:
            errors.append(f"Departamento no mapeado: '{depto_nom}'")
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


# -- LOADER: MP Agraviados ----------------------------------------------------

def load_agraviados(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_mp_agraviados")
    archivo = archivo or CSV_MP["agraviados"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = _cargar_csv_mp(archivo)
    close_conn = conn is None
    if conn is None:
        conn = get_connection()

    ins, upd = _agregar_y_cargar(
        conn, df,
        col_anio="año_ocu", col_depto="depto_ocu",
        col_delito="g_delitos", col_sexo="sexo_per",
        fallback_codigo=MP_AGRAVIADOS_FALLBACK,
        fuente=FUENTE_MP_AGR, archivo_nombre=archivo.name,
        loader_name="load_mp_agraviados", logger=logger,
    )
    if close_conn:
        conn.close()
    return ins, upd


# -- LOADER: MP Sindicados ----------------------------------------------------

def load_sincidados(conn=None, archivo: Path = None) -> tuple[int, int]:
    logger  = get_logger("load_mp_sincidados")
    archivo = archivo or CSV_MP["sincidados"]

    logger.info(f"Leyendo: {archivo.name}")
    if not archivo.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {archivo}")

    df = _cargar_csv_mp(archivo)
    close_conn = conn is None
    if conn is None:
        conn = get_connection()

    ins, upd = _agregar_y_cargar(
        conn, df,
        col_anio="año_denuncia", col_depto="depto_ocu_hecho",
        col_delito="principales_delitos", col_sexo="sexo_per",
        fallback_codigo=MP_SINCIDADOS_FALLBACK,
        fuente=FUENTE_MP_SIN, archivo_nombre=archivo.name,
        loader_name="load_mp_sincidados", logger=logger,
    )
    if close_conn:
        conn.close()
    return ins, upd


if __name__ == "__main__":
    load_agraviados()
    load_sincidados()
