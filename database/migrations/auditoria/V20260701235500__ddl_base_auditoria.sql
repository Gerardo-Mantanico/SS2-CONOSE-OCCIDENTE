-- Schema: auditoria
-- Auditoría genérica y centralizada de la base.
--
-- Tabla de registro y función trigger genérica para cualquier tabla
-- No hay que escribir código por tabla ni por schema. Las tablas nuevas quedan auditadas sin intervención manual.
-- Los triggers se enganchan automáticamente con auditoria.aplicar_auditoria(),


CREATE SCHEMA IF NOT EXISTS auditoria;
COMMENT ON SCHEMA auditoria IS 'Auditoría genérica y centralizada de la base de datos. Registra automáticamente cambios estructurales y de datos sin requerir código específico por tabla.';

-- Bitácora de registros
-- Guarda el antes/después como JSONB, así no depende de la estructura de las tablas auditadas.
CREATE TABLE auditoria.registro (
    id          BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    esquema     TEXT        NOT NULL,
    tabla       TEXT        NOT NULL,
    operacion   TEXT        NOT NULL,          -- INSERT | UPDATE | DELETE
    pk          TEXT,                          -- valor de la columna 'id' si existe
    datos_old   JSONB,                         -- fila previa (UPDATE/DELETE)
    datos_new   JSONB,                         -- fila nueva (INSERT/UPDATE)
    usuario_bd  TEXT        NOT NULL DEFAULT current_user,   -- rol de PostgreSQL
    app_usuario TEXT,                          -- colaborador/ETL (GUC 'audit.app_usuario')
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria.registro IS 'Bitácora central de auditoría. Guarda el estado previo y posterior de las filas modificadas en formato JSONB para independizarse de la estructura de cada tabla.';
COMMENT ON COLUMN auditoria.registro.id IS 'Identificador único autogenerado del registro de auditoría.';
COMMENT ON COLUMN auditoria.registro.esquema IS 'Nombre del esquema de la base de datos donde ocurrió la modificación.';
COMMENT ON COLUMN auditoria.registro.tabla IS 'Nombre de la tabla donde ocurrió la modificación.';
COMMENT ON COLUMN auditoria.registro.operacion IS 'Tipo de operación DML realizada (INSERT, UPDATE o DELETE).';
COMMENT ON COLUMN auditoria.registro.pk IS 'Valor de la columna "id" de la fila afectada (si la tabla auditada cuenta con una).';
COMMENT ON COLUMN auditoria.registro.datos_old IS 'Estado previo de la fila en formato JSONB (se llena en operaciones UPDATE y DELETE).';
COMMENT ON COLUMN auditoria.registro.datos_new IS 'Nuevo estado de la fila en formato JSONB (se llena en operaciones INSERT y UPDATE).';
COMMENT ON COLUMN auditoria.registro.usuario_bd IS 'Rol o usuario nativo de PostgreSQL que ejecutó la operación en la base de datos.';
COMMENT ON COLUMN auditoria.registro.app_usuario IS 'Usuario de la aplicación, colaborador o proceso ETL responsable del cambio (obtenido de la variable GUC "audit.app_usuario").';
COMMENT ON COLUMN auditoria.registro.fecha IS 'Fecha y hora exactas en la que se registró la operación.';



CREATE INDEX ON auditoria.registro (esquema, tabla);
CREATE INDEX ON auditoria.registro (fecha);

-- Función trigger genérica. Usa las variables TG_* para saber qué tabla lo disparó
CREATE OR REPLACE FUNCTION auditoria.fn_auditar()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_old JSONB := NULL;
    v_new JSONB := NULL;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old := to_jsonb(OLD);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
    ELSE  -- INSERT
        v_new := to_jsonb(NEW);
    END IF;

    INSERT INTO auditoria.registro
        (esquema, tabla, operacion, pk, datos_old, datos_new, app_usuario)
    VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        COALESCE(v_new ->> 'id', v_old ->> 'id'),   -- NULL si la tabla no tiene 'id'
        v_old,
        v_new,
        current_setting('audit.app_usuario', true)  -- NULL si no se indica
    );

    RETURN NULL;  -- trigger AFTER: el valor de retorno se ignora
END;
$$;
COMMENT ON FUNCTION auditoria.fn_auditar() IS 'Función trigger genérica. Determina el tipo de operación (TG_OP), extrae los registros OLD/NEW según corresponda, los convierte a JSONB e inserta el evento en auditoria.registro.';



-- Engancha el trigger de auditoría a todas las tablas de los schemas indicados que aún no lo tengan.
-- Audita todos los schemas de dominio, excluyendo los de sistema, 'auditoria' (su propio esquema) y 'meta' (trazabilidad de cargas)
-- Para auditar meta u otro subconjunto: SELECT auditoria.aplicar_auditoria(ARRAY['meta']);
CREATE OR REPLACE FUNCTION auditoria.aplicar_auditoria(p_schemas TEXT[] DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_schemas TEXT[];
    r RECORD;
BEGIN
    IF p_schemas IS NULL THEN
        SELECT array_agg(nspname) INTO v_schemas
        FROM pg_namespace
        WHERE nspname NOT IN ('auditoria', 'meta',
                              'pg_catalog', 'information_schema', 'pg_toast')
          AND nspname NOT LIKE 'pg_temp%'
          AND nspname NOT LIKE 'pg_toast_temp%';
    ELSE
        v_schemas := p_schemas;
    END IF;

    IF v_schemas IS NULL THEN
        RETURN;  -- no hay schemas que auditar todavía
    END IF;

    FOR r IN
        SELECT n.nspname AS esquema, c.relname AS tabla
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'                       -- solo tablas ordinarias
          AND n.nspname = ANY(v_schemas)
          AND NOT EXISTS (
              SELECT 1 FROM pg_trigger t
              WHERE t.tgrelid = c.oid
                AND t.tgname  = 'trg_auditoria'
                AND NOT t.tgisinternal
          )
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_auditoria
               AFTER INSERT OR UPDATE OR DELETE ON %I.%I
               FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar()',
            r.esquema, r.tabla
        );
        RAISE NOTICE 'Auditoría aplicada a %.%', r.esquema, r.tabla;
    END LOOP;
END;
$$;
COMMENT ON FUNCTION auditoria.aplicar_auditoria(TEXT[]) IS 'Función utilitaria que asocia automáticamente el trigger "trg_auditoria" a todas las tablas ordinarias de los esquemas indicados. Si no se especifican esquemas, audita todos los esquemas de dominio excluyendo los de sistema, "meta" y "auditoria".';