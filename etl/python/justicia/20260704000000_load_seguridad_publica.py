"""
20260704000000_load_seguridad_publica.py
Orquestador del ETL de seguridad publica (modulo Justicia).
Descubierto automaticamente por run_all.py gracias al prefijo de timestamp.

Fuentes incluidas:
    INE  — estadisticas anuales 2009-2022 (robos por depto, sexo, edad, tipo)
    PNC  — datos de nivel evento 2023 (victimas y detenidos)
    MP   — datos de nivel evento 2023 (agraviados y sindicados)

Uso:
    python etl/python/justicia/20260704000000_load_seguridad_publica.py
    python etl/python/justicia/20260704000000_load_seguridad_publica.py --solo depto
    python etl/python/justicia/20260704000000_load_seguridad_publica.py --dry-run
"""
from __future__ import annotations

import argparse
import sys
import traceback
from datetime import datetime
from pathlib import Path

_JUSTICIA_DIR   = Path(__file__).resolve().parent
_ETL_PYTHON_DIR = _JUSTICIA_DIR.parent

sys.path.insert(0, str(_JUSTICIA_DIR))
sys.path.insert(0, str(_ETL_PYTHON_DIR))

from utils import get_logger, get_connection  # noqa: E402
from loaders.load_robos_departamento import load as load_depto         # noqa: E402
from loaders.load_robos_sexo import load as load_sexo                  # noqa: E402
from loaders.load_robos_edad_tipo import load_edad, load_tipo          # noqa: E402
from loaders.load_pnc import load_victimas, load_detenidos             # noqa: E402
from loaders.load_mp import load_agraviados, load_sincidados           # noqa: E402


LOADERS = {
    # INE — datos agregados anuales 2009-2022
    "depto":      ("INE - Robos por departamento",   load_depto),
    "sexo":       ("INE - Robos por sexo",           load_sexo),
    "edad":       ("INE - Robos por edad",           load_edad),
    "tipo":       ("INE - Robos por tipo de delito", load_tipo),
    # PNC — datos de nivel evento 2023
    "pnc_vic":    ("PNC 2023 - Victimas",            load_victimas),
    "pnc_det":    ("PNC 2023 - Detenidos",           load_detenidos),
    # MP — datos de nivel evento 2023
    "mp_agr":     ("MP 2023 - Agraviados",           load_agraviados),
    "mp_sin":     ("MP 2023 - Sindicados",           load_sincidados),
}



def main():
    parser = argparse.ArgumentParser(
        description="ETL Seguridad Publica — Modulo Justicia"
    )
    parser.add_argument(
        "--solo", choices=list(LOADERS.keys()),
        help="Ejecutar solo un loader especifico",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Valida archivos sin cargar datos a la BD",
    )
    args = parser.parse_args()

    logger = get_logger("etl_seguridad_publica")
    inicio = datetime.now()

    logger.info("=" * 65)
    logger.info("  ETL Modulo Justicia — Seguridad Publica (INE/PNC)")
    logger.info(f"  Inicio: {inicio.strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 65)

    if args.dry_run:
        logger.info("MODO DRY-RUN: solo se validan archivos, no se carga nada.")

    to_run = [args.solo] if args.solo else list(LOADERS.keys())
    resultados: dict[str, tuple] = {}
    conn = None

    try:
        if not args.dry_run:
            conn = get_connection()
            logger.info("Conexion a BD establecida.")

        for key in to_run:
            nombre, fn = LOADERS[key]
            logger.info(f"\n{'─'*55}")
            logger.info(f"  Ejecutando: {nombre}")
            logger.info(f"{'─'*55}")

            try:
                if args.dry_run:
                    resultados[key] = ("VALIDADO", 0, 0)
                else:
                    ins, upd = fn(conn=conn)
                    resultados[key] = ("OK", ins, upd)
            except FileNotFoundError as e:
                logger.error(f"Archivo no encontrado: {e}")
                resultados[key] = ("ERROR_ARCHIVO", 0, 0)
            except SystemExit:
                logger.error(f"{nombre} abortado por error de validacion.")
                resultados[key] = ("ERROR_VALIDACION", 0, 0)
            except Exception as e:
                logger.error(f"Error inesperado en {nombre}: {e}")
                logger.debug(traceback.format_exc())
                resultados[key] = ("ERROR", 0, 0)

    finally:
        if conn:
            conn.close()
            logger.info("Conexion a BD cerrada.")

    # -- Reporte final --------------------------------------------------------
    fin      = datetime.now()
    duracion = (fin - inicio).total_seconds()

    logger.info(f"\n{'='*65}")
    logger.info("  RESUMEN FINAL")
    logger.info(f"  Duracion: {duracion:.1f}s")
    logger.info(f"{'='*65}")

    errores_totales = 0
    for key, (estado, ins, upd) in resultados.items():
        nombre = LOADERS[key][0]
        logger.info(f"  {nombre:<35} {estado:<20} ins={ins} upd={upd}")
        if estado.startswith("ERROR"):
            errores_totales += 1

    logger.info("=" * 65)

    if errores_totales:
        logger.error(f"{errores_totales} loader(s) fallaron. Revisar logs.")
        sys.exit(1)


if __name__ == "__main__":
    main()
