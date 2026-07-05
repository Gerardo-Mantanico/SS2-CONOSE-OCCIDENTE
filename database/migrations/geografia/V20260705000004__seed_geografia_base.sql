-- =============================================================================
-- Geografía — Seed base: Guatemala y sus 22 departamentos
-- =============================================================================

-- -----------------------------------------------------------------------------
-- País: Guatemala  (id = 1)
-- -----------------------------------------------------------------------------
INSERT INTO geografia.pais (id, nombre, iso2, iso3, pcode)
OVERRIDING SYSTEM VALUE
VALUES (1, 'Guatemala', 'GT', 'GTM', 'GT')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 22 Departamentos  (ids 1-22, orden INE)
-- -----------------------------------------------------------------------------
INSERT INTO geografia.departamento (id, pais_id, nombre, pcode)
OVERRIDING SYSTEM VALUE
VALUES
    ( 1, 1, 'Guatemala',       'GT-GU'),
    ( 2, 1, 'El Progreso',     'GT-PR'),
    ( 3, 1, 'Sacatepéquez',    'GT-SA'),
    ( 4, 1, 'Chimaltenango',   'GT-CM'),
    ( 5, 1, 'Escuintla',       'GT-ES'),
    ( 6, 1, 'Santa Rosa',      'GT-SR'),
    ( 7, 1, 'Sololá',          'GT-SO'),
    ( 8, 1, 'Totonicapán',     'GT-TO'),
    ( 9, 1, 'Quetzaltenango',  'GT-QZ'),
    (10, 1, 'Suchitepéquez',   'GT-SU'),
    (11, 1, 'Retalhuleu',      'GT-RE'),
    (12, 1, 'San Marcos',      'GT-SM'),
    (13, 1, 'Huehuetenango',   'GT-HU'),
    (14, 1, 'Quiché',          'GT-QC'),
    (15, 1, 'Baja Verapaz',    'GT-BV'),
    (16, 1, 'Alta Verapaz',    'GT-AV'),
    (17, 1, 'Petén',           'GT-PE'),
    (18, 1, 'Izabal',          'GT-IZ'),
    (19, 1, 'Zacapa',          'GT-ZA'),
    (20, 1, 'Chiquimula',      'GT-CQ'),
    (21, 1, 'Jalapa',          'GT-JA'),
    (22, 1, 'Jutiapa',         'GT-JU')
ON CONFLICT (id) DO NOTHING;
