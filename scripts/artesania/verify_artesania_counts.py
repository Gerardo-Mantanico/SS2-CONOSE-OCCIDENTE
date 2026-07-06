#!/usr/bin/env python3
"""
Validador de conteo de registros para el esquema artesania.
Verifica que cada una de las 11 tablas supere los 1,000 registros.
"""

import sys
import psycopg2

def main():
    db_url = "postgresql://postgres:postgres@localhost:5432/bd_nacional"
    print(f"Conectando a la base de datos para verificación: {db_url}")
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        sys.exit(1)

    tablas = [
        "tipo_obra_arte",
        "tecnica_artesanal",
        "material_arte",
        "taller_colectivo",
        "artista_artesano",
        "obra_arte_artesania",
        "obra_tecnica",
        "obra_material",
        "produccion_artesanal_municipal",
        "evento_exposicion_arte",
        "participante_evento"
    ]

    errores = 0
    total_registros = 0
    print("\n=== CONTEO DE REGISTROS POR TABLA EN ESQUEMA 'ARTESANIA' ===")
    
    for tabla in tablas:
        try:
            cur.execute(f"SELECT COUNT(*) FROM artesania.{tabla};")
            count = cur.fetchone()[0]
            total_registros += count
            
            status = "OK (>= 1000)" if count >= 1000 else "ERROR (< 1000)"
            if count < 1000:
                errores += 1
                
            print(f"- {tabla:32}: {count:6} registros | [{status}]")
        except Exception as e:
            print(f"- {tabla:32}: ERROR AL CONSULTAR ({e})")
            errores += 1

    conn.close()
    
    print("\n================ SUMMARY ================")
    print(f"Total registros cargados: {total_registros}")
    if errores > 0:
        print(f"Resultado: ¡FALLA! {errores} tabla(s) no cumplen con el requerimiento de mínimos.")
        sys.exit(1)
    else:
        print("Resultado: ¡EXITOSO! Todas las tablas superan el umbral de 1,000 registros.")
        sys.exit(0)

if __name__ == "__main__":
    main()
