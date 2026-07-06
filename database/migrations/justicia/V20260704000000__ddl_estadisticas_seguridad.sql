-- =============================================================================
-- Modulo Justicia — Estadisticas de Seguridad Publica (INE/PNC)
-- Tablas nuevas que extienden el schema justicia con datos cuantitativos.
-- Autor: Modulo Justicia
-- Fuente: INE / PNC Guatemala — Periodo 2009-2022
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CATALOGO: justicia.sexo
-- Categorias de sexo usadas por el INE para clasificar victimas.
-- Se define aqui porque no existe en otro schema del proyecto.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.sexo (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

COMMENT ON TABLE  justicia.sexo IS 'Categorias de sexo de la victima segun clasificacion INE/PNC.';

-- -----------------------------------------------------------------------------
-- CATALOGO: justicia.tipo_delito
-- Modalidades de robo/hurto segun la clasificacion de la PNC.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.tipo_delito (
    id              INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo          VARCHAR(30)  NOT NULL UNIQUE,
    nombre          VARCHAR(150) NOT NULL,
    descripcion     TEXT,
    aplica_turistas BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  justicia.tipo_delito          IS 'Catalogo de modalidades de robo/hurto segun clasificacion PNC.';
COMMENT ON COLUMN justicia.tipo_delito.aplica_turistas IS 'TRUE si el tipo afecta directamente a turistas (util para Conoce Guate).';

-- -----------------------------------------------------------------------------
-- CATALOGO: justicia.grupo_edad_victima
-- Grupos quinquenales de edad usados por el INE.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.grupo_edad_victima (
    id       INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo   VARCHAR(20) NOT NULL UNIQUE,
    rango    VARCHAR(50) NOT NULL,
    edad_min SMALLINT,
    edad_max SMALLINT,
    orden    SMALLINT    NOT NULL
);

COMMENT ON TABLE justicia.grupo_edad_victima IS 'Grupos quinquenales de edad de la victima segun clasificacion INE/PNC.';

-- -----------------------------------------------------------------------------
-- TABLA CENTRAL: justicia.estadistica_seguridad
-- Un registro = valor anual para una combinacion especifica de dimensiones.
-- Diseño tipo estrella para facilitar consultas de la app Conoce Guate.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.estadistica_seguridad (
    id                  INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    anio                SMALLINT    NOT NULL CHECK (anio BETWEEN 2000 AND 2100),

    -- NULL = total nacional (Republica)
    departamento_id     INT         REFERENCES geografia.departamento(id),
    nombre_departamento VARCHAR(100),

    tipo_delito_id      INT         REFERENCES justicia.tipo_delito(id),
    sexo_id             INT         REFERENCES justicia.sexo(id),
    grupo_edad_id       INT         REFERENCES justicia.grupo_edad_victima(id),

    cantidad            INT         NOT NULL DEFAULT 0,
    fuente              VARCHAR(200),
    archivo_origen      VARCHAR(200),
    fecha_carga         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    cargado_por         VARCHAR(200),
    revisado            BOOLEAN     DEFAULT FALSE,

    -- Clave unica para upsert idempotente (NULLS NOT DISTINCT requiere PG >= 15)
    UNIQUE NULLS NOT DISTINCT (
        anio, departamento_id, tipo_delito_id, sexo_id, grupo_edad_id
    )
);

COMMENT ON TABLE  justicia.estadistica_seguridad IS 'Estadisticas anuales de robos/hurtos desagregadas por departamento, sexo, edad y tipo.';
COMMENT ON COLUMN justicia.estadistica_seguridad.departamento_id IS 'FK a geografia.departamento. NULL indica total nacional (Republica).';
COMMENT ON COLUMN justicia.estadistica_seguridad.revisado        IS 'Indica si el registro paso el filtro de pares (revision de calidad).';
