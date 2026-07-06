-- ============================================================
-- Flyway migration: V20260705113500__crear_datamarts_bi_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: crear datamarts / vistas materializadas para tableros BI.
--
-- Notas de correccion:
--   1. Esta migracion elimina previamente los datamarts derivados para evitar conflictos de columnas.
--   2. No usa CREATE OR REPLACE VIEW para vistas normales; primero las elimina y luego las crea.
--   3. Corrige la trazabilidad de fuentes usando turismo.destino_fuente y turismo.fuente_turistica.
--   4. Incluye todos los datamarts usados por el refresh repetible.
-- ============================================================

-- ============================================================
-- 0. Limpieza segura de objetos derivados BI
--    Se elimina cualquier materialized view, view o tabla con los nombres de datamarts.
--    Esto evita errores como:
--      - relation already exists
--      - cannot change name of view column
-- ============================================================
DO $$
DECLARE
    v_obj RECORD;
BEGIN
    FOR v_obj IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS object_name,
            c.relkind AS object_kind
        FROM pg_class c
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'turismo'
          AND c.relname IN (
              'mart_resumen_region',
              'mart_destinos_por_categoria_region',
              'mart_actividades_por_region',
              'mart_patrimonio_turistico',
              'mart_rutas_turisticas_detalle',
              'mart_destinos_recomendados_bi',
              'mart_trazabilidad_fuentes',
              'vw_bi_kpis_generales',
              'vw_bi_alertas_calidad'
          )
    LOOP
        IF v_obj.object_kind = 'm' THEN
            EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I.%I CASCADE', v_obj.schema_name, v_obj.object_name);
        ELSIF v_obj.object_kind = 'v' THEN
            EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', v_obj.schema_name, v_obj.object_name);
        ELSIF v_obj.object_kind IN ('r', 'p') THEN
            EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', v_obj.schema_name, v_obj.object_name);
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- 1. Datamart: resumen por region turistica
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_resumen_region AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_catalogo
)
SELECT
    r.id_region,
    r.nombre AS region_turistica,
    COUNT(DISTINCT f.id_destino) AS total_destinos,
    COUNT(DISTINCT f.id_departamento) AS total_departamentos,
    SUM(CASE WHEN f.es_area_protegida THEN 1 ELSE 0 END) AS total_destinos_area_protegida,
    SUM(CASE WHEN f.tiene_patrimonio THEN 1 ELSE 0 END) AS total_destinos_con_patrimonio,
    ROUND(AVG(f.total_actividades)::NUMERIC, 2) AS promedio_actividades_por_destino,
    ROUND(AVG(f.total_categorias)::NUMERIC, 2) AS promedio_categorias_por_destino,
    ROUND(AVG(f.puntaje_bi_catalogo)::NUMERIC, 2) AS puntaje_promedio_bi,
    ROUND(AVG(f.costo_aprox_nacional_q) FILTER (WHERE f.costo_aprox_nacional_q IS NOT NULL)::NUMERIC, 2) AS costo_promedio_nacional_q,
    ROUND(AVG(f.costo_aprox_extranjero_q) FILTER (WHERE f.costo_aprox_extranjero_q IS NOT NULL)::NUMERIC, 2) AS costo_promedio_extranjero_q
FROM turismo.dim_region r
LEFT JOIN turismo.fact_destino_catalogo f
    ON f.id_region = r.id_region
LEFT JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
WHERE f.id_fecha_carga = u.id_fecha_carga
   OR f.id_fecha_carga IS NULL
GROUP BY
    r.id_region,
    r.nombre
WITH DATA;

CREATE UNIQUE INDEX ux_mart_resumen_region
    ON turismo.mart_resumen_region(id_region);

COMMENT ON MATERIALIZED VIEW turismo.mart_resumen_region
IS 'Datamart con indicadores resumidos por region turistica.';
COMMENT ON COLUMN turismo.mart_resumen_region.id_region IS 'Identificador de la region turistica en la dimension BI.';
COMMENT ON COLUMN turismo.mart_resumen_region.region_turistica IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.mart_resumen_region.total_destinos IS 'Total de destinos turisticos asociados a la region.';
COMMENT ON COLUMN turismo.mart_resumen_region.total_departamentos IS 'Total de departamentos con destinos asociados a la region.';
COMMENT ON COLUMN turismo.mart_resumen_region.total_destinos_area_protegida IS 'Total de destinos de la region marcados como area protegida.';
COMMENT ON COLUMN turismo.mart_resumen_region.total_destinos_con_patrimonio IS 'Total de destinos de la region asociados a patrimonio turistico.';
COMMENT ON COLUMN turismo.mart_resumen_region.promedio_actividades_por_destino IS 'Promedio de actividades asociadas por destino turistico.';
COMMENT ON COLUMN turismo.mart_resumen_region.promedio_categorias_por_destino IS 'Promedio de categorias asociadas por destino turistico.';
COMMENT ON COLUMN turismo.mart_resumen_region.puntaje_promedio_bi IS 'Promedio del puntaje BI calculado para los destinos de la region.';
COMMENT ON COLUMN turismo.mart_resumen_region.costo_promedio_nacional_q IS 'Costo promedio aproximado para visitante nacional en quetzales, si existe dato.';
COMMENT ON COLUMN turismo.mart_resumen_region.costo_promedio_extranjero_q IS 'Costo promedio aproximado para visitante extranjero en quetzales, si existe dato.';

