# Datos Fuente - Organismo Judicial (OJ)

## Descripción

Como parte del proceso de construcción del **Operational Data Store (ODS)** del proyecto **Conoce Guate**, se utilizaron conjuntos de datos publicados por el **Organismo Judicial (OJ)** de Guatemala. Estos datos constituyen una de las principales fuentes de información para el dominio de **Justicia**, permitiendo analizar aspectos relacionados con el recurso humano de las instituciones judiciales y la actividad jurisdiccional durante los últimos años.

Con el objetivo de mantener un equilibrio entre el volumen de información y la actualidad de los datos, para esta primera versión del proyecto se decidió trabajar con un período de **tres años**. Esta decisión facilita el desarrollo del modelo de datos, reduce los tiempos de procesamiento y permite contar con información relativamente reciente. En futuras versiones del proyecto será posible incorporar nuevos períodos históricos conforme se encuentren disponibles.

## Conjuntos de datos utilizados

Se integraron los siguientes conjuntos de información provenientes del Organismo Judicial:

### Información de trabajadores

Se cuenta con registros del personal correspondiente a los años:

* 2026
* 2025
* 2024
* 2023

Estos archivos contienen información relacionada con los trabajadores del Organismo Judicial y fueron utilizados para construir el componente administrativo del dominio de Justicia.

### Información de sentencias

También se dispone de información sobre las **sentencias emitidas**, clasificadas por diferentes tipos de delitos durante el mismo período de análisis.

Es importante mencionar que únicamente para el **año 2023** fue posible obtener un conjunto de datos consolidado que relaciona de forma detallada la información de los trabajadores con las sentencias emitidas. En los años posteriores, la información pública disponible presenta un menor nivel de detalle y únicamente proporciona datos agregados, sin mantener la misma estructura utilizada en años anteriores. Debido a ello, el modelo de datos fue diseñado para adaptarse a esta limitación y permitir la incorporación de información más completa cuando sea publicada por la institución.

## Estructura de los datos

La información se encuentra organizada por año y por tipo de conjunto de datos. La estructura general es la siguiente:

```text
OJ/
├── 2023/
│   ├── Informacion_Trabajador/
│   │   ├── 01_Enero.csv
│   │   ├── 02_Febrero.csv
│   │   └── ...
│   └── Sentencias/
│       ├── Indice.csv
│       └── ...
├── 2024/
│   └── ...
├── 2025/
│   └── ...
└── 2026/
    └── ...
```

## Fuente de los datos

Todos los archivos utilizados para este dominio pueden consultarse en el siguiente repositorio de datos:

**Google Drive:**

https://drive.google.com/drive/folders/1muvgG27CqXKwU6RpBV4qxAL_hvA89mTV?usp=drive_link

> **Nota:** La disponibilidad, estructura y nivel de detalle de la información dependen de las publicaciones realizadas por el Organismo Judicial. En caso de que la institución publique nuevos conjuntos de datos o actualice los existentes, estos podrán integrarse en futuras versiones del proyecto mediante los procesos de carga definidos para el ODS.
