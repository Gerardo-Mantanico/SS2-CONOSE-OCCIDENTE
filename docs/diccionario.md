# Diccionario de datos - Base de Datos Nacional

> Generado automáticamente desde la vista `meta.diccionario`. No editar a mano; regenera con `python etl/python/meta/generar_diccionario.py`.

## Contenido

- **artesania**: `artista_artesano`, `evento_exposicion_arte`, `material_arte`, `obra_arte_artesania`, `obra_material`, `obra_tecnica`, `participante_evento`, `produccion_artesanal_municipal`, `taller_colectivo`, `tecnica_artesanal`, `tipo_obra_arte`
- **auditoria**: `registro`
- **auth**: `cuenta`, `rol`
- **clima**: `fuente_clima`, `registro_climatico`
- **cultura**: `evento_cultural`, `evento_municipio`, `idioma`, `idioma_municipio`, `ingrediente_autoctono`, `plato_geografia`, `plato_ingrediente`, `plato_tipico`
- **demografia**: `estado_civil`, `grupo_etnico`, `persona`, `sexo`
- **economia**: `actividad_materia`, `actividad_productiva`, `centro_acopio_procesamiento`, `certificacion`, `cooperativa_asociacion`, `materia_prima`, `mercado_tradicional`, `produccion_certificada`, `produccion_municipal`, `ruta_comercio`, `servicio_financiero`
- **geografia**: `departamento`, `municipio`, `pais`
- **justicia**: `denuncia`, `estadistica_seguridad`, `estado_denuncia`, `grupo_edad_victima`, `nomina_publica`, `registro_fecha_denuncia`, `renglon_presupuestario`, `sexo`, `tipo_delito`, `tipo_denuncia`, `tipo_evento`
- **meta**: `carga`, `cobertura_carga`, `estado_carga`, `fuente`, `tipo_fuente`
- **patrimonio**: `banco`, `cuenta_bancaria`, `empresa`, `inmueble`, `rol_empresa`, `vehiculo`
- **sector_publico**: `banco`, `cargo`, `contrato`, `cuenta_bancaria`, `empresa`, `inmueble`, `institucion`, `nivel_institucion`, `rol_empresa`, `tipo_contrato`, `tipo_institucion`, `trabajador`, `vehiculo`
- **turismo**: `actividad_turistica`, `categoria_destino`, `departamento_region_turistica`, `destino_actividad`, `destino_categoria`, `destino_fuente`, `destino_patrimonio`, `destino_temporada`, `destino_turistico`, `dim_actividad`, `dim_actividad_turismo`, `dim_categoria`, `dim_categoria_turismo`, `dim_departamento`, `dim_destino`, `dim_fecha`, `dim_fuente`, `dim_geografia_turistica`, `dim_municipio`, `dim_patrimonio`, `dim_region`, `dim_region_turistica`, `dim_ruta`, `dim_temporada`, `etl_ejecucion`, `etl_ejecucion_turismo`, `etl_error_turismo`, `etl_job`, `etl_validacion`, `fact_destino_actividad`, `fact_destino_catalogo`, `fact_destino_categoria`, `fact_destino_patrimonio`, `fact_destino_temporada`, `fact_destino_turistico`, `fact_metrica_destino`, `fact_ruta_destino`, `fuente_turistica`, `patrimonio_turistico`, `recomendacion_destino`, `region_turistica`, `ruta_destino`, `ruta_turistica`, `stg_destino_raw`, `stg_destino_turistico`, `stg_evento_usuario_raw`, `stg_fuente_raw`, `stg_metricas_destino_raw`, `temporada_turistica`


## Schema: `artesania`

### `artesania.artista_artesano`

Maestros artesanos y artistas de las diversas ramas en la región.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_artista | integer | no | X |  | `IDENTITY` | Identificador único del artista/artesano. |
| codigo | character varying(80) | no |  |  |  | Código estable de identificación del artista. |
| nombre_completo | character varying(220) | no |  |  |  | Nombre completo del artista/artesano. |
| genero | character varying(20) | sí |  |  |  | Género del artista/artesano. |
| fecha_nacimiento | date | sí |  |  |  | Fecha de nacimiento. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial de origen/residencia. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial de origen/residencia. |
| taller_id | integer | sí |  | artesania.taller_colectivo(id_taller) |  | Taller o colectivo al que pertenece, si aplica. |
| especialidad_principal | character varying(150) | no |  |  |  | Especialidad principal del artista (ej. Pintura Primitivista, Marimbista). |
| reconocimientos | text | sí |  |  |  | Listado de premios, distinciones o trayectoria. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.evento_exposicion_arte`

Eventos, ferias, exposiciones y festivales culturales de arte y artesanía.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_evento | integer | no | X |  | `IDENTITY` | Identificador único del evento. |
| codigo | character varying(80) | no |  |  |  | Código estable de identificación del evento. |
| nombre | character varying(220) | no |  |  |  | Nombre oficial del evento o exposición. |
| fecha_inicio | date | no |  |  |  | Fecha de inicio del evento. |
| fecha_fin | date | no |  |  |  | Fecha de finalización del evento. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial de sede del evento. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial de sede del evento. |
| lugar_detallado | character varying(350) | sí |  |  |  | Descripción del lugar físico o centro del evento. |
| organizador | character varying(180) | sí |  |  |  | Institución, cooperativa u organizador principal. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.material_arte`

Catálogo de materias primas o materiales utilizados en las obras.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_material | integer | no | X |  | `IDENTITY` | Identificador único del material. |
| codigo | character varying(80) | no |  |  |  | Código estable del material. |
| nombre | character varying(120) | no |  |  |  | Nombre del material (ej. Hilo de algodón, Madera de hormigo, Jade). |
| descripcion | text | sí |  |  |  | Descripción del material y sus propiedades. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.obra_arte_artesania`

Ficha técnica de obras, piezas o expresiones artísticas específicas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_obra | integer | no | X |  | `IDENTITY` | Identificador único de la obra. |
| codigo | character varying(80) | no |  |  |  | Código estable de la obra. |
| nombre | character varying(220) | no |  |  |  | Nombre o título descriptivo de la obra. |
| tipo_obra_id | integer | no |  | artesania.tipo_obra_arte(id_tipo_obra) |  | Tipo de obra asociada. |
| artista_id | integer | sí |  | artesania.artista_artesano(id_artista) |  | Referencia al artista/artesano creador. |
| taller_id | integer | sí |  | artesania.taller_colectivo(id_taller) |  | Referencia al taller o colectivo creador (si aplica). |
| descripcion | text | no |  |  |  | Descripción artística o artesanal de la pieza. |
| tiempo_estimado_creacion_dias | integer | sí |  |  |  | Tiempo estimado de elaboración en días. |
| precio_sugerido_q | numeric(10,2) | sí |  |  |  | Precio sugerido de venta en Quetzales. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.obra_material`

Relación muchos a muchos entre obras y materiales con proporciones.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| obra_id | integer | no | X | artesania.obra_arte_artesania(id_obra) |  | Identificador de la obra. |
| material_id | integer | no | X | artesania.material_arte(id_material) |  | Identificador del material utilizado. |
| proporcion_estimada | numeric(5,2) | sí |  |  |  | Proporción porcentual estimada del material en la pieza. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.obra_tecnica`

Relación muchos a muchos entre obras y técnicas aplicadas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| obra_id | integer | no | X | artesania.obra_arte_artesania(id_obra) |  | Identificador de la obra. |
| tecnica_id | integer | no | X | artesania.tecnica_artesanal(id_tecnica) |  | Identificador de la técnica aplicada. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.participante_evento`

Registro de artistas y talleres colectivos participantes en eventos y sus reconocimientos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| evento_id | integer | no |  | artesania.evento_exposicion_arte(id_evento) |  | Identificador del evento. |
| artista_id | integer | sí |  | artesania.artista_artesano(id_artista) |  | Artista individual participante (opcional). |
| taller_id | integer | sí |  | artesania.taller_colectivo(id_taller) |  | Taller colectivo participante (opcional). |
| premio_reconocimiento | character varying(250) | sí |  |  |  | Premio, mención o reconocimiento obtenido. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.produccion_artesanal_municipal`

Estimaciones anuales del volumen, valor comercial y artesanos activos por municipio.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_produccion | integer | no | X |  | `IDENTITY` | Identificador único del registro de producción. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial verificado. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial verificado. |
| tipo_obra_id | integer | no |  | artesania.tipo_obra_arte(id_tipo_obra) |  | Tipo de obra evaluado. |
| anio | integer | no |  |  |  | Año del registro estadístico. |
| volumen_estimado_unidades | integer | no |  |  |  | Volumen estimado de piezas anuales producidas. |
| valor_estimado_mercado_q | numeric(12,2) | no |  |  |  | Valor total estimado de mercado en Quetzales. |
| cantidad_artesanos_activos | integer | no |  |  |  | Cantidad estimada de artesanos activos en este rubro. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.taller_colectivo`

