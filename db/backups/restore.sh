#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <backup_file.sql>"
  exit 1
fi

BACKUP_FILE="$1"
DB_NAME="myapp"
DB_USER="dbuser"
DB_CONTAINER="app_db"
DB_PASSWORD="dbpassword"

echo "Restoring from $BACKUP_FILE into database $DB_NAME"

# Drop & recreate DB to ensure a clean restore (optional but recommended)
docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_CONTAINER" \
  psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"

docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_CONTAINER" \
  psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"

# Restore
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$DB_CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"

echo "Restore done."
