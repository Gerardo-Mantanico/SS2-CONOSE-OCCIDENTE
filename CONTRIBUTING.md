# Guia de contribución

Esta guía explica como está organizado el proyecto CONOCE GUATEMALA y como usar sus herramientas y scripts para colaborar. 
Si es la primera vez, primero es necesario levantar el proyecto siguiendo el [README](README.md); 
esta guía asume que ya se tiene levantado el proyecto.

---

<!-- TOC -->
* [Guia de contribución](#guia-de-contribución)
  * [Filosofía del proyecto](#filosofía-del-proyecto)
  * [Preparar el entorno](#preparar-el-entorno)
  * [Organización del repositorio](#organización-del-repositorio)
  * [Flujo de trabajo con git](#flujo-de-trabajo-con-git)
  * [Convenciones](#convenciones)
    * [Numeración por timestamp](#numeración-por-timestamp)
    * [Migraciones](#migraciones)
    * [ETL](#etl)
    * [Fuentes de datos](#fuentes-de-datos)
    * [Auditoria](#auditoria)
    * [Datos y archivos generados](#datos-y-archivos-generados)
    * [Comentarios y diccionario](#comentarios-y-diccionario)
  * [Procesos paso a paso](#procesos-paso-a-paso)
    * [Agregar una tabla a un esquema existente](#agregar-una-tabla-a-un-esquema-existente)
    * [Crear un esquema nuevo](#crear-un-esquema-nuevo)
    * [Agregar una fuente de datos](#agregar-una-fuente-de-datos)
    * [Crear un proceso ETL](#crear-un-proceso-etl)
    * [Crear un script de utilidades](#crear-un-script-de-utilidades)
    * [Regenerar el diccionario](#regenerar-el-diccionario)
  * [Comandos utiles](#comandos-utiles)
  * [Recomendaciones](#recomendaciones)
  * [Referencias](#referencias)
<!-- TOC -->

---

## Filosofía del proyecto

Tres ideas guían todas las convenciones:

1. **La base nunca se cambia a mano.** Todo cambio de estructura es una migración versionada; 
   todo dato entra por un proceso de ETL. Asi el estado de la base es siempre reproducible desde el repositorio.
2. **Todo dato es trazable.** Cada fila de dominio sabe de qué carga vino, y cada carga sabe de qué fuente.
3. **La documentación se genera, para no necesitar mantenerla a mano**. El diccionario sale de los
   comentarios que se escriben en las mismas migraciones.

---

## Preparar el entorno

Levantar el proyecto si aún no se ha hecho:

```bash
python -m venv etl/python/.venv
source etl/python/.venv/bin/activate
pip install -r etl/python/requirements.txt
```

Activar el entorno virtual (`source etl/python/.venv/bin/activate`) siempre que se vayan a ejecutar scripts de Python.

---

## Organización del repositorio

- `/database`: estructura de la base, migraciones y configuración de Flyway. Las migraciones están en `database/migrations/`, una carpeta por esquema.
- `/etl`: procesos de extracción, transformación y carga. El código Python vive en `etl/python/`.
- `/scripts`: automatización y utilidades (entrada principal `run.sh`, preparación `init_db.sh`, generador `new.sh`) y el SQL generado por los ETL.
- `/data`: archivos de datos, el catálogo de fuentes (`fuentes.csv`) y enlaces a fuentes externas.
- `/docs`: documentación formal, guías y el diccionario generado.
- `/diagrams`: diagramas del modelo, arquitectura y flujos de ETL.

Cada carpeta tiene un README propio con su detalle.

---

## Flujo de trabajo con git

1. Crear una rama específica para el nuevo aporte:

   ```bash
   git checkout -b <feature>/<descripcion-corta>
   ```

2. Trabajar en commits pequeños y descriptivos, en modo imperativo. Por ejemplo:
   `agrega tabla aldea a geografia` o `carga municipios desde fuente HDX`.
3. Antes de abrir el Pull Request, verificar en una base limpia que todo corre:

   ```bash
   bash scripts/run.sh
   ```

   Si se modificaron los comentarios de los objetos de la base de datos, 
   verificar que se haya regenerado el diccionario (caso contrario ver [Regenerar el diccionario](#regenerar-el-diccionario)).
4. Abrir Pull Request hacia la rama `develop` describiendo que se agrega y por qué.
5. El Pull Request debe ser aprobado por al menos 2 colaboradores más para poder ser integrado a la rama `develop`.

No se incluyen en los commit: `.env`, `etl/python/.venv/`, ni archivos de datos pesados o privados. Verificar que estén en `.gitignore`.

---

## Convenciones

### Numeración por timestamp

Tanto las migraciones como los scripts de ETL se nombran con un prefijo de timestamp `YYYYMMDDHHMMSS`. 
Es el mismo número en ambos mundos, solo cambia el envoltorio que exige cada herramienta:

- Migración: `V<YYYYMMDDHHMMSS>__<descripcion>.sql`
- ETL: `<YYYYMMDDHHMMSS>_<descripcion>.py`

Aunque se puede escribir el número a mano, se recomienda el uso de `scripts/new.sh`, 
que lo genera automáticamente con el timestamp del momento, de este modo se evitan romper la secuencia de las migraciones

Flyway trata las versiones como una sola línea de tiempo global, sin importar en qué carpeta estén. 
Como cada archivo nuevo lleva el timestamp más alto, siempre se agrega al final de la secuencia; y como el orden alfabético del prefijo
coincide con el cronológico, el orden de ejecución sale solo de los nombres.

### Migraciones

- Una carpeta por esquema dentro de `database/migrations/`.
- La primera migración de un esquema crea el esquema con `CREATE SCHEMA IF NOT EXISTS <esquema>;` (la plantilla de `new.sh` ya lo incluye).
- Especificar SIEMPRE el esquema al nombrar objetos: `geografia.pais`, no solo `pais`.
  No se debe depender del `search_path`, ya que se ejecuta con Flyway, cuyo esquema por defecto es `meta` los objetos terminaran en un esquema incorrecto.
- Documentar cada objeto nuevo en la base de datos (Principalmente tablas y columnas) con `COMMENT ON` en la misma migración que la crea. De ahi sale el diccionario.
- A las tablas de dominio, agregar la columna de trazabilidad `carga_id INT REFERENCES meta.carga(id)`.
- En caso de dependencias cruzadas entre esquemas, se resuelve por el orden de los timestamps 
  (definir primero aquello de lo que algo depende). Si hay una dependencia cíclica, separa la creación de las tablas de la de sus llaves
  foráneas, crear las tablas y luego agregar las llaves con `ALTER TABLE ... ADD CONSTRAINT` en una migración posterior o usar restricciones `DEFERRABLE INITIALLY DEFERRED`.
- No editar una migración anterior o que ya se aplicó en un entorno compartido, crear una migración nueva parar evitar el fallo por checksum de Flyway.

### ETL

- Se crea idealmente una carpeta por módulo dentro de `etl/python/`, con scripts nombrados por timestamp.
- Cada script es autónomo: tiene su propio `main()` para que se pueda ejecutar por su cuenta.  La plantilla de `new.sh` ya trae el arranque para importar `config`.
- Los scripts consumen la conexión desde `config.py`. Para cargar datos usar `registrar_carga()`, que registra automáticamente la ejecución en `meta.carga`
  y entrega el `carga_id` para que sea estampado en cada fila que se registra.
- Los ETL deben ser idempotentes (por ejemplo, `INSERT ... ON CONFLICT ... DO UPDATE` por una clave natural) para poder ejecutarlos múltiples veces sin duplicar los registros.

### Fuentes de datos

- El catálogo de fuentes se mantiene en `data/fuentes.csv`, para evitar tener que hacer migraciones o insertar a mano en SQL.
- Registrar la fuente antes de cargar datos que la usen: agregar a `fuentes.csv` y ejecutar `...load_fuentes.py`, el script es idempotente entonces no hay problema con re-ejecutarlo.
- `registrar_carga()` falla si la fuente no existe, por ello hay que registrarla primero.

### Auditoria

- Es automática. No se necesita hacer nada por tabla: el trigger de auditoria se engancha solo a las tablas nuevas tras cada `flyway migrate`.
- Tomar en cuenta que una carga masiva genera una fila de auditoria por cada fila afectada. Si en un ETL grande estorba, se podría desactivar el trigger de esa
  tabla durante la carga y reactivarlo después.

### Datos y archivos generados

- Los archivos fuente reproducibles se versionan en `data/` (por ejemplo un
  Excel de referencia), para que el flujo se pueda repetir.
- El SQL que generan los ETL se guarda en `scripts/generated/` y se versiona:
  es evidencia exacta de lo que se cargó y es determinista (mismo insumo, mismo
  archivo).

### Comentarios y diccionario

- Comenta idealmente todo objeto nuevo, como minimo tablas y columnas en la migración que las crea. El diccionario
  (`docs/diccionario.md`) se genera desde esos comentarios; sin los comentarios, aparecerán sin descripción.

---

## Procesos paso a paso

### Agregar una tabla a un esquema existente

1. Generar la migración:

   ```bash
   bash scripts/new.sh migration geografia agregar_tabla_aldea
   ```

   Crea `database/migrations/geografia/V<timestamp>__agregar_tabla_aldea.sql`.
2. Editar el archivo: definir la tabla especificando el esquema, agregando `carga_id INT REFERENCES meta.carga(id)` si guardara datos de dominio,
   y escribir los `COMMENT ON` de la tabla y sus columnas.
3. Aplicar cambios:

   ```bash
   bash scripts/run.sh --migrate
   ```

4. Regenerar el diccionario `bash scripts/run.sh --dict`, verificar y hacer commit.

### Crear un esquema nuevo

Agregar un esquema no requiere tocar configuración central (ni `flyway.conf` ni el orquestador): basta con crear los
archivos.

1. Generar la primera migración del esquema:

   ```bash
   bash scripts/new.sh migration salud crear_base
   ```

   La plantilla ya incluye `CREATE SCHEMA IF NOT EXISTS salud;`. 
   Definir ahi las tablas (especificando que pertenecen a `salud.`), con su `carga_id` y sus comentarios.
2. Si el esquema tendrá ETL, crear su carpeta de módulo cuando se necesite (ver el siguiente proceso); tampoco hay que registrarla en ningún lado.
3. Aplicar cambios con `bash scripts/run.sh --migrate` y regenerar el diccionario `bash scripts/run.sh --dict`.

### Agregar una fuente de datos

1. Agregar una fila a `data/fuentes.csv` con su `codigo` (definir un identificador estable y unico, por ejemplo `INE_CENSO_2018`), 
   agregar `tipo_fuente`, nombre, institución, la URL de la que se obtuvo, descripción y la licencia si aplica.
2. Cargar el catálogo de fuentes:

   ```bash
   bash scripts/run.sh --etl -m meta
   ```

   También puedes correr directamente el script de fuentes de `etl/python/meta/<ts>_load_fuentes.py`.
3. A partir de ahi, cualquier ETL puede referenciar esa fuente por su `codigo`.

### Crear un proceso ETL

1. Generar el script:

   ```bash
   bash scripts/new.sh etl salud load_hospitales
   ```

   Esto crea `etl/python/salud/<timestamp>_load_hospitales.py` con la plantilla lista para importar `config`.
2. Implementa la carga consumiendo `registrar_carga()` y estampando el `carga_id`:

   ```python
   from config import registrar_carga

   def main():
       with registrar_carga("CODIGO_FUENTE", archivo="data/salud/hospitales.csv") as carga:
           carga.cur.execute(
               "INSERT INTO salud.hospital (nombre, carga_id) VALUES (%s, %s)",
               ("Hospital General", carga.id),
           )
           carga.filas_insertadas += carga.cur.rowcount

   if __name__ == "__main__":
       main()
   ```

3. Probar ejecución del script por su cuenta o por su módulo completo:

   ```bash
   python etl/python/salud/<timestamp>_load_hospitales.py
   bash scripts/run.sh --etl -m salud
   ```

Si el proceso ETL genera SQL o algún otro script que sea útil versionar, se puede guardar en `scripts/generated/<modulo>/` (ver el ETL de geografía como referencia).

### Crear un script de utilidades

Los scripts de utilidad (por ejemplo, generar documentación o hacer una verificación) no llevan prefijo de timestamp, 
para que el orquestador de ETL los ignore.

- Si estos scripts necesitan la base, se pueden ubicar junto al código Python de etl (por ejemplo en `etl/python/meta/`)
  para poder importar `config` con el mismo arranque que usan los ETL. Ejemplo existente: `etl/python/meta/generar_diccionario.py`.
- Si son utilidades de shell o SQL sueltas, es mejor ubicarlas en `scripts/`.

### Regenerar el diccionario

Después de aplicar migraciones que agreguen o cambien comentarios:

```bash
python etl/python/meta/generar_diccionario.py
# o
scripts/run.sh --dict 
```

Esto sobreescribe `docs/diccionario.md` a partir de la vista `meta.diccionario`.

---

## Comandos utiles

| Accion                                       | Comando                                                                         |
|----------------------------------------------|---------------------------------------------------------------------------------|
| Preparar dependencias de Python              | `python -m venv etl/python/.venv && pip install -r etl/python/requirements.txt` |
| Crear base, usuarios y extensiones (una vez) | `bash scripts/init_db.sh`                                                       |
| Migraciones + ETL                            | `bash scripts/run.sh`                                                           |
| Solo migraciones                             | `bash scripts/run.sh --migrate`                                                 |
| Solo ETL                                     | `bash scripts/run.sh --etl`                                                     |
| ETL de un modulo                             | `bash scripts/run.sh --etl -m <modulo>`                                         |
| Ver el plan del ETL sin ejecutarlo           | `bash scripts/run.sh --etl --list`                                              |
| Nueva migracion                              | `bash scripts/new.sh migration <carpeta> <descripcion>`                         |
| Nuevo proceso ETL                            | `bash scripts/new.sh etl <carpeta> <descripcion>`                               |
| Regenerar el diccionario                     | `python etl/python/meta/generar_diccionario.py`                                 |

`new.sh` acepta además `--ts YYYYMMDDHHMMSS` para fijar el timestamp (util para emparejar un ETL con la migración correspondiente).

---

## Recomendaciones

- Se recomienda el uso de `new.sh` para crear migraciones y ETL, para asegurar el cumplimiento de la nomenclatura.
- Mantener las migraciones pequeñas y con un solo propósito claro.
- Nunca editar una migración ya aplicada en un entorno compartido; crear una nueva.
- Escribir ETL idempotentes para poder re-ejecutarlos con seguridad.
- Especificar siempre el esquema y comentar todo objeto nuevo de la base de datos.
- Registrar la fuente antes de cargar datos que dependan de ella.
- Antes del Pull Request, ejecutar el flujo completo en una base limpia y regenera el diccionario si hubo cambios de comentarios.

---

## Referencias

- [README](README.md): contexto del proyecto y como levantarlo.
- [Guía de instalación de dependencias](docs/Guia_instalacion_dependencias.md):
  PostgreSQL y Flyway por sistema operativo.
- [Diccionario de datos](docs/diccionario.md): estructura y descripción de todas las tablas.
- Guias especificas por carpeta:
  - [](data/README.md)
  - [](database/README.md)
  - [](diagrams/README.md)
  - [](docs/README.md)
  - [](etl/README.md)
  - [](scripts/README.md)
- Recursos externos: 
  - [Documentación de Flyway](https://documentation.red-gate.com/fd)
  - [Documentación de PostgreSQL](https://www.postgresql.org/docs/17/index.html)
