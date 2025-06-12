#!/bin/bash
# Script d'installation de Zabbix Server pour Debian 12
# Auteur : Thomas Delzor © 2025 - Tous droits réservés

# Vérifie que whiptail est présent
if ! command -v whiptail &> /dev/null; then
    echo "Installation de whiptail..."
    apt update && apt install -y whiptail
fi

# Génère un mot de passe sécurisé
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

DB_PASSWORD=$(generate_password)

# Message d'intro
whiptail --title "INFRACT - Installation Zabbix Server" \
--msgbox "Ce script installe un serveur Zabbix 7.0 complet sur Debian 12 avec Apache, MariaDB et PHP." 12 60

# Demande confirmation
if ! whiptail --title "Confirmation" --yesno "Souhaitez-vous procéder à l'installation de Zabbix Server ?" 10 60; then
    echo "Installation annulée ❌"
    exit 1
fi

# Demande mot de passe root MySQL (invisible)
MYSQL_ROOT_PASSWORD=$(whiptail --passwordbox "Entrez le mot de passe root MySQL (existant) :" 10 60 3>&1 1>&2 2>&3)

# Mise à jour système
echo "📦 Mise à jour du système..."
apt update && apt upgrade -y

# Locales et fuseau horaire
echo "🌍 Configuration locale et fuseau horaire..."
dpkg-reconfigure locales
dpkg-reconfigure tzdata

# Installation LAMP + PHP modules
echo "🔧 Installation du serveur LAMP + modules PHP..."
apt install -y apache2 php php-mysql php-mysqlnd php-ldap php-bcmath php-mbstring php-gd php-pdo php-xml libapache2-mod-php mariadb-server mariadb-client

# Installation dépôt Zabbix
echo "📥 Installation du dépôt Zabbix..."
wget -q https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb
dpkg -i zabbix-release_latest_7.0+debian12_all.deb
apt update

# Installation des paquets Zabbix
echo "📦 Installation des paquets Zabbix..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Création BDD
echo "🛢️ Création de la base de données..."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

# Import du schéma
echo "📄 Importation du schéma de la base de données..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"$DB_PASSWORD" zabbix

# Remise à 0 log_bin_trust
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

# Configuration du mot de passe BDD
echo "🔧 Configuration du mot de passe dans Zabbix Server..."
sed -i "s/# DBPassword=/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Démarrage des services
echo "🚀 Démarrage des services Zabbix..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

# Récupère l'IP locale
SERVER_IP=$(hostname -I | awk '{print $1}')

# Affichage final avec whiptail
whiptail --title "✅ Installation terminée !" --msgbox "Zabbix Server est maintenant installé avec succès 🎉

🌐 Interface Web : http://$SERVER_IP/zabbix
🗄️ Base de données : zabbix
👤 Utilisateur : zabbix
🔐 Mot de passe BDD : $DB_PASSWORD

➡️ Identifiants Zabbix Web initiaux : Admin / zabbix" 20 70
