-- Schema: clima
-- Climatología registrada por estaciones meteorológicas.

CREATE SCHEMA IF NOT EXISTS clima;

DROP TABLE IF EXISTS clima.registro_climatico CASCADE;
DROP TABLE IF EXISTS clima.fuente_clima CASCADE;

-- Estación meteorológica
CREATE TABLE clima.estacion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    ubicacion TEXT,
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7),
    carga_id INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE  clima.estacion IS 'Estaciones meteorologicas que reportan datos climaticos.';
COMMENT ON COLUMN clima.estacion.codigo IS 'Codigo de la estacion segun la fuente. Clave natural.';
COMMENT ON COLUMN clima.estacion.nombre IS 'Nombre de la estacion.';
COMMENT ON COLUMN clima.estacion.ubicacion IS 'Ubicacion o descripcion del sitio de la estacion.';
COMMENT ON COLUMN clima.estacion.latitud IS 'Latitud de la estacion en grados decimales.';
COMMENT ON COLUMN clima.estacion.longitud IS 'Longitud de la estacion en grados decimales.';
COMMENT ON COLUMN clima.estacion.carga_id IS 'Carga (meta.carga) que registro o actualizo esta estacion.';

-- Registro climatico diario
-- Una fila por estacion y fecha. Cada medición es opcional
CREATE TABLE clima.registro_climatico (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estacion_id INT  NOT NULL REFERENCES clima.estacion(id),
    fecha DATE NOT NULL,
    lluvia NUMERIC,
    temperatura_maxima NUMERIC,
    temperatura_minima NUMERIC,
    temperatura_media NUMERIC,
    evaporacion_tanque NUMERIC,
    humedad_relativa NUMERIC,
    brillo_solar NUMERIC,
    nubosidad NUMERIC,
    velocidad_viento NUMERIC,
    direccion_viento NUMERIC,
    presion_atmosferica NUMERIC,
    temperatura_suelo_50cm NUMERIC,
    temperatura_suelo_100cm NUMERIC,
    radiacion NUMERIC,
    carga_id INT REFERENCES meta.carga(id),
    CONSTRAINT uq_registro_estacion_fecha UNIQUE (estacion_id, fecha)
);

COMMENT ON TABLE  clima.registro_climatico IS 'Mediciones climáticas diarias por estación. Una fila por estación y fecha.';
COMMENT ON COLUMN clima.registro_climatico.estacion_id IS 'Estación que produjo el registro.';
COMMENT ON COLUMN clima.registro_climatico.fecha IS 'Fecha del registro (dia).';
COMMENT ON COLUMN clima.registro_climatico.lluvia IS 'Precipitación (lluvia) del dia, en mm.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_maxima IS 'Temperatura maxima del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_minima IS 'Temperatura minima del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_media IS 'Temperatura media del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.evaporacion_tanque IS 'Evaporación medida en tanque, en mm.';
COMMENT ON COLUMN clima.registro_climatico.humedad_relativa IS 'Humedad relativa, en porcentaje.';
COMMENT ON COLUMN clima.registro_climatico.brillo_solar IS 'Brillo solar (horas de sol).';
COMMENT ON COLUMN clima.registro_climatico.nubosidad IS 'Nubosidad reportada por la estación.';
COMMENT ON COLUMN clima.registro_climatico.velocidad_viento IS 'Velocidad del viento según la fuente.';
COMMENT ON COLUMN clima.registro_climatico.direccion_viento IS 'Dirección del viento, en grados.';
COMMENT ON COLUMN clima.registro_climatico.presion_atmosferica IS 'Presión atmosférica, en hPa.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_suelo_50cm IS 'Temperatura del suelo a 50 cm, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_suelo_100cm IS 'Temperatura del suelo a 100 cm, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.radiacion IS 'Radiación solar según la fuente.';
COMMENT ON COLUMN clima.registro_climatico.carga_id IS 'Carga (meta.carga) que registro o actualizo esta fila.';

CREATE INDEX ON clima.registro_climatico (fecha);
