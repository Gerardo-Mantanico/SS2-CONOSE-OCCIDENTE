-- =============================================================================
-- Sector Publico — Declaracion de bienes de trabajadores
-- Tablas definidas en el modelo ER (JSON Justicia) ausentes en la migracion base.
-- Dependen de sector_publico.trabajador, creado en V20260702070824.
-- =============================================================================

-- Catalogo de bancos del sistema financiero
CREATE TABLE sector_publico.banco (
    id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE
);
COMMENT ON TABLE sector_publico.banco IS 'Catalogo de bancos para declaraciones de bienes de trabajadores.';

-- Rol del trabajador dentro de una empresa privada
CREATE TABLE sector_publico.rol_empresa (
    id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);
COMMENT ON TABLE sector_publico.rol_empresa IS 'Rol que ejerce un trabajador en una empresa (socio, director, accionista, etc.).';

-- Vehiculos declarados
CREATE TABLE sector_publico.vehiculo (
    id                INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id     INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    placa             VARCHAR(20),
    marca             VARCHAR(100),
    modelo            VARCHAR(100),
    anio              SMALLINT,
    valor_declarado   DECIMAL(15, 2),
    fecha_adquisicion DATE
);
COMMENT ON TABLE sector_publico.vehiculo IS 'Vehiculos declarados por trabajadores del sector publico.';

-- Cuentas bancarias declaradas
CREATE TABLE sector_publico.cuenta_bancaria (
    id              INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id   INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    banco_id        INT  NOT NULL REFERENCES sector_publico.banco(id),
    tipo_cuenta     VARCHAR(50),
    no_cuenta       VARCHAR(50),
    moneda          VARCHAR(10) DEFAULT 'GTQ',
    saldo_declarado DECIMAL(15, 2),
    fecha_apertura  DATE
);
COMMENT ON TABLE sector_publico.cuenta_bancaria IS 'Cuentas bancarias declaradas por trabajadores del sector publico.';

-- Inmuebles declarados
CREATE TABLE sector_publico.inmueble (
    id                 INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id      INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    municipio_id       INT  REFERENCES geografia.municipio(id),
    direccion          TEXT,
    no_finca           VARCHAR(50),
    area_mc            DECIMAL(15, 4),
    valor_declarado    DECIMAL(15, 2),
    forma_adquisicion  VARCHAR(100),
    fecha_adquisicion  DATE
);
COMMENT ON TABLE sector_publico.inmueble IS 'Inmuebles declarados por trabajadores del sector publico.';

-- Empresas en las que participa el trabajador
CREATE TABLE sector_publico.empresa (
    id                         INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id              INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    rol_empresa_id             INT  REFERENCES sector_publico.rol_empresa(id),
    nombre                     VARCHAR(200) NOT NULL,
    nit                        VARCHAR(20),
    porcentaje_participacion   DECIMAL(5, 2),
    valor_declarado            DECIMAL(15, 2),
    fecha_inicio_participacion DATE
);
COMMENT ON TABLE sector_publico.empresa IS 'Empresas privadas en las que participa un trabajador del sector publico.';
