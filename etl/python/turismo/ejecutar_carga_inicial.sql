-- ============================================================
-- Flyway migration: V20260705113000__ejecutar_carga_inicial_bi_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- Convencion del proyecto: todos los objetos van calificados con turismo.<objeto>; no se usa search_path.
-- Objetivo: ejecutar primera carga de dimensiones y hechos BI
-- ============================================================


SELECT turismo.sp_etl_ejecutar_bi_completo();
