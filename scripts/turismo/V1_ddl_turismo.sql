-- ============================================================
-- Flyway migration: V1__crear_schema_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Objetivo: crear estructura relacional para el modulo Turismo
-- ============================================================

CREATE SCHEMA IF NOT EXISTS turismo;
SET search_path TO turismo, public;

CREATE TYPE tipo_destino AS ENUM (
  'NATURAL', 'CULTURAL', 'ARQUEOLOGICO', 'URBANO', 'RELIGIOSO', 'RECREATIVO', 'MIXTO'
);

CREATE TYPE dificultad_destino AS ENUM (
  'BAJA', 'MEDIA', 'ALTA', 'VARIABLE'
);

CREATE TYPE tipo_patrimonio AS ENUM (
  'UNESCO_CULTURAL', 'UNESCO_NATURAL', 'UNESCO_MIXTO', 'UNESCO_INTANGIBLE', 'NACIONAL'
);

CREATE TYPE tipo_recomendacion AS ENUM (
  'SEGURIDAD', 'AMBIENTAL', 'CULTURAL', 'LOGISTICA'
);

-- ============================================================
-- BASE DE DATOS: Turismo Guatemala / Conocer Guatemala
-- Motor: PostgreSQL
-- Autor: generado para proyecto academico
-- Fecha de consulta de fuentes: 2026-06-29
-- Objetivo: almacenar informacion real de destinos turisticos de Guatemala
--          con trazabilidad por fuentes.
-- ============================================================


-- --------------------------
-- 1. FUENTES
-- --------------------------
CREATE TABLE fuente (
  id_fuente INT PRIMARY KEY,
  nombre VARCHAR(180) NOT NULL,
  tipo VARCHAR(60) NOT NULL,
  url VARCHAR(500) NOT NULL,
  fecha_consulta DATE NOT NULL,
  notas VARCHAR(500)
);

-- --------------------------
-- 2. GEOGRAFIA TURISTICA
-- --------------------------
CREATE TABLE region_turistica (
  id_region INT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  descripcion TEXT,
  id_fuente INT,
  CONSTRAINT fk_region_fuente FOREIGN KEY (id_fuente) REFERENCES fuente(id_fuente)
);

CREATE TABLE departamento (
  id_departamento INT PRIMARY KEY,
  codigo_ine CHAR(2) NOT NULL UNIQUE,
  nombre VARCHAR(80) NOT NULL UNIQUE,
  id_region INT NOT NULL,
  CONSTRAINT fk_departamento_region FOREIGN KEY (id_region) REFERENCES region_turistica(id_region)
);

CREATE TABLE municipio (
  id_municipio INT PRIMARY KEY,
  id_departamento INT NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  CONSTRAINT uq_municipio UNIQUE (id_departamento, nombre),
  CONSTRAINT fk_municipio_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);

-- --------------------------
-- 3. CLASIFICACION TURISTICA
-- --------------------------
CREATE TABLE categoria_destino (
  id_categoria INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(350)
);

CREATE TABLE actividad (
  id_actividad INT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  descripcion VARCHAR(350)
);

CREATE TABLE temporada (
  id_temporada INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  meses VARCHAR(80) NOT NULL,
  descripcion VARCHAR(350)
);

-- --------------------------
-- 4. DESTINOS / SITIOS
-- --------------------------
CREATE TABLE destino (
  id_destino INT PRIMARY KEY,
  nombre VARCHAR(180) NOT NULL,
  tipo tipo_destino NOT NULL,
  id_departamento INT NOT NULL,
  id_municipio INT NULL,
  descripcion TEXT NOT NULL,
  direccion_referencia VARCHAR(350),
  latitud DECIMAL(10,7) NULL,
  longitud DECIMAL(10,7) NULL,
  altitud_msnm INT NULL,
  dificultad dificultad_destino DEFAULT 'BAJA',
  tiempo_recomendado VARCHAR(80),
  costo_aprox_nacional_q DECIMAL(10,2) NULL,
  costo_aprox_extranjero_q DECIMAL(10,2) NULL,
  horario VARCHAR(180) NULL,
  es_area_protegida BOOLEAN DEFAULT FALSE,
  id_fuente_principal INT NULL,
  activo BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_destino_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento),
  CONSTRAINT fk_destino_municipio FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio),
  CONSTRAINT fk_destino_fuente FOREIGN KEY (id_fuente_principal) REFERENCES fuente(id_fuente)
);

