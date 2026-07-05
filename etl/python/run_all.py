#!/usr/bin/env python3
"""
Orquestador de procesos ETL — BD Nacional.

Descubre scripts ETL en las subcarpetas de este directorio y los ejecuta en
orden GLOBAL según el prefijo de timestamp del nombre de archivo, sin importar
en qué carpeta estén.

Convención de nombres:
    etl/python/<modulo>/<YYYYMMDDHHMMSS>_descripcion.py
    p.ej. etl/python/geografia/20260703120014_load_pais.py

El prefijo (timestamp de 14 dígitos) define el orden. Como es de ancho fijo,
el orden lexicográfico del nombre coincide con el cronológico y con el de
dependencias, porque una carga se escribe después de aquello de lo que depende.
Esto permite dependencias cruzadas entre módulos: el orden ya no es "carpeta por
carpeta", sino la secuencia real de timestamps.

Cada script se ejecuta como proceso independiente (igual que si se corriera a
mano). Por eso:
  - un fallo o un sys.exit() en un script no tumba al orquestador,
  - no hay fuga de estado entre scripts,
  - cada script debe ser ejecutable por su cuenta (tener su propio main()).

Uso:
    python run_all.py                      # todos, en orden global por timestamp
    python run_all.py --module geografia   # solo esa carpeta (recursivo), en orden
    python run_all.py --stop-on-error      # aborta al primer fallo
    python run_all.py --list               # muestra el plan sin ejecutar nada
"""

from __future__ import annotations

import argparse
import logging
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("etl")

ETL_ROOT = Path(__file__).resolve().parent

# Un script ETL válido empieza con el timestamp de 14 dígitos y un separador "_".
# Esto excluye automáticamente a config.py, run_all.py, __init__.py, etc.
SCRIPT_RE = re.compile(r"^\d{14}_.*\.py$")


def _is_hidden(path: Path) -> bool:
    """True si alguna parte de la ruta (relativa a ETL_ROOT) es oculta (.venv, .git...)."""
    return any(part.startswith(".") for part in path.relative_to(ETL_ROOT).parts)


def discover(module: str | None = None) -> list[Path]:
    """
    Retorna los scripts ETL a ejecutar, ordenados por su prefijo de timestamp
    (orden global, sin importar la carpeta).

    Si `module` se indica, restringe la búsqueda a esa subcarpeta (recursiva).
    """
    base = ETL_ROOT / module if module else ETL_ROOT
    if module and not base.is_dir():
        raise SystemExit(f"El módulo '{module}' no existe en {ETL_ROOT}")

    scripts = [
        p
        for p in base.rglob("*.py")
        if SCRIPT_RE.match(p.name) and not _is_hidden(p)
    ]
    # El prefijo timestamp es de ancho fijo, así que ordenar por nombre basta.
    # Se desempata por ruta para que el orden sea determinista.
    scripts.sort(key=lambda p: (p.name, str(p)))
    return scripts


def run_script(script: Path) -> bool:
    """Ejecuta un script como proceso independiente. True si termina con código 0."""
    rel = script.relative_to(ETL_ROOT)
    log.info(f"  -> {rel}")

    # Garantiza que el script pueda `import config` sin importar el CWD.
    env = os.environ.copy()
    env["PYTHONPATH"] = os.pathsep.join(
        filter(None, [str(ETL_ROOT), env.get("PYTHONPATH", "")])
    )

    result = subprocess.run([sys.executable, str(script)], env=env)
    if result.returncode != 0:
        log.error(f"     x {rel} terminó con código {result.returncode}")
        return False
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Orquestador ETL BD Nacional")
    parser.add_argument(
        "--module", "-m",
        help="Ejecutar solo los scripts de esta carpeta (p.ej. geografia).",
    )
    parser.add_argument(
        "--stop-on-error", action="store_true",
        help="Abortar al primer script que falle.",
    )
    parser.add_argument(
        "--list", action="store_true",
        help="Mostrar el orden de ejecución sin ejecutar nada.",
    )
    args = parser.parse_args()

    scripts = discover(args.module)

    if not scripts:
        donde = f"el módulo '{args.module}'" if args.module else "etl/python"
        log.warning(f"No se encontraron scripts ETL en {donde}.")
        return

    if args.list:
        log.info(f"Plan de ejecución ({len(scripts)} scripts):")
        for s in scripts:
            print(f"  {s.relative_to(ETL_ROOT)}")
        return

    alcance = f"módulo '{args.module}'" if args.module else "todos los módulos"
    log.info(f">>>> ETL BD Nacional — {alcance} — {len(scripts)} scripts")

    start = datetime.now()
    ok = failed = 0

    for script in scripts:
        if run_script(script):
            ok += 1
        else:
            failed += 1
            if args.stop_on_error:
                log.error("--stop-on-error activo. Abortando.")
                break

    elapsed = (datetime.now() - start).seconds
    log.info(f"Completado en {elapsed}s — {ok} exitosos, {failed} fallidos")

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
