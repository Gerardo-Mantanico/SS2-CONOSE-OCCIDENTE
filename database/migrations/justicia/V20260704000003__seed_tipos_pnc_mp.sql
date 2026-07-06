-- =============================================================================
-- Justicia — Tipos de delito adicionales para fuentes PNC y MP
-- Ejecutar despues de V20260704000001__seed_catalogos_seguridad.sql
-- Codigos separados por fuente para evitar conflictos en el UNIQUE constraint
-- de estadistica_seguridad (anio, departamento_id, tipo_delito_id, sexo_id, grupo_edad_id).
-- =============================================================================

INSERT INTO justicia.tipo_delito (codigo, nombre, descripcion, aplica_turistas) VALUES
    -- PNC 2023 / Victimas
    ('VICTIMAS_PATRIMONIO', 'Victimas - Contra el patrimonio (PNC)',
     'Delitos contra el patrimonio registrados por PNC, fuente: Victimas 2023.', TRUE),
    ('VICTIMAS_OTRAS',      'Victimas - Otras causas (PNC)',
     'Otras causas registradas por PNC, fuente: Victimas 2023.',               FALSE),

    -- PNC 2023 / Detenidos
    ('DETENIDOS_PATRIMONIO', 'Detenidos - Contra el patrimonio (PNC)',
     'Delitos contra el patrimonio registrados por PNC, fuente: Detenidos 2023.', FALSE),
    ('DETENIDOS_OTRAS',      'Detenidos - Otras causas (PNC)',
     'Otras causas registradas por PNC, fuente: Detenidos 2023.',                 FALSE),

    -- MP 2023 / Agraviados
    ('AGRAVIADOS_OTRAS', 'Agraviados - Delitos (MP)',
     'Delitos registrados por el MP, fuente: Agraviados 2023.', FALSE),

    -- MP 2023 / Sindicados
    ('SINCIDADOS_OTROS', 'Sindicados - Delitos (MP)',
     'Delitos registrados por el MP, fuente: Sindicados 2023.', FALSE)

ON CONFLICT (codigo) DO NOTHING;
