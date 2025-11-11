#!/bin/bash

# Nombre del proyecto
PROJECT_NAME="ulasalle-drupal-site"

# Carpeta de backups
BACKUP_DIR="backups"

# Crear carpeta si no existe
mkdir -p "$BACKUP_DIR"

# Fecha para el nombre del archivo
DATE=$(date +"%Y_%m_%d_%H_%M")

# Nombre final del archivo
FILE="$BACKUP_DIR/backup_${DATE}.sql"

# Exportar sin compresión
ddev export-db --gzip=false --file="$FILE"

echo "Backup creado: $FILE"
