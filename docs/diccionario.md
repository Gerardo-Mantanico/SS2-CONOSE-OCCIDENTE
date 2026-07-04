# Diccionario de datos - Base de Datos Nacional

> Generado automáticamente desde la vista `meta.diccionario`. No editar a mano; regenera con `python etl/python/meta/generar_diccionario.py`.

## Contenido

- **auditoria**: `registro`
- **auth**: `cuenta`, `rol`
- **clima**: `fuente_clima`, `registro_climatico`
- **demografia**: `estado_civil`, `grupo_etnico`, `persona`, `sexo`
- **geografia**: `departamento`, `municipio`, `pais`
- **justicia**: `denuncia`, `estado_denuncia`, `registro_fecha_denuncia`, `tipo_denuncia`, `tipo_evento`
- **meta**: `carga`, `cobertura_carga`, `estado_carga`, `fuente`, `tipo_fuente`
- **patrimonio**: `banco`, `cuenta_bancaria`, `empresa`, `inmueble`, `rol_empresa`, `vehiculo`
- **sector_publico**: `cargo`, `contrato`, `institucion`, `nivel_institucion`, `tipo_contrato`, `tipo_institucion`, `trabajador`


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

### `justicia.estado_denuncia`

Catálogo de estados en los que puede encontrarse una denuncia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del estado de la denuncia. |
| nombre | character varying(100) | no |  |  |  | Nombre del estado procesal de la denuncia. |

### `justicia.registro_fecha_denuncia`

Registro cronológico de eventos asociados al trámite de una denuncia.

| Columna | Tipo | Nulo | PK | FK | Default | Descripción |
|---|---|---|---|---|---|---|
| id | integer | no | X |  | `IDENTITY` | Identificador único del registro de evento. |
| denuncia_id | integer | no |  | justicia.denuncia(id) |  | Denuncia a la que pertenece el evento registrado. |
| tipo_evento_id | integer | no |  | justicia.tipo_evento(id) |  | Tipo de evento ocurrido durante el proceso de la denuncia. |
| observaciones | text | sí |  |  |  | Observaciones o detalles relacionados con el evento. |
| fecha | date | sí |  |  |  | Fecha en la que ocurrió el evento registrado. |

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
