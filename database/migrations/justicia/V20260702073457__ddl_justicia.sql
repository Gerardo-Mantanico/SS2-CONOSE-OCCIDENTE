CREATE SCHEMA IF NOT EXISTS justicia;

COMMENT ON SCHEMA justicia IS 'Denuncias, estados procesales y eventos relacionados con el sistema de justicia.';

-- Catálogos
CREATE TABLE justicia.tipo_denuncia (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
COMMENT ON TABLE justicia.tipo_denuncia IS 'Catálogo de tipos de denuncias registradas en el sistema.';
COMMENT ON COLUMN justicia.tipo_denuncia.id IS 'Identificador único del tipo de denuncia.';
COMMENT ON COLUMN justicia.tipo_denuncia.nombre IS 'Nombre del tipo de denuncia.';


CREATE TABLE justicia.estado_denuncia (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
COMMENT ON TABLE justicia.estado_denuncia IS 'Catálogo de estados en los que puede encontrarse una denuncia.';
COMMENT ON COLUMN justicia.estado_denuncia.id IS 'Identificador único del estado de la denuncia.';
COMMENT ON COLUMN justicia.estado_denuncia.nombre IS 'Nombre del estado procesal de la denuncia.';


CREATE TABLE justicia.tipo_evento (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
COMMENT ON TABLE justicia.tipo_evento IS 'Catálogo de eventos que pueden ocurrir durante el ciclo de vida de una denuncia.';
COMMENT ON COLUMN justicia.tipo_evento.id IS 'Identificador único del tipo de evento.';
COMMENT ON COLUMN justicia.tipo_evento.nombre IS 'Nombre del tipo de evento.';


-- Denuncia
CREATE TABLE justicia.denuncia (
    id                      INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_denuncia_id        INT  NOT NULL REFERENCES justicia.tipo_denuncia(id),
    estado_denuncia_id      INT  NOT NULL REFERENCES justicia.estado_denuncia(id),
    institucion_id          INT  NOT NULL REFERENCES sector_publico.institucion(id),
    municipio_incidencia_id INT  NOT NULL REFERENCES geografia.municipio(id),
    descripcion             TEXT
);
COMMENT ON TABLE justicia.denuncia IS 'Denuncias registradas dentro del sistema de justicia.';
COMMENT ON COLUMN justicia.denuncia.id IS 'Identificador único de la denuncia.';
COMMENT ON COLUMN justicia.denuncia.tipo_denuncia_id IS 'Tipo de denuncia registrada.';
COMMENT ON COLUMN justicia.denuncia.estado_denuncia_id IS 'Estado procesal actual de la denuncia.';
COMMENT ON COLUMN justicia.denuncia.institucion_id IS 'Institución responsable de conocer o tramitar la denuncia.';
COMMENT ON COLUMN justicia.denuncia.municipio_incidencia_id IS 'Municipio donde ocurrió el hecho denunciado.';
COMMENT ON COLUMN justicia.denuncia.descripcion IS 'Descripción de los hechos reportados en la denuncia.';


-- Registro cronológico de eventos dentro del proceso de una denuncia.
CREATE TABLE justicia.registro_fecha_denuncia (
    id             INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    denuncia_id    INT  NOT NULL REFERENCES justicia.denuncia(id),
    tipo_evento_id INT  NOT NULL REFERENCES justicia.tipo_evento(id),
    observaciones  TEXT,
    fecha          DATE
);
COMMENT ON TABLE justicia.registro_fecha_denuncia IS 'Registro cronológico de eventos asociados al trámite de una denuncia.';
COMMENT ON COLUMN justicia.registro_fecha_denuncia.id IS 'Identificador único del registro de evento.';
COMMENT ON COLUMN justicia.registro_fecha_denuncia.denuncia_id IS 'Denuncia a la que pertenece el evento registrado.';
COMMENT ON COLUMN justicia.registro_fecha_denuncia.tipo_evento_id IS 'Tipo de evento ocurrido durante el proceso de la denuncia.';
COMMENT ON COLUMN justicia.registro_fecha_denuncia.observaciones IS 'Observaciones o detalles relacionados con el evento.';
COMMENT ON COLUMN justicia.registro_fecha_denuncia.fecha IS 'Fecha en la que ocurrió el evento registrado.';