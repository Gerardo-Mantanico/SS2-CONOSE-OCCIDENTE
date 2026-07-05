-- ============================================================
-- Flyway migration: V20260705112500__crear_funciones_etl_bi_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: crear funciones ETL/ELT para cargar dimensiones, hechos y validar calidad
-- ============================================================


CREATE OR REPLACE FUNCTION turismo.fn_etl_id_fecha_actual()
RETURNS INT
LANGUAGE SQL
AS $$
  SELECT TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INT;
$$;

CREATE OR REPLACE FUNCTION turismo.fn_etl_iniciar_job(p_nombre_job VARCHAR, p_mensaje TEXT DEFAULT NULL)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_job INT;
  v_id_ejecucion BIGINT;
BEGIN
  SELECT id_job INTO v_id_job
  FROM turismo.etl_job
  WHERE nombre = p_nombre_job;

  IF v_id_job IS NULL THEN
    INSERT INTO turismo.etl_job(nombre, descripcion, frecuencia_sugerida)
    VALUES (p_nombre_job, 'Job creado automaticamente por funcion ETL.', 'Bajo demanda')
    RETURNING id_job INTO v_id_job;
  END IF;

  INSERT INTO turismo.etl_ejecucion(id_job, estado, mensaje)
  VALUES (v_id_job, 'INICIADO', p_mensaje)
  RETURNING id_ejecucion INTO v_id_ejecucion;

  RETURN v_id_ejecucion;
END;
$$;

