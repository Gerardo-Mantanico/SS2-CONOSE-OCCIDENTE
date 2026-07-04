CREATE SCHEMA IF NOT EXISTS clima;
COMMENT ON SCHEMA clima IS 'Registros climáticos históricos y en tiempo real por municipio.';

CREATE TABLE clima.fuente_clima (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE clima.fuente_clima IS 'Catálogo de fuentes proveedoras de información climática.';
COMMENT ON COLUMN clima.fuente_clima.id IS 'Identificador único de la fuente climática.';
COMMENT ON COLUMN clima.fuente_clima.nombre IS 'Nombre de la fuente de datos climáticos.';
COMMENT ON COLUMN clima.fuente_clima.carga_id IS 'Referencia a la carga de datos mediante la cual se registró la fuente.';


CREATE TABLE clima.registro_climatico (
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fuente_clima_id  INT          NOT NULL REFERENCES clima.fuente_clima(id),
    municipio_id     INT          NOT NULL REFERENCES geografia.municipio(id),
    fecha            DATE,
    hora             TIME,
    velocidad_viento DECIMAL(8,2),
    humedad_relativa DECIMAL(5,2),
    precipitacion    DECIMAL(8,2),
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE clima.registro_climatico IS 'Registros de variables climáticas observadas para un municipio en una fecha y hora determinadas.';
COMMENT ON COLUMN clima.registro_climatico.id IS 'Identificador único del registro climático.';
COMMENT ON COLUMN clima.registro_climatico.fuente_clima_id IS 'Fuente de la cual provienen los datos climáticos.';
COMMENT ON COLUMN clima.registro_climatico.municipio_id IS 'Municipio al que corresponde la medición climática.';
COMMENT ON COLUMN clima.registro_climatico.fecha IS 'Fecha en que se realizó la medición.';
COMMENT ON COLUMN clima.registro_climatico.hora IS 'Hora en que se realizó la medición.';
COMMENT ON COLUMN clima.registro_climatico.velocidad_viento IS 'Velocidad del viento registrada, expresada en kilómetros por hora.';
COMMENT ON COLUMN clima.registro_climatico.humedad_relativa IS 'Humedad relativa del aire expresada como porcentaje.';
COMMENT ON COLUMN clima.registro_climatico.precipitacion IS 'Cantidad de precipitación registrada durante el período de observación, expresada en milímetros.';
COMMENT ON COLUMN clima.registro_climatico.carga_id IS 'Referencia a la carga de datos mediante la cual se registró la medición.';
