# Datos Fuente - Policía Nacional Civil (PNC)

## Descripción

Como parte del dominio de **Justicia** del proyecto **Conoce Guate**, se incorporó información pública proveniente de la **Policía Nacional Civil (PNC)** de Guatemala. Esta fuente proporciona datos estadísticos relacionados con la actividad delictiva registrada por la institución, permitiendo analizar el comportamiento de los delitos desde la perspectiva policial y complementando la información obtenida del Organismo Judicial y del Ministerio Público.

Los conjuntos de datos utilizados contienen información agregada, por lo que no incluyen datos personales de las víctimas o de las personas detenidas. En su lugar, registran variables de carácter estadístico como el tipo de delito, la fecha del incidente, la ubicación geográfica y otros atributos que permiten realizar análisis sobre la incidencia delictiva en el país.

## Conjuntos de datos utilizados

Para esta primera versión del proyecto se utilizaron los registros correspondientes al año **2023**, organizados en dos conjuntos principales:

* **Víctimas:** contiene información estadística sobre las personas afectadas por hechos delictivos, incluyendo variables como el tipo de delito, la fecha del incidente y la ubicación donde ocurrió.

* **Detenidos:** reúne información relacionada con las personas detenidas por la Policía Nacional Civil, incorporando datos como el delito asociado, la fecha del registro y otros atributos de interés para el análisis de la actividad policial.

La integración de ambos conjuntos permite generar indicadores relacionados con la incidencia delictiva, la distribución territorial de los delitos y la evolución de los registros a lo largo del tiempo, proporcionando una visión complementaria a la información obtenida de otras instituciones del sector justicia.

## Estructura de los datos

La organización de los archivos es la siguiente:

```text
PNC/
└── 2023/
    ├── Detenidos.csv
    └── Victimas.csv
```

## Fuente de los datos

Los archivos utilizados para este dominio pueden consultarse en el siguiente repositorio:

**Google Drive:**

https://drive.google.com/drive/folders/1-Np2kzrn9wqL00cRmmvbc6r4O6w99PSG?usp=drive_link

> **Nota:** La información utilizada corresponde a los datos públicos disponibles al momento del desarrollo del proyecto. Al igual que las demás fuentes integradas en el ODS, el modelo de datos fue diseñado para facilitar la incorporación de nuevos períodos y conjuntos de información que la Policía Nacional Civil publique en el futuro.