Talleres colectivos, cooperativas y asociaciones familiares de artesanos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_taller | integer | no | X |  | `IDENTITY` | Identificador único del taller o colectivo. |
| codigo | character varying(80) | no |  |  |  | Código estable del taller. |
| nombre | character varying(220) | no |  |  |  | Nombre oficial del taller o colectivo. |
| representante | character varying(180) | sí |  |  |  | Nombre del maestro artesano o líder representante. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial de ubicación del taller. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial de ubicación del taller. |
| direccion | character varying(350) | sí |  |  |  | Dirección o paraje detallado del taller. |
| anio_fundacion | integer | sí |  |  |  | Año aproximado de fundación. |
| cantidad_miembros | integer | no |  |  | `1` | Cantidad de artesanos activos en el colectivo. |
| contacto | character varying(150) | sí |  |  |  | Datos de contacto del taller. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.tecnica_artesanal`

Técnicas tradicionales y contemporáneas aplicadas en la creación de obras.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_tecnica | integer | no | X |  | `IDENTITY` | Identificador único de la técnica. |
| codigo | character varying(80) | no |  |  |  | Código estable de la técnica. |
| nombre | character varying(120) | no |  |  |  | Nombre de la técnica (ej. Jaspe, Telar de cintura, Modelado de barro). |
| origen_historico | text | sí |  |  |  | Información sobre el origen histórico de la técnica. |
| descripcion | text | sí |  |  |  | Descripción técnica de la metodología de trabajo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |

### `artesania.tipo_obra_arte`

Catálogo de tipos de expresiones artísticas o artesanales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_tipo_obra | integer | no | X |  | `IDENTITY` | Identificador único del tipo de obra. |
| codigo | character varying(80) | no |  |  |  | Código estable del tipo de obra para integraciones y ETL. |
| nombre | character varying(120) | no |  |  |  | Nombre del tipo de obra (ej. TEXTIL, CERAMICA, PINTURA). |
| descripcion | text | sí |  |  |  | Descripción del tipo de expresión artística. |
| categoria_general | character varying(80) | no |  |  |  | Categoría general (ej. ARTESANIA, ARTES_VISUALES, ARTES_ESCENICAS). |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia al registro de carga de metadatos. |


## Schema: `auditoria`

### `auditoria.registro`

Bitácora central de auditoría. Guarda el estado previo y posterior de las filas modificadas en formato JSONB para independizarse de la estructura de cada tabla.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | bigint | no | X |  | `IDENTITY` | Identificador único autogenerado del registro de auditoría. |
| esquema | text | no |  |  |  | Nombre del esquema de la base de datos donde ocurrió la modificación. |
| tabla | text | no |  |  |  | Nombre de la tabla donde ocurrió la modificación. |
| operacion | text | no |  |  |  | Tipo de operación DML realizada (INSERT, UPDATE o DELETE). |
| pk | text | sí |  |  |  | Valor de la columna "id" de la fila afectada (si la tabla auditada cuenta con una). |
| datos_old | jsonb | sí |  |  |  | Estado previo de la fila en formato JSONB (se llena en operaciones UPDATE y DELETE). |
| datos_new | jsonb | sí |  |  |  | Nuevo estado de la fila en formato JSONB (se llena en operaciones INSERT y UPDATE). |
| usuario_bd | text | no |  |  | `CURRENT_USER` | Rol o usuario nativo de PostgreSQL que ejecutó la operación en la base de datos. |
| app_usuario | text | sí |  |  |  | Usuario de la aplicación, colaborador o proceso ETL responsable del cambio (obtenido de la variable GUC "audit.app_usuario"). |
| fecha | timestamp with time zone | no |  |  | `now()` | Fecha y hora exactas en la que se registró la operación. |


## Schema: `auth`

### `auth.cuenta`

Credenciales de acceso asociadas a una persona registrada en el sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la cuenta de usuario. |
| persona_id | integer | no |  | demografia.persona(id) |  | Persona propietaria de la cuenta. |
| rol_id | integer | no |  | auth.rol(id) |  | Rol asignado a la cuenta para determinar sus permisos. |
| nombre_usuario | character varying(100) | no |  |  |  | Nombre de usuario utilizado para autenticarse en el sistema. |
| contrasena | character varying(255) | no |  |  |  | Contraseña almacenada de forma cifrada mediante un algoritmo seguro. |
| esta_activo | boolean | no |  |  | `true` | Indica si la cuenta se encuentra habilitada para iniciar sesión. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la cuenta. |

### `auth.rol`

Catálogo de roles disponibles para controlar los permisos de acceso al sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del rol. |
| nombre | character varying(100) | no |  |  |  | Nombre del rol. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el rol. |


## Schema: `clima`

### `clima.fuente_clima`

Catálogo de fuentes proveedoras de información climática.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la fuente climática. |
| nombre | character varying(100) | no |  |  |  | Nombre de la fuente de datos climáticos. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la fuente. |

### `clima.registro_climatico`

Registros de variables climáticas observadas para un municipio en una fecha y hora determinadas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del registro climático. |
| fuente_clima_id | integer | no |  | clima.fuente_clima(id) |  | Fuente de la cual provienen los datos climáticos. |
| municipio_id | integer | no |  | geografia.municipio(id) |  | Municipio al que corresponde la medición climática. |
| fecha | date | sí |  |  |  | Fecha en que se realizó la medición. |
| hora | time without time zone | sí |  |  |  | Hora en que se realizó la medición. |
| velocidad_viento | numeric(8,2) | sí |  |  |  | Velocidad del viento registrada, expresada en kilómetros por hora. |
| humedad_relativa | numeric(5,2) | sí |  |  |  | Humedad relativa del aire expresada como porcentaje. |
| precipitacion | numeric(8,2) | sí |  |  |  | Cantidad de precipitación registrada durante el período de observación, expresada en milímetros. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la medición. |


## Schema: `cultura`

### `cultura.evento_cultural`

Registro de festividades, ferias patronales, festivales y ceremonias tradicionales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del evento. |
| nombre | character varying(200) | no |  |  |  | Nombre oficial del evento o festividad. |
| tipo_evento | character varying(100) | sí |  |  |  | Tipo de festividad (ej: Feria Patronal, Festival Artístico, Ceremonia Espiritual). |
| mes_celebracion | integer | sí |  |  |  | Mes del año en que se realiza la celebración (1-12). |
| dia_inicio | integer | sí |  |  |  | Día del mes en que inicia la festividad. |
| dia_fin | integer | sí |  |  |  | Día del mes en que finaliza la festividad. |
| descripcion | text | sí |  |  |  | Descripción del contexto, tradición y actividades del evento. |
| recomendaciones_viaje | text | sí |  |  |  | Consejos prácticos para viajeros que desean asistir al evento. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el evento. |

### `cultura.evento_municipio`

Tabla asociativa que mapea la ubicación municipal donde se celebran los eventos culturales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| evento_id | integer | no | X | cultura.evento_cultural(id) |  | Identificador único del evento. |
| municipio_id | integer | no | X | geografia.municipio(id) |  | Identificador único del municipio. |

### `cultura.idioma`

Catálogo de idiomas nacionales hablados en el territorio guatemalteco (mayas, garífuna, xinka y español).

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del idioma. |
| nombre | character varying(100) | no |  |  |  | Nombre oficial del idioma. |
| familia_linguistica | character varying(100) | sí |  |  |  | Familia lingüística a la que pertenece el idioma (ej: Maya, Arahuaca, Aislada). |
| estado_vitalidad | character varying(50) | sí |  |  |  | Estado de vitalidad del idioma (ej: Vital, En peligro, Crítico). |
| descripcion | text | sí |  |  |  | Reseña e información relevante sobre la historia o distribución del idioma. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el idioma. |

### `cultura.idioma_municipio`

Tabla asociativa que mapea la distribución territorial y relevancia de los idiomas en los municipios.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| idioma_id | integer | no | X | cultura.idioma(id) |  | Identificador único del idioma. |
| municipio_id | integer | no | X | geografia.municipio(id) |  | Identificador único del municipio. |
| es_predominante | boolean | sí |  |  | `false` | Indica si el idioma es el predominante en el municipio. |

### `cultura.ingrediente_autoctono`

Ingredientes originarios o tradicionales de la gastronomía guatemalteca.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del ingrediente. |
| nombre | character varying(100) | no |  |  |  | Nombre del ingrediente (ej: Cacao, Pepitoria, Chile Cobanero). |
| descripcion | text | sí |  |  |  | Descripción de las propiedades o uso del ingrediente. |
| origen_prehispanico | boolean | sí |  |  | `true` | Indica si el ingrediente tiene origen prehispánico en la región. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el ingrediente. |

### `cultura.plato_geografia`

Relación geográfica de origen o arraigo de los platos típicos (departamento y opcionalmente municipio).

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| plato_id | integer | no | X | cultura.plato_tipico(id) |  | Identificador único del plato típico. |
| departamento_id | integer | no | X | geografia.departamento(id) |  | Departamento de origen o arraigo del plato. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio específico de origen o arraigo (opcional). |

### `cultura.plato_ingrediente`

Tabla asociativa que relaciona los platos típicos con sus ingredientes característicos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| plato_id | integer | no | X | cultura.plato_tipico(id) |  | Identificador único del plato típico. |
| ingrediente_id | integer | no | X | cultura.ingrediente_autoctono(id) |  | Identificador único del ingrediente. |

### `cultura.plato_tipico`

Catálogo de platillos y comidas tradicionales de Guatemala.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del plato típico. |
| nombre | character varying(150) | no |  |  |  | Nombre oficial del platillo tradicional (ej: Pepián, Kaq'ik). |
| descripcion | text | sí |  |  |  | Reseña de la composición y presentación del platillo. |
| historia_origen | text | sí |  |  |  | Contexto cultural e histórico del origen del platillo. |
| es_patrimonio | boolean | sí |  |  | `false` | Indica si el platillo ha sido declarado Patrimonio Cultural de la Nación. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el platillo. |


## Schema: `demografia`

### `demografia.estado_civil`

Catálogo de estados civiles utilizados para clasificar a las personas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del estado civil. |
| nombre | character varying(50) | no |  |  |  | Nombre del estado civil. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el estado civil. |

### `demografia.grupo_etnico`

Catálogo de grupos étnicos registrados en el sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del grupo étnico. |
| nombre | character varying(100) | no |  |  |  | Nombre del grupo étnico. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el grupo étnico. |

### `demografia.persona`

Información personal e identificatoria de los individuos registrados en el sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la persona. |
| estado_civil_id | integer | no |  | demografia.estado_civil(id) |  | Estado civil asociado a la persona. |
| sexo_id | integer | no |  | demografia.sexo(id) |  | Sexo registrado para la persona. |
| grupo_etnico_id | integer | no |  | demografia.grupo_etnico(id) |  | Grupo étnico al que pertenece la persona. |
| dpi | character varying(20) | sí |  |  |  | Número de Documento Personal de Identificación (DPI). |
| nit | character varying(20) | sí |  |  |  | Número de Identificación Tributaria (NIT). |
| nombres | character varying(150) | no |  |  |  | Nombres de la persona. |
| apellidos | character varying(150) | no |  |  |  | Apellidos de la persona. |
| correo | character varying(150) | sí |  |  |  | Dirección de correo electrónico. |
| telefono | character varying(20) | sí |  |  |  | Número telefónico de contacto. |
| fecha_nacimiento | date | sí |  |  |  | Fecha de nacimiento de la persona. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la persona. |

### `demografia.sexo`

Catálogo de sexos registrados para las personas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del sexo. |
| nombre | character varying(30) | no |  |  |  | Nombre del sexo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el sexo. |


## Schema: `economia`

### `economia.actividad_materia`

Matriz asociativa que vincula las actividades productivas con sus materias primas requeridas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| actividad_id | integer | no | X | economia.actividad_productiva(id) |  | Identificador de la actividad productiva. |
| materia_id | integer | no | X | economia.materia_prima(id) |  | Identificador de la materia prima requerida. |
| es_indispensable | boolean | sí |  |  | `true` | Indica si el insumo es crítico para la realización de la actividad. |

### `economia.actividad_productiva`

Catálogo detallado de actividades y productos líderes de la economía municipal.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la actividad productiva. |
| nombre | character varying(100) | no |  |  |  | Nombre oficial del producto o actividad (ej: Café, Tejidos Mayas, Cardamomo). |
| categoria | character varying(50) | no |  |  |  | Categoría sectorial de la actividad productiva. |
| descripcion | text | sí |  |  |  | Reseña de la importancia y características de la actividad. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró la actividad. |

### `economia.centro_acopio_procesamiento`

Infraestructura productiva local dedicada a la preparación, empaque o procesamiento de productos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la infraestructura. |
| nombre | character varying(150) | no |  |  |  | Nombre del centro de procesamiento (ej: Beneficio Las Cascadas). |
| tipo | character varying(50) | sí |  |  |  | Clasificación de la planta o centro de procesamiento. |
| municipio_id | integer | no |  | geografia.municipio(id) |  | Municipio donde opera físicamente el centro. |
| capacidad_estimada | character varying(100) | sí |  |  |  | Volumen o escala estimada de procesamiento (ej: 500 quintales/día). |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró la infraestructura. |

### `economia.certificacion`

Catálogo de sellos de calidad, origen, orgánicos o de comercio justo vigentes en el país.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la certificación. |
| nombre | character varying(150) | no |  |  |  | Nombre distintivo de la certificación o sello (ej: Orgánico USDA, Fairtrade). |
| ente_certificador | character varying(150) | no |  |  |  | Institución o empresa auditora que expide la certificación. |
| descripcion | text | sí |  |  |  | Descripción del propósito y alcance del sello. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la auditoría de carga de datos. |

### `economia.cooperativa_asociacion`

Cooperativas, gremiales y asociaciones que impulsan la producción y comercialización local.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la cooperativa o asociación. |
| nombre | character varying(200) | no |  |  |  | Nombre legal completo de la organización. |
| siglas | character varying(50) | sí |  |  |  | Siglas o acrónimo representativo (ej: Fedecocagua, Copichol). |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Sede o municipio principal de la organización. |
| cobertura | character varying(50) | sí |  |  |  | Ámbito de cobertura geográfica de la organización. |
| descripcion | text | sí |  |  |  | Reseña de la historia, fines y apoyo a productores de la organización. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró la organización. |

### `economia.materia_prima`

Insumos y materias primas clave utilizados en los procesos productivos locales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la materia prima. |
| nombre | character varying(100) | no |  |  |  | Nombre del insumo (ej: Hilo de algodón, Madera de pino, Cuero bobino). |
| origen | character varying(50) | sí |  |  |  | Origen geográfico principal del insumo. |
| descripcion | text | sí |  |  |  | Detalles sobre las características físicas y usos comunes del insumo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró el insumo. |

### `economia.mercado_tradicional`

Plazas comerciales y mercados históricos notables del país.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del mercado. |
| nombre | character varying(150) | no |  |  |  | Nombre distintivo del mercado local. |
| municipio_id | integer | no |  | geografia.municipio(id) |  | Municipio en el que se localiza el mercado. |
| dias_plaza | character varying(100) | no |  |  |  | Días principales de mercado y plaza tradicional. |
| tipo_mercado | character varying(50) | sí |  |  |  | Tipología principal del mercado. |
| cantidad_vendedores_est | integer | sí |  |  |  | Número estimado de vendedores en días principales de plaza. |
| latitud | numeric(9,6) | sí |  |  |  | Coordenada de latitud decimal (WGS84). |
| longitud | numeric(9,6) | sí |  |  |  | Coordenada de longitud decimal (WGS84). |
| descripcion | text | sí |  |  |  | Descripción del mercado, historia e importancia cultural. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró el mercado. |

### `economia.produccion_certificada`

Asociación de la producción municipal con sus respectivas certificaciones nacionales o internacionales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| municipio_id | integer | no | X | economia.produccion_municipal(municipio_id, actividad_id) |  | Identificador del municipio productor. |
| actividad_id | integer | no | X | economia.produccion_municipal(municipio_id, actividad_id) |  | Identificador de la actividad productiva. |
| certificacion_id | integer | no | X | economia.certificacion(id) |  | Referencia a la certificación que ostenta esta producción. |
| porcentaje_produccion | numeric(5,2) | sí |  |  |  | Porcentaje estimado de la producción del municipio amparado por la certificación. |
| fecha_auditoria | date | no |  |  |  | Fecha de la última auditoría de control de calidad. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la auditoría de carga de datos. |

### `economia.produccion_municipal`

Asociación de actividades productivas con municipios, detallando métricas socioeconómicas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| municipio_id | integer | no | X | geografia.municipio(id) |  | Identificador del municipio productor. |
| actividad_id | integer | no | X | economia.actividad_productiva(id) |  | Identificador de la actividad productiva. |
| cooperativa_id | integer | sí |  | economia.cooperativa_asociacion(id) |  | Identificador de la cooperativa local de apoyo (opcional). |
| es_principal | boolean | sí |  |  | `false` | Indica si es una de las actividades económicas líderes del municipio. |
| volumen_estimado | character varying(50) | sí |  |  |  | Volumen estimado de producción. |
| cantidad_productores_est | integer | sí |  |  |  | Cantidad estimada de productores o familias involucradas. |
| empleo_generado_est | integer | sí |  |  |  | Empleos directos generados estimados en el municipio. |
| ciclo_cosecha_meses | character varying(50) | sí |  |  |  | Meses clave de cosecha o mayor actividad (ej: Noviembre-Marzo para Café). |
| destino_principal | character varying(50) | sí |  |  |  | Destino principal del producto comercializado. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos por la cual se registró la producción. |

### `economia.ruta_comercio`

Registro de flujos logísticos y rutas de comercio de mercancías entre municipios o puertos de salida.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la ruta de comercio. |
| origen_municipio_id | integer | no |  | geografia.municipio(id) |  | Identificador del municipio origen del flujo comercial. |
| destino_municipio_id | integer | sí |  | geografia.municipio(id) |  | Identificador del municipio destino del flujo comercial (opcional si es exportación). |
| puerto_salida | character varying(100) | sí |  |  |  | Nombre del puerto marítimo o frontera terrestre de destino para exportación (ej: Puerto Quetzal, Tecún Umán). |
| medio_transporte | character varying(100) | no |  |  |  | Medio de transporte utilizado para movilizar la mercancía. |
| distancia_km | numeric(6,2) | sí |  |  |  | Distancia aproximada de la ruta en kilómetros. |
| tiempo_estimado_horas | numeric(4,2) | sí |  |  |  | Tiempo de tránsito estimado en horas. |
| producto_principal | character varying(150) | sí |  |  |  | Nombre del producto principal movilizado en la ruta. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la auditoría de carga de datos. |

### `economia.servicio_financiero`

Líneas de crédito y servicios de inclusión financiera ofrecidos por cooperativas rurales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del servicio financiero. |
| cooperativa_id | integer | no |  | economia.cooperativa_asociacion(id) |  | Referencia a la cooperativa que ofrece el servicio. |
| tipo_servicio | character varying(100) | no |  |  |  | Clasificación de producto crediticio o financiero. |
| tasa_interes_anual | numeric(4,2) | sí |  |  |  | Tasa de interés anualizada del servicio financiero. |
| monto_maximo_quetzales | numeric(12,2) | sí |  |  |  | Monto máximo de financiamiento en Quetzales. |
| requisito_principal | text | sí |  |  |  | Descripción del principal requisito para optar al financiamiento. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la auditoría de carga de datos. |


## Schema: `geografia`

### `geografia.departamento`

Catálogo de departamentos o divisiones administrativas de primer nivel.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del departamento. |
| nombre | character varying(100) | no |  |  |  | Nombre oficial del departamento. |
| pais_id | integer | no |  | geografia.pais(id) |  |  |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el departamento. |
| pcode | character varying(12) | sí |  |  |  | Código geográfico estandarizado (P-Code OCHA/HDX) del departamento, p.ej. GT04. |
| area_km2 | numeric(14,4) | sí |  |  |  | Superficie territorial del departamento expresada en kilómetros cuadrados. |
| centro_lat | numeric(11,8) | sí |  |  |  | Latitud del centroide geográfico del departamento. |
| centro_lon | numeric(11,8) | sí |  |  |  | Longitud del centroide geográfico del departamento. |

### `geografia.municipio`

Catálogo de municipios asociados a un departamento.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del municipio. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento al que pertenece el municipio. |
| nombre | character varying(100) | no |  |  |  | Nombre oficial del municipio. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el municipio. |
| pcode | character varying(12) | sí |  |  |  | Código geográfico estandarizado (P-Code OCHA/HDX) del municipio, p.ej. GT0411 |
| area_km2 | numeric(14,4) | sí |  |  |  | Superficie territorial del municipio expresada en kilómetros cuadrados. |
| centro_lat | numeric(11,8) | sí |  |  |  | Latitud del centroide geográfico del municipio. |
| centro_lon | numeric(11,8) | sí |  |  |  | Longitud del centroide geográfico del municipio. |

### `geografia.pais`

Catálogo de países utilizados por el sistema como nivel geográfico principal.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del país. |
| nombre | character varying(100) | no |  |  |  | Nombre oficial del país. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el país. |
| pcode | character varying(12) | sí |  |  |  | Código geográfico estandarizado (P-Code OCHA/HDX) del país, p.ej. GT |
| iso2 | character(2) | sí |  |  |  | Código ISO 3166-1 alfa-2 del país. |
| iso3 | character(3) | sí |  |  |  | Código ISO 3166-1 alfa-3 del país. |
| area_km2 | numeric(14,4) | sí |  |  |  | Superficie territorial del país expresada en kilómetros cuadrados. |
| centro_lat | numeric(11,8) | sí |  |  |  | Latitud del centroide geográfico del país. |
| centro_lon | numeric(11,8) | sí |  |  |  | Longitud del centroide geográfico del país. |


## Schema: `justicia`

### `justicia.denuncia`

Denuncias registradas dentro del sistema de justicia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la denuncia. |
| tipo_denuncia_id | integer | no |  | justicia.tipo_denuncia(id) |  | Tipo de denuncia registrada. |
| estado_denuncia_id | integer | no |  | justicia.estado_denuncia(id) |  | Estado procesal actual de la denuncia. |
| institucion_id | integer | no |  | sector_publico.institucion(id) |  | Institución responsable de conocer o tramitar la denuncia. |
| municipio_incidencia_id | integer | no |  | geografia.municipio(id) |  | Municipio donde ocurrió el hecho denunciado. |
| descripcion | text | sí |  |  |  | Descripción de los hechos reportados en la denuncia. |

### `justicia.estadistica_seguridad`

Estadisticas anuales de robos/hurtos desagregadas por departamento, sexo, edad y tipo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| anio | smallint | no |  |  |  |  |
| departamento_id | integer | sí |  | geografia.departamento(id) |  | FK a geografia.departamento. NULL indica total nacional (Republica). |
| nombre_departamento | character varying(100) | sí |  |  |  |  |
| tipo_delito_id | integer | sí |  | justicia.tipo_delito(id) |  |  |
| sexo_id | integer | sí |  | justicia.sexo(id) |  |  |
| grupo_edad_id | integer | sí |  | justicia.grupo_edad_victima(id) |  |  |
| cantidad | integer | no |  |  | `0` |  |
| fuente | character varying(200) | sí |  |  |  |  |
| archivo_origen | character varying(200) | sí |  |  |  |  |
| fecha_carga | timestamp without time zone | sí |  |  | `CURRENT_TIMESTAMP` |  |
| cargado_por | character varying(200) | sí |  |  |  |  |
| revisado | boolean | sí |  |  | `false` | Indica si el registro paso el filtro de pares (revision de calidad). |

### `justicia.estado_denuncia`

Catálogo de estados en los que puede encontrarse una denuncia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del estado de la denuncia. |
| nombre | character varying(100) | no |  |  |  | Nombre del estado procesal de la denuncia. |

### `justicia.grupo_edad_victima`

Grupos quinquenales de edad de la victima segun clasificacion INE/PNC.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| codigo | character varying(20) | no |  |  |  |  |
| rango | character varying(50) | no |  |  |  |  |
| edad_min | smallint | sí |  |  |  |  |
| edad_max | smallint | sí |  |  |  |  |
| orden | smallint | no |  |  |  |  |

### `justicia.nomina_publica`

Nómina de trabajadores de instituciones del sector justicia publicada bajo transparencia activa (LAIP). Fuentes: OJ y Congreso de la República.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| sigla_institucion | character varying(10) | no |  |  |  | Sigla de la institución de origen: OJ = Organismo Judicial, CR = Congreso de la República. |
| anio | smallint | no |  |  |  | Año del período de nómina reportado. |
| mes | smallint | sí |  |  |  | Mes del período de nómina reportado (1-12). NULL si el dato es de período anual o no especificado. |
| nip | character varying(20) | sí |  |  |  | Número de Identificación Personal del empleado según el sistema de la institución. Aplica para OJ. |
| nombre | character varying(300) | no |  |  |  | Nombre completo del trabajador tal como aparece en la fuente de datos. |
| puesto | character varying(300) | sí |  |  |  | Puesto o cargo desempeñado por el trabajador dentro de la institución. |
| unidad | character varying(300) | sí |  |  |  | Unidad administrativa, dependencia o bloque legislativo al que está asignado el trabajador. |
| renglon_id | integer | sí |  | justicia.renglon_presupuestario(id) |  | Renglón presupuestario bajo el que fue contratado el trabajador (011, 022 ó 029). |
| salario | numeric(12,2) | sí |  |  |  | Salario base o monto principal de remuneración en quetzales. Para CR renglón 029 corresponde a honorarios. |
| total_devengado | numeric(12,2) | sí |  |  |  | Total devengado incluyendo bonificaciones (OJ). NULL cuando la fuente no desglosa ese total. |
| fuente | character varying(200) | sí |  |  |  | Institución y referencia de la fuente de datos utilizada. |
| archivo_origen | character varying(200) | sí |  |  |  | Nombre del archivo CSV del que proviene el registro. |
| fecha_carga | timestamp without time zone | sí |  |  | `CURRENT_TIMESTAMP` |  |

### `justicia.registro_fecha_denuncia`

Registro cronológico de eventos asociados al trámite de una denuncia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del registro de evento. |
| denuncia_id | integer | no |  | justicia.denuncia(id) |  | Denuncia a la que pertenece el evento registrado. |
| tipo_evento_id | integer | no |  | justicia.tipo_evento(id) |  | Tipo de evento ocurrido durante el proceso de la denuncia. |
| observaciones | text | sí |  |  |  | Observaciones o detalles relacionados con el evento. |
| fecha | date | sí |  |  |  | Fecha en la que ocurrió el evento registrado. |

### `justicia.renglon_presupuestario`

Catálogo de renglones presupuestarios que clasifican el tipo de contratación de servidores públicos en Guatemala.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| codigo | character varying(10) | no |  |  |  | Código numérico del renglón presupuestario (ej. 011, 022, 029). |
| nombre | character varying(200) | no |  |  |  | Nombre oficial del renglón presupuestario según el presupuesto general del estado. |
| descripcion | text | sí |  |  |  | Descripción del tipo de contratación que corresponde al renglón. |

### `justicia.sexo`

Categorias de sexo de la victima segun clasificacion INE/PNC.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| nombre | character varying(50) | no |  |  |  |  |

### `justicia.tipo_delito`

Catalogo de modalidades de robo/hurto segun clasificacion PNC.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| codigo | character varying(30) | no |  |  |  |  |
| nombre | character varying(150) | no |  |  |  |  |
| descripcion | text | sí |  |  |  |  |
| aplica_turistas | boolean | sí |  |  | `false` | TRUE si el tipo afecta directamente a turistas (util para Conoce Guate). |
| created_at | timestamp without time zone | sí |  |  | `CURRENT_TIMESTAMP` |  |

### `justicia.tipo_denuncia`

Catálogo de tipos de denuncias registradas en el sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del tipo de denuncia. |
| nombre | character varying(100) | no |  |  |  | Nombre del tipo de denuncia. |

### `justicia.tipo_evento`

Catálogo de eventos que pueden ocurrir durante el ciclo de vida de una denuncia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del tipo de evento. |
| nombre | character varying(100) | no |  |  |  | Nombre del tipo de evento. |


## Schema: `meta`

### `meta.carga`

Representa una ejecución concreta de un proceso ETL. Inicia en estado en_proceso y se actualiza al finalizar.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único autogenerado de la ejecución de carga. |
| fuente_id | integer | no |  | meta.fuente(id) |  | Referencia a la fuente externa desde donde se extrajeron los datos. |
| estado_carga_id | integer | no |  | meta.estado_carga(id) |  | Estado actual de la ejecución del ETL. |
| nombre_script | character varying(200) | sí |  |  |  | Ruta relativa o nombre del script de código que ejecutó la carga (ej: sector_publico/..._load_instituciones.py). |
| archivo_fuente | text | sí |  |  |  | Nombre o ruta del archivo de datos origen que fue procesado. |
| hash_archivo | character varying(64) | sí |  |  |  | Hash SHA-256 del archivo origen, utilizado para prevenir duplicados y reprocesamientos. |
| ejecutado_por | text | sí |  |  |  | Usuario de base de datos, del sistema operativo o nombre del colaborador que lanzó el proceso. |
| iniciado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora exactas en que comenzó la ejecución del proceso ETL. |
| finalizado_en | timestamp with time zone | sí |  |  |  | Fecha y hora exactas en que concluyó la ejecución del proceso ETL. |
| filas_procesadas | integer | sí |  |  |  | Cantidad total de registros leídos desde el archivo o sistema fuente. |
| filas_insertadas | integer | sí |  |  |  | Cantidad de registros nuevos insertados en la base de datos destino. |
| filas_actualizadas | integer | sí |  |  |  | Cantidad de registros existentes que fueron modificados o actualizados. |
| filas_rechazadas | integer | sí |  |  |  | Cantidad de registros ignorados por errores, reglas de negocio o duplicidad. |
| notas | text | sí |  |  |  | Registro de errores, advertencias (warnings) u observaciones durante la ejecución. |

### `meta.cobertura_carga`

Registra el esquema y la tabla poblada por un ETL específico, así como el rango de tiempo de los datos ingresados.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único autogenerado de la cobertura. |
| carga_id | integer | no |  | meta.carga(id) |  | Referencia a la carga (ejecución del ETL) asociada. |
| schema_destino | character varying(100) | no |  |  |  | Nombre del esquema de base de datos poblado (ej: sector_publico). |
| tabla_destino | character varying(100) | no |  |  |  | Nombre de la tabla de base de datos poblada (ej: institucion). |
| periodo_inicio | date | sí |  |  |  | Fecha que indica el inicio del período de la información ingresada. |
| periodo_fin | date | sí |  |  |  | Fecha que indica el fin del período de la información ingresada. |
| notas | text | sí |  |  |  | Información adicional pertinente a los datos cargados en esta tabla específica. |

### `meta.estado_carga`

Catálogo de estados de la ejecución de una carga de datos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único autogenerado del estado de carga. |
| nombre | character varying(50) | no |  |  |  | Nombre del estado (ej: en_proceso, exitosa, fallida, parcial). |

### `meta.fuente`

Entidad o sistema externo que produce los datos (ej. INE, MINGOB). Una misma fuente puede tener múltiples cargas a lo largo del tiempo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único autogenerado de la fuente. |
| codigo | character varying(50) | no |  |  |  | Clave estable y legible con la que el proceso ETL referencia la fuente (ej. INE_CENSO_2018). |
| tipo_fuente_id | integer | no |  | meta.tipo_fuente(id) |  | Referencia a la forma en que se obtienen los datos de esta fuente. |
| nombre | character varying(200) | no |  |  |  | Nombre completo y descriptivo de la fuente de datos. |
| institucion | character varying(200) | sí |  |  |  | Nombre de la institución o entidad que publica los datos. |
| url | text | sí |  |  |  | URL de descarga directa, portal de datos o sitio de documentación. |
| descripcion | text | sí |  |  |  | Descripción detallada de la naturaleza de los datos y su propósito. |
| licencia | character varying(100) | sí |  |  |  | Licencia aplicable a los datos (ej: CC BY 4.0, uso público, restringida). |
| activa | boolean | no |  |  | `true` | Indica si la fuente de datos sigue vigente y en uso en el sistema. |
| creado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora en la que se registró la fuente en el catálogo. |

### `meta.tipo_fuente`

Catálogo de las formas en que se obtienen los datos (ej: archivo, api, scraping, entrada_manual).

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único autogenerado del tipo de fuente. |
| nombre | character varying(50) | no |  |  |  | Nombre del tipo de extracción o fuente de datos. |


## Schema: `patrimonio`

### `patrimonio.banco`

Catálogo de instituciones bancarias utilizadas en las declaraciones patrimoniales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del banco. |
| nombre | character varying(100) | no |  |  |  | Nombre de la institución bancaria. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el banco. |

### `patrimonio.cuenta_bancaria`

Información de cuentas bancarias declaradas por un servidor público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la cuenta bancaria registrada. |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  | Servidor público propietario de la cuenta. |
| banco_id | integer | no |  | patrimonio.banco(id) |  | Banco donde se encuentra registrada la cuenta. |
| tipo_cuenta | character varying(50) | sí |  |  |  | Tipo de cuenta bancaria (ahorro, monetaria u otro). |
| no_cuenta | character varying(50) | sí |  |  |  | Número de la cuenta bancaria declarada. |
| moneda | character varying(20) | sí |  |  |  | Moneda en la que está denominada la cuenta. |
| saldo_declarado | numeric(15,2) | sí |  |  |  | Saldo declarado para la cuenta bancaria. |
| fecha_apertura | date | sí |  |  |  | Fecha de apertura de la cuenta bancaria. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la cuenta. |

### `patrimonio.empresa`

Participaciones empresariales declaradas por un servidor público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la participación empresarial. |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  | Servidor público que participa en la empresa. |
| rol_empresa_id | integer | no |  | patrimonio.rol_empresa(id) |  | Rol desempeñado dentro de la empresa. |
| nombre | character varying(150) | sí |  |  |  | Nombre de la empresa. |
| nit | character varying(20) | sí |  |  |  | Número de Identificación Tributaria de la empresa. |
| area_m2 | numeric(12,4) | sí |  |  |  | Área física de las instalaciones de la empresa, expresada en metros cuadrados. |
| porcentaje_participacion | numeric(5,2) | sí |  |  |  | Porcentaje de participación accionaria o patrimonial. |
| valor_declarado | numeric(15,2) | sí |  |  |  | Valor declarado de la participación empresarial. |
| fecha_inicio_participacion | date | sí |  |  |  | Fecha de inicio de la participación en la empresa. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la participación. |

### `patrimonio.inmueble`

Bienes inmuebles declarados por un servidor público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del inmueble registrado. |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  | Servidor público propietario del inmueble. |
| municipio_id | integer | no |  | geografia.municipio(id) |  | Municipio donde se ubica el inmueble. |
| direccion | character varying(255) | sí |  |  |  | Dirección del inmueble. |
| no_finca | character varying(50) | sí |  |  |  | Número de finca o identificador registral del inmueble. |
| area_m2 | numeric(12,4) | sí |  |  |  | Área del inmueble expresada en metros cuadrados. |
| valor_declarado | numeric(15,2) | sí |  |  |  | Valor declarado del inmueble. |
| forma_adquisicion | character varying(100) | sí |  |  |  | Forma mediante la cual fue adquirido el inmueble. |
| fecha_adquisicion | date | sí |  |  |  | Fecha de adquisición del inmueble. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el inmueble. |

### `patrimonio.rol_empresa`

Catálogo de roles que una persona puede desempeñar dentro de una empresa.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del rol empresarial. |
| nombre | character varying(100) | no |  |  |  | Nombre del rol empresarial. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el rol empresarial. |

### `patrimonio.vehiculo`

Vehículos declarados como parte del patrimonio de un servidor público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del vehículo registrado. |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  | Servidor público propietario del vehículo. |
| placa | character varying(20) | sí |  |  |  | Número de placa del vehículo. |
| marca | character varying(50) | sí |  |  |  | Marca del vehículo. |
| modelo | character varying(50) | sí |  |  |  | Modelo del vehículo. |
| anio | integer | sí |  |  |  | Año de fabricación del vehículo. |
| valor_declarado | numeric(15,2) | sí |  |  |  | Valor declarado del vehículo. |
| fecha_adquisicion | date | sí |  |  |  | Fecha de adquisición del vehículo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el vehículo. |


## Schema: `sector_publico`

### `sector_publico.banco`

Catalogo de bancos para declaraciones de bienes de trabajadores.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| nombre | character varying(150) | no |  |  |  |  |

### `sector_publico.cargo`

Catálogo de cargos o puestos existentes dentro de una institución pública.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del cargo. |
| institucion_id | integer | no |  | sector_publico.institucion(id) |  | Institución a la que pertenece el cargo. |
| cargo_jefe_id | integer | sí |  | sector_publico.cargo(id) |  | Cargo superior inmediato dentro de la jerarquía organizacional. |
| nombre | character varying(150) | sí |  |  |  | Nombre del cargo. |
| descripcion | text | sí |  |  |  | Descripción de las funciones o responsabilidades del cargo. |
| fecha_creacion | date | sí |  |  |  | Fecha en que fue creado el cargo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el cargo. |

### `sector_publico.contrato`

Relación laboral entre un trabajador y una institución pública.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del contrato. |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  | Trabajador contratado. |
| institucion_id | integer | no |  | sector_publico.institucion(id) |  | Institución contratante. |
| cargo_id | integer | no |  | sector_publico.cargo(id) |  | Cargo desempeñado por el trabajador. |
| tipo_contrato_id | integer | no |  | sector_publico.tipo_contrato(id) |  | Tipo de contrato aplicado. |
| sueldo_base | numeric(15,2) | sí |  |  |  | Sueldo base asignado al contrato. |
| fecha_inicio | date | sí |  |  |  | Fecha de inicio de vigencia del contrato. |
| fecha_fin | date | sí |  |  |  | Fecha de finalización del contrato, si aplica. |
| esta_activo | boolean | no |  |  | `true` | Indica si el contrato se encuentra vigente. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el contrato. |

### `sector_publico.cuenta_bancaria`

Cuentas bancarias declaradas por trabajadores del sector publico.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  |  |
| banco_id | integer | no |  | sector_publico.banco(id) |  |  |
| tipo_cuenta | character varying(50) | sí |  |  |  |  |
| no_cuenta | character varying(50) | sí |  |  |  |  |
| moneda | character varying(10) | sí |  |  | `'GTQ'::character varying` |  |
| saldo_declarado | numeric(15,2) | sí |  |  |  |  |
| fecha_apertura | date | sí |  |  |  |  |

### `sector_publico.empresa`

Empresas privadas en las que participa un trabajador del sector publico.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  |  |
| rol_empresa_id | integer | sí |  | sector_publico.rol_empresa(id) |  |  |
| nombre | character varying(200) | no |  |  |  |  |
| nit | character varying(20) | sí |  |  |  |  |
| porcentaje_participacion | numeric(5,2) | sí |  |  |  |  |
| valor_declarado | numeric(15,2) | sí |  |  |  |  |
| fecha_inicio_participacion | date | sí |  |  |  |  |

### `sector_publico.inmueble`

Inmuebles declarados por trabajadores del sector publico.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  |  |
| municipio_id | integer | sí |  | geografia.municipio(id) |  |  |
| direccion | text | sí |  |  |  |  |
| no_finca | character varying(50) | sí |  |  |  |  |
| area_mc | numeric(15,4) | sí |  |  |  |  |
| valor_declarado | numeric(15,2) | sí |  |  |  |  |
| forma_adquisicion | character varying(100) | sí |  |  |  |  |
| fecha_adquisicion | date | sí |  |  |  |  |

### `sector_publico.institucion`

Instituciones pertenecientes al sector público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único de la institución. |
| municipio_id | integer | no |  | geografia.municipio(id) |  | Municipio donde se ubica la sede principal de la institución. |
| tipo_institucion_id | integer | no |  | sector_publico.tipo_institucion(id) |  | Tipo de institución al que pertenece. |
| nivel_institucion_id | integer | no |  | sector_publico.nivel_institucion(id) |  | Nivel administrativo de la institución. |
| nombre | character varying(200) | no |  |  |  | Nombre oficial de la institución. |
| siglas | character varying(30) | sí |  |  |  | Siglas o acrónimo oficial de la institución. |
| direccion | character varying(255) | sí |  |  |  | Dirección física de la institución. |
| telefono | character varying(30) | sí |  |  |  | Número telefónico de contacto. |
| fecha_creacion | date | sí |  |  |  | Fecha de creación de la institución. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró la institución. |

### `sector_publico.nivel_institucion`

Catálogo de niveles administrativos de las instituciones públicas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del nivel institucional. |
| nombre | character varying(100) | no |  |  |  | Nombre del nivel institucional. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el nivel institucional. |

### `sector_publico.rol_empresa`

Rol que ejerce un trabajador en una empresa (socio, director, accionista, etc.).

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| nombre | character varying(100) | no |  |  |  |  |

### `sector_publico.tipo_contrato`

Catálogo de modalidades de contratación utilizadas en el sector público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del tipo de contrato. |
| nombre | character varying(100) | sí |  |  |  | Nombre del tipo de contrato. |
| descripcion | text | sí |  |  |  | Descripción del tipo de contratación. |
| renglon_presupuestario | character varying(50) | sí |  |  |  | Renglón presupuestario asociado al tipo de contratación. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el tipo de contrato. |

### `sector_publico.tipo_institucion`

Catálogo de tipos de instituciones que conforman el sector público.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del tipo de institución. |
| nombre | character varying(100) | no |  |  |  | Nombre del tipo de institución. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el tipo de institución. |

### `sector_publico.trabajador`

Servidores públicos asociados a una persona registrada en el sistema.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del trabajador. |
| persona_id | integer | no |  | demografia.persona(id) |  | Persona asociada al trabajador. |
| esta_activo | boolean | no |  |  | `true` | Indica si el trabajador mantiene una relación activa con el sector público. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia a la carga de datos mediante la cual se registró el trabajador. |

### `sector_publico.vehiculo`

Vehiculos declarados por trabajadores del sector publico.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` |  |
| trabajador_id | integer | no |  | sector_publico.trabajador(id) |  |  |
| placa | character varying(20) | sí |  |  |  |  |
| marca | character varying(100) | sí |  |  |  |  |
| modelo | character varying(100) | sí |  |  |  |  |
| anio | smallint | sí |  |  |  |  |
| valor_declarado | numeric(15,2) | sí |  |  |  |  |
| fecha_adquisicion | date | sí |  |  |  |  |


