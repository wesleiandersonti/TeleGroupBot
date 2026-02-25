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

## Deploy rápido (produção)

```bash
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan migrate --force
npm ci && npm run production
```
