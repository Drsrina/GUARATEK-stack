#!/bin/bash
set -e

echo "========================================="
echo "Iniciando Setup da VPS - Guaratek Stack  "
echo "========================================="

echo "[1/4] Atualizando pacotes do sistema operativo..."
apt update && apt upgrade -y

echo "[2/4] Verificando e Criando Memória Swap de 8GB..."
if grep -q "swapfile" /etc/fstab; then
    echo "Swap já configurado no sistema."
else
    echo "Criando arquivo de Swap..."
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "[3/4] Verificando instalação do Docker..."
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

echo "[4/4] Preparando estrutura de pastas e permissões..."
mkdir -p data/npm data/letsencrypt data/portainer data/postgres data/n8n data/picoclaw data/odoo data/redis

# Ajuste fino de permissões (UIDs padrão das imagens oficiais)
chown -R 999:999 data/postgres  # UID do usuário postgres no Alpine
chown -R 1000:1000 data/n8n     # UID do usuário node
chown -R 101:101 data/odoo      # UID do usuário odoo
chmod -R 775 data/

echo "========================================="
echo "Setup Concluído com Sucesso!"
echo "========================================="