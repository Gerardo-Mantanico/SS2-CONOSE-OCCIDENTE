# Datos Fuente - Instituto Nacional de Estadística (INE)

## Descripción

Como complemento a las fuentes de información del sector justicia, el proyecto **Conoce Guate** incorpora datos estadísticos publicados por el **Instituto Nacional de Estadística (INE)**. A diferencia de los registros administrativos provenientes de instituciones como la Policía Nacional Civil, el Ministerio Público y el Organismo Judicial, el INE proporciona información estadística consolidada que permite contrastar, validar y enriquecer los análisis realizados con las demás fuentes de datos.

La información del INE resulta especialmente relevante para el objetivo de la plataforma, ya que permite conocer el comportamiento de las denuncias por robo desde diferentes perspectivas demográficas y geográficas. Estos indicadores pueden ser utilizados tanto para análisis estadísticos como para ofrecer información de interés a turistas, ciudadanos e instituciones, permitiendo identificar regiones con mayor incidencia delictiva y comprender la distribución de los delitos según distintas características de la población.

## Conjuntos de datos utilizados

Para esta primera versión del proyecto se integraron los siguientes conjuntos de datos:

* **Denuncias por Edad:** presenta la distribución de las denuncias según los diferentes rangos de edad de las personas involucradas.

* **Denuncias por Tipo:** clasifica las denuncias de acuerdo con el tipo de robo o delito registrado.

* **Denuncias por Departamento:** muestra la distribución territorial de las denuncias en los diferentes departamentos del país, facilitando la generación de indicadores geográficos.

* **Denuncias por Sexo:** permite analizar la incidencia de las denuncias según el sexo de las personas registradas.

La combinación de estos conjuntos de datos facilita la construcción de indicadores demográficos y territoriales que complementan la información obtenida de otras instituciones públicas, proporcionando una visión más completa del comportamiento de la seguridad en Guatemala.

## Estructura de los datos

La organización de los archivos es la siguiente:

```text
INE/
├── Denuncias_por_Edad.csv
├── Denuncias_por_Tipo.csv
├── Denuncias_por_Departamento.csv
└── Denuncias_por_Sexo.csv
```

## Fuente de los datos

Los archivos utilizados para este dominio pueden consultarse en el siguiente repositorio:

**Google Drive:**

https://drive.google.com/drive/folders/16MB00OmDgydL9DzPb6DjIFzAquUTWfIm?usp=drive_link

> **Nota:** Los datos publicados por el Instituto Nacional de Estadística corresponden a información estadística consolidada y se utilizan como una fuente complementaria para enriquecer los análisis del dominio de Justicia. Su integración permite contrastar la información proveniente de otras instituciones del Estado y generar indicadores que apoyen la toma de decisiones y la consulta de información sobre seguridad dentro de la plataforma **Conoce Guate**.
