#!/bin/bash

# Couleurs terminal pour logs
BLUE='\033[1;34m'
NC='\033[0m'

# Vérifie que whiptail est installé
if ! command -v whiptail &> /dev/null; then
    echo -e "${BLUE}Installation de whiptail...${NC}"
    apt update && apt install -y whiptail
fi

CHOICE=$(whiptail --title "Installation Zabbix" \
--menu "Que souhaitez-vous installer ?" 15 60 4 \
"1" "Zabbix Server (Debian 12)" \
"2" "Zabbix Agent (Debian 12)" \
3>&1 1>&2 2>&3)

exitstatus=$?

if [ $exitstatus -ne 0 ]; then
    echo "Installation annulée."
    exit 1
fi

# Liens vers les scripts
SCRIPT_SERVER="https://raw.githubusercontent.com/TON_UTILISATEUR_GITHUB/TON_REPO/main/zabbix-server.sh"
SCRIPT_AGENT="https://raw.githubusercontent.com/TON_UTILISATEUR_GITHUB/TON_REPO/main/zabbix-agent.sh"

case $CHOICE in
    1)
        echo -e "${BLUE}Installation du serveur Zabbix...${NC}"
        curl -fsSL "$SCRIPT_SERVER" | bash
        ;;
    2)
        echo -e "${BLUE}Installation de l'agent Zabbix...${NC}"
        curl -fsSL "$SCRIPT_AGENT" | bash
        ;;
esac
