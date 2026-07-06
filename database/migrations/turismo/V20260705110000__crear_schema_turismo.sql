-- ============================================================
-- Proyecto: SS2-CONOSE-OCCIDENTE
-- Modulo: Turismo / Conocer Guatemala
-- Migracion: crear esquema y modelo OLTP/ODS del area turismo
-- Motor: PostgreSQL
-- Convenciones aplicadas:
--   - Todos los objetos se califican con esquema.objeto.
--   - Tablas de dominio incluyen carga_id INT REFERENCES meta.carga(id).
--   - Tablas y columnas se documentan con COMMENT ON.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS turismo;

COMMENT ON SCHEMA turismo IS 'Esquema del area Turismo para el proyecto CONOSE Occidente / Conocer Guatemala. Consume la geografia oficial desde el esquema geografia.';

-- ============================================================
-- Tipos de datos propios del dominio turismo
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_destino'
    ) THEN
        CREATE TYPE turismo.tipo_destino AS ENUM (
            'NATURAL',
            'CULTURAL',
            'ARQUEOLOGICO',
            'URBANO',
            'RELIGIOSO',
            'RECREATIVO',
            'MIXTO'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'dificultad_destino'
    ) THEN
        CREATE TYPE turismo.dificultad_destino AS ENUM (
            'BAJA',
            'MEDIA',
            'ALTA',
            'VARIABLE'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_patrimonio'
    ) THEN
        CREATE TYPE turismo.tipo_patrimonio AS ENUM (
            'UNESCO_CULTURAL',
            'UNESCO_NATURAL',
            'UNESCO_MIXTO',
            'UNESCO_INTANGIBLE',
            'NACIONAL'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_recomendacion'
    ) THEN
        CREATE TYPE turismo.tipo_recomendacion AS ENUM (
            'SEGURIDAD',
            'AMBIENTAL',
            'CULTURAL',
            'LOGISTICA',
            'TEMPORADA'
        );
    END IF;
END $$;

COMMENT ON TYPE turismo.tipo_destino IS 'Clasificacion general del destino turistico: natural, cultural, arqueologico, urbano, religioso, recreativo o mixto.';
COMMENT ON TYPE turismo.dificultad_destino IS 'Nivel de dificultad esperado para visitar el destino turistico.';
COMMENT ON TYPE turismo.tipo_patrimonio IS 'Tipo de reconocimiento patrimonial asociado al destino o expresion cultural.';
COMMENT ON TYPE turismo.tipo_recomendacion IS 'Tipo de recomendacion asociada a un destino turistico.';

