#!/bin/bash

echo "Installation et configuration de MariaDB sur $(hostname)..."

# Mise à jour des paquets et installation de MariaDB
sudo apt update -y
sudo apt install -y mariadb-server

# Démarrer et activer MariaDB
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Définition des variables
DB_NAME="web_db"
DB_USER="web_user"
DB_PASS="password"

# Définition des variables pour la replication
REPLICA_USER="replicator"
REPLICA_PASS="replica_pass"

log-bin
server_id=1
log-basename=master1
binlog-format=mixed

# Configuration de MariaDB pour accepter les connexions externes
echo "Configuration de MariaDB pour accepter les connexions externes..."
sudo sed -i "s/^bind-address\s*=.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i "/^\[mysqld\]/a log-bin\nserver-id=1" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb

# Création de la base de données et de l'utilisateur avec accès distant
echo "Création de la base et de l'utilisateur..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "Création de l'utilisateur de réplication..."
sudo mysql -e "CREATE USER IF NOT EXISTS '${REPLICA_USER}'@'%' IDENTIFIED BY '${REPLICA_PASS}';"
sudo mysql -e "GRANT REPLICATION SLAVE, BINLOG MONITOR ON *.* TO 'replicator'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Création de la table pour stocker les messages du formulaire
sudo mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

echo "MariaDB configuré et prêt à l'utilisation sur $(hostname)."