-- ============================================================
-- 2. Datamart: destinos por categoria y region
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_destinos_por_categoria_region AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_categoria
)
SELECT
    r.id_region,
    r.nombre AS region_turistica,
    c.id_categoria,
    c.nombre AS categoria,
    COUNT(DISTINCT f.id_destino) AS total_destinos
FROM turismo.fact_destino_categoria f
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d
    ON d.id_destino = f.id_destino
JOIN turismo.dim_region r
    ON r.id_region = d.id_region
JOIN turismo.dim_categoria c
    ON c.id_categoria = f.id_categoria
GROUP BY
    r.id_region,
    r.nombre,
    c.id_categoria,
    c.nombre
WITH DATA;

CREATE INDEX idx_mart_destinos_categoria_region
    ON turismo.mart_destinos_por_categoria_region(region_turistica, categoria);

COMMENT ON MATERIALIZED VIEW turismo.mart_destinos_por_categoria_region
IS 'Datamart de conteo de destinos por categoria y region.';
COMMENT ON COLUMN turismo.mart_destinos_por_categoria_region.id_region IS 'Identificador de la region turistica.';
COMMENT ON COLUMN turismo.mart_destinos_por_categoria_region.region_turistica IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.mart_destinos_por_categoria_region.id_categoria IS 'Identificador de la categoria turistica.';
COMMENT ON COLUMN turismo.mart_destinos_por_categoria_region.categoria IS 'Nombre de la categoria turistica.';
COMMENT ON COLUMN turismo.mart_destinos_por_categoria_region.total_destinos IS 'Total de destinos asociados a la categoria dentro de la region.';

-- ============================================================
-- 3. Datamart: actividades por region
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_actividades_por_region AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_actividad
)
SELECT
    r.id_region,
    r.nombre AS region_turistica,
    a.id_actividad,
    a.nombre AS actividad,
    COUNT(DISTINCT f.id_destino) AS total_destinos
FROM turismo.fact_destino_actividad f
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d
    ON d.id_destino = f.id_destino
JOIN turismo.dim_region r
    ON r.id_region = d.id_region
JOIN turismo.dim_actividad a
    ON a.id_actividad = f.id_actividad
GROUP BY
    r.id_region,
    r.nombre,
    a.id_actividad,
    a.nombre
WITH DATA;

CREATE INDEX idx_mart_actividades_region
    ON turismo.mart_actividades_por_region(region_turistica, actividad);

COMMENT ON MATERIALIZED VIEW turismo.mart_actividades_por_region
IS 'Datamart de actividades disponibles por region turistica.';
COMMENT ON COLUMN turismo.mart_actividades_por_region.id_region IS 'Identificador de la region turistica.';
COMMENT ON COLUMN turismo.mart_actividades_por_region.region_turistica IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.mart_actividades_por_region.id_actividad IS 'Identificador de la actividad turistica.';
COMMENT ON COLUMN turismo.mart_actividades_por_region.actividad IS 'Nombre de la actividad turistica.';
COMMENT ON COLUMN turismo.mart_actividades_por_region.total_destinos IS 'Total de destinos de la region donde se registra la actividad.';

-- ============================================================
-- 4. Datamart: patrimonio turistico
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_patrimonio_turistico AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_patrimonio
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
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_patrimonio p
    ON p.id_patrimonio = f.id_patrimonio
JOIN turismo.dim_destino d
    ON d.id_destino = f.id_destino
WITH DATA;

CREATE INDEX idx_mart_patrimonio_tipo_region
    ON turismo.mart_patrimonio_turistico(tipo, region_turistica);

