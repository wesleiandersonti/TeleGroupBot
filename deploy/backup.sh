#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/var/www/telegroupbot}"
BACKUP_DIR="${2:-/var/backups/telegroupbot}"
RETENTION_DAYS="${3:-7}"

mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d_%H%M%S)

DB_NAME=$(grep '^DB_DATABASE=' "$APP_DIR/.env" | cut -d'=' -f2-)
DB_USER=$(grep '^DB_USERNAME=' "$APP_DIR/.env" | cut -d'=' -f2-)
DB_PASS=$(grep '^DB_PASSWORD=' "$APP_DIR/.env" | cut -d'=' -f2-)

mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/db_${TS}.sql"
tar -czf "$BACKUP_DIR/app_${TS}.tar.gz" -C "$APP_DIR" .env storage

find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete

echo "Backup concluído em $BACKUP_DIR"
