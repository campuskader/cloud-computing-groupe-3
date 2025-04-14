#!/bin/bash

# Vérifie que le nombre d'arguments est correct
if [ $# -ne 1 ]; then
  echo "Usage: $0 <nombre_de_requetes>"
  exit 1
fi

echo "$1"
# Récupère le nombre de requêtes à envoyer
N=$1
URL="http://192.168.56.10"

# Boucle de requêtes
for ((i=1; i<=N; i++)); do
  echo "Requête n°$i sur le Loadbalancer :"
  body=$(curl -s "$URL")
  echo "Reponse du serveur: $body"
  echo -e "\n------------------------------------------\n"
done