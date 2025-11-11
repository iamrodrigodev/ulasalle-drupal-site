#!/bin/bash

# Uso: ./restore.sh backups/archivo.sql

if [ -z "$1" ]; then
  echo "Debes especificar el archivo SQL a restaurar."
  echo "Ejemplo: ./restore.sh backups/backup_2025_11_11_16_05.sql"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "❌ El archivo $FILE no existe."
  exit 1
fi

echo "Restaurando base de datos desde: $FILE ..."
ddev import-db --src="$FILE"
ddev drush cr

echo "Restauración completa."