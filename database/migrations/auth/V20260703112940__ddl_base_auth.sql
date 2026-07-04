-- Migración: ddl_base_auth
-- Schema:    auth
-- Generado:  2026-07-03 11:29:40

CREATE SCHEMA IF NOT EXISTS auth;
COMMENT ON SCHEMA auth IS 'Objetos relacionados con autenticación, autorización y administración de cuentas de usuario.';


CREATE TABLE auth.rol (
    id     INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE auth.rol IS 'Catálogo de roles disponibles para controlar los permisos de acceso al sistema.';
COMMENT ON COLUMN auth.rol.id IS 'Identificador único del rol.';
COMMENT ON COLUMN auth.rol.nombre IS 'Nombre del rol.';
COMMENT ON COLUMN auth.rol.carga_id IS 'Referencia a la carga de datos mediante la cual se registró el rol.';


CREATE TABLE auth.cuenta (
    id             INT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    persona_id     INT     NOT NULL REFERENCES demografia.persona(id),
    rol_id         INT     NOT NULL REFERENCES auth.rol(id),
    nombre_usuario VARCHAR(100) NOT NULL UNIQUE,
    contrasena     VARCHAR(255) NOT NULL,
    esta_activo    BOOLEAN NOT NULL DEFAULT TRUE,
    carga_id INT REFERENCES meta.carga(id)
);
COMMENT ON TABLE auth.cuenta IS 'Credenciales de acceso asociadas a una persona registrada en el sistema.';
COMMENT ON COLUMN auth.cuenta.id IS 'Identificador único de la cuenta de usuario.';
COMMENT ON COLUMN auth.cuenta.persona_id IS 'Persona propietaria de la cuenta.';
COMMENT ON COLUMN auth.cuenta.rol_id IS 'Rol asignado a la cuenta para determinar sus permisos.';
COMMENT ON COLUMN auth.cuenta.nombre_usuario IS 'Nombre de usuario utilizado para autenticarse en el sistema.';
COMMENT ON COLUMN auth.cuenta.contrasena IS 'Contraseña almacenada de forma cifrada mediante un algoritmo seguro.';
COMMENT ON COLUMN auth.cuenta.esta_activo IS 'Indica si la cuenta se encuentra habilitada para iniciar sesión.';
COMMENT ON COLUMN auth.cuenta.carga_id IS 'Referencia a la carga de datos mediante la cual se registró la cuenta.';