## Schema: `turismo`

### `turismo.actividad_turistica`

Actividades turisticas que pueden realizarse o recomendarse en los destinos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_actividad | integer | no | X |  | `IDENTITY` | Identificador unico de la actividad turistica. |
| codigo | character varying(60) | no |  |  |  | Codigo estable de la actividad. |
| nombre | character varying(140) | no |  |  |  | Nombre de la actividad turistica. |
| descripcion | text | sí |  |  |  | Descripcion de la actividad y su uso analitico. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.categoria_destino`

Categorias tematicas utilizadas para clasificar destinos turisticos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_categoria | integer | no | X |  | `IDENTITY` | Identificador unico de la categoria turistica. |
| codigo | character varying(60) | no |  |  |  | Codigo estable de la categoria. |
| nombre | character varying(120) | no |  |  |  | Nombre de la categoria. |
| descripcion | text | sí |  |  |  | Descripcion de la categoria y criterio de uso. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.departamento_region_turistica`

Tabla puente entre regiones turisticas del esquema turismo y departamentos oficiales del esquema geografia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_departamento_region | integer | no | X |  | `IDENTITY` | Identificador unico de la relacion departamento-region turistica. |
| region_turistica_id | integer | no |  | turismo.region_turistica(id_region) |  | Region turistica a la que se asocia el departamento. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial registrado en geografia.departamento. |
| observacion | character varying(400) | sí |  |  |  | Nota para casos donde un departamento participa parcialmente en mas de una region turistica. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_actividad`

Relacion muchos a muchos entre destinos y actividades turisticas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico asociado a la actividad. |
| actividad_id | integer | no | X | turismo.actividad_turistica(id_actividad) |  | Actividad turistica disponible o recomendada. |
| notas | character varying(500) | sí |  |  |  | Notas sobre alcance o condiciones de la actividad en el destino. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_categoria`

