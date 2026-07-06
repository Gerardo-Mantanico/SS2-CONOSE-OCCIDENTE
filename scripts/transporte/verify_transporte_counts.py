#!/usr/bin/env python3
"""
Validador de conteos de registros para el esquema 'transporte'.
Verifica que las tablas transaccionales y de relación tengan >= 1,000 registros.
"""

import sys
import psycopg2

def main():
    db_url = "postgresql://postgres:postgres@localhost:5432/bd_nacional"
    print(f"Conectando a la base de datos para verificación: {db_url}\n")
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        sys.exit(1)

    # Definir umbrales esperados
    # tipo_transporte y tipo_via son tablas maestras de pocos registros fijos (6 y 5)
    # conexion_municipal es 160 municipios * 3 vehículos = 480 registros
    # Las demás deben tener >= 1,000 registros
    tables_to_verify = [
        {"table": "transporte.tipo_transporte", "min": 6, "is_lookup": True},
        {"table": "transporte.proveedor_transporte", "min": 1000, "is_lookup": False},
        {"table": "transporte.ruta_transporte", "min": 1000, "is_lookup": False},
        {"table": "transporte.itinerario_transporte", "min": 1000, "is_lookup": False},
        {"table": "transporte.tipo_via", "min": 5, "is_lookup": True},
        {"table": "transporte.tramo_vial", "min": 1000, "is_lookup": False},
        {"table": "transporte.incidencia_vial", "min": 1000, "is_lookup": False},
        {"table": "transporte.destino_transporte", "min": 1000, "is_lookup": False},
        {"table": "transporte.conexion_municipal", "min": 1000, "is_lookup": False}
    ]

    total_rows = 0
    failures = 0

    print("=== CONTEO DE REGISTROS POR TABLA EN ESQUEMA 'TRANSPORTE' ===")
    for item in tables_to_verify:
        t_name = item["table"]
        t_min = item["min"]
        
        try:
            cur.execute(f"SELECT COUNT(*) FROM {t_name};")
            count = cur.fetchone()[0]
            total_rows += count
            
            status = f"[OK (>= {t_min})]" if count >= t_min else f"[FALLA (< {t_min})]"
            if count < t_min:
                failures += 1
                
            print(f"- {t_name:<32} : {count:6d} registros | {status}")
        except Exception as e:
            print(f"- {t_name:<32} : ERROR AL CONSULTAR ({e})")
            failures += 1

    print("\n================ SUMMARY ================")
    print(f"Total registros cargados: {total_rows}")
    
    cur.close()
    conn.close()

    if failures > 0:
        print("Resultado: ¡FALLA! Una o más tablas no cumplen con el requerimiento de mínimos.")
        sys.exit(1)
    else:
        print("Resultado: ¡EXITOSO! Todas las tablas cumplen con el volumen esperado.")
        sys.exit(0)

if __name__ == "__main__":
    main()