CREATE OR REPLACE FUNCTION turismo.fn_etl_finalizar_job(
  p_id_ejecucion BIGINT,
  p_estado VARCHAR,
  p_filas_insertadas BIGINT DEFAULT 0,
  p_filas_actualizadas BIGINT DEFAULT 0,
  p_filas_error BIGINT DEFAULT 0,
  p_mensaje TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE turismo.etl_ejecucion
  SET fecha_fin = NOW(),
      estado = p_estado,
      filas_insertadas = COALESCE(p_filas_insertadas,0),
      filas_actualizadas = COALESCE(p_filas_actualizadas,0),
      filas_error = COALESCE(p_filas_error,0),
      mensaje = p_mensaje
  WHERE id_ejecucion = p_id_ejecucion;
END;
$$;

CREATE OR REPLACE FUNCTION turismo.sp_etl_validar_calidad(p_id_ejecucion BIGINT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO turismo.etl_validacion(id_ejecucion, entidad, regla, nivel, total_registros, total_observaciones, detalle)
  SELECT p_id_ejecucion, 'destino', 'Destino sin fuente principal', 'ADVERTENCIA', COUNT(*), COUNT(*),
         'Todo destino deberia tener una fuente principal para trazabilidad.'
  FROM turismo.destino
  WHERE id_fuente_principal IS NULL;

  INSERT INTO turismo.etl_validacion(id_ejecucion, entidad, regla, nivel, total_registros, total_observaciones, detalle)
  SELECT p_id_ejecucion, 'destino', 'Destino sin coordenadas', 'INFO', (SELECT COUNT(*) FROM turismo.destino), COUNT(*),
         'Las coordenadas mejoran mapas y analitica geografica.'
  FROM turismo.destino
  WHERE latitud IS NULL OR longitud IS NULL;

  INSERT INTO turismo.etl_validacion(id_ejecucion, entidad, regla, nivel, total_registros, total_observaciones, detalle)
  SELECT p_id_ejecucion, 'destino_categoria', 'Destino sin categoria', 'ERROR', (SELECT COUNT(*) FROM turismo.destino), COUNT(*),
         'Todo destino debe tener al menos una categoria para analitica.'
  FROM turismo.destino d
  WHERE NOT EXISTS (SELECT 1 FROM turismo.destino_categoria dc WHERE dc.id_destino = d.id_destino);

  INSERT INTO turismo.etl_validacion(id_ejecucion, entidad, regla, nivel, total_registros, total_observaciones, detalle)
  SELECT p_id_ejecucion, 'destino_actividad', 'Destino sin actividad', 'ADVERTENCIA', (SELECT COUNT(*) FROM turismo.destino), COUNT(*),
         'Las actividades permiten recomendaciones y segmentacion de turistas.'
  FROM turismo.destino d
  WHERE NOT EXISTS (SELECT 1 FROM turismo.destino_actividad da WHERE da.id_destino = d.id_destino);

  INSERT INTO turismo.etl_validacion(id_ejecucion, entidad, regla, nivel, total_registros, total_observaciones, detalle)
  SELECT p_id_ejecucion, 'fuente', 'URL duplicada en fuentes', 'ADVERTENCIA', COUNT(*), COUNT(*) - COUNT(DISTINCT url),
         'Revisar URLs repetidas para evitar duplicidad de referencias.'
  FROM turismo.fuente
  HAVING COUNT(*) - COUNT(DISTINCT url) > 0;
END;
$$;

CREATE OR REPLACE FUNCTION turismo.sp_etl_cargar_dimensiones()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO turismo.dim_fuente(id_fuente, nombre, tipo, url, fecha_consulta, notas, fecha_carga_dw)
  SELECT id_fuente, nombre, tipo, url, fecha_consulta, notas, NOW()
  FROM turismo.fuente
  ON CONFLICT (id_fuente) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    tipo = EXCLUDED.tipo,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    notas = EXCLUDED.notas,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_region(id_region, nombre, descripcion, id_fuente, fecha_carga_dw)
  SELECT id_region, nombre, descripcion, id_fuente, NOW()
  FROM turismo.region_turistica
  ON CONFLICT (id_region) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    id_fuente = EXCLUDED.id_fuente,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_departamento(id_departamento, codigo_ine, nombre, id_region, region_nombre, fecha_carga_dw)
  SELECT dep.id_departamento, dep.codigo_ine, dep.nombre, dep.id_region, r.nombre, NOW()
  FROM turismo.departamento dep
  JOIN turismo.region_turistica r ON r.id_region = dep.id_region
  ON CONFLICT (id_departamento) DO UPDATE SET
    codigo_ine = EXCLUDED.codigo_ine,
    nombre = EXCLUDED.nombre,
    id_region = EXCLUDED.id_region,
    region_nombre = EXCLUDED.region_nombre,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_municipio(id_municipio, id_departamento, departamento_nombre, nombre, fecha_carga_dw)
  SELECT m.id_municipio, m.id_departamento, dep.nombre, m.nombre, NOW()
  FROM turismo.municipio m
  JOIN turismo.departamento dep ON dep.id_departamento = m.id_departamento
  ON CONFLICT (id_municipio) DO UPDATE SET
    id_departamento = EXCLUDED.id_departamento,
    departamento_nombre = EXCLUDED.departamento_nombre,
    nombre = EXCLUDED.nombre,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_categoria(id_categoria, nombre, descripcion, fecha_carga_dw)
  SELECT id_categoria, nombre, descripcion, NOW()
  FROM turismo.categoria_destino
  ON CONFLICT (id_categoria) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_actividad(id_actividad, nombre, descripcion, fecha_carga_dw)
  SELECT id_actividad, nombre, descripcion, NOW()
  FROM turismo.actividad
  ON CONFLICT (id_actividad) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_temporada(id_temporada, nombre, meses, descripcion, fecha_carga_dw)
  SELECT id_temporada, nombre, meses, descripcion, NOW()
  FROM turismo.temporada
  ON CONFLICT (id_temporada) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    meses = EXCLUDED.meses,
    descripcion = EXCLUDED.descripcion,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_patrimonio(id_patrimonio, tipo, nombre, organismo, anio_inscripcion, descripcion, id_fuente, fecha_carga_dw)
  SELECT id_patrimonio, tipo::VARCHAR, nombre, organismo, anio_inscripcion, descripcion, id_fuente, NOW()
  FROM turismo.patrimonio
  ON CONFLICT (id_patrimonio) DO UPDATE SET
    tipo = EXCLUDED.tipo,
    nombre = EXCLUDED.nombre,
    organismo = EXCLUDED.organismo,
    anio_inscripcion = EXCLUDED.anio_inscripcion,
    descripcion = EXCLUDED.descripcion,
    id_fuente = EXCLUDED.id_fuente,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_ruta(id_ruta, id_region, region_nombre, nombre, descripcion, duracion_dias, id_fuente, fecha_carga_dw)
  SELECT rt.id_ruta, rt.id_region, r.nombre, rt.nombre, rt.descripcion, rt.duracion_dias, rt.id_fuente, NOW()
  FROM turismo.ruta_turistica rt
  LEFT JOIN turismo.region_turistica r ON r.id_region = rt.id_region
  ON CONFLICT (id_ruta) DO UPDATE SET
    id_region = EXCLUDED.id_region,
    region_nombre = EXCLUDED.region_nombre,
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    duracion_dias = EXCLUDED.duracion_dias,
    id_fuente = EXCLUDED.id_fuente,
    fecha_carga_dw = NOW();

  INSERT INTO turismo.dim_destino(
    id_destino, nombre, tipo, id_departamento, departamento_nombre, id_municipio, municipio_nombre,
    id_region, region_nombre, descripcion, direccion_referencia, latitud, longitud, altitud_msnm,
    dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario,
    es_area_protegida, id_fuente_principal, fuente_principal, url_fuente_principal, activo,
    checksum_origen, fecha_carga_dw
  )
  SELECT
    d.id_destino,
    d.nombre,
    d.tipo::VARCHAR,
    dep.id_departamento,
    dep.nombre,
    m.id_municipio,
    m.nombre,
    r.id_region,
    r.nombre,
    d.descripcion,
    d.direccion_referencia,
    d.latitud,
    d.longitud,
    d.altitud_msnm,
    d.dificultad::VARCHAR,
    d.tiempo_recomendado,
    d.costo_aprox_nacional_q,
    d.costo_aprox_extranjero_q,
    d.horario,
    d.es_area_protegida,
    d.id_fuente_principal,
    f.nombre,
    f.url,
    d.activo,
    MD5(CONCAT_WS('|', d.id_destino, d.nombre, d.tipo::VARCHAR, dep.nombre, COALESCE(m.nombre,''), r.nombre, COALESCE(d.latitud::TEXT,''), COALESCE(d.longitud::TEXT,''), d.activo::TEXT)),
    NOW()
  FROM turismo.destino d
  JOIN turismo.departamento dep ON dep.id_departamento = d.id_departamento
  JOIN turismo.region_turistica r ON r.id_region = dep.id_region
  LEFT JOIN turismo.municipio m ON m.id_municipio = d.id_municipio
  LEFT JOIN turismo.fuente f ON f.id_fuente = d.id_fuente_principal
  ON CONFLICT (id_destino) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    tipo = EXCLUDED.tipo,
    id_departamento = EXCLUDED.id_departamento,
    departamento_nombre = EXCLUDED.departamento_nombre,
    id_municipio = EXCLUDED.id_municipio,
    municipio_nombre = EXCLUDED.municipio_nombre,
    id_region = EXCLUDED.id_region,
    region_nombre = EXCLUDED.region_nombre,
    descripcion = EXCLUDED.descripcion,
    direccion_referencia = EXCLUDED.direccion_referencia,
    latitud = EXCLUDED.latitud,
    longitud = EXCLUDED.longitud,
    altitud_msnm = EXCLUDED.altitud_msnm,
    dificultad = EXCLUDED.dificultad,
    tiempo_recomendado = EXCLUDED.tiempo_recomendado,
    costo_aprox_nacional_q = EXCLUDED.costo_aprox_nacional_q,
    costo_aprox_extranjero_q = EXCLUDED.costo_aprox_extranjero_q,
    horario = EXCLUDED.horario,
    es_area_protegida = EXCLUDED.es_area_protegida,
    id_fuente_principal = EXCLUDED.id_fuente_principal,
    fuente_principal = EXCLUDED.fuente_principal,
    url_fuente_principal = EXCLUDED.url_fuente_principal,
    activo = EXCLUDED.activo,
    checksum_origen = EXCLUDED.checksum_origen,
    fecha_carga_dw = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION turismo.sp_etl_cargar_hechos()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_fecha INT := turismo.fn_etl_id_fecha_actual();
BEGIN
  WITH metricas AS (
    SELECT
      d.id_destino,
      COUNT(DISTINCT dc.id_categoria)::INT AS total_categorias,
      COUNT(DISTINCT da.id_actividad)::INT AS total_actividades,
      COUNT(DISTINCT dt.id_temporada)::INT AS total_temporadas,
      COUNT(DISTINCT fd.id_fuente)::INT AS total_fuentes,
      COUNT(DISTINCT rd2.id_recomendacion)::INT AS total_recomendaciones,
      COUNT(DISTINCT dp.id_patrimonio)::INT AS total_patrimonios
    FROM turismo.destino d
    LEFT JOIN turismo.destino_categoria dc ON dc.id_destino = d.id_destino
    LEFT JOIN turismo.destino_actividad da ON da.id_destino = d.id_destino
    LEFT JOIN turismo.destino_temporada dt ON dt.id_destino = d.id_destino
    LEFT JOIN turismo.fuente_destino fd ON fd.id_destino = d.id_destino
    LEFT JOIN turismo.recomendacion_destino rd2 ON rd2.id_destino = d.id_destino
    LEFT JOIN turismo.destino_patrimonio dp ON dp.id_destino = d.id_destino
    GROUP BY d.id_destino
  )
  INSERT INTO turismo.fact_destino_catalogo(
    id_fecha_carga, id_destino, id_region, id_departamento, id_municipio, tipo, dificultad,
    total_categorias, total_actividades, total_temporadas, total_fuentes, total_recomendaciones,
    tiene_patrimonio, total_patrimonios, es_area_protegida, tiene_coordenadas, tiene_horario,
    costo_aprox_nacional_q, costo_aprox_extranjero_q, puntaje_bi_catalogo, fecha_actualizacion
  )
  SELECT
    v_id_fecha,
    dd.id_destino,
    dd.id_region,
    dd.id_departamento,
    dd.id_municipio,
    dd.tipo,
    dd.dificultad,
    COALESCE(m.total_categorias,0),
    COALESCE(m.total_actividades,0),
    COALESCE(m.total_temporadas,0),
    COALESCE(m.total_fuentes,0),
    COALESCE(m.total_recomendaciones,0),
    COALESCE(m.total_patrimonios,0) > 0,
    COALESCE(m.total_patrimonios,0),
    dd.es_area_protegida,
    dd.latitud IS NOT NULL AND dd.longitud IS NOT NULL,
    dd.horario IS NOT NULL,
    dd.costo_aprox_nacional_q,
    dd.costo_aprox_extranjero_q,
    ROUND((
      LEAST(COALESCE(m.total_actividades,0) * 5, 25) +
      LEAST(COALESCE(m.total_categorias,0) * 3, 15) +
      LEAST(COALESCE(m.total_fuentes,0) * 2, 10) +
      LEAST(COALESCE(m.total_recomendaciones,0) * 2, 10) +
      CASE WHEN COALESCE(m.total_patrimonios,0) > 0 THEN 20 ELSE 0 END +
      CASE WHEN dd.es_area_protegida THEN 10 ELSE 0 END +
      CASE WHEN dd.latitud IS NOT NULL AND dd.longitud IS NOT NULL THEN 5 ELSE 0 END +
      CASE WHEN dd.horario IS NOT NULL THEN 5 ELSE 0 END
    )::NUMERIC, 2) AS puntaje_bi_catalogo,
    NOW()
  FROM turismo.dim_destino dd
  LEFT JOIN metricas m ON m.id_destino = dd.id_destino
  ON CONFLICT (id_fecha_carga, id_destino) DO UPDATE SET
    id_region = EXCLUDED.id_region,
    id_departamento = EXCLUDED.id_departamento,
    id_municipio = EXCLUDED.id_municipio,
    tipo = EXCLUDED.tipo,
    dificultad = EXCLUDED.dificultad,
    total_categorias = EXCLUDED.total_categorias,
    total_actividades = EXCLUDED.total_actividades,
    total_temporadas = EXCLUDED.total_temporadas,
    total_fuentes = EXCLUDED.total_fuentes,
    total_recomendaciones = EXCLUDED.total_recomendaciones,
    tiene_patrimonio = EXCLUDED.tiene_patrimonio,
    total_patrimonios = EXCLUDED.total_patrimonios,
    es_area_protegida = EXCLUDED.es_area_protegida,
    tiene_coordenadas = EXCLUDED.tiene_coordenadas,
    tiene_horario = EXCLUDED.tiene_horario,
    costo_aprox_nacional_q = EXCLUDED.costo_aprox_nacional_q,
    costo_aprox_extranjero_q = EXCLUDED.costo_aprox_extranjero_q,
    puntaje_bi_catalogo = EXCLUDED.puntaje_bi_catalogo,
    fecha_actualizacion = NOW();

  INSERT INTO turismo.fact_destino_categoria(id_fecha_carga, id_destino, id_categoria, cantidad)
  SELECT v_id_fecha, id_destino, id_categoria, 1
  FROM turismo.destino_categoria
  ON CONFLICT (id_fecha_carga, id_destino, id_categoria) DO UPDATE SET cantidad = EXCLUDED.cantidad;

  INSERT INTO turismo.fact_destino_actividad(id_fecha_carga, id_destino, id_actividad, cantidad, notas)
  SELECT v_id_fecha, id_destino, id_actividad, 1, notas
  FROM turismo.destino_actividad
  ON CONFLICT (id_fecha_carga, id_destino, id_actividad) DO UPDATE SET
    cantidad = EXCLUDED.cantidad,
    notas = EXCLUDED.notas;

  INSERT INTO turismo.fact_destino_temporada(id_fecha_carga, id_destino, id_temporada, cantidad, recomendacion)
  SELECT v_id_fecha, id_destino, id_temporada, 1, recomendacion
  FROM turismo.destino_temporada
  ON CONFLICT (id_fecha_carga, id_destino, id_temporada) DO UPDATE SET
    cantidad = EXCLUDED.cantidad,
    recomendacion = EXCLUDED.recomendacion;

  INSERT INTO turismo.fact_destino_patrimonio(id_fecha_carga, id_destino, id_patrimonio, cantidad, observacion)
  SELECT v_id_fecha, id_destino, id_patrimonio, 1, observacion
  FROM turismo.destino_patrimonio
  ON CONFLICT (id_fecha_carga, id_destino, id_patrimonio) DO UPDATE SET
    cantidad = EXCLUDED.cantidad,
    observacion = EXCLUDED.observacion;

  INSERT INTO turismo.fact_ruta_destino(id_fecha_carga, id_ruta, id_destino, orden_visita, tiempo_sugerido, duracion_dias, cantidad)
  SELECT v_id_fecha, rd.id_ruta, rd.id_destino, rd.orden_visita, rd.tiempo_sugerido, dr.duracion_dias, 1
  FROM turismo.ruta_destino rd
  JOIN turismo.dim_ruta dr ON dr.id_ruta = rd.id_ruta
  ON CONFLICT (id_fecha_carga, id_ruta, id_destino) DO UPDATE SET
    orden_visita = EXCLUDED.orden_visita,
    tiempo_sugerido = EXCLUDED.tiempo_sugerido,
    duracion_dias = EXCLUDED.duracion_dias,
    cantidad = EXCLUDED.cantidad;

  INSERT INTO turismo.fact_metrica_destino(
    id_fecha, id_destino, fuente_metrica, visitantes_nacionales, visitantes_extranjeros,
    calificacion_promedio, cantidad_resenas, busquedas_web, menciones_redes, fecha_carga_dw
  )
  SELECT
    TO_CHAR(s.fecha_metrica, 'YYYYMMDD')::INT,
    dd.id_destino,
    COALESCE(s.fuente_metrica, 'STAGING'),
    s.visitantes_nacionales,
    s.visitantes_extranjeros,
    s.calificacion_promedio,
    s.cantidad_resenas,
    s.busquedas_web,
    s.menciones_redes,
    NOW()
  FROM turismo.stg_metricas_destino_raw s
  JOIN turismo.dim_destino dd ON UPPER(TRIM(dd.nombre)) = UPPER(TRIM(s.nombre_destino))
  WHERE s.procesado = FALSE
  ON CONFLICT (id_fecha, id_destino, fuente_metrica) DO UPDATE SET
    visitantes_nacionales = EXCLUDED.visitantes_nacionales,
    visitantes_extranjeros = EXCLUDED.visitantes_extranjeros,
    calificacion_promedio = EXCLUDED.calificacion_promedio,
    cantidad_resenas = EXCLUDED.cantidad_resenas,
    busquedas_web = EXCLUDED.busquedas_web,
    menciones_redes = EXCLUDED.menciones_redes,
    fecha_carga_dw = NOW();

  UPDATE turismo.stg_metricas_destino_raw
  SET procesado = TRUE,
      mensaje_proceso = 'Procesado hacia fact_metrica_destino'
  WHERE procesado = FALSE
    AND EXISTS (
      SELECT 1
      FROM turismo.dim_destino dd
      WHERE UPPER(TRIM(dd.nombre)) = UPPER(TRIM(stg_metricas_destino_raw.nombre_destino))
    );
END;
$$;

CREATE OR REPLACE FUNCTION turismo.sp_etl_refrescar_datamarts()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  IF TO_REGCLASS('turismo.mart_resumen_region') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_resumen_region;
  END IF;

  IF TO_REGCLASS('turismo.mart_destinos_por_categoria_region') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_destinos_por_categoria_region;
  END IF;

  IF TO_REGCLASS('turismo.mart_actividades_por_region') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_actividades_por_region;
  END IF;

  IF TO_REGCLASS('turismo.mart_patrimonio_turistico') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_patrimonio_turistico;
  END IF;

  IF TO_REGCLASS('turismo.mart_rutas_turisticas_detalle') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_rutas_turisticas_detalle;
  END IF;

  IF TO_REGCLASS('turismo.mart_destinos_recomendados_bi') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi;
  END IF;

  IF TO_REGCLASS('turismo.mart_trazabilidad_fuentes') IS NOT NULL THEN
    REFRESH MATERIALIZED VIEW turismo.mart_trazabilidad_fuentes;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION turismo.sp_etl_ejecutar_bi_completo()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_ejecucion BIGINT;
  v_total_destinos BIGINT;
BEGIN
  v_id_ejecucion := turismo.fn_etl_iniciar_job('BI_TURISMO_CARGA_COMPLETA', 'Inicio de carga completa BI Turismo');

  PERFORM turismo.sp_etl_validar_calidad(v_id_ejecucion);
  PERFORM turismo.sp_etl_cargar_dimensiones();
  PERFORM turismo.sp_etl_cargar_hechos();
  PERFORM turismo.sp_etl_refrescar_datamarts();

  SELECT COUNT(*) INTO v_total_destinos FROM turismo.dim_destino;

  PERFORM turismo.fn_etl_finalizar_job(
    v_id_ejecucion,
    'EXITOSO',
    v_total_destinos,
    0,
    0,
    'Carga BI finalizada correctamente. Destinos cargados: ' || v_total_destinos
  );
EXCEPTION WHEN OTHERS THEN
  IF v_id_ejecucion IS NOT NULL THEN
    PERFORM turismo.fn_etl_finalizar_job(v_id_ejecucion, 'ERROR', 0, 0, 1, SQLERRM);
  END IF;
  RAISE;
END;
$$;
