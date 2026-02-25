#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/var/www/telegroupbot}"
PHP_BIN="${2:-php}"

cd "$APP_DIR"

echo "[1/5] Atualizando código"
git fetch --all
git reset --hard origin/main

echo "[2/5] Composer"
composer install --no-dev --optimize-autoloader

echo "[3/5] Laravel"
$PHP_BIN artisan migrate --force || true
$PHP_BIN artisan config:cache
$PHP_BIN artisan route:cache
$PHP_BIN artisan view:cache

echo "[4/5] Frontend"
npm ci || npm install
npm run production

echo "[5/5] Permissões"
chown -R www-data:www-data "$APP_DIR"
chmod -R 775 "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

echo "✅ Update concluído"
