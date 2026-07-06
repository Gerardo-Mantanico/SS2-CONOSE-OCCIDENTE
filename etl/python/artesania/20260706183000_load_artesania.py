#!/usr/bin/env python3
"""
ETL para el módulo de Arte y Artesanía (11 Tablas).
Carga datos de tipos de obra, técnicas, materiales, talleres, artistas, obras,
relaciones, producción municipal, eventos y participaciones en el esquema `artesania`.

Ejecutable por su cuenta:
    python etl/python/artesania/20260706183000_load_artesania.py
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
    """Ubica la carpeta data/artesania en la raíz del repo."""
    for parent in Path(__file__).resolve().parents:
        cand = parent / "data" / "artesania"
        if cand.exists():
            return cand
    raise FileNotFoundError("No se encontró data/artesania en la raíz del repo.")

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
    csv_tipo_obra = data_dir / "tipo_obra_arte.csv"
    csv_tecnica = data_dir / "tecnica_artesanal.csv"
    csv_material = data_dir / "material_arte.csv"
    csv_taller = data_dir / "taller_colectivo.csv"
    csv_artista = data_dir / "artista_artesano.csv"
    csv_obra = data_dir / "obra_arte_artesania.csv"
    csv_obra_tecnica = data_dir / "obra_tecnica.csv"
    csv_obra_material = data_dir / "obra_material.csv"
    csv_produccion = data_dir / "produccion_artesanal_municipal.csv"
    csv_evento = data_dir / "evento_exposicion_arte.csv"
    csv_participante = data_dir / "participante_evento.csv"

    # Hash del archivo principal para el registro
    hash_combinado = _calcular_hash(csv_produccion)

    print(f"Iniciando ETL de Arte y Artesanía. Insumos en: {data_dir}")

    # Registramos la carga en meta.carga
    with registrar_carga(
        codigo_fuente="2026_07_gtm_arte_artesania",
        archivo="data/artesania/",
        hash_archivo=hash_combinado,
        nombre_script="artesania/20260706183000_load_artesania.py"
    ) as carga:

        cur = carga.cur

        # --- LIMPIEZA INICIAL EN ORDEN INVERSO ---
        print("Realizando limpieza inicial del esquema artesania...")
        cur.execute("DELETE FROM artesania.participante_evento;")
        cur.execute("DELETE FROM artesania.obra_material;")
        cur.execute("DELETE FROM artesania.obra_tecnica;")
        cur.execute("DELETE FROM artesania.obra_arte_artesania;")
        cur.execute("DELETE FROM artesania.artista_artesano;")
        cur.execute("DELETE FROM artesania.taller_colectivo;")
        cur.execute("DELETE FROM artesania.evento_exposicion_arte;")
        cur.execute("DELETE FROM artesania.produccion_artesanal_municipal;")
        cur.execute("DELETE FROM artesania.material_arte;")
        cur.execute("DELETE FROM artesania.tecnica_artesanal;")
        cur.execute("DELETE FROM artesania.tipo_obra_arte;")

        # Mapas para resolver relaciones entre IDs de CSV e IDs de base de datos
        muni_id_map = {}
        dep_id_map = {}
        tipo_obra_map = {} # codigo -> db_id
        tipo_obra_csv_map = {} # csv_id -> db_id
        tecnica_map = {} # csv_id -> db_id
        material_map = {} # csv_id -> db_id
        taller_map = {} # csv_id -> db_id
        artista_map = {} # csv_id -> db_id
        obra_map = {} # csv_id -> db_id
        evento_map = {} # csv_id -> db_id

        # Cachear departamentos y municipios
        cur.execute("SELECT pcode, id FROM geografia.departamento;")
        for row in cur.fetchall():
            dep_id_map[row[0]] = row[1]

        cur.execute("SELECT pcode, id FROM geografia.municipio;")
        for row in cur.fetchall():
            muni_id_map[row[0]] = row[1]

        # --- 1. TIPO OBRA ARTE ---
        print("Cargando tipos de obra de arte...")
        with csv_tipo_obra.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_tipo_obra"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                desc = fila["descripcion"].strip() or None
                cat_gen = fila["categoria_general"].strip()

                cur.execute(
                    """
                    INSERT INTO artesania.tipo_obra_arte (codigo, nombre, descripcion, categoria_general, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_tipo_obra;
                    """,
                    (codigo, nombre, desc, cat_gen, carga.id)
                )
                db_id = cur.fetchone()[0]
                tipo_obra_map[codigo] = db_id
                tipo_obra_csv_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 2. TECNICA ARTESANAL ---
        print("Cargando técnicas artesanales...")
        with csv_tecnica.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_tecnica"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                origen = fila["origen_historico"].strip() or None
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO artesania.tecnica_artesanal (codigo, nombre, origen_historico, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_tecnica;
                    """,
                    (codigo, nombre, origen, desc, carga.id)
                )
                db_id = cur.fetchone()[0]
                tecnica_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 3. MATERIAL ARTE ---
        print("Cargando catálogo de materiales...")
        with csv_material.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_material"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO artesania.material_arte (codigo, nombre, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id_material;
                    """,
                    (codigo, nombre, desc, carga.id)
                )
                db_id = cur.fetchone()[0]
                material_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 4. TALLER COLECTIVO ---
        print("Cargando talleres y colectivos...")
        with csv_taller.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_taller"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                repre = fila["representante"].strip() or None
                dep_pcode = fila["departamento_pcode"].strip()
                muni_pcode = fila["municipio_pcode"].strip()
                dir_det = fila["direccion"].strip() or None
                anio_fun = int(fila["anio_fundacion"]) if fila["anio_fundacion"] else None
                cant_miembros = int(fila["cantidad_miembros"]) if fila["cantidad_miembros"] else 1
                contacto = fila["contacto"].strip() or None

                dep_id = dep_id_map.get(dep_pcode)
                muni_id = muni_id_map.get(muni_pcode)

                if not dep_id:
                    print(f"Warning: Departamento {dep_pcode} no encontrado para taller {nombre}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.taller_colectivo 
                        (codigo, nombre, representante, departamento_id, municipio_id, direccion, anio_fundacion, cantidad_miembros, contacto, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_taller;
                    """,
                    (codigo, nombre, repre, dep_id, muni_id, dir_det, anio_fun, cant_miembros, contacto, carga.id)
                )
                db_id = cur.fetchone()[0]
                taller_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 5. ARTISTA ARTESANO ---
        print("Cargando artistas y artesanos...")
        with csv_artista.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_artista"])
                codigo = fila["codigo"].strip()
                nombre_comp = fila["nombre_completo"].strip()
                genero = fila["genero"].strip() or None
                fecha_nac = fila["fecha_nacimiento"].strip() or None
                dep_pcode = fila["departamento_pcode"].strip()
                muni_pcode = fila["municipio_pcode"].strip()
                csv_taller_id = int(fila["taller_id"]) if fila["taller_id"] else None
                esp_princ = fila["especialidad_principal"].strip()
                reco = fila["reconocimientos"].strip() or None

                dep_id = dep_id_map.get(dep_pcode)
                muni_id = muni_id_map.get(muni_pcode)
                taller_db_id = taller_map.get(csv_taller_id) if csv_taller_id else None

                if not dep_id:
                    print(f"Warning: Departamento {dep_pcode} no encontrado para artista {nombre_comp}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.artista_artesano 
                        (codigo, nombre_completo, genero, fecha_nacimiento, departamento_id, municipio_id, taller_id, especialidad_principal, reconocimientos, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_artista;
                    """,
                    (codigo, nombre_comp, genero, fecha_nac, dep_id, muni_id, taller_db_id, esp_princ, reco, carga.id)
                )
                db_id = cur.fetchone()[0]
                artista_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 6. OBRA ARTE ARTESANIA ---
        print("Cargando obras de arte y artesanía...")
        with csv_obra.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_obra"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                csv_tipo_id = int(fila["tipo_obra_id"])
                csv_art_id = int(fila["artista_id"]) if fila["artista_id"] else None
                csv_taller_id = int(fila["taller_id"]) if fila["taller_id"] else None
                desc = fila["descripcion"].strip()
                dias_creacion = int(fila["tiempo_estimado_creacion_dias"]) if fila["tiempo_estimado_creacion_dias"] else None
                precio = float(fila["precio_sugerido_q"]) if fila["precio_sugerido_q"] else None

                tipo_db_id = tipo_obra_csv_map.get(csv_tipo_id)
                art_db_id = artista_map.get(csv_art_id) if csv_art_id else None
                taller_db_id = taller_map.get(csv_taller_id) if csv_taller_id else None

                if not tipo_db_id:
                    print(f"Warning: Tipo de obra CSV ID {csv_tipo_id} no encontrado para obra {nombre}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.obra_arte_artesania 
                        (codigo, nombre, tipo_obra_id, artista_id, taller_id, descripcion, tiempo_estimado_creacion_dias, precio_sugerido_q, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_obra;
                    """,
                    (codigo, nombre, tipo_db_id, art_db_id, taller_db_id, desc, dias_creacion, precio, carga.id)
                )
                db_id = cur.fetchone()[0]
                obra_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 7. OBRA TECNICA ---
        print("Cargando relaciones de obras y técnicas...")
        with csv_obra_tecnica.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_obra_id = int(fila["obra_id"])
                csv_tec_id = int(fila["tecnica_id"])

                db_obra_id = obra_map.get(csv_obra_id)
                db_tec_id = tecnica_map.get(csv_tec_id)

                if not db_obra_id or not db_tec_id:
                    print(f"Warning: Obra CSV ID {csv_obra_id} o Técnica CSV ID {csv_tec_id} no encontrados. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.obra_tecnica (obra_id, tecnica_id, carga_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (obra_id, tecnica_id) DO NOTHING;
                    """,
                    (db_obra_id, db_tec_id, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 8. OBRA MATERIAL ---
        print("Cargando relaciones de obras y materiales...")
        with csv_obra_material.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_obra_id = int(fila["obra_id"])
                csv_mat_id = int(fila["material_id"])
                prop = float(fila["proporcion_estimada"]) if fila["proporcion_estimada"] else None

                db_obra_id = obra_map.get(csv_obra_id)
                db_mat_id = material_map.get(csv_mat_id)

                if not db_obra_id or not db_mat_id:
                    print(f"Warning: Obra CSV ID {csv_obra_id} o Material CSV ID {csv_mat_id} no encontrados. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.obra_material (obra_id, material_id, proporcion_estimada, carga_id)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (obra_id, material_id) DO UPDATE SET
                        proporcion_estimada = EXCLUDED.proporcion_estimada,
                        carga_id = EXCLUDED.carga_id;
                    """,
                    (db_obra_id, db_mat_id, prop, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 9. PRODUCCION ARTESANAL MUNICIPAL ---
        print("Cargando estadísticas de producción artesanal municipal...")
        with csv_produccion.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                dep_pcode = fila["departamento_pcode"].strip()
                muni_pcode = fila["municipio_pcode"].strip()
                csv_tipo_id = int(fila["tipo_obra_id"])
                anio = int(fila["anio"])
                volumen = int(fila["volumen_estimado_unidades"])
                valor = float(fila["valor_estimado_mercado_q"])
                artesanos = int(fila["cantidad_artesanos_activos"])

                dep_id = dep_id_map.get(dep_pcode)
                muni_id = muni_id_map.get(muni_pcode)
                tipo_db_id = tipo_obra_csv_map.get(csv_tipo_id)

                if not dep_id or not muni_id or not tipo_db_id:
                    print(f"Warning: Datos de geografía/tipo inválidos para producción de {muni_pcode}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.produccion_artesanal_municipal 
                        (departamento_id, municipio_id, tipo_obra_id, anio, volumen_estimado_unidades, valor_estimado_mercado_q, cantidad_artesanos_activos, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (municipio_id, tipo_obra_id, anio) DO UPDATE SET
                        volumen_estimado_unidades = EXCLUDED.volumen_estimado_unidades,
                        valor_estimado_mercado_q = EXCLUDED.valor_estimado_mercado_q,
                        cantidad_artesanos_activos = EXCLUDED.cantidad_artesanos_activos,
                        carga_id = EXCLUDED.carga_id;
                    """,
                    (dep_id, muni_id, tipo_db_id, anio, volumen, valor, artesanos, carga.id)
                )
                carga.filas_insertadas += 1

        # --- 10. EVENTO EXPOSICION ARTE ---
        print("Cargando exposiciones y eventos de arte...")
        with csv_evento.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_id = int(fila["id_evento"])
                codigo = fila["codigo"].strip()
                nombre = fila["nombre"].strip()
                fecha_ini = fila["fecha_inicio"].strip()
                fecha_fin = fila["fecha_fin"].strip()
                dep_pcode = fila["departamento_pcode"].strip()
                muni_pcode = fila["municipio_pcode"].strip()
                lugar = fila["lugar_detallado"].strip() or None
                org = fila["organizador"].strip() or None

                dep_id = dep_id_map.get(dep_pcode)
                muni_id = muni_id_map.get(muni_pcode)

                if not dep_id:
                    print(f"Warning: Departamento {dep_pcode} no encontrado para evento {nombre}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.evento_exposicion_arte 
                        (codigo, nombre, fecha_inicio, fecha_fin, departamento_id, municipio_id, lugar_detallado, organizador, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_evento;
                    """,
                    (codigo, nombre, fecha_ini, fecha_fin, dep_id, muni_id, lugar, org, carga.id)
                )
                db_id = cur.fetchone()[0]
                evento_map[csv_id] = db_id
                carga.filas_insertadas += 1

        # --- 11. PARTICIPANTE EVENTO ---
        print("Cargando participaciones en eventos...")
        with csv_participante.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                csv_evt_id = int(fila["evento_id"])
                csv_art_id = int(fila["artista_id"]) if fila["artista_id"] else None
                csv_taller_id = int(fila["taller_id"]) if fila["taller_id"] else None
                premio = fila["premio_reconocimiento"].strip() or None

                db_evt_id = evento_map.get(csv_evt_id)
                db_art_id = artista_map.get(csv_art_id) if csv_art_id else None
                db_taller_id = taller_map.get(csv_taller_id) if csv_taller_id else None

                if not db_evt_id or (not db_art_id and not db_taller_id):
                    print(f"Warning: Datos inválidos para participación en evento CSV ID {csv_evt_id}. Saltando...")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO artesania.participante_evento (evento_id, artista_id, taller_id, premio_reconocimiento, carga_id)
                    VALUES (%s, %s, %s, %s, %s);
                    """,
                    (db_evt_id, db_art_id, db_taller_id, premio, carga.id)
                )
                carga.filas_insertadas += 1

        print("¡ETL del módulo de Arte y Artesanía completado exitosamente!")

if __name__ == "__main__":
    main()
