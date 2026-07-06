#!/usr/bin/env python3
"""
Pre-ETL script to transform PDF recipe books (converted to text) into structured CSV files.
Parses the layout-preserved texts, extracts recipes, resolves PCodes, and writes them.
"""

from __future__ import annotations

import csv
import re
import sys
import unicodedata
from pathlib import Path

# Add python path for database connection configuration
def _repo_root() -> Path:
    for parent in Path(__file__).resolve().parents:
        if (parent / ".env").exists() or (parent / "scripts").is_dir():
            return parent
    return Path(__file__).resolve().parents[1]

REPO_ROOT = _repo_root()
sys.path.insert(0, str(REPO_ROOT / "etl" / "python"))

from config import get_connection

def clean_str(s: str) -> str:
    """Normalizes string for comparison by removing accents and lowercasing."""
    if not s:
        return ""
    return "".join(
        c for c in unicodedata.normalize("NFD", s)
        if unicodedata.category(c) != "Mn"
    ).lower().strip()

# List of Guatemalan traditional dishes to extract from the PDFs
TARGET_DISHES = {
    # Recetario-F.pdf (Ruta Gastronómica)
    "bacha' de pescado": "Bacha' de pescado",
    "bebida de chunak": "Bebida de Chunak",
    "juybil pur": "Juybil Pur",
    "kaq' ik": "Kaq'ik",
    "b'eleb taas": "B'eleb taas",
    "pinol de rabinal": "Pinol de Rabinal",
    "caldo de gallina criolla con hoja de chaya": "Caldo de gallina criolla con hoja de chaya",
    "pak'to'": "Pak'to'",
    "boxboles": "Boxboles",
    "patin": "Patín",
    "caldo de gallina criolla colorado": "Caldo de gallina criolla colorado",
    "chojin": "Chojín",
    "atol suchi o ixchu'n ja'": "Atol suchi o Ixchu'n ja'",
    "shecas de santa maria": "Shecas de Santa María",
    "tob' ik": "Tob'ik",
    "yuca con chicharron": "Yuca con chicharrón",
    "tapado": "Tapado",
    "coche relleno": "Coche relleno",
    "gallina en crema y loroco": "Gallina en crema y loroco",
    "caldo de bodas": "Caldo de bodas",
    "estofado": "Estofado",
    "k'aj": "K'äj (Pinol Blanco)",
    "pepian": "Pepián",
    "entomillado": "Entomillado",
    "fiambre rojo": "Fiambre rojo",
    "platanos en mole": "Plátanos en mole",
    "pepian de tres carnes": "Pepián de tres carnes",
    "piloyada antigueña": "Piloyada antigüeña",

    # VOL-2 (Bebidas)
    "agulangu": "Agulangu",
    "arroz con chocolate": "Arroz con chocolate",
    "arroz en leche": "Arroz en leche",
    "atol blanco": "Atol blanco",
    "atol de elote": "Atol de elote",
    "atol de haba": "Atol de haba",
    "atol de tres cocimientos": "Atol de tres cocimientos",
    "atolillo": "Atolillo",
    "batido": "Batido",
    "boj": "Boj",
    "cafe artesanal": "Café artesanal",
    "caldo de frutas": "Caldo de frutas",
    "chinchivir": "Chinchivir",
    "chocolate artesanal": "Chocolate artesanal",
    "chilate": "Chilate",
    "chilacayote": "Fresco de Chilacayote",
    "horchata": "Horchata",
    "jamaica con limon": "Fresco de Jamaica con limón",

    # VOL-3 (Dulces)
    "ayote en dulce": "Ayote en dulce",
    "alboroto": "Alboroto",
    "bocado de la reina": "Bocado de la reina",
    "bolitas de leche": "Bolitas de leche",
    "bolitas de tamarindo": "Bolitas de tamarindo",
    "buñuelos": "Buñuelos",
    "camote en dulce": "Camote en dulce",
    "cascos de naranja": "Cascos de naranja",
    "dulce de semillas": "Dulce de semillas",
    "chupetes": "Chupetes",
    "cocada horneada": "Cocada horneada",
    "coyoles en miel": "Coyoles en miel",
    "cuadritos de zapote": "Cuadritos de zapote",
    "empanadas de hierbas y vegetales": "Empanadas de hierbas y vegetales",
    "empanadas de leche": "Empanadas de leche",
    "empanadas de salpor": "Empanadas de salpor",
    "espumillas": "Espumillas",
    "güicoyitos en leche": "Güicoyitos en leche",

    # VOL-4 (Tamales)
    "bollitos peteneros": "Bollitos peteneros",
    "chuchitos": "Chuchitos",
    "chuchitos de salpor": "Chuchitos de salpor",
    "marilas": "Marilas",
    "paches": "Paches",
    "tamalito de chipilin y chicharron": "Tamalito de chipilín y chicharrón",
    "tamal torteado": "Tamal torteado",
    "tamal de arroz": "Tamal de arroz",
    "tamales colorados": "Tamales colorados",
    "tamales negros": "Tamales negros",
    "tamales de viaje": "Tamales de viaje",
    "tamalito pooch": "Tamalito pooch",
    "tamalitos blancos": "Tamalitos blancos",
    "tamalitos de chipilin": "Tamalitos de chipilín",
    "tamalitos de elote": "Tamalitos de elote",
    "tamalitos de güicoy tierno": "Tamalitos de güicoy tierno",
    "tamalitos de vegetales con queso": "Tamalitos de vegetales con queso",
    "tamalitos de loroco con queso": "Tamalitos de loroco con queso",

    # VOL-5 (Recados)
    "bacalao a la vizcaina": "Bacalao a la vizcaína",
    "caldo de cordero": "Caldo de cordero",
    "caldo de pata": "Caldo de pata",
    "caldo de res": "Caldo de res",
    "cerdo ahumado": "Cerdo ahumado",
    "chiles rellenos": "Chiles rellenos",
    "chirmol con marrano": "Chirmol con marrano",
    "choka'": "Choka'",
    "estofado de res": "Estofado de res",
    "frijoles blancos con pescaditos": "Frijoles blancos con pescaditos (pepesca)",
    "frijoles colorados con chicharron": "Frijoles colorados con chicharrón",
    "frijoles con quequesque": "Frijoles con quequesque",
    "frito": "Frito",
    "gallo en chicha": "Gallo en Chicha",
    "hilachas": "Hilachas",
    "jocon de pollo": "Jocón de pollo",
    "mole de pollo": "Mole de pollo",
    "muxque": "Muxque",
    "ollada marquense": "Ollada marquense",
    "pollo en iwaxte": "Pollo en iwaxte",
    "pulique": "Pulique",
    "quichom": "Quichom",
    "rabo guisado": "Rabo guisado",
    "revolcado": "Revolcado",
    "sopa de arroz con chipilin": "Sopa de arroz con chipilín",
    "sopa de quilete": "Sopa de quilete",
    "suban'ik": "Suban'ik",
    "tikini": "Tikini",
    "tiras de panza en amarillo": "Tiras de panza en amarillo"
}

