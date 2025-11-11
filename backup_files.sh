#!/bin/bash

# Nombre de la carpeta de archivos de Drupal
FILES_DIR="web/sites/default/files"

# Carpeta donde se guardarán los backups
BACKUP_DIR="backups"

# Crear carpeta si no existe
mkdir -p "$BACKUP_DIR"

# Fecha para el nombre del archivo
DATE=$(date +"%Y_%m_%d_%H_%M")

# Nombre final del archivo
tarfile="$BACKUP_DIR/files_backup_${DATE}.tar.gz"

# Crear el backup (comprimir toda la carpeta files)
tar -czf "$tarfile" "$FILES_DIR"

echo "Backup de archivos creado: $tarfile"