COMMENT ON MATERIALIZED VIEW turismo.mart_patrimonio_turistico
IS 'Datamart de destinos asociados a patrimonio cultural, natural o intangible.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.id_patrimonio IS 'Identificador del patrimonio turistico.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.patrimonio IS 'Nombre del patrimonio turistico.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.tipo IS 'Tipo de reconocimiento patrimonial.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.organismo IS 'Organismo que reconoce o registra el patrimonio.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.anio_inscripcion IS 'Anio de inscripcion o reconocimiento patrimonial.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.id_destino IS 'Identificador del destino asociado al patrimonio.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.destino IS 'Nombre del destino asociado al patrimonio.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.departamento IS 'Departamento del destino asociado.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.region_turistica IS 'Region turistica del destino asociado.';
COMMENT ON COLUMN turismo.mart_patrimonio_turistico.observacion IS 'Observacion de la relacion entre destino y patrimonio.';

-- ============================================================
-- 5. Datamart: rutas turisticas detalle
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_rutas_turisticas_detalle AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_ruta_destino
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
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_ruta r
    ON r.id_ruta = f.id_ruta
JOIN turismo.dim_destino d
    ON d.id_destino = f.id_destino
ORDER BY
    r.id_ruta,
    f.orden_visita
WITH DATA;

CREATE INDEX idx_mart_rutas_orden
    ON turismo.mart_rutas_turisticas_detalle(id_ruta, orden_visita);

COMMENT ON MATERIALIZED VIEW turismo.mart_rutas_turisticas_detalle
IS 'Datamart de rutas turisticas con destinos y orden de visita.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.id_ruta IS 'Identificador de la ruta turistica.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.ruta_turistica IS 'Nombre de la ruta turistica.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.duracion_dias IS 'Duracion estimada de la ruta en dias.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.orden_visita IS 'Orden sugerido de visita del destino dentro de la ruta.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.id_destino IS 'Identificador del destino turistico incluido en la ruta.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.destino IS 'Nombre del destino turistico incluido en la ruta.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.departamento IS 'Departamento del destino turistico.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.municipio IS 'Municipio del destino turistico, cuando existe.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.region_turistica IS 'Region turistica del destino.';
COMMENT ON COLUMN turismo.mart_rutas_turisticas_detalle.tiempo_sugerido IS 'Tiempo sugerido de permanencia en el destino dentro de la ruta.';

-- ============================================================
-- 6. Datamart: destinos recomendados BI
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_catalogo
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
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga
JOIN turismo.dim_destino d
    ON d.id_destino = f.id_destino
ORDER BY
    f.puntaje_bi_catalogo DESC,
    d.nombre
WITH DATA;

CREATE UNIQUE INDEX ux_mart_destinos_recomendados_bi
    ON turismo.mart_destinos_recomendados_bi(id_destino);

CREATE INDEX idx_mart_destinos_recomendados_score
    ON turismo.mart_destinos_recomendados_bi(puntaje_bi_catalogo DESC);

COMMENT ON MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi
IS 'Datamart de destinos priorizados por puntaje BI calculado desde datos de catalogo.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.id_destino IS 'Identificador del destino turistico.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.destino IS 'Nombre del destino turistico.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.region_turistica IS 'Region turistica del destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.departamento IS 'Departamento del destino turistico.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.municipio IS 'Municipio del destino turistico, cuando existe.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.tipo IS 'Tipo de destino turistico.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.dificultad IS 'Dificultad registrada para visitar el destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_categorias IS 'Cantidad de categorias asociadas al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_actividades IS 'Cantidad de actividades asociadas al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_temporadas IS 'Cantidad de temporadas asociadas al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_fuentes IS 'Cantidad de fuentes asociadas al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_recomendaciones IS 'Cantidad de recomendaciones asociadas al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.total_patrimonios IS 'Cantidad de patrimonios asociados al destino.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.es_area_protegida IS 'Indica si el destino esta marcado como area protegida.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.tiene_coordenadas IS 'Indica si el destino tiene coordenadas registradas.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.tiene_horario IS 'Indica si el destino tiene horario registrado.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.puntaje_bi_catalogo IS 'Puntaje BI del destino calculado a partir de completitud y relaciones de catalogo.';
COMMENT ON COLUMN turismo.mart_destinos_recomendados_bi.nivel_recomendacion_bi IS 'Nivel derivado del puntaje BI: MUY_ALTO, ALTO, MEDIO o BAJO.';

-- ============================================================
-- 7. Datamart: trazabilidad de fuentes
--    Usa modelo curado real, no dimensiones, para evitar dependencia de dim_fuente.
-- ============================================================
CREATE MATERIALIZED VIEW turismo.mart_trazabilidad_fuentes AS
SELECT
    f.id_fuente,
    f.codigo AS codigo_fuente,
    f.nombre AS fuente,
    f.institucion,
    f.tipo,
    f.url,
    f.fecha_consulta,
    COUNT(DISTINCT df.destino_id) AS destinos_relacionados,
    COUNT(DISTINCT CASE
        WHEN d.fuente_principal_id = f.id_fuente THEN d.id_destino
    END) AS destinos_como_fuente_principal
