-- ============================================================
-- Flyway migration: V20260705111200__crear_staging_y_control_etl_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- ============================================================

CREATE TABLE IF NOT EXISTS turismo.etl_job (
    id_job INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL UNIQUE,
    descripcion TEXT,
    frecuencia_sugerida VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS turismo.etl_ejecucion (
    id_ejecucion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_job INT NOT NULL REFERENCES turismo.etl_job(id_job),
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_fin TIMESTAMPTZ,
    estado VARCHAR(20) NOT NULL DEFAULT 'INICIADO',
    filas_insertadas BIGINT NOT NULL DEFAULT 0,
    filas_actualizadas BIGINT NOT NULL DEFAULT 0,
    filas_error BIGINT NOT NULL DEFAULT 0,
    mensaje TEXT,
    CONSTRAINT ck_etl_ejecucion_estado
        CHECK (estado IN ('INICIADO', 'EXITOSO', 'ERROR', 'ADVERTENCIA'))
);

CREATE TABLE IF NOT EXISTS turismo.etl_validacion (
    id_validacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_ejecucion BIGINT REFERENCES turismo.etl_ejecucion(id_ejecucion),
    entidad VARCHAR(120) NOT NULL,
    regla VARCHAR(220) NOT NULL,
    nivel VARCHAR(20) NOT NULL DEFAULT 'INFO',
    total_registros BIGINT NOT NULL DEFAULT 0,
    total_observaciones BIGINT NOT NULL DEFAULT 0,
    detalle TEXT,
    fecha_validacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_etl_validacion_nivel
        CHECK (nivel IN ('INFO', 'ADVERTENCIA', 'ERROR'))
);

INSERT INTO turismo.etl_job (nombre, descripcion, frecuencia_sugerida)
VALUES
    (
        'BI_TURISMO_CARGA_COMPLETA',
        'Carga de dimensiones, hechos y datamarts desde las tablas base del esquema turismo.',
        'Diaria o bajo demanda'
    ),
    (
        'BI_TURISMO_VALIDACION_CALIDAD',
        'Validaciones de calidad de datos para destinos, fuentes, ubicacion, categorias y actividades.',
        'Diaria o antes de publicar'
    ),
    (
        'BI_TURISMO_REFRESH_MARTS',
        'Refresco de vistas materializadas para tableros BI.',
        'Despues de cada carga'
    )
ON CONFLICT (nombre) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    frecuencia_sugerida = EXCLUDED.frecuencia_sugerida,
    activo = TRUE;

-- ============================================================
-- 2. Zona staging para carga futura colaborativa
-- ============================================================

CREATE TABLE IF NOT EXISTS turismo.stg_fuente_raw (
    id_stg_fuente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_archivo VARCHAR(260),
    codigo_fuente VARCHAR(120),
    nombre_fuente VARCHAR(180),
    institucion VARCHAR(180),
    tipo_fuente VARCHAR(80),
    url VARCHAR(600),
    fecha_consulta DATE,
    notas TEXT,
    raw_payload JSONB,
    cargado_por VARCHAR(120) NOT NULL DEFAULT CURRENT_USER,
    cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    procesado BOOLEAN NOT NULL DEFAULT FALSE,
    mensaje_proceso TEXT
);

CREATE TABLE IF NOT EXISTS turismo.stg_destino_raw (
    id_stg_destino BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_archivo VARCHAR(260),
    codigo_destino VARCHAR(120),
    nombre_destino VARCHAR(180) NOT NULL,
    tipo VARCHAR(80),
    departamento VARCHAR(100),
    municipio VARCHAR(120),
    region_turistica VARCHAR(140),
    descripcion TEXT,
    direccion_referencia VARCHAR(350),
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    altitud_msnm INT,
    dificultad VARCHAR(40),
    tiempo_recomendado VARCHAR(80),
    costo_aprox_nacional_q NUMERIC(10,2),
    costo_aprox_extranjero_q NUMERIC(10,2),
    horario VARCHAR(180),
    es_area_protegida BOOLEAN,
    codigo_fuente_principal VARCHAR(120),
    url_fuente VARCHAR(600),
    raw_payload JSONB,
    cargado_por VARCHAR(120) NOT NULL DEFAULT CURRENT_USER,
    cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    procesado BOOLEAN NOT NULL DEFAULT FALSE,
    mensaje_proceso TEXT
);

CREATE TABLE IF NOT EXISTS turismo.stg_metricas_destino_raw (
    id_stg_metrica BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_archivo VARCHAR(260),
    fecha_metrica DATE NOT NULL,
    codigo_destino VARCHAR(120),
    nombre_destino VARCHAR(180) NOT NULL,
    fuente_metrica VARCHAR(180),
    visitantes_nacionales INT,
    visitantes_extranjeros INT,
    calificacion_promedio NUMERIC(4,2),
    cantidad_resenas INT,
    busquedas_web INT,
    menciones_redes INT,
    raw_payload JSONB,
    cargado_por VARCHAR(120) NOT NULL DEFAULT CURRENT_USER,
    cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    procesado BOOLEAN NOT NULL DEFAULT FALSE,
    mensaje_proceso TEXT,
    CONSTRAINT ck_stg_metricas_visitantes_nacionales
        CHECK (visitantes_nacionales IS NULL OR visitantes_nacionales >= 0),
    CONSTRAINT ck_stg_metricas_visitantes_extranjeros
        CHECK (visitantes_extranjeros IS NULL OR visitantes_extranjeros >= 0),
    CONSTRAINT ck_stg_metricas_calificacion
        CHECK (calificacion_promedio IS NULL OR calificacion_promedio BETWEEN 0 AND 5),
    CONSTRAINT ck_stg_metricas_resenas
        CHECK (cantidad_resenas IS NULL OR cantidad_resenas >= 0),
    CONSTRAINT ck_stg_metricas_busquedas
        CHECK (busquedas_web IS NULL OR busquedas_web >= 0),
    CONSTRAINT ck_stg_metricas_menciones
        CHECK (menciones_redes IS NULL OR menciones_redes >= 0)
);

CREATE TABLE IF NOT EXISTS turismo.stg_evento_usuario_raw (
    id_stg_evento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_archivo VARCHAR(260),
    fecha_evento DATE NOT NULL,
    codigo_destino VARCHAR(120),
    nombre_destino VARCHAR(180),
    codigo_ruta VARCHAR(120),
    tipo_evento VARCHAR(60) NOT NULL,
    canal VARCHAR(80),
    dispositivo VARCHAR(80),
    pais_usuario VARCHAR(80),
    conteo INT NOT NULL DEFAULT 1,

    -- Banderas derivadas para analitica.
    -- Se mantienen aunque exista tipo_evento, porque facilitan agregaciones BI.
    vista_destino BOOLEAN NOT NULL DEFAULT FALSE,
    click_ruta BOOLEAN NOT NULL DEFAULT FALSE,
    favorito BOOLEAN NOT NULL DEFAULT FALSE,
    compartido BOOLEAN NOT NULL DEFAULT FALSE,
    busqueda BOOLEAN NOT NULL DEFAULT FALSE,
    consulta_patrimonio BOOLEAN NOT NULL DEFAULT FALSE,

    raw_payload JSONB,
    cargado_por VARCHAR(120) NOT NULL DEFAULT CURRENT_USER,
    cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    procesado BOOLEAN NOT NULL DEFAULT FALSE,
    mensaje_proceso TEXT,

    CONSTRAINT ck_stg_evento_usuario_tipo
        CHECK (tipo_evento IN (
            'BUSQUEDA',
            'VISTA_DESTINO',
            'CLICK_RUTA',
            'FAVORITO',
            'COMPARTIDO',
            'CONSULTA_PATRIMONIO',
            'OTRO'
        )),
    CONSTRAINT ck_stg_evento_usuario_conteo
        CHECK (conteo >= 0)
);

-- ============================================================
-- 3. Indices
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_etl_ejecucion_job_fecha
    ON turismo.etl_ejecucion(id_job, fecha_inicio DESC);

CREATE INDEX IF NOT EXISTS idx_etl_validacion_entidad_fecha
    ON turismo.etl_validacion(entidad, fecha_validacion DESC);

CREATE INDEX IF NOT EXISTS idx_stg_fuente_raw_codigo
    ON turismo.stg_fuente_raw(codigo_fuente);

CREATE INDEX IF NOT EXISTS idx_stg_fuente_raw_procesado
    ON turismo.stg_fuente_raw(procesado);

CREATE INDEX IF NOT EXISTS idx_stg_destino_raw_codigo
    ON turismo.stg_destino_raw(codigo_destino);

CREATE INDEX IF NOT EXISTS idx_stg_destino_raw_nombre
    ON turismo.stg_destino_raw(nombre_destino);

CREATE INDEX IF NOT EXISTS idx_stg_destino_raw_ubicacion
    ON turismo.stg_destino_raw(departamento, municipio);

CREATE INDEX IF NOT EXISTS idx_stg_destino_raw_procesado
    ON turismo.stg_destino_raw(procesado);

CREATE INDEX IF NOT EXISTS idx_stg_metricas_destino_fecha
    ON turismo.stg_metricas_destino_raw(fecha_metrica, nombre_destino);

CREATE INDEX IF NOT EXISTS idx_stg_metricas_destino_codigo_fecha
    ON turismo.stg_metricas_destino_raw(codigo_destino, fecha_metrica);

CREATE INDEX IF NOT EXISTS idx_stg_metricas_destino_procesado
    ON turismo.stg_metricas_destino_raw(procesado);

CREATE INDEX IF NOT EXISTS idx_stg_evento_usuario_fecha
    ON turismo.stg_evento_usuario_raw(fecha_evento, tipo_evento);

CREATE INDEX IF NOT EXISTS idx_stg_evento_usuario_destino_fecha
    ON turismo.stg_evento_usuario_raw(codigo_destino, fecha_evento);

CREATE INDEX IF NOT EXISTS idx_stg_evento_usuario_procesado
    ON turismo.stg_evento_usuario_raw(procesado);

-- ============================================================
-- 4. Comentarios para diccionario de datos
-- ============================================================

COMMENT ON TABLE turismo.etl_job IS 'Catálogo de procesos ETL definidos para el módulo de turismo.';
COMMENT ON COLUMN turismo.etl_job.id_job IS 'Identificador único del job ETL.';
COMMENT ON COLUMN turismo.etl_job.nombre IS 'Nombre único del proceso ETL.';
COMMENT ON COLUMN turismo.etl_job.descripcion IS 'Descripción del objetivo del proceso ETL.';
COMMENT ON COLUMN turismo.etl_job.frecuencia_sugerida IS 'Frecuencia sugerida de ejecución del proceso.';
COMMENT ON COLUMN turismo.etl_job.activo IS 'Indica si el job ETL está activo.';
COMMENT ON COLUMN turismo.etl_job.creado_en IS 'Fecha y hora de creación del registro.';

COMMENT ON TABLE turismo.etl_ejecucion IS 'Registro histórico de ejecuciones de procesos ETL del módulo turismo.';
COMMENT ON COLUMN turismo.etl_ejecucion.id_ejecucion IS 'Identificador único de la ejecución ETL.';
COMMENT ON COLUMN turismo.etl_ejecucion.id_job IS 'Job ETL ejecutado.';
COMMENT ON COLUMN turismo.etl_ejecucion.fecha_inicio IS 'Fecha y hora de inicio de la ejecución.';
COMMENT ON COLUMN turismo.etl_ejecucion.fecha_fin IS 'Fecha y hora de finalización de la ejecución.';
COMMENT ON COLUMN turismo.etl_ejecucion.estado IS 'Estado de la ejecución: INICIADO, EXITOSO, ERROR o ADVERTENCIA.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_insertadas IS 'Cantidad de filas insertadas durante la ejecución.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_actualizadas IS 'Cantidad de filas actualizadas durante la ejecución.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_error IS 'Cantidad de filas con error durante la ejecución.';
COMMENT ON COLUMN turismo.etl_ejecucion.mensaje IS 'Mensaje de resultado, diagnóstico o error de la ejecución.';

COMMENT ON TABLE turismo.etl_validacion IS 'Resultados de validaciones de calidad ejecutadas sobre datos de turismo.';
COMMENT ON COLUMN turismo.etl_validacion.id_validacion IS 'Identificador único de la validación.';
COMMENT ON COLUMN turismo.etl_validacion.id_ejecucion IS 'Ejecución ETL asociada a la validación, cuando aplique.';
COMMENT ON COLUMN turismo.etl_validacion.entidad IS 'Entidad, tabla o componente validado.';
COMMENT ON COLUMN turismo.etl_validacion.regla IS 'Regla de calidad aplicada.';
COMMENT ON COLUMN turismo.etl_validacion.nivel IS 'Nivel de severidad de la validación: INFO, ADVERTENCIA o ERROR.';
COMMENT ON COLUMN turismo.etl_validacion.total_registros IS 'Total de registros evaluados por la validación.';
COMMENT ON COLUMN turismo.etl_validacion.total_observaciones IS 'Total de observaciones encontradas por la validación.';
COMMENT ON COLUMN turismo.etl_validacion.detalle IS 'Detalle de hallazgos o explicación de la validación.';
COMMENT ON COLUMN turismo.etl_validacion.fecha_validacion IS 'Fecha y hora en que se ejecutó la validación.';

COMMENT ON TABLE turismo.stg_fuente_raw IS 'Tabla staging para recibir fuentes turísticas crudas antes de validarlas y cargarlas al modelo curado.';
COMMENT ON COLUMN turismo.stg_fuente_raw.id_stg_fuente IS 'Identificador del registro crudo de fuente turística.';
COMMENT ON COLUMN turismo.stg_fuente_raw.nombre_archivo IS 'Nombre del archivo origen del registro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.codigo_fuente IS 'Código propuesto para la fuente turística.';
COMMENT ON COLUMN turismo.stg_fuente_raw.nombre_fuente IS 'Nombre de la fuente turística.';
COMMENT ON COLUMN turismo.stg_fuente_raw.institucion IS 'Institución responsable o asociada a la fuente.';
COMMENT ON COLUMN turismo.stg_fuente_raw.tipo_fuente IS 'Tipo de fuente: institucional, internacional, municipal, cultural, conservación u otro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.url IS 'URL de consulta o respaldo de la fuente.';
COMMENT ON COLUMN turismo.stg_fuente_raw.fecha_consulta IS 'Fecha en que se consultó la fuente.';
COMMENT ON COLUMN turismo.stg_fuente_raw.notas IS 'Notas adicionales sobre la fuente.';
COMMENT ON COLUMN turismo.stg_fuente_raw.raw_payload IS 'Registro original en formato JSONB para auditoría o reproceso.';
COMMENT ON COLUMN turismo.stg_fuente_raw.cargado_por IS 'Usuario de base de datos que cargó el registro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.procesado IS 'Indica si el registro ya fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_fuente_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento del registro.';

COMMENT ON TABLE turismo.stg_destino_raw IS 'Tabla staging para recibir destinos turísticos crudos antes de validarlos y cargarlos al modelo curado.';
COMMENT ON COLUMN turismo.stg_destino_raw.id_stg_destino IS 'Identificador del registro crudo de destino turístico.';
COMMENT ON COLUMN turismo.stg_destino_raw.nombre_archivo IS 'Nombre del archivo origen del registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.codigo_destino IS 'Código propuesto para el destino turístico.';
COMMENT ON COLUMN turismo.stg_destino_raw.nombre_destino IS 'Nombre del destino turístico.';
COMMENT ON COLUMN turismo.stg_destino_raw.tipo IS 'Tipo propuesto del destino turístico.';
COMMENT ON COLUMN turismo.stg_destino_raw.departamento IS 'Departamento reportado por la fuente.';
COMMENT ON COLUMN turismo.stg_destino_raw.municipio IS 'Municipio reportado por la fuente.';
COMMENT ON COLUMN turismo.stg_destino_raw.region_turistica IS 'Región turística reportada o propuesta.';
COMMENT ON COLUMN turismo.stg_destino_raw.descripcion IS 'Descripción del destino turístico.';
COMMENT ON COLUMN turismo.stg_destino_raw.direccion_referencia IS 'Referencia textual de ubicación del destino.';
COMMENT ON COLUMN turismo.stg_destino_raw.latitud IS 'Latitud reportada por la fuente, si existe.';
COMMENT ON COLUMN turismo.stg_destino_raw.longitud IS 'Longitud reportada por la fuente, si existe.';
COMMENT ON COLUMN turismo.stg_destino_raw.altitud_msnm IS 'Altitud en metros sobre el nivel del mar reportada por la fuente, si existe.';
COMMENT ON COLUMN turismo.stg_destino_raw.dificultad IS 'Dificultad sugerida o reportada para visitar el destino.';
COMMENT ON COLUMN turismo.stg_destino_raw.tiempo_recomendado IS 'Tiempo recomendado de visita reportado o propuesto.';
COMMENT ON COLUMN turismo.stg_destino_raw.costo_aprox_nacional_q IS 'Costo aproximado para visitante nacional, si la fuente lo reporta.';
COMMENT ON COLUMN turismo.stg_destino_raw.costo_aprox_extranjero_q IS 'Costo aproximado para visitante extranjero, si la fuente lo reporta.';
COMMENT ON COLUMN turismo.stg_destino_raw.horario IS 'Horario reportado por la fuente, si existe.';
COMMENT ON COLUMN turismo.stg_destino_raw.es_area_protegida IS 'Indica si el destino se reporta como área protegida.';
COMMENT ON COLUMN turismo.stg_destino_raw.codigo_fuente_principal IS 'Código de la fuente principal que respalda el destino.';
COMMENT ON COLUMN turismo.stg_destino_raw.url_fuente IS 'URL específica de respaldo del destino.';
COMMENT ON COLUMN turismo.stg_destino_raw.raw_payload IS 'Registro original en formato JSONB para auditoría o reproceso.';
COMMENT ON COLUMN turismo.stg_destino_raw.cargado_por IS 'Usuario de base de datos que cargó el registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.procesado IS 'Indica si el registro ya fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_destino_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento del registro.';

COMMENT ON TABLE turismo.stg_metricas_destino_raw IS 'Tabla staging para recibir métricas crudas de destinos turísticos antes de validarlas y cargarlas al modelo analítico.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.id_stg_metrica IS 'Identificador del registro crudo de métrica turística.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.nombre_archivo IS 'Nombre del archivo origen del registro.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.fecha_metrica IS 'Fecha de referencia de la métrica.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.codigo_destino IS 'Código del destino turístico relacionado con la métrica.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.nombre_destino IS 'Nombre del destino turístico relacionado con la métrica.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.fuente_metrica IS 'Fuente que reporta la métrica.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.visitantes_nacionales IS 'Cantidad de visitantes nacionales reportados.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.visitantes_extranjeros IS 'Cantidad de visitantes extranjeros reportados.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.calificacion_promedio IS 'Calificación promedio reportada para el destino, de 0 a 5.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cantidad_resenas IS 'Cantidad de reseñas reportadas.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.busquedas_web IS 'Cantidad de búsquedas web asociadas al destino.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.menciones_redes IS 'Cantidad de menciones en redes sociales asociadas al destino.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.raw_payload IS 'Registro original en formato JSONB para auditoría o reproceso.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cargado_por IS 'Usuario de base de datos que cargó el registro.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.procesado IS 'Indica si el registro ya fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento del registro.';

COMMENT ON TABLE turismo.stg_evento_usuario_raw IS 'Tabla staging para recibir eventos agregados de usuario antes de validarlos y cargarlos al modelo analítico de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.id_stg_evento IS 'Identificador del registro crudo de evento de usuario.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.nombre_archivo IS 'Nombre del archivo origen del registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.fecha_evento IS 'Fecha del evento o del agregado de eventos.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.codigo_destino IS 'Código del destino turístico relacionado con el evento, cuando aplique.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.nombre_destino IS 'Nombre del destino turístico relacionado con el evento, cuando aplique.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.codigo_ruta IS 'Código de la ruta turística relacionada con el evento, cuando aplique.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.tipo_evento IS 'Tipo de evento reportado: BUSQUEDA, VISTA_DESTINO, CLICK_RUTA, FAVORITO, COMPARTIDO, CONSULTA_PATRIMONIO u OTRO.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.canal IS 'Canal donde se registró el evento, por ejemplo web, móvil o carga simulada.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.dispositivo IS 'Tipo de dispositivo reportado para el evento.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.pais_usuario IS 'País reportado del usuario.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.conteo IS 'Cantidad de eventos agregados en el registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.vista_destino IS 'Bandera que indica si el evento corresponde a visualización de destino.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.click_ruta IS 'Bandera que indica si el evento corresponde a clic o consulta de ruta turística.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.favorito IS 'Bandera que indica si el evento corresponde a marcado como favorito.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.compartido IS 'Bandera que indica si el evento corresponde a compartir un destino o ruta.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.busqueda IS 'Bandera que indica si el evento corresponde a una búsqueda.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.consulta_patrimonio IS 'Bandera que indica si el evento corresponde a consulta de patrimonio turístico.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.raw_payload IS 'Registro original en formato JSONB para auditoría o reproceso.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.cargado_por IS 'Usuario de base de datos que cargó el registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.procesado IS 'Indica si el registro ya fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento del registro.';

-- ============================================================
-- 5. Registros simulados mínimos de staging
--    Sirven para probar la estructura sin depender todavía del ETL real.
-- ============================================================

INSERT INTO turismo.stg_evento_usuario_raw (
    fecha_evento,
    codigo_destino,
    nombre_destino,
    codigo_ruta,
    tipo_evento,
    canal,
    dispositivo,
    pais_usuario,
    conteo,
    vista_destino,
    click_ruta,
    favorito,
    compartido,
    busqueda,
    consulta_patrimonio,
    raw_payload
)
VALUES
    (
        CURRENT_DATE,
        'ANTIGUA_GUATEMALA',
        'Antigua Guatemala',
        NULL,
        'VISTA_DESTINO',
        'web',
        'desktop',
        'Guatemala',
        12,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        '{"origen":"seed_staging","descripcion":"Evento agregado simulado para validar staging de turismo"}'::jsonb
    ),
    (
        CURRENT_DATE,
        'PARQUE_NACIONAL_TIKAL',
        'Parque Nacional Tikal',
        NULL,
        'CONSULTA_PATRIMONIO',
        'web',
        'mobile',
        'Guatemala',
        8,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        '{"origen":"seed_staging","descripcion":"Consulta simulada de patrimonio turistico"}'::jsonb
    ),
    (
        CURRENT_DATE,
        NULL,
        NULL,
        'RUTA_PATRIMONIO_UNESCO',
        'CLICK_RUTA',
        'web',
        'desktop',
        'Guatemala',
        5,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        '{"origen":"seed_staging","descripcion":"Clic simulado sobre ruta turistica"}'::jsonb
    ),
    (
        CURRENT_DATE,
        NULL,
        'Lago de Atitlan',
        NULL,
        'BUSQUEDA',
        'web',
        'mobile',
        'Guatemala',
        15,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        '{"origen":"seed_staging","descripcion":"Busqueda simulada de destino turistico"}'::jsonb
    )
ON CONFLICT DO NOTHING;
