CREATE TABLE pais (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE region (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    pais_id INT NOT NULL,
    nombre  VARCHAR(100) NOT NULL,
    FOREIGN KEY (pais_id) REFERENCES pais(id)
);

CREATE TABLE departamento (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    region_id INT NOT NULL,
    nombre    VARCHAR(100) NOT NULL,
    FOREIGN KEY (region_id) REFERENCES region(id)
);

CREATE TABLE municipio (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    municipio_id   INT,
    nombre         VARCHAR(100) NOT NULL,
    latitud        DECIMAL(10,7),
    longitud       DECIMAL(10,7),
    zona_climatica VARCHAR(50),
    FOREIGN KEY (municipio_id) REFERENCES departamento(id)
);

CREATE TABLE fuente_clima (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE registro_climatico (
    id               INT PRIMARY KEY AUTO_INCREMENT,
    fuente_clima_id  INT NOT NULL,
    municipio_id     INT NOT NULL,
    fecha            DATE,
    hora             TIME,
    velocidad_viento DECIMAL(8,2),
    humedad_relativa DECIMAL(5,2),
    precipitacion    DECIMAL(8,2),
    FOREIGN KEY (fuente_clima_id) REFERENCES fuente_clima(id),
    FOREIGN KEY (municipio_id)    REFERENCES municipio(id)
);

CREATE TABLE estado_civil (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE sexo (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL
);

CREATE TABLE grupo_etnico (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE persona (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    estado_civil_id INT NOT NULL,
    sexo_id         INT NOT NULL,
    grupo_etnico_id INT NOT NULL,
    dpi             VARCHAR(20),
    nit             VARCHAR(20),
    nombres         VARCHAR(150) NOT NULL,
    apellidos       VARCHAR(150) NOT NULL,
    correo          VARCHAR(150),
    telefono        VARCHAR(20),
    fecha_nacimiento DATE,
    FOREIGN KEY (estado_civil_id) REFERENCES estado_civil(id),
    FOREIGN KEY (sexo_id)         REFERENCES sexo(id),
    FOREIGN KEY (grupo_etnico_id) REFERENCES grupo_etnico(id)
);

CREATE TABLE rol (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE cuenta (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    persona_id     INT NOT NULL,
    rol_id         INT NOT NULL,
    nombre_usuario VARCHAR(100) NOT NULL UNIQUE,
    contrasena     VARCHAR(255) NOT NULL,
    esta_activo    TINYINT(1) DEFAULT 1,
    FOREIGN KEY (persona_id) REFERENCES persona(id),
    FOREIGN KEY (rol_id)     REFERENCES rol(id)
);