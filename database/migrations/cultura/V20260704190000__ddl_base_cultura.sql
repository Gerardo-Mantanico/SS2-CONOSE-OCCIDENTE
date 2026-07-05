-- Schema: cultura
-- Describe el patrimonio intangible, gastronomía, idiomas y festividades de Guatemala.

CREATE SCHEMA IF NOT EXISTS cultura;
COMMENT ON SCHEMA cultura IS 'Patrimonio inmaterial, gastronomía tradicional, diversidad lingüística y festividades patronales de Guatemala.';

-- 1. GASTRONOMÍA

-- Platos típicos
CREATE TABLE cultura.plato_tipico (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT,
    historia_origen TEXT,
    es_patrimonio BOOLEAN DEFAULT FALSE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE cultura.plato_tipico IS 'Catálogo de platillos y comidas tradicionales de Guatemala.';
COMMENT ON COLUMN cultura.plato_tipico.id IS 'Identificador único del plato típico.';
COMMENT ON COLUMN cultura.plato_tipico.nombre IS 'Nombre oficial del platillo tradicional (ej: Pepián, Kaq''ik).';
COMMENT ON COLUMN cultura.plato_tipico.descripcion IS 'Reseña de la composición y presentación del platillo.';
COMMENT ON COLUMN cultura.plato_tipico.historia_origen IS 'Contexto cultural e histórico del origen del platillo.';
COMMENT ON COLUMN cultura.plato_tipico.es_patrimonio IS 'Indica si el platillo ha sido declarado Patrimonio Cultural de la Nación.';
COMMENT ON COLUMN cultura.plato_tipico.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el platillo.';

-- Ingredientes autóctonos
CREATE TABLE cultura.ingrediente_autoctono (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    origen_prehispanico BOOLEAN DEFAULT TRUE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE cultura.ingrediente_autoctono IS 'Ingredientes originarios o tradicionales de la gastronomía guatemalteca.';
COMMENT ON COLUMN cultura.ingrediente_autoctono.id IS 'Identificador único del ingrediente.';
COMMENT ON COLUMN cultura.ingrediente_autoctono.nombre IS 'Nombre del ingrediente (ej: Cacao, Pepitoria, Chile Cobanero).';
COMMENT ON COLUMN cultura.ingrediente_autoctono.descripcion IS 'Descripción del ingrediente y sus usos comunes.';
COMMENT ON COLUMN cultura.ingrediente_autoctono.origen_prehispanico IS 'Indica si el ingrediente era cultivado y consumido en la época prehispánica.';
COMMENT ON COLUMN cultura.ingrediente_autoctono.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el ingrediente.';

-- Relación de platos e ingredientes (Muchos a Muchos)
CREATE TABLE cultura.plato_ingrediente (
    plato_id INT REFERENCES cultura.plato_tipico(id) ON DELETE CASCADE,
    ingrediente_id INT REFERENCES cultura.ingrediente_autoctono(id) ON DELETE CASCADE,
    PRIMARY KEY (plato_id, ingrediente_id)
);
COMMENT ON TABLE cultura.plato_ingrediente IS 'Tabla asociativa de ingredientes clave que componen cada platillo típico.';
COMMENT ON COLUMN cultura.plato_ingrediente.plato_id IS 'Identificador del plato típico.';
COMMENT ON COLUMN cultura.plato_ingrediente.ingrediente_id IS 'Identificador del ingrediente autóctono.';

-- Relación de platos con regiones geográficas (Muchos a Muchos)
CREATE TABLE cultura.plato_geografia (
    plato_id INT REFERENCES cultura.plato_tipico(id) ON DELETE CASCADE,
    departamento_id INT REFERENCES geografia.departamento(id) ON DELETE RESTRICT,
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    PRIMARY KEY (plato_id, departamento_id)
);
COMMENT ON TABLE cultura.plato_geografia IS 'Asociación de platillos tradicionales con los departamentos y municipios donde se originan o consumen tradicionalmente.';
COMMENT ON COLUMN cultura.plato_geografia.plato_id IS 'Identificador del plato típico.';
COMMENT ON COLUMN cultura.plato_geografia.departamento_id IS 'Departamento asociado al origen o tradición del platillo.';
COMMENT ON COLUMN cultura.plato_geografia.municipio_id IS 'Municipio específico donde es tradicional el platillo (opcional).';


-- 2. DIVERSIDAD LINGÜÍSTICA (IDIOMAS)

-- Idiomas
CREATE TABLE cultura.idioma (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    familia_linguistica VARCHAR(100),
    estado_vitalidad VARCHAR(50),
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE cultura.idioma IS 'Idiomas oficiales y lenguas nacionales habladas en el territorio de Guatemala.';
COMMENT ON COLUMN cultura.idioma.id IS 'Identificador único del idioma.';
COMMENT ON COLUMN cultura.idioma.nombre IS 'Nombre oficial del idioma (ej: K''iche'', Q''eqchi'', Garífuna).';
COMMENT ON COLUMN cultura.idioma.familia_linguistica IS 'Familia lingüística a la que pertenece el idioma (ej: Maya, Arahuaca, Aislada).';
COMMENT ON COLUMN cultura.idioma.estado_vitalidad IS 'Estado de conservación y uso del idioma (ej: Vital, En peligro, Crítico).';
COMMENT ON COLUMN cultura.idioma.descripcion IS 'Reseña histórica y cultural del idioma.';
COMMENT ON COLUMN cultura.idioma.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el idioma.';

-- Relación de idiomas y municipios (Muchos a Muchos)
CREATE TABLE cultura.idioma_municipio (
    idioma_id INT REFERENCES cultura.idioma(id) ON DELETE CASCADE,
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE CASCADE,
    es_predominante BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (idioma_id, municipio_id)
);
COMMENT ON TABLE cultura.idioma_municipio IS 'Mapeo de distribución territorial de los idiomas en los diferentes municipios del país.';
COMMENT ON COLUMN cultura.idioma_municipio.idioma_id IS 'Identificador del idioma.';
COMMENT ON COLUMN cultura.idioma_municipio.municipio_id IS 'Municipio donde se habla el idioma.';
COMMENT ON COLUMN cultura.idioma_municipio.es_predominante IS 'Indica si el idioma es el más hablado o de uso principal en el municipio.';


-- 3. FESTIVIDADES Y FERIAS PATRONALES

-- Eventos culturales
CREATE TABLE cultura.evento_cultural (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    tipo_evento VARCHAR(100),
    mes_celebracion INT CHECK (mes_celebracion BETWEEN 1 AND 12),
    dia_inicio INT CHECK (dia_inicio BETWEEN 1 AND 31),
    dia_fin INT CHECK (dia_fin BETWEEN 1 AND 31),
    descripcion TEXT,
    recomendaciones_viaje TEXT,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE cultura.evento_cultural IS 'Ferias patronales, festivales folklóricos y celebraciones tradicionales notables de Guatemala.';
COMMENT ON COLUMN cultura.evento_cultural.id IS 'Identificador único del evento.';
COMMENT ON COLUMN cultura.evento_cultural.nombre IS 'Nombre de la celebración o festividad.';
COMMENT ON COLUMN cultura.evento_cultural.tipo_evento IS 'Categoría del evento (ej: Feria Patronal, Ceremonia, Festival Artístico).';
COMMENT ON COLUMN cultura.evento_cultural.mes_celebracion IS 'Mes del año en que ocurre la celebración (1-12).';
COMMENT ON COLUMN cultura.evento_cultural.dia_inicio IS 'Día del mes en que comienza la festividad.';
COMMENT ON COLUMN cultura.evento_cultural.dia_fin IS 'Día del mes en que termina la festividad.';
COMMENT ON COLUMN cultura.evento_cultural.descripcion IS 'Reseña de las actividades, danzas y rituales del evento.';
COMMENT ON COLUMN cultura.evento_cultural.recomendaciones_viaje IS 'Consejos prácticos para visitantes locales y extranjeros durante el evento.';
COMMENT ON COLUMN cultura.evento_cultural.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el evento.';

-- Relación de eventos y municipios (Muchos a Muchos)
CREATE TABLE cultura.evento_municipio (
    evento_id INT REFERENCES cultura.evento_cultural(id) ON DELETE CASCADE,
    municipio_id INT REFERENCES geografia.municipio(id) ON DELETE CASCADE,
    PRIMARY KEY (evento_id, municipio_id)
);
COMMENT ON TABLE cultura.evento_municipio IS 'Vínculo de las celebraciones con los municipios en los que se llevan a cabo.';
COMMENT ON COLUMN cultura.evento_municipio.evento_id IS 'Identificador del evento cultural.';
COMMENT ON COLUMN cultura.evento_municipio.municipio_id IS 'Municipio donde se celebra la festividad.';

-- Crear índices para acelerar búsquedas comunes
CREATE INDEX ON cultura.plato_geografia (departamento_id);
CREATE INDEX ON cultura.idioma_municipio (municipio_id);
CREATE INDEX ON cultura.evento_municipio (municipio_id);
CREATE INDEX ON cultura.evento_cultural (mes_celebracion);
