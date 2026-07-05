-- ============================================================
-- Flyway migration: V20260705112000__crear_modelo_dimensional_bi_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: crear modelo dimensional para analitica/BI
-- ============================================================


-- --------------------------
-- 1. Dimensiones
-- --------------------------
CREATE TABLE turismo.dim_fecha (
  id_fecha INT PRIMARY KEY, -- formato YYYYMMDD
  fecha DATE NOT NULL UNIQUE,
  anio INT NOT NULL,
  trimestre INT NOT NULL,
  mes INT NOT NULL,
  nombre_mes VARCHAR(20) NOT NULL,
  dia INT NOT NULL,
  dia_semana INT NOT NULL,
  nombre_dia VARCHAR(20) NOT NULL,
  semana_anio INT NOT NULL,
  es_fin_semana BOOLEAN NOT NULL
);

INSERT INTO turismo.dim_fecha (id_fecha, fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia, semana_anio, es_fin_semana)
SELECT
  TO_CHAR(fecha, 'YYYYMMDD')::INT AS id_fecha,
  fecha::DATE,
  EXTRACT(YEAR FROM fecha)::INT,
  EXTRACT(QUARTER FROM fecha)::INT,
  EXTRACT(MONTH FROM fecha)::INT,
  TRIM(TO_CHAR(fecha, 'TMMonth')),
  EXTRACT(DAY FROM fecha)::INT,
  EXTRACT(ISODOW FROM fecha)::INT,
  TRIM(TO_CHAR(fecha, 'TMDay')),
  EXTRACT(WEEK FROM fecha)::INT,
  EXTRACT(ISODOW FROM fecha)::INT IN (6,7)
FROM GENERATE_SERIES('2015-01-01'::DATE, '2035-12-31'::DATE, INTERVAL '1 day') AS gs(fecha)
ON CONFLICT (id_fecha) DO NOTHING;

