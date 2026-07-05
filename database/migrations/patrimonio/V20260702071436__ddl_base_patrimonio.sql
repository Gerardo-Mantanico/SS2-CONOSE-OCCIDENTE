
CREATE SCHEMA IF NOT EXISTS patrimonio;

COMMENT ON SCHEMA patrimonio IS 'Declaraciones patrimoniales de servidores públicos: bienes, cuentas y empresas.';

-- Cuentas bancarias
CREATE TABLE patrimonio.banco (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.banco IS'Catálogo de instituciones bancarias utilizadas en las declaraciones patrimoniales.';
COMMENT ON COLUMN patrimonio.banco.id IS'Identificador único del banco.';
COMMENT ON COLUMN patrimonio.banco.nombre IS'Nombre de la institución bancaria.';
COMMENT ON COLUMN patrimonio.banco.carga_id IS'Referencia a la carga de datos mediante la cual se registró el banco.';


CREATE TABLE patrimonio.cuenta_bancaria (
    id              INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id   INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    banco_id        INT  NOT NULL REFERENCES patrimonio.banco(id),
    tipo_cuenta     VARCHAR(50),
    no_cuenta       VARCHAR(50),
    moneda          VARCHAR(20),
    saldo_declarado DECIMAL(15,2),
    fecha_apertura  DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.cuenta_bancaria IS'Información de cuentas bancarias declaradas por un servidor público.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.id IS'Identificador único de la cuenta bancaria registrada.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.trabajador_id IS'Servidor público propietario de la cuenta.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.banco_id IS'Banco donde se encuentra registrada la cuenta.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.tipo_cuenta IS'Tipo de cuenta bancaria (ahorro, monetaria u otro).';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.no_cuenta IS'Número de la cuenta bancaria declarada.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.moneda IS'Moneda en la que está denominada la cuenta.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.saldo_declarado IS'Saldo declarado para la cuenta bancaria.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.fecha_apertura IS'Fecha de apertura de la cuenta bancaria.';
COMMENT ON COLUMN patrimonio.cuenta_bancaria.carga_id IS'Referencia a la carga de datos mediante la cual se registró la cuenta.';

-- Vehículos
CREATE TABLE patrimonio.vehiculo (
    id                INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id     INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    placa             VARCHAR(20),
    marca             VARCHAR(50),
    modelo            VARCHAR(50),
    anio              INT,
    valor_declarado   DECIMAL(15,2),
    fecha_adquisicion DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.vehiculo IS'Vehículos declarados como parte del patrimonio de un servidor público.';
COMMENT ON COLUMN patrimonio.vehiculo.id IS'Identificador único del vehículo registrado.';
COMMENT ON COLUMN patrimonio.vehiculo.trabajador_id IS'Servidor público propietario del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.placa IS'Número de placa del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.marca IS'Marca del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.modelo IS'Modelo del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.anio IS'Año de fabricación del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.valor_declarado IS'Valor declarado del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.fecha_adquisicion IS'Fecha de adquisición del vehículo.';
COMMENT ON COLUMN patrimonio.vehiculo.carga_id IS'Referencia a la carga de datos mediante la cual se registró el vehículo.';

-- Inmuebles
CREATE TABLE patrimonio.inmueble (
    id                INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id     INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    municipio_id      INT  NOT NULL REFERENCES geografia.municipio(id),
    direccion         VARCHAR(255),
    no_finca          VARCHAR(50),
    area_m2           DECIMAL(12,4),   --area_m2 (metros cuadrados)
    valor_declarado   DECIMAL(15,2),
    forma_adquisicion VARCHAR(100),
    fecha_adquisicion DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.inmueble IS'Bienes inmuebles declarados por un servidor público.';
COMMENT ON COLUMN patrimonio.inmueble.id IS'Identificador único del inmueble registrado.';
COMMENT ON COLUMN patrimonio.inmueble.trabajador_id IS'Servidor público propietario del inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.municipio_id IS'Municipio donde se ubica el inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.direccion IS'Dirección del inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.no_finca IS'Número de finca o identificador registral del inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.area_m2 IS'Área del inmueble expresada en metros cuadrados.';
COMMENT ON COLUMN patrimonio.inmueble.valor_declarado IS'Valor declarado del inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.forma_adquisicion IS'Forma mediante la cual fue adquirido el inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.fecha_adquisicion IS'Fecha de adquisición del inmueble.';
COMMENT ON COLUMN patrimonio.inmueble.carga_id IS'Referencia a la carga de datos mediante la cual se registró el inmueble.';


-- Participación en empresas
CREATE TABLE patrimonio.rol_empresa (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.rol_empresa IS'Catálogo de roles que una persona puede desempeñar dentro de una empresa.';
COMMENT ON COLUMN patrimonio.rol_empresa.id IS'Identificador único del rol empresarial.';
COMMENT ON COLUMN patrimonio.rol_empresa.nombre IS'Nombre del rol empresarial.';
COMMENT ON COLUMN patrimonio.rol_empresa.carga_id IS'Referencia a la carga de datos mediante la cual se registró el rol empresarial.';


CREATE TABLE patrimonio.empresa (
    id                         INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id              INT  NOT NULL REFERENCES sector_publico.trabajador(id),
    rol_empresa_id             INT  NOT NULL REFERENCES patrimonio.rol_empresa(id),
    nombre                     VARCHAR(150),
    nit                        VARCHAR(20),
    area_m2                    DECIMAL(12,4),
    porcentaje_participacion   DECIMAL(5,2),
    valor_declarado            DECIMAL(15,2),
    fecha_inicio_participacion DATE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE patrimonio.empresa IS'Participaciones empresariales declaradas por un servidor público.';
COMMENT ON COLUMN patrimonio.empresa.id IS'Identificador único de la participación empresarial.';
COMMENT ON COLUMN patrimonio.empresa.trabajador_id IS'Servidor público que participa en la empresa.';
COMMENT ON COLUMN patrimonio.empresa.rol_empresa_id IS'Rol desempeñado dentro de la empresa.';
COMMENT ON COLUMN patrimonio.empresa.nombre IS'Nombre de la empresa.';
COMMENT ON COLUMN patrimonio.empresa.nit IS'Número de Identificación Tributaria de la empresa.';
COMMENT ON COLUMN patrimonio.empresa.area_m2 IS'Área física de las instalaciones de la empresa, expresada en metros cuadrados.';
COMMENT ON COLUMN patrimonio.empresa.porcentaje_participacion IS'Porcentaje de participación accionaria o patrimonial.';
COMMENT ON COLUMN patrimonio.empresa.valor_declarado IS'Valor declarado de la participación empresarial.';
COMMENT ON COLUMN patrimonio.empresa.fecha_inicio_participacion IS'Fecha de inicio de la participación en la empresa.';
COMMENT ON COLUMN patrimonio.empresa.carga_id IS'Referencia a la carga de datos mediante la cual se registró la participación.';
