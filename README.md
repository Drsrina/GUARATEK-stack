# 🎯 GUARATEK Stack — Kit de Implantação Automática

Kit completo de infraestrutura como código (IaC) para deploy de um ecossistema de software empresarial (Enterprise Grade) em um servidor VPS Linux.

O sistema é projetado em **4 camadas**, garantindo escalabilidade, isolamento e segurança.

---

## 🚀 Arquitetura em 4 Camadas

O projeto segue uma arquitetura modular onde cada componente possui responsabilidades bem definidas.

### Camada 1 — Infraestrutura & Auditoria

Componentes essenciais para gerenciar o servidor e o tráfego.

- **Nginx Proxy Manager (NPM):** Gerenciamento de domínios, SSL automático via Let's Encrypt e proxy reverso.
- **Portainer:** Interface visual para gerenciamento dos containers Docker.

### Camada 2 — Banco de Dados Centralizado

Um único servidor PostgreSQL com extensão **pgvector** (suporte a vetores para IA), atendendo todos os sistemas com isolamento por usuário e banco.

- **PostgreSQL + pgvector:** Banco de dados relacional com suporte nativo a embeddings.
- **Script de Inicialização:** Cria automaticamente bancos e usuários isolados para cada aplicação (`init-banco.sh`).

### Camada 3 — Motores de Execução (Core Business)

O cérebro da operação. Aplicativos que rodam 24/7.

- **n8n:** Plataforma de automação e integração (Workflow Engine).
- **Windmill:** Orquestração de fluxos de trabalho e automações complexas.
- **Odoo:** ERP completo com gestão de estoques, finanças e CRM.
- **Typebot Builder:** Plataforma visual para criação de chatbots e fluxos conversacionais.
- **Typebot Viewer:** Motor de execução que entrega os bots aos usuários finais.
- **PicoClaw:** Solução de "Digital Twin" e robótica de processos (RPA/IoT). *(Ativado com o perfil `launcher`)*

### Camada 4 — Atendimento (Opcional)

Componentes de comunicação, ativados somente quando necessário.

- **Redis:** Cache e gerenciamento de filas.
- **Chatwoot:** Plataforma de atendimento ao cliente (SAC) omnicanal. *(Ativado com o perfil `atendimento`)*

---

## 📋 Pré-requisitos

Antes de iniciar o deploy, certifique-se de ter:

1. **Um servidor VPS com Linux (Ubuntu 22.04 / Debian 12):**
   - Mínimo **4 GB de RAM** (8 GB recomendado para rodar tudo).
   - Acesso SSH com privilégios de `root` ou `sudo`.

2. **Um domínio:**
   - Aponte um domínio ou subdomínio (ex: `vps.seudominio.com.br`) para o IP público do seu VPS.
   - Para testes locais, use serviços como `nip.io` (ex: `177.153.194.108.nip.io`).

---

## ⚙️ Instalação Passo a Passo

### Passo 1 — Preparar o servidor VPS

Execute o script de setup na VPS como `root`. Ele instala o Docker, cria o Swap de 8 GB e prepara as permissões de diretório:

```bash
git clone <url-do-repositorio>
cd GUARATEK-stack
chmod +x setup_vps.sh
sudo ./setup_vps.sh
```

### Passo 2 — Configurar as variáveis de ambiente

Crie o arquivo `.env` a partir do modelo e preencha todas as senhas e chaves:

```bash
cp .env.example .env
nano .env
```

Preencha obrigatoriamente:

| Variável | Descrição |
|---|---|
| `CLIENTE_NOME` | Nome da empresa/cliente |
| `DOMINIO_BASE` | Seu domínio ou IP nip.io (ex: `177.153.194.108.nip.io`) |
| `POSTGRES_USER` | Usuário mestre do banco de dados |
| `POSTGRES_PASSWORD` | Senha mestre do PostgreSQL (use uma senha forte) |
| `N8N_DB_PASS` | Senha do banco do n8n |
| `N8N_ENCRYPTION_KEY` | Chave aleatória para criptografia do n8n |
| `ODOO_DB_PASS` | Senha do banco do Odoo |
| `WINDMILL_DB_PASS` | Senha do banco do Windmill |
| `CHATWOOT_DB_PASS` | Senha do banco do Chatwoot |
| `TYPEBOT_DB_PASS` | Senha do banco do Typebot |
| `TYPEBOT_ENCRYPTION_SECRET` | Chave secreta do Typebot (gere com `openssl rand -hex 32`) |

### Passo 3 — Criar a configuração do PicoClaw

Crie o arquivo de configuração necessário para o serviço PicoClaw:

```bash
mkdir -p data/picoclaw
cat > data/picoclaw/config.json << 'EOF'
{
    "model_list": [
        {
            "model": "sipeed-maix",
            "model_name": "sipeed-maix"
        }
    ]
}
EOF
```

### Passo 4 — Subir a stack

Escolha o comando conforme os serviços que deseja ativar:

```bash
# Camadas 1, 2 e 3 (recomendado para início)
docker compose up -d

# Inclui a Camada 4: Chatwoot
docker compose --profile atendimento up -d

# Inclui o PicoClaw (RPA/IoT)
docker compose --profile launcher up -d

# Stack completa (todos os serviços)
docker compose --profile atendimento --profile launcher up -d
```

### Passo 5 — Configurar o Nginx Proxy Manager

Após os containers subirem, acesse o painel do NPM para configurar os proxy hosts:

1. Acesse: `http://<IP-DA-VPS>:81`
2. Login inicial: `admin@example.com` / `changeme` (altere imediatamente)
3. Crie um **Proxy Host** para cada serviço, apontando para o nome interno do container:

| Serviço | Domínio sugerido | Container interno | Porta |
|---|---|---|---|
| NPM Admin | `npm.${DOMINIO_BASE}` | — | `81` |
| n8n | `n8n.${DOMINIO_BASE}` | `n8n` | `5678` |
| Windmill | `windmill.${DOMINIO_BASE}` | `windmill` | `8000` |
| Odoo | `odoo.${DOMINIO_BASE}` | `odoo` | `8069` |
| Typebot Builder | `typebot-builder.${DOMINIO_BASE}` | `typebot-builder` | `3000` |
| Typebot Viewer | `typebot-viewer.${DOMINIO_BASE}` | `typebot-viewer` | `3000` |
| Portainer | `portainer.${DOMINIO_BASE}` | `portainer` | `9000` |
| Chatwoot | `chatwoot.${DOMINIO_BASE}` | `chatwoot-web` | `3000` |

> **Dica:** Ative o SSL em cada proxy host usando o Let's Encrypt. Marque "Force SSL" e "HTTP/2 Support".

---

## 🔧 Comandos Úteis

```bash
# Verificar status de todos os containers
docker compose ps

# Ver logs de um serviço específico
docker compose logs -f n8n

# Reiniciar um serviço
docker compose restart n8n

# Parar toda a stack
docker compose down

# Atualizar as imagens e reiniciar
docker compose pull && docker compose up -d
```

---

## 📁 Estrutura de Diretórios

```
GUARATEK-stack/
├── config/
│   └── init-banco.sh       # Script de inicialização dos bancos PostgreSQL
├── data/                   # Volumes persistentes (criados automaticamente)
│   ├── npm/                # Dados do Nginx Proxy Manager
│   ├── letsencrypt/        # Certificados SSL
│   ├── portainer/          # Dados do Portainer
│   ├── postgres/           # Dados do PostgreSQL
│   ├── n8n/                # Dados do n8n
│   ├── odoo/               # Dados do Odoo
│   ├── picoclaw/           # Configuração do PicoClaw
│   └── redis/              # Dados do Redis
├── .env.example            # Modelo de variáveis de ambiente
├── docker-compose.yml      # Orquestração principal
├── setup_vps.sh            # Script de preparação do servidor
└── README.md
```