Relacion muchos a muchos entre destinos turisticos y categorias.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico clasificado. |
| categoria_id | integer | no | X | turismo.categoria_destino(id_categoria) |  | Categoria asignada al destino. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_fuente`

Fuentes documentales que respaldan la informacion de cada destino turistico.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico documentado. |
| fuente_id | integer | no | X | turismo.fuente_turistica(id_fuente) |  | Fuente turistica relacionada con el destino. |
| detalle | character varying(600) | sí |  |  |  | Detalle sobre el uso de la fuente para el destino. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_patrimonio`

Relacion entre destinos turisticos y reconocimientos patrimoniales.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico asociado al patrimonio. |
| patrimonio_id | integer | no | X | turismo.patrimonio_turistico(id_patrimonio) |  | Patrimonio asociado al destino. |
| observacion | character varying(600) | sí |  |  |  | Observacion de la relacion entre destino y patrimonio. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_temporada`

Relacion entre destinos y temporadas recomendadas para visita.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico asociado a la temporada. |
| temporada_id | integer | no | X | turismo.temporada_turistica(id_temporada) |  | Temporada recomendada o relevante. |
| recomendacion | character varying(600) | sí |  |  |  | Recomendacion especifica para visitar el destino en la temporada indicada. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.destino_turistico`

