# scripts

Automatización y utilidades del proyecto: los scripts que preparan el entorno,
aplican las migraciones, ejecutan el ETL y generan archivos.

```
scripts/
|-- run.sh          entrada principal: migraciones, diccionario y ETL
|-- init_db.sh      crea la base e instala extensiones (una vez)
|-- init_db.sql     extensiones y configuraciones iniciales
|-- new.sh          genera migraciones y scripts de ETL bien nombrados
|-- cultura/        scripts utilitarios específicos de cultura e identidad
|   |-- enrich_languages.py      genera catálogo y relaciones de idiomas
|   `-- parse_gastronomia_pdfs.py  parsea PDFs de recetas a CSV estructurado
`-- generated/      scripts generados por otros procesos, versionados
```

---

## Scripts principales

### run.sh

Es la entrada principal del proyecto. Aplica las migraciones con Flyway, genera o
actualiza el diccionario de la base y ejecuta los procesos de ETL, en ese orden.
Detecta automáticamente si usar Flyway CLI o Docker según lo que esté disponible.

Sin argumentos corre las tres fases. También se puede correr una sola:

```bash
bash scripts/run.sh              # migraciones + diccionario + ETL
bash scripts/run.sh --migrate    # solo migraciones
bash scripts/run.sh --dict       # solo generar el diccionario
bash scripts/run.sh --etl        # solo ETL
bash scripts/run.sh --etl -m geografia   # solo el ETL de un módulo
```

Lee la configuración del `.env` de la raíz del proyecto, así que este debe existir antes de ejecutarlo.

### init_db.sh

Prepara la base de datos. Crea la base si aún no existe e instala las extensiones necesarias (ejecutando `init_db.sql`). 
Solo hace falta correrlo una vez, la primera vez que se levanta el proyecto en un entorno:

```bash
bash scripts/init_db.sh
```

Aunque hoy la preparación es sencilla, se dejó como paso aparte para dar espacio
a futuras configuraciones iniciales, como la separación de usuarios de la base.

### init_db.sql

Script SQL que ejecuta `init_db.sh`. Instala las extensiones de PostgreSQL que el proyecto necesita y sirve de lugar para futuras configuraciones iniciales. 
Se ejecuta una sola vez por entorno.

### new.sh

Genera un archivo de migración o de ETL con el nombre correcto (timestamp y formato), creando la carpeta destino si no existe. 
Evita errores de numeración al escribir los nombres a mano.

```bash
bash scripts/new.sh migration <carpeta> <descripcion>   # nueva migración
bash scripts/new.sh etl <carpeta> <descripcion>         # nuevo proceso ETL
```

Ejemplos:

```bash
bash scripts/new.sh migration geografia agregar_tabla_aldea
bash scripts/new.sh etl salud load_hospitales
```

Acepta `--ts YYYYMMDDHHMMSS` para fijar el timestamp de forma manual (útil para emparejar un ETL con la migración correspondiente).

---

## cultura/

Contiene scripts de preparación y enriquecimiento para el módulo de Cultura e Identidad.

### enrich_languages.py

Genera los archivos CSV `idiomas.csv` e `idiomas_municipios.csv` con el catálogo completo de los 24 idiomas nacionales de Guatemala y sus relaciones de distribución municipal oficiales.

```bash
python scripts/cultura/enrich_languages.py
```

### parse_gastronomia_pdfs.py

Script de pre-ETL que lee libros de cocina tradicionales en formato de texto plano (extraídos de PDFs), estructura la información en platillos típicos, ingredientes y relaciones, resuelve las PCodes geográficas a través de la base de datos y escribe los archivos CSV correspondientes.

```bash
python scripts/cultura/parse_gastronomia_pdfs.py
```

---

## generated/

Guarda los scripts generados por otros procesos que se desea versionar, principalmente el SQL que producen algunos ETL. 
Se organizan por módulo, por ejemplo `scripts/generated/geografia/`.

Estos archivos se generan de forma determinista (el mismo insumo produce el mismo archivo),
por lo que sirven como evidencia exacta y versionable de lo que se cargó. 
No se editan a mano: se regeneran corriendo el proceso que los produce.

---

## Referencias

- [`README.md`](../README.md): cómo levantar el proyecto desde cero.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md): convenciones y flujos de contribución.
- [`etl/python/README.md`](../etl/python/README.md): detalle del orquestador y los procesos de ETL.
