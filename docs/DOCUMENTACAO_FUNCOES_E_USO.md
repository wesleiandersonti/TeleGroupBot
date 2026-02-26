# TeleGroupBot — Documentação de Funções e Guia de Uso

## 1) Visão geral
O **TeleGroupBot** é uma plataforma SaaS (base Laravel) para gerenciamento de grupos/bots, assinaturas, usuários e operação administrativa.

Esta documentação cobre:
- principais funções do sistema
- fluxos de uso
- operação em produção
- comandos de manutenção

---

## 2) Módulos principais

## 2.1 Dashboard
- visão geral de uso
- estatísticas operacionais
- acesso para usuários autenticados

Rotas principais:
- `GET /dashboard`
- `GET /dashboard/user`
- `POST /dashboard/dashboard-change-data`

---

## 2.2 Configurações (Settings)
Permite configurar conta e parâmetros gerais do sistema.

Funções:
- conta do usuário
- configurações gerais
- configurações de pagamento
- APIs de SMS/E-mail e integrações
- tutoriais de vídeo

Rotas exemplo:
- `GET /settings`
- `POST /settings`
- `GET /settings/account`
- `POST /settings/account`

---

## 2.3 Assinaturas e pacotes
Gerencia planos e usuários (SaaS).

Funções:
- criar/editar/excluir pacotes
- listar e gerenciar usuários
- alterar status de usuário
- enviar e-mail para usuário

Rotas exemplo:
- `GET /package/list`
- `GET /package/create`
- `GET /user/list`
- `GET /user/create`

---

## 2.4 Pagamentos
Suporte para fluxo de compra e logs de transação.

Funções:
- selecionar pacote
- comprar pacote
- visualizar logs
- pagamento manual

Rotas exemplo:
- `GET /payment/select-package`
- `GET /payment/buy-package/{id}`
- `GET /payment/transaction-log`

---

## 2.5 Update Center (Admin)
Área administrativa para atualização e operações de sistema.

Funções:
1. **Check Update** (mecanismo do sistema)
2. **Update do Sistema** (local, via script)
3. **Reiniciar Serviços** (nginx/php-fpm)

Rotas:
- `GET /check/update`
- `POST /initiate/update`
- `POST /system/ops/update-local`
- `POST /system/ops/restart-services`

Segurança aplicada:
- autenticação obrigatória
- throttle (`3` chamadas/min)
- lock para evitar dupla execução
- log de auditoria para ações admin

---

## 2.6 Healthcheck
Endpoint de saúde para monitoramento.

- `GET /health`

Resposta esperada:
```json
{
  "ok": true,
  "app": "TeleGroupBot",
  "time": "..."
}
```

---

## 3) Instalação (Ubuntu 22.04)

## 3.1 One-command installer (profissional)
```bash
sudo bash deploy/install-ubuntu-22.04.sh \
  --repo https://github.com/wesleiandersonti/TeleGroupBot.git \
  --db-name telegroupbot \
  --db-user telegroupbot \
  --db-pass 'SENHA_FORTE' \
  --cloudflared-only
```

O instalador já configura:
- Nginx
- PHP-FPM
- MySQL
- Node + build frontend
- Redis
- UFW + Fail2ban
- SSH
- worker de fila (systemd)
- backup diário
- comandos globais de operação
- sudoers para botões admin (restart/update)

---

## 4) Operação diária

## 4.1 Comandos globais
- **Atualizar sistema**:
```bash
telegroupbot-update /var/www/telegroupbot
```

- **Healthcheck**:
```bash
telegroupbot-health http://127.0.0.1/health
```

## 4.2 Serviço de fila
```bash
systemctl status telegroupbot-worker
systemctl restart telegroupbot-worker
```

## 4.3 Logs úteis
- Laravel:
  - `storage/logs/`
- Operações admin:
  - `storage/logs/system-update.log`
  - `storage/logs/system-restart.log`

---

## 5) Backups

Backup automático diário às 03:30:
- destino: `/var/backups/telegroupbot`
- retenção padrão: 7 dias

Script manual:
```bash
bash deploy/backup.sh /var/www/telegroupbot /var/backups/telegroupbot 7
```

Inclui:
- dump do banco
- `.env`
- `storage`

---

## 6) E-mail (SMTP)
Pode ser configurado depois, sem bloquear o funcionamento inicial.

Exemplo Gmail no `.env`:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=seuemail@gmail.com
MAIL_PASSWORD=SUA_APP_PASSWORD
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=seuemail@gmail.com
MAIL_FROM_NAME="TeleGroupBot"
```

Aplicar:
```bash
php artisan config:clear
php artisan config:cache
```

---

## 7) Publicação com Cloudflared
Como você usa Cloudflare Tunnel:
- sistema roda em IP local da VM
- Cloudflared expõe o domínio público
- sem necessidade de IP fixo público

Exemplo no painel/config de tunnel:
- service: `http://IP_LOCAL_DA_VM:80`

---

## 8) Boas práticas de produção
1. manter repo privado após estabilizar
2. usar senha forte de banco
3. revisar `.env` e segredos
4. monitorar logs e healthcheck
5. testar restore de backup
6. aplicar updates por janela de manutenção

---

## 9) Checklist de validação pós-instalação
```bash
systemctl status nginx --no-pager -l
systemctl status php8.1-fpm --no-pager -l
systemctl status telegroupbot-worker --no-pager -l
telegroupbot-health http://127.0.0.1/health
crontab -l | grep telegroupbot-backup
```

Se todos OK, o sistema está pronto para operação SaaS.
