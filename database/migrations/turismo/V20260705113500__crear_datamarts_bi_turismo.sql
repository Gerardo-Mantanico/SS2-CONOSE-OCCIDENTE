-- ============================================================
-- Flyway migration: V20260705113500__crear_datamarts_bi_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: crear datamarts / vistas materializadas para tableros BI
-- ============================================================


CREATE MATERIALIZED VIEW turismo.mart_resumen_region AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_catalogo
)
SELECT
  r.id_region,
  r.nombre AS region_turistica,
  COUNT(DISTINCT f.id_destino) AS total_destinos,
  COUNT(DISTINCT f.id_departamento) AS total_departamentos,
  SUM(CASE WHEN f.es_area_protegida THEN 1 ELSE 0 END) AS destinos_area_protegida,
  SUM(CASE WHEN f.tiene_patrimonio THEN 1 ELSE 0 END) AS destinos_con_patrimonio,
  ROUND(AVG(f.total_actividades)::NUMERIC, 2) AS promedio_actividades_por_destino,
  ROUND(AVG(f.total_categorias)::NUMERIC, 2) AS promedio_categorias_por_destino,
  ROUND(AVG(f.puntaje_bi_catalogo)::NUMERIC, 2) AS puntaje_promedio_bi,
  ROUND(AVG(f.costo_aprox_nacional_q) FILTER (WHERE f.costo_aprox_nacional_q IS NOT NULL)::NUMERIC, 2) AS costo_promedio_nacional_q,
  ROUND(AVG(f.costo_aprox_extranjero_q) FILTER (WHERE f.costo_aprox_extranjero_q IS NOT NULL)::NUMERIC, 2) AS costo_promedio_extranjero_q
FROM turismo.dim_region r
LEFT JOIN turismo.fact_destino_catalogo f ON f.id_region = r.id_region
LEFT JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
WHERE f.id_fecha_carga = u.id_fecha_carga OR f.id_fecha_carga IS NULL
GROUP BY r.id_region, r.nombre;

CREATE UNIQUE INDEX ux_mart_resumen_region ON turismo.mart_resumen_region(id_region);

CREATE MATERIALIZED VIEW turismo.mart_destinos_por_categoria_region AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_categoria
)
SELECT
  r.id_region,
  r.nombre AS region_turistica,
  c.id_categoria,
  c.nombre AS categoria,
  COUNT(DISTINCT f.id_destino) AS total_destinos
FROM turismo.fact_destino_categoria f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d ON d.id_destino = f.id_destino
JOIN turismo.dim_region r ON r.id_region = d.id_region
JOIN turismo.dim_categoria c ON c.id_categoria = f.id_categoria
GROUP BY r.id_region, r.nombre, c.id_categoria, c.nombre;

CREATE INDEX idx_mart_destinos_categoria_region ON turismo.mart_destinos_por_categoria_region(region_turistica, categoria);

CREATE MATERIALIZED VIEW turismo.mart_actividades_por_region AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_actividad
)
SELECT
  r.id_region,
  r.nombre AS region_turistica,
  a.id_actividad,
  a.nombre AS actividad,
  COUNT(DISTINCT f.id_destino) AS total_destinos
FROM turismo.fact_destino_actividad f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d ON d.id_destino = f.id_destino
JOIN turismo.dim_region r ON r.id_region = d.id_region
JOIN turismo.dim_actividad a ON a.id_actividad = f.id_actividad
GROUP BY r.id_region, r.nombre, a.id_actividad, a.nombre;

CREATE INDEX idx_mart_actividades_region ON turismo.mart_actividades_por_region(region_turistica, actividad);

CREATE MATERIALIZED VIEW turismo.mart_patrimonio_turistico AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_patrimonio
)
SELECT
  p.id_patrimonio,
  p.nombre AS patrimonio,
  p.tipo,
  p.organismo,
  p.anio_inscripcion,
  d.id_destino,
  d.nombre AS destino,
  d.departamento_nombre AS departamento,
  d.region_nombre AS region_turistica,
  f.observacion
FROM turismo.fact_destino_patrimonio f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_patrimonio p ON p.id_patrimonio = f.id_patrimonio
JOIN turismo.dim_destino d ON d.id_destino = f.id_destino;

CREATE INDEX idx_mart_patrimonio_tipo_region ON turismo.mart_patrimonio_turistico(tipo, region_turistica);

CREATE MATERIALIZED VIEW turismo.mart_rutas_turisticas_detalle AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_ruta_destino
)
SELECT
  r.id_ruta,
  r.nombre AS ruta_turistica,
  r.duracion_dias,
  f.orden_visita,
  d.id_destino,
  d.nombre AS destino,
  d.departamento_nombre AS departamento,
  d.municipio_nombre AS municipio,
  d.region_nombre AS region_turistica,
  f.tiempo_sugerido
FROM turismo.fact_ruta_destino f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_ruta r ON r.id_ruta = f.id_ruta
JOIN turismo.dim_destino d ON d.id_destino = f.id_destino
ORDER BY r.id_ruta, f.orden_visita;

CREATE INDEX idx_mart_rutas_orden ON turismo.mart_rutas_turisticas_detalle(id_ruta, orden_visita);

