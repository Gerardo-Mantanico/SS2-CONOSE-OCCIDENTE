-- ============================================================
-- Flyway migration: V20260705111500__crear_staging_y_control_etl_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: crear zona staging y control de procesos ETL/ELT
-- ============================================================


-- --------------------------
-- 1. Control de jobs ETL
-- --------------------------
CREATE TABLE turismo.etl_job (
  id_job INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  descripcion TEXT,
  frecuencia_sugerida VARCHAR(80),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.etl_ejecucion (
  id_ejecucion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_job INT NOT NULL REFERENCES turismo.etl_job(id_job),
  fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_fin TIMESTAMPTZ,
  estado VARCHAR(20) NOT NULL DEFAULT 'INICIADO',
  filas_insertadas BIGINT NOT NULL DEFAULT 0,
  filas_actualizadas BIGINT NOT NULL DEFAULT 0,
  filas_error BIGINT NOT NULL DEFAULT 0,
  mensaje TEXT,
  CONSTRAINT ck_etl_ejecucion_estado CHECK (estado IN ('INICIADO','EXITOSO','ERROR','ADVERTENCIA'))
);

CREATE TABLE turismo.etl_validacion (
  id_validacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_ejecucion BIGINT NULL REFERENCES turismo.etl_ejecucion(id_ejecucion),
  entidad VARCHAR(120) NOT NULL,
  regla VARCHAR(220) NOT NULL,
  nivel VARCHAR(20) NOT NULL DEFAULT 'INFO',
  total_registros BIGINT NOT NULL DEFAULT 0,
  total_observaciones BIGINT NOT NULL DEFAULT 0,
  detalle TEXT,
  fecha_validacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_etl_validacion_nivel CHECK (nivel IN ('INFO','ADVERTENCIA','ERROR'))
);

INSERT INTO turismo.etl_job (nombre, descripcion, frecuencia_sugerida) VALUES
  ('BI_TURISMO_CARGA_COMPLETA', 'Carga de dimensiones, hechos y datamarts desde las tablas base del esquema turismo.', 'Diaria o bajo demanda'),
  ('BI_TURISMO_VALIDACION_CALIDAD', 'Validaciones de calidad de datos para destinos, fuentes, ubicacion, categorias y actividades.', 'Diaria o antes de publicar'),
  ('BI_TURISMO_REFRESH_MARTS', 'Refresco de vistas materializadas para tableros BI.', 'Despues de cada carga')
ON CONFLICT (nombre) DO NOTHING;

-- --------------------------
-- 2. Zona staging para carga futura colaborativa
--    Estas tablas permiten que otros colaboradores carguen CSV/API sin tocar el modelo curado.
-- --------------------------
CREATE TABLE turismo.stg_fuente_raw (
  id_stg_fuente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre_archivo VARCHAR(260),
  nombre_fuente VARCHAR(180),
  tipo_fuente VARCHAR(80),
  url VARCHAR(600),
  fecha_consulta DATE,
  notas TEXT,
  raw_payload JSONB,
  cargado_por VARCHAR(120) DEFAULT CURRENT_USER,
  cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  procesado BOOLEAN NOT NULL DEFAULT FALSE,
  mensaje_proceso TEXT
);

CREATE TABLE turismo.stg_destino_raw (
  id_stg_destino BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre_archivo VARCHAR(260),
  nombre_destino VARCHAR(180) NOT NULL,
  tipo VARCHAR(80),
  departamento VARCHAR(80),
  municipio VARCHAR(120),
  region_turistica VARCHAR(120),
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
  url_fuente VARCHAR(600),
  raw_payload JSONB,
  cargado_por VARCHAR(120) DEFAULT CURRENT_USER,
  cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  procesado BOOLEAN NOT NULL DEFAULT FALSE,
  mensaje_proceso TEXT
);

CREATE TABLE turismo.stg_metricas_destino_raw (
  id_stg_metrica BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre_archivo VARCHAR(260),
  fecha_metrica DATE NOT NULL,
  nombre_destino VARCHAR(180) NOT NULL,
  fuente_metrica VARCHAR(180),
  visitantes_nacionales INT,
  visitantes_extranjeros INT,
  calificacion_promedio NUMERIC(4,2),
  cantidad_resenas INT,
  busquedas_web INT,
  menciones_redes INT,
  raw_payload JSONB,
  cargado_por VARCHAR(120) DEFAULT CURRENT_USER,
  cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  procesado BOOLEAN NOT NULL DEFAULT FALSE,
  mensaje_proceso TEXT
);

CREATE TABLE turismo.stg_evento_usuario_raw (
  id_stg_evento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fecha_evento DATE NOT NULL,
  nombre_destino VARCHAR(180),
  tipo_evento VARCHAR(60) NOT NULL, -- BUSQUEDA, VISTA_DESTINO, CLICK_RUTA, FAVORITO, COMPARTIDO
  canal VARCHAR(80),
  dispositivo VARCHAR(80),
  pais_usuario VARCHAR(80),
  conteo INT NOT NULL DEFAULT 1,
  raw_payload JSONB,
  cargado_por VARCHAR(120) DEFAULT CURRENT_USER,
  cargado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  procesado BOOLEAN NOT NULL DEFAULT FALSE,
  mensaje_proceso TEXT
);

CREATE INDEX idx_etl_ejecucion_job_fecha ON turismo.etl_ejecucion(id_job, fecha_inicio DESC);
CREATE INDEX idx_etl_validacion_entidad_fecha ON turismo.etl_validacion(entidad, fecha_validacion DESC);
CREATE INDEX idx_stg_destino_raw_nombre ON turismo.stg_destino_raw(nombre_destino);
CREATE INDEX idx_stg_metricas_destino_fecha ON turismo.stg_metricas_destino_raw(fecha_metrica, nombre_destino);
CREATE INDEX idx_stg_evento_usuario_fecha ON turismo.stg_evento_usuario_raw(fecha_evento, tipo_evento);

-- Comentarios para diccionario de datos generado desde metadata.
COMMENT ON TABLE turismo.etl_job IS 'Tabla de control para procesos ETL del area de turismo.';
COMMENT ON COLUMN turismo.etl_job.id_job IS 'Identificador del job ETL.';
COMMENT ON COLUMN turismo.etl_job.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.etl_job.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.etl_job.frecuencia_sugerida IS 'Frecuencia sugerida de ejecucion.';
COMMENT ON COLUMN turismo.etl_job.activo IS 'Indica si el registro se encuentra activo.';
COMMENT ON COLUMN turismo.etl_job.creado_en IS 'Fecha y hora de creacion del registro.';

COMMENT ON TABLE turismo.etl_ejecucion IS 'Tabla de control para procesos ETL del area de turismo.';
COMMENT ON COLUMN turismo.etl_ejecucion.id_ejecucion IS 'Identificador de la ejecucion ETL.';
COMMENT ON COLUMN turismo.etl_ejecucion.id_job IS 'Identificador del job ETL.';
COMMENT ON COLUMN turismo.etl_ejecucion.fecha_inicio IS 'Fecha y hora de inicio de la ejecucion.';
COMMENT ON COLUMN turismo.etl_ejecucion.fecha_fin IS 'Fecha y hora de finalizacion de la ejecucion.';
COMMENT ON COLUMN turismo.etl_ejecucion.estado IS 'Estado de la ejecucion o validacion.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_insertadas IS 'Cantidad de filas insertadas.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_actualizadas IS 'Cantidad de filas actualizadas.';
COMMENT ON COLUMN turismo.etl_ejecucion.filas_error IS 'Cantidad de filas con error.';
COMMENT ON COLUMN turismo.etl_ejecucion.mensaje IS 'Mensaje de resultado o diagnostico.';

COMMENT ON TABLE turismo.etl_validacion IS 'Tabla de control para procesos ETL del area de turismo.';
COMMENT ON COLUMN turismo.etl_validacion.id_validacion IS 'Identificador de la validacion.';
COMMENT ON COLUMN turismo.etl_validacion.id_ejecucion IS 'Identificador de la ejecucion ETL.';
COMMENT ON COLUMN turismo.etl_validacion.entidad IS 'Entidad o tabla validada.';
COMMENT ON COLUMN turismo.etl_validacion.regla IS 'Regla de validacion aplicada.';
COMMENT ON COLUMN turismo.etl_validacion.nivel IS 'Nivel de severidad de la validacion.';
COMMENT ON COLUMN turismo.etl_validacion.total_registros IS 'Total de registros evaluados.';
COMMENT ON COLUMN turismo.etl_validacion.total_observaciones IS 'Total de observaciones encontradas.';
COMMENT ON COLUMN turismo.etl_validacion.detalle IS 'Detalle de la validacion.';
COMMENT ON COLUMN turismo.etl_validacion.fecha_validacion IS 'Fecha y hora de validacion.';

COMMENT ON TABLE turismo.stg_fuente_raw IS 'Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.';
COMMENT ON COLUMN turismo.stg_fuente_raw.id_stg_fuente IS 'Campo id stg fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.nombre_archivo IS 'Nombre del archivo origen.';
COMMENT ON COLUMN turismo.stg_fuente_raw.nombre_fuente IS 'Campo nombre fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.tipo_fuente IS 'Campo tipo fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.url IS 'Campo url del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.fecha_consulta IS 'Campo fecha consulta del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.notas IS 'Campo notas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_fuente_raw.raw_payload IS 'Registro original en formato JSON para auditoria o reproceso.';
COMMENT ON COLUMN turismo.stg_fuente_raw.cargado_por IS 'Usuario que cargo el registro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_fuente_raw.procesado IS 'Indica si el registro fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_fuente_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento.';

COMMENT ON TABLE turismo.stg_destino_raw IS 'Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.';
COMMENT ON COLUMN turismo.stg_destino_raw.id_stg_destino IS 'Campo id stg destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.nombre_archivo IS 'Nombre del archivo origen.';
COMMENT ON COLUMN turismo.stg_destino_raw.nombre_destino IS 'Campo nombre destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.tipo IS 'Campo tipo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.departamento IS 'Campo departamento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.municipio IS 'Campo municipio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.region_turistica IS 'Campo region turistica del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.direccion_referencia IS 'Campo direccion referencia del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.latitud IS 'Campo latitud del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.longitud IS 'Campo longitud del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.altitud_msnm IS 'Campo altitud msnm del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.dificultad IS 'Campo dificultad del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.tiempo_recomendado IS 'Campo tiempo recomendado del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.costo_aprox_nacional_q IS 'Campo costo aprox nacional q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.costo_aprox_extranjero_q IS 'Campo costo aprox extranjero q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.horario IS 'Campo horario del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.es_area_protegida IS 'Campo es area protegida del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.url_fuente IS 'Campo url fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_destino_raw.raw_payload IS 'Registro original en formato JSON para auditoria o reproceso.';
COMMENT ON COLUMN turismo.stg_destino_raw.cargado_por IS 'Usuario que cargo el registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_destino_raw.procesado IS 'Indica si el registro fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_destino_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento.';

COMMENT ON TABLE turismo.stg_metricas_destino_raw IS 'Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.id_stg_metrica IS 'Campo id stg metrica del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.nombre_archivo IS 'Nombre del archivo origen.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.fecha_metrica IS 'Campo fecha metrica del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.nombre_destino IS 'Campo nombre destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.fuente_metrica IS 'Campo fuente metrica del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.visitantes_nacionales IS 'Campo visitantes nacionales del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.visitantes_extranjeros IS 'Campo visitantes extranjeros del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.calificacion_promedio IS 'Campo calificacion promedio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cantidad_resenas IS 'Campo cantidad resenas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.busquedas_web IS 'Campo busquedas web del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.menciones_redes IS 'Campo menciones redes del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.raw_payload IS 'Registro original en formato JSON para auditoria o reproceso.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cargado_por IS 'Usuario que cargo el registro.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.procesado IS 'Indica si el registro fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_metricas_destino_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento.';

COMMENT ON TABLE turismo.stg_evento_usuario_raw IS 'Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.id_stg_evento IS 'Campo id stg evento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.fecha_evento IS 'Campo fecha evento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.nombre_destino IS 'Campo nombre destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.tipo_evento IS 'Campo tipo evento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.VISTA_DESTINO IS 'Campo VISTA DESTINO del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.CLICK_RUTA IS 'Campo CLICK RUTA del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.FAVORITO IS 'Campo FAVORITO del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.COMPARTIDO IS 'Campo COMPARTIDO del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.dispositivo IS 'Campo dispositivo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.pais_usuario IS 'Campo pais usuario del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.conteo IS 'Campo conteo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.raw_payload IS 'Registro original en formato JSON para auditoria o reproceso.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.cargado_por IS 'Usuario que cargo el registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.cargado_en IS 'Fecha y hora de carga del registro.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.procesado IS 'Indica si el registro fue procesado por el ETL.';
COMMENT ON COLUMN turismo.stg_evento_usuario_raw.mensaje_proceso IS 'Mensaje generado durante el procesamiento.';

