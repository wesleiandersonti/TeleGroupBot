#!/usr/bin/env bash
set -euo pipefail

APP_URL="${1:-http://127.0.0.1/health}"

echo "== TeleGroupBot Healthcheck =="

systemctl is-active --quiet nginx && echo "nginx: ok" || (echo "nginx: fail" && exit 1)
if systemctl list-units | grep -q 'php8.1-fpm'; then
  systemctl is-active --quiet php8.1-fpm && echo "php-fpm: ok" || (echo "php-fpm: fail" && exit 1)
fi

HTTP_CODE=$(curl -s -o /tmp/telegroupbot-health.json -w "%{http_code}" "$APP_URL" || true)
if [[ "$HTTP_CODE" == "200" ]]; then
  echo "health endpoint: ok"
  cat /tmp/telegroupbot-health.json || true
else
  echo "health endpoint: fail (HTTP $HTTP_CODE)"
  exit 1
fi

echo "Healthcheck concluído com sucesso"
