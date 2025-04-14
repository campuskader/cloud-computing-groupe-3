#!/bin/bash

# Mise à jour système
sudo apt update -y
sudo apt upgrade -y

# Installer Prometheus & Node Exporter depuis les dépôts officiels Ubuntu
sudo apt install -y prometheus

# Configuration basique Prometheus
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'nodes'
    static_configs:
      - targets: ['192.168.56.10:9100', '192.168.56.11:9100', '192.168.56.12:9100', '192.168.56.13:9100', '192.168.56.14:9100', '192.168.56.15:9100', '192.168.56.16:9100']
EOF

# Redémarrer Prometheus avec la nouvelle conf
sudo systemctl restart prometheus
sudo systemctl enable prometheus


# Ajouter le dépôt Grafana
sudo apt install -y software-properties-common wget apt-transport-https gnupg2 curl
wget -q -O - https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana.gpg
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Installer Grafana
sudo apt update
sudo apt install -y grafana

# Activer les services au démarrage
sudo systemctl enable prometheus
sudo systemctl start prometheus

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "Prometheus : http://localhost:9090"
echo "Grafana : http://localhost:3000 (admin/admin)"