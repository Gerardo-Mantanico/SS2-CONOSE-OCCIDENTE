-- Schema: geografia

CREATE SCHEMA geografia;
COMMENT ON SCHEMA geografia IS 'Entidades geográficas: países, regiones, departamentos, municipios.';

CREATE TABLE geografia.pais (
    id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id),
    pcode      VARCHAR(12) UNIQUE,
    iso2       CHAR(2),
    iso3       CHAR(3),
    area_km2   NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.pais IS 'Catálogo de países utilizados por el sistema como nivel geográfico principal.';
COMMENT ON COLUMN geografia.pais.id IS 'Identificador único del país.';
COMMENT ON COLUMN geografia.pais.nombre IS 'Nombre oficial del país.';
COMMENT ON COLUMN geografia.pais.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el país.';
COMMENT ON COLUMN geografia.pais.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del país, p.ej. GT';
COMMENT ON COLUMN geografia.pais.iso2 IS 'Código ISO 3166-1 alfa-2 del país.';
COMMENT ON COLUMN geografia.pais.iso3 IS 'Código ISO 3166-1 alfa-3 del país.';
COMMENT ON COLUMN geografia.pais.area_km2 IS 'Superficie territorial del país expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.pais.centro_lat IS 'Latitud del centroide geográfico del país.';
COMMENT ON COLUMN geografia.pais.centro_lon IS 'Longitud del centroide geográfico del país.';


CREATE TABLE geografia.departamento (
    id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre    VARCHAR(100) NOT NULL,
    pais_id    INT NOT NULL REFERENCES geografia.pais(id),
    carga_id   INT REFERENCES meta.carga(id),
    pcode      VARCHAR(12) UNIQUE,
    area_km2   NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.departamento IS 'Catálogo de departamentos o divisiones administrativas de primer nivel.';
COMMENT ON COLUMN geografia.departamento.id IS 'Identificador único del departamento.';
COMMENT ON COLUMN geografia.departamento.nombre IS 'Nombre oficial del departamento.';
COMMENT ON COLUMN geografia.departamento.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el departamento.';
COMMENT ON COLUMN geografia.departamento.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del departamento, p.ej. GT04.';
COMMENT ON COLUMN geografia.departamento.area_km2 IS 'Superficie territorial del departamento expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.departamento.centro_lat IS 'Latitud del centroide geográfico del departamento.';
COMMENT ON COLUMN geografia.departamento.centro_lon IS 'Longitud del centroide geográfico del departamento.';


CREATE TABLE geografia.municipio (
    id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departamento_id INT         NOT NULL REFERENCES geografia.departamento(id),
    nombre          VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id),
    pcode      VARCHAR(12) UNIQUE,
    area_km2   NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.municipio IS 'Catálogo de municipios asociados a un departamento.';
COMMENT ON COLUMN geografia.municipio.id IS 'Identificador único del municipio.';
COMMENT ON COLUMN geografia.municipio.departamento_id IS 'Departamento al que pertenece el municipio.';
COMMENT ON COLUMN geografia.municipio.nombre IS 'Nombre oficial del municipio.';
COMMENT ON COLUMN geografia.municipio.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el municipio.';
COMMENT ON COLUMN geografia.municipio.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del municipio, p.ej. GT0411';
COMMENT ON COLUMN geografia.municipio.area_km2 IS 'Superficie territorial del municipio expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.municipio.centro_lat IS'Latitud del centroide geográfico del municipio.';
COMMENT ON COLUMN geografia.municipio.centro_lon IS 'Longitud del centroide geográfico del municipio.';