Destinos turisticos reales de Guatemala documentados para consulta, ETL y analitica BI.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_destino | integer | no | X |  | `IDENTITY` | Identificador unico del destino turistico. |
| codigo | character varying(80) | no |  |  |  | Codigo estable del destino turistico para migraciones y ETL. |
| nombre | character varying(220) | no |  |  |  | Nombre del destino turistico. |
| tipo | turismo.tipo_destino | no |  |  |  | Tipo general del destino turistico. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial donde se ubica el destino, referenciado desde geografia.departamento. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial donde se ubica el destino, referenciado desde geografia.municipio cuando se conoce. |
| region_turistica_id | integer | sí |  | turismo.region_turistica(id_region) |  | Region turistica principal asociada al destino. Se usa para evitar ambiguedad en departamentos que participan parcialmente en mas de una region turistica. |
| descripcion | text | no |  |  |  | Descripcion documentada del destino turistico. |
| direccion_referencia | character varying(500) | sí |  |  |  | Referencia textual de ubicacion, acceso o zona del destino. |
| latitud | numeric(10,7) | sí |  |  |  | Latitud aproximada del destino turistico. |
| longitud | numeric(10,7) | sí |  |  |  | Longitud aproximada del destino turistico. |
| altitud_msnm | integer | sí |  |  |  | Altitud aproximada sobre el nivel del mar, cuando se conoce. |
| dificultad | turismo.dificultad_destino | no |  |  | `'BAJA'::turismo.dificultad_destino` | Nivel de dificultad general para visitar el destino. |
| tiempo_recomendado | character varying(120) | sí |  |  |  | Tiempo recomendado de visita. |
| costo_aprox_nacional_q | numeric(10,2) | sí |  |  |  | Costo aproximado para visitante nacional, en quetzales, cuando existe dato publico. |
| costo_aprox_extranjero_q | numeric(10,2) | sí |  |  |  | Costo aproximado para visitante extranjero, en quetzales, cuando existe dato publico. |
| horario | character varying(250) | sí |  |  |  | Horario de visita o atencion cuando se tiene publicado. |
| es_area_protegida | boolean | no |  |  | `false` | Indica si el destino pertenece o se relaciona con un area protegida. |
| fuente_principal_id | integer | sí |  | turismo.fuente_turistica(id_fuente) |  | Fuente turistica principal usada para documentar el destino. |
| activo | boolean | no |  |  | `true` | Indica si el destino se mantiene activo para consulta. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.dim_actividad`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_actividad | integer | no | X |  |  | Campo id actividad del objeto BI o ETL de turismo. |
| nombre | character varying(120) | no |  |  |  | Nombre del registro. |
| descripcion | character varying(350) | sí |  |  |  | Descripcion del registro. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_actividad_turismo`

Dimension BI de actividades turisticas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_dim_actividad | integer | no | X |  | `IDENTITY` | Llave surrogate de actividad BI. |
| actividad_id | integer | no |  | turismo.actividad_turistica(id_actividad) |  | Llave natural hacia turismo.actividad_turistica. |
| codigo | character varying(60) | no |  |  |  | Codigo de actividad. |
| nombre | character varying(140) | no |  |  |  | Nombre de actividad. |
| descripcion | text | sí |  |  |  | Descripcion de actividad. |
| fecha_actualizacion | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de actualizacion dimensional. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga. |

