#!/usr/bin/env python3
"""
ETL para el módulo de Cultura e Identidad.
Carga datos de gastronomía, idiomas mayas y festividades en sus respectivas tablas del esquema `cultura`.

Ejecutable por su cuenta:
    python etl/python/cultura/20260704191000_load_cultura.py
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
    """Ubica la carpeta data/cultura en la raíz del repo."""
    for parent in Path(__file__).resolve().parents:
        cand = parent / "data" / "cultura"
        if cand.exists():
            return cand
    raise FileNotFoundError("No se encontró data/cultura en la raíz del repo.")


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
    csv_ingredientes = data_dir / "ingredientes.csv"
    csv_platos = data_dir / "platos_tipicos.csv"
    csv_plato_ingredientes = data_dir / "plato_ingredientes.csv"
    csv_idiomas = data_dir / "idiomas.csv"
    csv_idiomas_mun = data_dir / "idiomas_municipios.csv"
    csv_eventos = data_dir / "eventos.csv"

    # Usamos el principal para el registro, y calculamos un hash combinado para las notas
    hash_combinado = _calcular_hash(csv_platos)

    print(f"Iniciando ETL de Cultura. Insumos en: {data_dir}")

    # Registramos la carga en meta.carga
    with registrar_carga(
        codigo_fuente="2026_07_gtm_cultura_identidad",
        archivo="data/cultura/",
        hash_archivo=hash_combinado,
        nombre_script="cultura/20260704191000_load_cultura.py"
    ) as carga:

        cur = carga.cur

        # --- 1. CARGA DE INGREDIENTES ---
        print("Cargando ingredientes autóctonos...")
        ingrediente_id_map = {}
        with csv_ingredientes.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                desc = fila["descripcion"].strip() or None
                origen = fila["origen_prehispanico"].strip().lower() == "true"

                cur.execute(
                    """
                    INSERT INTO cultura.ingrediente_autoctono (nombre, descripcion, origen_prehispanico, carga_id)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        descripcion = EXCLUDED.descripcion,
                        origen_prehispanico = EXCLUDED.origen_prehispanico,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, desc, origen, carga.id)
                )
                ing_id = cur.fetchone()[0]
                ingrediente_id_map[nombre] = ing_id
                carga.filas_insertadas += 1

        # --- 2. CARGA DE PLATOS TÍPICOS ---
        print("Cargando platillos típicos...")
        plato_id_map = {}
        with csv_platos.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                desc = fila["descripcion"].strip() or None
                historia = fila["historia_origen"].strip() or None
                patrimonio = fila["es_patrimonio"].strip().lower() == "true"
                depto_pcode = fila["departamento_pcode"].strip() or None
                mun_pcode = fila["municipio_pcode"].strip() or None

                # Insertar en tabla base
                cur.execute(
                    """
                    INSERT INTO cultura.plato_tipico (nombre, descripcion, historia_origen, es_patrimonio, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        descripcion = EXCLUDED.descripcion,
                        historia_origen = EXCLUDED.historia_origen,
                        es_patrimonio = EXCLUDED.es_patrimonio,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, desc, historia, patrimonio, carga.id)
                )
                plato_id = cur.fetchone()[0]
                plato_id_map[nombre] = plato_id
                carga.filas_insertadas += 1

                # Relacionar geográficamente si tiene departamento
                if depto_pcode:
                    cur.execute("SELECT id FROM geografia.departamento WHERE pcode = %s", (depto_pcode,))
                    row_depto = cur.fetchone()
                    if not row_depto:
                        raise ValueError(f"No se encontró departamento con pcode '{depto_pcode}' para plato '{nombre}'")
                    depto_id = row_depto[0]

                    mun_id = None
                    if mun_pcode:
                        cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                        row_mun = cur.fetchone()
                        if not row_mun:
                            raise ValueError(f"No se encontró municipio con pcode '{mun_pcode}' para plato '{nombre}'")
                        mun_id = row_mun[0]

                    cur.execute(
                        """
                        INSERT INTO cultura.plato_geografia (plato_id, departamento_id, municipio_id)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (plato_id, departamento_id) DO UPDATE SET
                            municipio_id = EXCLUDED.municipio_id
                        """,
                        (plato_id, depto_id, mun_id)
                    )

        # --- 3. RELACIÓN PLATO - INGREDIENTE ---
        print("Estableciendo relaciones plato-ingrediente...")
        with csv_plato_ingredientes.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                plato_nombre = fila["plato_nombre"].strip()
                ingrediente_nombre = fila["ingrediente_nombre"].strip()

                plato_id = plato_id_map.get(plato_nombre)
                ingrediente_id = ingrediente_id_map.get(ingrediente_nombre)

                if not plato_id or not ingrediente_id:
                    print(f"Warning: Plato o Ingrediente no encontrado para la relación: {plato_nombre} - {ingrediente_nombre}")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute(
                    """
                    INSERT INTO cultura.plato_ingrediente (plato_id, ingrediente_id)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (plato_id, ingrediente_id)
                )
                carga.filas_insertadas += 1

        # --- 4. CARGA DE IDIOMAS ---
        print("Cargando idiomas y lenguas nacionales...")
        idioma_id_map = {}
        with csv_idiomas.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                familia = fila["familia_linguistica"].strip() or None
                vitalidad = fila["estado_vitalidad"].strip() or None
                desc = fila["descripcion"].strip() or None

                cur.execute(
                    """
                    INSERT INTO cultura.idioma (nombre, familia_linguistica, estado_vitalidad, descripcion, carga_id)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        familia_linguistica = EXCLUDED.familia_linguistica,
                        estado_vitalidad = EXCLUDED.estado_vitalidad,
                        descripcion = EXCLUDED.descripcion,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, familia, vitalidad, desc, carga.id)
                )
                idioma_id = cur.fetchone()[0]
                idioma_id_map[nombre] = idioma_id
                carga.filas_insertadas += 1

        # --- 5. RELACIÓN IDIOMA - MUNICIPIO ---
        print("Estableciendo distribución geográfica de idiomas...")
        with csv_idiomas_mun.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                idioma_nombre = fila["idioma_nombre"].strip()
                mun_pcode = fila["municipio_pcode"].strip()
                es_predominante = fila["es_predominante"].strip().lower() == "true"

                idioma_id = idioma_id_map.get(idioma_nombre)
                if not idioma_id:
                    print(f"Warning: Idioma '{idioma_nombre}' no encontrado.")
                    carga.filas_rechazadas += 1
                    continue

                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado.")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO cultura.idioma_municipio (idioma_id, municipio_id, es_predominante)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (idioma_id, municipio_id) DO UPDATE SET
                        es_predominante = EXCLUDED.es_predominante
                    """,
                    (idioma_id, mun_id, es_predominante)
                )
                carga.filas_insertadas += 1

        # --- 6. CARGA DE EVENTOS Y FESTIVALES ---
        print("Cargando celebraciones y ferias patronales...")
        with csv_eventos.open(encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for fila in reader:
                carga.filas_procesadas += 1
                nombre = fila["nombre"].strip()
                tipo = fila["tipo_evento"].strip() or None
                mes = int(fila["mes_celebracion"].strip())
                dia_ini = int(fila["dia_inicio"].strip())
                dia_fin = int(fila["dia_fin"].strip())
                desc = fila["descripcion"].strip() or None
                viaje = fila["recomendaciones_viaje"].strip() or None
                mun_pcode = fila["municipio_pcode"].strip()

                cur.execute(
                    """
                    INSERT INTO cultura.evento_cultural 
                        (nombre, tipo_evento, mes_celebracion, dia_inicio, dia_fin, descripcion, recomendaciones_viaje, carga_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (nombre) DO UPDATE SET
                        tipo_evento = EXCLUDED.tipo_evento,
                        mes_celebracion = EXCLUDED.mes_celebracion,
                        dia_inicio = EXCLUDED.dia_inicio,
                        dia_fin = EXCLUDED.dia_fin,
                        descripcion = EXCLUDED.descripcion,
                        recomendaciones_viaje = EXCLUDED.recomendaciones_viaje,
                        carga_id = EXCLUDED.carga_id
                    RETURNING id
                    """,
                    (nombre, tipo, mes, dia_ini, dia_fin, desc, viaje, carga.id)
                )
                evento_id = cur.fetchone()[0]
                carga.filas_insertadas += 1

                # Relación con el municipio del evento
                cur.execute("SELECT id FROM geografia.municipio WHERE pcode = %s", (mun_pcode,))
                row_mun = cur.fetchone()
                if not row_mun:
                    print(f"Warning: Municipio con pcode '{mun_pcode}' no encontrado para evento '{nombre}'.")
                    carga.filas_rechazadas += 1
                    continue
                mun_id = row_mun[0]

                cur.execute(
                    """
                    INSERT INTO cultura.evento_municipio (evento_id, municipio_id)
                    VALUES (%s, %s)
                    ON CONFLICT (evento_id, municipio_id) DO NOTHING
                    """,
                    (evento_id, mun_id)
                )

        print("ETL del módulo de Cultura finalizado con éxito.")

    print(f"Proceso concluido: {carga.filas_procesadas} filas leídas, {carga.filas_insertadas} insertadas.")


if __name__ == "__main__":
    main()
