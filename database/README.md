# database

Estructura de la base de datos: las migraciones versionadas y la configuración de Flyway. 
Todo cambio en el esquema de la base de datos vive aquí; la base nunca se modifica a mano.

```
database/
|-- flyway.conf        configuración de Flyway (sin credenciales)
`-- migrations/        una carpeta por esquema
    |-- meta/
    |-- geografia/
    |-- auditoria/
    `-- ...
```

---

## Cómo funciona Flyway

Flyway lleva el control de versiones del esquema. Cada migración es un archivo SQL que Flyway aplica una sola vez y en orden. 
Lo aplicado queda registrado en una tabla de historial (`flyway_schema_history`, en el esquema `meta`), junto a un checksum de cada archivo.

Consecuencias prácticas:

- Las versiones forman una única línea de tiempo global, sin importar en qué carpeta esté cada migración.
- Una migración ya aplicada no se edita: al cambiar su contenido cambia el checksum y Flyway falla. Para modificar algo, crear una migración nueva.
- Como cada archivo nuevo lleva el timestamp más alto, siempre se agrega al final de la secuencia.

Para aplicar las migraciones:

```bash
bash scripts/run.sh --migrate
```

---

## Nomenclatura de las migraciones

Cada migración se nombra así:

```
V<YYYYMMDDHHMMSS>__<descripcion>.sql
```

- La `V` indica que es una migración versionada.
- El bloque de 14 dígitos es un timestamp; define el orden de ejecución.
- El doble guion bajo separa la versión de la descripción.

Ejemplo: `V20260703120000__agregar_tabla_aldea.sql`.

Las migraciones se organizan en una carpeta por esquema dentro de `database/migrations/`. 
Flyway escanea esas carpetas de forma recursiva, así que agregar un esquema nuevo es
solo crear su carpeta y sus archivos, no hay que registrar nada en la configuración.

### Generar migraciones con new.sh

No escribir el nombre ni el timestamp a mano. Usar el generador, que crea el archivo bien nombrado (y la carpeta si no existe):

```bash
bash scripts/new.sh migration geografia agregar_tabla_aldea
```

Para la primera migración de un esquema, la plantilla ya incluye `CREATE SCHEMA IF NOT EXISTS <esquema>;`. 
El generador acepta además `--ts YYYYMMDDHHMMSS` para fijar el timestamp de forma manual.

---

## flyway.conf

Es la configuración de Flyway, sin credenciales. Lo relevante:

- `flyway.locations`: apunta a `filesystem:database/migrations` de forma recursiva. Por eso las carpetas por esquema se descubren solas.
- `flyway.schemas` / `flyway.defaultSchema`: `meta`. Flyway crea el esquema `meta` donde vive su tabla de historial;
  los demás esquemas son creados desde sus propias migraciones con `CREATE SCHEMA IF NOT EXISTS`.

Las credenciales (URL, usuario y contraseña) se pasan por variables de entorno
(`FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD`), nunca dentro del `.conf`.

---

## Convenciones al escribir migraciones

- Especificar siempre el esquema al nombrar objetos: `geografia.pais`, no solo`pais`. No depender del `search_path` ya que al ejecutarse con flyway caerá erróneamente en el schema `meta`.
- En la primera migración de un esquema, crearlo con `CREATE SCHEMA IF NOT EXISTS <esquema>;`.
- Si una tabla guarda datos de dominio, agregar la columna de trazabilidad `carga_id INT REFERENCES meta.carga(id)`.
- No editar una migración ya aplicada en un entorno compartido; crear una nueva.

### Comentar todos los objetos

Documentar cada objeto con `COMMENT ON` en la misma migración que lo crea. 
Es obligatorio para tablas y columnas, porque de esos comentarios se genera el diccionario de la base (`meta.diccionario` produce `docs/diccionario.md`): 
una columna sin comentario aparece sin descripción.

Comentar los demás objetos (restricciones, índices, vistas, funciones, el propio esquema) no es obligatorio, pero tampoco hace daño y ayuda a entender el modelo.

```sql
CREATE TABLE geografia.aldea (
    id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    municipio_id   INT NOT NULL REFERENCES geografia.municipio(id),
    carga_id       INT REFERENCES meta.carga(id)
);

COMMENT ON TABLE  geografia.aldea            IS 'Aldeas, cuelgan de un municipio.';
COMMENT ON COLUMN geografia.aldea.nombre     IS 'Nombre de la aldea.';
COMMENT ON COLUMN geografia.aldea.municipio_id IS 'Municipio al que pertenece.';
```

---

## Referencias

- [`CONTRIBUTING.md`](../CONTRIBUTING.md): flujos completos para agregar tablas, esquemas y dependencias entre esquemas.
- [`docs/diccionario.md`](../docs/diccionario.md): diccionario generado desde los comentarios.
