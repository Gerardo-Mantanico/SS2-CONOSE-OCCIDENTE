#!/bin/bash

# Genera un archivo de migración (Flyway) o de ETL (Python) con el nombre
# estandarizado del proyecto: prefijo de timestamp YYYYMMDDHHMMSS.
#
# Uso:
#   bash scripts/new.sh <tipo> <carpeta> <descripcion> [--ts YYYYMMDDHHMMSS]
#
#   tipo         migration | etl
#   carpeta      subcarpeta destino, se crea si no existe (p.ej. geografia,
#                o anidada: geografia/limites)
#   descripcion  nombre corto en snake_case ASCII (p.ej. crear_pais)
#   --ts         (opcional) fija el timestamp en vez de usar la hora actual.
#                Útil para emparejar un ETL con su migración usando el mismo
#                número.
#
# Ejemplos:
#   bash scripts/new.sh migration geografia crear_pais
#     -> database/migrations/geografia/V20260703120014__crear_pais.sql
#   bash scripts/new.sh etl geografia load_pais
#     -> etl/python/geografia/20260703120014_load_pais.py
#   bash scripts/new.sh etl geografia load_pais --ts 20260703120014
#     -> reutiliza el número de la migración correspondiente

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    # Imprime el bloque de comentarios de la cabecera (hasta el primer no-comentario).
    awk 'NR<=2 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
}

# --- Argumentos ---------------------------------------------------------------
TS_OVERRIDE=""
POSITIONAL=()

while [ $# -gt 0 ]; do
    case "$1" in
        --ts) TS_OVERRIDE="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Opción no reconocida: $1"; echo; usage; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
set -- ${POSITIONAL[@]+"${POSITIONAL[@]}"}

TIPO="${1:-}"
CARPETA="${2:-}"
DESC="${3:-}"

if [ -z "$TIPO" ] || [ -z "$CARPETA" ] || [ -z "$DESC" ]; then
    usage
    exit 1
fi

# --- Timestamp ----------------------------------------------------------------
if [ -n "$TS_OVERRIDE" ]; then
    if ! [[ "$TS_OVERRIDE" =~ ^[0-9]{14}$ ]]; then
        echo "ERROR: --ts debe tener el formato YYYYMMDDHHMMSS (14 dígitos)."
        exit 1
    fi
    TS="$TS_OVERRIDE"
else
    TS="$(date +%Y%m%d%H%M%S)"
fi

# --- Normalizar descripción a snake_case --------------------------------------
SLUG="$(echo "$DESC" | tr '[:upper:]' '[:lower:]' | tr ' -' '__' | tr -cd 'a-z0-9_')"
if [ -z "$SLUG" ]; then
    echo "ERROR: la descripción quedó vacía tras normalizar. Usa snake_case ASCII."
    exit 1
fi

FECHA_LEGIBLE="$(date '+%Y-%m-%d %H:%M:%S')"

case "$TIPO" in
    migration|migracion|mig)
        SCHEMA="${CARPETA%%/*}"                       # primer segmento = schema
        DIR="$ROOT_DIR/database/migrations/$CARPETA"
        FILE="$DIR/V${TS}__${SLUG}.sql"
        mkdir -p "$DIR"
        [ -e "$FILE" ] && { echo "ERROR: ya existe $FILE"; exit 1; }

        cat > "$FILE" <<EOF
-- Migración: ${SLUG}
-- Schema:    ${SCHEMA}
-- Generado:  ${FECHA_LEGIBLE}
--
-- indicar SIEMPRE el schema al crear un objeto (${SCHEMA}.tabla).
-- No depender del search_path por defecto.

CREATE SCHEMA IF NOT EXISTS ${SCHEMA};

EOF
        ;;

    etl)
        DIR="$ROOT_DIR/etl/python/$CARPETA"
        FILE="$DIR/${TS}_${SLUG}.py"
        mkdir -p "$DIR"
        [ -e "$FILE" ] && { echo "ERROR: ya existe $FILE"; exit 1; }

        cat > "$FILE" <<EOF
#!/usr/bin/env python3
"""ETL: ${SLUG}  (módulo: ${CARPETA})
Generado: ${FECHA_LEGIBLE}
"""

import sys
from pathlib import Path

# Permite importar config al ejecutar el script por su cuenta, sin importar el directorio de trabajo
for _p in Path(__file__).resolve().parents:
    if (_p / "config.py").exists():
        sys.path.insert(0, str(_p))
        break

from config import get_connection


def main() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            # TODO: implementar la carga.
            pass
        conn.commit()


if __name__ == "__main__":
    main()
EOF
        chmod +x "$FILE"
        ;;

    *)
        echo "ERROR: tipo desconocido '$TIPO' (usa: migration | etl)"
        echo
        usage
        exit 1
        ;;
esac

echo "Creado: ${FILE#"$ROOT_DIR"/}"