# Known key ingredients to extract and link to dishes
KNOWN_INGREDIENTS = {
    "cacao": "Cacao",
    "pepitoria": "Pepitoria",
    "ajonjoli": "Ajonjolí",
    "chile cobanero": "Chile Cobanero",
    "miltomate": "Miltomate",
    "achiote": "Achiote",
    "maiz": "Maíz",
    "frijol": "Frijol Negro",
    "arroz": "Arroz",
    "canela": "Canela",
    "chile pimiento": "Chile Pimiento",
    "chile guaque": "Chile Guaque",
    "chile pasa": "Chile Pasa",
    "platano": "Plátano",
    "pan frances": "Pan Francés",
    "chipilin": "Chipilín",
    "loroco": "Loroco",
    "pollo": "Pollo",
    "gallina": "Gallina",
    "res": "Carne de Res",
    "cerdo": "Carne de Cerdo",
    "cordero": "Carne de Cordero",
    "pescado": "Pescado",
    "tilapia": "Tilapia",
    "camaron": "Camarón",
    "jaiba": "Jaiba",
    "tomate": "Tomate",
    "cebolla": "Cebolla",
    "ajo": "Ajo"
}

def main():
    print("=== Conectando a la Base de Datos para Obtener Geografía ===")
    conn = get_connection()
    cur = conn.cursor()
    
    # 1. Obtener departamentos
    cur.execute("SELECT nombre, pcode FROM geografia.departamento")
    depto_lookup = {}
    for name, pcode in cur.fetchall():
        depto_lookup[clean_str(name)] = pcode
        
    # 2. Obtener municipios con su departamento
    cur.execute("""
        SELECT m.nombre, m.pcode, d.nombre 
        FROM geografia.municipio m
        JOIN geografia.departamento d ON m.departamento_id = d.id
    """)
    muni_lookup = {}
    for m_name, m_pcode, d_name in cur.fetchall():
        # Map both by (muni_name, depto_name) and just muni_name as fallback
        muni_lookup[(clean_str(m_name), clean_str(d_name))] = m_pcode
        muni_lookup[clean_str(m_name)] = m_pcode
        
    conn.close()
    
    print("Cargando archivos de texto y parseando recetas...")
    texts_dir = REPO_ROOT / "data" / "cultura" / "extracted_texts"
    files = sorted(texts_dir.glob("*.txt"))
    
    extracted_dishes = []
    extracted_ingredients_map = {}
    extracted_plato_ingredientes = []
    
    # Pre-populate known ingredients
    for key, name in KNOWN_INGREDIENTS.items():
        extracted_ingredients_map[name] = {
            "nombre": name,
            "descripcion": f"Ingrediente tradicional ({name}) extraído de las recetas de gastronomía.",
            "origen_prehispanico": "true" if key in ["cacao", "pepitoria", "chile cobanero", "miltomate", "achiote", "maiz", "frijol", "tomate", "chile guaque", "chile pasa", "chipilin", "loroco"] else "false"
        }
        
    for file_path in files:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        pages = content.split("\x0c")
        
        for page_num, p in enumerate(pages):
            ing_proc_match = re.search(r"Ingredientes\s+Procedimiento", p, re.IGNORECASE) or re.search(r"Ingredientes\s+Preparacion", p, re.IGNORECASE) or re.search(r"Ingredientes\s+Procedmiento", p, re.IGNORECASE)
            if not ing_proc_match:
                continue
                
            # Find where Procedimiento starts
            line_start = p.rfind("\n", 0, ing_proc_match.start()) + 1
            line_end = p.find("\n", ing_proc_match.end())
            header_line = p[line_start:line_end]
            idx_proc = header_line.find("Procedimiento")
            if idx_proc == -1:
                idx_proc = header_line.find("Preparacion")
            if idx_proc == -1:
                idx_proc = header_line.find("Procedmiento")
            if idx_proc == -1:
                idx_proc = 35 # Default splitting index
                
            lines = [l.strip() for l in p.split("\n")]
            non_empty = [l for l in lines if l]
            
            # Geography parsing
            depto = None
            muni = None
            geo_idx = -1
            
            for idx in range(min(5, len(non_empty))):
                l_clean = clean_str(non_empty[idx])
                # Check for exact department match
                matched_depto_key = next((d for d in depto_lookup if d == l_clean), None)
                if matched_depto_key:
                    depto = depto_lookup[matched_depto_key]
                    geo_idx = idx
                    if idx > 0 and clean_str(non_empty[idx-1]) not in depto_lookup:
                        muni = non_empty[idx-1]
                    elif idx + 1 < len(non_empty) and clean_str(non_empty[idx+1]) not in depto_lookup and "ingredientes" not in clean_str(non_empty[idx+1]):
                        muni = non_empty[idx+1]
                        geo_idx = idx + 1
                    break
            
            # Fallback geography check anywhere on page if not found at top
            if not depto:
                for idx, l in enumerate(non_empty):
                    l_clean = clean_str(l)
                    if l_clean in depto_lookup:
                        depto = depto_lookup[l_clean]
                        break
                        
            # Recipe Title extraction
            title_idx = geo_idx + 1 if depto else 0
            if title_idx < len(non_empty):
                title = non_empty[title_idx]
                if "Rinde:" in title or "Ingredientes" in title:
                    title = non_empty[0]
            else:
                title = non_empty[0]
                
            if re.match(r"^\d+$", title) or len(title) < 3:
                continue
                
            # Match title to a target dish
            clean_title = clean_str(title)
            matched_dish_name = TARGET_DISHES.get(clean_title)
            if not matched_dish_name:
                # Try partial match (e.g. "Jocón de pollo" matches "Jocón")
                matched_dish_name = next((val for key, val in TARGET_DISHES.items() if key in clean_title or clean_title in key), None)
                
            if not matched_dish_name:
                continue # Skip if it doesn't match any known dish
                
            # Description extraction
            desc_lines = []
            for idx in range(title_idx + 1, len(non_empty)):
                l = non_empty[idx]
                if "Rinde:" in l or "Ingredientes" in l or "Procedimiento" in l or "Preparacion" in l:
                    break
                desc_lines.append(l)
            desc = " ".join(desc_lines)
            if not desc:
                desc = f"Guiso tradicional de la gastronomía de Guatemala: {matched_dish_name}."
                
            # Left-column Ingredients extraction
            ingredients_extracted = []
            lines_raw = p.split("\n")
            header_idx = -1
            for idx, l in enumerate(lines_raw):
                if "Ingredientes" in l:
                    header_idx = idx
                    break
                    
            for l in lines_raw[header_idx+1:]:
                if not l.strip():
                    continue
                left_side = l[:idx_proc].strip()
                if left_side:
                    # Skip page numbers, author names or bottom elements
                    if re.match(r"^\d+$", left_side) or "Rinde:" in left_side or "Tiempo de" in left_side:
                        continue
                    if any(author in left_side for author in ["Marisela", "Hercilia", "Ana Iris", "Hercilia Ramos", "Méndez", "Pérez", "Ovalle", "Tzoc"]):
                        continue
                    ingredients_extracted.append(left_side)
                    
            # Identify and map individual ingredients
            desc_with_ingredients = desc + " | Ingredientes: " + ", ".join(ingredients_extracted)
            
            # Map geography codes
            depto_pcode = depto if depto else ""
            muni_pcode = ""
            if muni:
                muni_clean = clean_str(muni)
                # Try combined lookup (muni_name, depto_name)
                depto_name = next((k for k, v in depto_lookup.items() if v == depto), "")
                muni_pcode = muni_lookup.get((muni_clean, depto_name), muni_lookup.get(muni_clean, ""))
                
            # Set es_patrimonio = True for top 5 heritage dishes
            es_patrimonio = "true" if matched_dish_name in ["Pepián", "Kaq'ik", "Jocón de pollo", "Plátanos en mole", "Pinol de Rabinal"] else "false"
            
            extracted_dishes.append({
                "nombre": matched_dish_name,
                "descripcion": desc_with_ingredients,
                "historia_origen": desc,
                "es_patrimonio": es_patrimonio,
                "departamento_pcode": depto_pcode,
                "municipio_pcode": muni_pcode
            })
            
            # Link matched ingredients
            for ing_line in ingredients_extracted:
                ing_clean = clean_str(ing_line)
                for key, name in KNOWN_INGREDIENTS.items():
                    if key in ing_clean:
                        extracted_plato_ingredientes.append({
                            "plato_nombre": matched_dish_name,
                            "ingrediente_nombre": name
                        })
                        
    # Deduplicate plato-ingredientes relations
    unique_plato_ingredientes = []
    seen_pi = set()
    for pi in extracted_plato_ingredientes:
        key = (pi["plato_nombre"], pi["ingrediente_nombre"])
        if key not in seen_pi:
            seen_pi.add(key)
            unique_plato_ingredientes.append(pi)
            
    # Deduplicate dishes by name
    unique_dishes = []
    seen_dishes = set()
    for d in extracted_dishes:
        if d["nombre"] not in seen_dishes:
            seen_dishes.add(d["nombre"])
            unique_dishes.append(d)
            
    # Write to platos_tipicos.csv
    print(f"\nGuardando {len(unique_dishes)} platos típicos en platos_tipicos.csv...")
    with open(REPO_ROOT / "data" / "cultura" / "platos_tipicos.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["nombre", "descripcion", "historia_origen", "es_patrimonio", "departamento_pcode", "municipio_pcode"])
        for d in unique_dishes:
            writer.writerow([d["nombre"], d["descripcion"], d["historia_origen"], d["es_patrimonio"], d["departamento_pcode"], d["municipio_pcode"]])
            
    # Write to ingredientes.csv
    print(f"Guardando {len(extracted_ingredients_map)} ingredientes en ingredientes.csv...")
    with open(REPO_ROOT / "data" / "cultura" / "ingredientes.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["nombre", "descripcion", "origen_prehispanico"])
        for name, ing in extracted_ingredients_map.items():
            writer.writerow([ing["nombre"], ing["descripcion"], ing["origen_prehispanico"]])
            
    # Write to plato_ingredientes.csv
    print(f"Guardando {len(unique_plato_ingredientes)} relaciones de ingredientes en plato_ingredientes.csv...")
    with open(REPO_ROOT / "data" / "cultura" / "plato_ingredientes.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["plato_nombre", "ingrediente_nombre"])
        for pi in unique_plato_ingredientes:
            writer.writerow([pi["plato_nombre"], pi["ingrediente_nombre"]])
            
    print("\n=== Extracción y Transformación de PDFs Finalizada ===")

if __name__ == "__main__":
    main()