CREATE TABLE destino_categoria (
  id_destino INT NOT NULL,
  id_categoria INT NOT NULL,
  PRIMARY KEY (id_destino, id_categoria),
  CONSTRAINT fk_dc_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino),
  CONSTRAINT fk_dc_categoria FOREIGN KEY (id_categoria) REFERENCES categoria_destino(id_categoria)
);

CREATE TABLE destino_actividad (
  id_destino INT NOT NULL,
  id_actividad INT NOT NULL,
  notas VARCHAR(300),
  PRIMARY KEY (id_destino, id_actividad),
  CONSTRAINT fk_da_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino),
  CONSTRAINT fk_da_actividad FOREIGN KEY (id_actividad) REFERENCES actividad(id_actividad)
);

CREATE TABLE destino_temporada (
  id_destino INT NOT NULL,
  id_temporada INT NOT NULL,
  recomendacion VARCHAR(350),
  PRIMARY KEY (id_destino, id_temporada),
  CONSTRAINT fk_dt_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino),
  CONSTRAINT fk_dt_temporada FOREIGN KEY (id_temporada) REFERENCES temporada(id_temporada)
);

CREATE TABLE fuente_destino (
  id_destino INT NOT NULL,
  id_fuente INT NOT NULL,
  detalle VARCHAR(350),
  PRIMARY KEY (id_destino, id_fuente),
  CONSTRAINT fk_fd_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino),
  CONSTRAINT fk_fd_fuente FOREIGN KEY (id_fuente) REFERENCES fuente(id_fuente)
);

-- --------------------------
-- 5. PATRIMONIO Y RUTAS
-- --------------------------
CREATE TABLE patrimonio (
  id_patrimonio INT PRIMARY KEY,
  tipo tipo_patrimonio NOT NULL,
  nombre VARCHAR(180) NOT NULL,
  organismo VARCHAR(120) NOT NULL,
  anio_inscripcion INT NULL,
  descripcion TEXT,
  id_fuente INT NULL,
  CONSTRAINT fk_patrimonio_fuente FOREIGN KEY (id_fuente) REFERENCES fuente(id_fuente)
);

CREATE TABLE destino_patrimonio (
  id_destino INT NOT NULL,
  id_patrimonio INT NOT NULL,
  observacion VARCHAR(350),
  PRIMARY KEY (id_destino, id_patrimonio),
  CONSTRAINT fk_dp_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino),
  CONSTRAINT fk_dp_patrimonio FOREIGN KEY (id_patrimonio) REFERENCES patrimonio(id_patrimonio)
);

CREATE TABLE ruta_turistica (
  id_ruta INT PRIMARY KEY,
  id_region INT NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  duracion_dias INT,
  id_fuente INT NULL,
  CONSTRAINT fk_ruta_region FOREIGN KEY (id_region) REFERENCES region_turistica(id_region),
  CONSTRAINT fk_ruta_fuente FOREIGN KEY (id_fuente) REFERENCES fuente(id_fuente)
);

CREATE TABLE ruta_destino (
  id_ruta INT NOT NULL,
  id_destino INT NOT NULL,
  orden_visita INT NOT NULL,
  tiempo_sugerido VARCHAR(80),
  PRIMARY KEY (id_ruta, id_destino),
  CONSTRAINT fk_rd_ruta FOREIGN KEY (id_ruta) REFERENCES ruta_turistica(id_ruta),
  CONSTRAINT fk_rd_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino)
);

CREATE TABLE recomendacion_destino (
  id_recomendacion INT PRIMARY KEY,
  id_destino INT NOT NULL,
  tipo tipo_recomendacion NOT NULL,
  recomendacion VARCHAR(500) NOT NULL,
  CONSTRAINT fk_rec_destino FOREIGN KEY (id_destino) REFERENCES destino(id_destino)
);
