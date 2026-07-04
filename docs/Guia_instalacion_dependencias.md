# Guía de Instalación local de dependencias

## PostgreSQL
### En Linux:
- Distribuciones basadas en **Debian/Ubuntu**:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```
- Distribuciones basadas en **Arch**:
```bash
sudo pacman -Syu postgresql
sudo -u postgres initdb -D /var/lib/postgres/data
```
- Distribuciones basadas en **Red Hat**:
```bash
# Desactiva el módulo predeterminado para no instalar una versión antigua y agregar el repositorio oficial 
sudo dnf module disable postgresql
sudo dnf install -y https://postgresql.org(rpm -E %rhel)-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Instalar el servidor de la versión deseada
sudo dnf install -y postgresql17-server

# Inicializar el serrvidor y la base de datos
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl start postgresql-17
sudo systemctl enable postgresql-17
```
- Verificar estado, iniciar servicio y habilitar en arranque: 
```bash
sudo systemctl status postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### En Mac
Instalar con `brew install postgresql`

### En Windows:
- Descargar instalador oficial desde https://www.postgresql.org/download/windows/
- Ejecutar y seguir los pasos del instalador

## Flyway
Se usa Flyway para el control de versiones y migraciones.

### En Linux:
- Asegurarse de tener Java instalado: `java -version`
- Descargar el tar.gz: `wget https://red-gate.com`
- Extraer el archivo: `tar -xzf flyway-commandline-10.18.2-linux-x64.tar.gz`
- Mover a /opt: `sudo mv flyway-10.18.2 /opt/flyway`
- Crear SymLink: `sudo ln -s /opt/flyway/flyway /usr/local/bin/flyway`
- Verificar: `flyway -v`

Otra opción es usar snap: `sudo snap install flyway`

En distribuciones basadas en Arch, se puede usar yay: `yay -S flyway-cli`

### En MAC
Instalar con: `brew install flyway`

### En Windows:
- Descargar el instalador oficial desde la página de descarga de [Redgate Flyway Community](https://www.red-gate.com/products/flyway/community/download/).
- Ejecutar y seguir los pasos del instalador
- Automáticamente, se instala la CLI y se añaden las variables al PATH, al terminar la instalación se puede ejecutar desde la terminal
- Verificar desde consola: `flyway -version`
