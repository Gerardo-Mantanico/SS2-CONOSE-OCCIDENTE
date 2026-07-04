-- Se ejecuta automáticamente después de cada 'flyway migrate'.
-- Engancha el trigger de auditoría a las tablas nuevas que aún no lo tengan.
-- si no hay tablas nuevas, no hace nada.

SELECT auditoria.aplicar_auditoria();
