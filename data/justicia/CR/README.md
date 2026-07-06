# Datos Fuente - Congreso de la República (CR)

## Descripción

Como parte del dominio de **Justicia** del proyecto **Conoce Guate**, se integró información pública proveniente del **Congreso de la República de Guatemala**. Esta fuente proporciona datos relacionados con la nómina del personal que labora en la institución, permitiendo analizar la distribución de los recursos humanos y económicos dentro del organismo legislativo.

Los conjuntos de datos incluyen información sobre los trabajadores, el puesto que desempeñan, el renglón presupuestario al que pertenecen y la remuneración correspondiente. Esta información resulta de interés para la generación de indicadores relacionados con la administración pública, la transparencia institucional y el análisis de la distribución del gasto destinado al recurso humano.

## Conjuntos de datos utilizados

Para esta primera versión del proyecto se utilizaron los registros correspondientes al año **2023**, organizados según el renglón presupuestario de contratación:

* **Renglón 011:** Personal permanente.
* **Renglón 022:** Personal contratado por tiempo determinado.
* **Renglón 029:** Personal contratado por servicios técnicos o profesionales.

La separación por renglón presupuestario permite realizar análisis sobre la composición del personal, la distribución de los distintos tipos de contratación y la asignación de recursos económicos dentro de la institución.

## Estructura de los datos

La organización de los archivos es la siguiente:

```text
CR/
└── 2023/
    ├── Renglon_011/
    ├── Renglon_022/
    └── Renglon_029/
```

## Fuente de los datos

Los archivos utilizados para este dominio pueden consultarse en el siguiente repositorio:

**Google Drive:**

https://drive.google.com/drive/folders/1thOLlV4NTxoejBUpA7hHP1gJ9JJugXtd?usp=drive_link

> **Nota:** La información utilizada corresponde a los registros públicos disponibles del Congreso de la República al momento del desarrollo del proyecto. El modelo de datos fue diseñado para permitir la incorporación de nuevos períodos y actualizaciones de la información, facilitando la generación de análisis históricos y comparativos sobre la estructura del personal y la ejecución de recursos humanos.
