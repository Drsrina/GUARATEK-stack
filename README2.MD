# 💬 Guia de Instalação: Chatwoot via Docker Compose

Este documento descreve o processo de deploy do Chatwoot em uma nova VPS utilizando Infraestrutura como Código (IaC). O Chatwoot exige configurações específicas de banco de dados (especialmente a extensão **pgvector** para recursos de IA) e variáveis de sessão.

---

## 🏗 Arquitetura do Serviço

```
[ Internet ]
     |
     | (HTTPS)
     ↓
[ Nginx Proxy Manager ] ──► Escuta no subdomínio (ex: chatwoot.seudominio.com)
     |
     ├── (Porta 3000) ──► [ chatwoot-web ]    (Motor Principal / Rails)
     |                            |
     |                            ├──► [ chatwoot-sidekiq ]  (Workers / Background Jobs)
     |                            |
     |                            ├──► [ redis ]             (Fila de Tarefas / Cache)
     |                            |
     |                            └──► [ postgres-central ]  (Banco de Dados c/ pgvector)
```

---

## 1. Pré-requisitos e Variáveis de Ambiente (`.env`)

Antes de subir qualquer contêiner, garanta que o arquivo `.env` na raiz do seu projeto possua as seguintes variáveis.

> [!IMPORTANT]
> O Chatwoot **não inicia** sem o `SECRET_KEY_BASE`. Para gerar uma chave segura, rode no terminal da VPS:
> ```bash
> openssl rand -hex 64
> ```

Adicione ao seu `.env`:

```ini
# Configurações Base
DOMINIO_BASE=seudominio.com.br

# Credenciais de Banco de Dados
POSTGRES_USER=postgres_master
POSTGRES_PASSWORD=sua_senha_super_segura
CHATWOOT_DB_PASS=senha_do_banco_chatwoot

# Segurança do Chatwoot
CHATWOOT_SECRET=cole_aqui_a_chave_gerada_com_openssl
```

---

## 2. A Imagem do Banco de Dados (Crucial)

O Chatwoot moderno utiliza IA e **exige suporte a vetores** no banco de dados.

Certifique-se de que o seu serviço PostgreSQL no `docker-compose.yml` esteja usando a imagem `pgvector`, e **não** o Postgres puro:

```yaml
postgres-central:
  image: pgvector/pgvector:pg16  # OBRIGATÓRIO PARA O CHATWOOT
  # ... resto das configurações
```

---

## 3. Passo a Passo do Deploy (O "Pulo do Gato")

> [!CAUTION]
> Siga esta ordem **estritamente** para evitar erros de permissão (`InsufficientPrivilege`) e falta de tabelas (`UndefinedTable`).

### Passo 3.1 — Subir a Infraestrutura Base

Primeiro, inicie apenas o banco de dados e o Redis:

```bash
docker compose --profile atendimento up -d postgres-central redis
```

### Passo 3.2 — Configurar Permissões e Extensões no Postgres

O Rails tentará criar extensões, então o usuário do Chatwoot precisa de permissões de superusuário e da extensão `vector` ativada.

> Substitua `postgres_master` pelo usuário administrador definido no seu `.env`.

```bash
docker compose --profile atendimento exec postgres-central psql -U postgres_master -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'chatwoot_user') THEN
    CREATE USER chatwoot_user WITH PASSWORD '${CHATWOOT_DB_PASS}';
  END IF;
END \$\$;

ALTER ROLE chatwoot_user WITH SUPERUSER;
CREATE DATABASE chatwoot_db OWNER chatwoot_user;
GRANT ALL ON SCHEMA public TO chatwoot_user;
"
```

Em seguida, habilite a extensão `vector` no banco recém-criado:

```bash
docker compose --profile atendimento exec postgres-central \
  psql -U postgres_master -d chatwoot_db \
  -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### Passo 3.3 — Migração de Banco de Dados (Safe Mode)

Para evitar que o banco fique "pela metade", use a carga direta de esquema em vez de apenas `db:prepare`:

```bash
# 1. Garante que o banco está limpo de tentativas falhas anteriores
docker compose --profile atendimento run --rm chatwoot-web bundle exec rails db:drop

# 2. Cria e carrega toda a estrutura do banco corretamente
docker compose --profile atendimento run --rm chatwoot-web bundle exec rails db:create
docker compose --profile atendimento run --rm chatwoot-web bundle exec rails db:schema:load

# 3. Roda as migrações finais
docker compose --profile atendimento run --rm chatwoot-web bundle exec rails db:migrate
```

> **Nota:** Se aparecerem avisos sobre o `RubyLLM`, são apenas *warnings* de depreciação e não afetam a instalação.

### Passo 3.4 — Subir a Interface

Com o banco preparado, suba a stack completa:

```bash
docker compose --profile atendimento up -d
```

---

## 4. Configuração Final (Nginx Proxy Manager)

1. Acesse o painel do **Nginx Proxy Manager** em `http://<IP-DA-VPS>:81`.
2. Adicione um **Proxy Host** apontando `chatwoot.seudominio.com.br` → container `chatwoot-web` na **porta 3000**.
3. Ative o **SSL via Let's Encrypt** e marque "Force SSL".
4. Acesse a URL no navegador e crie sua conta de administrador.

---

## 🛠 Troubleshooting Comum

### ❌ `ArgumentError: Missing secret_key_base`

- **Causa:** O container `chatwoot-web` não está lendo a variável `SECRET_KEY_BASE`.
- **Solução:** Verifique se ela está declarada no seu `docker-compose.yml` e no arquivo `.env`.

### ❌ `PG::InsufficientPrivilege: permission denied to create extension`

- **Causa:** O usuário do banco (`chatwoot_user`) não tem a role `SUPERUSER`.
- **Solução:** Repita o **Passo 3.2**.

### ❌ `PG::FeatureNotSupported: extension "vector" is not available`

- **Causa:** A imagem do Postgres não suporta vetores.
- **Solução:** Troque a imagem no `docker-compose.yml` para `pgvector/pgvector:pg16` e recrie o container do banco.