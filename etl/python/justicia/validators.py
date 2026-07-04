"""
validators.py — Validaciones de calidad de datos antes de cargar a la BD.
Implementa el control de "filtro de pares" por archivo Excel.
"""
import pandas as pd
from config_justicia import YEAR_MIN, YEAR_MAX


class ValidationResult:
    """Acumula errores y advertencias de un proceso de validacion."""

    def __init__(self, nombre_archivo: str):
        self.nombre = nombre_archivo
        self.errores: list[str] = []
        self.advertencias: list[str] = []
        self.filas_totales = 0
        self.filas_validas = 0

    def error(self, msg: str):
        self.errores.append(msg)

    def warn(self, msg: str):
        self.advertencias.append(msg)

    @property
    def es_valido(self) -> bool:
        return len(self.errores) == 0

    def resumen(self) -> str:
        estado = "VALIDO" if self.es_valido else "INVALIDO"
        lines = [
            f"\n{'='*55}",
            f"  VALIDACION: {self.nombre}  ->  {estado}",
            f"{'='*55}",
            f"  Filas totales  : {self.filas_totales}",
            f"  Filas validas  : {self.filas_validas}",
            f"  Errores        : {len(self.errores)}",
            f"  Advertencias   : {len(self.advertencias)}",
        ]
        if self.errores:
            lines.append("\n  ERRORES (bloquean la carga):")
            for e in self.errores:
                lines.append(f"    x {e}")
        if self.advertencias:
            lines.append("\n  ADVERTENCIAS (no bloquean):")
            for w in self.advertencias:
                lines.append(f"    ! {w}")
        lines.append("=" * 55)
        return "\n".join(lines)


# -- Validaciones comunes -----------------------------------------------------

def validate_years(df: pd.DataFrame, col_año: str, result: ValidationResult):
    invalidos = df[~df[col_año].between(YEAR_MIN, YEAR_MAX)][col_año].tolist()
    if invalidos:
        result.error(f"Años fuera de rango [{YEAR_MIN}-{YEAR_MAX}]: {invalidos}")


def validate_no_negative(df: pd.DataFrame, columnas: list[str], result: ValidationResult):
    for col in columnas:
        if col in df.columns:
            neg = df[df[col] < 0][col].count()
            if neg > 0:
                result.error(f"Columna '{col}' tiene {neg} valores negativos.")


def validate_totals_match(
    df: pd.DataFrame, col_total: str, cols_detalle: list[str],
    result: ValidationResult, tolerancia: int = 5,
):
    cols_presentes = [c for c in cols_detalle if c in df.columns]
    if not cols_presentes:
        return
    suma_detalle = df[cols_presentes].sum(axis=1)
    diferencias  = (df[col_total] - suma_detalle).abs()
    filas_error  = df[diferencias > tolerancia]
    if not filas_error.empty:
        result.error(
            f"Columna '{col_total}' no coincide con suma del detalle en "
            f"{len(filas_error)} filas (tolerancia: +-{tolerancia}). "
            f"Años afectados: {filas_error.iloc[:, 0].tolist()}"
        )


def validate_no_duplicate_years(df: pd.DataFrame, col_año: str, result: ValidationResult):
    dups = df[df[col_año].duplicated()][col_año].tolist()
    if dups:
        result.error(f"Años duplicados en el archivo: {dups}")


def validate_expected_columns(
    df: pd.DataFrame, columnas_esperadas: list[str], result: ValidationResult,
):
    faltantes = [c for c in columnas_esperadas if c not in df.columns]
    extras    = [c for c in df.columns if c not in columnas_esperadas]
    if faltantes:
        result.error(
            f"Columnas faltantes: {faltantes}. "
            "Cambio la estructura del Excel del INE?"
        )
    if extras:
        result.warn(f"Columnas extra (seran ignoradas): {extras}")


def validate_no_all_zeros(df: pd.DataFrame, cols_numericas: list[str], result: ValidationResult):
    for col in cols_numericas:
        if col in df.columns and (df[col] == 0).all():
            result.warn(
                f"Columna '{col}' tiene unicamente ceros. Verificar si es correcto."
            )


# -- Validadores por loader ---------------------------------------------------

def validate_departamento(df: pd.DataFrame, deptos_esperados: list[str]) -> ValidationResult:
    r = ValidationResult("robos_por_departamento.xlsx")
    r.filas_totales = len(df)

    validate_no_duplicate_years(df, "Año", r)
    validate_years(df, "Año", r)
    validate_no_negative(df, [c for c in df.columns if c != "Año"], r)

    deptos_presentes = [c for c in df.columns if c not in ["Año", "República"]]
    faltantes = [d for d in deptos_esperados if d not in deptos_presentes]
    extras    = [d for d in deptos_presentes if d not in deptos_esperados]
    if faltantes:
        r.error(f"Departamentos faltantes en el Excel: {faltantes}")
    if extras:
        r.warn(f"Departamentos extra (no mapeados): {extras}")

    if "República" in df.columns:
        for col in deptos_presentes:
            if col in df.columns:
                mayor = df[df[col] > df["República"]]
                if not mayor.empty:
                    r.error(
                        f"'{col}' supera al total 'República' en años: "
                        f"{mayor['Año'].tolist()}"
                    )

    r.filas_validas = len(df) if r.es_valido else 0
    return r


def validate_sexo(df: pd.DataFrame) -> ValidationResult:
    r = ValidationResult("robos_por_sexo.xlsx")
    r.filas_totales = len(df)

    validate_no_duplicate_years(df, "Año", r)
    validate_years(df, "Año", r)
    validate_expected_columns(df, ["Año", "Total", "Hombre", "Mujer", "Ignorado"], r)
    validate_no_negative(df, ["Total", "Hombre", "Mujer", "Ignorado"], r)
    validate_totals_match(df, "Total", ["Hombre", "Mujer", "Ignorado"], r)

    r.filas_validas = len(df) if r.es_valido else 0
    return r


def validate_edad(df: pd.DataFrame) -> ValidationResult:
    grupos = [
        "Menor de 15", "15-19", "20-24", "25-29", "30-34", "35-39",
        "40-44", "45-49", "50-54", "55-59", "60 y más", "Ignorado",
    ]
    r = ValidationResult("robos_por_edad.xlsx")
    r.filas_totales = len(df)

    validate_no_duplicate_years(df, "Año", r)
    validate_years(df, "Año", r)
    validate_expected_columns(df, ["Año", "Total"] + grupos, r)
    validate_no_negative(df, ["Total"] + grupos, r)
    validate_totals_match(df, "Total", grupos, r)

    r.filas_validas = len(df) if r.es_valido else 0
    return r


def validate_tipo(df: pd.DataFrame) -> ValidationResult:
    tipos = [
        "Vehículos", "Peatones", "Arma de fuego", "Motocicletas", "Comercios",
        "Residencias", "Buses", "Turistas", "Iglesias", "Banco",
        "Unidades blindadas", "Otros robos",
    ]
    r = ValidationResult("robos_por_tipo.xlsx")
    r.filas_totales = len(df)

    validate_no_duplicate_years(df, "Año", r)
    validate_years(df, "Año", r)
    validate_expected_columns(df, ["Año", "Total"] + tipos, r)
    validate_no_negative(df, ["Total"] + tipos, r)
    validate_totals_match(df, "Total", tipos, r)

    if "Turistas" in df.columns:
        ceros = df[df["Turistas"] == 0]["Año"].tolist()
        if ceros:
            r.warn(f"'Turistas' = 0 en años {ceros}. Confirmar si es correcto.")

    r.filas_validas = len(df) if r.es_valido else 0
    return r
