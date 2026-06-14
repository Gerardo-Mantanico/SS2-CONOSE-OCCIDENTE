-- ========================
-- MÓDULO TRABAJADOR
-- ========================

CREATE TABLE Trabajador (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    persona_id INT NOT NULL,
    esta_activo TINYINT(1) DEFAULT 1,
    FOREIGN KEY (persona_id) REFERENCES persona(id)
);

CREATE TABLE banco (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE cuenta_bancaria (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    trabajador_id   INT NOT NULL,
    banco_id        INT NOT NULL,
    tipo_cuenta     VARCHAR(50),
    no_cuenta       VARCHAR(50),
    moneda          VARCHAR(20),
    saldo_declarado DECIMAL(15,2),
    fecha_apertura  DATE,
    FOREIGN KEY (trabajador_id) REFERENCES Trabajador(id),
    FOREIGN KEY (banco_id)      REFERENCES banco(id)
);

CREATE TABLE vehiculo (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    trabajador_id   INT NOT NULL,
    placa           VARCHAR(20),
    marca           VARCHAR(50),
    modelo          VARCHAR(50),
    anio            INT,
    valor_declarado DECIMAL(15,2),
    fecha_adquisicion DATE,
    FOREIGN KEY (trabajador_id) REFERENCES Trabajador(id)
);

CREATE TABLE inmueble (
    id                INT PRIMARY KEY AUTO_INCREMENT,
    trabajador_id     INT NOT NULL,
    municipio_id      INT NOT NULL,
    direccion         VARCHAR(255),
    no_finca          VARCHAR(50),
    area_mc           DECIMAL(12,4),
    valor_declarado   DECIMAL(15,2),
    forma_adquisicion VARCHAR(100),
    fecha_adquisicion DATE,
    FOREIGN KEY (trabajador_id) REFERENCES Trabajador(id),
    FOREIGN KEY (municipio_id)  REFERENCES municipio(id)
);

-- ========================
-- MÓDULO EMPRESA / CONTRATO
-- ========================

CREATE TABLE rol_empresa (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE empresa (
    id                      INT PRIMARY KEY AUTO_INCREMENT,
    trabajador_id           INT NOT NULL,
    rol_empresa_id          INT NOT NULL,
    nombre                  VARCHAR(150),
    nit                     VARCHAR(20),
    area_mc                 DECIMAL(12,4),
    porcentaje_participacion DECIMAL(5,2),
    valor_declarado         DECIMAL(15,2),
    fecha_inicio_participacion DATE,
    FOREIGN KEY (trabajador_id)  REFERENCES Trabajador(id),
    FOREIGN KEY (rol_empresa_id) REFERENCES rol_empresa(id)
);

CREATE TABLE tipo_contrato (
    id                   INT PRIMARY KEY AUTO_INCREMENT,
    nombre               VARCHAR(100),
    descripcion          TEXT,
    renglon_presupuestario VARCHAR(50)
);

-- ========================
-- MÓDULO INSTITUCIÓN
-- ========================

CREATE TABLE Tipo_Institucion (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Nivel_Institucion (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Institucion (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    municipio_id        INT NOT NULL,
    tipo_institucion_id INT NOT NULL,
    nivel_institucion_id INT NOT NULL,
    nombre              VARCHAR(200) NOT NULL,
    siglas              VARCHAR(30),
    direccion           VARCHAR(255),
    telefono            VARCHAR(30),
    fecha_creacion      DATE,
    FOREIGN KEY (municipio_id)         REFERENCES municipio(id),
    FOREIGN KEY (tipo_institucion_id)  REFERENCES Tipo_Institucion(id),
    FOREIGN KEY (nivel_institucion_id) REFERENCES Nivel_Institucion(id)
);

CREATE TABLE Cargo (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    institucion_id INT NOT NULL,
    cargo_jefe_id  INT, 
    nombre         VARCHAR(150),
    descripcion    TEXT,
    fecha_creacion DATE,
    FOREIGN KEY (institucion_id) REFERENCES Institucion(id),
    FOREIGN KEY (cargo_jefe_id)  REFERENCES Cargo(id)
);

CREATE TABLE Contrato (
    id               INT PRIMARY KEY AUTO_INCREMENT,
    trabajador_id    INT NOT NULL,
    institucion_id   INT NOT NULL,
    cargo_id         INT NOT NULL,
    tipo_contrato_id INT NOT NULL,
    sueldo_base      DECIMAL(15,2),
    fecha_inicio     DATE,
    fecha_fin        DATE,
    esta_activo      TINYINT(1) DEFAULT 1,
    FOREIGN KEY (trabajador_id)    REFERENCES Trabajador(id),
    FOREIGN KEY (institucion_id)   REFERENCES Institucion(id),
    FOREIGN KEY (cargo_id)         REFERENCES Cargo(id),
    FOREIGN KEY (tipo_contrato_id) REFERENCES tipo_contrato(id)
);

-- ========================
-- MÓDULO DENUNCIA
-- ========================

CREATE TABLE Tipo_Denuncia (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Estado_Denuncia (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Tipo_Evento (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Denuncia (
    id                   INT PRIMARY KEY AUTO_INCREMENT,
    tipo_denuncia_id     INT NOT NULL,
    estado_denuncia_id   INT NOT NULL,
    institucion_id       INT NOT NULL,
    municipio_incidencia_id INT NOT NULL,
    descripcion          TEXT,
    FOREIGN KEY (tipo_denuncia_id)      REFERENCES Tipo_Denuncia(id),
    FOREIGN KEY (estado_denuncia_id)    REFERENCES Estado_Denuncia(id),
    FOREIGN KEY (institucion_id)        REFERENCES Institucion(id),
    FOREIGN KEY (municipio_incidencia_id) REFERENCES municipio(id)
);

CREATE TABLE Registro_Fecha_Denuncia (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    denuncia_id    INT NOT NULL,
    tipo_evento_id INT NOT NULL,
    observaciones  TEXT,
    fecha          DATE,
    FOREIGN KEY (denuncia_id)    REFERENCES Denuncia(id),
    FOREIGN KEY (tipo_evento_id) REFERENCES Tipo_Evento(id)
);