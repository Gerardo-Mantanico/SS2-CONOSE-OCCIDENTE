-- =============================================================================
-- Modulo Justicia — Datos iniciales de catalogos de seguridad publica
-- Ejecutar despues de V20260704000000__ddl_estadisticas_seguridad.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- justicia.sexo
-- IDs fijos (1-3) para coincidir con SEXO_MAP del ETL.
-- Se usa OVERRIDING SYSTEM VALUE porque la PK es GENERATED ALWAYS AS IDENTITY.
-- -----------------------------------------------------------------------------
INSERT INTO justicia.sexo (id, nombre)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Hombre'),
    (2, 'Mujer'),
    (3, 'No especificado')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- justicia.tipo_delito
-- Los IDs son asignados por la BD; el ETL hace lookup por codigo.
-- -----------------------------------------------------------------------------
INSERT INTO justicia.tipo_delito (codigo, nombre, descripcion, aplica_turistas) VALUES
    ('VEHICULOS',          'Robo de vehiculos',        'Sustraccion de automoviles, camionetas u otros vehiculos de 4 ruedas.',      FALSE),
    ('PEATONES',           'Robo a peatones',           'Asalto y sustraccion de bienes a personas en via publica.',                  TRUE),
    ('ARMA_FUEGO',         'Robo con arma de fuego',    'Sustraccion cometida portando arma de fuego.',                               TRUE),
    ('MOTOCICLETAS',       'Robo de motocicletas',      'Sustraccion de motocicletas y similares.',                                   FALSE),
    ('COMERCIOS',          'Robo a comercios',          'Asalto en establecimientos comerciales abiertos al publico.',                FALSE),
    ('RESIDENCIAS',        'Robo a residencias',        'Ingreso forzado y sustraccion en inmuebles residenciales.',                  FALSE),
    ('BUSES',              'Robo en buses',             'Asalto a pasajeros o conductores de transporte colectivo.',                  TRUE),
    ('TURISTAS',           'Robo a turistas',           'Eventos donde la victima es identificada como turista.',                     TRUE),
    ('IGLESIAS',           'Robo a iglesias',           'Sustraccion en recintos religiosos.',                                        FALSE),
    ('BANCO',              'Robo a bancos',             'Asalto a instituciones bancarias o cajeros automaticos.',                    FALSE),
    ('UNIDADES_BLINDADAS', 'Robo a unidades blindadas', 'Asalto a vehiculos de traslado de valores.',                                FALSE),
    ('OTROS',              'Otros robos',               'Modalidades no clasificadas en las categorias anteriores.',                  FALSE),
    ('TOTAL',              'Total general',             'Suma de todas las modalidades. Usado para registros de resumen.',            FALSE)
ON CONFLICT (codigo) DO NOTHING;

-- -----------------------------------------------------------------------------
-- justicia.grupo_edad_victima
-- Los IDs son asignados por la BD; el ETL hace lookup por codigo.
-- -----------------------------------------------------------------------------
INSERT INTO justicia.grupo_edad_victima (codigo, rango, edad_min, edad_max, orden) VALUES
    ('MENOR_15', 'Menor de 15',  0,    14,    1),
    ('G15_19',   '15-19',        15,   19,    2),
    ('G20_24',   '20-24',        20,   24,    3),
    ('G25_29',   '25-29',        25,   29,    4),
    ('G30_34',   '30-34',        30,   34,    5),
    ('G35_39',   '35-39',        35,   39,    6),
    ('G40_44',   '40-44',        40,   44,    7),
    ('G45_49',   '45-49',        45,   49,    8),
    ('G50_54',   '50-54',        50,   54,    9),
    ('G55_59',   '55-59',        55,   59,   10),
    ('G60_MAS',  '60 y mas',     60,   NULL, 11),
    ('IGNORADO', 'Ignorado',     NULL, NULL, 12)
ON CONFLICT (codigo) DO NOTHING;
