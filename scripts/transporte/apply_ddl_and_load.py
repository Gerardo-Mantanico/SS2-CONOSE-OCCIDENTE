#!/usr/bin/env python3
"""
Orquestador en Python para aplicar el módulo de Logística y Transporte.
1. Aplica la migración DDL en la base de datos local.
2. Carga las fuentes (incluyendo la nueva fuente de transporte).
3. Ejecuta el ETL de carga de datos para las 9 tablas.
4. Valida y muestra el conteo final de registros.
"""

import sys
import psycopg2
import importlib
from pathlib import Path

# Agregar directorios al PATH de Python para poder importar los módulos
repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))
sys.path.insert(0, str(repo_root / "etl" / "python"))

def main():
    db_url = "postgresql://postgres:postgres@localhost:5432/bd_nacional"
    ddl_file = repo_root / "database/migrations/transporte/V20260706190000__ddl_transporte.sql"

    print("=== 1. Aplicando Migración DDL ===")
    if not ddl_file.exists():
        print(f"Error: No se encontró el archivo DDL en {ddl_file}")
        sys.exit(1)

    print(f"Conectando a la base de datos para aplicar DDL: {db_url}")
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # Leer y ejecutar el contenido SQL
        ddl_sql = ddl_file.read_text(encoding="utf-8")
        cur.execute(ddl_sql)
        conn.commit()
        cur.close()
        conn.close()
        print("¡Migración DDL aplicada exitosamente!")
    except Exception as e:
        print(f"Error al aplicar la migración DDL: {e}")
        sys.exit(1)

    print("\n=== 2. Registrando Fuentes de Datos ===")
    try:
        load_fuentes_mod = importlib.import_module("meta.20260702231447_load_fuentes")
        load_fuentes = load_fuentes_mod.main
        load_fuentes()
        print("¡Fuentes registradas exitosamente!")
    except Exception as e:
        print(f"Error al registrar fuentes: {e}")
        sys.exit(1)

    print("\n=== 3. Ejecutando ETL de Logística y Transporte ===")
    try:
        load_transporte_mod = importlib.import_module("transporte.20260706193000_load_transporte")
        load_transporte = load_transporte_mod.main
        load_transporte()
        print("¡ETL de Transporte completado exitosamente!")
    except Exception as e:
        print(f"Error al ejecutar ETL: {e}")
        sys.exit(1)

    print("\n=== 4. Verificando conteos finales ===")
    try:
        from scripts.transporte.verify_transporte_counts import main as verify_counts
        verify_counts()
    except Exception as e:
        print(f"Error en la verificación final: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
