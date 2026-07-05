-- Migración: agregar_unique_evento_cultural
-- Schema:    cultura
-- Generado:  2026-07-05 15:28:07

-- 1. Eliminar eventos duplicados dejando solo la primera ocurrencia (menor ID)
-- Esto automáticamente limpia la tabla intermedia 'evento_municipio' gracias a ON DELETE CASCADE.
DELETE FROM cultura.evento_cultural a
USING cultura.evento_cultural b
WHERE a.id > b.id AND a.nombre = b.nombre;

-- 2. Agregar restricción UNIQUE al campo nombre
ALTER TABLE cultura.evento_cultural ADD CONSTRAINT evento_cultural_nombre_key UNIQUE (nombre);
COMMENT ON CONSTRAINT evento_cultural_nombre_key ON cultura.evento_cultural IS 'Garantiza que no existan eventos culturales con nombres duplicados.';
