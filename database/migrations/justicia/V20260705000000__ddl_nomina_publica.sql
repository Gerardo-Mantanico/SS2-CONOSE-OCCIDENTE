-- =============================================================================
-- Módulo Justicia — Nómina pública de trabajadores (OJ y CR)
-- Tablas que consolidan datos de nómina publicados por el Organismo Judicial
-- y el Congreso de la República bajo transparencia activa (LAIP).
-- Autor: Módulo Justicia
-- Fuente: OJ Enero 2023 / CR Enero-Febrero 2025
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CATÁLOGO: justicia.renglon_presupuestario
-- Clasifica el tipo de contratación según el renglón del presupuesto del estado.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.renglon_presupuestario (
    id          INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo      VARCHAR(10)  NOT NULL UNIQUE,
    nombre      VARCHAR(200) NOT NULL,
    descripcion TEXT
);

COMMENT ON TABLE  justicia.renglon_presupuestario             IS 'Catálogo de renglones presupuestarios que clasifican el tipo de contratación de servidores públicos en Guatemala.';
COMMENT ON COLUMN justicia.renglon_presupuestario.codigo      IS 'Código numérico del renglón presupuestario (ej. 011, 022, 029).';
COMMENT ON COLUMN justicia.renglon_presupuestario.nombre      IS 'Nombre oficial del renglón presupuestario según el presupuesto general del estado.';
COMMENT ON COLUMN justicia.renglon_presupuestario.descripcion IS 'Descripción del tipo de contratación que corresponde al renglón.';

-- -----------------------------------------------------------------------------
-- TABLA: justicia.nomina_publica
-- Consolida registros de nómina publicados bajo la LAIP por instituciones
-- del sector justicia. Un registro = un trabajador en un período de reporte.
-- -----------------------------------------------------------------------------
CREATE TABLE justicia.nomina_publica (
    id                  INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Institución de origen
    sigla_institucion   VARCHAR(10)  NOT NULL,        -- 'OJ', 'CR'

    -- Período del reporte
    anio                SMALLINT     NOT NULL,
    mes                 SMALLINT     CHECK (mes BETWEEN 1 AND 12),

    -- Identificación del empleado
    nip                 VARCHAR(20),                  -- Número interno de empleado (OJ)
    nombre              VARCHAR(300) NOT NULL,

    -- Puesto y tipo de contrato
    puesto              VARCHAR(300),
    unidad              VARCHAR(300),                 -- Unidad orgánica o bloque legislativo
    renglon_id          INT          REFERENCES justicia.renglon_presupuestario(id),

    -- Remuneración (en quetzales)
    salario             NUMERIC(12,2),                -- Salario base o monto principal
    total_devengado     NUMERIC(12,2),                -- Total con bonificaciones (OJ); NULL si no aplica

    -- Trazabilidad
    fuente              VARCHAR(200),
    archivo_origen      VARCHAR(200),
    fecha_carga         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  justicia.nomina_publica                     IS 'Nómina de trabajadores de instituciones del sector justicia publicada bajo transparencia activa (LAIP). Fuentes: OJ y Congreso de la República.';
COMMENT ON COLUMN justicia.nomina_publica.sigla_institucion   IS 'Sigla de la institución de origen: OJ = Organismo Judicial, CR = Congreso de la República.';
COMMENT ON COLUMN justicia.nomina_publica.anio                IS 'Año del período de nómina reportado.';
COMMENT ON COLUMN justicia.nomina_publica.mes                 IS 'Mes del período de nómina reportado (1-12). NULL si el dato es de período anual o no especificado.';
COMMENT ON COLUMN justicia.nomina_publica.nip                 IS 'Número de Identificación Personal del empleado según el sistema de la institución. Aplica para OJ.';
COMMENT ON COLUMN justicia.nomina_publica.nombre              IS 'Nombre completo del trabajador tal como aparece en la fuente de datos.';
COMMENT ON COLUMN justicia.nomina_publica.puesto              IS 'Puesto o cargo desempeñado por el trabajador dentro de la institución.';
COMMENT ON COLUMN justicia.nomina_publica.unidad              IS 'Unidad administrativa, dependencia o bloque legislativo al que está asignado el trabajador.';
COMMENT ON COLUMN justicia.nomina_publica.renglon_id          IS 'Renglón presupuestario bajo el que fue contratado el trabajador (011, 022 ó 029).';
COMMENT ON COLUMN justicia.nomina_publica.salario             IS 'Salario base o monto principal de remuneración en quetzales. Para CR renglón 029 corresponde a honorarios.';
COMMENT ON COLUMN justicia.nomina_publica.total_devengado     IS 'Total devengado incluyendo bonificaciones (OJ). NULL cuando la fuente no desglosa ese total.';
COMMENT ON COLUMN justicia.nomina_publica.fuente              IS 'Institución y referencia de la fuente de datos utilizada.';
COMMENT ON COLUMN justicia.nomina_publica.archivo_origen      IS 'Nombre del archivo CSV del que proviene el registro.';
