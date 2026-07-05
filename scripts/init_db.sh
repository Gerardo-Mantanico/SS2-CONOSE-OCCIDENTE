#!/bin/bash

# Wrapper de inicialización
# Crea la base de datos si no existe
# Lee las variables de entorno desde .env y corre init_db.sql.
# Instala las extensiones de PostgreSQL necesarias para el proyecto.
# Solo necesita correrse una vez por entorno.
# Uso: bash scripts/init_db.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: No se encontró .env en la raíz del proyecto."
    echo "Copia .env.example como .env y completa las variables."
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

echo "Conectando a PostgreSQL en ${DB_HOST}:${DB_PORT}/${DB_NAME} para crear la base de datos si no existe"

PGPASSWORD="$DB_PASSWORD" psql \
            -h "$DB_HOST" \
            -p "$DB_PORT" \
            -U "$DB_USER" \
            -d postgres -tc \
            "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 \
            || PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres \
            -c "CREATE DATABASE \"$DB_NAME\""

echo "Conectando a PostgreSQL en ${DB_HOST}:${DB_PORT}/${DB_NAME} para agregar extensiones"

PGPASSWORD="$DB_PASSWORD" psql \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -f "$SCRIPT_DIR/init_db.sql"