CREATE MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_catalogo
)
SELECT
  d.id_destino,
  d.nombre AS destino,
  d.region_nombre AS region_turistica,
  d.departamento_nombre AS departamento,
  d.municipio_nombre AS municipio,
  d.tipo,
  d.dificultad,
  f.total_categorias,
  f.total_actividades,
  f.total_temporadas,
  f.total_fuentes,
  f.total_recomendaciones,
  f.total_patrimonios,
  f.es_area_protegida,
  f.tiene_coordenadas,
  f.tiene_horario,
  f.puntaje_bi_catalogo,
  CASE
    WHEN f.puntaje_bi_catalogo >= 80 THEN 'MUY_ALTO'
    WHEN f.puntaje_bi_catalogo >= 60 THEN 'ALTO'
    WHEN f.puntaje_bi_catalogo >= 40 THEN 'MEDIO'
    ELSE 'BAJO'
  END AS nivel_recomendacion_bi
FROM turismo.fact_destino_catalogo f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d ON d.id_destino = f.id_destino
ORDER BY f.puntaje_bi_catalogo DESC, d.nombre;

CREATE UNIQUE INDEX ux_mart_destinos_recomendados_bi ON turismo.mart_destinos_recomendados_bi(id_destino);
CREATE INDEX idx_mart_destinos_recomendados_score ON turismo.mart_destinos_recomendados_bi(puntaje_bi_catalogo DESC);

CREATE MATERIALIZED VIEW turismo.mart_trazabilidad_fuentes AS
SELECT
  f.id_fuente,
  f.nombre AS fuente,
  f.tipo,
  f.url,
  f.fecha_consulta,
  COUNT(DISTINCT fd.id_destino) AS destinos_relacionados,
  COUNT(DISTINCT CASE WHEN d.id_fuente_principal = f.id_fuente THEN d.id_destino END) AS destinos_como_fuente_principal
FROM turismo.dim_fuente f
LEFT JOIN turismo.fuente_destino fd ON fd.id_fuente = f.id_fuente
LEFT JOIN turismo.dim_destino d ON d.id_destino = fd.id_destino OR d.id_fuente_principal = f.id_fuente
GROUP BY f.id_fuente, f.nombre, f.tipo, f.url, f.fecha_consulta;

CREATE UNIQUE INDEX ux_mart_trazabilidad_fuentes ON turismo.mart_trazabilidad_fuentes(id_fuente);

-- Vistas normales para herramientas BI que no necesitan refresco manual.
CREATE OR REPLACE VIEW turismo.vw_bi_kpis_generales AS
WITH ultima AS (
  SELECT MAX(id_fecha_carga) AS id_fecha_carga FROM turismo.fact_destino_catalogo
)
SELECT
  COUNT(DISTINCT f.id_destino) AS total_destinos,
  COUNT(DISTINCT f.id_region) AS total_regiones,
  COUNT(DISTINCT f.id_departamento) AS total_departamentos,
  SUM(CASE WHEN f.es_area_protegida THEN 1 ELSE 0 END) AS total_areas_protegidas,
  SUM(CASE WHEN f.tiene_patrimonio THEN 1 ELSE 0 END) AS total_destinos_con_patrimonio,
  ROUND(AVG(f.puntaje_bi_catalogo)::NUMERIC, 2) AS puntaje_promedio_bi
FROM turismo.fact_destino_catalogo f
JOIN ultima u ON u.id_fecha_carga = f.id_fecha_carga;

CREATE OR REPLACE VIEW turismo.vw_bi_alertas_calidad AS
SELECT
  v.fecha_validacion,
  v.entidad,
  v.regla,
  v.nivel,
  v.total_registros,
  v.total_observaciones,
  v.detalle
FROM turismo.etl_validacion v
ORDER BY v.fecha_validacion DESC, v.nivel DESC;


-- Comentarios de datamarts y vistas BI.
COMMENT ON MATERIALIZED VIEW turismo.mart_resumen_region IS 'Datamart con indicadores resumidos por region turistica.';
COMMENT ON MATERIALIZED VIEW turismo.mart_destinos_por_categoria_region IS 'Datamart de conteo de destinos por categoria y region.';
COMMENT ON MATERIALIZED VIEW turismo.mart_actividades_por_region IS 'Datamart de actividades disponibles por region turistica.';
COMMENT ON MATERIALIZED VIEW turismo.mart_patrimonio_turistico IS 'Datamart de destinos asociados a patrimonio cultural, natural o intangible.';
COMMENT ON MATERIALIZED VIEW turismo.mart_rutas_turisticas_detalle IS 'Datamart de rutas turisticas con destinos y orden de visita.';
COMMENT ON MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi IS 'Datamart de destinos priorizados por puntaje BI calculado desde datos de catalogo.';
COMMENT ON MATERIALIZED VIEW turismo.mart_trazabilidad_fuentes IS 'Datamart de trazabilidad entre destinos, fuentes y calidad documental.';
COMMENT ON VIEW turismo.vw_bi_kpis_generales IS 'Vista de indicadores generales del modelo BI de turismo.';
COMMENT ON VIEW turismo.vw_bi_alertas_calidad IS 'Vista de alertas de calidad de datos para el catalogo turistico.';
