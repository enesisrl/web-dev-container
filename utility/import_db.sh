#!/bin/bash

# Controllo parametri
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <file_sql> <database_name>"
    exit 1
fi

SQL_FILE="$1"
DB_NAME="$2"

# Verifica che il file esista
if [ ! -f "$SQL_FILE" ]; then
    echo "Errore: file '$SQL_FILE' non trovato!"
    exit 1
fi

# Import nel container MySQL
docker exec -i mysql80 mysql -uroot -pEn3s1sr7! --init-command="SET FOREIGN_KEY_CHECKS=0;" "$DB_NAME" < "$SQL_FILE"

# Controllo esito
if [ $? -eq 0 ]; then
    echo "Importazione completata con successo!"
else
    echo "Errore durante l'importazione."
fi