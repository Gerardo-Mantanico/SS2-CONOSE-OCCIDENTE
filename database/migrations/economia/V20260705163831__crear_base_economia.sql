-- Migración: crear_base_economia
-- Schema:    economia
-- Generado:  2026-07-05 16:38:31

CREATE SCHEMA IF NOT EXISTS economia;
COMMENT ON SCHEMA economia IS 'Esquema que describe las actividades económicas principales, producción local (agrícola y artesanal) y mercados tradicionales de los municipios de Guatemala.';

-- 1. ACTIVIDADES PRODUCTIVAS
CREATE TABLE economia.actividad_productiva (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('Agrícola', 'Artesanía/Textil', 'Pecuaria', 'Industrial', 'Comercial')),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.actividad_productiva IS 'Catálogo de actividades y productos líderes de la economía municipal.';
COMMENT ON COLUMN economia.actividad_productiva.id IS 'Identificador único de la actividad productiva.';
COMMENT ON COLUMN economia.actividad_productiva.nombre IS 'Nombre oficial del producto o actividad (ej: Café, Tejidos Mayas, Cardamomo).';
COMMENT ON COLUMN economia.actividad_productiva.categoria IS 'Categoría sectorial de la actividad.';
COMMENT ON COLUMN economia.actividad_productiva.descripcion IS 'Reseña de la importancia y características de la actividad.';
COMMENT ON COLUMN economia.actividad_productiva.carga_id IS 'Referencia a la carga de datos por la cual se registró la actividad.';

-- 2. PRODUCCIÓN MUNICIPAL (Muchos a Muchos)
CREATE TABLE economia.produccion_municipal (
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    actividad_id INT REFERENCES economia.actividad_productiva(id) ON DELETE CASCADE,
    es_principal BOOLEAN DEFAULT FALSE,
    volumen_estimado VARCHAR(50) CHECK (volumen_estimado IN ('Alto', 'Medio', 'Bajo', 'No disponible')),
    carga_id INT REFERENCES meta.carga(id),
    PRIMARY KEY (municipio_id, actividad_id)
);
COMMENT ON TABLE economia.produccion_municipal IS 'Asociación de actividades y cultivos producidos en cada municipio del país.';
COMMENT ON COLUMN economia.produccion_municipal.municipio_id IS 'Identificador del municipio productor.';
COMMENT ON COLUMN economia.produccion_municipal.actividad_id IS 'Identificador de la actividad o producto cultivado.';
COMMENT ON COLUMN economia.produccion_municipal.es_principal IS 'Indica si es uno de los motores económicos o cultivos líderes del municipio.';
COMMENT ON COLUMN economia.produccion_municipal.volumen_estimado IS 'Nivel o escala estimada de volumen de producción municipal.';
COMMENT ON COLUMN economia.produccion_municipal.carga_id IS 'Referencia a la carga de datos por la cual se registró la producción.';

-- 3. MERCADOS TRADICIONALES Y DÍAS DE PLAZA
CREATE TABLE economia.mercado_tradicional (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    municipio_id INT NOT NULL REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    dias_plaza VARCHAR(100) NOT NULL,
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.mercado_tradicional IS 'Mercados cantonales y municipales tradicionales notables de Guatemala.';
COMMENT ON COLUMN economia.mercado_tradicional.id IS 'Identificador único del mercado.';
COMMENT ON COLUMN economia.mercado_tradicional.nombre IS 'Nombre distintivo del mercado local.';
COMMENT ON COLUMN economia.mercado_tradicional.municipio_id IS 'Municipio en el que se ubica el mercado.';
COMMENT ON COLUMN economia.mercado_tradicional.dias_plaza IS 'Días de la semana de mayor actividad comercial y plaza tradicional.';
COMMENT ON COLUMN economia.mercado_tradicional.descripcion IS 'Descripción de productos, especialidad del mercado e importancia cultural.';
COMMENT ON COLUMN economia.mercado_tradicional.carga_id IS 'Referencia a la carga de datos por la cual se registró el mercado.';

-- Crear índices para acelerar búsquedas comunes
CREATE INDEX ON economia.produccion_municipal (actividad_id);
CREATE INDEX ON economia.mercado_tradicional (municipio_id);
