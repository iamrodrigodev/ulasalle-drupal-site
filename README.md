# Proyecto Drupal 11 con DDEV

Este documento explica paso a paso cómo trabajar con un proyecto Drupal 11 en DDEV, cómo respaldar todo (código, configuración, base de datos y archivos) y cómo preparar los archivos necesarios para desplegar en un VPS. Los comandos están explicados en contexto para que quede claro qué hacen y cuándo usarlos.

---

## 1. Requisitos (local)
1. Docker instalado y funcionando.
2. DDEV instalado y configurado.
3. Git instalado.
4. Composer (opcional en host; DDEV puede ejecutar composer dentro del contenedor).

---

## 2. Estructura relevante del proyecto
- `web/` : raíz pública de Drupal (index.php, core, modules, themes).
- `config/sync/` o `sites/default/files/sync/` : carpeta donde exporta la configuración (depende de tu ajuste de sincronización).
- `web/sites/default/files/` : archivos subidos por el sitio (imágenes, documentos).
- `.ddev/` : configuración del entorno DDEV.
- `.ddev/db_snapshots/` : donde DDEV guarda las exportaciones de base de datos con `ddev export-db`.

---

## 3. Clonar y preparar el proyecto (si ya existe en Git)
Explicación: clonas el repo, inicias DDEV y recuperas dependencias. Si el proyecto fue creado localmente, omite el `git clone`.

```bash
# Clonar el repositorio
git clone <URL-del-repositorio>
cd <nombre-del-proyecto>

# Iniciar DDEV (esto arranca los contenedores configurados en .ddev)
ddev start

# Instalar dependencias con composer dentro del contenedor (recomendado)
ddev composer install
```

Qué hace cada comando:
- `git clone`: copia tu código desde GitHub/GitLab al VPS local.
- `ddev start`: arranca los contenedores Docker (web, db, router, etc.). Crea volúmenes y mapea tu directorio local dentro del contenedor.
- `ddev composer install`: instala las dependencias del `composer.json`. Se ejecuta dentro del contenedor para evitar problemas de versiones de PHP en el host.

Después de `ddev start`, puedes abrir la URL local con:
```bash
ddev launch
```

---

## 4. Trabajo diario: código vs contenido
Explicación: Drupal separa cambios en "configuración" y "contenido". Es importante saber dónde guardar cada cosa.

- **Código**: módulos personalizados, temas y archivos versionados en Git. Se maneja con commits.
- **Configuración**: vistas, tipos de contenido, roles y permisos. Se exporta a YAML y se versiona en Git.
- **Contenido**: nodos, usuarios, textos creados por el editor y referencias a archivos. Se guarda en la base de datos y no debe ir a Git.
- **Archivos (uploads)**: imágenes y documentos están en `web/sites/default/files` y no van a Git; se transfieren por scp/rsync o se empaquetan.

---

## 5. Exportar configuración (para versionar)
Explicación: cuando cambias estructuras (p. ej. creas un tipo de contenido), debes exportarlo para que otros desarrolladores y producción reciban esos cambios.

```bash
# Ejecutar desde la máquina host (no dentro de ddev ssh) en la raíz del proyecto
ddev drush cex
# Ahora añade los cambios a git y haz commit
git add config/ sites/default/files/sync/ || true
git commit -m "Exportar configuración: descripción del cambio"
git push
```

Qué hace `ddev drush cex`:
- Ejecuta `drush config-export` dentro del contenedor.
- Genera/actualiza archivos YAML en la carpeta de sincronización (`config/sync` o `sites/default/files/sync` según tu sitio).

Nota: Si el comando responde que "la configuración activa es idéntica", no hay cambios que exportar.

---

## 6. Exportar la base de datos (contenido)
Explicación: para mover contenido entre entornos o crear un backup completo, exporta la base de datos.

```bash
# Ejecutar desde la máquina host
ddev export-db --file=backup.sql
```

Resultado:
- DDEV crea un archivo comprimido ubicado en `.ddev/db_snapshots/backup.sql.gz` (el nombre final puede contener la extensión .gz).

Qué contiene:
- Todas las tablas de la base de datos (nodos, usuarios, vistas exportadas a config no incluidas aquí, etc.).

---

## 7. Respaldar archivos subidos (images, media)
Explicación: los archivos físicos no están en la base de datos y deben copiarse o empaquetarse por separado.

```bash
# Desde la raíz del proyecto
# Opción tar (recomendada por eficiencia)
tar -czvf files-backup.tar.gz web/sites/default/files

# Opción zip
zip -r files-backup.zip web/sites/default/files
```

Ambos comandos crean un archivo que puedes transferir al VPS.

---

