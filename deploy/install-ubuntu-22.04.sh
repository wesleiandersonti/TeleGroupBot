#!/usr/bin/env bash
set -euo pipefail

# TeleGroupBot one-command installer for Ubuntu 22.04
# Usage example:
# sudo bash deploy/install-ubuntu-22.04.sh \
#   --repo https://github.com/wesleiandersonti/TeleGroupBot.git \
#   --domain app.seudominio.com \
#   --email seu@email.com \
#   --db-name telegroupbot --db-user telegroupbot --db-pass 'SENHA_FORTE'

REPO_URL="https://github.com/wesleiandersonti/TeleGroupBot.git"
APP_DIR="/var/www/telegroupbot"
DOMAIN=""
LETSENCRYPT_EMAIL=""
PHP_VERSION="8.1"
DB_NAME="telegroupbot"
DB_USER="telegroupbot"
DB_PASS="telegroupbot123"
DB_ROOT_PASS=""
SSH_PORT="22"
APP_ENV="production"
APP_DEBUG="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2 ;;
    --app-dir) APP_DIR="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --email) LETSENCRYPT_EMAIL="$2"; shift 2 ;;
    --php) PHP_VERSION="$2"; shift 2 ;;
    --db-name) DB_NAME="$2"; shift 2 ;;
    --db-user) DB_USER="$2"; shift 2 ;;
    --db-pass) DB_PASS="$2"; shift 2 ;;
    --db-root-pass) DB_ROOT_PASS="$2"; shift 2 ;;
    --ssh-port) SSH_PORT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Execute como root: sudo bash $0 ..."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/12] Atualizando sistema..."
apt-get update -y
apt-get upgrade -y

echo "[2/12] Instalando dependências base..."
apt-get install -y software-properties-common ca-certificates curl gnupg lsb-release unzip git ufw nginx mysql-server redis-server

echo "[3/12] Instalando PHP ${PHP_VERSION} + extensões..."
add-apt-repository -y ppa:ondrej/php
apt-get update -y
apt-get install -y \
  php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-xml \
  php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-intl

if ! command -v composer >/dev/null 2>&1; then
  echo "[4/12] Instalando Composer..."
  EXPECTED_SIGNATURE=$(curl -s https://composer.github.io/installer.sig)
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")
  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo 'ERRO: assinatura inválida do Composer'
    rm -f composer-setup.php
    exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f composer-setup.php
fi

echo "[5/12] Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "[6/12] Configurando MySQL..."
systemctl enable --now mysql
if [[ -n "$DB_ROOT_PASS" ]]; then
  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_ROOT_PASS}'; FLUSH PRIVILEGES;" || true
  MYSQL_AUTH="-uroot -p${DB_ROOT_PASS}"
else
  MYSQL_AUTH="-uroot"
fi

mysql ${MYSQL_AUTH} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql ${MYSQL_AUTH} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql ${MYSQL_AUTH} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

echo "[7/12] Deploy do código..."
mkdir -p "$(dirname "$APP_DIR")"
if [[ -d "$APP_DIR/.git" ]]; then
  cd "$APP_DIR"
  git fetch --all
  git reset --hard origin/main
else
  rm -rf "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

if [[ ! -f .env && -f .env.example ]]; then
  cp .env.example .env
fi

sed -i "s|^APP_ENV=.*|APP_ENV=${APP_ENV}|" .env || true
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=${APP_DEBUG}|" .env || true
LOCAL_IP=$(hostname -I | awk '{print $1}')
sed -i "s|^APP_URL=.*|APP_URL=http://${DOMAIN:-$LOCAL_IP}|" .env || true
sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=mysql|" .env || true
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" .env || true
sed -i "s|^DB_PORT=.*|DB_PORT=3306|" .env || true
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env || true
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" .env || true
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env || true

echo "[8/12] Dependências da aplicação..."
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan migrate --force || true

npm ci || npm install
npm run production

echo "[9/12] Permissões..."
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR" -type f -exec chmod 644 {} \;
find "$APP_DIR" -type d -exec chmod 755 {} \;
chmod -R 775 "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

echo "[10/12] Nginx + PHP-FPM..."
cat >/etc/nginx/sites-available/telegroupbot <<NGINX
server {
    listen 80;
    server_name ${DOMAIN:-_};

    root ${APP_DIR}/public;
    index index.php index.html;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/telegroupbot /etc/nginx/sites-enabled/telegroupbot
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now php${PHP_VERSION}-fpm nginx redis-server
systemctl reload nginx

echo "[11/12] SSH + Firewall..."
apt-get install -y openssh-server
systemctl enable --now ssh
if [[ "$SSH_PORT" != "22" ]]; then
  sed -i "s/^#\?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
  systemctl restart ssh
fi
ufw default deny incoming
ufw default allow outgoing
ufw allow ${SSH_PORT}/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "[12/12] HTTPS (opcional automático)..."
if [[ -n "$DOMAIN" && -n "$LETSENCRYPT_EMAIL" ]]; then
  apt-get install -y certbot python3-certbot-nginx
  certbot --nginx -d "$DOMAIN" -m "$LETSENCRYPT_EMAIL" --agree-tos --non-interactive --redirect || true
fi

LOCAL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Instalação concluída"
echo "App (local): http://${DOMAIN:-$LOCAL_IP}"
echo "SSH (local): ssh -p ${SSH_PORT} $(whoami)@${LOCAL_IP}"
echo "Path: ${APP_DIR}"
echo ""
