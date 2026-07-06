#!/usr/bin/env python3
"""Ejecuta procesos BI del esquema turismo.

Este script no reemplaza Flyway. Primero se aplican migraciones; luego se usa
para refrescar dimensiones, hechos, validaciones y datamarts.
"""
import argparse
import os
import sys
from contextlib import closing

import psycopg2
from dotenv import load_dotenv


def get_connection():
    load_dotenv()
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "conose_occidente"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
    )


def execute_scalar(cur, sql):
    cur.execute(sql)
    row = cur.fetchone()
    return row[0] if row else None


def run_full():
    with closing(get_connection()) as conn:
        conn.autocommit = False
        try:
            with conn.cursor() as cur:
                resultado = execute_scalar(cur, "SELECT turismo.sp_etl_ejecutar_bi_completo();")
                cur.execute("SELECT * FROM turismo.vw_bi_kpis_generales;")
                kpis = cur.fetchall()
            conn.commit()
            print("ETL BI turismo ejecutado correctamente.")
            print(resultado)
            for row in kpis:
                print(row)
        except Exception:
            conn.rollback()
            raise


def refresh_marts():
    with closing(get_connection()) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT turismo.sp_etl_refrescar_datamarts();")
        conn.commit()
        print("Datamarts de turismo refrescados.")


def validate_quality():
    with closing(get_connection()) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT turismo.sp_etl_validar_calidad(NULL);")
            cur.execute("SELECT * FROM turismo.vw_bi_alertas_calidad;")
            for row in cur.fetchall():
                print(row)
        conn.commit()


def main():
    parser = argparse.ArgumentParser(description="ETL BI para el area turismo")
    parser.add_argument("--full", action="store_true", help="Carga dimensiones, hechos, valida calidad y refresca datamarts")
    parser.add_argument("--refresh-marts", action="store_true", help="Refresca vistas materializadas")
    parser.add_argument("--validate", action="store_true", help="Ejecuta validaciones de calidad")
    args = parser.parse_args()

    if args.full:
        run_full()
    elif args.refresh_marts:
        refresh_marts()
    elif args.validate:
        validate_quality()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
