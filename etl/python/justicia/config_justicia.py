"""
config_justicia.py — Constantes del modulo ETL Justicia / Seguridad Publica.
No contiene credenciales de BD; la conexion la provee el config.py del proyecto.
"""
from pathlib import Path

# Raiz del repositorio: etl/python/justicia -> etl/python -> etl -> raiz (proyecto)
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent

DATA_DIR      = BASE_DIR / "data" / "justicia"
LOGS_DIR      = DATA_DIR / "logs"

# Archivos CSV del INE (2 filas de cabecera antes de los datos)
INE_DIR = DATA_DIR / "INE"
CSV_INE = {
    "departamento": INE_DIR / "Denunicas Por Depto.csv",
    "sexo":         INE_DIR / "Denunicas Por Sexo.csv",
    "edad":         INE_DIR / "Denuncias Por Edad.csv",
    "tipo":         INE_DIR / "Denuncias Por Tipo.csv",
}
# Filas de cabecera del INE antes de los datos (0-indexed para pandas)
INE_HEADER_ROW = 2

# Archivos CSV de la PNC — datos de nivel evento, anio 2023
PNC_DIR = DATA_DIR / "PNC" / "2023"
CSV_PNC = {
    "victimas":   PNC_DIR / "Victimas.csv",
    "detenidos":  PNC_DIR / "Detenidos.csv",
}

# Archivos CSV del MP — datos de nivel evento, anio 2023
MP_DIR = DATA_DIR / "MP" / "2023"
CSV_MP = {
    "agraviados": MP_DIR / "Agraviados.csv",
    "sincidados": MP_DIR / "Sincidados.csv",
}

YEAR_MIN = 2009
YEAR_MAX = 2030

NULL_MARKERS = ["-", "\u2014", "N/A", "", None]

FUENTE_INE = "INE / PNC Guatemala"
FUENTE_PNC_VIC = "PNC 2023 - Victimas"
FUENTE_PNC_DET = "PNC 2023 - Detenidos"
FUENTE_MP_AGR  = "MP 2023 - Agraviados"
FUENTE_MP_SIN  = "MP 2023 - Sindicados"

# Nombre en CSV -> ID en geografia.departamento
# Fallback cuando el ETL de geografia no ha cargado datos.
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

# Nombre en CSV -> ID en justicia.sexo (debe coincidir con seed V20260704000001)
SEXO_MAP = {
    "Hombre":          1,
    "Mujer":           2,
    "Ignorado":        3,
    "No especificado": 3,
}

# Nombre en CSV -> ID en justicia.grupo_edad_victima (referencia, no usado directo)
EDAD_MAP = {
    "Menor de 15":  1,  "15-19":    2,  "20-24":    3,
    "25-29":        4,  "30-34":    5,  "35-39":    6,
    "40-44":        7,  "45-49":    8,  "50-54":    9,
    "55-59":       10,  "60 y más": 11, "Ignorado": 12,
}

# Nombre en CSV INE -> codigo en justicia.tipo_delito
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

# Columna g_delitos de PNC Victimas -> codigo en justicia.tipo_delito
PNC_VICTIMAS_MAP = {
    "Contra el patrimonio": "VICTIMAS_PATRIMONIO",
}
PNC_VICTIMAS_FALLBACK = "VICTIMAS_OTRAS"

# Columna g_delitos de PNC Detenidos -> codigo en justicia.tipo_delito
PNC_DETENIDOS_MAP = {
    "Contra el patrimonio": "DETENIDOS_PATRIMONIO",
}
PNC_DETENIDOS_FALLBACK = "DETENIDOS_OTRAS"

# Columna principales_delitos de MP -> codigo en justicia.tipo_delito
# V1 usa un unico codigo por fuente; se puede expandir en futuras versiones.
MP_AGRAVIADOS_FALLBACK = "AGRAVIADOS_OTRAS"
MP_SINCIDADOS_FALLBACK  = "SINCIDADOS_OTROS"
