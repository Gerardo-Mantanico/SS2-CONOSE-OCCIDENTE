#!/usr/bin/env python3
"""
ETL para el módulo de Economía y Producción Avanzado (11 Tablas).
Carga datos de actividades productivas, materias primas, cooperativas, relaciones,
producción municipal, mercados, infraestructura, rutas de comercio, servicios financieros,
certificaciones y producción certificada en el esquema `economia`.

Ejecutable por su cuenta:
    python etl/python/economia/20260705164500_load_economia.py
"""

from __future__ import annotations

import csv
import hashlib
import sys
from pathlib import Path

# Permite importar config al correr el script directo, sin importar el CWD.
for _p in Path(__file__).resolve().parents:
    if (_p / "config.py").exists():
        sys.path.insert(0, str(_p))
        break

from config import registrar_carga


def _find_data_dir() -> Path:
    """Ubica la carpeta data/economia en la raíz del repo."""
    for parent in Path(__file__).resolve().parents:
        cand = parent / "data" / "economia"
        if cand.exists():
            return cand
    raise FileNotFoundError("No se encontró data/economia en la raíz del repo.")


def _calcular_hash(ruta: Path) -> str:
    """Retorna el hash SHA-256 de un archivo para registrar la trazabilidad."""
    hasher = hashlib.sha256()
    with ruta.open("rb") as f:
        while chunk := f.read(8192):
            hasher.update(chunk)
    return hasher.hexdigest()


