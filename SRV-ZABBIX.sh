#!/bin/bash

                # Fonction pour générer un mot de passe sécurisé de 12 caractères
                generate_password() {
                    tr -dc A-Za-z0-9 &lt; /dev/urandom | head -c 12
                }

                DB_PASSWORD=$(generate_password)

                # Affichage du logo
                clear
                echo "############################################################"
                echo "#               ZABBIX INSTALLER                     #"
                echo "############################################################"
                echo ""
                echo "1) Installer Zabbix"
                echo "2) Quitter"
                echo ""
                read -p "Choisissez une option : " choice

                if [[ "$choice" == "1" ]]; then
                    # Demande du mot de passe root MySQL
                    read -s -p "Entrez le mot de passe root MySQL : " MYSQL_ROOT_PASSWORD
                    echo

                    # Mise à jour du système
                    echo "Mise à jour du système..."
                    apt update && apt upgrade -y

                    # Changement de la locale
                    echo "Configuration de la locale en FR..."
                    dpkg-reconfigure locales

                    # Changement du fuseau horaire
                    echo "Configuration du fuseau horaire..."
                    dpkg-reconfigure tzdata

                    # Installation du serveur LAMP
                    echo "Installation du serveur LAMP..."
                    apt install -y apache2 php php-mysql php-mysqlnd php-ldap php-bcmath php-mbstring php-gd php-pdo php-xml libapache2-mod-php mariadb-server mariadb-client

                    # Installation du dépôt Zabbix
                    echo "Installation du dépôt Zabbix..."
                    wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb
                    dpkg -i zabbix-release_latest_7.0+debian12_all.deb
                    apt update

                    # Installation de Zabbix
                    echo "Installation de Zabbix..."
                    apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

                    # Création de la base de données
                    echo "Création de la base de données..."
                    mysql -uroot -p$MYSQL_ROOT_PASSWORD &lt;&lt;EOF
                CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
                CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
                GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
                SET GLOBAL log_bin_trust_function_creators = 1;
                EOF

                    # Importation du schéma de la base de données
                    echo "Importation du schéma de la base de données..."
                    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p$DB_PASSWORD zabbix

                    # Désactivation de l'option log_bin_trust_function_creators
                    mysql -uroot -p$MYSQL_ROOT_PASSWORD &lt;&lt;EOF
                SET GLOBAL log_bin_trust_function_creators = 0;
                EOF

                    # Configuration de la base de données pour Zabbix
                    echo "Configuration de Zabbix..."
                    sed -i "s/# DBPassword=/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

                    # Démarrage et activation des services
                    echo "Démarrage des services Zabbix..."
                    systemctl restart zabbix-server zabbix-agent apache2
                    systemctl enable zabbix-server zabbix-agent apache2

                    # Affichage des informations de connexion
                    echo "############################################################"
                    echo "Installation terminée !"
                    echo "URL d'accès : http://$(hostname -I | awk '{print $1}')/zabbix"
                    echo "Base de données : zabbix"
                    echo "Utilisateur : zabbix"
                    echo "Mot de passe : $DB_PASSWORD"
                    echo "############################################################"
                    exit 0

                elif [[ "$choice" == "2" ]]; then
                    echo "Au revoir !"
                    exit 0
                else
                    echo "Option invalide."
                    exit 1
                fi