### `turismo.dim_categoria`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_categoria | integer | no | X |  |  | Campo id categoria del objeto BI o ETL de turismo. |
| nombre | character varying(100) | no |  |  |  | Nombre del registro. |
| descripcion | character varying(350) | sí |  |  |  | Descripcion del registro. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_categoria_turismo`

Dimension BI de categorias turisticas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_dim_categoria | integer | no | X |  | `IDENTITY` | Llave surrogate de categoria BI. |
| categoria_id | integer | no |  | turismo.categoria_destino(id_categoria) |  | Llave natural hacia turismo.categoria_destino. |
| codigo | character varying(60) | no |  |  |  | Codigo de categoria. |
| nombre | character varying(120) | no |  |  |  | Nombre de categoria. |
| descripcion | text | sí |  |  |  | Descripcion de categoria. |
| fecha_actualizacion | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de actualizacion dimensional. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga. |

### `turismo.dim_departamento`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_departamento | integer | no | X |  |  | Campo id departamento del objeto BI o ETL de turismo. |
| codigo_ine | character(2) | no |  |  |  | Campo codigo ine del objeto BI o ETL de turismo. |
| nombre | character varying(80) | no |  |  |  | Nombre del registro. |
| id_region | integer | no |  | turismo.dim_region(id_region) |  | Campo id region del objeto BI o ETL de turismo. |
| region_nombre | character varying(120) | no |  |  |  | Campo region nombre del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_destino`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_destino | integer | no | X |  |  | Campo id destino del objeto BI o ETL de turismo. |
| nombre | character varying(180) | no |  |  |  | Nombre del registro. |
| tipo | character varying(40) | no |  |  |  | Campo tipo del objeto BI o ETL de turismo. |
| id_departamento | integer | no |  | turismo.dim_departamento(id_departamento) |  | Campo id departamento del objeto BI o ETL de turismo. |
| departamento_nombre | character varying(80) | no |  |  |  | Campo departamento nombre del objeto BI o ETL de turismo. |
| id_municipio | integer | sí |  | turismo.dim_municipio(id_municipio) |  | Campo id municipio del objeto BI o ETL de turismo. |
| municipio_nombre | character varying(120) | sí |  |  |  | Campo municipio nombre del objeto BI o ETL de turismo. |
| id_region | integer | no |  | turismo.dim_region(id_region) |  | Campo id region del objeto BI o ETL de turismo. |
| region_nombre | character varying(120) | no |  |  |  | Campo region nombre del objeto BI o ETL de turismo. |
| descripcion | text | no |  |  |  | Descripcion del registro. |
| direccion_referencia | character varying(350) | sí |  |  |  | Campo direccion referencia del objeto BI o ETL de turismo. |
| latitud | numeric(10,7) | sí |  |  |  | Campo latitud del objeto BI o ETL de turismo. |
| longitud | numeric(10,7) | sí |  |  |  | Campo longitud del objeto BI o ETL de turismo. |
| altitud_msnm | integer | sí |  |  |  | Campo altitud msnm del objeto BI o ETL de turismo. |
| dificultad | character varying(40) | sí |  |  |  | Campo dificultad del objeto BI o ETL de turismo. |
| tiempo_recomendado | character varying(80) | sí |  |  |  | Campo tiempo recomendado del objeto BI o ETL de turismo. |
| costo_aprox_nacional_q | numeric(10,2) | sí |  |  |  | Campo costo aprox nacional q del objeto BI o ETL de turismo. |
| costo_aprox_extranjero_q | numeric(10,2) | sí |  |  |  | Campo costo aprox extranjero q del objeto BI o ETL de turismo. |
| horario | character varying(180) | sí |  |  |  | Campo horario del objeto BI o ETL de turismo. |
| es_area_protegida | boolean | no |  |  | `false` | Campo es area protegida del objeto BI o ETL de turismo. |
| id_fuente_principal | integer | sí |  |  |  | Campo id fuente principal del objeto BI o ETL de turismo. |
| fuente_principal | character varying(180) | sí |  |  |  | Campo fuente principal del objeto BI o ETL de turismo. |
| url_fuente_principal | character varying(500) | sí |  |  |  | Campo url fuente principal del objeto BI o ETL de turismo. |
| activo | boolean | no |  |  | `true` | Indica si el registro se encuentra activo. |
| checksum_origen | character varying(32) | sí |  |  |  |  |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_fecha`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha | integer | no | X |  |  | Llave de fecha en formato YYYYMMDD. |
| fecha | date | no |  |  |  |  |
| anio | integer | no |  |  |  | Anio calendario. |
| trimestre | integer | no |  |  |  | Trimestre calendario. |
| mes | integer | no |  |  |  | Numero de mes calendario. |
| nombre_mes | character varying(20) | no |  |  |  | Nombre del mes. |
| dia | integer | no |  |  |  | Dia del mes. |
| dia_semana | integer | no |  |  |  | Dia de la semana en formato ISO. |
| nombre_dia | character varying(20) | no |  |  |  | Nombre del dia de la semana. |
| semana_anio | integer | no |  |  |  | Numero de semana del anio. |
| es_fin_semana | boolean | no |  |  |  | Indica si la fecha corresponde a sabado o domingo. |

### `turismo.dim_fuente`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fuente | integer | no | X |  |  | Campo id fuente del objeto BI o ETL de turismo. |
| nombre | character varying(180) | no |  |  |  | Nombre del registro. |
| tipo | character varying(60) | no |  |  |  | Campo tipo del objeto BI o ETL de turismo. |
| url | character varying(500) | no |  |  |  | Campo url del objeto BI o ETL de turismo. |
| fecha_consulta | date | no |  |  |  | Campo fecha consulta del objeto BI o ETL de turismo. |
| notas | character varying(500) | sí |  |  |  | Campo notas del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_geografia_turistica`

Dimension BI de geografia turistica derivada de geografia.departamento, geografia.municipio y turismo.region_turistica.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_dim_geografia | integer | no | X |  | `IDENTITY` | Llave surrogate de la dimension geografia turistica. |
| departamento_id | integer | no |  | geografia.departamento(id) |  | Departamento oficial de geografia.departamento. |
| municipio_id | integer | sí |  | geografia.municipio(id) |  | Municipio oficial de geografia.municipio cuando existe. |
| departamento | character varying(120) | no |  |  |  | Nombre del departamento desnormalizado para analitica. |
| municipio | character varying(120) | sí |  |  |  | Nombre del municipio desnormalizado para analitica. |
| region_turistica_id | integer | sí |  | turismo.region_turistica(id_region) |  | Region turistica asociada. |
| region_turistica | character varying(150) | sí |  |  |  | Nombre de region turistica desnormalizado. |
| fecha_actualizacion | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de actualizacion dimensional. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga. |

### `turismo.dim_municipio`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_municipio | integer | no | X |  |  | Campo id municipio del objeto BI o ETL de turismo. |
| id_departamento | integer | no |  | turismo.dim_departamento(id_departamento) |  | Campo id departamento del objeto BI o ETL de turismo. |
| departamento_nombre | character varying(80) | no |  |  |  | Campo departamento nombre del objeto BI o ETL de turismo. |
| nombre | character varying(120) | no |  |  |  | Nombre del registro. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_patrimonio`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_patrimonio | integer | no | X |  |  | Campo id patrimonio del objeto BI o ETL de turismo. |
| tipo | character varying(40) | no |  |  |  | Campo tipo del objeto BI o ETL de turismo. |
| nombre | character varying(180) | no |  |  |  | Nombre del registro. |
| organismo | character varying(120) | no |  |  |  | Campo organismo del objeto BI o ETL de turismo. |
| anio_inscripcion | integer | sí |  |  |  | Campo anio inscripcion del objeto BI o ETL de turismo. |
| descripcion | text | sí |  |  |  | Descripcion del registro. |
| id_fuente | integer | sí |  |  |  | Campo id fuente del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_region`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_region | integer | no | X |  |  | Campo id region del objeto BI o ETL de turismo. |
| nombre | character varying(120) | no |  |  |  | Nombre del registro. |
| descripcion | text | sí |  |  |  | Descripcion del registro. |
| id_fuente | integer | sí |  |  |  | Campo id fuente del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_region_turistica`

Dimension BI de regiones turisticas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_dim_region | integer | no | X |  | `IDENTITY` | Llave surrogate de la dimension region turistica. |
| region_turistica_id | integer | no |  | turismo.region_turistica(id_region) |  | Llave natural hacia turismo.region_turistica. |
| codigo | character varying(50) | no |  |  |  | Codigo de region turistica. |
| nombre | character varying(150) | no |  |  |  | Nombre de la region turistica. |
| descripcion | text | sí |  |  |  | Descripcion de la region turistica. |
| fecha_actualizacion | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de actualizacion dimensional. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga. |

### `turismo.dim_ruta`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_ruta | integer | no | X |  |  | Campo id ruta del objeto BI o ETL de turismo. |
| id_region | integer | sí |  | turismo.dim_region(id_region) |  | Campo id region del objeto BI o ETL de turismo. |
| region_nombre | character varying(120) | sí |  |  |  | Campo region nombre del objeto BI o ETL de turismo. |
| nombre | character varying(150) | no |  |  |  | Nombre del registro. |
| descripcion | text | sí |  |  |  | Descripcion del registro. |
| duracion_dias | integer | sí |  |  |  | Campo duracion dias del objeto BI o ETL de turismo. |
| id_fuente | integer | sí |  |  |  | Campo id fuente del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.dim_temporada`

