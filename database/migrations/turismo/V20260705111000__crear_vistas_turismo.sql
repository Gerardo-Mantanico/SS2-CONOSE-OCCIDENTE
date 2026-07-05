-- ============================================================
-- Migracion: vistas de consulta para turismo
-- Convencion: objetos siempre calificados con esquema.objeto.
-- ============================================================

CREATE OR REPLACE VIEW turismo.vw_destinos_completos AS
SELECT
    d.id_destino,
    d.codigo,
    d.nombre AS destino,
    d.tipo,
    dep.nombre AS departamento,
    mun.nombre AS municipio,
    rt.nombre AS region_turistica,
    d.descripcion,
    d.direccion_referencia,
    d.latitud,
    d.longitud,
    d.altitud_msnm,
    d.dificultad,
    d.tiempo_recomendado,
    d.es_area_protegida,
    ft.nombre AS fuente_principal,
    ft.url AS url_fuente_principal,
    string_agg(DISTINCT cd.nombre, ', ' ORDER BY cd.nombre) AS categorias,
    string_agg(DISTINCT at.nombre, ', ' ORDER BY at.nombre) AS actividades,
    string_agg(DISTINCT tt.nombre, ', ' ORDER BY tt.nombre) AS temporadas,
    count(DISTINCT pt.id_patrimonio) AS total_patrimonios
FROM turismo.destino_turistico d
JOIN geografia.departamento dep ON dep.id = d.departamento_id
LEFT JOIN geografia.municipio mun ON mun.id = d.municipio_id
LEFT JOIN turismo.region_turistica rt ON rt.id_region = d.region_turistica_id
LEFT JOIN turismo.fuente_turistica ft ON ft.id_fuente = d.fuente_principal_id
LEFT JOIN turismo.destino_categoria dc ON dc.destino_id = d.id_destino
LEFT JOIN turismo.categoria_destino cd ON cd.id_categoria = dc.categoria_id
LEFT JOIN turismo.destino_actividad da ON da.destino_id = d.id_destino
LEFT JOIN turismo.actividad_turistica at ON at.id_actividad = da.actividad_id
LEFT JOIN turismo.destino_temporada dt ON dt.destino_id = d.id_destino
LEFT JOIN turismo.temporada_turistica tt ON tt.id_temporada = dt.temporada_id
LEFT JOIN turismo.destino_patrimonio dp ON dp.destino_id = d.id_destino
LEFT JOIN turismo.patrimonio_turistico pt ON pt.id_patrimonio = dp.patrimonio_id
WHERE d.activo = TRUE
GROUP BY
    d.id_destino, d.codigo, d.nombre, d.tipo, dep.nombre, mun.nombre, rt.nombre,
    d.descripcion, d.direccion_referencia, d.latitud, d.longitud, d.altitud_msnm,
    d.dificultad, d.tiempo_recomendado, d.es_area_protegida, ft.nombre, ft.url;

