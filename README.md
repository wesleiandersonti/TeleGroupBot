# TeleGroupBot

Plataforma SaaS para gerenciamento de grupos no Telegram (base Laravel).

## Requisitos

- PHP 8+
- Composer
- Node.js 18+
- MySQL/MariaDB

## Instalação (local)

```bash
composer install
cp .env.example .env
php artisan key:generate
```

Configure banco no `.env` e rode:

```bash
php artisan migrate --seed
npm install
npm run dev
php artisan serve
```

## Estrutura principal

- `app/` lógica da aplicação
- `routes/` rotas web/api
- `resources/` views/assets
- `database/` migrations e seeders
- `public/` entrada pública

## Observações

- Arquivos sensíveis (`.env`, logs, dependências locais) ficam fora do versionamento.
- Para produção, configure cache, queue e HTTPS.

## Deploy profissional em Ubuntu 22.04 (1 comando)

Script completo (instala dependências, Nginx, PHP, MySQL, Node, SSH, firewall, app):

```bash
sudo bash deploy/install-ubuntu-22.04.sh \
  --repo https://github.com/wesleiandersonti/TeleGroupBot.git \
  --domain app.seudominio.com \
  --email seu@email.com \
  --db-name telegroupbot \
  --db-user telegroupbot \
  --db-pass 'SENHA_FORTE'
```

No final, o script mostra:
- URL da aplicação
- IP público detectado
- comando SSH pronto

## Update do sistema

```bash
bash deploy/update.sh /var/www/telegroupbot
```
