#!/bin/bash
set -e

# O script usa as variáveis de ambiente passadas pelo docker-compose
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    /* Banco do n8n */
    CREATE USER n8n_user WITH PASSWORD '${N8N_DB_PASS}';
    CREATE DATABASE n8n_db OWNER n8n_user;

    /* Banco do Odoo */
    CREATE USER odoo_user WITH PASSWORD '${ODOO_DB_PASS}';
    CREATE DATABASE odoo_db OWNER odoo_user;

/* Banco do Windmill */
    CREATE USER windmill_user WITH PASSWORD '${WINDMILL_DB_PASS}';
    CREATE ROLE windmill_admin;
    
    /* Concede a chave mestra para o usuário da aplicação */
    GRANT windmill_admin TO windmill_user;
    
    /* Define o Admin como o dono absoluto */
    CREATE DATABASE windmill_db OWNER windmill_admin;
    
    /* Banco do Chatwoot */
    CREATE USER chatwoot_user WITH PASSWORD '${CHATWOOT_DB_PASS}';
    CREATE DATABASE chatwoot_db OWNER chatwoot_user;

    /* Banco do Typebot */
    CREATE USER typebot_user WITH PASSWORD '${TYPEBOT_DB_PASS}';
    CREATE DATABASE typebot_db OWNER typebot_user;
EOSQL