
CREATE SCHEMA IF NOT EXISTS sector_publico;

COMMENT ON SCHEMA sector_publico IS 'Instituciones del estado, cargos y contratación de servidores públicos.';

-- Catálogos de institución
CREATE TABLE sector_publico.tipo_institucion (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.tipo_institucion IS 'Catálogo de tipos de instituciones que conforman el sector público.';
COMMENT ON COLUMN sector_publico.tipo_institucion.id IS 'Identificador único del tipo de institución.';
COMMENT ON COLUMN sector_publico.tipo_institucion.nombre IS 'Nombre del tipo de institución.';
COMMENT ON COLUMN sector_publico.tipo_institucion.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el tipo de institución.';


CREATE TABLE sector_publico.nivel_institucion (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.nivel_institucion IS 'Catálogo de niveles administrativos de las instituciones públicas.';
COMMENT ON COLUMN sector_publico.nivel_institucion.id IS 'Identificador único del nivel institucional.';
COMMENT ON COLUMN sector_publico.nivel_institucion.nombre IS 'Nombre del nivel institucional.';
COMMENT ON COLUMN sector_publico.nivel_institucion.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el nivel institucional.';


-- Institución pública
CREATE TABLE sector_publico.institucion (
    id                   INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    municipio_id         INT  NOT NULL REFERENCES geografia.municipio(id),
    tipo_institucion_id  INT  NOT NULL REFERENCES sector_publico.tipo_institucion(id),
    nivel_institucion_id INT  NOT NULL REFERENCES sector_publico.nivel_institucion(id),
    nombre               VARCHAR(200) NOT NULL,
    siglas               VARCHAR(30),
    direccion            VARCHAR(255),
    telefono             VARCHAR(30),
    fecha_creacion       DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.institucion IS 'Instituciones pertenecientes al sector público.';
COMMENT ON COLUMN sector_publico.institucion.id IS 'Identificador único de la institución.';
COMMENT ON COLUMN sector_publico.institucion.municipio_id IS 'Municipio donde se ubica la sede principal de la institución.';
COMMENT ON COLUMN sector_publico.institucion.tipo_institucion_id IS 'Tipo de institución al que pertenece.';
COMMENT ON COLUMN sector_publico.institucion.nivel_institucion_id IS 'Nivel administrativo de la institución.';
COMMENT ON COLUMN sector_publico.institucion.nombre IS 'Nombre oficial de la institución.';
COMMENT ON COLUMN sector_publico.institucion.siglas IS 'Siglas o acrónimo oficial de la institución.';
COMMENT ON COLUMN sector_publico.institucion.direccion IS 'Dirección física de la institución.';
COMMENT ON COLUMN sector_publico.institucion.telefono IS 'Número telefónico de contacto.';
COMMENT ON COLUMN sector_publico.institucion.fecha_creacion IS 'Fecha de creación de la institución.';
COMMENT ON COLUMN sector_publico.institucion.carga_id IS 'Referencia a la carga de datos mediante la cual se registró la institución.';


CREATE TABLE sector_publico.cargo (
    id             INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    institucion_id INT  NOT NULL REFERENCES sector_publico.institucion(id),
    cargo_jefe_id  INT  REFERENCES sector_publico.cargo(id),  -- nullable: el cargo raíz no tiene jefe
    nombre         VARCHAR(150),
    descripcion    TEXT,
    fecha_creacion DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.cargo IS 'Catálogo de cargos o puestos existentes dentro de una institución pública.';
COMMENT ON COLUMN sector_publico.cargo.id IS 'Identificador único del cargo.';
COMMENT ON COLUMN sector_publico.cargo.institucion_id IS 'Institución a la que pertenece el cargo.';
COMMENT ON COLUMN sector_publico.cargo.cargo_jefe_id IS 'Cargo superior inmediato dentro de la jerarquía organizacional.';
COMMENT ON COLUMN sector_publico.cargo.nombre IS 'Nombre del cargo.';
COMMENT ON COLUMN sector_publico.cargo.descripcion IS 'Descripción de las funciones o responsabilidades del cargo.';
COMMENT ON COLUMN sector_publico.cargo.fecha_creacion IS 'Fecha en que fue creado el cargo.';
COMMENT ON COLUMN sector_publico.cargo.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el cargo.';


-- Trabajador y contrato
-- Vínculo entre una persona natural y su condición de servidor público.
-- Una persona puede haber tenido múltiples contratos en distintas instituciones.
CREATE TABLE sector_publico.trabajador (
    id         INT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    persona_id INT     NOT NULL REFERENCES demografia.persona(id),
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.trabajador IS 'Servidores públicos asociados a una persona registrada en el sistema.';
COMMENT ON COLUMN sector_publico.trabajador.id IS 'Identificador único del trabajador.';
COMMENT ON COLUMN sector_publico.trabajador.persona_id IS 'Persona asociada al trabajador.';
COMMENT ON COLUMN sector_publico.trabajador.esta_activo IS 'Indica si el trabajador mantiene una relación activa con el sector público.';
COMMENT ON COLUMN sector_publico.trabajador.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el trabajador.';


CREATE TABLE sector_publico.tipo_contrato (
    id                     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre                 VARCHAR(100),
    descripcion            TEXT,
    renglon_presupuestario VARCHAR(50),
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.tipo_contrato IS 'Catálogo de modalidades de contratación utilizadas en el sector público.';
COMMENT ON COLUMN sector_publico.tipo_contrato.id IS 'Identificador único del tipo de contrato.';
COMMENT ON COLUMN sector_publico.tipo_contrato.nombre IS 'Nombre del tipo de contrato.';
COMMENT ON COLUMN sector_publico.tipo_contrato.descripcion IS 'Descripción del tipo de contratación.';
COMMENT ON COLUMN sector_publico.tipo_contrato.renglon_presupuestario IS 'Renglón presupuestario asociado al tipo de contratación.';
COMMENT ON COLUMN sector_publico.tipo_contrato.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el tipo de contrato.';


CREATE TABLE sector_publico.contrato (
    id               INT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id    INT     NOT NULL REFERENCES sector_publico.trabajador(id),
    institucion_id   INT     NOT NULL REFERENCES sector_publico.institucion(id),
    cargo_id         INT     NOT NULL REFERENCES sector_publico.cargo(id),
    tipo_contrato_id INT     NOT NULL REFERENCES sector_publico.tipo_contrato(id),
    sueldo_base      DECIMAL(15,2),
    fecha_inicio     DATE,
    fecha_fin        DATE,
    esta_activo      BOOLEAN NOT NULL DEFAULT TRUE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE sector_publico.contrato IS 'Relación laboral entre un trabajador y una institución pública.';
COMMENT ON COLUMN sector_publico.contrato.id IS 'Identificador único del contrato.';
COMMENT ON COLUMN sector_publico.contrato.trabajador_id IS 'Trabajador contratado.';
COMMENT ON COLUMN sector_publico.contrato.institucion_id IS 'Institución contratante.';
COMMENT ON COLUMN sector_publico.contrato.cargo_id IS 'Cargo desempeñado por el trabajador.';
COMMENT ON COLUMN sector_publico.contrato.tipo_contrato_id IS 'Tipo de contrato aplicado.';
COMMENT ON COLUMN sector_publico.contrato.sueldo_base IS 'Sueldo base asignado al contrato.';
COMMENT ON COLUMN sector_publico.contrato.fecha_inicio IS 'Fecha de inicio de vigencia del contrato.';
COMMENT ON COLUMN sector_publico.contrato.fecha_fin IS 'Fecha de finalización del contrato, si aplica.';
COMMENT ON COLUMN sector_publico.contrato.esta_activo IS 'Indica si el contrato se encuentra vigente.';
COMMENT ON COLUMN sector_publico.contrato.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el contrato.';
