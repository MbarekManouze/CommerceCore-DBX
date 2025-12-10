#!/usr/bin/env bash
set -e

DB_NAME="myapp"
DB_USER="dbuser"
DB_CONTAINER="app_db"
DB_PASSWORD="dbpassword"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILE="backup_${DB_NAME}_${TIMESTAMP}.sql"

echo "Creating backup: $FILE"

docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_CONTAINER" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" -F p \
  > "$FILE"

echo "Backup done."
