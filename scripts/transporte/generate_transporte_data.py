#!/usr/bin/env python3
"""
Generador de Datos de Prueba para el módulo de Logística, Transporte y Conectividad Vial.
Genera 9 archivos CSV en la carpeta data/transporte/ asegurando un volumen superior a 1,000 registros.
"""

import os
import csv
import random
import psycopg2
from datetime import datetime, time
from pathlib import Path

def main():
    db_url = "postgresql://postgres:postgres@localhost:5432/bd_nacional"
    print(f"Conectando a la base de datos en: {db_url}")
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        return

    # 1. Obtener municipios y sus departamentos (Altiplano Occidental)
    # Departamentos: Quetzaltenango, Totonicapán, San Marcos, Huehuetenango, El Quiché, Sololá
    cur.execute("""
        SELECT m.id, m.nombre, d.nombre, d.pcode
        FROM geografia.municipio m
        JOIN geografia.departamento d ON d.id = m.departamento_id
        ORDER BY m.id;
    """)
    municipios = cur.fetchall()
    print(f"Municipios de Guatemala cargados: {len(municipios)}")

    # 2. Obtener todos los destinos turísticos activos
    cur.execute("""
        SELECT id_destino, nombre, municipio_id
        FROM turismo.destino_turistico
        WHERE activo = TRUE
        ORDER BY id_destino;
    """)
    destinos = cur.fetchall()
    print(f"Destinos turísticos activos cargados: {len(destinos)}")

    cur.close()
    conn.close()

    if not municipios:
        print("Error: No se encontraron municipios del Altiplano en la base de datos.")
        return

    output_dir = Path("data/transporte")
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Carpeta de salida: {output_dir.resolve()}")

    # Nombres para simular
    nombres_propios = ["Juan", "Pedro", "María", "Carlos", "José", "Luisa", "Manuel", "Diego", "Francisco", "Juana", "Tomasa", "Miguel", "Esteban", "Rosa", "Elena"]
    apellidos_locales = ["Yax", "Tzoc", "Chaj", "Jax", "Cox", "Batz", "Tzul", "Guzmán", "Marroquín", "Cabrera", "Méndez", "Pérez", "Hernández", "López", "Gómez"]
    
    base_proveedores = ["Transportes", "Autobuses", "Lancheros Unidos", "Fleteros del Altiplano", "Cooperativa de Transportistas", "Rápidos de Occidente", "Shuttles", "Taxis del Centro"]

    # 1. tipo_transporte.csv
    print("Generando tipo_transporte.csv...")
    tipos_transporte = [
        {"codigo": "TUC_TUC", "nombre": "Tuc-tuc", "descripcion": "Mototaxi local para traslados cortos de pasajeros dentro del municipio."},
        {"codigo": "EXTRAURBANO", "nombre": "Autobús extraurbano", "descripcion": "Autobús de parrilla tradicional (chicken bus) para rutas intermunicipales."},
        {"codigo": "LANCHA", "nombre": "Lancha colectiva", "descripcion": "Transporte acuático en lanchas compartidas para destinos alrededor de lagos (ej. Atitlán)."},
        {"codigo": "FLETERO", "nombre": "Microbús / Fletero", "descripcion": "Microbús rápido para trayectos rotativos intercomunitarios."},
        {"codigo": "SHUTTLE", "nombre": "Shuttle turístico", "descripcion": "Transporte privado o compartido con aire acondicionado ideal para turistas."},
        {"codigo": "TAXI", "nombre": "Taxi local", "descripcion": "Servicio de transporte privado individual en vehículo sedán."}
    ]
    with open(output_dir / "tipo_transporte.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "nombre", "descripcion"])
        writer.writeheader()
        writer.writerows(tipos_transporte)

    # 2. proveedor_transporte.csv (1020 registros)
    print("Generando proveedor_transporte.csv...")
    proveedores = []
    for i in range(1020):
        muni = municipios[i % len(municipios)]
        base = base_proveedores[i % len(base_proveedores)]
        nombre = f"{base} {muni[1]} - Ref {i+1}"
        codigo = f"PROV_{muni[3]}_{i:04d}"
        repre = f"{random.choice(nombres_propios)} {random.choice(apellidos_locales)}"
        contacto = f"+502 {random.randint(4000, 5999)}{random.randint(1000, 9999)}"
        proveedores.append({
            "codigo": codigo,
            "nombre": nombre,
            "representante": repre,
            "contacto": contacto,
            "departamento_nombre": muni[2],
            "municipio_nombre": muni[1]
        })
    with open(output_dir / "proveedor_transporte.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "nombre", "representante", "contacto", "departamento_nombre", "municipio_nombre"])
        writer.writeheader()
        writer.writerows(proveedores)

    # 3. ruta_transporte.csv (1020 registros)
    print("Generando ruta_transporte.csv...")
    rutas = []
    for i in range(1020):
        muni_orig = municipios[i % len(municipios)]
        muni_dest = municipios[(i + 47) % len(municipios)]
        
        # Si son municipios del lago Atitlán, podemos usar lancha, si no, otros
        es_lago = ("Sololá" in [muni_orig[2], muni_dest[2]] and 
                   any(x in muni_orig[1].lower() or x in muni_dest[1].lower() for x in ["panajachel", "pedro", "marcos", "santiago", "lucas", "cruz"]))
        
        if es_lago and random.random() > 0.3:
            tipo_cod = "LANCHA"
        else:
            tipo_cod = random.choice(["EXTRAURBANO", "FLETERO", "SHUTTLE", "TAXI"])

        codigo = f"RUT_{muni_orig[0]}_{muni_dest[0]}_{i:04d}"
        rutas.append({
            "codigo": codigo,
            "origen_municipio_nombre": muni_orig[1],
            "destino_municipio_nombre": muni_dest[1],
            "tipo_transporte_codigo": tipo_cod
        })
    with open(output_dir / "ruta_transporte.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "origen_municipio_nombre", "destino_municipio_nombre", "tipo_transporte_codigo"])
        writer.writeheader()
        writer.writerows(rutas)

    # 4. itinerario_transporte.csv (1020 registros)
    print("Generando itinerario_transporte.csv...")
    itinerarios = []
    frecuencias = ["Diario", "Cada 30 minutos", "Cada hora", "Lunes a Viernes", "Solo fines de semana", "Cada 15 minutos"]
    for i in range(1020):
        ruta = rutas[i % len(rutas)]
        prov = proveedores[(i + 9) % len(proveedores)]
        
        h = 5 + (i % 14) # Horarios de 5:00 a 19:00
        m = (i * 15) % 60
        hora_salida = f"{h:02d}:{m:02d}:00"
        
        frec = frecuencias[i % len(frecuencias)]
        tarifa = round(random.uniform(5.00, 150.00), 2)
        duracion = random.randint(15, 240) # duración en minutos

        itinerarios.append({
            "ruta_transporte_codigo": ruta["codigo"],
            "proveedor_codigo": prov["codigo"],
            "hora_salida": hora_salida,
            "frecuencia": frec,
            "tarifa_q": tarifa,
            "duracion_estimada_minutos": duracion
        })
    with open(output_dir / "itinerario_transporte.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["ruta_transporte_codigo", "proveedor_codigo", "hora_salida", "frecuencia", "tarifa_q", "duracion_estimada_minutos"])
        writer.writeheader()
        writer.writerows(itinerarios)

    # 5. tipo_via.csv
    print("Generando tipo_via.csv...")
    tipos_via = [
        {"codigo": "INTERAMERICANA", "nombre": "Carretera Interamericana (CA-1)", "descripcion": "Carretera principal asfaltada de alta velocidad de 2 o 4 carriles."},
        {"codigo": "NACIONAL_ASFALTO", "nombre": "Ruta Nacional Asfaltada", "descripcion": "Vías de conexión asfaltadas de dos carriles."},
        {"codigo": "TERRACERIA", "nombre": "Camino de terracería", "descripcion": "Vías de tierra y balastro. Sujetas a afectaciones climáticas."},
        {"codigo": "ACUATICA", "nombre": "Vía Fluvial / Lacustre", "descripcion": "Rutas de navegación acuática en lancha o transbordador."},
        {"codigo": "PEATONAL", "nombre": "Sendero Peatonal", "descripcion": "Caminos rurales transitables únicamente a pie o a caballo."}
    ]
    with open(output_dir / "tipo_via.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "nombre", "descripcion"])
        writer.writeheader()
        writer.writerows(tipos_via)

    # 6. tramo_vial.csv (1020 registros)
    print("Generando tramo_vial.csv...")
    tramos = []
    carreteras_locales = ["Ruta Nacional RN-1", "RN-15 Sacapulas", "RN-9 Salcajá", "RN-7 Cobán-Quiché", "CA-1 Occidente", "RN-11 Panajachel"]
    estados = ["BUENO", "REGULAR", "MALO", "BLOQUEADO"]
    for i in range(1020):
        muni_orig = municipios[i % len(municipios)]
        muni_dest = municipios[(i + 31) % len(municipios)]
        via = random.choice(tipos_via)
        
        nombre = f"Tramo {random.choice(carreteras_locales)} ({muni_orig[1]} - {muni_dest[1]}) - Ref {i+1}"
        codigo = f"TRM_{muni_orig[0]}_{muni_dest[0]}_{i:04d}"
        distancia = round(random.uniform(5.0, 75.0), 2)
        tiempo = int(distancia * random.uniform(1.2, 3.5)) # Más lento para terracería/cerros
        
        # Distribución de estados (mayoría Bueno y Regular)
        estado = random.choices(estados, weights=[70, 20, 8, 2], k=1)[0]

        tramos.append({
            "codigo": codigo,
            "nombre": nombre,
            "origen_municipio_nombre": muni_orig[1],
            "destino_municipio_nombre": muni_dest[1],
            "tipo_via_codigo": via["codigo"],
            "distancia_km": distancia,
            "tiempo_promedio_minutos": max(5, tiempo),
            "estado_transitabilidad": estado
        })
    with open(output_dir / "tramo_vial.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "nombre", "origen_municipio_nombre", "destino_municipio_nombre", "tipo_via_codigo", "distancia_km", "tiempo_promedio_minutos", "estado_transitabilidad"])
        writer.writeheader()
        writer.writerows(tramos)

    # 7. incidencia_vial.csv (1020 registros)
    print("Generando incidencia_vial.csv...")
    incidencias = []
    tipos_incidencia = ["Derrumbe activo", "Bloqueo de carreteras por manifestación", "Trabajos de bacheo", "Accidente vial obstruyendo carril", "Fuerte neblina y lluvias", "Inundación por desborde de río"]
    for i in range(1020):
        tramo = tramos[i % len(tramos)]
        codigo = f"INC_{i:04d}"
        tipo_inc = tipos_incidencia[i % len(tipos_incidencia)]
        desc = f"Reporte de {tipo_inc} en el tramo {tramo['nombre']}. Tomar precauciones o vías alternas."
        
        h = random.randint(1, 23)
        fecha_rep = f"2026-07-06 {h:02d}:30:00"
        activo = random.choice(["true", "false"])

        incidencias.append({
            "codigo": codigo,
            "tramo_codigo": tramo["codigo"],
            "tipo_incidencia": tipo_inc.split(" ")[0],
            "descripcion": desc,
            "fecha_reporte": fecha_rep,
            "activo": activo
        })
    with open(output_dir / "incidencia_vial.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["codigo", "tramo_codigo", "tipo_incidencia", "descripcion", "fecha_reporte", "activo"])
        writer.writeheader()
        writer.writerows(incidencias)

    # 8. destino_transporte.csv (1020 registros)
    print("Generando destino_transporte.csv...")
    destino_transportes = []
    
    # Si no hay destinos en base de datos, usamos destinos predefinidos para simulación
    if not destinos:
        destinos = [(1, "Lago de Atitlán"), (2, "Fuentes Georginas"), (3, "Biotopo del Quetzal"), (4, "Ruinas de Zaculeu"), (5, "Mercado de Chichicastenango")]

    # Generamos 1,020 combinaciones vinculando destinos con los tipos de transporte
    for i in range(1020):
        dest = destinos[i % len(destinos)]
        tipo = tipos_transporte[i % len(tipos_transporte)]
        
        dest_nombre = dest[1]
        parada = f"Estación Central de {tipo['nombre']} cerca de {dest_nombre} - Ref {i+1}"
        distancia = round(random.uniform(0.5, 15.0), 2)
        costo = round(random.uniform(5.00, 50.00), 2)
        tiempo = int(distancia * random.uniform(2.5, 5.0)) # en minutos

        destino_transportes.append({
            "destino_nombre": dest_nombre,
            "parada_cercana": parada,
            "tipo_transporte_codigo": tipo["codigo"],
            "distancia_parada_km": distancia,
            "costo_traslado_local_q": costo,
            "tiempo_traslado_minutos": max(2, tiempo)
        })
    with open(output_dir / "destino_transporte.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["destino_nombre", "parada_cercana", "tipo_transporte_codigo", "distancia_parada_km", "costo_traslado_local_q", "tiempo_traslado_minutos"])
        writer.writeheader()
        writer.writerows(destino_transportes)

    # 9. conexion_municipal.csv (480 registros - 160 municipios * 3 vehículos)
    # Genera la matriz para los 160 municipios del altiplano, para cada uno de los 3 vehículos
    print("Generando conexion_municipal.csv...")
    conexiones = []
    vehiculos = ["LIVIANO", "PESADO", "AUTOBUS"]
    for muni in municipios:
        for veh in vehiculos:
            dist_cab = round(random.uniform(2.0, 95.0), 2)
            time_cab = int(dist_cab * random.uniform(1.1, 2.5)) # minutos
            
            dist_cap = round(random.uniform(110.0, 310.0), 2)
            time_cap = int(dist_cap * random.uniform(1.8, 3.5)) # minutos
            
            # Ajuste según tipo de vehículo (pesado y autobús son más lentos)
            if veh == "PESADO":
                time_cab = int(time_cab * 1.5)
                time_cap = int(time_cap * 1.6)
            elif veh == "AUTOBUS":
                time_cab = int(time_cab * 1.3)
                time_cap = int(time_cap * 1.4)

            conexiones.append({
                "municipio_nombre": muni[1],
                "tipo_vehiculo": veh,
                "distancia_cabecera_km": dist_cab,
                "tiempo_cabecera_minutos": max(5, time_cab),
                "distancia_capital_km": dist_cap,
                "tiempo_capital_minutos": max(60, time_cap)
            })
    with open(output_dir / "conexion_municipal.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["municipio_nombre", "tipo_vehiculo", "distancia_cabecera_km", "tiempo_cabecera_minutos", "distancia_capital_km", "tiempo_capital_minutos"])
        writer.writeheader()
        writer.writerows(conexiones)

    print("¡Todos los 9 archivos CSV para el módulo de transporte generados exitosamente!")

if __name__ == "__main__":
    main()
