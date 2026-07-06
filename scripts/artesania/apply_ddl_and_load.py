#!/usr/bin/env python3
"""
Orquestador en Python para aplicar el módulo de Arte y Artesanía.
1. Aplica la migración DDL en la base de datos local.
2. Carga las fuentes (incluyendo la nueva fuente de artesania).
3. Ejecuta el ETL de carga de datos para las 11 tablas.
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
    ddl_file = repo_root / "database/migrations/artesania/V20260706180000__ddl_artesania.sql"

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

    print("\n=== 3. Ejecutando ETL de Arte y Artesanía ===")
    try:
        load_artesania_mod = importlib.import_module("artesania.20260706183000_load_artesania")
        load_artesania = load_artesania_mod.main
        load_artesania()
        print("¡ETL de Arte y Artesanía completado exitosamente!")
    except Exception as e:
        print(f"Error al ejecutar ETL: {e}")
        sys.exit(1)

    print("\n=== 4. Verificando conteos finales ===")
    try:
        from scripts.artesania.verify_artesania_counts import main as verify_counts
        verify_counts()
    except Exception as e:
        print(f"Error en la verificación final: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