## 8. Qué subir al VPS (lista de archivos finales)
- Código (vía Git): todo el repo excepto lo que esté en `.gitignore`.
- Configuración exportada (ya en Git): `config/sync/` o la carpeta que uses.
- Base de datos: `.ddev/db_snapshots/backup.sql.gz` (o el `backup.sql` que generes).
- Archivos subidos: `files-backup.tar.gz` o `files-backup.zip`.

---

## 9. Restaurar en el VPS (pasos detallados)
Explicación: estos pasos asumen que en el VPS tienes PHP, Composer y MySQL/MariaDB instalados, y un servidor web configurado (Nginx/Apache). Ajusta rutas y nombres de base de datos según tu entorno.

1. Subir los archivos al VPS (por SCP, SFTP o rsync). Ejemplo usando scp/rsync:
```bash
# Desde tu máquina local
scp .ddev/db_snapshots/backup.sql.gz usuario@vps:/home/usuario/
scp files-backup.tar.gz usuario@vps:/home/usuario/
# O con rsync (más eficiente para grandes archivos)
rsync -avz files/ usuario@vps:/ruta/del/sitio/web/sites/default/files
```

2. En el VPS, situarte en el directorio del proyecto (o clonar el repo):
```bash
git clone <URL-del-repo> /var/www/mi-proyecto
cd /var/www/mi-proyecto
composer install --no-dev --optimize-autoloader
```

3. Descomprimir y mover archivos subidos:
```bash
# Si subiste el tar.gz
tar -xzvf /home/usuario/files-backup.tar.gz -C /var/www/mi-proyecto/web/sites/default/
# Asegúrate de permisos
chown -R www-data:www-data /var/www/mi-proyecto/web/sites/default/files
chmod -R 775 /var/www/mi-proyecto/web/sites/default/files
```

4. Importar la base de datos:
```bash
# Descomprimir el SQL si está comprimido
gunzip /home/usuario/backup.sql.gz
# Crear la base si no existe
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
# Importar
mysql -u root -p drupal < /home/usuario/backup.sql
```

5. Configurar `settings.php` (ajustar acceso a DB y rutas de archivos). Comprueba que `settings.php` apunte a la base de datos correcta y que los valores de `file_public_path` sean válidos.

6. Limpiar caché y ejecutar actualizaciones si aplica:
```bash
# Si tienes drush en servidor
drush cr
drush updb -y   # solo si necesitas aplicar actualizaciones de base de datos
```

7. Revisar logs del servidor y de Drupal para resolver permisos o errores (system logs, PHP-FPM logs, Nginx/Apache).

---

## 10. Comandos DDEV útiles (contexto y cuándo usarlos)
- `ddev start` : arrancar contenedores del proyecto. Úsalo cuando abras el proyecto por primera vez o lo reinicies.
- `ddev stop` : detener los contenedores.
- `ddev restart` : aplicar cambios en `.ddev` (por ejemplo versión de PHP) reiniciando contenedores.
- `ddev ssh` : entrar al contenedor web en `/var/www/html` (útil para ejecutar comandos manuales).
- `ddev drush cr` : limpiar caché de Drupal, úsalo tras cambios en templates, librerías u otras modificaciones de código.
- `ddev drush cex` : exportar configuración activa a archivos YAML.
- `ddev drush cim` : importar configuración desde la carpeta de sincronización.
- `ddev export-db --file=backup.sql` : exporta la base de datos; ejecuta este comando desde la máquina host, no dentro del contenedor.
- `ddev import-db --src=archivo.sql.gz` : importar base de datos en el proyecto DDEV local.

---

## 11. Automatizar backups (script ejemplo)
Explicación: script sencillo para generar un backup de base de datos y archivos con marcas de tiempo.

```bash
#!/usr/bin/env bash
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M)
DBFILE=".ddev/db_snapshots/backup_${TIMESTAMP}.sql.gz"
FILESFILE="files-backup_${TIMESTAMP}.tar.gz"

echo "Exportando base de datos a ${DBFILE}"
ddev export-db --file="backup_${TIMESTAMP}.sql"

echo "Comprimiendo archivos subidos a ${FILESFILE}"
tar -czvf ${FILESFILE} web/sites/default/files

echo "Backups creados:"
ls -lh ${DBFILE} ${FILESFILE}
```

Guarda como `backup.sh`, dale permisos `chmod +x backup.sh` y ejecútalo desde la raíz del proyecto.

---

## 12. Notas finales y buenas prácticas
- Versiona siempre la **configuración** (YAML) en Git y documenta los cambios en los mensajes de commit.
- No subas `web/sites/default/files` a Git. Usa rsync/scp/archivos comprimidos para transferir esos archivos.
- Mantén copias regulares de la base de datos; automatiza si es posible.
- Antes de restaurar en producción, revisa los ajustes de `settings.php` (clave de salts, trusted_host_patterns, conexión DB).
- Si trabajas en equipo, establezcan un procedimiento: exportar config después de cambios de estructura y compartir backups de DB cuando sea necesario.

---