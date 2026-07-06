-- =============================================================================
-- Módulo Justicia — Datos iniciales: renglones presupuestarios
-- Ejecutar después de V20260705000000__ddl_nomina_publica.sql
-- Fuente: Presupuesto General de Ingresos y Egresos del Estado — Guatemala
-- =============================================================================

INSERT INTO justicia.renglon_presupuestario (codigo, nombre, descripcion) VALUES
    ('011',
     'Personal permanente',
     'Servidores públicos contratados con nombramiento permanente. Gozan de estabilidad laboral y acceso a todas las prestaciones establecidas por la Ley de Servicio Civil.'),
    ('022',
     'Personal por contrato',
     'Servidores contratados por tiempo determinado mediante contrato individual de trabajo. No poseen plaza presupuestada permanente.'),
    ('029',
     'Otras remuneraciones de personal temporal',
     'Contratos de servicios técnicos o profesionales pagados por honorarios. No implican relación de dependencia laboral directa con la institución.')
ON CONFLICT (codigo) DO NOTHING;
