#!/bin/bash
                # Script d'installation de Zabbix Agent
                # Auteur : Thomas Delzor
                # Date : 2025
                # Ce script est la propriété de Thomas Delzor et ne doit pas être redistribué sans autorisation.
                # © Thomas Delzor - Tous droits réservés.

                CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

                install_zabbix_agent() {
                    echo "Installation de Zabbix Agent en cours..."
                    wget -q https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb
                    dpkg -i zabbix-release_latest_7.0+debian12_all.deb
                    apt update -y
                    apt install -y zabbix-agent
                    systemctl enable zabbix-agent
                    echo "Installation terminée ✅"
                    configure_zabbix_agent
                }

                configure_zabbix_agent() {
                    read -p "Entrez l'IP du serveur Zabbix : " ZABBIX_SERVER
                    read -p "Entrez le nom d'hôte du client : " CLIENT_HOSTNAME

                    if [ -f "$CONFIG_FILE" ]; then
                        echo "Configuration de Zabbix Agent..."
                        sed -i "s/^Server=.*/Server=$ZABBIX_SERVER/" $CONFIG_FILE
                        sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER/" $CONFIG_FILE
                        sed -i "s/^Hostname=.*/Hostname=$CLIENT_HOSTNAME/" $CONFIG_FILE
                        chown root:root $CONFIG_FILE
                        echo "Configuration appliquée ✅"
                    else
                        echo "Erreur : Fichier de configuration non trouvé ❌"
                        exit 1
                    fi
                    restart_zabbix_agent
                }

                restart_zabbix_agent() {
                    echo "Redémarrage du service Zabbix Agent..."
                    systemctl restart zabbix-agent
                    systemctl enable zabbix-agent
                    echo "Zabbix Agent est actif ✅"
                }

                menu() {
                    while true; do
                        clear
                        echo "==============================="
                        echo "      Installation Zabbix Agent"
                        echo "      Script par Thomas Delzor ©"
                        echo "==============================="
                        echo "1) Installer Zabbix Agent"
                        echo "2) Quitter"
                        echo "==============================="
                        read -p "Choisissez une option : " CHOICE

                        case $CHOICE in
                            1) install_zabbix_agent ;;
                            2) echo "Bye 👋"; exit 0 ;;
                            *) echo "Option invalide ❌"; sleep 2 ;;
                        esac
                    done
                }

                menu

                # © Thomas Delzor - Tous droits réservés.
