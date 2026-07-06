-- ============================================================
-- Repeatable migration: refrescar datamarts BI de turismo
-- Se puede ejecutar nuevamente cuando cambien datos catalogados o staging.
-- ============================================================

SELECT turismo.fn_refrescar_bi_turismo();

REFRESH MATERIALIZED VIEW turismo.mart_resumen_region;
REFRESH MATERIALIZED VIEW turismo.mart_destinos_recomendados_bi;
REFRESH MATERIALIZED VIEW turismo.mart_patrimonio_turistico;
