# TeleGroupBot

Plataforma SaaS para gerenciamento de grupos no Telegram (base Laravel).

## Documentação completa
- `docs/DOCUMENTACAO_FUNCOES_E_USO.md`

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

Para uso com túnel Cloudflared (sem HTTPS local/certbot):

```bash
sudo bash deploy/install-ubuntu-22.04.sh \
  --repo https://github.com/wesleiandersonti/TeleGroupBot.git \
  --db-name telegroupbot \
  --db-user telegroupbot \
  --db-pass 'SENHA_FORTE' \
  --cloudflared-only
```

No final, o script mostra:
- URL da aplicação
- IP público detectado
- comando SSH pronto

## Update do sistema

Comando local no projeto:

```bash
bash deploy/update.sh /var/www/telegroupbot
```

Comando global (criado pelo instalador):

```bash
telegroupbot-update /var/www/telegroupbot
```

## Botões no painel Admin (Update + Restart)

Na tela **Update Center** (`/check/update`) existem dois botões:
- **Update do Sistema**
- **Reiniciar Serviços**

✅ O instalador já configura automaticamente o sudoers necessário em:
`/etc/sudoers.d/telegroupbot`

## Automações de produção já incluídas

- `telegroupbot-update` (update 1 comando)
- `telegroupbot-health` (healthcheck 1 comando)
- worker de fila via systemd (`telegroupbot-worker`)
- backup diário automático (03:30) em `/var/backups/telegroupbot`
- fail2ban habilitado
- endpoint de saúde: `/health`
