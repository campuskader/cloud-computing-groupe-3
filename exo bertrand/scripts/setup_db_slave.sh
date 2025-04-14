#!/bin/bash

echo "Installation de MariaDB sur db-slave..."
sudo apt update -y
sudo apt install -y mariadb-server

sudo systemctl enable mariadb
sudo systemctl start mariadb

REPLICA_USER="replicator"
REPLICA_PASS="replica_pass"
MASTER_IP="192.168.56.13"

echo "Configuration de MariaDB pour devenir esclave..."
sudo sed -i "s/^bind-address\s*=.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i "/^\[mysqld\]/a server-id=2\nrelay-log=relay-bin" /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

echo "Attente du serveur maître..."
sleep 10

echo "🔍 Récupération des informations du maître..."
LOG_FILE=$(mysql -h $MASTER_IP -u$REPLICA_USER -p$REPLICA_PASS -e "SHOW MASTER STATUS\G" | grep File | awk '{print $2}')
LOG_POS=$(mysql -h $MASTER_IP -u$REPLICA_USER -p$REPLICA_PASS -e "SHOW MASTER STATUS\G" | grep Position | awk '{print $2}')

echo "Configuration de la réplication..."
sudo mysql -e "STOP SLAVE;"
sudo mysql -e "CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_USER='$REPLICA_USER', MASTER_PASSWORD='$REPLICA_PASS', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=0;"
sudo mysql -e "START SLAVE;"

echo "Réplication configurée sur db-slave."