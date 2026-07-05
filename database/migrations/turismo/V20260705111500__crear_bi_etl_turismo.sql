-- ============================================================
-- Migracion: modelo BI y estructuras ETL para turismo
-- Objetivo: preparar staging, dimensiones, hechos y datamarts.
-- Correccion aplicada: las dimensiones de geografia se derivan de geografia.departamento/geografia.municipio.
-- ============================================================

-- ============================================================
-- Control ETL especifico del dominio turismo
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.etl_ejecucion_turismo (
    id_ejecucion       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_proceso     VARCHAR(160) NOT NULL,
    tipo_proceso       VARCHAR(60) NOT NULL,
    fecha_inicio       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin          TIMESTAMP,
    estado             VARCHAR(40) NOT NULL DEFAULT 'INICIADO',
    registros_leidos   INT NOT NULL DEFAULT 0,
    registros_insertados INT NOT NULL DEFAULT 0,
    registros_actualizados INT NOT NULL DEFAULT 0,
    registros_rechazados INT NOT NULL DEFAULT 0,
    observacion        TEXT,
    carga_id           INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.etl_ejecucion_turismo IS 'Bitacora de ejecuciones ETL especificas del area turismo.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.id_ejecucion IS 'Identificador unico de ejecucion ETL.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.nombre_proceso IS 'Nombre del proceso ETL ejecutado.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.tipo_proceso IS 'Tipo de proceso: STAGING, DIMENSIONAL, HECHOS, DATAMART u otro.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.fecha_inicio IS 'Fecha y hora de inicio de la ejecucion.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.fecha_fin IS 'Fecha y hora de finalizacion de la ejecucion.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.estado IS 'Estado del proceso: INICIADO, FINALIZADO, ERROR.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.registros_leidos IS 'Cantidad de registros leidos por el proceso.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.registros_insertados IS 'Cantidad de registros insertados por el proceso.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.registros_actualizados IS 'Cantidad de registros actualizados por el proceso.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.registros_rechazados IS 'Cantidad de registros rechazados por el proceso.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.observacion IS 'Detalle o mensaje del proceso.';
COMMENT ON COLUMN turismo.etl_ejecucion_turismo.carga_id IS 'Referencia opcional a meta.carga para trazabilidad transversal.';

CREATE TABLE IF NOT EXISTS turismo.etl_error_turismo (
    id_error      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ejecucion_id  INT REFERENCES turismo.etl_ejecucion_turismo(id_ejecucion),
    tabla_destino VARCHAR(180),
    codigo_registro VARCHAR(160),
    mensaje_error TEXT NOT NULL,
    datos_origen JSONB,
    fecha_error TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE turismo.etl_error_turismo IS 'Errores detectados durante procesos ETL del area turismo.';
COMMENT ON COLUMN turismo.etl_error_turismo.id_error IS 'Identificador unico del error ETL.';
COMMENT ON COLUMN turismo.etl_error_turismo.ejecucion_id IS 'Ejecucion ETL asociada al error.';
COMMENT ON COLUMN turismo.etl_error_turismo.tabla_destino IS 'Tabla destino relacionada con el error.';
COMMENT ON COLUMN turismo.etl_error_turismo.codigo_registro IS 'Codigo o llave del registro que produjo el error.';
COMMENT ON COLUMN turismo.etl_error_turismo.mensaje_error IS 'Descripcion del error detectado.';
COMMENT ON COLUMN turismo.etl_error_turismo.datos_origen IS 'Datos originales del registro en formato JSONB para trazabilidad.';
COMMENT ON COLUMN turismo.etl_error_turismo.fecha_error IS 'Fecha y hora del error.';

-- ============================================================
-- Staging: preparado para CSV/API futuros sin tocar el modelo curado.
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.stg_destino_turistico (
    id_stg              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(80),
    nombre              VARCHAR(220),
    tipo                VARCHAR(60),
    departamento        VARCHAR(120),
    municipio           VARCHAR(120),
    descripcion         TEXT,
    direccion_referencia VARCHAR(500),
    latitud             NUMERIC(10,7),
    longitud            NUMERIC(10,7),
    altitud_msnm        INT,
    dificultad          VARCHAR(60),
    tiempo_recomendado  VARCHAR(120),
    es_area_protegida   BOOLEAN,
    fuente_codigo       VARCHAR(80),
    fecha_carga         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_validacion   VARCHAR(40) DEFAULT 'PENDIENTE',
    mensaje_validacion  TEXT,
    carga_id            INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.stg_destino_turistico IS 'Tabla staging para cargar destinos turisticos desde CSV, Excel, APIs o fuentes externas antes de normalizarlos.';
COMMENT ON COLUMN turismo.stg_destino_turistico.id_stg IS 'Identificador tecnico del registro staging.';
COMMENT ON COLUMN turismo.stg_destino_turistico.codigo IS 'Codigo del destino recibido desde la fuente.';
COMMENT ON COLUMN turismo.stg_destino_turistico.nombre IS 'Nombre del destino recibido desde la fuente.';
COMMENT ON COLUMN turismo.stg_destino_turistico.tipo IS 'Tipo de destino recibido como texto antes de validar contra el enum.';
COMMENT ON COLUMN turismo.stg_destino_turistico.departamento IS 'Departamento recibido como texto, a resolver contra geografia.departamento.';
COMMENT ON COLUMN turismo.stg_destino_turistico.municipio IS 'Municipio recibido como texto, a resolver contra geografia.municipio.';
COMMENT ON COLUMN turismo.stg_destino_turistico.descripcion IS 'Descripcion del destino recibida desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.direccion_referencia IS 'Referencia textual de ubicacion recibida desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.latitud IS 'Latitud recibida desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.longitud IS 'Longitud recibida desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.altitud_msnm IS 'Altitud recibida desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.dificultad IS 'Dificultad recibida como texto antes de validar contra el enum.';
COMMENT ON COLUMN turismo.stg_destino_turistico.tiempo_recomendado IS 'Tiempo sugerido recibido desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.es_area_protegida IS 'Indicador recibido desde fuente externa.';
COMMENT ON COLUMN turismo.stg_destino_turistico.fuente_codigo IS 'Codigo de fuente turistica a resolver contra turismo.fuente_turistica.';
COMMENT ON COLUMN turismo.stg_destino_turistico.fecha_carga IS 'Fecha de ingreso del registro a staging.';
COMMENT ON COLUMN turismo.stg_destino_turistico.estado_validacion IS 'Estado de validacion del registro staging.';
COMMENT ON COLUMN turismo.stg_destino_turistico.mensaje_validacion IS 'Mensaje de validacion o rechazo.';
COMMENT ON COLUMN turismo.stg_destino_turistico.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

-- ============================================================
-- Modelo dimensional BI
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.dim_region_turistica (
    id_dim_region       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_turistica_id INT NOT NULL UNIQUE REFERENCES turismo.region_turistica(id_region),
    codigo              VARCHAR(50) NOT NULL,
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    carga_id            INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.dim_region_turistica IS 'Dimension BI de regiones turisticas.';
COMMENT ON COLUMN turismo.dim_region_turistica.id_dim_region IS 'Llave surrogate de la dimension region turistica.';
COMMENT ON COLUMN turismo.dim_region_turistica.region_turistica_id IS 'Llave natural hacia turismo.region_turistica.';
COMMENT ON COLUMN turismo.dim_region_turistica.codigo IS 'Codigo de region turistica.';
COMMENT ON COLUMN turismo.dim_region_turistica.nombre IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.dim_region_turistica.descripcion IS 'Descripcion de la region turistica.';
COMMENT ON COLUMN turismo.dim_region_turistica.fecha_actualizacion IS 'Fecha de actualizacion dimensional.';
COMMENT ON COLUMN turismo.dim_region_turistica.carga_id IS 'Referencia opcional a meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.dim_geografia_turistica (
    id_dim_geografia    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departamento_id     INT NOT NULL REFERENCES geografia.departamento(id),
    municipio_id        INT REFERENCES geografia.municipio(id),
    departamento        VARCHAR(120) NOT NULL,
    municipio           VARCHAR(120),
    region_turistica_id INT REFERENCES turismo.region_turistica(id_region),
    region_turistica    VARCHAR(150),
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    carga_id            INT REFERENCES meta.carga(id),
    CONSTRAINT uq_dim_geografia_turistica UNIQUE (departamento_id, municipio_id, region_turistica_id)
);

COMMENT ON TABLE turismo.dim_geografia_turistica IS 'Dimension BI de geografia turistica derivada de geografia.departamento, geografia.municipio y turismo.region_turistica.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.id_dim_geografia IS 'Llave surrogate de la dimension geografia turistica.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.departamento_id IS 'Departamento oficial de geografia.departamento.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.municipio_id IS 'Municipio oficial de geografia.municipio cuando existe.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.departamento IS 'Nombre del departamento desnormalizado para analitica.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.municipio IS 'Nombre del municipio desnormalizado para analitica.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.region_turistica_id IS 'Region turistica asociada.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.region_turistica IS 'Nombre de region turistica desnormalizado.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.fecha_actualizacion IS 'Fecha de actualizacion dimensional.';
COMMENT ON COLUMN turismo.dim_geografia_turistica.carga_id IS 'Referencia opcional a meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.dim_categoria_turismo (
    id_dim_categoria    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_id        INT NOT NULL UNIQUE REFERENCES turismo.categoria_destino(id_categoria),
    codigo              VARCHAR(60) NOT NULL,
    nombre              VARCHAR(120) NOT NULL,
    descripcion         TEXT,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    carga_id            INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.dim_categoria_turismo IS 'Dimension BI de categorias turisticas.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.id_dim_categoria IS 'Llave surrogate de categoria BI.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.categoria_id IS 'Llave natural hacia turismo.categoria_destino.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.codigo IS 'Codigo de categoria.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.nombre IS 'Nombre de categoria.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.descripcion IS 'Descripcion de categoria.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.fecha_actualizacion IS 'Fecha de actualizacion dimensional.';
COMMENT ON COLUMN turismo.dim_categoria_turismo.carga_id IS 'Referencia opcional a meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.dim_actividad_turismo (
    id_dim_actividad    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actividad_id        INT NOT NULL UNIQUE REFERENCES turismo.actividad_turistica(id_actividad),
    codigo              VARCHAR(60) NOT NULL,
    nombre              VARCHAR(140) NOT NULL,
    descripcion         TEXT,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    carga_id            INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.dim_actividad_turismo IS 'Dimension BI de actividades turisticas.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.id_dim_actividad IS 'Llave surrogate de actividad BI.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.actividad_id IS 'Llave natural hacia turismo.actividad_turistica.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.codigo IS 'Codigo de actividad.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.nombre IS 'Nombre de actividad.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.descripcion IS 'Descripcion de actividad.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.fecha_actualizacion IS 'Fecha de actualizacion dimensional.';
COMMENT ON COLUMN turismo.dim_actividad_turismo.carga_id IS 'Referencia opcional a meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.fact_destino_turistico (
    destino_id           INT PRIMARY KEY REFERENCES turismo.destino_turistico(id_destino),
    id_dim_region        INT REFERENCES turismo.dim_region_turistica(id_dim_region),
    id_dim_geografia     INT REFERENCES turismo.dim_geografia_turistica(id_dim_geografia),
    tipo                 turismo.tipo_destino NOT NULL,
    dificultad           turismo.dificultad_destino NOT NULL,
    es_area_protegida    BOOLEAN NOT NULL,
    tiene_patrimonio     BOOLEAN NOT NULL,
    total_categorias     INT NOT NULL DEFAULT 0,
    total_actividades    INT NOT NULL DEFAULT 0,
    total_temporadas     INT NOT NULL DEFAULT 0,
    total_patrimonios    INT NOT NULL DEFAULT 0,
    puntaje_bi_catalogo  NUMERIC(10,2) NOT NULL DEFAULT 0,
    fecha_actualizacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    carga_id             INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.fact_destino_turistico IS 'Tabla de hechos BI a nivel de destino turistico; contiene indicadores derivados del catalogo curado.';
COMMENT ON COLUMN turismo.fact_destino_turistico.destino_id IS 'Destino turistico que funciona como grano del hecho.';
COMMENT ON COLUMN turismo.fact_destino_turistico.id_dim_region IS 'Dimension region turistica asociada.';
COMMENT ON COLUMN turismo.fact_destino_turistico.id_dim_geografia IS 'Dimension geografia turistica asociada.';
COMMENT ON COLUMN turismo.fact_destino_turistico.tipo IS 'Tipo de destino.';
COMMENT ON COLUMN turismo.fact_destino_turistico.dificultad IS 'Dificultad de visita.';
COMMENT ON COLUMN turismo.fact_destino_turistico.es_area_protegida IS 'Indicador de area protegida.';
COMMENT ON COLUMN turismo.fact_destino_turistico.tiene_patrimonio IS 'Indicador de reconocimiento patrimonial asociado.';
COMMENT ON COLUMN turismo.fact_destino_turistico.total_categorias IS 'Cantidad de categorias asociadas al destino.';
COMMENT ON COLUMN turismo.fact_destino_turistico.total_actividades IS 'Cantidad de actividades asociadas al destino.';
COMMENT ON COLUMN turismo.fact_destino_turistico.total_temporadas IS 'Cantidad de temporadas asociadas al destino.';
COMMENT ON COLUMN turismo.fact_destino_turistico.total_patrimonios IS 'Cantidad de patrimonios asociados al destino.';
COMMENT ON COLUMN turismo.fact_destino_turistico.puntaje_bi_catalogo IS 'Puntaje analitico calculado para priorizacion de destinos en dashboard.';
COMMENT ON COLUMN turismo.fact_destino_turistico.fecha_actualizacion IS 'Fecha de actualizacion del hecho.';
COMMENT ON COLUMN turismo.fact_destino_turistico.carga_id IS 'Referencia opcional a meta.carga.';

CREATE INDEX IF NOT EXISTS ix_fact_destino_region ON turismo.fact_destino_turistico(id_dim_region);
CREATE INDEX IF NOT EXISTS ix_fact_destino_geografia ON turismo.fact_destino_turistico(id_dim_geografia);
CREATE INDEX IF NOT EXISTS ix_fact_destino_tipo ON turismo.fact_destino_turistico(tipo);

-- ============================================================
-- Funciones de carga dimensional desde OLTP/ODS curado
-- ============================================================
CREATE OR REPLACE FUNCTION turismo.fn_cargar_dimensiones_turismo()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO turismo.dim_region_turistica (region_turistica_id, codigo, nombre, descripcion)
    SELECT r.id_region, r.codigo, r.nombre, r.descripcion
    FROM turismo.region_turistica r
    ON CONFLICT (region_turistica_id) DO UPDATE
    SET codigo = EXCLUDED.codigo,
        nombre = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion,
        fecha_actualizacion = CURRENT_TIMESTAMP;

    INSERT INTO turismo.dim_geografia_turistica (departamento_id, municipio_id, departamento, municipio, region_turistica_id, region_turistica)
    SELECT DISTINCT
        d.departamento_id,
        d.municipio_id,
        dep.nombre AS departamento,
        mun.nombre AS municipio,
        rt.id_region,
        rt.nombre AS region_turistica
    FROM turismo.destino_turistico d
    JOIN geografia.departamento dep ON dep.id = d.departamento_id
    LEFT JOIN geografia.municipio mun ON mun.id = d.municipio_id
    LEFT JOIN turismo.region_turistica rt ON rt.id_region = d.region_turistica_id
    WHERE d.activo = TRUE
    ON CONFLICT (departamento_id, municipio_id, region_turistica_id) DO UPDATE
    SET departamento = EXCLUDED.departamento,
        municipio = EXCLUDED.municipio,
        region_turistica = EXCLUDED.region_turistica,
        fecha_actualizacion = CURRENT_TIMESTAMP;

    INSERT INTO turismo.dim_categoria_turismo (categoria_id, codigo, nombre, descripcion)
    SELECT c.id_categoria, c.codigo, c.nombre, c.descripcion
    FROM turismo.categoria_destino c
    ON CONFLICT (categoria_id) DO UPDATE
    SET codigo = EXCLUDED.codigo,
        nombre = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion,
        fecha_actualizacion = CURRENT_TIMESTAMP;

    INSERT INTO turismo.dim_actividad_turismo (actividad_id, codigo, nombre, descripcion)
    SELECT a.id_actividad, a.codigo, a.nombre, a.descripcion
    FROM turismo.actividad_turistica a
    ON CONFLICT (actividad_id) DO UPDATE
    SET codigo = EXCLUDED.codigo,
        nombre = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion,
        fecha_actualizacion = CURRENT_TIMESTAMP;
END;
$$;

COMMENT ON FUNCTION turismo.fn_cargar_dimensiones_turismo() IS 'Carga o actualiza dimensiones BI del area turismo a partir del catalogo curado.';

CREATE OR REPLACE FUNCTION turismo.fn_cargar_hechos_turismo()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO turismo.fact_destino_turistico (
        destino_id,
        id_dim_region,
        id_dim_geografia,
        tipo,
        dificultad,
        es_area_protegida,
        tiene_patrimonio,
        total_categorias,
        total_actividades,
        total_temporadas,
        total_patrimonios,
        puntaje_bi_catalogo
    )
    SELECT
        d.id_destino,
        dr.id_dim_region,
        dg.id_dim_geografia,
        d.tipo,
        d.dificultad,
        d.es_area_protegida,
        CASE WHEN count(DISTINCT dp.patrimonio_id) > 0 THEN TRUE ELSE FALSE END AS tiene_patrimonio,
        count(DISTINCT dc.categoria_id) AS total_categorias,
        count(DISTINCT da.actividad_id) AS total_actividades,
        count(DISTINCT dt.temporada_id) AS total_temporadas,
        count(DISTINCT dp.patrimonio_id) AS total_patrimonios,
        (
            count(DISTINCT dc.categoria_id) * 1.00 +
            count(DISTINCT da.actividad_id) * 0.60 +
            count(DISTINCT dt.temporada_id) * 0.25 +
            count(DISTINCT dp.patrimonio_id) * 3.00 +
            CASE WHEN d.es_area_protegida THEN 1.50 ELSE 0 END +
            CASE d.dificultad WHEN 'BAJA' THEN 1.00 WHEN 'MEDIA' THEN 0.70 WHEN 'ALTA' THEN 0.40 ELSE 0.50 END
        )::NUMERIC(10,2) AS puntaje_bi_catalogo
    FROM turismo.destino_turistico d
    LEFT JOIN turismo.dim_region_turistica dr ON dr.region_turistica_id = d.region_turistica_id
    LEFT JOIN turismo.dim_geografia_turistica dg
           ON dg.departamento_id = d.departamento_id
          AND (dg.municipio_id IS NOT DISTINCT FROM d.municipio_id)
          AND (dg.region_turistica_id IS NOT DISTINCT FROM d.region_turistica_id)
    LEFT JOIN turismo.destino_categoria dc ON dc.destino_id = d.id_destino
    LEFT JOIN turismo.destino_actividad da ON da.destino_id = d.id_destino
    LEFT JOIN turismo.destino_temporada dt ON dt.destino_id = d.id_destino
    LEFT JOIN turismo.destino_patrimonio dp ON dp.destino_id = d.id_destino
    WHERE d.activo = TRUE
    GROUP BY d.id_destino, dr.id_dim_region, dg.id_dim_geografia, d.tipo, d.dificultad, d.es_area_protegida
    ON CONFLICT (destino_id) DO UPDATE
    SET id_dim_region = EXCLUDED.id_dim_region,
        id_dim_geografia = EXCLUDED.id_dim_geografia,
        tipo = EXCLUDED.tipo,
        dificultad = EXCLUDED.dificultad,
        es_area_protegida = EXCLUDED.es_area_protegida,
        tiene_patrimonio = EXCLUDED.tiene_patrimonio,
        total_categorias = EXCLUDED.total_categorias,
        total_actividades = EXCLUDED.total_actividades,
        total_temporadas = EXCLUDED.total_temporadas,
        total_patrimonios = EXCLUDED.total_patrimonios,
        puntaje_bi_catalogo = EXCLUDED.puntaje_bi_catalogo,
        fecha_actualizacion = CURRENT_TIMESTAMP;
END;
$$;

COMMENT ON FUNCTION turismo.fn_cargar_hechos_turismo() IS 'Carga o actualiza hechos BI a nivel de destino turistico.';

CREATE OR REPLACE FUNCTION turismo.fn_refrescar_bi_turismo()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_ejecucion_id INT;
BEGIN
    INSERT INTO turismo.etl_ejecucion_turismo (nombre_proceso, tipo_proceso, estado)
    VALUES ('refrescar_bi_turismo', 'DIMENSIONAL', 'INICIADO')
    RETURNING id_ejecucion INTO v_ejecucion_id;

    PERFORM turismo.fn_cargar_dimensiones_turismo();
    PERFORM turismo.fn_cargar_hechos_turismo();

    UPDATE turismo.etl_ejecucion_turismo
       SET estado = 'FINALIZADO',
           fecha_fin = CURRENT_TIMESTAMP,
           registros_leidos = (SELECT count(*) FROM turismo.destino_turistico WHERE activo = TRUE),
           registros_insertados = (SELECT count(*) FROM turismo.fact_destino_turistico),
           observacion = 'Carga dimensional de turismo ejecutada correctamente.'
     WHERE id_ejecucion = v_ejecucion_id;
EXCEPTION WHEN OTHERS THEN
    UPDATE turismo.etl_ejecucion_turismo
       SET estado = 'ERROR',
           fecha_fin = CURRENT_TIMESTAMP,
           observacion = SQLERRM
     WHERE id_ejecucion = v_ejecucion_id;
    RAISE;
END;
$$;

COMMENT ON FUNCTION turismo.fn_refrescar_bi_turismo() IS 'Orquesta carga de dimensiones y hechos del modelo BI de turismo.';

-- Ejecuta primera carga dimensional inicial.
SELECT turismo.fn_refrescar_bi_turismo();

-- ============================================================
-- Datamarts materializados para dashboards
-- ============================================================
DROP MATERIALIZED VIEW IF EXISTS turismo.mart_resumen_region;
CREATE MATERIALIZED VIEW turismo.mart_resumen_region AS
SELECT
    coalesce(dr.nombre, 'Sin region') AS region_turistica,
    count(DISTINCT f.destino_id) AS total_destinos,
    count(DISTINCT f.destino_id) FILTER (WHERE f.es_area_protegida) AS destinos_area_protegida,
    count(DISTINCT f.destino_id) FILTER (WHERE f.tiene_patrimonio) AS destinos_patrimonio,
    round(avg(f.puntaje_bi_catalogo), 2) AS puntaje_promedio_bi,
    max(f.puntaje_bi_catalogo) AS puntaje_maximo_bi
FROM turismo.fact_destino_turistico f
LEFT JOIN turismo.dim_region_turistica dr ON dr.id_dim_region = f.id_dim_region
GROUP BY coalesce(dr.nombre, 'Sin region')
WITH DATA;

COMMENT ON MATERIALIZED VIEW turismo.mart_resumen_region IS 'Datamart BI con resumen de destinos por region turistica.';

CREATE UNIQUE INDEX IF NOT EXISTS ux_mart_resumen_region ON turismo.mart_resumen_region(region_turistica);

DROP MATERIALIZED VIEW IF EXISTS turismo.mart_destinos_recomendados_bi;
CREATE MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi AS
SELECT
    d.codigo,
    d.nombre AS destino,
    dep.nombre AS departamento,
    mun.nombre AS municipio,
    dr.nombre AS region_turistica,
    f.tipo,
    f.dificultad,
    f.es_area_protegida,
    f.tiene_patrimonio,
    f.total_categorias,
    f.total_actividades,
    f.total_patrimonios,
    f.puntaje_bi_catalogo
FROM turismo.fact_destino_turistico f
JOIN turismo.destino_turistico d ON d.id_destino = f.destino_id
JOIN geografia.departamento dep ON dep.id = d.departamento_id
LEFT JOIN geografia.municipio mun ON mun.id = d.municipio_id
LEFT JOIN turismo.dim_region_turistica dr ON dr.id_dim_region = f.id_dim_region
ORDER BY f.puntaje_bi_catalogo DESC, d.nombre
WITH DATA;

COMMENT ON MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi IS 'Datamart BI de destinos priorizados por puntaje de catalogo.';

CREATE UNIQUE INDEX IF NOT EXISTS ux_mart_destinos_recomendados_codigo ON turismo.mart_destinos_recomendados_bi(codigo);

DROP MATERIALIZED VIEW IF EXISTS turismo.mart_patrimonio_turistico;
CREATE MATERIALIZED VIEW turismo.mart_patrimonio_turistico AS
SELECT
    p.codigo,
    p.nombre AS patrimonio,
    p.tipo,
    p.organismo,
    p.anio_inscripcion,
    count(DISTINCT dp.destino_id) AS destinos_asociados,
    string_agg(DISTINCT d.nombre, ', ' ORDER BY d.nombre) AS destinos
FROM turismo.patrimonio_turistico p
LEFT JOIN turismo.destino_patrimonio dp ON dp.patrimonio_id = p.id_patrimonio
LEFT JOIN turismo.destino_turistico d ON d.id_destino = dp.destino_id
GROUP BY p.codigo, p.nombre, p.tipo, p.organismo, p.anio_inscripcion
WITH DATA;

COMMENT ON MATERIALIZED VIEW turismo.mart_patrimonio_turistico IS 'Datamart BI de patrimonios y destinos asociados.';

CREATE UNIQUE INDEX IF NOT EXISTS ux_mart_patrimonio_codigo ON turismo.mart_patrimonio_turistico(codigo);

CREATE OR REPLACE VIEW turismo.vw_bi_kpis_generales AS
SELECT
    (SELECT count(*) FROM turismo.destino_turistico WHERE activo = TRUE) AS total_destinos,
    (SELECT count(*) FROM turismo.destino_turistico WHERE activo = TRUE AND es_area_protegida = TRUE) AS total_destinos_area_protegida,
    (SELECT count(*) FROM turismo.patrimonio_turistico) AS total_patrimonios,
    (SELECT count(*) FROM turismo.region_turistica) AS total_regiones_turisticas,
    (SELECT count(*) FROM turismo.ruta_turistica) AS total_rutas,
    (SELECT round(avg(puntaje_bi_catalogo), 2) FROM turismo.fact_destino_turistico) AS puntaje_promedio_catalogo;

COMMENT ON VIEW turismo.vw_bi_kpis_generales IS 'Vista BI con indicadores generales del area turismo.';

CREATE OR REPLACE VIEW turismo.vw_bi_alertas_calidad AS
SELECT
    'DESTINO_SIN_MUNICIPIO' AS tipo_alerta,
    d.codigo,
    d.nombre,
    'El destino no tiene municipio resuelto contra geografia.municipio.' AS descripcion
FROM turismo.destino_turistico d
WHERE d.municipio_id IS NULL
UNION ALL
SELECT
    'DESTINO_SIN_CATEGORIA' AS tipo_alerta,
    d.codigo,
    d.nombre,
    'El destino no tiene categorias asociadas.' AS descripcion
FROM turismo.destino_turistico d
WHERE NOT EXISTS (SELECT 1 FROM turismo.destino_categoria dc WHERE dc.destino_id = d.id_destino)
UNION ALL
SELECT
    'DESTINO_SIN_ACTIVIDAD' AS tipo_alerta,
    d.codigo,
    d.nombre,
    'El destino no tiene actividades asociadas.' AS descripcion
FROM turismo.destino_turistico d
WHERE NOT EXISTS (SELECT 1 FROM turismo.destino_actividad da WHERE da.destino_id = d.id_destino);

COMMENT ON VIEW turismo.vw_bi_alertas_calidad IS 'Vista de control de calidad para detectar datos incompletos en turismo.';