Dimension del modelo BI de turismo utilizada para analisis descriptivo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_temporada | integer | no | X |  |  | Campo id temporada del objeto BI o ETL de turismo. |
| nombre | character varying(100) | no |  |  |  | Nombre del registro. |
| meses | character varying(80) | no |  |  |  | Campo meses del objeto BI o ETL de turismo. |
| descripcion | character varying(350) | sí |  |  |  | Descripcion del registro. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.etl_ejecucion`

Tabla de control para procesos ETL del area de turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_ejecucion | bigint | no | X |  | `IDENTITY` | Identificador de la ejecucion ETL. |
| id_job | integer | no |  | turismo.etl_job(id_job) |  | Identificador del job ETL. |
| fecha_inicio | timestamp with time zone | no |  |  | `now()` | Fecha y hora de inicio de la ejecucion. |
| fecha_fin | timestamp with time zone | sí |  |  |  | Fecha y hora de finalizacion de la ejecucion. |
| estado | character varying(20) | no |  |  | `'INICIADO'::character varying` | Estado de la ejecucion o validacion. |
| filas_insertadas | bigint | no |  |  | `0` | Cantidad de filas insertadas. |
| filas_actualizadas | bigint | no |  |  | `0` | Cantidad de filas actualizadas. |
| filas_error | bigint | no |  |  | `0` | Cantidad de filas con error. |
| mensaje | text | sí |  |  |  | Mensaje de resultado o diagnostico. |

### `turismo.etl_ejecucion_turismo`

Bitacora de ejecuciones ETL especificas del area turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_ejecucion | integer | no | X |  | `IDENTITY` | Identificador unico de ejecucion ETL. |
| nombre_proceso | character varying(160) | no |  |  |  | Nombre del proceso ETL ejecutado. |
| tipo_proceso | character varying(60) | no |  |  |  | Tipo de proceso: STAGING, DIMENSIONAL, HECHOS, DATAMART u otro. |
| fecha_inicio | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha y hora de inicio de la ejecucion. |
| fecha_fin | timestamp without time zone | sí |  |  |  | Fecha y hora de finalizacion de la ejecucion. |
| estado | character varying(40) | no |  |  | `'INICIADO'::character varying` | Estado del proceso: INICIADO, FINALIZADO, ERROR. |
| registros_leidos | integer | no |  |  | `0` | Cantidad de registros leidos por el proceso. |
| registros_insertados | integer | no |  |  | `0` | Cantidad de registros insertados por el proceso. |
| registros_actualizados | integer | no |  |  | `0` | Cantidad de registros actualizados por el proceso. |
| registros_rechazados | integer | no |  |  | `0` | Cantidad de registros rechazados por el proceso. |
| observacion | text | sí |  |  |  | Detalle o mensaje del proceso. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga para trazabilidad transversal. |

### `turismo.etl_error_turismo`

Errores detectados durante procesos ETL del area turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_error | integer | no | X |  | `IDENTITY` | Identificador unico del error ETL. |
| ejecucion_id | integer | sí |  | turismo.etl_ejecucion_turismo(id_ejecucion) |  | Ejecucion ETL asociada al error. |
| tabla_destino | character varying(180) | sí |  |  |  | Tabla destino relacionada con el error. |
| codigo_registro | character varying(160) | sí |  |  |  | Codigo o llave del registro que produjo el error. |
| mensaje_error | text | no |  |  |  | Descripcion del error detectado. |
| datos_origen | jsonb | sí |  |  |  | Datos originales del registro en formato JSONB para trazabilidad. |
| fecha_error | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha y hora del error. |

### `turismo.etl_job`

Tabla de control para procesos ETL del area de turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_job | integer | no | X |  | `IDENTITY` | Identificador del job ETL. |
| nombre | character varying(120) | no |  |  |  | Nombre del registro. |
| descripcion | text | sí |  |  |  | Descripcion del registro. |
| frecuencia_sugerida | character varying(80) | sí |  |  |  | Frecuencia sugerida de ejecucion. |
| activo | boolean | no |  |  | `true` | Indica si el registro se encuentra activo. |
| creado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora de creacion del registro. |

### `turismo.etl_validacion`

Tabla de control para procesos ETL del area de turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_validacion | bigint | no | X |  | `IDENTITY` | Identificador de la validacion. |
| id_ejecucion | bigint | sí |  | turismo.etl_ejecucion(id_ejecucion) |  | Identificador de la ejecucion ETL. |
| entidad | character varying(120) | no |  |  |  | Entidad o tabla validada. |
| regla | character varying(220) | no |  |  |  | Regla de validacion aplicada. |
| nivel | character varying(20) | no |  |  | `'INFO'::character varying` | Nivel de severidad de la validacion. |
| total_registros | bigint | no |  |  | `0` | Total de registros evaluados. |
| total_observaciones | bigint | no |  |  | `0` | Total de observaciones encontradas. |
| detalle | text | sí |  |  |  | Detalle de la validacion. |
| fecha_validacion | timestamp with time zone | no |  |  | `now()` | Fecha y hora de validacion. |

### `turismo.fact_destino_actividad`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| id_actividad | integer | no | X | turismo.dim_actividad(id_actividad) |  | Campo id actividad del objeto BI o ETL de turismo. |
| cantidad | integer | no |  |  | `1` | Cantidad contabilizada para el hecho. |
| notas | character varying(300) | sí |  |  |  | Campo notas del objeto BI o ETL de turismo. |

### `turismo.fact_destino_catalogo`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| id_region | integer | no |  | turismo.dim_region(id_region) |  | Campo id region del objeto BI o ETL de turismo. |
| id_departamento | integer | no |  | turismo.dim_departamento(id_departamento) |  | Campo id departamento del objeto BI o ETL de turismo. |
| id_municipio | integer | sí |  | turismo.dim_municipio(id_municipio) |  | Campo id municipio del objeto BI o ETL de turismo. |
| tipo | character varying(40) | no |  |  |  | Campo tipo del objeto BI o ETL de turismo. |
| dificultad | character varying(40) | sí |  |  |  | Campo dificultad del objeto BI o ETL de turismo. |
| total_categorias | integer | no |  |  | `0` | Campo total categorias del objeto BI o ETL de turismo. |
| total_actividades | integer | no |  |  | `0` | Campo total actividades del objeto BI o ETL de turismo. |
| total_temporadas | integer | no |  |  | `0` | Campo total temporadas del objeto BI o ETL de turismo. |
| total_fuentes | integer | no |  |  | `0` | Campo total fuentes del objeto BI o ETL de turismo. |
| total_recomendaciones | integer | no |  |  | `0` | Campo total recomendaciones del objeto BI o ETL de turismo. |
| tiene_patrimonio | boolean | no |  |  | `false` | Campo tiene patrimonio del objeto BI o ETL de turismo. |
| total_patrimonios | integer | no |  |  | `0` | Campo total patrimonios del objeto BI o ETL de turismo. |
| es_area_protegida | boolean | no |  |  | `false` | Campo es area protegida del objeto BI o ETL de turismo. |
| tiene_coordenadas | boolean | no |  |  | `false` | Campo tiene coordenadas del objeto BI o ETL de turismo. |
| tiene_horario | boolean | no |  |  | `false` | Campo tiene horario del objeto BI o ETL de turismo. |
| costo_aprox_nacional_q | numeric(10,2) | sí |  |  |  | Campo costo aprox nacional q del objeto BI o ETL de turismo. |
| costo_aprox_extranjero_q | numeric(10,2) | sí |  |  |  | Campo costo aprox extranjero q del objeto BI o ETL de turismo. |
| puntaje_bi_catalogo | numeric(8,2) | no |  |  | `0` | Puntaje calculado para priorizar destinos en tableros BI. |
| fecha_actualizacion | timestamp with time zone | no |  |  | `now()` | Fecha y hora de actualizacion del hecho. |

### `turismo.fact_destino_categoria`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| id_categoria | integer | no | X | turismo.dim_categoria(id_categoria) |  | Campo id categoria del objeto BI o ETL de turismo. |
| cantidad | integer | no |  |  | `1` | Cantidad contabilizada para el hecho. |

### `turismo.fact_destino_patrimonio`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| id_patrimonio | integer | no | X | turismo.dim_patrimonio(id_patrimonio) |  | Campo id patrimonio del objeto BI o ETL de turismo. |
| cantidad | integer | no |  |  | `1` | Cantidad contabilizada para el hecho. |
| observacion | character varying(350) | sí |  |  |  | Campo observacion del objeto BI o ETL de turismo. |

### `turismo.fact_destino_temporada`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| id_temporada | integer | no | X | turismo.dim_temporada(id_temporada) |  | Campo id temporada del objeto BI o ETL de turismo. |
| cantidad | integer | no |  |  | `1` | Cantidad contabilizada para el hecho. |
| recomendacion | character varying(350) | sí |  |  |  | Campo recomendacion del objeto BI o ETL de turismo. |

### `turismo.fact_destino_turistico`

Tabla de hechos BI a nivel de destino turistico; contiene indicadores derivados del catalogo curado.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino turistico que funciona como grano del hecho. |
| id_dim_region | integer | sí |  | turismo.dim_region_turistica(id_dim_region) |  | Dimension region turistica asociada. |
| id_dim_geografia | integer | sí |  | turismo.dim_geografia_turistica(id_dim_geografia) |  | Dimension geografia turistica asociada. |
| tipo | turismo.tipo_destino | no |  |  |  | Tipo de destino. |
| dificultad | turismo.dificultad_destino | no |  |  |  | Dificultad de visita. |
| es_area_protegida | boolean | no |  |  |  | Indicador de area protegida. |
| tiene_patrimonio | boolean | no |  |  |  | Indicador de reconocimiento patrimonial asociado. |
| total_categorias | integer | no |  |  | `0` | Cantidad de categorias asociadas al destino. |
| total_actividades | integer | no |  |  | `0` | Cantidad de actividades asociadas al destino. |
| total_temporadas | integer | no |  |  | `0` | Cantidad de temporadas asociadas al destino. |
| total_patrimonios | integer | no |  |  | `0` | Cantidad de patrimonios asociados al destino. |
| puntaje_bi_catalogo | numeric(10,2) | no |  |  | `0` | Puntaje analitico calculado para priorizacion de destinos en dashboard. |
| fecha_actualizacion | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de actualizacion del hecho. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional a meta.carga. |

### `turismo.fact_metrica_destino`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha en formato YYYYMMDD. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| fuente_metrica | character varying(180) | no | X |  |  | Campo fuente metrica del objeto BI o ETL de turismo. |
| visitantes_nacionales | integer | sí |  |  |  | Campo visitantes nacionales del objeto BI o ETL de turismo. |
| visitantes_extranjeros | integer | sí |  |  |  | Campo visitantes extranjeros del objeto BI o ETL de turismo. |
| calificacion_promedio | numeric(4,2) | sí |  |  |  | Campo calificacion promedio del objeto BI o ETL de turismo. |
| cantidad_resenas | integer | sí |  |  |  | Campo cantidad resenas del objeto BI o ETL de turismo. |
| busquedas_web | integer | sí |  |  |  | Campo busquedas web del objeto BI o ETL de turismo. |
| menciones_redes | integer | sí |  |  |  | Campo menciones redes del objeto BI o ETL de turismo. |
| fecha_carga_dw | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga en el modelo dimensional. |

### `turismo.fact_ruta_destino`

Tabla de hechos del modelo BI de turismo utilizada para indicadores y metricas.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fecha_carga | integer | no | X | turismo.dim_fecha(id_fecha) |  | Llave de fecha asociada a la carga del hecho. |
| id_ruta | integer | no | X | turismo.dim_ruta(id_ruta) |  | Campo id ruta del objeto BI o ETL de turismo. |
| id_destino | integer | no | X | turismo.dim_destino(id_destino) |  | Campo id destino del objeto BI o ETL de turismo. |
| orden_visita | integer | no |  |  |  | Campo orden visita del objeto BI o ETL de turismo. |
| tiempo_sugerido | character varying(80) | sí |  |  |  | Campo tiempo sugerido del objeto BI o ETL de turismo. |
| duracion_dias | integer | sí |  |  |  | Campo duracion dias del objeto BI o ETL de turismo. |
| cantidad | integer | no |  |  | `1` | Cantidad contabilizada para el hecho. |

### `turismo.fuente_turistica`

Fuentes documentales utilizadas para sustentar los datos reales del area de turismo.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_fuente | integer | no | X |  | `IDENTITY` | Identificador unico de la fuente turistica dentro del esquema turismo. |
| codigo | character varying(80) | no |  |  |  | Codigo estable de la fuente para usar en migraciones, ETL y trazabilidad. |
| nombre | character varying(220) | no |  |  |  | Nombre oficial o descriptivo de la fuente consultada. |
| institucion | character varying(180) | sí |  |  |  | Institucion, organismo o portal responsable de la fuente. |
| tipo | character varying(80) | no |  |  |  | Tipo de fuente: oficial, internacional, cultural, conservacion, turismo u otro. |
| url | character varying(700) | no |  |  |  | URL principal consultada. |
| fecha_consulta | date | no |  |  |  | Fecha de consulta de la fuente. |
| descripcion | text | sí |  |  |  | Descripcion del uso de la fuente dentro del modelo turismo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.patrimonio_turistico`

Patrimonios UNESCO, nacionales o intangibles vinculados con el turismo en Guatemala.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_patrimonio | integer | no | X |  | `IDENTITY` | Identificador unico del patrimonio turistico. |
| codigo | character varying(80) | no |  |  |  | Codigo estable del patrimonio. |
| tipo | turismo.tipo_patrimonio | no |  |  |  | Tipo de reconocimiento patrimonial. |
| nombre | character varying(220) | no |  |  |  | Nombre del patrimonio o expresion cultural. |
| organismo | character varying(160) | no |  |  |  | Organismo que reconoce o respalda el patrimonio. |
| anio_inscripcion | integer | sí |  |  |  | Anio de inscripcion o reconocimiento, cuando aplica. |
| descripcion | text | sí |  |  |  | Descripcion resumida del valor patrimonial. |
| fuente_id | integer | sí |  | turismo.fuente_turistica(id_fuente) |  | Fuente principal que respalda el patrimonio. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.recomendacion_destino`

Recomendaciones turisticas, logisticas, culturales, ambientales, de seguridad o temporada por destino.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_recomendacion | integer | no | X |  | `IDENTITY` | Identificador unico de la recomendacion. |
| destino_id | integer | no |  | turismo.destino_turistico(id_destino) |  | Destino al que aplica la recomendacion. |
| tipo | turismo.tipo_recomendacion | no |  |  |  | Tipo de recomendacion. |
| recomendacion | character varying(800) | no |  |  |  | Texto de la recomendacion. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.region_turistica`

