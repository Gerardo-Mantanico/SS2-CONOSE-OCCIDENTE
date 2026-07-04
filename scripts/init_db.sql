
-- Inicialización de la base de datos
-- Ejecutar UNA SOLA VEZ como superusuario antes de Flyway.
-- Usar el wrapper: bash scripts/init_db.sh

\set ON_ERROR_STOP on

-- Se instalan aquí porque en algunas configuraciones de PostgreSQL solo el superusuario puede crear extensiones.
CREATE EXTENSION IF NOT EXISTS "btree_gist";  -- constraints de exclusión temporal
CREATE EXTENSION IF NOT EXISTS "unaccent";    -- búsqueda sin tildes

\echo ''
\echo 'Extensiones instaladas correctamente.'
\echo ''
