#!/usr/bin/env python3
"""
Script de enriquecimiento para el catálogo de Idiomas y su distribución municipal en Guatemala.
Define los 24 idiomas nacionales (22 mayas, garífuna y xinka) y sus correspondencias
municipales basadas en el Mapa de Idiomas Nacionales oficial.
"""

from pathlib import Path
import csv

def main():
    repo_root = Path(__file__).resolve().parents[1]
    cultura_dir = repo_root / "data" / "cultura"
    cultura_dir.mkdir(parents=True, exist_ok=True)
    
    # 1. CATÁLOGO COMPLETO DE IDIOMAS NACIONALES DE GUATEMALA
    # Formato: nombre, familia_linguistica, estado_vitalidad, descripcion
    idiomas = [
        [
            "K'iche'", "Maya", "Vital",
            "El idioma maya con mayor número de hablantes en Guatemala, hablado en el altiplano central y occidental."
        ],
        [
            "Q'eqchi'", "Maya", "Vital",
            "Idioma maya con la mayor extensión territorial y rápido crecimiento, hablado principalmente en el norte y oriente."
        ],
        [
            "Kaqchikel", "Maya", "Vital",
            "Idioma maya del altiplano central, históricamente hablado por el reino Kaqchikel en Iximché."
        ],
        [
            "Mam", "Maya", "Vital",
            "Idioma maya de gran antigüedad hablado en el occidente del país, fronterizo con México."
        ],
        [
            "Poqomchi'", "Maya", "Vital",
            "Idioma maya hablado principalmente en Alta Verapaz, Baja Verapaz y El Quiché."
        ],
        [
            "Tz'utujil", "Maya", "Vital",
            "Idioma hablado en la cuenca del Lago de Atitlán en Sololá y Suchitepéquez."
        ],
        [
            "Ch'orti'", "Maya", "En peligro",
            "Idioma maya del oriente del país, estrechamente relacionado con el área arqueológica maya clásica."
        ],
        [
            "Achi'", "Maya", "Vital",
            "Idioma hablado en el departamento de Baja Verapaz, famoso por su obra de teatro del siglo XV Rabinal Achi'."
        ],
        [
            "Garífuna", "Arahuaca", "En peligro",
            "Idioma hablado por la comunidad de afrodescendientes garífunas en la costa atlántica (Izabal)."
        ],
        [
            "Xinka", "Aislada", "Crítico",
            "Familia de lenguas no mayas del suroriente de Guatemala con muy pocos hablantes fluidos actualmente."
        ],
        [
            "Akateko", "Maya", "Vital",
            "Idioma maya hablado principalmente en el noroccidente del departamento de Huehuetenango."
        ],
        [
            "Awakateko", "Maya", "Vital",
            "Idioma maya hablado en el municipio de Aguacatán, Huehuetenango."
        ],
        [
            "Chuj", "Maya", "Vital",
            "Idioma maya del norte de Huehuetenango, emparentado con las lenguas de la rama q'anjob'al."
        ],
        [
            "Ixil", "Maya", "Vital",
            "Idioma hablado en la región norcentral de El Quiché (triángulo Ixil: Nebaj, Chajul y Cotzal)."
        ],
        [
            "Jakalteko (Popti')", "Maya", "Vital",
            "Idioma maya hablado en la región huista de Huehuetenango, fronteriza con Chiapas."
        ],
        [
            "Q'anjob'al", "Maya", "Vital",
            "Idioma maya hablado en el altiplano de Huehuetenango, reconocido por su rica tradición oral."
        ],
        [
            "Sakapulteko", "Maya", "En peligro",
            "Idioma maya minoritario hablado en el municipio de Sacapulas, El Quiché."
        ],
        [
            "Sipakapense", "Maya", "En peligro",
            "Idioma maya minoritario hablado en el municipio de Sipacapa, San Marcos."
        ],
        [
            "Tektiteko", "Maya", "Crítico",
            "Idioma maya minoritario hablado en el municipio de Tectitán, Huehuetenango."
        ],
        [
            "Uspanteko", "Maya", "En peligro",
            "Idioma maya hablado en el municipio de Uspantán, El Quiché."
        ],
        [
            "Mopan", "Maya", "En peligro",
            "Idioma maya hablado en el oriente de Petén, colindante con Belice."
        ],
        [
            "Itza'", "Maya", "Crítico",
            "Idioma maya histórico del Petén, hablado en las cercanías del Lago Petén Itzá."
        ],
        [
            "Chalchiteko", "Maya", "Vital",
            "Idioma maya reconocido en 2003, hablado principalmente en el municipio de Aguacatán, Huehuetenango."
        ],
        [
            "Poqomam", "Maya", "Vital",
            "Idioma maya hablado en pequeñas comunidades dispersas en Guatemala, Jalapa y Escuintla."
        ]
    ]
    
    # 2. DISTRIBUCIÓN GEOGRÁFICA DE IDIOMAS POR MUNICIPIO (Mapeo oficial)
    # Formato: idioma_nombre, municipio_pcode, es_predominante
    idiomas_municipios = [
        # K'iche' (Altiplano)
        ["K'iche'", "GT0801", "true"],  # Totonicapán
        ["K'iche'", "GT0802", "true"],  # San Cristóbal Totonicapán
        ["K'iche'", "GT0803", "true"],  # San Francisco El Alto
        ["K'iche'", "GT0805", "true"],  # Momostenango
        ["K'iche'", "GT0806", "true"],  # Santa María Chiquimula
        ["K'iche'", "GT1401", "true"],  # Santa Cruz del Quiché
        ["K'iche'", "GT1402", "true"],  # Chiché
        ["K'iche'", "GT1406", "true"],  # Chichicastenango
        ["K'iche'", "GT1412", "true"],  # Joyabaj
        ["K'iche'", "GT0901", "false"], # Quetzaltenango (coexiste)
        ["K'iche'", "GT0912", "true"],  # Cantel
        ["K'iche'", "GT0705", "true"],  # Nahualá
        
        # Q'eqchi' (Norte, Oriente)
        ["Q'eqchi'", "GT1601", "true"],  # Cobán
        ["Q'eqchi'", "GT1609", "true"],  # San Pedro Carchá
        ["Q'eqchi'", "GT1610", "true"],  # San Juan Chamelco
        ["Q'eqchi'", "GT1611", "true"],  # Lanquín
        ["Q'eqchi'", "GT1612", "true"],  # Cahabón
        ["Q'eqchi'", "GT1613", "true"],  # Chisec
        ["Q'eqchi'", "GT1614", "true"],  # Chahal
        ["Q'eqchi'", "GT1615", "true"],  # Fray Bartolomé de las Casas
        ["Q'eqchi'", "GT1710", "true"],  # Sayaxché (Petén)
        ["Q'eqchi'", "GT1803", "true"],  # El Estor (Izabal)
        ["Q'eqchi'", "GT1508", "true"],  # Purulhá (Baja Verapaz)
        
        # Kaqchikel (Centro)
        ["Kaqchikel", "GT0401", "true"],  # Chimaltenango
        ["Kaqchikel", "GT0403", "true"],  # San Martín Jilotepeque
        ["Kaqchikel", "GT0404", "true"],  # Comalapa
        ["Kaqchikel", "GT0406", "true"],  # Tecpán Guatemala
        ["Kaqchikel", "GT0407", "true"],  # Patzún
        ["Kaqchikel", "GT0304", "true"],  # Sumpango
        ["Kaqchikel", "GT0306", "true"],  # Santiago Sacatepéquez
        ["Kaqchikel", "GT0311", "true"],  # Santa María de Jesús
        ["Kaqchikel", "GT0701", "false"], # Sololá (coexiste)
        ["Kaqchikel", "GT0110", "true"],  # San Juan Sacatepéquez
        ["Kaqchikel", "GT0109", "true"],  # San Pedro Sacatepéquez
        
        # Mam (Occidente)
        ["Mam", "GT1201", "true"],  # San Marcos
        ["Mam", "GT1202", "true"],  # San Pedro Sacatepéquez (San Marcos)
        ["Mam", "GT1204", "true"],  # Comitancillo
        ["Mam", "GT1206", "true"],  # Concepción Tutuapa
        ["Mam", "GT1207", "true"],  # Tacaná
        ["Mam", "GT1301", "true"],  # Huehuetenango
        ["Mam", "GT1306", "true"],  # San Pedro Necta
        ["Mam", "GT1309", "true"],  # Ixtahuacán
        ["Mam", "GT0918", "true"],  # San Martín Sacatepéquez (Quetzaltenango)
        
        # Poqomchi'
        ["Poqomchi'", "GT1604", "true"],  # Tactic
        ["Poqomchi'", "GT1605", "true"],  # Tamahú
        ["Poqomchi'", "GT1606", "true"],  # Tucurú
        ["Poqomchi'", "GT1508", "false"], # Purulhá (coexiste)
        
        # Tz'utujil (Lago de Atitlán)
        ["Tz'utujil", "GT0707", "true"],  # Santiago Atitlán
        ["Tz'utujil", "GT0708", "true"],  # San Pedro La Laguna
        ["Tz'utujil", "GT0716", "true"],  # San Juan La Laguna
        ["Tz'utujil", "GT1013", "true"],  # Chicacao
        
        # Ch'orti' (Oriente)
        ["Ch'orti'", "GT2004", "true"],  # Jocotán
        ["Ch'orti'", "GT2005", "true"],  # Camotán
        ["Ch'orti'", "GT2006", "true"],  # Olopa
        
        # Achi' (Baja Verapaz)
        ["Achi'", "GT1503", "true"],  # Rabinal
        ["Achi'", "GT1502", "true"],  # San Miguel Chicaj
        ["Achi'", "GT1504", "true"],  # Cubulco
        
        # Garífuna (Caribe)
        ["Garífuna", "GT1802", "true"],  # Lívingston
        ["Garífuna", "GT1801", "false"], # Puerto Barrios
        
        # Xinka (Suroriente)
        ["Xinka", "GT0608", "true"],  # Chiquimulilla
        ["Xinka", "GT0611", "true"],  # Guazacapán
        
        # Akateko
        ["Akateko", "GT1313", "true"],  # San Miguel Acatán
        ["Akateko", "GT1314", "true"],  # San Rafael La Independencia
        
        # Awakateko
        ["Awakateko", "GT1327", "true"], # Aguacatán
        
        # Chuj
        ["Chuj", "GT1318", "true"],  # San Mateo Ixtatán
        ["Chuj", "GT1305", "true"],  # Nentón
        
        # Ixil
        ["Ixil", "GT1413", "true"],  # Nebaj
        ["Ixil", "GT1405", "true"],  # Chajul
        ["Ixil", "GT1411", "true"],  # Cotzal
        
        # Jakalteko
        ["Jakalteko (Popti')", "GT1307", "true"],  # Jacaltenango
        ["Jakalteko (Popti')", "GT1322", "true"],  # Concepción Huista
        
        # Q'anjob'al
        ["Q'anjob'al", "GT1308", "true"],  # Soloma
        ["Q'anjob'al", "GT1317", "true"],  # Santa Eulalia
        ["Q'anjob'al", "GT1326", "true"],  # Barillas
        
        # Sakapulteko
        ["Sakapulteko", "GT1416", "true"], # Sacapulas
        
        # Sipakapense
        ["Sipakapense", "GT1226", "true"], # Sipacapa
        
        # Tektiteko
        ["Tektiteko", "GT1321", "true"],  # Tectitán
        
        # Uspanteko
        ["Uspanteko", "GT1415", "true"],  # Uspantán
        
        # Mopan
        ["Mopan", "GT1709", "true"],  # San Luis (Petén)
        ["Mopan", "GT1712", "true"],  # Poptún
        
        # Itza'
        ["Itza'", "GT1702", "true"],  # San José (Petén)
        
        # Chalchiteko
        ["Chalchiteko", "GT1327", "false"], # Aguacatán (coexiste con Awakateko)
        
        # Poqomam
        ["Poqomam", "GT0105", "true"],  # Palencia
        ["Poqomam", "GT0106", "true"],  # Chinautla
        ["Poqomam", "GT2103", "true"],  # San Luis Jilotepeque (Jalapa)
        ["Poqomam", "GT0511", "true"]   # Palín (Escuintla)
    ]
    
    # Escribir idiomas.csv
    print(f"Guardando {len(idiomas)} idiomas en idiomas.csv...")
    with open(cultura_dir / "idiomas.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["nombre", "familia_linguistica", "estado_vitalidad", "descripcion"])
        writer.writerows(idiomas)
        
    # Escribir idiomas_municipios.csv
    print(f"Guardando {len(idiomas_municipios)} relaciones de idiomas-municipios...")
    with open(cultura_dir / "idiomas_municipios.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["idioma_nombre", "municipio_pcode", "es_predominante"])
        writer.writerows(idiomas_municipios)
        
    print("Archivos CSV de Idiomas enriquecidos generados con éxito.")

if __name__ == "__main__":
    main()
