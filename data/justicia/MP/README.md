# Datos Fuente - Ministerio Público (MP)

## Descripción

Como parte del dominio de **Justicia** del proyecto **Conoce Guate**, se integró información pública proveniente del **Ministerio Público (MP)** de Guatemala. Esta fuente proporciona datos estadísticos relacionados con las denuncias registradas por la institución, permitiendo analizar la incidencia delictiva, el comportamiento de los casos y la distribución de los actores involucrados.

A diferencia de otras instituciones del sector justicia, el Ministerio Público no publica de forma abierta información relacionada con la nómina de su personal, debido a que este tipo de información no se encuentra disponible dentro de los conjuntos de datos consultados. Por ello, el proyecto se centra en la información estadística de los procesos penales, la cual resulta de mayor utilidad para los objetivos analíticos de la plataforma.

## Conjuntos de datos utilizados

Para esta primera versión del proyecto se utilizaron los registros correspondientes al año **2023**, los cuales se encuentran organizados en dos conjuntos principales:

* **Agraviados:** contiene información estadística de las personas afectadas por hechos delictivos, incluyendo variables como el tipo de delito, fecha de registro, ubicación geográfica y otros atributos de interés.

* **Sindicados:** reúne información relacionada con las personas señaladas dentro de los procesos penales, incorporando datos como el tipo de delito, estado del caso, fecha de registro y demás características relevantes para el análisis de la actividad delictiva.

Estos conjuntos de datos permiten realizar análisis sobre la distribución de delitos, la evolución temporal de los casos y su comportamiento en diferentes regiones del país, complementando la información obtenida del Organismo Judicial.

## Estructura de los datos

La organización de los archivos es la siguiente:

```text
MP/
└── 2023/
    ├── Agraviados/
    └── Sindicados/
```

## Fuente de los datos

Los archivos utilizados para este dominio pueden consultarse en el siguiente repositorio:

**Google Drive:**

https://drive.google.com/drive/folders/1-LcB24wwzNrmX2vRgkC2kC789dPyKe7x?usp=drive_link

> **Nota:** La información utilizada corresponde a los conjuntos de datos públicos disponibles al momento de desarrollar el proyecto. En futuras versiones del ODS podrán incorporarse nuevos períodos o conjuntos de datos publicados por el Ministerio Público, permitiendo ampliar la cobertura histórica y mejorar los análisis realizados.
