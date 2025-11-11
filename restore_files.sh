#!/bin/bash

# Uso: ./restore_files.sh backups/files_backup_YYYY_MM_DD_HH_MM.tar.gz

if [ -z "$1" ]; then
  echo "Debes especificar el archivo .tar.gz de backup de archivos."
  echo "Ejemplo: ./restore_files.sh backups/files_backup_2025_11_11_16_05.tar.gz"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "El archivo $FILE no existe."
  exit 1
fi

# Restaurar en la estructura de Drupal
# Extrae el contenido directamente sobre el proyecto
echo "Restaurando archivos desde $FILE ..."
tar -xzf "$FILE" -C .

echo "Archivos restaurados correctamente en web/sites/default/files"