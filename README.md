# 🎯 GUARATEK Stack - Kit de Implantação Automática

Este é um kit completo de infraestrutura como código (IaC) para deploy de um ecossistema de software empresarial (Enterprise Grade) em um servidor VPS (Linux).

O sistema é projetado em **4 camadas**, garantindo escalabilidade, isolamento e segurança.

docker compose up -d           -sem chatwoot

docker compose --profile atendimento up -d      - chatwoot separado

---

## 🚀 Arquitetura em 4 Camadas

O projeto segue uma arquitetura modular onde cada componente possui responsabilidades bem definidas.

### Camada 1: Infraestrutura & Auditoria

Componentes essenciais para gerenciar o servidor e o tráfego.

- **Nginx Proxy Manager (NPM):** Gerenciamento de domínios, SSL automático via Let's Encrypt e balanceamento de carga.
- **Portainer:** Interface visual para gerenciamento dos containers Docker.

### Camada 2: Banco de Dados Centralizado

Um único servidor PostgreSQL robusto, atendendo todos os sistemas.

- **PostgreSQL:** Banco de dados relacional.
- **Script de Inicialização:** Cria automaticamente bancos e usuários isolados para cada aplicação.

### Camada 3: Motores de Execução (Core Business)

O cérebro da operação. Aplicativos que rodam 24/7.

- **n8n:** Plataforma de automação e integração (Workflow Engine).
- **Windmill:** Orquestração de fluxos de trabalho e automações complexas.
- **PicoClaw:** Solução de "Digital Twin" e robótica de processos (RPA/IoT).
- **Odoo:** ERP completo com gestão de estoques, finanças e CRM.

### Camada 4: Atendimento (Opcional)

Componentes de comunicação, ativados somente quando necessário.

- **Redis:** Cache e gerenciamento de filas.
- **Chatwoot:** Plataforma de atendimento ao cliente (SAC) omnicanal.

---

## 📋 Pré-requisitos

Antes de iniciar o deploy, certifique-se de ter:

1. **Um servidor VPS com Linux (Ubuntu/Debian):**

   - Mínimo 4GB de RAM (8GB recomendado para rodar tudo).
   - Acesso SSH com privilégios de `sudo`.
1. **Docker e Docker Compose instalados:**

   ```bash
   # Exemplo para Ubuntu/Debian
   sudo apt update
   sudo apt install ca-certificates curl gnupg lsb-release
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo 
   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu 
   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
1. **Um domínio:**

   - Aponte um subdomínio (ex: `vps.guaratek.com.br`) para o IP público do seu VPS.
   - **Observação:** O script está configurado para usar IPs (ex: `177.153.194.108.nip.io`) para testes locais, mas o Nginx está pronto para domínios reais.

---

## ⚙️ Configuração Inicial

1. **Clone o repositório:**

   ```bash
   git clone <url-do-repositorio>
   cd GUARATEK-stack
   ```
1. **Configure as variáveis de ambiente:**
   Crie um arquivo `.env` na raiz do projeto baseado no arquivo modelo:

   ```bash
   cp .env.example .env
   nano .env  # ou use seu editor favorito
   ```

   Preencha as variáveis conforme necessário, especialmente:

   - `CLIENTE_NOME`: Nome da empresa.
   - `DOMINIO_BASE`: Seu domínio ou IP de teste.
   - `POSTGRES_USER`: Usuário mestre do banco.
   - `POSTGRES_PASSWORD`: Senha mestre **forta**.
   - `N8N_ENCRYPTION_KEY`: Chave aleatória para criptografia do n8n.

---



### Instalação Inicial do pico claw

1. Apos O Clone Do repositório.
2. Crie a estrutura de dados:
   mkdir -p data/picoclaw
   cat <<EOF > data/picoclaw/config.json
   {
   "model_list": [
   {
   "model": "sipeed-maix",
   "model_name": "sipeed-maix"
   }
   ]
   }

EOF

---

