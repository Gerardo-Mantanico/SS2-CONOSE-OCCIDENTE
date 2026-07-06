-- Migración para el esquema de economía avanzada (11 tablas)
-- Agrega soporte para logística (rutas), inclusión financiera (cooperativas), certificaciones de calidad y producción certificada.

CREATE TABLE economia.ruta_comercio (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    origen_municipio_id INT NOT NULL REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    destino_municipio_id INT REFERENCES geografia.municipio(id) ON DELETE RESTRICT,
    puerto_salida VARCHAR(100),
    medio_transporte VARCHAR(100) NOT NULL CHECK (medio_transporte IN ('Terrestre - Camión de Carga', 'Terrestre - Camión de Volteo', 'Fluvial - Lancha', 'Marítimo - Buque', 'Aéreo')),
    distancia_km NUMERIC(6,2) CHECK (distancia_km >= 0),
    tiempo_estimado_horas NUMERIC(4,2) CHECK (tiempo_estimado_horas >= 0),
    producto_principal VARCHAR(150),
    carga_id INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE economia.ruta_comercio IS 'Registro de flujos logísticos y rutas de comercio de mercancías entre municipios o puertos de salida.';
COMMENT ON COLUMN economia.ruta_comercio.id IS 'Identificador único de la ruta de comercio.';
COMMENT ON COLUMN economia.ruta_comercio.origen_municipio_id IS 'Identificador del municipio origen del flujo comercial.';
COMMENT ON COLUMN economia.ruta_comercio.destino_municipio_id IS 'Identificador del municipio destino del flujo comercial (opcional si es exportación).';
COMMENT ON COLUMN economia.ruta_comercio.puerto_salida IS 'Nombre del puerto marítimo o frontera terrestre de destino para exportación (ej: Puerto Quetzal, Tecún Umán).';
COMMENT ON COLUMN economia.ruta_comercio.medio_transporte IS 'Medio de transporte utilizado para movilizar la mercancía.';
COMMENT ON COLUMN economia.ruta_comercio.distancia_km IS 'Distancia aproximada de la ruta en kilómetros.';
COMMENT ON COLUMN economia.ruta_comercio.tiempo_estimado_horas IS 'Tiempo de tránsito estimado en horas.';
COMMENT ON COLUMN economia.ruta_comercio.producto_principal IS 'Nombre del producto principal movilizado en la ruta.';
COMMENT ON COLUMN economia.ruta_comercio.carga_id IS 'Referencia a la auditoría de carga de datos.';

CREATE TABLE economia.servicio_financiero (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cooperativa_id INT NOT NULL REFERENCES economia.cooperativa_asociacion(id) ON DELETE CASCADE,
    tipo_servicio VARCHAR(100) NOT NULL CHECK (tipo_servicio IN ('Microcrédito Agrícola', 'Crédito Artesanal', 'Ahorro Plazo Fijo', 'Remesas Familiares', 'Financiamiento de Equipo')),
    tasa_interes_anual NUMERIC(4,2) CHECK (tasa_interes_anual BETWEEN 0.0 AND 100.0),
    monto_maximo_quetzales NUMERIC(12,2) CHECK (monto_maximo_quetzales >= 0),
    requisito_principal TEXT,
    carga_id INT REFERENCES meta.carga(id),
    UNIQUE (cooperativa_id, tipo_servicio)
);

COMMENT ON TABLE economia.servicio_financiero IS 'Líneas de crédito y servicios de inclusión financiera ofrecidos por cooperativas rurales.';
COMMENT ON COLUMN economia.servicio_financiero.id IS 'Identificador único del servicio financiero.';
COMMENT ON COLUMN economia.servicio_financiero.cooperativa_id IS 'Referencia a la cooperativa que ofrece el servicio.';
COMMENT ON COLUMN economia.servicio_financiero.tipo_servicio IS 'Clasificación de producto crediticio o financiero.';
COMMENT ON COLUMN economia.servicio_financiero.tasa_interes_anual IS 'Tasa de interés anualizada del servicio financiero.';
COMMENT ON COLUMN economia.servicio_financiero.monto_maximo_quetzales IS 'Monto máximo de financiamiento en Quetzales.';
COMMENT ON COLUMN economia.servicio_financiero.requisito_principal IS 'Descripción del principal requisito para optar al financiamiento.';
COMMENT ON COLUMN economia.servicio_financiero.carga_id IS 'Referencia a la auditoría de carga de datos.';

CREATE TABLE economia.certificacion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) UNIQUE NOT NULL,
    ente_certificador VARCHAR(150) NOT NULL,
    descripcion TEXT,
    carga_id INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE economia.certificacion IS 'Catálogo de sellos de calidad, origen, orgánicos o de comercio justo vigentes en el país.';
COMMENT ON COLUMN economia.certificacion.id IS 'Identificador único de la certificación.';
COMMENT ON COLUMN economia.certificacion.nombre IS 'Nombre distintivo de la certificación o sello (ej: Orgánico USDA, Fairtrade).';
COMMENT ON COLUMN economia.certificacion.ente_certificador IS 'Institución o empresa auditora que expide la certificación.';
COMMENT ON COLUMN economia.certificacion.descripcion IS 'Descripción del propósito y alcance del sello.';
COMMENT ON COLUMN economia.certificacion.carga_id IS 'Referencia a la auditoría de carga de datos.';

CREATE TABLE economia.produccion_certificada (
    municipio_id INT NOT NULL,
    actividad_id INT NOT NULL,
    certificacion_id INT NOT NULL REFERENCES economia.certificacion(id) ON DELETE CASCADE,
    porcentaje_produccion NUMERIC(5,2) CHECK (porcentaje_produccion BETWEEN 0.0 AND 100.0),
    fecha_auditoria DATE NOT NULL,
    carga_id INT REFERENCES meta.carga(id),
    PRIMARY KEY (municipio_id, actividad_id, certificacion_id),
    FOREIGN KEY (municipio_id, actividad_id) REFERENCES economia.produccion_municipal(municipio_id, actividad_id) ON DELETE CASCADE
);

COMMENT ON TABLE economia.produccion_certificada IS 'Asociación de la producción municipal con sus respectivas certificaciones nacionales o internacionales.';
COMMENT ON COLUMN economia.produccion_certificada.municipio_id IS 'Identificador del municipio productor.';
COMMENT ON COLUMN economia.produccion_certificada.actividad_id IS 'Identificador de la actividad productiva.';
COMMENT ON COLUMN economia.produccion_certificada.certificacion_id IS 'Referencia a la certificación que ostenta esta producción.';
COMMENT ON COLUMN economia.produccion_certificada.porcentaje_produccion IS 'Porcentaje estimado de la producción del municipio amparado por la certificación.';
COMMENT ON COLUMN economia.produccion_certificada.fecha_auditoria IS 'Fecha de la última auditoría de control de calidad.';
COMMENT ON COLUMN economia.produccion_certificada.carga_id IS 'Referencia a la auditoría de carga de datos.';
