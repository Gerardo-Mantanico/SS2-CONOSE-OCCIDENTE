# etl/python

Procesos de extracción, transformación y carga (ETL) escritos en Python. Cada
proceso lee de una fuente, transforma los datos y los carga en la base, registrando la ejecución en `meta.carga`.

En las versiones iniciales el ETL se maneja solo con Python, por eso el código vive bajo `etl/python/`. 
Si a futuro se agrega otra tecnología, tendrá su propia sub-carpeta hermana dentro de `etl/`.

```
etl/python/
|-- config.py         conexión compartida y registro de cargas
|-- requirements.txt  dependencias de Python
|-- run_all.py        orquestador de los procesos ETL
`-- {modulo}/         scripts de carga por dominio (geografia, meta, ...)
```

---

## Entorno virtual

Crear el entorno virtual (una vez):

```bash
python -m venv etl/python/.venv
```

Activarlo (cada vez que se vaya a trabajar con el ETL):

```bash
source etl/python/.venv/bin/activate
```

Instalar las dependencias:

```bash
pip install -r etl/python/requirements.txt
```

---

## requirements.txt

Lista las dependencias de Python del ETL (actualmente `psycopg2-binary`,
`python-dotenv` y `openpyxl`).

Cuando un script nuevo necesite un paquete que no esté en la lista, agregar ese
paquete a `requirements.txt` (idealmente con su versión) y volver a instalar. 
Así cualquier persona que clone el proyecto obtiene el mismo entorno. 
No depender de paquetes instalados solo en la máquina propia.

---

## Nomenclatura de los scripts

Los scripts de carga se nombran con un prefijo de timestamp:

```
etl/python/{modulo}/<YYYYMMDDHHMMSS>_<descripcion>.py
```

Ejemplo: `etl/python/geografia/20260703140000_load_admin_boundaries.py`.

- El prefijo de 14 dígitos define el orden de ejecución.
- El orden es global: los scripts se ejecutan por su timestamp sin importar la
  carpeta, lo que permite dependencias entre módulos.

Generar los scripts con el generador para no equivocarse con el nombre:

```bash
bash scripts/new.sh etl geografia load_departamentos
```

### Scripts de utilidad

Los scripts que necesitan vivir aquí, pero no son procesos de carga (por ejemplo,
generar documentación) no llevan prefijo de timestamp. Así el orquestador los
ignora y no los ejecuta como parte del ETL. Ejemplo:
`etl/python/meta/generar_diccionario.py`.

---

## Documentar cada script

Todo script debe estar bien documentado internamente: un docstring al inicio que
explique qué hace, de qué fuente lee y qué tablas puebla, y comentarios en los
puntos donde la lógica no sea evidente. Un colaborador nuevo debería entender el
proceso leyendo el archivo, sin tener que reconstruirlo.

---

## Scripts principales

### config.py

Utilidades compartidas por todos los procesos:

- `get_connection()`: devuelve una conexión a la base leyendo la configuración
  del `.env` (usa `DATABASE_URL` o, en su defecto, las variables `DB_*`) y fija
  la codificación en UTF-8.
- `registrar_carga(codigo_fuente, ...)`: context manager que registra la
  ejecución en `meta.carga` y entrega el campo `carga_id` para estampar en las tablas
  de dominio. Marca la carga como exitosa (o parcial si hubo filas rechazadas) al
  terminar, o fallida si ocurre un error, dejando siempre rastro. Falla si la
  fuente indicada no existe en `meta.fuente`, para mantener el catálogo curado.

Uso típico:

```python
from config import registrar_carga

def main():
    with registrar_carga("INE_CENSO_2018", archivo="data/censo.csv") as carga:
        carga.cur.execute(
            "INSERT INTO demografia.persona (nombre, carga_id) VALUES (%s, %s)",
            ("Juan", carga.id),
        )
        carga.filas_insertadas += carga.cur.rowcount

if __name__ == "__main__":
    main()
```

### run_all.py

Orquestador del ETL. Descubre de forma recursiva los scripts con prefijo de
timestamp en todas las carpetas y los ejecuta en orden global, cada uno como un
proceso independiente (un fallo en un script no tumba al resto). Opciones:

- `--module <modulo>` (o `-m`): ejecutar solo los scripts de esa carpeta.
- `--list`: mostrar el orden de ejecución sin ejecutar nada.
- `--stop-on-error`: abortar en el primer script que falle.

Normalmente, no se invoca directo, sino a través de `scripts/run.sh` (que activa el entorno virtual y ejecuta esta fase). 
Aun así, cada script se puede correr por su cuenta:

```bash
python etl/python/geografia/20260703140000_load_admin_boundaries.py
bash scripts/run.sh --etl -m geografia
```

---

## Referencias

- [`CONTRIBUTING.md`](../../CONTRIBUTING.md): flujo completo para crear un proceso ETL y agregar una fuente de datos.
- [`scripts/README.md`](../../scripts/README.md): detalle de `run.sh` y el resto de utilidades.
