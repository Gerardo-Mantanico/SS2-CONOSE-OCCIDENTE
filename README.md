# CONOCE GUATEMALA

Base de datos relacional que toma a Guatemala como eje central, pensada para reunir en un solo lugar información relevante de multiples áreas de interés
(justicia, salud, educación, turismo, clima, geografía, demografía, entre otras) y habilitar su análisis integral y transversal.

Funciona como repositorio central: los datos se recopilan de fuentes oficiales, se normalizan por dominio y se cargan con trazabilidad completa, de modo que a
futuro se puedan hacer extracciones y análisis específicos con datos de calidad.
El diseño es normalizado y transaccional (una base operacional organizada por
esquemas), no un data-warehouse.

---

<!-- TOC -->
* [CONOCE GUATEMALA](#conoce-guatemala)
  * [Propósito](#propósito)
  * [Como funciona](#como-funciona)
  * [Estructura del repositorio](#estructura-del-repositorio)
  * [Requisitos](#requisitos)
  * [Configuración (.env)](#configuración-env)
  * [Levantar el proyecto desde cero](#levantar-el-proyecto-desde-cero)
    * [1. Credenciales](#1-credenciales)
    * [2. Levantar PostgreSQL](#2-levantar-postgresql)
    * [3. Preparar el entorno de Python](#3-preparar-el-entorno-de-python)
    * [4. Crear la base y sus extensiones](#4-crear-la-base-y-sus-extensiones)
    * [5. Ejecutar migraciones y ETL](#5-ejecutar-migraciones-y-etl)
  * [Ajustar según el entorno](#ajustar-según-el-entorno)
  * [Consumir la base](#consumir-la-base)
    * [Puntos de entrada recomendados:](#puntos-de-entrada-recomendados)
  * [Reproducibilidad](#reproducibilidad)
  * [Documentación adicional](#documentación-adicional)
  * [Estado del proyecto](#estado-del-proyecto)
<!-- TOC -->

---

## Propósito

El proyecto reune datos de distintas fuentes en una sola base relacional, cuidando tres cosas:

1. Calidad y normalización: cada dominio se modela en su propio esquema, con integridad referencial y tipos correctos.
2. Trazabilidad: de cada dato se sabe de qué fuente vino, en que carga entro y cuando (esquema `meta`).
3. Reproducibilidad: cualquier persona puede levantar la base completa desde cero, en diferentes entornos.

---

## Como funciona

- **Migraciones versionadas con Flyway.** Todo cambio de esquema es una migración en `database/migrations/`; la base nunca se modifica a mano.
- **ETL**. Los procesos de transformación y carga viven en `etl/`, de momento en las versiones iniciales se manejarán procesos solo con python,
  pero agregar otra tecnología o lenguaje no será complicado en el futuro, por ello los procesos se encuentran en `etl/python/`
  comparten una conexión común a la base de datos y registran cada ejecución en `meta.carga`.
- **Trazabilidad por diseño.** Cada tabla de dominio lleva un `carga_id` que apunta al proceso de carga que la pobló, y esa carga apunta a si vez a la fuente de datos.
- **Auditoria automática.** El esquema `auditoria` registra los cambios (INSERT, UPDATE, DELETE) de las tablas de dominio mediante triggers genéricos que se enganchan tras cada migración.
- **Diccionario autogenerado.** La documentación de objetos de la base de datos, el diccionario de la base de datos, se genera a partir de la misma base de datos (`meta.diccionario` produce `docs/diccionario.md`), 
  asi siempre está sincronizada con el esquema real.
- **Credenciales fuera del repositorio.** Todo se configura por `.env` para ajustarlo al entorno, no se sube al repositorio.

---

## Estructura del repositorio

```
/
|-- .env.example              plantilla de variables de entorno
|-- .gitignore
|-- docker-compose.yml        postgres + flyway
|
|-- database/                 estructura de la base, migraciones y config de Flyway
|   |-- flyway.conf
|   `-- migrations/           una carpeta por esquema
|       |-- meta/             fuentes, cargas, vista de diccionario
|       |-- geografia/
|       |-- clima/
|       |-- demografia/
|       |-- auth/
|       |-- sector_publico/
|       |-- patrimonio/
|       |-- justicia/
|       `-- auditoria/        bitácora, triggers genericos y callback afterMigrate
|
|-- etl/                      procesos de extraccion, transformacion y carga
|   `-- python/
|       |-- config.py         get_connection() y registrar_carga() compartidos
|       |-- requirements.txt  
|       |-- run_all.py        orquestador de los procesos ETL
|       `-- {modulo}/         scripts de carga por dominio
|
|-- scripts/                  automatizacion y utilidades
|   |-- run.sh                entrada principal: migraciones, generación del diccionario, ejecución ETL
|   |-- init_db.sh            crea la base si aún no existe y agrega sus extensiones
|   |-- init_db.sql           script para agregar las extensiones o futar configuraciones iniciales necesarias
|   |-- new.sh                genera archivos de migracion o ETL bien nombrados
|   `-- generated/            scripts generados por algún otro proceso que se desen versionar
|
|-- data/                     archivos de datos, catalogo de fuentes, diccionarios de estas fuentes
|-- diagrams/                 diagramas del modelo, arquitectura y flujos
`-- docs/                     documentacion formal, guias y diccionario generado
```

Cada carpeta tiene un README propio con el detalle de su uso.

---

## Requisitos

- PostgreSQL, en cualquiera de estas dos formas:
  - Local: una instancia de PostgreSQL accesible (version 16 o superior), o
  - Docker: Docker y Docker Compose (levanta PostgreSQL por ti).
- Flyway, en cualquiera de estas dos formas:
  - Flyway CLI instalado localmente, o
  - Docker (el script `run.sh` usa la imagen de Flyway automáticamente).
- Python 3.10 o superior, con las dependencias de `etl/python/requirements.txt`.
- git.

El script `run.sh` detecta qué se tiene disponible (Flyway CLI o Docker) y actúa en consecuencia, por lo que no se necesitan ambos.

Para instalar PostgreSQL o Flyway en tu sistema, consulta la
[Guía de instalación de dependencias](docs/Guia_instalacion_dependencias.md).

---

## Configuración (.env)

Desde la raiz del proyecto, copia la plantilla y ajusta lo que necesites:

```bash
cp .env.example .env
```

`.env.example` documenta todas las variables. Si se levantará el proyecto con
Docker, se pueden dejar los valores por defecto. Variables principales:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bd_nacional
DB_USER=postgres
DB_PASSWORD=postgres

FLYWAY_URL=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
FLYWAY_USER=${DB_USER}
FLYWAY_PASSWORD=${DB_PASSWORD}

DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}

# Solo aplica si Flyway corre dentro de Docker. Host para alcanzar Postgres:
#   postgres              -> Postgres tambien en Docker (compose)
#   host.docker.internal  -> Postgres local en el host
FLYWAY_DOCKER_HOST=postgres
```

El archivo `.env` con las credenciales del entorno local nunca se sube al repositorio.

---

## Levantar el proyecto desde cero

El proceso es sencillo, básicamente:
1. Clonar repo
2. Configurar entorno `.env`
3. Ejecutar `bash scripts/init_db.sh`
4. Ejecutar `bash scripts/run.sh`

A continuación se detallan estos pasos. Habiendo clonado el repositorio:

```bash
git clone <url-del-repo>
cd <repo>
```

### 1. Credenciales

```bash
cp .env.example .env
```

Editar el archivo `.env` con los valores adecuados para el entorno (ver [Ajustar según el entorno](#ajustar-según-el-entorno)).

### 2. Levantar PostgreSQL

Opción A, con Docker:

```bash
docker compose up -d postgres
```

Opción B, con una instalación local: si ya se tiene instalado PostgreSQL, no hace falta nada extra; 
en caso contrario revisar la [Guía de instalación de dependencias](docs/Guia_instalacion_dependencias.md).

### 3. Preparar el entorno de Python

```bash
python -m venv etl/python/.venv
source etl/python/.venv/bin/activate
pip install -r etl/python/requirements.txt
```

### 4. Crear la base y sus extensiones

Solo es necesario ejecutarlo una vez, la primera vez que se levanta el proyecto en un entorno.
Crea la base de datos si aún no existe e instala las extensiones necesarias:

```bash
bash scripts/init_db.sh
```

> Aunque de momento el iniciar la base de datos no es un proceso muy complicado, se dejó como proceso aparte
> para dar espacio y facilitar futuras configuraciones iniciales como la separación de usuarios de la base de datos

### 5. Ejecutar migraciones y ETL

`run.sh` aplica las migraciones con Flyway, genera o actualiza el diccionario de la base de datos y luego ejecuta los procesos de ETL:

```bash
bash scripts/run.sh
```

Al terminar tendrás la base creada, con su estructura y sus datos cargados.

Para trabajar por partes también puedes correr solo una fase:

```bash
bash scripts/run.sh --migrate            # solo migraciones
bash scripts/run.sh --dict               # solo generar el diccionario de la base de datos
bash scripts/run.sh --etl                # solo ETL
bash scripts/run.sh --etl -m geografia   # solo el ETL de un modulo
```

---

## Ajustar según el entorno

El proyecto debe adaptarse a diferentes entornos simplemente cambiando variables del `.env`; 
Sin necesidad de tocar código. Casos comunes:

- Postgres en Docker (opción A): dejar `DB_HOST=localhost` y, si Flyway corre en Docker, `FLYWAY_DOCKER_HOST=postgres`.
- Postgres local y Flyway en Docker: `FLYWAY_DOCKER_HOST=host.docker.internal` para que el contenedor de Flyway alcance la base del host.
- Postgres local y Flyway CLI local: no necesita `FLYWAY_DOCKER_HOST`; todo apunta a `localhost`.
- Base en otro host o puerto (remoto u otra máquina): ajustar `DB_HOST`, `DB_PORT`, `DB_USER` y `DB_PASSWORD`; 
  `FLYWAY_URL` y `DATABASE_URL` se derivan de esas variables.

---

## Consumir la base

Una vez cargada la base de datos, conectarse con cualquier cliente SQL usando las credenciales del
`.env`, o directamente con `DATABASE_URL`:

```bash
psql "$DATABASE_URL"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
```

### Puntos de entrada recomendados:

- `meta.diccionario`: vista que lista todas las tablas y columnas con su tipo, llaves, referencias y descripción. Es el mapa de la base.

```sql
SELECT esquema, tabla, columna, tipo, comentario
FROM meta.diccionario
WHERE esquema = 'geografia';
```

- Esquemas de dominio (`geografia`, `demografia`, `justicia`, etc.): los datos ya normalizados.
- `meta.fuente` y `meta.carga`: de donde viene cada dato y en que carga entro. Cada tabla de dominio tiene un `carga_id` que enlaza a `meta.carga`.
- `auditoria.registro`: historial de cambios de las tablas de dominio.

También se puede consultar la version en Markdown del diccionario en
[`docs/diccionario.md`](docs/diccionario.md).

---

## Reproducibilidad

- Los datos de referencia y los archivos fuente reproducibles se versionan en`data/`. 
  Cambiando un archivo de entrada por otro con la misma estructura, el mismo proceso ETL sirve para otra version u otro caso.
- Los ETL que generan otros scripts (principalmente SQL) los guardan en `scripts/generated/` de forma
  determinista (mismo insumo produce el mismo archivo), dejando evidencia exacta y versionable de lo que se cargó.
- Cada carga registra en `meta.carga` el hash SHA-256 del archivo procesado, para poder corroborar que la base corresponde a un archivo concreto.

---

## Documentación adicional

- [`CONTRIBUTING.md`](CONTRIBUTING.md): guía detallada para colaborar
  (convenciones, flujos, comandos y herramientas).
- [`docs/Guia_instalacion_dependencias.md`](docs/Guia_instalacion_dependencias.md):
  instalación de PostgreSQL y Flyway por sistema operativo.
- [`docs/diccionario.md`](docs/diccionario.md): diccionario de datos generado.
- README por carpeta (`data/`, `etl/`, `scripts/`, `database/`): uso y modificación específica de cada parte.

---

## Estado del proyecto

Implementado:

- Migraciones por esquema con Flyway y numeración por timestamp.
- ETL en Python con orquestador y registro de cargas en `meta`.
- Trazabilidad fuente, carga y tabla mediante `carga_id`.
- Auditoria automática por triggers genéricos.
- Diccionario de datos autogenerado.

Planificado:

- Tablas bitemporales (`valid_from`, `valid_to`, `recorded_at`, `superseded_at`) para datos que cambian en el tiempo.
- Nuevos dominios (salud, educación, turismo, entre otros).
- Vistas de corroboración entre fuentes distintas para un mismo hecho.