def main() -> None:
    data_dir = _find_data_dir()
    
    # Rutas de los archivos CSV
    csv_actividades = data_dir / "actividades.csv"
    csv_materias = data_dir / "materias_primas.csv"
    csv_act_mat = data_dir / "actividad_materia.csv"
    csv_cooperativas = data_dir / "cooperativas.csv"
    csv_produccion = data_dir / "produccion_municipal.csv"
    csv_mercados = data_dir / "mercados.csv"
    csv_procesamiento = data_dir / "centros_procesamiento.csv"
    csv_rutas = data_dir / "rutas_comercio.csv"
    csv_servicios = data_dir / "servicios_financieros.csv"
    csv_certificaciones = data_dir / "certificaciones.csv"
    csv_prod_cert = data_dir / "produccion_certificada.csv"

    # Usamos el de producción para el hash principal
    hash_combinado = _calcular_hash(csv_produccion)

    print(f"Iniciando ETL de Economía Avanzado. Insumos en: {data_dir}")

    # Registramos la carga en meta.carga
    with registrar_carga(
        codigo_fuente="2026_07_gtm_economia_produccion",
        archivo="data/economia/",
        hash_archivo=hash_combinado,
        nombre_script="economia/20260705164500_load_economia.py"
    ) as carga:

        cur = carga.cur

        # --- 1. CARGA DE ACTIVIDADES PRODUCTIVAS ---
        print("Cargando catálogo de actividades productivas...")
        actividad_id_map = {}
        with csv_actividades.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                cat = fila["categoria"].strip()
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO economia.actividad_productiva (nombre, categoria, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        categoria = EXCLUDED.categoria,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, cat, desc, carga.id)
                )
                act_id = cur.fetchone()[0]
                actividad_id_map[nombre] = act_id
                carga.filas_insertadas += 1

        # --- 2. CARGA DE MATERIAS PRIMAS ---
        print("Cargando catálogo de materias primas...")
        materia_id_map = {}
        with csv_materias.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                origen = fila["origen"].strip()
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO economia.materia_prima (nombre, origen, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        origen = EXCLUDED.origen,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, origen, desc, carga.id)
                )
                mat_id = cur.fetchone()[0]
                materia_id_map[nombre] = mat_id
                carga.filas_insertadas += 1

        # --- 3. CARGA DE RELACIÓN ACTIVIDAD - MATERIA ---
        print("Cargando relaciones actividad - materia...")
        with csv_act_mat.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                act_nombre = fila["actividad_nombre"].strip()
                mat_nombre = fila["materia_nombre"].strip()
                indispensable = fila["es_indispensable"].strip().lower() == "true"

                act_id = actividad_id_map.get(act_nombre)
                mat_id = materia_id_map.get(mat_nombre)

                if not act_id or not mat_id:
                    print(f"Warning: Actividad '{act_nombre}' o Materia '{mat_nombre}' no encontradas para relacion. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO economia.actividad_materia (actividad_id, materia_id, es_indispensable)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (actividad_id, materia_id) DO UPDATE SET
                        es_indispensable = EXCLUDED.es_indispensable
                    """,
                    (act_id, mat_id, indispensable)
                )
                carga.filas_insertadas += 1

        # --- 4. CARGA DE COOPERATIVAS Y ASOCIACIONES ---
        print("Cargando catálogo de cooperativas y asociaciones...")
        cooperativa_id_map = {}
        cooperativa_siglas_map = {}
        with csv_cooperativas.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                siglas = fila["siglas"].strip() or None
                mun_pcode = fila["municipio_pcode"].strip()
                cobertura = fila["cobertura"].strip()
                desc = fila["descripcion"].strip() or None

                # Resolver municipio
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado para cooperativa '{nombre}'. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO economia.cooperativa_asociacion (nombre, siglas, municipio_id, cobertura, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        siglas = EXCLUDED.siglas,
                        municipio_id = EXCLUDED.municipio_id,
                        cobertura = EXCLUDED.cobertura,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, siglas, mun_id, cobertura, desc, carga.id)
                )
                coop_id = cur.fetchone()[0]
                cooperativa_id_map[nombre] = coop_id
                if siglas:
                    cooperativa_siglas_map[siglas] = coop_id
                carga.filas_insertadas += 1

        # --- 5. CARGA DE PRODUCCIÓN MUNICIPAL ---
        print("Cargando producción municipal detallada...")
        with csv_produccion.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                mun_pcode = fila["municipio_pcode"].strip()
                act_nombre = fila["actividad_nombre"].strip()
                coop_nombre = fila["cooperativa_nombre"].strip() or None
                es_principal = fila["es_principal"].strip().lower() == "true"
                volumen = fila["volumen_estimado"].strip() or "No disponible"
                productores = int(fila["cantidad_productores_est"].strip()) if fila["cantidad_productores_est"].strip() else 0
                empleo = int(fila["empleo_generado_est"].strip()) if fila["empleo_generado_est"].strip() else 0
                ciclo = fila["ciclo_cosecha_meses"].strip() or None
                destino = fila["destino_principal"].strip()

                act_id = actividad_id_map.get(act_nombre)
                if not act_id:
                    print(f"Warning: Actividad '{act_nombre}' no encontrada en el catálogo. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                coop_id = cooperativa_id_map.get(coop_nombre) if coop_nombre else None

                # Resolver municipio
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado para produccion. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO economia.produccion_municipal 
                        (municipio_id, actividad_id, cooperativa_id, es_principal, volumen_estimado, cantidad_productores_est, empleo_generado_est, ciclo_cosecha_meses, destino_principal, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (municipio_id, actividad_id) DO UPDATE SET
                        cooperativa_id = EXCLUDED.cooperativa_id,
                        es_principal = EXCLUDED.es_principal,
                        volumen_estimado = EXCLUDED.volumen_estimado,
                        cantidad_productores_est = EXCLUDED.cantidad_productores_est,
                        empleo_generado_est = EXCLUDED.empleo_generado_est,
                        ciclo_cosecha_meses = EXCLUDED.ciclo_cosecha_meses,
                        destino_principal = EXCLUDED.destino_principal,
                        carga_id = EXCLUDED.carga_id
                    """,
                    (mun_id, act_id, coop_id, es_principal, volumen, productores, empleo, ciclo, destino, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 6. CARGA DE MERCADOS TRADICIONALES ---
        print("Cargando mercados tradicionales...")
        with csv_mercados.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                mun_pcode = fila["municipio_pcode"].strip()
                dias_plaza = fila["dias_plaza"].strip()
                tipo_mercado = fila["tipo_mercado"].strip()
                vendedores = int(fila["cantidad_vendedores_est"].strip()) if fila["cantidad_vendedores_est"].strip() else None
                latitud = float(fila["latitud"].strip()) if fila["latitud"].strip() else None
                longitud = float(fila["longitud"].strip()) if fila["longitud"].strip() else None
                desc = fila["descripcion"].strip() or None

                # Resolver municipio
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado para mercado '{nombre}'. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO economia.mercado_tradicional 
                        (nombre, municipio_id, dias_plaza, tipo_mercado, cantidad_vendedores_est, latitud, longitud, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        municipio_id = EXCLUDED.municipio_id,
                        dias_plaza = EXCLUDED.dias_plaza,
                        tipo_mercado = EXCLUDED.tipo_mercado,
                        cantidad_vendedores_est = EXCLUDED.cantidad_vendedores_est,
                        latitud = EXCLUDED.latitud,
                        longitud = EXCLUDED.longitud,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    """,
                    (nombre, mun_id, dias_plaza, tipo_mercado, vendedores, latitud, longitud, desc, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 7. CARGA DE INFRAESTRUCTURA PRODUCTIVA ---
        print("Cargando centros de procesamiento y acopio...")
        with csv_procesamiento.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                tipo = fila["tipo"].strip()
                mun_pcode = fila["municipio_pcode"].strip()
                capacidad = fila["capacidad_estimada"].strip() or None

                # Resolver municipio
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado para centro '{nombre}'. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO economia.centro_acopio_procesamiento (nombre, tipo, municipio_id, capacidad_estimada, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (nombre, municipio_id) DO UPDATE SET
                        tipo = EXCLUDED.tipo,
                        capacidad_estimada = EXCLUDED.capacidad_estimada,
                        carga_id = EXCLUDED.carga_id
                    """,
                    (nombre, tipo, mun_id, capacidad, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 8. CARGA DE RUTAS DE COMERCIO ---
        print("Cargando rutas de comercio...")
        with csv_rutas.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                orig_pcode = fila["origen_municipio_pcode"].strip()
                dest_pcode = fila["destino_municipio_pcode"].strip() or None
                puerto = fila["puerto_salida"].strip() or None
                medio = fila["medio_transporte"].strip()
                distancia = float(fila["distancia_km"].strip()) if fila["distancia_km"].strip() else None
                tiempo = float(fila["tiempo_estimado_horas"].strip()) if fila["tiempo_estimado_horas"].strip() else None
                producto = fila["producto_principal"].strip() or None

                # Resolver origen
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (orig_pcode,))
                row_orig = cur.fetchone()
                if not row_orig:
                    print(f"Warning: Municipio de origen '{orig_pcode}' no encontrado. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                orig_id = row_orig[0]

                # Resolver destino
                dest_id = None
                if dest_pcode:
                    cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (dest_pcode,))
                    row_dest = cur.fetchone()
                    if not row_dest:
                        print(f"Warning: Municipio de destino '{dest_pcode}' no encontrado. Saltando...")
                        carga.filas_rechazadas += 1
                        continue
                    dest_id = row_dest[0]

                cur.execute(
                    """
                    INSERT INTO economia.ruta_comercio 
                        (origen_municipio_id, destino_municipio_id, puerto_salida, medio_transporte, distancia_km, tiempo_estimado_horas, producto_principal, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (orig_id, dest_id, puerto, medio, distancia, tiempo, producto, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 9. CARGA DE SERVICIOS FINANCIEROS ---
        print("Cargando servicios financieros...")
        with csv_servicios.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                coop_siglas = fila["cooperativa_siglas"].strip()
                tipo = fila["tipo_servicio"].strip()
                tasa = float(fila["tasa_interes_anual"].strip()) if fila["tasa_interes_anual"].strip() else None
                monto = float(fila["monto_maximo_quetzales"].strip()) if fila["monto_maximo_quetzales"].strip() else None
                requisito = fila["requisito_principal"].strip() or None

                coop_id = cooperativa_siglas_map.get(coop_siglas)
                if not coop_id:
                    print(f"Warning: Cooperativa con siglas '{coop_siglas}' no encontrada. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO economia.servicio_financiero 
                        (cooperativa_id, tipo_servicio, tasa_interes_anual, monto_maximo_quetzales, requisito_principal, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (cooperativa_id, tipo_servicio) DO UPDATE SET
                        tasa_interes_anual = EXCLUDED.tasa_interes_anual,
                        monto_maximo_quetzales = EXCLUDED.monto_maximo_quetzales,
                        requisito_principal = EXCLUDED.requisito_principal,
                        carga_id = EXCLUDED.carga_id
                    """,
                    (coop_id, tipo, tasa, monto, requisito, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 10. CARGA DE CERTIFICACIONES ---
        print("Cargando catálogo de certificaciones...")
        certificacion_id_map = {}
        with csv_certificaciones.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                ente = fila["ente_certificador"].strip()
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO economia.certificacion (nombre, ente_certificador, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        ente_certificador = EXCLUDED.ente_certificador,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, ente, desc, carga.id)
                )
                cert_id = cur.fetchone()[0]
                certificacion_id_map[nombre] = cert_id
                carga.filas_insertadas += 1

        # --- 11. CARGA DE PRODUCCIÓN CERTIFICADA ---
        print("Cargando producción certificada...")
        with csv_prod_cert.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                mun_pcode = fila["municipio_pcode"].strip()
                act_nombre = fila["actividad_nombre"].strip()
                cert_nombre = fila["certificacion_nombre"].strip()
                porcentaje = float(fila["porcentaje_produccion"].strip()) if fila["porcentaje_produccion"].strip() else None
                fecha_auditoria = fila["fecha_auditoria"].strip()

                # Resolver municipio
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio '{mun_pcode}' no encontrado. Saltando...")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                # Resolver actividad
                act_id = actividad_id_map.get(act_nombre)
                if not act_id:
                    print(f"Warning: Actividad '{act_nombre}' no encontrada. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                # Resolver certificación
                cert_id = certificacion_id_map.get(cert_nombre)
                if not cert_id:
                    print(f"Warning: Certificación '{cert_nombre}' no encontrada. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO economia.produccion_certificada 
                        (municipio_id, actividad_id, certificacion_id, porcentaje_produccion, fecha_auditoria, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (municipio_id, actividad_id, certificacion_id) DO UPDATE SET
                        porcentaje_produccion = EXCLUDED.porcentaje_produccion,
                        fecha_auditoria = EXCLUDED.fecha_auditoria,
                        carga_id = EXCLUDED.carga_id
                    """,
                    (mun_id, act_id, cert_id, porcentaje, fecha_auditoria, carga.id)
                )
                carga.filas_insertadas += 1

        print("ETL del módulo de Economía Complejo finalizado con éxito.")

    print(f"Proceso concluido: {carga.filas_procesadas} filas leídas, {carga.filas_insertadas} insertadas.")


if __name__ == "__main__":
    main()
