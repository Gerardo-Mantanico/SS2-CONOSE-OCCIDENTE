"""
config_justicia.py — Constantes del modulo ETL Justicia / Seguridad Publica.
No contiene credenciales de BD; la conexion la provee el config.py del proyecto.
"""
from pathlib import Path

# Raiz del repositorio: etl/python/justicia -> etl/python -> etl -> raiz
BASE_DIR = Path(__file__).resolve().parent.parent.parent

DATA_DIR      = BASE_DIR / "data" / "justicia"
RAW_DIR       = DATA_DIR / "raw"
PROCESSED_DIR = DATA_DIR / "processed"
LOGS_DIR      = DATA_DIR / "logs"

EXCEL_FILES = {
    "departamento": RAW_DIR / "robos_por_departamento.xlsx",
    "sexo":         RAW_DIR / "robos_por_sexo.xlsx",
    "edad":         RAW_DIR / "robos_por_edad.xlsx",
    "tipo":         RAW_DIR / "robos_por_tipo.xlsx",
}

SHEET_NAME = "Datos"

YEAR_MIN = 2009
YEAR_MAX = 2030

NULL_MARKERS = ["-", "\u2014", "N/A", "", None]

# Fila donde empieza la data real en los Excel del INE (0-indexed para pandas)
HEADER_ROW = 2

FUENTE = "INE / PNC Guatemala"

# Nombre en Excel -> ID en geografia.departamento
# Los IDs asumen que el ETL de geografia los cargo en orden (1-22).
DEPTO_MAP = {
    "Guatemala":      1,  "El Progreso":    2,  "Sacatepéquez":   3,
    "Chimaltenango":  4,  "Escuintla":      5,  "Santa Rosa":     6,
    "Sololá":         7,  "Totonicapán":    8,  "Quetzaltenango": 9,
    "Suchitepéquez": 10,  "Retalhuleu":    11,  "San Marcos":    12,
    "Huehuetenango": 13,  "Quiché":        14,  "Baja Verapaz":  15,
    "Alta Verapaz":  16,  "Petén":         17,  "Izabal":        18,
    "Zacapa":        19,  "Chiquimula":    20,  "Jalapa":        21,
    "Jutiapa":       22,
}

# Nombre en Excel -> ID en justicia.sexo (debe coincidir con seed)
SEXO_MAP = {
    "Hombre":          1,
    "Mujer":           2,
    "Ignorado":        3,
    "No especificado": 3,
}

# Nombre en Excel -> ID en justicia.grupo_edad_victima (referencia, no usado directo)
EDAD_MAP = {
    "Menor de 15":  1,  "15-19":    2,  "20-24":    3,
    "25-29":        4,  "30-34":    5,  "35-39":    6,
    "40-44":        7,  "45-49":    8,  "50-54":    9,
    "55-59":       10,  "60 y más": 11, "Ignorado": 12,
}

# Nombre en Excel -> codigo en justicia.tipo_delito
TIPO_ROBO_MAP = {
    "Vehículos":          "VEHICULOS",
    "Peatones":           "PEATONES",
    "Arma de fuego":      "ARMA_FUEGO",
    "Motocicletas":       "MOTOCICLETAS",
    "Comercios":          "COMERCIOS",
    "Residencias":        "RESIDENCIAS",
    "Buses":              "BUSES",
    "Turistas":           "TURISTAS",
    "Iglesias":           "IGLESIAS",
    "Banco":              "BANCO",
    "Unidades blindadas": "UNIDADES_BLINDADAS",
    "Otros robos":        "OTROS",
}