CREATE TABLE turismo.dim_fuente (
  id_fuente INT PRIMARY KEY,
  nombre VARCHAR(180) NOT NULL,
  tipo VARCHAR(60) NOT NULL,
  url VARCHAR(500) NOT NULL,
  fecha_consulta DATE NOT NULL,
  notas VARCHAR(500),
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_region (
  id_region INT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  descripcion TEXT,
  id_fuente INT,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_departamento (
  id_departamento INT PRIMARY KEY,
  codigo_ine CHAR(2) NOT NULL,
  nombre VARCHAR(80) NOT NULL,
  id_region INT NOT NULL REFERENCES turismo.dim_region(id_region),
  region_nombre VARCHAR(120) NOT NULL,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_municipio (
  id_municipio INT PRIMARY KEY,
  id_departamento INT NOT NULL REFERENCES turismo.dim_departamento(id_departamento),
  departamento_nombre VARCHAR(80) NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_categoria (
  id_categoria INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion VARCHAR(350),
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_actividad (
  id_actividad INT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(350),
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_temporada (
  id_temporada INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  meses VARCHAR(80) NOT NULL,
  descripcion VARCHAR(350),
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_patrimonio (
  id_patrimonio INT PRIMARY KEY,
  tipo VARCHAR(40) NOT NULL,
  nombre VARCHAR(180) NOT NULL,
  organismo VARCHAR(120) NOT NULL,
  anio_inscripcion INT,
  descripcion TEXT,
  id_fuente INT,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_ruta (
  id_ruta INT PRIMARY KEY,
  id_region INT REFERENCES turismo.dim_region(id_region),
  region_nombre VARCHAR(120),
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  duracion_dias INT,
  id_fuente INT,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE turismo.dim_destino (
  id_destino INT PRIMARY KEY,
  nombre VARCHAR(180) NOT NULL,
  tipo VARCHAR(40) NOT NULL,
  id_departamento INT NOT NULL REFERENCES turismo.dim_departamento(id_departamento),
  departamento_nombre VARCHAR(80) NOT NULL,
  id_municipio INT NULL REFERENCES turismo.dim_municipio(id_municipio),
  municipio_nombre VARCHAR(120),
  id_region INT NOT NULL REFERENCES turismo.dim_region(id_region),
  region_nombre VARCHAR(120) NOT NULL,
  descripcion TEXT NOT NULL,
  direccion_referencia VARCHAR(350),
  latitud NUMERIC(10,7),
  longitud NUMERIC(10,7),
  altitud_msnm INT,
  dificultad VARCHAR(40),
  tiempo_recomendado VARCHAR(80),
  costo_aprox_nacional_q NUMERIC(10,2),
  costo_aprox_extranjero_q NUMERIC(10,2),
  horario VARCHAR(180),
  es_area_protegida BOOLEAN NOT NULL DEFAULT FALSE,
  id_fuente_principal INT,
  fuente_principal VARCHAR(180),
  url_fuente_principal VARCHAR(500),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  checksum_origen VARCHAR(32),
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------
-- 2. Hechos derivados de catalogo turistico
-- --------------------------
CREATE TABLE turismo.fact_destino_catalogo (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  id_region INT NOT NULL REFERENCES turismo.dim_region(id_region),
  id_departamento INT NOT NULL REFERENCES turismo.dim_departamento(id_departamento),
  id_municipio INT NULL REFERENCES turismo.dim_municipio(id_municipio),
  tipo VARCHAR(40) NOT NULL,
  dificultad VARCHAR(40),
  total_categorias INT NOT NULL DEFAULT 0,
  total_actividades INT NOT NULL DEFAULT 0,
  total_temporadas INT NOT NULL DEFAULT 0,
  total_fuentes INT NOT NULL DEFAULT 0,
  total_recomendaciones INT NOT NULL DEFAULT 0,
  tiene_patrimonio BOOLEAN NOT NULL DEFAULT FALSE,
  total_patrimonios INT NOT NULL DEFAULT 0,
  es_area_protegida BOOLEAN NOT NULL DEFAULT FALSE,
  tiene_coordenadas BOOLEAN NOT NULL DEFAULT FALSE,
  tiene_horario BOOLEAN NOT NULL DEFAULT FALSE,
  costo_aprox_nacional_q NUMERIC(10,2),
  costo_aprox_extranjero_q NUMERIC(10,2),
  puntaje_bi_catalogo NUMERIC(8,2) NOT NULL DEFAULT 0,
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (id_fecha_carga, id_destino)
);

CREATE TABLE turismo.fact_destino_categoria (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  id_categoria INT NOT NULL REFERENCES turismo.dim_categoria(id_categoria),
  cantidad INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_fecha_carga, id_destino, id_categoria)
);

CREATE TABLE turismo.fact_destino_actividad (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  id_actividad INT NOT NULL REFERENCES turismo.dim_actividad(id_actividad),
  cantidad INT NOT NULL DEFAULT 1,
  notas VARCHAR(300),
  PRIMARY KEY (id_fecha_carga, id_destino, id_actividad)
);

CREATE TABLE turismo.fact_destino_temporada (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  id_temporada INT NOT NULL REFERENCES turismo.dim_temporada(id_temporada),
  cantidad INT NOT NULL DEFAULT 1,
  recomendacion VARCHAR(350),
  PRIMARY KEY (id_fecha_carga, id_destino, id_temporada)
);

CREATE TABLE turismo.fact_destino_patrimonio (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  id_patrimonio INT NOT NULL REFERENCES turismo.dim_patrimonio(id_patrimonio),
  cantidad INT NOT NULL DEFAULT 1,
  observacion VARCHAR(350),
  PRIMARY KEY (id_fecha_carga, id_destino, id_patrimonio)
);

CREATE TABLE turismo.fact_ruta_destino (
  id_fecha_carga INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_ruta INT NOT NULL REFERENCES turismo.dim_ruta(id_ruta),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  orden_visita INT NOT NULL,
  tiempo_sugerido VARCHAR(80),
  duracion_dias INT,
  cantidad INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_fecha_carga, id_ruta, id_destino)
);

-- Tabla preparada para metricas reales futuras: visitantes, reseñas, busquedas, redes.
CREATE TABLE turismo.fact_metrica_destino (
  id_fecha INT NOT NULL REFERENCES turismo.dim_fecha(id_fecha),
  id_destino INT NOT NULL REFERENCES turismo.dim_destino(id_destino),
  fuente_metrica VARCHAR(180),
  visitantes_nacionales INT,
  visitantes_extranjeros INT,
  calificacion_promedio NUMERIC(4,2),
  cantidad_resenas INT,
  busquedas_web INT,
  menciones_redes INT,
  fecha_carga_dw TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (id_fecha, id_destino, fuente_metrica)
);

CREATE INDEX idx_fact_destino_catalogo_region ON turismo.fact_destino_catalogo(id_fecha_carga, id_region);
CREATE INDEX idx_fact_destino_catalogo_departamento ON turismo.fact_destino_catalogo(id_fecha_carga, id_departamento);
CREATE INDEX idx_fact_destino_categoria_categoria ON turismo.fact_destino_categoria(id_fecha_carga, id_categoria);
CREATE INDEX idx_fact_destino_actividad_actividad ON turismo.fact_destino_actividad(id_fecha_carga, id_actividad);
CREATE INDEX idx_fact_metrica_destino_destino_fecha ON turismo.fact_metrica_destino(id_destino, id_fecha);

-- Comentarios para diccionario de datos generado desde metadata.
COMMENT ON TABLE turismo.dim_fecha IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_fecha.id_fecha IS 'Llave de fecha en formato YYYYMMDD.';
COMMENT ON COLUMN turismo.dim_fecha.anio IS 'Anio calendario.';
COMMENT ON COLUMN turismo.dim_fecha.trimestre IS 'Trimestre calendario.';
COMMENT ON COLUMN turismo.dim_fecha.mes IS 'Numero de mes calendario.';
COMMENT ON COLUMN turismo.dim_fecha.nombre_mes IS 'Nombre del mes.';
COMMENT ON COLUMN turismo.dim_fecha.dia IS 'Dia del mes.';
COMMENT ON COLUMN turismo.dim_fecha.dia_semana IS 'Dia de la semana en formato ISO.';
COMMENT ON COLUMN turismo.dim_fecha.nombre_dia IS 'Nombre del dia de la semana.';
COMMENT ON COLUMN turismo.dim_fecha.semana_anio IS 'Numero de semana del anio.';
COMMENT ON COLUMN turismo.dim_fecha.es_fin_semana IS 'Indica si la fecha corresponde a sabado o domingo.';

COMMENT ON TABLE turismo.dim_fuente IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_fuente.id_fuente IS 'Campo id fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_fuente.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_fuente.tipo IS 'Campo tipo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_fuente.url IS 'Campo url del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_fuente.fecha_consulta IS 'Campo fecha consulta del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_fuente.notas IS 'Campo notas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_fuente.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_region IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_region.id_region IS 'Campo id region del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_region.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_region.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_region.id_fuente IS 'Campo id fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_region.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_departamento IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_departamento.id_departamento IS 'Campo id departamento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_departamento.codigo_ine IS 'Campo codigo ine del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_departamento.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_departamento.id_region IS 'Campo id region del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_departamento.region_nombre IS 'Campo region nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_departamento.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_municipio IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_municipio.id_municipio IS 'Campo id municipio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_municipio.id_departamento IS 'Campo id departamento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_municipio.departamento_nombre IS 'Campo departamento nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_municipio.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_municipio.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_categoria IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_categoria.id_categoria IS 'Campo id categoria del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_categoria.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_categoria.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_categoria.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_actividad IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_actividad.id_actividad IS 'Campo id actividad del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_actividad.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_actividad.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_actividad.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_temporada IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_temporada.id_temporada IS 'Campo id temporada del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_temporada.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_temporada.meses IS 'Campo meses del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_temporada.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_temporada.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_patrimonio IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_patrimonio.id_patrimonio IS 'Campo id patrimonio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_patrimonio.tipo IS 'Campo tipo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_patrimonio.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_patrimonio.organismo IS 'Campo organismo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_patrimonio.anio_inscripcion IS 'Campo anio inscripcion del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_patrimonio.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_patrimonio.id_fuente IS 'Campo id fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_patrimonio.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_ruta IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_ruta.id_ruta IS 'Campo id ruta del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_ruta.id_region IS 'Campo id region del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_ruta.region_nombre IS 'Campo region nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_ruta.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_ruta.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_ruta.duracion_dias IS 'Campo duracion dias del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_ruta.id_fuente IS 'Campo id fuente del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_ruta.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.dim_destino IS 'Dimension del modelo BI de turismo utilizada para analisis descriptivo.';
COMMENT ON COLUMN turismo.dim_destino.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.nombre IS 'Nombre del registro.';
COMMENT ON COLUMN turismo.dim_destino.tipo IS 'Campo tipo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.id_departamento IS 'Campo id departamento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.departamento_nombre IS 'Campo departamento nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.id_municipio IS 'Campo id municipio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.municipio_nombre IS 'Campo municipio nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.id_region IS 'Campo id region del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.region_nombre IS 'Campo region nombre del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.descripcion IS 'Descripcion del registro.';
COMMENT ON COLUMN turismo.dim_destino.direccion_referencia IS 'Campo direccion referencia del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.latitud IS 'Campo latitud del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.longitud IS 'Campo longitud del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.altitud_msnm IS 'Campo altitud msnm del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.dificultad IS 'Campo dificultad del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.tiempo_recomendado IS 'Campo tiempo recomendado del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.costo_aprox_nacional_q IS 'Campo costo aprox nacional q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.costo_aprox_extranjero_q IS 'Campo costo aprox extranjero q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.horario IS 'Campo horario del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.es_area_protegida IS 'Campo es area protegida del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.id_fuente_principal IS 'Campo id fuente principal del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.fuente_principal IS 'Campo fuente principal del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.url_fuente_principal IS 'Campo url fuente principal del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.dim_destino.activo IS 'Indica si el registro se encuentra activo.';
COMMENT ON COLUMN turismo.dim_destino.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

COMMENT ON TABLE turismo.fact_destino_catalogo IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.id_region IS 'Campo id region del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.id_departamento IS 'Campo id departamento del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.id_municipio IS 'Campo id municipio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.tipo IS 'Campo tipo del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.dificultad IS 'Campo dificultad del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_categorias IS 'Campo total categorias del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_actividades IS 'Campo total actividades del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_temporadas IS 'Campo total temporadas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_fuentes IS 'Campo total fuentes del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_recomendaciones IS 'Campo total recomendaciones del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.tiene_patrimonio IS 'Campo tiene patrimonio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.total_patrimonios IS 'Campo total patrimonios del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.es_area_protegida IS 'Campo es area protegida del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.tiene_coordenadas IS 'Campo tiene coordenadas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.tiene_horario IS 'Campo tiene horario del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.costo_aprox_nacional_q IS 'Campo costo aprox nacional q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.costo_aprox_extranjero_q IS 'Campo costo aprox extranjero q del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.puntaje_bi_catalogo IS 'Puntaje calculado para priorizar destinos en tableros BI.';
COMMENT ON COLUMN turismo.fact_destino_catalogo.fecha_actualizacion IS 'Fecha y hora de actualizacion del hecho.';

COMMENT ON TABLE turismo.fact_destino_categoria IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_destino_categoria.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_destino_categoria.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_categoria.id_categoria IS 'Campo id categoria del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_categoria.cantidad IS 'Cantidad contabilizada para el hecho.';

COMMENT ON TABLE turismo.fact_destino_actividad IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_destino_actividad.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_destino_actividad.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_actividad.id_actividad IS 'Campo id actividad del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_actividad.cantidad IS 'Cantidad contabilizada para el hecho.';
COMMENT ON COLUMN turismo.fact_destino_actividad.notas IS 'Campo notas del objeto BI o ETL de turismo.';

COMMENT ON TABLE turismo.fact_destino_temporada IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_destino_temporada.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_destino_temporada.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_temporada.id_temporada IS 'Campo id temporada del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_temporada.cantidad IS 'Cantidad contabilizada para el hecho.';
COMMENT ON COLUMN turismo.fact_destino_temporada.recomendacion IS 'Campo recomendacion del objeto BI o ETL de turismo.';

COMMENT ON TABLE turismo.fact_destino_patrimonio IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_destino_patrimonio.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_destino_patrimonio.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_patrimonio.id_patrimonio IS 'Campo id patrimonio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_destino_patrimonio.cantidad IS 'Cantidad contabilizada para el hecho.';
COMMENT ON COLUMN turismo.fact_destino_patrimonio.observacion IS 'Campo observacion del objeto BI o ETL de turismo.';

COMMENT ON TABLE turismo.fact_ruta_destino IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_ruta_destino.id_fecha_carga IS 'Llave de fecha asociada a la carga del hecho.';
COMMENT ON COLUMN turismo.fact_ruta_destino.id_ruta IS 'Campo id ruta del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_ruta_destino.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_ruta_destino.orden_visita IS 'Campo orden visita del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_ruta_destino.tiempo_sugerido IS 'Campo tiempo sugerido del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_ruta_destino.duracion_dias IS 'Campo duracion dias del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_ruta_destino.cantidad IS 'Cantidad contabilizada para el hecho.';

COMMENT ON TABLE turismo.fact_metrica_destino IS 'Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.';
COMMENT ON COLUMN turismo.fact_metrica_destino.id_fecha IS 'Llave de fecha en formato YYYYMMDD.';
COMMENT ON COLUMN turismo.fact_metrica_destino.id_destino IS 'Campo id destino del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.fuente_metrica IS 'Campo fuente metrica del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.visitantes_nacionales IS 'Campo visitantes nacionales del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.visitantes_extranjeros IS 'Campo visitantes extranjeros del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.calificacion_promedio IS 'Campo calificacion promedio del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.cantidad_resenas IS 'Campo cantidad resenas del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.busquedas_web IS 'Campo busquedas web del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.menciones_redes IS 'Campo menciones redes del objeto BI o ETL de turismo.';
COMMENT ON COLUMN turismo.fact_metrica_destino.fecha_carga_dw IS 'Fecha y hora de carga en el modelo dimensional.';

