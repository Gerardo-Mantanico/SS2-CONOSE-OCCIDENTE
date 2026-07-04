CREATE SCHEMA IF NOT EXISTS demografia;
COMMENT ON SCHEMA demografia IS 'Datos personales e identitarios de individuos.';

CREATE TABLE demografia.estado_civil (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE demografia.estado_civil IS 'Catálogo de estados civiles utilizados para clasificar a las personas.';
COMMENT ON COLUMN demografia.estado_civil.id IS 'Identificador único del estado civil.';
COMMENT ON COLUMN demografia.estado_civil.nombre IS 'Nombre del estado civil.';
COMMENT ON COLUMN demografia.estado_civil.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el estado civil.';


CREATE TABLE demografia.sexo (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE demografia.sexo IS 'Catálogo de sexos registrados para las personas.';
COMMENT ON COLUMN demografia.sexo.id IS 'Identificador único del sexo.';
COMMENT ON COLUMN demografia.sexo.nombre IS 'Nombre del sexo.';
COMMENT ON COLUMN demografia.sexo.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el sexo.';


CREATE TABLE demografia.grupo_etnico (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE demografia.grupo_etnico IS 'Catálogo de grupos étnicos registrados en el sistema.';
COMMENT ON COLUMN demografia.grupo_etnico.id IS 'Identificador único del grupo étnico.';
COMMENT ON COLUMN demografia.grupo_etnico.nombre IS 'Nombre del grupo étnico.';
COMMENT ON COLUMN demografia.grupo_etnico.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el grupo étnico.';


CREATE TABLE demografia.persona (
    id               INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estado_civil_id  INT  NOT NULL REFERENCES demografia.estado_civil(id),
    sexo_id          INT  NOT NULL REFERENCES demografia.sexo(id),
    grupo_etnico_id  INT  NOT NULL REFERENCES demografia.grupo_etnico(id),
    dpi              VARCHAR(20),
    nit              VARCHAR(20),
    nombres          VARCHAR(150) NOT NULL,
    apellidos        VARCHAR(150) NOT NULL,
    correo           VARCHAR(150),
    telefono         VARCHAR(20),
    fecha_nacimiento DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE demografia.persona IS 'Información personal e identificatoria de los individuos registrados en el sistema.';
COMMENT ON COLUMN demografia.persona.id IS 'Identificador único de la persona.';
COMMENT ON COLUMN demografia.persona.estado_civil_id IS 'Estado civil asociado a la persona.';
COMMENT ON COLUMN demografia.persona.sexo_id IS 'Sexo registrado para la persona.';
COMMENT ON COLUMN demografia.persona.grupo_etnico_id IS 'Grupo étnico al que pertenece la persona.';
COMMENT ON COLUMN demografia.persona.dpi IS 'Número de Documento Personal de Identificación (DPI).';
COMMENT ON COLUMN demografia.persona.nit IS 'Número de Identificación Tributaria (NIT).';
COMMENT ON COLUMN demografia.persona.nombres IS 'Nombres de la persona.';
COMMENT ON COLUMN demografia.persona.apellidos IS 'Apellidos de la persona.';
COMMENT ON COLUMN demografia.persona.correo IS 'Dirección de correo electrónico.';
COMMENT ON COLUMN demografia.persona.telefono IS 'Número telefónico de contacto.';
COMMENT ON COLUMN demografia.persona.fecha_nacimiento IS 'Fecha de nacimiento de la persona.';
COMMENT ON COLUMN demografia.persona.carga_id IS 'Referencia a la carga de datos mediante la cual se registró la persona.';
