#!/bin/bash

# Aplica migraciones de Flyway, genera el diccionario de datos y/o ejecuta el ETL.
#
# Fases (si no se indica ninguna, corren todas en orden):
#   --migrate            Solo migraciones.
#   --dict               Solo generación del diccionario de datos.
#   --etl                Solo ETL.
#
# Opciones del ETL (se reenvían a run_all.py; aplican cuando corre el ETL):
#   -m, --module NOMBRE  Ejecuta solo esa carpeta (p.ej. geografia).
#   --stop-on-error      Aborta al primer script que falle.
#   --list               Muestra el orden de ejecución sin ejecutar.
#
# Ejemplos:
#   bash scripts/run.sh                        # migraciones + ETL completo
#   bash scripts/run.sh --migrate              # solo migraciones
#   bash scripts/run.sh --dict                 # solo diccionario
#   bash scripts/run.sh --etl                  # solo ETL completo
#   bash scripts/run.sh --etl -m geografia     # solo ETL de un módulo
#   bash scripts/run.sh --etl --list           # ver el plan del ETL

set -e

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ETL_PYTHON_DIR="$ROOT_DIR/etl/python"


# Trabajar desde la raíz para que las rutas relativas de flyway.conf resuelvan bien.
cd "$ROOT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
    # Imprime el bloque de comentarios de la cabecera (hasta el primer no-comentario).
    awk 'NR<=2 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
}

# Argumentos
RUN_MIGRATE=false
RUN_ETL=false
RUN_DICT=false
PHASE_SELECTED=false
ETL_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --migrate) RUN_MIGRATE=true; PHASE_SELECTED=true; shift ;;
        --dict)    RUN_DICT=true;    PHASE_SELECTED=true; shift ;;
        --etl)     RUN_ETL=true;     PHASE_SELECTED=true; shift ;;
        -m|--module)
            [ -n "${2:-}" ] || fail "Falta el nombre del módulo tras $1"
            ETL_ARGS+=("--module" "$2"); shift 2 ;;
        --stop-on-error|--list)
            ETL_ARGS+=("$1"); shift ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Argumento no reconocido: $1  (usa --help)" ;;
    esac
done

# Sin fase explícita => corren ambas.
if [ "$PHASE_SELECTED" = false ]; then
    RUN_MIGRATE=true
    RUN_DICT=true
    RUN_ETL=true
fi

# .env
if [ ! -f "$ENV_FILE" ]; then
    fail "No se encontró .env. Copia .env.example como .env y completa las variables."
fi

set -a
source "$ENV_FILE"
set +a

# Migraciones
if [ "$RUN_MIGRATE" = true ]; then
    log "Aplicando migraciones con Flyway..."

    if command -v flyway &> /dev/null; then
        log "  Usando Flyway CLI local."
        flyway \
            -configFiles="$ROOT_DIR/database/flyway.conf" \
            -url="$FLYWAY_URL" \
            -user="$FLYWAY_USER" \
            -password="$FLYWAY_PASSWORD" \
            migrate

    elif command -v docker &> /dev/null; then
        log "  Flyway CLI no encontrado. Usando Docker."

        # Dentro del contenedor 'localhost' no sirve. El host para alcanzar
        # Postgres se decide por variable de entorno (no por sistema operativo):
        #   Postgres en Docker (compose):  postgres              (nombre del servicio)
        #   Postgres local en el host:     host.docker.internal
        DOCKER_HOST_DB="${FLYWAY_DOCKER_HOST:-postgres}"
        FLYWAY_DOCKER_URL="jdbc:postgresql://${DOCKER_HOST_DB}:${DB_PORT}/${DB_NAME}"
        log "  Host de BD para el contenedor: ${DOCKER_HOST_DB}"

        docker compose \
            -f "$ROOT_DIR/docker-compose.yml" \
            run --rm \
            -e FLYWAY_URL="$FLYWAY_DOCKER_URL" \
            flyway

    else
        fail "Ni Flyway CLI ni Docker están disponibles. Instala uno de los dos."
    fi

    log "Migraciones aplicadas."
fi


# Diccionario de Datos
if [ "$RUN_DICT" = true ]; then
    log "Generando diccionario de la base de datos..."

    cd "$ETL_PYTHON_DIR"

    if [ -f ".venv/bin/activate" ]; then
        source ".venv/bin/activate"
        pip install -r requirements.txt
    else
        warn "No se encontró entorno virtual en .venv."
        warn "Ejecutar: python -m venv ${ETL_DIR}/.venv"
    fi

    python "$ETL_PYTHON_DIR/meta/generar_diccionario.py"

    log "Diccionario generado/actualizado."
fi


# --- ETL (Python) -------------------------------------------------------------
if [ "$RUN_ETL" = true ]; then
    log "Iniciando procesos ETL..."

    cd "$ETL_PYTHON_DIR"

    if [ -f ".venv/bin/activate" ]; then
        source ".venv/bin/activate"
        pip install -r requirements.txt
    else
        warn "No se encontró entorno virtual en ${ETL_PYTHON_DIR}/.venv."
        warn "Ejecutar: python -m venv ${ETL_PYTHON_DIR}/.venv"
    fi

    # Reenvía las opciones del ETL (módulo, list, stop-on-error) si las hay.
    python "./run_all.py" ${ETL_ARGS[@]+"${ETL_ARGS[@]}"}

    log "ETL completado."
fi

log "Listo."
