#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root" >&2
    exit 1
fi

# Carrega configurações
CONFIG_DIR="./config"
source "${CONFIG_DIR}/users_groups.conf"

# Função para criar grupos
create_groups() {
    echo "Criando grupos..."
    for group in "${GROUPS[@]}"; do
        if ! getent group "$group" >/dev/null; then
            groupadd "$group"
            echo "Grupo $group criado com sucesso."
        else
            echo "Grupo $group já existe. Pulando..."
        fi
    done
    echo ""
}

# Função para criar usuários
create_users() {
    echo "Criando usuários..."
    for user in "${!USERS[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "Usuário $user criado com sucesso."
            
            # Define a senha (opcional - em produção usar outro método)
            echo "$user:${USERS[$user]}" | chpasswd
            
            # Adiciona aos grupos secundários
            IFS=',' read -ra user_groups <<< "${USER_GROUPS[$user]}"
            for group in "${user_groups[@]}"; do
                usermod -aG "$group" "$user"
            done
        else
            echo "Usuário $user já existe. Pulando..."
        fi
    done
    echo ""
}

# Função para criar diretórios
create_directories() {
    echo "Criando diretórios..."
    for dir in "${!DIRECTORIES[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Diretório $dir criado com sucesso."
            
            # Configura dono e grupo
            IFS=':' read -ra owner_group <<< "${DIRECTORIES[$dir]}"
            chown "${owner_group[0]}:${owner_group[1]}" "$dir"
            
            # Configura permissões
            if [[ "${dir}" == *"public"* ]]; then
                chmod 777 "$dir"
            elif [[ "${dir}" == *"private"* ]]; then
                chmod 700 "$dir"
            else
                chmod 750 "$dir"
            fi
        else
            echo "Diretório $dir já existe. Pulando..."
        fi
    done
    echo ""
}

# Função principal
main() {
    echo "Iniciando configuração automática da infraestrutura..."
    echo "====================================================="
    
    create_groups
    create_users
    create_directories
    
    echo "Configuração concluída com sucesso!"
    echo "====================================================="
}

# Executa a função principal
main