COMMENT ON VIEW turismo.vw_destinos_completos IS 'Vista integral de destinos turisticos con geografia oficial, region turistica, categorias, actividades, temporadas y fuente principal.';
COMMENT ON COLUMN turismo.vw_destinos_completos.id_destino IS 'Identificador del destino turistico.';
COMMENT ON COLUMN turismo.vw_destinos_completos.codigo IS 'Codigo estable del destino turistico.';
COMMENT ON COLUMN turismo.vw_destinos_completos.destino IS 'Nombre del destino turistico.';
COMMENT ON COLUMN turismo.vw_destinos_completos.tipo IS 'Tipo general del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.departamento IS 'Departamento oficial del esquema geografia.';
COMMENT ON COLUMN turismo.vw_destinos_completos.municipio IS 'Municipio oficial del esquema geografia cuando fue posible resolverlo.';
COMMENT ON COLUMN turismo.vw_destinos_completos.region_turistica IS 'Region turistica asociada al departamento.';
COMMENT ON COLUMN turismo.vw_destinos_completos.descripcion IS 'Descripcion del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.direccion_referencia IS 'Referencia de ubicacion o acceso.';
COMMENT ON COLUMN turismo.vw_destinos_completos.latitud IS 'Latitud aproximada.';
COMMENT ON COLUMN turismo.vw_destinos_completos.longitud IS 'Longitud aproximada.';
COMMENT ON COLUMN turismo.vw_destinos_completos.altitud_msnm IS 'Altitud aproximada sobre el nivel del mar.';
COMMENT ON COLUMN turismo.vw_destinos_completos.dificultad IS 'Dificultad general de visita.';
COMMENT ON COLUMN turismo.vw_destinos_completos.tiempo_recomendado IS 'Tiempo recomendado de visita.';
COMMENT ON COLUMN turismo.vw_destinos_completos.es_area_protegida IS 'Indica si el destino es o pertenece a un area protegida.';
COMMENT ON COLUMN turismo.vw_destinos_completos.fuente_principal IS 'Fuente principal del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.url_fuente_principal IS 'URL de la fuente principal.';
COMMENT ON COLUMN turismo.vw_destinos_completos.categorias IS 'Categorias agregadas del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.actividades IS 'Actividades agregadas del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.temporadas IS 'Temporadas agregadas del destino.';
COMMENT ON COLUMN turismo.vw_destinos_completos.total_patrimonios IS 'Cantidad de reconocimientos patrimoniales asociados.';

CREATE OR REPLACE VIEW turismo.vw_destinos_patrimonio AS
SELECT
    d.codigo AS codigo_destino,
    d.nombre AS destino,
    dep.nombre AS departamento,
    mun.nombre AS municipio,
    p.codigo AS codigo_patrimonio,
    p.nombre AS patrimonio,
    p.tipo,
    p.organismo,
    p.anio_inscripcion,
    p.descripcion,
    ft.url AS fuente_url
FROM turismo.destino_patrimonio dp
JOIN turismo.destino_turistico d ON d.id_destino = dp.destino_id
JOIN geografia.departamento dep ON dep.id = d.departamento_id
LEFT JOIN geografia.municipio mun ON mun.id = d.municipio_id
JOIN turismo.patrimonio_turistico p ON p.id_patrimonio = dp.patrimonio_id
LEFT JOIN turismo.fuente_turistica ft ON ft.id_fuente = p.fuente_id;

COMMENT ON VIEW turismo.vw_destinos_patrimonio IS 'Vista de destinos con reconocimientos patrimoniales, especialmente UNESCO.';

CREATE OR REPLACE VIEW turismo.vw_rutas_detalle AS
SELECT
    r.codigo AS codigo_ruta,
    r.nombre AS ruta,
    rt.nombre AS region_turistica,
    r.duracion_dias,
    rd.orden_visita,
    d.codigo AS codigo_destino,
    d.nombre AS destino,
    dep.nombre AS departamento,
    mun.nombre AS municipio,
    rd.tiempo_sugerido
FROM turismo.ruta_turistica r
LEFT JOIN turismo.region_turistica rt ON rt.id_region = r.region_id
JOIN turismo.ruta_destino rd ON rd.ruta_id = r.id_ruta
JOIN turismo.destino_turistico d ON d.id_destino = rd.destino_id
JOIN geografia.departamento dep ON dep.id = d.departamento_id
LEFT JOIN geografia.municipio mun ON mun.id = d.municipio_id
ORDER BY r.codigo, rd.orden_visita;

COMMENT ON VIEW turismo.vw_rutas_detalle IS 'Vista de rutas turisticas con destinos ordenados, departamentos y municipios oficiales.';

CREATE OR REPLACE VIEW turismo.vw_fuentes_turismo AS
SELECT
    ft.codigo,
    ft.nombre,
    ft.institucion,
    ft.tipo,
    ft.url,
    ft.fecha_consulta,
    ft.descripcion
FROM turismo.fuente_turistica ft
ORDER BY ft.codigo;

COMMENT ON VIEW turismo.vw_fuentes_turismo IS 'Vista de fuentes documentales utilizadas en el area turismo.';
