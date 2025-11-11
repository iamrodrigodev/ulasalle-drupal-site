# Proyecto Drupal

Este proyecto utiliza **DDEV** para gestionar el entorno local de desarrollo y facilitar la exportación de la base de datos y archivos para su despliegue en un servidor (por ejemplo, un VPS).

## Requisitos previos

Asegúrate de tener instalado:

- Docker
- DDEV
- Git

## Inicializar el proyecto en local

Clonar el repositorio:

```bash
git clone <URL-del-repositorio>
cd <nombre-del-proyecto>
```

Iniciar el proyecto con DDEV:

```bash
ddev start
```

Acceder al sitio local:

```bash
ddev launch
```

Acceder al contenedor web:

```bash
ddev ssh
```

## Exportar la base de datos (backup)

Para exportar la base de datos a un archivo `.sql.gz`:

```bash
ddev export-db --file=backup.sql
```

Esto generará un archivo comprimido `backup.sql.gz` en la carpeta principal del proyecto.

## Exportar archivos (imágenes, uploads, media)

Los archivos subidos por el sitio están en:

```
web/sites/default/files
```

Para hacer una copia de esos archivos:

```bash
zip -r files_backup.zip web/sites/default/files
```

## Sincronización de configuración (Config Sync)

Drupal maneja configuraciones (vistas, bloques, contenido estructural, etc.) que se almacenan en archivos YAML.

Exportar la configuración:

```bash
ddev drush cex
```

Importar la configuración:

```bash
ddev drush cim
```

Si recibes el mensaje:

```
The active configuration is identical to the configuration in the export directory
```

Significa que no hay cambios pendientes.

## Subir al servidor (VPS)

Cuando vayas a implementar:

1. Subir los archivos del proyecto mediante `git`, `scp` o `rsync`.
2. Subir la copia de archivos (`files_backup.zip`) a `web/sites/default/files`.
3. Importar la base de datos en el servidor:

```bash
gunzip backup.sql.gz
mysql -u usuario -p nombre_base < backup.sql
```

4. Ejecutar `drush cim` en el servidor para sincronizar configuración.

---

## Resumen

| Acción | Comando |
|-------|---------|
| Iniciar entorno | `ddev start` |
| Abrir sitio | `ddev launch` |
| Entrar al contenedor | `ddev ssh` |
| Exportar DB | `ddev export-db --file=backup.sql` |
| Exportar configuración | `ddev drush cex` |
| Importar configuración | `ddev drush cim` |