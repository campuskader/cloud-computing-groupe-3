#!/bin/bash

# Configuration améliorée de Nginx en Load Balancer
echo "Installation et configuration de Nginx en Load Balancer..."

# Mise à jour des paquets et installation de Nginx avec gestion d'erreur
sudo apt update -y || { echo "Échec de la mise à jour des paquets"; exit 1; }
sudo apt install -y nginx || { echo "Échec de l'installation de Nginx"; exit 1; }

# Sauvegarde de la configuration existante
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Création de la configuration Nginx pour le Load Balancer avec plus d'options avancées
cat <<EOF | sudo tee /etc/nginx/sites-available/loadbalancer
upstream backend_servers {
    # Utilisation d'un algorithme de répartition de charge plus efficace
    # least_conn: envoie la requête au serveur avec le moins de connexions actives
    least_conn;
    
    # Configuration des serveurs backend avec options de santé et de poids
    server 192.168.56.11:80 max_fails=3 fail_timeout=30s;
    server 192.168.56.12:80 max_fails=3 fail_timeout=30s;
    
    # Délai d'attente pour les serveurs inactifs
    keepalive 16;
}

server {
    listen 80 default_server;
    server_name _;
    
    # Configuration de base pour le proxy
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Configurer des timeout pour éviter les problèmes de connexion
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Activer les buffers pour améliorer les performances
        proxy_buffering on;
    }
    
    # Page de statut pour le monitoring
    location /status {
        stub_status on;
        access_log off;
        # Limiter l'accès au réseau interne et au serveur de monitoring
        allow 127.0.0.1;
        allow 192.168.56.15;
        allow 192.168.56.16;
        deny all;
    }
    
    # Gestion des journaux
    access_log /var/log/nginx/loadbalancer_access.log;
    error_log /var/log/nginx/loadbalancer_error.log;
}
EOF

# Activer la configuration et supprimer la configuration par défaut
sudo ln -sf /etc/nginx/sites-available/loadbalancer /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Vérifier la configuration avant de redémarrer
sudo nginx -t || { echo "La configuration Nginx contient des erreurs"; exit 1; }

# Redémarrer Nginx pour appliquer les changements
sudo systemctl restart nginx || { echo "Échec du redémarrage de Nginx"; exit 1; }
sudo systemctl enable nginx || { echo "Échec de l'activation de Nginx"; exit 1; }

# Vérifier que Nginx est bien en cours d'exécution
if sudo systemctl is-active --quiet nginx; then
    echo "Load Balancer configuré avec succès en mode Least Connections!"
    echo "Le service est actif et en cours d'exécution."
else
    echo "Erreur: Le service Nginx n'est pas en cours d'exécution."
    echo "Vérifiez les journaux avec: sudo journalctl -xe"
    exit 1
fi

# Ouvrir le port 80 dans le pare-feu si UFW est activé
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "active"; then
    sudo ufw allow 80/tcp
    echo "Port 80 ouvert dans le pare-feu UFW."
fi

# Afficher les informations de base sur le système
echo -e "\nInformations sur le Load Balancer:"
echo "IP du Load Balancer: $(hostname -I | awk '{print $1}')"
echo "Nginx version: $(nginx -v 2>&1 | cut -d '/' -f 2)"