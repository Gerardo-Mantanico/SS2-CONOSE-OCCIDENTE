-- Migración: ddl_economia_complejo
-- Schema:    economia
-- Generado:  2026-07-05 17:00:00

CREATE SCHEMA IF NOT EXISTS economia;
COMMENT ON SCHEMA economia IS 'Esquema avanzado para el análisis socioeconómico municipal, integrando agricultura, artesanías, cooperativas, materias primas e infraestructura comercial.';

-- 0. Limpieza de tablas previas si existen (para evitar colisión de nombres y tipos)
DROP TABLE IF EXISTS economia.centro_acopio_procesamiento CASCADE;
DROP TABLE IF EXISTS economia.mercado_tradicional CASCADE;
DROP TABLE IF EXISTS economia.produccion_municipal CASCADE;
DROP TABLE IF EXISTS economia.actividad_materia CASCADE;
DROP TABLE IF EXISTS economia.cooperativa_asociacion CASCADE;
DROP TABLE IF EXISTS economia.materia_prima CASCADE;
DROP TABLE IF EXISTS economia.actividad_productiva CASCADE;

-- 1. ACTIVIDADES PRODUCTIVAS
CREATE TABLE economia.actividad_productiva (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('Agrícola', 'Artesanía/Textil', 'Pecuaria', 'Industrial', 'Comercial', 'Servicios')),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.actividad_productiva IS 'Catálogo detallado de actividades y productos líderes de la economía municipal.';
COMMENT ON COLUMN economia.actividad_productiva.id IS 'Identificador único de la actividad productiva.';
COMMENT ON COLUMN economia.actividad_productiva.nombre IS 'Nombre oficial del producto o actividad (ej: Café, Tejidos Mayas, Cardamomo).';
COMMENT ON COLUMN economia.actividad_productiva.categoria IS 'Categoría sectorial de la actividad productiva.';
COMMENT ON COLUMN economia.actividad_productiva.descripcion IS 'Reseña de la importancia y características de la actividad.';
COMMENT ON COLUMN economia.actividad_productiva.carga_id IS 'Referencia a la carga de datos por la cual se registró la actividad.';

