#!/usr/bin/env python3
import psycopg2

def main():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/bd_nacional')
    cur = conn.cursor()
    tables = [
        'actividad_productiva',
        'materia_prima',
        'actividad_materia',
        'cooperativa_asociacion',
        'produccion_municipal',
        'mercado_tradicional',
        'centro_acopio_procesamiento',
        'ruta_comercio',
        'servicio_financiero',
        'certificacion',
        'produccion_certificada'
    ]
    print("=== Conteo de Registros por Tabla ===")
    for t in tables:
        cur.execute(f'SELECT COUNT(*) FROM economia.{t}')
        print(f'economia.{t}: {cur.fetchone()[0]} filas')
    conn.close()

if __name__ == '__main__':
    main()
