#!/bin/bash
# Script d'installation de Zabbix Agent
# Auteur : Thomas Delzor © 2025 - Tous droits réservés

CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

# Vérifie si whiptail est présent
if ! command -v whiptail &> /dev/null; then
    echo "Installation de whiptail..."
    apt update && apt install -y whiptail
fi

# Message d'intro
whiptail --title "INFRACT - Installation Zabbix Agent" \
--msgbox "Ce script va installer et configurer l'agent Zabbix sur cette machine Debian 12." 10 60

# Confirmation
if ! whiptail --title "Confirmation" --yesno "Souhaitez-vous procéder à l'installation de l'agent Zabbix ?" 10 60; then
    echo "Installation annulée ❌"
    exit 1
fi

install_zabbix_agent() {
    echo "Installation de Zabbix Agent..."
    wget -q https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb
    dpkg -i zabbix-release_latest_7.0+debian12_all.deb
    apt update -y
    apt install -y zabbix-agent
    systemctl enable zabbix-agent
    echo "Installation terminée ✅"
    configure_zabbix_agent
}

configure_zabbix_agent() {
    ZABBIX_SERVER=$(whiptail --inputbox "Entrez l'IP du serveur Zabbix :" 10 60 3>&1 1>&2 2>&3)
    CLIENT_HOSTNAME=$(whiptail --inputbox "Entrez le nom d'hôte de cette machine :" 10 60 3>&1 1>&2 2>&3)

    if [ -f "$CONFIG_FILE" ]; then
        echo "Configuration de Zabbix Agent..."
        sed -i "s/^Server=.*/Server=$ZABBIX_SERVER/" $CONFIG_FILE
        sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER/" $CONFIG_FILE
        sed -i "s/^Hostname=.*/Hostname=$CLIENT_HOSTNAME/" $CONFIG_FILE
        chown root:root $CONFIG_FILE
        echo "Configuration appliquée ✅"
    else
        echo "Erreur : Fichier de configuration introuvable ❌"
        exit 1
    fi
    restart_zabbix_agent
}

restart_zabbix_agent() {
    echo "Redémarrage de l'agent..."
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    echo "Zabbix Agent est actif ✅"
    whiptail --title "Succès 🎉" --msgbox "Zabbix Agent est maintenant installé et configuré." 10 60
}

# Lancement
install_zabbix_agent