-- 2. MATERIAS PRIMAS / INSUMOS
CREATE TABLE economia.materia_prima (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    origen VARCHAR(50) CHECK (origen IN ('Nacional', 'Importado', 'Mixto')),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.materia_prima IS 'Insumos y materias primas clave utilizados en los procesos productivos locales.';
COMMENT ON COLUMN economia.materia_prima.id IS 'Identificador único de la materia prima.';
COMMENT ON COLUMN economia.materia_prima.nombre IS 'Nombre del insumo (ej: Hilo de algodón, Madera de pino, Cuero bobino).';
COMMENT ON COLUMN economia.materia_prima.origen IS 'Origen geográfico principal del insumo.';
COMMENT ON COLUMN economia.materia_prima.descripcion IS 'Detalles sobre las características físicas y usos comunes del insumo.';
COMMENT ON COLUMN economia.materia_prima.carga_id IS 'Referencia a la carga de datos por la cual se registró el insumo.';

-- 3. ACTIVIDAD - MATERIA (Relación Muchos a Muchos)
CREATE TABLE economia.actividad_materia (
    actividad_id INT REFERENCES economia.actividad_productiva(id) ON DELETE CASCADE,
    materia_id INT REFERENCES economia.materia_prima(id) ON DELETE CASCADE,
    es_indispensable BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (actividad_id, materia_id)
);
COMMENT ON TABLE economia.actividad_materia IS 'Matriz asociativa que vincula las actividades productivas con sus materias primas requeridas.';
COMMENT ON COLUMN economia.actividad_materia.actividad_id IS 'Identificador de la actividad productiva.';
COMMENT ON COLUMN economia.actividad_materia.materia_id IS 'Identificador de la materia prima requerida.';
COMMENT ON COLUMN economia.actividad_materia.es_indispensable IS 'Indica si el insumo es crítico para la realización de la actividad.';

-- 4. COOPERATIVAS Y ASOCIACIONES DE PRODUCTORES
CREATE TABLE economia.cooperativa_asociacion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(200) UNIQUE NOT NULL,
    siglas VARCHAR(50),
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    cobertura VARCHAR(50) CHECK (cobertura IN ('Local', 'Departamental', 'Regional', 'Nacional')),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.cooperativa_asociacion IS 'Cooperativas, gremiales y asociaciones que impulsan la producción y comercialización local.';
COMMENT ON COLUMN economia.cooperativa_asociacion.id IS 'Identificador único de la cooperativa o asociación.';
COMMENT ON COLUMN economia.cooperativa_asociacion.nombre IS 'Nombre legal completo de la organización.';
COMMENT ON COLUMN economia.cooperativa_asociacion.siglas IS 'Siglas o acrónimo representativo (ej: Fedecocagua, Copichol).';
COMMENT ON COLUMN economia.cooperativa_asociacion.municipio_id IS 'Sede o municipio principal de la organización.';
COMMENT ON COLUMN economia.cooperativa_asociacion.cobertura IS 'Ámbito de cobertura geográfica de la organización.';
COMMENT ON COLUMN economia.cooperativa_asociacion.descripcion IS 'Reseña de la historia, fines y apoyo a productores de la organización.';
COMMENT ON COLUMN economia.cooperativa_asociacion.carga_id IS 'Referencia a la carga de datos por la cual se registró la organización.';

-- 5. PRODUCCIÓN MUNICIPAL (Relación Muchos a Muchos con métricas socioeconómicas)
CREATE TABLE economia.produccion_municipal (
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    actividad_id INT REFERENCES economia.actividad_productiva(id) ON DELETE CASCADE,
    cooperativa_id INT REFERENCES economia.cooperativa_asociacion(id) ON DELETE SET NULL,
    es_principal BOOLEAN DEFAULT FALSE,
    volumen_estimado VARCHAR(50) CHECK (volumen_estimado IN ('Alto', 'Medio', 'Bajo', 'No disponible')),
    cantidad_productores_est INT CHECK (cantidad_productores_est >= 0),
    empleo_generado_est INT CHECK (empleo_generado_est >= 0),
    ciclo_cosecha_meses VARCHAR(50),
    destino_principal VARCHAR(50) CHECK (destino_principal IN ('Exportación', 'Mercado Nacional', 'Autoconsumo', 'Mixto')),
    carga_id INT REFERENCES meta.carga(id),
    PRIMARY KEY (municipio_id, actividad_id)
);
COMMENT ON TABLE economia.produccion_municipal IS 'Asociación de actividades productivas con municipios, detallando métricas socioeconómicas.';
COMMENT ON COLUMN economia.produccion_municipal.municipio_id IS 'Identificador del municipio productor.';
COMMENT ON COLUMN economia.produccion_municipal.actividad_id IS 'Identificador de la actividad productiva.';
COMMENT ON COLUMN economia.produccion_municipal.cooperativa_id IS 'Identificador de la cooperativa local de apoyo (opcional).';
COMMENT ON COLUMN economia.produccion_municipal.es_principal IS 'Indica si es una de las actividades económicas líderes del municipio.';
COMMENT ON COLUMN economia.produccion_municipal.volumen_estimado IS 'Volumen estimado de producción.';
COMMENT ON COLUMN economia.produccion_municipal.cantidad_productores_est IS 'Cantidad estimada de productores o familias involucradas.';
COMMENT ON COLUMN economia.produccion_municipal.empleo_generado_est IS 'Empleos directos generados estimados en el municipio.';
COMMENT ON COLUMN economia.produccion_municipal.ciclo_cosecha_meses IS 'Meses clave de cosecha o mayor actividad (ej: Noviembre-Marzo para Café).';
COMMENT ON COLUMN economia.produccion_municipal.destino_principal IS 'Destino principal del producto comercializado.';
COMMENT ON COLUMN economia.produccion_municipal.carga_id IS 'Referencia a la carga de datos por la cual se registró la producción.';

-- 6. MERCADOS TRADICIONALES
CREATE TABLE economia.mercado_tradicional (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) UNIQUE NOT NULL,
    municipio_id INT NOT NULL REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    dias_plaza VARCHAR(100) NOT NULL,
    tipo_mercado VARCHAR(50) CHECK (tipo_mercado IN ('Artesanal', 'Mayorista', 'Cantonal/Municipal', 'Mixto')),
    cantidad_vendedores_est INT,
    latitud NUMERIC(9,6) CHECK (latitud BETWEEN 13.0 AND 18.0),
    longitud NUMERIC(9,6) CHECK (longitud BETWEEN -93.0 AND -88.0),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE economia.mercado_tradicional IS 'Plazas comerciales y mercados históricos notables del país.';
COMMENT ON COLUMN economia.mercado_tradicional.id IS 'Identificador único del mercado.';
COMMENT ON COLUMN economia.mercado_tradicional.nombre IS 'Nombre distintivo del mercado local.';
COMMENT ON COLUMN economia.mercado_tradicional.municipio_id IS 'Municipio en el que se localiza el mercado.';
COMMENT ON COLUMN economia.mercado_tradicional.dias_plaza IS 'Días principales de mercado y plaza tradicional.';
COMMENT ON COLUMN economia.mercado_tradicional.tipo_mercado IS 'Tipología principal del mercado.';
COMMENT ON COLUMN economia.mercado_tradicional.cantidad_vendedores_est IS 'Número estimado de vendedores en días principales de plaza.';
COMMENT ON COLUMN economia.mercado_tradicional.latitud IS 'Coordenada de latitud decimal (WGS84).';
COMMENT ON COLUMN economia.mercado_tradicional.longitud IS 'Coordenada de longitud decimal (WGS84).';
COMMENT ON COLUMN economia.mercado_tradicional.descripcion IS 'Descripción del mercado, historia e importancia cultural.';
COMMENT ON COLUMN economia.mercado_tradicional.carga_id IS 'Referencia a la carga de datos por la cual se registró el mercado.';

-- 7. INFRAESTRUCTURA PRODUCTIVA Y CENTROS DE PROCESAMIENTO
CREATE TABLE economia.centro_acopio_procesamiento (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(50) CHECK (tipo IN ('Beneficio de Café', 'Taller Artesanal', 'Centro de Acopio', 'Aserradero', 'Procesadora')),
    municipio_id INT NOT NULL REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    capacidad_estimada VARCHAR(100),
    carga_id INT REFERENCES meta.carga(id),
    UNIQUE (nombre, municipio_id)
);
COMMENT ON TABLE economia.centro_acopio_procesamiento IS 'Infraestructura productiva local dedicada a la preparación, empaque o procesamiento de productos.';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.id IS 'Identificador único de la infraestructura.';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.nombre IS 'Nombre del centro de procesamiento (ej: Beneficio Las Cascadas).';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.tipo IS 'Clasificación de la planta o centro de procesamiento.';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.municipio_id IS 'Municipio donde opera físicamente el centro.';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.capacidad_estimada IS 'Volumen o escala estimada de procesamiento (ej: 500 quintales/día).';
COMMENT ON COLUMN economia.centro_acopio_procesamiento.carga_id IS 'Referencia a la carga de datos por la cual se registró la infraestructura.';

-- Crear índices para acelerar búsquedas y optimizar consultas cruzadas
CREATE INDEX ON economia.produccion_municipal (actividad_id);
CREATE INDEX ON economia.produccion_municipal (cooperativa_id);
CREATE INDEX ON economia.actividad_materia (materia_id);
CREATE INDEX ON economia.cooperativa_asociacion (municipio_id);
CREATE INDEX ON economia.mercado_tradicional (municipio_id);
CREATE INDEX ON economia.centro_acopio_procesamiento (municipio_id);
