"""
utils.py — Utilidades compartidas por los loaders del modulo Justicia.
Usa get_connection() del config.py central del proyecto.
"""
import logging
import sys
from datetime import datetime
from pathlib import Path

from psycopg2.extras import execute_values

# Agrega etl/python al path para importar el config central
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from config import get_connection  # noqa: E402

from config_justicia import LOGS_DIR, NULL_MARKERS  # noqa: E402


def get_logger(nombre: str) -> logging.Logger:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = LOGS_DIR / f"{nombre}_{timestamp}.log"

    logger = logging.getLogger(nombre)
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()

    fmt = logging.Formatter(
        "[%(asctime)s] %(levelname)-8s %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    logger.info(f"Log iniciado -> {log_file}")
    return logger


def clean_int(value) -> int:
    if value is None or str(value).strip() in NULL_MARKERS:
        return 0
    try:
        return int(float(str(value).replace(",", "").strip()))
    except (ValueError, TypeError):
        raise ValueError(f"No se pudo convertir a entero: {repr(value)}")


def clean_year(value) -> int:
    try:
        yr = int(float(str(value).strip()))
        if not (2000 <= yr <= 2100):
            raise ValueError(f"Año fuera de rango: {yr}")
        return yr
    except (ValueError, TypeError):
        raise ValueError(f"Valor de año invalido: {repr(value)}")


def normalize_str(value: str) -> str:
    return " ".join(str(value).strip().split())


def get_tipo_delito_id(conn, codigo: str) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id FROM justicia.tipo_delito WHERE codigo = %s", (codigo,)
        )
        row = cur.fetchone()
        if not row:
            raise ValueError(
                f"justicia.tipo_delito con codigo '{codigo}' no encontrado. "
                "Verifica que se ejecuto V20260704000001__seed_catalogos_seguridad.sql"
            )
        return row[0]


def get_sexo_id(conn, nombre: str):
    if not nombre:
        return None
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id FROM justicia.sexo WHERE LOWER(nombre) = LOWER(%s)", (nombre,)
        )
        row = cur.fetchone()
        return row[0] if row else None


def get_grupo_edad_id(conn, codigo: str):
    if not codigo:
        return None
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id FROM justicia.grupo_edad_victima WHERE codigo = %s", (codigo,)
        )
        row = cur.fetchone()
        return row[0] if row else None


def bulk_upsert_estadisticas(conn, rows: list[dict], logger: logging.Logger) -> tuple[int, int]:
    if not rows:
        logger.warning("No hay filas para insertar.")
        return 0, 0

    sql = """
        INSERT INTO justicia.estadistica_seguridad
            (anio, departamento_id, nombre_departamento,
             tipo_delito_id, sexo_id, grupo_edad_id,
             cantidad, fuente, archivo_origen, cargado_por)
        VALUES %s
        ON CONFLICT (anio, departamento_id, tipo_delito_id, sexo_id, grupo_edad_id)
        DO UPDATE SET
            cantidad       = EXCLUDED.cantidad,
            fuente         = EXCLUDED.fuente,
            archivo_origen = EXCLUDED.archivo_origen,
            fecha_carga    = CURRENT_TIMESTAMP,
            cargado_por    = EXCLUDED.cargado_por
        RETURNING (xmax = 0) AS inserted
    """

    values = [
        (
            r["anio"], r.get("departamento_id"), r.get("nombre_departamento"),
            r.get("tipo_delito_id"), r.get("sexo_id"), r.get("grupo_edad_id"),
            r["cantidad"], r.get("fuente", "INE/PNC"),
            r.get("archivo_origen", ""), r.get("cargado_por", "ETL"),
        )
        for r in rows
    ]

    with conn.cursor() as cur:
        execute_values(cur, sql, values, page_size=500)
        results = cur.fetchall()

    conn.commit()
    insertados   = sum(1 for r in results if r[0])
    actualizados = len(results) - insertados
    logger.info(f"  {insertados} registros insertados, {actualizados} actualizados.")
    return insertados, actualizados


def print_summary(logger, loader_name: str, total: int, errors: list[str]):
    logger.info("=" * 60)
    logger.info(f"RESUMEN - {loader_name}")
    logger.info(f"  Filas procesadas : {total}")
    logger.info(f"  Errores          : {len(errors)}")
    if errors:
        logger.warning("  Detalle de errores:")
        for e in errors[:20]:
            logger.warning(f"    - {e}")
        if len(errors) > 20:
            logger.warning(f"    ... y {len(errors) - 20} mas. Ver archivo .log")
    logger.info("=" * 60)
