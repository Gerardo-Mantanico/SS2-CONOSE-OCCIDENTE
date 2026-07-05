-- Schema: meta
-- Vista de diccionario de datos.
--
-- Lee la estructura y los comentarios (COMMENT ON TABLE/COLUMN) directamente del
-- catálogo de PostgreSQL, por lo que SIEMPRE está sincronizada con el esquema real
-- Es la "meta-tabla" para explorar qué hay en la base.
-- La documentación docs/diccionario.md se genera a partir del contenido de esta vista.
--
-- Incluye todas las tablas de usuario (excluye catálogos del sistema y la tabla
-- de historial de Flyway). Una fila por columna.

CREATE OR REPLACE VIEW meta.diccionario AS
SELECT
    n.nspname                            AS esquema,
    c.relname                            AS tabla,
    obj_description(c.oid, 'pg_class')   AS comentario_tabla,
    a.attnum                             AS posicion,
    a.attname                            AS columna,
    format_type(a.atttypid, a.atttypmod) AS tipo,
    NOT a.attnotnull                     AS nullable,
    CASE
        WHEN a.attidentity IN ('a', 'd') THEN 'IDENTITY'
        ELSE pg_get_expr(ad.adbin, ad.adrelid)
    END                                  AS por_defecto,
    EXISTS (
        SELECT 1 FROM pg_constraint pk
        WHERE pk.conrelid = c.oid
          AND pk.contype = 'p'
          AND a.attnum = ANY (pk.conkey)
    )                                    AS es_pk,
    (
        SELECT format('%s.%s(%s)', rn.nspname, rc.relname,
                   (SELECT string_agg(ra.attname, ', ' ORDER BY k.ord)
                      FROM unnest(fk.confkey) WITH ORDINALITY AS k(attnum, ord)
                      JOIN pg_attribute ra
                        ON ra.attrelid = fk.confrelid AND ra.attnum = k.attnum))
        FROM pg_constraint fk
        JOIN pg_class     rc ON rc.oid = fk.confrelid
        JOIN pg_namespace rn ON rn.oid = rc.relnamespace
        WHERE fk.conrelid = c.oid
          AND fk.contype = 'f'
          AND a.attnum = ANY (fk.conkey)
        LIMIT 1
    )                                    AS fk_referencia,
    col_description(c.oid, a.attnum)     AS comentario
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum
WHERE c.relkind IN ('r', 'p')                                   -- tablas (incl. particionadas)
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
  AND c.relname <> 'flyway_schema_history'
ORDER BY n.nspname, c.relname, a.attnum;

COMMENT ON VIEW meta.diccionario IS 'Diccionario de datos derivado del catálogo interno de PostgreSQL. Muestra la estructura (esquemas, tablas, columnas) y los comentarios asociados, excluyendo tablas de sistema y migraciones.';
COMMENT ON COLUMN meta.diccionario.esquema IS 'Nombre del esquema de la base de datos al que pertenece la tabla.';
COMMENT ON COLUMN meta.diccionario.tabla IS 'Nombre de la tabla física o tabla particionada.';
COMMENT ON COLUMN meta.diccionario.comentario_tabla IS 'Descripción de la tabla, obtenida del comando COMMENT ON TABLE.';
COMMENT ON COLUMN meta.diccionario.posicion IS 'Número de orden secuencial de la columna dentro de la tabla (attnum).';
COMMENT ON COLUMN meta.diccionario.columna IS 'Nombre de la columna.';
COMMENT ON COLUMN meta.diccionario.tipo IS 'Tipo de dato completo de la columna, incluyendo longitud o precisión (ej: VARCHAR(50), NUMERIC(10,2)).';
COMMENT ON COLUMN meta.diccionario.nullable IS 'Indicador booleano que señala si la columna permite valores nulos (TRUE) o si tiene restricción NOT NULL (FALSE).';
COMMENT ON COLUMN meta.diccionario.por_defecto IS 'Valor por defecto asignado a la columna. Muestra "IDENTITY" si es autogenerada, o la expresión literal del default.';
COMMENT ON COLUMN meta.diccionario.es_pk IS 'Indicador booleano que señala si esta columna forma parte de la Llave Primaria (Primary Key) de la tabla.';
COMMENT ON COLUMN meta.diccionario.fk_referencia IS 'Información de la Llave Foránea (Foreign Key) si la columna referencia a otra tabla. Formato: "esquema.tabla(columna)".';
COMMENT ON COLUMN meta.diccionario.comentario IS 'Descripción específica de la columna, obtenida del comando COMMENT ON COLUMN.';