FROM turismo.fuente_turistica f
LEFT JOIN turismo.destino_fuente df
    ON df.fuente_id = f.id_fuente
LEFT JOIN turismo.destino_turistico d
    ON d.id_destino = df.destino_id
    OR d.fuente_principal_id = f.id_fuente
GROUP BY
    f.id_fuente,
    f.codigo,
    f.nombre,
    f.institucion,
    f.tipo,
    f.url,
    f.fecha_consulta
WITH DATA;

CREATE INDEX idx_mart_trazabilidad_fuentes_codigo
    ON turismo.mart_trazabilidad_fuentes(codigo_fuente);

CREATE INDEX idx_mart_trazabilidad_fuentes_tipo
    ON turismo.mart_trazabilidad_fuentes(tipo);

COMMENT ON MATERIALIZED VIEW turismo.mart_trazabilidad_fuentes
IS 'Datamart de trazabilidad entre destinos, fuentes y calidad documental.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.id_fuente IS 'Identificador de la fuente turistica.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.codigo_fuente IS 'Codigo unico de la fuente turistica.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.fuente IS 'Nombre de la fuente turistica.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.institucion IS 'Institucion asociada a la fuente turistica.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.tipo IS 'Tipo de fuente turistica.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.url IS 'URL de consulta de la fuente.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.fecha_consulta IS 'Fecha de consulta registrada para la fuente.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.destinos_relacionados IS 'Cantidad de destinos relacionados con la fuente mediante turismo.destino_fuente.';
COMMENT ON COLUMN turismo.mart_trazabilidad_fuentes.destinos_como_fuente_principal IS 'Cantidad de destinos donde la fuente aparece como fuente principal.';

-- ============================================================
-- 8. Vistas normales para herramientas BI que no requieren refresh manual
-- ============================================================
CREATE VIEW turismo.vw_bi_kpis_generales AS
WITH ultima AS (
    SELECT MAX(id_fecha_carga) AS id_fecha_carga
    FROM turismo.fact_destino_catalogo
)
SELECT
    COUNT(DISTINCT f.id_destino) AS total_destinos,
    COUNT(DISTINCT f.id_region) AS total_regiones,
    COUNT(DISTINCT f.id_departamento) AS total_departamentos,
    SUM(CASE WHEN f.es_area_protegida THEN 1 ELSE 0 END) AS total_areas_protegidas,
    SUM(CASE WHEN f.tiene_patrimonio THEN 1 ELSE 0 END) AS total_destinos_con_patrimonio,
    ROUND(AVG(f.puntaje_bi_catalogo)::NUMERIC, 2) AS puntaje_promedio_bi
FROM turismo.fact_destino_catalogo f
JOIN ultima u
    ON u.id_fecha_carga = f.id_fecha_carga;

COMMENT ON VIEW turismo.vw_bi_kpis_generales
IS 'Vista de indicadores generales del modelo BI de turismo.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.total_destinos IS 'Total de destinos considerados en la ultima carga BI.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.total_regiones IS 'Total de regiones turisticas con destinos en la ultima carga BI.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.total_departamentos IS 'Total de departamentos con destinos en la ultima carga BI.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.total_areas_protegidas IS 'Total de destinos marcados como area protegida.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.total_destinos_con_patrimonio IS 'Total de destinos asociados a patrimonio turistico.';
COMMENT ON COLUMN turismo.vw_bi_kpis_generales.puntaje_promedio_bi IS 'Promedio del puntaje BI de destinos en la ultima carga.';

CREATE VIEW turismo.vw_bi_alertas_calidad AS
SELECT
    v.fecha_validacion,
    v.entidad,
    v.regla,
    v.nivel,
    v.total_registros,
    v.total_observaciones,
    v.detalle
FROM turismo.etl_validacion v
ORDER BY
    v.fecha_validacion DESC,
    v.nivel DESC;

COMMENT ON VIEW turismo.vw_bi_alertas_calidad
IS 'Vista de alertas de calidad de datos para el catalogo turistico.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.fecha_validacion IS 'Fecha y hora en que se ejecuto la validacion.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.entidad IS 'Entidad, tabla o componente validado.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.regla IS 'Regla de calidad aplicada.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.nivel IS 'Nivel de severidad de la validacion.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.total_registros IS 'Total de registros evaluados por la validacion.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.total_observaciones IS 'Total de observaciones encontradas por la validacion.';
COMMENT ON COLUMN turismo.vw_bi_alertas_calidad.detalle IS 'Detalle de hallazgos o explicacion de la validacion.';
