#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/var/www/telegroupbot}"
PHP_BIN="${2:-/usr/bin/php}"

cat >/etc/systemd/system/telegroupbot-worker.service <<EOF
[Unit]
Description=TeleGroupBot Laravel Queue Worker
After=network.target

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=${PHP_BIN} ${APP_DIR}/artisan queue:work --sleep=3 --tries=3 --timeout=120
WorkingDirectory=${APP_DIR}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now telegroupbot-worker

echo "Worker configurado: telegroupbot-worker.service"