Regiones turisticas de Guatemala utilizadas para agrupar atractivos y destinos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_region | integer | no | X |  | `IDENTITY` | Identificador unico de la region turistica. |
| codigo | character varying(50) | no |  |  |  | Codigo estable de la region turistica. |
| nombre | character varying(150) | no |  |  |  | Nombre de la region turistica. |
| descripcion | text | sí |  |  |  | Descripcion general de la region turistica. |
| fuente_id | integer | sí |  | turismo.fuente_turistica(id_fuente) |  | Fuente documental principal que respalda la definicion de la region. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.ruta_destino`

Detalle de destinos incluidos en cada ruta turistica sugerida.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| ruta_id | integer | no | X | turismo.ruta_turistica(id_ruta) |  | Ruta turistica que contiene el destino. |
| destino_id | integer | no | X | turismo.destino_turistico(id_destino) |  | Destino incluido en la ruta. |
| orden_visita | integer | no |  |  |  | Orden sugerido de visita dentro de la ruta. |
| tiempo_sugerido | character varying(120) | sí |  |  |  | Tiempo sugerido para visitar el destino dentro de la ruta. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.ruta_turistica`

Rutas turisticas sugeridas para recorrer destinos relacionados.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_ruta | integer | no | X |  | `IDENTITY` | Identificador unico de la ruta turistica. |
| codigo | character varying(80) | no |  |  |  | Codigo estable de la ruta. |
| nombre | character varying(180) | no |  |  |  | Nombre de la ruta turistica. |
| region_id | integer | sí |  | turismo.region_turistica(id_region) |  | Region turistica principal asociada a la ruta. |
| descripcion | text | sí |  |  |  | Descripcion general de la ruta. |
| duracion_dias | integer | sí |  |  |  | Duracion sugerida de la ruta en dias. |
| fuente_id | integer | sí |  | turismo.fuente_turistica(id_fuente) |  | Fuente principal usada para documentar la ruta. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.stg_destino_raw`

Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_stg_destino | bigint | no | X |  | `IDENTITY` | Campo id stg destino del objeto BI o ETL de turismo. |
| nombre_archivo | character varying(260) | sí |  |  |  | Nombre del archivo origen. |
| nombre_destino | character varying(180) | no |  |  |  | Campo nombre destino del objeto BI o ETL de turismo. |
| tipo | character varying(80) | sí |  |  |  | Campo tipo del objeto BI o ETL de turismo. |
| departamento | character varying(80) | sí |  |  |  | Campo departamento del objeto BI o ETL de turismo. |
| municipio | character varying(120) | sí |  |  |  | Campo municipio del objeto BI o ETL de turismo. |
| region_turistica | character varying(120) | sí |  |  |  | Campo region turistica del objeto BI o ETL de turismo. |
| descripcion | text | sí |  |  |  | Descripcion del registro. |
| direccion_referencia | character varying(350) | sí |  |  |  | Campo direccion referencia del objeto BI o ETL de turismo. |
| latitud | numeric(10,7) | sí |  |  |  | Campo latitud del objeto BI o ETL de turismo. |
| longitud | numeric(10,7) | sí |  |  |  | Campo longitud del objeto BI o ETL de turismo. |
| altitud_msnm | integer | sí |  |  |  | Campo altitud msnm del objeto BI o ETL de turismo. |
| dificultad | character varying(40) | sí |  |  |  | Campo dificultad del objeto BI o ETL de turismo. |
| tiempo_recomendado | character varying(80) | sí |  |  |  | Campo tiempo recomendado del objeto BI o ETL de turismo. |
| costo_aprox_nacional_q | numeric(10,2) | sí |  |  |  | Campo costo aprox nacional q del objeto BI o ETL de turismo. |
| costo_aprox_extranjero_q | numeric(10,2) | sí |  |  |  | Campo costo aprox extranjero q del objeto BI o ETL de turismo. |
| horario | character varying(180) | sí |  |  |  | Campo horario del objeto BI o ETL de turismo. |
| es_area_protegida | boolean | sí |  |  |  | Campo es area protegida del objeto BI o ETL de turismo. |
| url_fuente | character varying(600) | sí |  |  |  | Campo url fuente del objeto BI o ETL de turismo. |
| raw_payload | jsonb | sí |  |  |  | Registro original en formato JSON para auditoria o reproceso. |
| cargado_por | character varying(120) | sí |  |  | `CURRENT_USER` | Usuario que cargo el registro. |
| cargado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga del registro. |
| procesado | boolean | no |  |  | `false` | Indica si el registro fue procesado por el ETL. |
| mensaje_proceso | text | sí |  |  |  | Mensaje generado durante el procesamiento. |

### `turismo.stg_destino_turistico`

Tabla staging para cargar destinos turisticos desde CSV, Excel, APIs o fuentes externas antes de normalizarlos.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_stg | integer | no | X |  | `IDENTITY` | Identificador tecnico del registro staging. |
| codigo | character varying(80) | sí |  |  |  | Codigo del destino recibido desde la fuente. |
| nombre | character varying(220) | sí |  |  |  | Nombre del destino recibido desde la fuente. |
| tipo | character varying(60) | sí |  |  |  | Tipo de destino recibido como texto antes de validar contra el enum. |
| departamento | character varying(120) | sí |  |  |  | Departamento recibido como texto, a resolver contra geografia.departamento. |
| municipio | character varying(120) | sí |  |  |  | Municipio recibido como texto, a resolver contra geografia.municipio. |
| descripcion | text | sí |  |  |  | Descripcion del destino recibida desde fuente externa. |
| direccion_referencia | character varying(500) | sí |  |  |  | Referencia textual de ubicacion recibida desde fuente externa. |
| latitud | numeric(10,7) | sí |  |  |  | Latitud recibida desde fuente externa. |
| longitud | numeric(10,7) | sí |  |  |  | Longitud recibida desde fuente externa. |
| altitud_msnm | integer | sí |  |  |  | Altitud recibida desde fuente externa. |
| dificultad | character varying(60) | sí |  |  |  | Dificultad recibida como texto antes de validar contra el enum. |
| tiempo_recomendado | character varying(120) | sí |  |  |  | Tiempo sugerido recibido desde fuente externa. |
| es_area_protegida | boolean | sí |  |  |  | Indicador recibido desde fuente externa. |
| fuente_codigo | character varying(80) | sí |  |  |  | Codigo de fuente turistica a resolver contra turismo.fuente_turistica. |
| fecha_carga | timestamp without time zone | no |  |  | `CURRENT_TIMESTAMP` | Fecha de ingreso del registro a staging. |
| estado_validacion | character varying(40) | sí |  |  | `'PENDIENTE'::character varying` | Estado de validacion del registro staging. |
| mensaje_validacion | text | sí |  |  |  | Mensaje de validacion o rechazo. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |

### `turismo.stg_evento_usuario_raw`

Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_stg_evento | bigint | no | X |  | `IDENTITY` | Campo id stg evento del objeto BI o ETL de turismo. |
| fecha_evento | date | no |  |  |  | Campo fecha evento del objeto BI o ETL de turismo. |
| nombre_destino | character varying(180) | sí |  |  |  | Campo nombre destino del objeto BI o ETL de turismo. |
| tipo_evento | character varying(60) | no |  |  |  | Campo tipo evento del objeto BI o ETL de turismo. |
| canal | character varying(80) | sí |  |  |  |  |
| dispositivo | character varying(80) | sí |  |  |  | Campo dispositivo del objeto BI o ETL de turismo. |
| pais_usuario | character varying(80) | sí |  |  |  | Campo pais usuario del objeto BI o ETL de turismo. |
| conteo | integer | no |  |  | `1` | Campo conteo del objeto BI o ETL de turismo. |
| raw_payload | jsonb | sí |  |  |  | Registro original en formato JSON para auditoria o reproceso. |
| cargado_por | character varying(120) | sí |  |  | `CURRENT_USER` | Usuario que cargo el registro. |
| cargado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga del registro. |
| procesado | boolean | no |  |  | `false` | Indica si el registro fue procesado por el ETL. |
| mensaje_proceso | text | sí |  |  |  | Mensaje generado durante el procesamiento. |

### `turismo.stg_fuente_raw`

Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_stg_fuente | bigint | no | X |  | `IDENTITY` | Campo id stg fuente del objeto BI o ETL de turismo. |
| nombre_archivo | character varying(260) | sí |  |  |  | Nombre del archivo origen. |
| nombre_fuente | character varying(180) | sí |  |  |  | Campo nombre fuente del objeto BI o ETL de turismo. |
| tipo_fuente | character varying(80) | sí |  |  |  | Campo tipo fuente del objeto BI o ETL de turismo. |
| url | character varying(600) | sí |  |  |  | Campo url del objeto BI o ETL de turismo. |
| fecha_consulta | date | sí |  |  |  | Campo fecha consulta del objeto BI o ETL de turismo. |
| notas | text | sí |  |  |  | Campo notas del objeto BI o ETL de turismo. |
| raw_payload | jsonb | sí |  |  |  | Registro original en formato JSON para auditoria o reproceso. |
| cargado_por | character varying(120) | sí |  |  | `CURRENT_USER` | Usuario que cargo el registro. |
| cargado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga del registro. |
| procesado | boolean | no |  |  | `false` | Indica si el registro fue procesado por el ETL. |
| mensaje_proceso | text | sí |  |  |  | Mensaje generado durante el procesamiento. |

### `turismo.stg_metricas_destino_raw`

Tabla staging para recibir datos crudos de turismo antes de validarlos y cargarlos al modelo curado.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_stg_metrica | bigint | no | X |  | `IDENTITY` | Campo id stg metrica del objeto BI o ETL de turismo. |
| nombre_archivo | character varying(260) | sí |  |  |  | Nombre del archivo origen. |
| fecha_metrica | date | no |  |  |  | Campo fecha metrica del objeto BI o ETL de turismo. |
| nombre_destino | character varying(180) | no |  |  |  | Campo nombre destino del objeto BI o ETL de turismo. |
| fuente_metrica | character varying(180) | sí |  |  |  | Campo fuente metrica del objeto BI o ETL de turismo. |
| visitantes_nacionales | integer | sí |  |  |  | Campo visitantes nacionales del objeto BI o ETL de turismo. |
| visitantes_extranjeros | integer | sí |  |  |  | Campo visitantes extranjeros del objeto BI o ETL de turismo. |
| calificacion_promedio | numeric(4,2) | sí |  |  |  | Campo calificacion promedio del objeto BI o ETL de turismo. |
| cantidad_resenas | integer | sí |  |  |  | Campo cantidad resenas del objeto BI o ETL de turismo. |
| busquedas_web | integer | sí |  |  |  | Campo busquedas web del objeto BI o ETL de turismo. |
| menciones_redes | integer | sí |  |  |  | Campo menciones redes del objeto BI o ETL de turismo. |
| raw_payload | jsonb | sí |  |  |  | Registro original en formato JSON para auditoria o reproceso. |
| cargado_por | character varying(120) | sí |  |  | `CURRENT_USER` | Usuario que cargo el registro. |
| cargado_en | timestamp with time zone | no |  |  | `now()` | Fecha y hora de carga del registro. |
| procesado | boolean | no |  |  | `false` | Indica si el registro fue procesado por el ETL. |
| mensaje_proceso | text | sí |  |  |  | Mensaje generado durante el procesamiento. |

### `turismo.temporada_turistica`

Temporadas o periodos utiles para planificacion turistica.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id_temporada | integer | no | X |  | `IDENTITY` | Identificador unico de la temporada turistica. |
| codigo | character varying(60) | no |  |  |  | Codigo estable de la temporada. |
| nombre | character varying(120) | no |  |  |  | Nombre de la temporada. |
| meses | character varying(120) | no |  |  |  | Meses o periodo del anio asociado a la temporada. |
| descripcion | text | sí |  |  |  | Descripcion de condiciones o recomendaciones generales de la temporada. |
| carga_id | integer | sí |  | meta.carga(id) |  | Referencia opcional al proceso de carga registrado en meta.carga. |