-- ============================================================
-- Funciones helper para resolver llaves de geografia por nombre
-- Evitan guardar departamentos/municipios duplicados en turismo.
-- ============================================================
CREATE OR REPLACE FUNCTION turismo.fn_normalizar_texto(p_texto TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT lower(
        translate(
            coalesce(p_texto, ''),
            'ÁÉÍÓÚÜÑáéíóúüñ',
            'AEIOUUNaeiouun'
        )
    );
$$;

COMMENT ON FUNCTION turismo.fn_normalizar_texto(TEXT) IS 'Normaliza texto a minusculas y sin tildes para comparar nombres de geografia y turismo sin depender de extensiones externas.';

CREATE OR REPLACE FUNCTION turismo.fn_departamento_id(p_nombre_departamento TEXT)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_id INT;
BEGIN
    SELECT d.id
      INTO v_id
      FROM geografia.departamento d
     WHERE turismo.fn_normalizar_texto(d.nombre) = turismo.fn_normalizar_texto(p_nombre_departamento)
     LIMIT 1;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro el departamento % en geografia.departamento', p_nombre_departamento;
    END IF;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION turismo.fn_departamento_id(TEXT) IS 'Devuelve el identificador de geografia.departamento a partir del nombre del departamento.';

CREATE OR REPLACE FUNCTION turismo.fn_municipio_id(
    p_nombre_departamento TEXT,
    p_nombre_municipio TEXT,
    p_obligatorio BOOLEAN DEFAULT FALSE
)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_nombre_municipio IS NULL OR btrim(p_nombre_municipio) = '' THEN
        RETURN NULL;
    END IF;

    SELECT m.id
      INTO v_id
      FROM geografia.municipio m
      JOIN geografia.departamento d ON d.id = m.departamento_id
     WHERE turismo.fn_normalizar_texto(d.nombre) = turismo.fn_normalizar_texto(p_nombre_departamento)
       AND turismo.fn_normalizar_texto(m.nombre) = turismo.fn_normalizar_texto(p_nombre_municipio)
     LIMIT 1;

    IF v_id IS NULL AND p_obligatorio THEN
        RAISE EXCEPTION 'No se encontro el municipio % en el departamento % dentro de geografia.municipio', p_nombre_municipio, p_nombre_departamento;
    END IF;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION turismo.fn_municipio_id(TEXT, TEXT, BOOLEAN) IS 'Devuelve el identificador de geografia.municipio a partir del departamento y municipio; opcionalmente falla si no existe.';

-- ============================================================
-- Fuentes documentales del dominio turismo
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.fuente_turistica (
    id_fuente        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo           VARCHAR(80)  NOT NULL UNIQUE,
    nombre           VARCHAR(220) NOT NULL,
    institucion      VARCHAR(180),
    tipo             VARCHAR(80)  NOT NULL,
    url              VARCHAR(700) NOT NULL,
    fecha_consulta   DATE NOT NULL,
    descripcion      TEXT,
    carga_id         INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.fuente_turistica IS 'Fuentes documentales utilizadas para sustentar los datos reales del area de turismo.';
COMMENT ON COLUMN turismo.fuente_turistica.id_fuente IS 'Identificador unico de la fuente turistica dentro del esquema turismo.';
COMMENT ON COLUMN turismo.fuente_turistica.codigo IS 'Codigo estable de la fuente para usar en migraciones, ETL y trazabilidad.';
COMMENT ON COLUMN turismo.fuente_turistica.nombre IS 'Nombre oficial o descriptivo de la fuente consultada.';
COMMENT ON COLUMN turismo.fuente_turistica.institucion IS 'Institucion, organismo o portal responsable de la fuente.';
COMMENT ON COLUMN turismo.fuente_turistica.tipo IS 'Tipo de fuente: oficial, internacional, cultural, conservacion, turismo u otro.';
COMMENT ON COLUMN turismo.fuente_turistica.url IS 'URL principal consultada.';
COMMENT ON COLUMN turismo.fuente_turistica.fecha_consulta IS 'Fecha de consulta de la fuente.';
COMMENT ON COLUMN turismo.fuente_turistica.descripcion IS 'Descripcion del uso de la fuente dentro del modelo turismo.';
COMMENT ON COLUMN turismo.fuente_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

-- ============================================================
-- Regiones turisticas y su relacion con geografia.departamento
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.region_turistica (
    id_region      INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo         VARCHAR(50)  NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL UNIQUE,
    descripcion    TEXT,
    fuente_id      INT REFERENCES turismo.fuente_turistica(id_fuente),
    carga_id       INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.region_turistica IS 'Regiones turisticas de Guatemala utilizadas para agrupar atractivos y destinos.';
COMMENT ON COLUMN turismo.region_turistica.id_region IS 'Identificador unico de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.codigo IS 'Codigo estable de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.nombre IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.descripcion IS 'Descripcion general de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.fuente_id IS 'Fuente documental principal que respalda la definicion de la region.';
COMMENT ON COLUMN turismo.region_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.departamento_region_turistica (
    id_departamento_region INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    region_turistica_id    INT NOT NULL REFERENCES turismo.region_turistica(id_region),
    departamento_id        INT NOT NULL REFERENCES geografia.departamento(id),
    observacion            VARCHAR(400),
    carga_id               INT REFERENCES meta.carga(id),
    CONSTRAINT uq_turismo_departamento_region UNIQUE (region_turistica_id, departamento_id)
);

COMMENT ON TABLE turismo.departamento_region_turistica IS 'Tabla puente entre regiones turisticas del esquema turismo y departamentos oficiales del esquema geografia.';
COMMENT ON COLUMN turismo.departamento_region_turistica.id_departamento_region IS 'Identificador unico de la relacion departamento-region turistica.';
COMMENT ON COLUMN turismo.departamento_region_turistica.region_turistica_id IS 'Region turistica a la que se asocia el departamento.';
COMMENT ON COLUMN turismo.departamento_region_turistica.departamento_id IS 'Departamento oficial registrado en geografia.departamento.';
COMMENT ON COLUMN turismo.departamento_region_turistica.observacion IS 'Nota para casos donde un departamento participa parcialmente en mas de una region turistica.';
COMMENT ON COLUMN turismo.departamento_region_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE INDEX IF NOT EXISTS ix_depto_region_region ON turismo.departamento_region_turistica(region_turistica_id);
CREATE INDEX IF NOT EXISTS ix_depto_region_depto ON turismo.departamento_region_turistica(departamento_id);

-- ============================================================
-- Catalogos de clasificacion turistica
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.categoria_destino (
    id_categoria INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(120) NOT NULL UNIQUE,
    descripcion  TEXT,
    carga_id     INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.categoria_destino IS 'Categorias tematicas utilizadas para clasificar destinos turisticos.';
COMMENT ON COLUMN turismo.categoria_destino.id_categoria IS 'Identificador unico de la categoria turistica.';
COMMENT ON COLUMN turismo.categoria_destino.codigo IS 'Codigo estable de la categoria.';
COMMENT ON COLUMN turismo.categoria_destino.nombre IS 'Nombre de la categoria.';
COMMENT ON COLUMN turismo.categoria_destino.descripcion IS 'Descripcion de la categoria y criterio de uso.';
COMMENT ON COLUMN turismo.categoria_destino.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.actividad_turistica (
    id_actividad INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(140) NOT NULL UNIQUE,
    descripcion  TEXT,
    carga_id     INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.actividad_turistica IS 'Actividades turisticas que pueden realizarse o recomendarse en los destinos.';
COMMENT ON COLUMN turismo.actividad_turistica.id_actividad IS 'Identificador unico de la actividad turistica.';
COMMENT ON COLUMN turismo.actividad_turistica.codigo IS 'Codigo estable de la actividad.';
COMMENT ON COLUMN turismo.actividad_turistica.nombre IS 'Nombre de la actividad turistica.';
COMMENT ON COLUMN turismo.actividad_turistica.descripcion IS 'Descripcion de la actividad y su uso analitico.';
COMMENT ON COLUMN turismo.actividad_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.temporada_turistica (
    id_temporada INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(120) NOT NULL UNIQUE,
    meses        VARCHAR(120) NOT NULL,
    descripcion  TEXT,
    carga_id     INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.temporada_turistica IS 'Temporadas o periodos utiles para planificacion turistica.';
COMMENT ON COLUMN turismo.temporada_turistica.id_temporada IS 'Identificador unico de la temporada turistica.';
COMMENT ON COLUMN turismo.temporada_turistica.codigo IS 'Codigo estable de la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.nombre IS 'Nombre de la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.meses IS 'Meses o periodo del anio asociado a la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.descripcion IS 'Descripcion de condiciones o recomendaciones generales de la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

-- ============================================================
-- Destinos turisticos
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.destino_turistico (
    id_destino                 INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo                     VARCHAR(80)  NOT NULL UNIQUE,
    nombre                     VARCHAR(220) NOT NULL,
    tipo                       turismo.tipo_destino NOT NULL,
    departamento_id            INT NOT NULL REFERENCES geografia.departamento(id),
    municipio_id               INT REFERENCES geografia.municipio(id),
    region_turistica_id        INT REFERENCES turismo.region_turistica(id_region),
    descripcion                TEXT NOT NULL,
    direccion_referencia       VARCHAR(500),
    latitud                    NUMERIC(10, 7),
    longitud                   NUMERIC(10, 7),
    altitud_msnm               INT,
    dificultad                 turismo.dificultad_destino NOT NULL DEFAULT 'BAJA',
    tiempo_recomendado         VARCHAR(120),
    costo_aprox_nacional_q     NUMERIC(10, 2),
    costo_aprox_extranjero_q   NUMERIC(10, 2),
    horario                    VARCHAR(250),
    es_area_protegida          BOOLEAN NOT NULL DEFAULT FALSE,
    fuente_principal_id        INT REFERENCES turismo.fuente_turistica(id_fuente),
    activo                     BOOLEAN NOT NULL DEFAULT TRUE,
    carga_id                   INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.destino_turistico IS 'Destinos turisticos reales de Guatemala documentados para consulta, ETL y analitica BI.';
COMMENT ON COLUMN turismo.destino_turistico.id_destino IS 'Identificador unico del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.codigo IS 'Codigo estable del destino turistico para migraciones y ETL.';
COMMENT ON COLUMN turismo.destino_turistico.nombre IS 'Nombre del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.tipo IS 'Tipo general del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.departamento_id IS 'Departamento oficial donde se ubica el destino, referenciado desde geografia.departamento.';
COMMENT ON COLUMN turismo.destino_turistico.municipio_id IS 'Municipio oficial donde se ubica el destino, referenciado desde geografia.municipio cuando se conoce.';
COMMENT ON COLUMN turismo.destino_turistico.region_turistica_id IS 'Region turistica principal asociada al destino. Se usa para evitar ambiguedad en departamentos que participan parcialmente en mas de una region turistica.';
COMMENT ON COLUMN turismo.destino_turistico.descripcion IS 'Descripcion documentada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.direccion_referencia IS 'Referencia textual de ubicacion, acceso o zona del destino.';
COMMENT ON COLUMN turismo.destino_turistico.latitud IS 'Latitud aproximada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.longitud IS 'Longitud aproximada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.altitud_msnm IS 'Altitud aproximada sobre el nivel del mar, cuando se conoce.';
COMMENT ON COLUMN turismo.destino_turistico.dificultad IS 'Nivel de dificultad general para visitar el destino.';
COMMENT ON COLUMN turismo.destino_turistico.tiempo_recomendado IS 'Tiempo recomendado de visita.';
COMMENT ON COLUMN turismo.destino_turistico.costo_aprox_nacional_q IS 'Costo aproximado para visitante nacional, en quetzales, cuando existe dato publico.';
COMMENT ON COLUMN turismo.destino_turistico.costo_aprox_extranjero_q IS 'Costo aproximado para visitante extranjero, en quetzales, cuando existe dato publico.';
COMMENT ON COLUMN turismo.destino_turistico.horario IS 'Horario de visita o atencion cuando se tiene publicado.';
COMMENT ON COLUMN turismo.destino_turistico.es_area_protegida IS 'Indica si el destino pertenece o se relaciona con un area protegida.';
COMMENT ON COLUMN turismo.destino_turistico.fuente_principal_id IS 'Fuente turistica principal usada para documentar el destino.';
COMMENT ON COLUMN turismo.destino_turistico.activo IS 'Indica si el destino se mantiene activo para consulta.';
COMMENT ON COLUMN turismo.destino_turistico.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE INDEX IF NOT EXISTS ix_destino_departamento ON turismo.destino_turistico(departamento_id);
CREATE INDEX IF NOT EXISTS ix_destino_municipio ON turismo.destino_turistico(municipio_id);
CREATE INDEX IF NOT EXISTS ix_destino_region ON turismo.destino_turistico(region_turistica_id);
CREATE INDEX IF NOT EXISTS ix_destino_tipo ON turismo.destino_turistico(tipo);
CREATE INDEX IF NOT EXISTS ix_destino_area_protegida ON turismo.destino_turistico(es_area_protegida);

CREATE TABLE IF NOT EXISTS turismo.destino_categoria (
    destino_id   INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    categoria_id INT NOT NULL REFERENCES turismo.categoria_destino(id_categoria),
    carga_id     INT REFERENCES meta.carga(id),
    PRIMARY KEY (destino_id, categoria_id)
);

COMMENT ON TABLE turismo.destino_categoria IS 'Relacion muchos a muchos entre destinos turisticos y categorias.';
COMMENT ON COLUMN turismo.destino_categoria.destino_id IS 'Destino turistico clasificado.';
COMMENT ON COLUMN turismo.destino_categoria.categoria_id IS 'Categoria asignada al destino.';
COMMENT ON COLUMN turismo.destino_categoria.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.destino_actividad (
    destino_id    INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    actividad_id  INT NOT NULL REFERENCES turismo.actividad_turistica(id_actividad),
    notas         VARCHAR(500),
    carga_id      INT REFERENCES meta.carga(id),
    PRIMARY KEY (destino_id, actividad_id)
);

COMMENT ON TABLE turismo.destino_actividad IS 'Relacion muchos a muchos entre destinos y actividades turisticas.';
COMMENT ON COLUMN turismo.destino_actividad.destino_id IS 'Destino turistico asociado a la actividad.';
COMMENT ON COLUMN turismo.destino_actividad.actividad_id IS 'Actividad turistica disponible o recomendada.';
COMMENT ON COLUMN turismo.destino_actividad.notas IS 'Notas sobre alcance o condiciones de la actividad en el destino.';
COMMENT ON COLUMN turismo.destino_actividad.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.destino_temporada (
    destino_id      INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    temporada_id    INT NOT NULL REFERENCES turismo.temporada_turistica(id_temporada),
    recomendacion   VARCHAR(600),
    carga_id        INT REFERENCES meta.carga(id),
    PRIMARY KEY (destino_id, temporada_id)
);

COMMENT ON TABLE turismo.destino_temporada IS 'Relacion entre destinos y temporadas recomendadas para visita.';
COMMENT ON COLUMN turismo.destino_temporada.destino_id IS 'Destino turistico asociado a la temporada.';
COMMENT ON COLUMN turismo.destino_temporada.temporada_id IS 'Temporada recomendada o relevante.';
COMMENT ON COLUMN turismo.destino_temporada.recomendacion IS 'Recomendacion especifica para visitar el destino en la temporada indicada.';
COMMENT ON COLUMN turismo.destino_temporada.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.destino_fuente (
    destino_id INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    fuente_id  INT NOT NULL REFERENCES turismo.fuente_turistica(id_fuente),
    detalle    VARCHAR(600),
    carga_id   INT REFERENCES meta.carga(id),
    PRIMARY KEY (destino_id, fuente_id)
);

COMMENT ON TABLE turismo.destino_fuente IS 'Fuentes documentales que respaldan la informacion de cada destino turistico.';
COMMENT ON COLUMN turismo.destino_fuente.destino_id IS 'Destino turistico documentado.';
COMMENT ON COLUMN turismo.destino_fuente.fuente_id IS 'Fuente turistica relacionada con el destino.';
COMMENT ON COLUMN turismo.destino_fuente.detalle IS 'Detalle sobre el uso de la fuente para el destino.';
COMMENT ON COLUMN turismo.destino_fuente.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

-- ============================================================
-- Patrimonio, rutas y recomendaciones
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.patrimonio_turistico (
    id_patrimonio     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo            VARCHAR(80)  NOT NULL UNIQUE,
    tipo              turismo.tipo_patrimonio NOT NULL,
    nombre            VARCHAR(220) NOT NULL,
    organismo         VARCHAR(160) NOT NULL,
    anio_inscripcion  INT,
    descripcion       TEXT,
    fuente_id         INT REFERENCES turismo.fuente_turistica(id_fuente),
    carga_id          INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.patrimonio_turistico IS 'Patrimonios UNESCO, nacionales o intangibles vinculados con el turismo en Guatemala.';
COMMENT ON COLUMN turismo.patrimonio_turistico.id_patrimonio IS 'Identificador unico del patrimonio turistico.';
COMMENT ON COLUMN turismo.patrimonio_turistico.codigo IS 'Codigo estable del patrimonio.';
COMMENT ON COLUMN turismo.patrimonio_turistico.tipo IS 'Tipo de reconocimiento patrimonial.';
COMMENT ON COLUMN turismo.patrimonio_turistico.nombre IS 'Nombre del patrimonio o expresion cultural.';
COMMENT ON COLUMN turismo.patrimonio_turistico.organismo IS 'Organismo que reconoce o respalda el patrimonio.';
COMMENT ON COLUMN turismo.patrimonio_turistico.anio_inscripcion IS 'Anio de inscripcion o reconocimiento, cuando aplica.';
COMMENT ON COLUMN turismo.patrimonio_turistico.descripcion IS 'Descripcion resumida del valor patrimonial.';
COMMENT ON COLUMN turismo.patrimonio_turistico.fuente_id IS 'Fuente principal que respalda el patrimonio.';
COMMENT ON COLUMN turismo.patrimonio_turistico.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.destino_patrimonio (
    destino_id     INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    patrimonio_id  INT NOT NULL REFERENCES turismo.patrimonio_turistico(id_patrimonio),
    observacion    VARCHAR(600),
    carga_id       INT REFERENCES meta.carga(id),
    PRIMARY KEY (destino_id, patrimonio_id)
);

COMMENT ON TABLE turismo.destino_patrimonio IS 'Relacion entre destinos turisticos y reconocimientos patrimoniales.';
COMMENT ON COLUMN turismo.destino_patrimonio.destino_id IS 'Destino turistico asociado al patrimonio.';
COMMENT ON COLUMN turismo.destino_patrimonio.patrimonio_id IS 'Patrimonio asociado al destino.';
COMMENT ON COLUMN turismo.destino_patrimonio.observacion IS 'Observacion de la relacion entre destino y patrimonio.';
COMMENT ON COLUMN turismo.destino_patrimonio.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.ruta_turistica (
    id_ruta       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo        VARCHAR(80)  NOT NULL UNIQUE,
    nombre        VARCHAR(180) NOT NULL,
    region_id     INT REFERENCES turismo.region_turistica(id_region),
    descripcion   TEXT,
    duracion_dias INT,
    fuente_id     INT REFERENCES turismo.fuente_turistica(id_fuente),
    carga_id      INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.ruta_turistica IS 'Rutas turisticas sugeridas para recorrer destinos relacionados.';
COMMENT ON COLUMN turismo.ruta_turistica.id_ruta IS 'Identificador unico de la ruta turistica.';
COMMENT ON COLUMN turismo.ruta_turistica.codigo IS 'Codigo estable de la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.nombre IS 'Nombre de la ruta turistica.';
COMMENT ON COLUMN turismo.ruta_turistica.region_id IS 'Region turistica principal asociada a la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.descripcion IS 'Descripcion general de la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.duracion_dias IS 'Duracion sugerida de la ruta en dias.';
COMMENT ON COLUMN turismo.ruta_turistica.fuente_id IS 'Fuente principal usada para documentar la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.ruta_destino (
    ruta_id         INT NOT NULL REFERENCES turismo.ruta_turistica(id_ruta) ON DELETE CASCADE,
    destino_id      INT NOT NULL REFERENCES turismo.destino_turistico(id_destino),
    orden_visita    INT NOT NULL,
    tiempo_sugerido VARCHAR(120),
    carga_id        INT REFERENCES meta.carga(id),
    PRIMARY KEY (ruta_id, destino_id),
    CONSTRAINT uq_ruta_orden UNIQUE (ruta_id, orden_visita)
);

COMMENT ON TABLE turismo.ruta_destino IS 'Detalle de destinos incluidos en cada ruta turistica sugerida.';
COMMENT ON COLUMN turismo.ruta_destino.ruta_id IS 'Ruta turistica que contiene el destino.';
COMMENT ON COLUMN turismo.ruta_destino.destino_id IS 'Destino incluido en la ruta.';
COMMENT ON COLUMN turismo.ruta_destino.orden_visita IS 'Orden sugerido de visita dentro de la ruta.';
COMMENT ON COLUMN turismo.ruta_destino.tiempo_sugerido IS 'Tiempo sugerido para visitar el destino dentro de la ruta.';
COMMENT ON COLUMN turismo.ruta_destino.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

CREATE TABLE IF NOT EXISTS turismo.recomendacion_destino (
    id_recomendacion INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    destino_id       INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    tipo             turismo.tipo_recomendacion NOT NULL,
    recomendacion    VARCHAR(800) NOT NULL,
    carga_id         INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE turismo.recomendacion_destino IS 'Recomendaciones turisticas, logisticas, culturales, ambientales, de seguridad o temporada por destino.';
COMMENT ON COLUMN turismo.recomendacion_destino.id_recomendacion IS 'Identificador unico de la recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.destino_id IS 'Destino al que aplica la recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.tipo IS 'Tipo de recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.recomendacion IS 'Texto de la recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.carga_id IS 'Referencia opcional al proceso de carga registrado en meta.carga.';

-- ============================================================
-- Trigger de validacion geografia: municipio debe pertenecer al departamento indicado
-- ============================================================
CREATE OR REPLACE FUNCTION turismo.fn_validar_destino_geografia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_departamento_municipio INT;
BEGIN
    IF NEW.municipio_id IS NOT NULL THEN
        SELECT m.departamento_id
          INTO v_departamento_municipio
          FROM geografia.municipio m
         WHERE m.id = NEW.municipio_id;

        IF v_departamento_municipio IS DISTINCT FROM NEW.departamento_id THEN
            RAISE EXCEPTION 'El municipio_id % no pertenece al departamento_id % para el destino %',
                NEW.municipio_id, NEW.departamento_id, NEW.nombre;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION turismo.fn_validar_destino_geografia() IS 'Valida que el municipio referenciado por un destino pertenezca al departamento indicado.';

DROP TRIGGER IF EXISTS trg_validar_destino_geografia ON turismo.destino_turistico;
CREATE TRIGGER trg_validar_destino_geografia
BEFORE INSERT OR UPDATE OF departamento_id, municipio_id
ON turismo.destino_turistico
FOR EACH ROW
EXECUTE FUNCTION turismo.fn_validar_destino_geografia();
