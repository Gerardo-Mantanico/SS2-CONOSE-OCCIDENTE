#!/usr/bin/env python3
"""
Pipeline ETL para cargar el módulo de Logística, Transporte y Conectividad Vial.
Lee los CSVs generados en data/transporte/, mapea IDs geográficos/destinos,
y realiza la carga en las 9 tablas de base de datos bajo una sola transacción.
"""

import sys
import csv
from pathlib import Path

# Configurar rutas de importación de utilidades
repo_root = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(repo_root / "etl" / "python"))

from config import registrar_carga

def main():
    csv_dir = repo_root / "data" / "transporte"
    print(f"Iniciando ETL de Transporte. Insumos en: {csv_dir}")

    if not csv_dir.exists():
        print(f"Error: La carpeta de insumos {csv_dir} no existe.")
        sys.exit(1)

    with registrar_carga(
        codigo_fuente="2026_07_gtm_logistica_transporte",
        nombre_script="transporte/20260706193000_load_transporte.py"
    ) as carga:
        cur = carga.cur

        # 1. Limpieza inicial en orden inverso de dependencias
        print("Realizando limpieza inicial del esquema transporte...")
        cur.execute("TRUNCATE TABLE transporte.incidencia_vial CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.itinerario_transporte CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.destino_transporte CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.conexion_municipal CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.tramo_vial CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.ruta_transporte CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.proveedor_transporte CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.tipo_via CASCADE;")
        cur.execute("TRUNCATE TABLE transporte.tipo_transporte CASCADE;")

        # 2. Cargar mapas de resolución (Geografía y Destinos)
        # 2a. Departamentos
        cur.execute("SELECT id, nombre FROM geografia.departamento;")
        dep_map = {row[1].strip().lower(): row[0] for row in cur.fetchall()}

        # 2b. Municipios (incluye departamento_id para evitar homónimos)
        cur.execute("SELECT id, nombre, departamento_id FROM geografia.municipio;")
        muni_map = {}
        for row in cur.fetchall():
            muni_id, name, dep_id = row
            muni_map[(name.strip().lower(), dep_id)] = muni_id

        # 2c. Mapa de municipios por nombre simple (si no hay colisión, o para fallback rápido)
        cur.execute("SELECT id, nombre FROM geografia.municipio;")
        muni_simple_map = {row[1].strip().lower(): row[0] for row in cur.fetchall()}

        # 2d. Destinos turísticos
        cur.execute("SELECT id_destino, nombre FROM turismo.destino_turistico;")
        dest_map = {row[1].strip().lower(): row[0] for row in cur.fetchall()}

        # Contenedores de mapeos internos de la carga
        tipo_transporte_ids = {}
        tipo_via_ids = {}
        proveedor_ids = {}
        ruta_ids = {}
        tramo_ids = {}

        # ==========================================
        # TABLA 1: tipo_transporte
        # ==========================================
        print("Cargando tipos de transporte...")
        with open(csv_dir / "tipo_transporte.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                cur.execute(
                    """
                    INSERT INTO transporte.tipo_transporte (codigo, nombre, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id_tipo_transporte;
                    """,
                    (row["codigo"], row["nombre"], row["descripcion"], carga.id)
                )
                tipo_transporte_ids[row["codigo"]] = cur.fetchone()[0]
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 2: proveedor_transporte
        # ==========================================
        print("Cargando proveedores de transporte...")
        with open(csv_dir / "proveedor_transporte.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                dep_name = row["departamento_name"] if "departamento_name" in row else row["departamento_nombre"]
                muni_name = row["municipio_name"] if "municipio_name" in row else row["municipio_nombre"]
                
                dep_id = dep_map.get(dep_name.strip().lower())
                if not dep_id:
                    print(f"Advertencia: Departamento '{dep_name}' no encontrado para proveedor '{row['nombre']}'")
                    carga.filas_rechazadas += 1
                    continue
                    
                muni_id = muni_map.get((muni_name.strip().lower(), dep_id)) or muni_simple_map.get(muni_name.strip().lower())
                
                cur.execute(
                    """
                    INSERT INTO transporte.proveedor_transporte (codigo, nombre, representante, contacto, departamento_id, municipio_id, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_proveedor;
                    """,
                    (row["codigo"], row["nombre"], row["representante"], row["contacto"], dep_id, muni_id, carga.id)
                )
                proveedor_ids[row["codigo"]] = cur.fetchone()[0]
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 3: ruta_transporte
        # ==========================================
        print("Cargando rutas de transporte...")
        with open(csv_dir / "ruta_transporte.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                orig_muni = row["origen_municipio_nombre"]
                dest_muni = row["destino_municipio_nombre"]
                tipo_cod = row["tipo_transporte_codigo"]
                
                orig_muni_id = muni_simple_map.get(orig_muni.strip().lower())
                dest_muni_id = muni_simple_map.get(dest_muni.strip().lower())
                tipo_id = tipo_transporte_ids.get(tipo_cod)
                
                if not orig_muni_id or not dest_muni_id or not tipo_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.ruta_transporte (codigo, origen_municipio_id, destino_municipio_id, tipo_transporte_id, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_ruta_transporte;
                    """,
                    (row["codigo"], orig_muni_id, dest_muni_id, tipo_id, carga.id)
                )
                ruta_ids[row["codigo"]] = cur.fetchone()[0]
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 4: itinerario_transporte
        # ==========================================
        print("Cargando itinerarios...")
        with open(csv_dir / "itinerario_transporte.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                ruta_id = ruta_ids.get(row["ruta_transporte_codigo"])
                prov_id = proveedor_ids.get(row["proveedor_codigo"])
                
                if not ruta_id or not prov_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.itinerario_transporte (ruta_transporte_id, proveedor_id, hora_salida, frecuencia, tarifa_q, duracion_estimada_minutos, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s);
                    """,
                    (ruta_id, prov_id, row["hora_salida"], row["frecuencia"], float(row["tarifa_q"]), int(row["duracion_estimada_minutos"]), carga.id)
                )
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 5: tipo_via
        # ==========================================
        print("Cargando tipos de vía...")
        with open(csv_dir / "tipo_via.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                cur.execute(
                    """
                    INSERT INTO transporte.tipo_via (codigo, nombre, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id_tipo_via;
                    """,
                    (row["codigo"], row["nombre"], row["descripcion"], carga.id)
                )
                tipo_via_ids[row["codigo"]] = cur.fetchone()[0]
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 6: tramo_vial
        # ==========================================
        print("Cargando tramos viales...")
        with open(csv_dir / "tramo_vial.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                orig_muni = row["origen_municipio_nombre"]
                dest_muni = row["destino_municipio_nombre"]
                via_cod = row["tipo_via_codigo"]
                
                orig_muni_id = muni_simple_map.get(orig_muni.strip().lower())
                dest_muni_id = muni_simple_map.get(dest_muni.strip().lower())
                via_id = tipo_via_ids.get(via_cod)
                
                if not orig_muni_id or not dest_muni_id or not via_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.tramo_vial (codigo, nombre, origen_municipio_id, destino_municipio_id, tipo_via_id, distancia_km, tiempo_promedio_minutos, estado_transitabilidad, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_tramo;
                    """,
                    (row["codigo"], row["nombre"], orig_muni_id, dest_muni_id, via_id, float(row["distancia_km"]), int(row["tiempo_promedio_minutos"]), row["estado_transitabilidad"], carga.id)
                )
                tramo_ids[row["codigo"]] = cur.fetchone()[0]
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 7: incidencia_vial
        # ==========================================
        print("Cargando incidencias viales...")
        with open(csv_dir / "incidencia_vial.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                tramo_id = tramo_ids.get(row["tramo_codigo"])
                if not tramo_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.incidencia_vial (codigo, tramo_id, tipo_incidencia, descripcion, fecha_reporte, activo, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s);
                    """,
                    (row["codigo"], tramo_id, row["tipo_incidencia"], row["descripcion"], row["fecha_reporte"], row["activo"].lower() == "true", carga.id)
                )
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 8: destino_transporte
        # ==========================================
        print("Cargando paradas de transporte en destinos turísticos...")
        with open(csv_dir / "destino_transporte.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                dest_id = dest_map.get(row["destino_nombre"].strip().lower())
                tipo_id = tipo_transporte_ids.get(row["tipo_transporte_codigo"])
                
                if not dest_id or not tipo_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.destino_transporte (destino_id, parada_cercana, tipo_transporte_id, distancia_parada_km, costo_traslado_local_q, tiempo_traslado_minutos, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (destino_id, parada_cercana, tipo_transporte_id) DO UPDATE SET
                      distancia_parada_km = EXCLUDED.distancia_parada_km,
                      costo_traslado_local_q = EXCLUDED.costo_traslado_local_q,
                      tiempo_traslado_minutos = EXCLUDED.tiempo_traslado_minutos,
                      carga_id = EXCLUDED.carga_id;
                    """,
                    (dest_id, row["parada_cercana"], tipo_id, float(row["distancia_parada_km"]), float(row["costo_traslado_local_q"]), int(row["tiempo_traslado_minutos"]), carga.id)
                )
                carga.filas_insertadas += 1

        # ==========================================
        # TABLA 9: conexion_municipal
        # ==========================================
        print("Cargando matriz de conexión municipal...")
        with open(csv_dir / "conexion_municipal.csv", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                carga.filas_procesadas += 1
                
                muni_name = row["municipio_nombre"]
                muni_id = muni_simple_map.get(muni_name.strip().lower())
                
                if not muni_id:
                    carga.filas_rechazadas += 1
                    continue
                    
                cur.execute(
                    """
                    INSERT INTO transporte.conexion_municipal (municipio_id, tipo_vehiculo, distancia_cabecera_km, tiempo_cabecera_minutos, distancia_capital_km, tiempo_capital_minutos, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (municipio_id, tipo_vehiculo) DO UPDATE SET
                      distancia_cabecera_km = EXCLUDED.distancia_cabecera_km,
                      tiempo_cabecera_minutos = EXCLUDED.tiempo_cabecera_minutos,
                      distancia_capital_km = EXCLUDED.distancia_capital_km,
                      tiempo_capital_minutos = EXCLUDED.tiempo_capital_minutos,
                      carga_id = EXCLUDED.carga_id;
                    """,
                    (muni_id, row["tipo_vehiculo"], float(row["distancia_cabecera_km"]), int(row["tiempo_cabecera_minutos"]), float(row["distancia_capital_km"]), int(row["tiempo_capital_minutos"]), carga.id)
                )
                carga.filas_insertadas += 1

        print("¡ETL del módulo de Logística, Transporte y Conectividad Vial finalizado exitosamente!")

if __name__ == "__main__":
    main()
