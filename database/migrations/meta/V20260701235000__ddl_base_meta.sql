-- Schema: meta
-- Trazabilidad de los datos: de dónde vienen, quién los cargó y cuándo.
-- Cada proceso ETL debe registrar una entrada en meta.carga al ejecutarse

CREATE SCHEMA IF NOT EXISTS meta;
COMMENT ON SCHEMA meta IS 'Trazabilidad de los datos: registro de orígenes, responsables y tiempos de ejecución de los procesos ETL.';


-- Tipo de fuente - cómo se obtienen los datos
CREATE TABLE meta.tipo_fuente (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
COMMENT ON TABLE meta.tipo_fuente IS 'Catálogo de las formas en que se obtienen los datos (ej: archivo, api, scraping, entrada_manual).';
COMMENT ON COLUMN meta.tipo_fuente.id IS 'Identificador único autogenerado del tipo de fuente.';
COMMENT ON COLUMN meta.tipo_fuente.nombre IS 'Nombre del tipo de extracción o fuente de datos.';
INSERT INTO meta.tipo_fuente (nombre) VALUES
    ('archivo'),
    ('api'),
    ('scraping'),
    ('entrada_manual');


-- Fuente de datos
-- Una misma fuente puede tener múltiples cargas a lo largo del tiempo.
-- 'codigo' es la clave estable y legible con la que el ETL referencia la fuente (p.ej. 'INE_CENSO_2018').
-- El script etl/python/meta/..._load_fuentes.py facilita el registro de fuentes a partir de data/fuentes.csv
CREATE TABLE meta.fuente (
    id              INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo          VARCHAR(50)  NOT NULL UNIQUE,
    tipo_fuente_id  INT  NOT NULL REFERENCES meta.tipo_fuente(id),
    nombre          VARCHAR(200) NOT NULL,
    institucion     VARCHAR(200),
    url             TEXT,
    descripcion     TEXT,
    licencia        VARCHAR(100),
    activa          BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE meta.fuente IS 'Entidad o sistema externo que produce los datos (ej. INE, MINGOB). Una misma fuente puede tener múltiples cargas a lo largo del tiempo.';
COMMENT ON COLUMN meta.fuente.id IS 'Identificador único autogenerado de la fuente.';
COMMENT ON COLUMN meta.fuente.codigo IS 'Clave estable y legible con la que el proceso ETL referencia la fuente (ej. INE_CENSO_2018).';
COMMENT ON COLUMN meta.fuente.tipo_fuente_id IS 'Referencia a la forma en que se obtienen los datos de esta fuente.';
COMMENT ON COLUMN meta.fuente.nombre IS 'Nombre completo y descriptivo de la fuente de datos.';
COMMENT ON COLUMN meta.fuente.institucion IS 'Nombre de la institución o entidad que publica los datos.';
COMMENT ON COLUMN meta.fuente.url IS 'URL de descarga directa, portal de datos o sitio de documentación.';
COMMENT ON COLUMN meta.fuente.descripcion IS 'Descripción detallada de la naturaleza de los datos y su propósito.';
COMMENT ON COLUMN meta.fuente.licencia IS 'Licencia aplicable a los datos (ej: CC BY 4.0, uso público, restringida).';
COMMENT ON COLUMN meta.fuente.activa IS 'Indica si la fuente de datos sigue vigente y en uso en el sistema.';
COMMENT ON COLUMN meta.fuente.creado_en IS 'Fecha y hora en la que se registró la fuente en el catálogo.';



CREATE TABLE meta.estado_carga (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
COMMENT ON TABLE meta.estado_carga IS 'Catálogo de estados de la ejecución de una carga de datos.';
COMMENT ON COLUMN meta.estado_carga.id IS 'Identificador único autogenerado del estado de carga.';
COMMENT ON COLUMN meta.estado_carga.nombre IS 'Nombre del estado (ej: en_proceso, exitosa, fallida, parcial).';
INSERT INTO meta.estado_carga (nombre) VALUES
    ('en_proceso'),
    ('exitosa'),
    ('fallida'),
    ('parcial');



-- Carga
-- Representa una ejecución concreta de un proceso ETL. Se crea (estado 'en_proceso') al inicio y se actualiza al finalizar.
CREATE TABLE meta.carga (
    id              INT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fuente_id       INT         NOT NULL REFERENCES meta.fuente(id),
    estado_carga_id INT         NOT NULL REFERENCES meta.estado_carga(id),
    nombre_script   VARCHAR(200),
    archivo_fuente  TEXT,
    hash_archivo    VARCHAR(64),
    ejecutado_por   TEXT,
    iniciado_en     TIMESTAMPTZ NOT NULL DEFAULT now(),
    finalizado_en   TIMESTAMPTZ,
    filas_procesadas INT,
    filas_insertadas INT,
    filas_actualizadas INT,
    filas_rechazadas INT,
    notas           TEXT
);
COMMENT ON TABLE meta.carga IS 'Representa una ejecución concreta de un proceso ETL. Inicia en estado en_proceso y se actualiza al finalizar.';
COMMENT ON COLUMN meta.carga.id IS 'Identificador único autogenerado de la ejecución de carga.';
COMMENT ON COLUMN meta.carga.fuente_id IS 'Referencia a la fuente externa desde donde se extrajeron los datos.';
COMMENT ON COLUMN meta.carga.estado_carga_id IS 'Estado actual de la ejecución del ETL.';
COMMENT ON COLUMN meta.carga.nombre_script IS 'Ruta relativa o nombre del script de código que ejecutó la carga (ej: sector_publico/..._load_instituciones.py).';
COMMENT ON COLUMN meta.carga.archivo_fuente IS 'Nombre o ruta del archivo de datos origen que fue procesado.';
COMMENT ON COLUMN meta.carga.hash_archivo IS 'Hash SHA-256 del archivo origen, utilizado para prevenir duplicados y reprocesamientos.';
COMMENT ON COLUMN meta.carga.ejecutado_por IS 'Usuario de base de datos, del sistema operativo o nombre del colaborador que lanzó el proceso.';
COMMENT ON COLUMN meta.carga.iniciado_en IS 'Fecha y hora exactas en que comenzó la ejecución del proceso ETL.';
COMMENT ON COLUMN meta.carga.finalizado_en IS 'Fecha y hora exactas en que concluyó la ejecución del proceso ETL.';
COMMENT ON COLUMN meta.carga.filas_procesadas IS 'Cantidad total de registros leídos desde el archivo o sistema fuente.';
COMMENT ON COLUMN meta.carga.filas_insertadas IS 'Cantidad de registros nuevos insertados en la base de datos destino.';
COMMENT ON COLUMN meta.carga.filas_actualizadas IS 'Cantidad de registros existentes que fueron modificados o actualizados.';
COMMENT ON COLUMN meta.carga.filas_rechazadas IS 'Cantidad de registros ignorados por errores, reglas de negocio o duplicidad.';
COMMENT ON COLUMN meta.carga.notas IS 'Registro de errores, advertencias (warnings) u observaciones durante la ejecución.';


-- Cobertura de carga
-- Registra qué tabla fue afectada por una carga y para qué período de datos, ya que una carga puede afectar múltiples tablas.
CREATE TABLE meta.cobertura_carga (
    id              INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    carga_id        INT  NOT NULL REFERENCES meta.carga(id),
    schema_destino  VARCHAR(100) NOT NULL,
    tabla_destino   VARCHAR(100) NOT NULL,
    periodo_inicio  DATE,
    periodo_fin     DATE,
    notas           TEXT
);
COMMENT ON TABLE meta.cobertura_carga IS 'Registra el esquema y la tabla poblada por un ETL específico, así como el rango de tiempo de los datos ingresados.';
COMMENT ON COLUMN meta.cobertura_carga.id IS 'Identificador único autogenerado de la cobertura.';
COMMENT ON COLUMN meta.cobertura_carga.carga_id IS 'Referencia a la carga (ejecución del ETL) asociada.';
COMMENT ON COLUMN meta.cobertura_carga.schema_destino IS 'Nombre del esquema de base de datos poblado (ej: sector_publico).';
COMMENT ON COLUMN meta.cobertura_carga.tabla_destino IS 'Nombre de la tabla de base de datos poblada (ej: institucion).';
COMMENT ON COLUMN meta.cobertura_carga.periodo_inicio IS 'Fecha que indica el inicio del período de la información ingresada.';
COMMENT ON COLUMN meta.cobertura_carga.periodo_fin IS 'Fecha que indica el fin del período de la información ingresada.';
COMMENT ON COLUMN meta.cobertura_carga.notas IS 'Información adicional pertinente a los datos cargados en esta tabla específica.';


CREATE INDEX ON meta.carga (fuente_id);
CREATE INDEX ON meta.carga (iniciado_en);
CREATE INDEX ON meta.cobertura_carga (carga_id);
CREATE INDEX ON meta.cobertura_carga (schema_destino, tabla_destino);

