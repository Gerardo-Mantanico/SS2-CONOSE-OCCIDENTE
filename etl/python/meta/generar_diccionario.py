#!/usr/bin/env python3

"""
Genera o sobreescribe docs/diccionario.md a partir de la vista meta.diccionario.

Los COMMENT en la base de datos son la fuente de la verdad, se consultan desde la vista meta.diccionario
Ejecutar este script para regenerar el archivo cuando cambie el esquema.

El diccionario generado (docs/diccionario.md) se sube al repositorio para seguir sus cambios también.

El contenido es determinista, sin marcas de tiempo, así los diffs en git solo reflejan cambios reales del esquema.

Uso:
    python etl/python/meta/generar_diccionario.py
"""

from __future__ import annotations

import sys
from collections import OrderedDict
from pathlib import Path

# Permite importar config al correr el script directo.
for _p in Path(__file__).resolve().parents:
    if (_p / "config.py").exists():
        sys.path.insert(0, str(_p))
        break

from config import get_connection

SCRIPT_REL = "etl/python/meta/generar_diccionario.py"


def _repo_root() -> Path:
    for parent in Path(__file__).resolve().parents:
        if (parent / ".env").exists() or (parent / "docs").is_dir():
            return parent
    return Path(__file__).resolve().parents[3]


def _esc(s) -> str:
    """Escapa una celda de tabla Markdown."""
    if s is None:
        return ""
    return str(s).replace("\\", "\\\\").replace("|", "\\|").replace("\n", " ").strip()


def main() -> None:
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT esquema, tabla, comentario_tabla, columna, tipo, nullable,
                       por_defecto, es_pk, fk_referencia, comentario
                FROM meta.diccionario
                ORDER BY esquema, tabla, posicion
                """
            )
            filas = cur.fetchall()
    finally:
        conn.close()

    # Agrupar: esquema -> tabla -> {comentario, columnas[]}
    esquemas: "OrderedDict[str, OrderedDict]" = OrderedDict()
    for esq, tab, com_tab, col, tipo, nullable, deflt, es_pk, fk, com in filas:
        tablas = esquemas.setdefault(esq, OrderedDict())
        info = tablas.setdefault(tab, {"comentario": com_tab, "cols": []})
        info["cols"].append((col, tipo, nullable, deflt, es_pk, fk, com))

    out: list[str] = []
    out.append("# Diccionario de datos - Base de Datos Nacional\n")
    out.append(
        f"> Generado automáticamente desde la vista `meta.diccionario`. "
        f"No editar a mano; regenera con `python {SCRIPT_REL}`.\n"
    )

    # Índice
    out.append("## Contenido\n")
    for esq, tablas in esquemas.items():
        out.append(f"- **{esq}**: " + ", ".join(f"`{t}`" for t in tablas))
    out.append("")

    # Secciones
    for esq, tablas in esquemas.items():
        out.append(f"\n## Schema: `{esq}`\n")
        for tab, info in tablas.items():
            out.append(f"### `{esq}.{tab}`\n")
            if info["comentario"]:
                out.append(f"{info['comentario'].strip()}\n")
            out.append("| Columna | Tipo | Nulo | PK | FK | Default | Descripción |")
            out.append("|---|---|---|---|---|---|---|")
            for col, tipo, nullable, deflt, es_pk, fk, com in info["cols"]:
                out.append(
                    "| {} | {} | {} | {} | {} | {} | {} |".format(
                        _esc(col),
                        _esc(tipo),
                        "sí" if nullable else "no",
                        "X" if es_pk else "",
                        _esc(fk),
                        f"`{_esc(deflt)}`" if deflt else "",
                        _esc(com),
                    )
                )
            out.append("")

    md = "\n".join(out).rstrip() + "\n"

    docs = _repo_root() / "docs"
    docs.mkdir(parents=True, exist_ok=True)
    destino = docs / "diccionario.md"
    destino.write_text(md, encoding="utf-8")

    n_tablas = sum(len(t) for t in esquemas.values())
    print(f"Diccionario escrito: {destino}  ({len(filas)} columnas, {n_tablas} tablas)")


if __name__ == "__main__":
    main()