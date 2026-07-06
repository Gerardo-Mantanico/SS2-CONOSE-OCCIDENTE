"""
ETL BI para el módulo Turismo.

Este script no reemplaza Flyway.

Flujo esperado:
  1. Ejecutar migraciones Flyway.
  2. Cargar geografía con el ETL de geografía.
  3. Cargar catálogo de turismo.
  4. Ejecutar este script para:
     - cargar/refrescar dimensiones,
     - cargar/refrescar hechos,
     - ejecutar validaciones,
     - refrescar datamarts.

Uso:
  python etl/python/turismo/run_turismo_bi.py --full
  python etl/python/turismo/run_turismo_bi.py --refresh-marts
  python etl/python/turismo/run_turismo_bi.py --validate
  python etl/python/turismo/run_turismo_bi.py --check
"""

import argparse
import os
import sys
from contextlib import closing
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


def find_project_root() -> Path:
    """
    Busca la raíz del proyecto usando el archivo .env.
    Esto permite ejecutar el script desde cualquier carpeta.
    """
    current = Path(__file__).resolve()

    for parent in current.parents:
        if (parent / ".env").exists():
            return parent

    raise FileNotFoundError(
        "No se encontró el archivo .env en la raíz del proyecto."
    )


def get_connection():
    """
    Crea conexión a PostgreSQL usando variables del .env.
    Para ejecución desde Windows hacia Docker, DB_HOST debe ser localhost.
    """
    project_root = find_project_root()
    env_path = project_root / ".env"

    load_dotenv(dotenv_path=env_path)

    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "bd_nacional"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
    )


def execute_scalar(cur, sql):
    cur.execute(sql)
    row = cur.fetchone()
    return row[0] if row else None


def function_exists(cur, function_name: str) -> bool:
    """
    Valida si existe una función o procedimiento en el esquema turismo.
    """
    cur.execute(
        """
        SELECT EXISTS (
            SELECT 1
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'turismo'
              AND p.proname = %s
        );
        """,
        (function_name,),
    )
    return cur.fetchone()[0]


def check_prerequisites():
    """
    Valida que ya existan los datos mínimos antes de correr BI.
    """
    with closing(get_connection()) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM geografia.departamento;")
            total_departamentos = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM geografia.municipio;")
            total_municipios = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM turismo.fuente_turistica;")
            total_fuentes = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM turismo.destino_turistico;")
            total_destinos = cur.fetchone()[0]

            print("Validación de prerequisitos:")
            print(f"Departamentos: {total_departamentos}")
            print(f"Municipios: {total_municipios}")
            print(f"Fuentes turismo: {total_fuentes}")
            print(f"Destinos turismo: {total_destinos}")

            if total_departamentos < 22:
                raise RuntimeError(
                    "Geografía incompleta: se esperaban al menos 22 departamentos."
                )

            if total_municipios == 0:
                raise RuntimeError(
                    "Geografía incompleta: no existen municipios cargados."
                )

            if total_fuentes == 0:
                raise RuntimeError(
                    "Turismo incompleto: no existen fuentes turísticas cargadas."
                )

            if total_destinos == 0:
                raise RuntimeError(
                    "Turismo incompleto: no existen destinos turísticos cargados."
                )

            print("Prerequisitos correctos.")


def run_full():
    """
    Ejecuta el flujo BI completo definido en la base.
    """
    check_prerequisites()

    with closing(get_connection()) as conn:
        conn.autocommit = False

        try:
            with conn.cursor() as cur:
                if not function_exists(cur, "sp_etl_ejecutar_bi_completo"):
                    raise RuntimeError(
                        "No existe turismo.sp_etl_ejecutar_bi_completo(). "
                        "Revisa la migración de funciones ETL BI."
                    )

                resultado = execute_scalar(
                    cur,
                    "SELECT turismo.sp_etl_ejecutar_bi_completo();"
                )

                cur.execute("SELECT * FROM turismo.vw_bi_kpis_generales;")
                kpis = cur.fetchall()

            conn.commit()

            print("ETL BI turismo ejecutado correctamente.")
            print(f"Resultado: {resultado}")
            print("KPIs generales:")
            for row in kpis:
                print(row)

        except Exception:
            conn.rollback()
            raise


def refresh_marts():
    """
    Refresca datamarts BI.
    Usa la función segura creada en las migraciones.
    """
    with closing(get_connection()) as conn:
        conn.autocommit = False

        try:
            with conn.cursor() as cur:
                if function_exists(cur, "sp_etl_refrescar_datamarts"):
                    cur.execute("SELECT turismo.sp_etl_refrescar_datamarts();")
                elif function_exists(cur, "fn_refrescar_bi_turismo"):
                    cur.execute("SELECT turismo.fn_refrescar_bi_turismo();")
                else:
                    raise RuntimeError(
                        "No existe función para refrescar datamarts. "
                        "Se esperaba turismo.sp_etl_refrescar_datamarts() "
                        "o turismo.fn_refrescar_bi_turismo()."
                    )

            conn.commit()
            print("Datamarts de turismo refrescados correctamente.")

        except Exception:
            conn.rollback()
            raise


def validate_quality():
    """
    Ejecuta validaciones de calidad de datos del módulo turismo.
    """
    with closing(get_connection()) as conn:
        conn.autocommit = False

        try:
            with conn.cursor() as cur:
                if not function_exists(cur, "sp_etl_validar_calidad"):
                    raise RuntimeError(
                        "No existe turismo.sp_etl_validar_calidad()."
                    )

                cur.execute("SELECT turismo.sp_etl_validar_calidad(NULL);")

                cur.execute(
                    """
                    SELECT
                        fecha_validacion,
                        entidad,
                        regla,
                        nivel,
                        total_registros,
                        total_observaciones,
                        detalle
                    FROM turismo.vw_bi_alertas_calidad
                    ORDER BY fecha_validacion DESC, nivel DESC;
                    """
                )

                rows = cur.fetchall()

            conn.commit()

            print("Validaciones de calidad ejecutadas.")
            for row in rows:
                print(row)

        except Exception:
            conn.rollback()
            raise


def main():
    parser = argparse.ArgumentParser(
        description="ETL BI para el módulo Turismo"
    )

    parser.add_argument(
        "--full",
        action="store_true",
        help="Carga dimensiones, hechos, valida calidad y refresca datamarts"
    )

    parser.add_argument(
        "--refresh-marts",
        action="store_true",
        help="Refresca vistas materializadas"
    )

    parser.add_argument(
        "--validate",
        action="store_true",
        help="Ejecuta validaciones de calidad"
    )

    parser.add_argument(
        "--check",
        action="store_true",
        help="Valida prerequisitos de geografía y turismo"
    )

    args = parser.parse_args()

    if args.full:
        run_full()
    elif args.refresh_marts:
        refresh_marts()
    elif args.validate:
        validate_quality()
    elif args.check:
        check_prerequisites()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()