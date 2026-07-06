-- ============================================================
-- Flyway migration: V20260705112700__corregir_funciones_calidad_turismo.sql
-- Motor: PostgreSQL
-- Esquema: turismo
-- ============================================================

CREATE OR REPLACE FUNCTION turismo.sp_etl_validar_calidad(
    p_id_ejecucion BIGINT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total BIGINT;
    v_observaciones BIGINT;
BEGIN
    -- ========================================================
    -- 1. Destinos sin fuente principal
    -- ========================================================
    SELECT COUNT(*)
    INTO v_total
    FROM turismo.destino_turistico;

    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico
    WHERE fuente_principal_id IS NULL;

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_turistico',
        'Destinos turisticos con fuente principal registrada',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Todo destino turistico deberia tener una fuente principal verificable.'
    );

    -- ========================================================
    -- 2. Destinos sin region turistica
    -- ========================================================
    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico
    WHERE region_turistica_id IS NULL;

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_turistico',
        'Destinos turisticos con region turistica asignada',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Todo destino turistico deberia estar asociado a una region turistica principal.'
    );

    -- ========================================================
    -- 3. Destinos con municipio que no pertenece al departamento
    -- ========================================================
    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico d
    JOIN geografia.municipio m
        ON m.id = d.municipio_id
    WHERE d.municipio_id IS NOT NULL
      AND m.departamento_id <> d.departamento_id;

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_turistico',
        'Municipio del destino pertenece al departamento registrado',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ERROR' END,
        v_total,
        v_observaciones,
        'Valida que el municipio asociado al destino pertenezca al mismo departamento registrado.'
    );

    -- ========================================================
    -- 4. Destinos sin categoria
    -- ========================================================
    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico d
    WHERE NOT EXISTS (
        SELECT 1
        FROM turismo.destino_categoria dc
        WHERE dc.destino_id = d.id_destino
    );

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_categoria',
        'Destinos turisticos con al menos una categoria',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Todo destino turistico deberia estar clasificado en al menos una categoria.'
    );

    -- ========================================================
    -- 5. Destinos sin actividad
    -- ========================================================
    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico d
    WHERE NOT EXISTS (
        SELECT 1
        FROM turismo.destino_actividad da
        WHERE da.destino_id = d.id_destino
    );

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_actividad',
        'Destinos turisticos con al menos una actividad',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Todo destino turistico deberia tener al menos una actividad asociada.'
    );

    -- ========================================================
    -- 6. Fuentes sin URL
    -- ========================================================
    SELECT COUNT(*)
    INTO v_total
    FROM turismo.fuente_turistica;

    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.fuente_turistica
    WHERE url IS NULL
       OR trim(url) = '';

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.fuente_turistica',
        'Fuentes turisticas con URL verificable',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Toda fuente turistica deberia tener URL para trazabilidad documental.'
    );

    -- ========================================================
    -- 7. Destinos activos sin relacion en destino_fuente
    -- ========================================================
    SELECT COUNT(*)
    INTO v_total
    FROM turismo.destino_turistico
    WHERE activo = TRUE;

    SELECT COUNT(*)
    INTO v_observaciones
    FROM turismo.destino_turistico d
    WHERE d.activo = TRUE
      AND NOT EXISTS (
          SELECT 1
          FROM turismo.destino_fuente df
          WHERE df.destino_id = d.id_destino
      );

    INSERT INTO turismo.etl_validacion (
        id_ejecucion,
        entidad,
        regla,
        nivel,
        total_registros,
        total_observaciones,
        detalle
    )
    VALUES (
        p_id_ejecucion,
        'turismo.destino_fuente',
        'Destinos activos con trazabilidad de fuentes',
        CASE WHEN v_observaciones = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        v_total,
        v_observaciones,
        'Todo destino activo deberia tener al menos una relacion en destino_fuente.'
    );

END;
$$;

COMMENT ON FUNCTION turismo.sp_etl_validar_calidad(BIGINT)
IS 'Ejecuta validaciones de calidad sobre el modelo turismo usando las tablas reales del esquema.';