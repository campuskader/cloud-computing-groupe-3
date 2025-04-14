#!/bin/bash

echo "Installation et configuration d'Apache, PHP et MariaDB sur $(hostname)..."

# Mise à jour et installation des paquets nécessaires
sudo apt update -y
sudo apt install -y apache2 php libapache2-mod-php php-mysql

# Démarrer et activer les services
sudo systemctl enable apache2
sudo systemctl start apache2

# Définir le hostname pour personnaliser la page PHP
HOSTNAME=$(hostname)

# Créer la base de données et l'utilisateur MySQL
DB_HOST="192.168.56.13"
DB_NAME="web_db"
DB_USER="web_user"
DB_PASS="password"


# Définir le VirtualHost Apache
cat <<EOF | sudo tee /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Activer PHP dans Apache
sudo a2enmod php
sudo systemctl restart apache2

# Créer un script servant de test curl dans le index.html
cat <<EOF | sudo tee /var/www/html/index.html
Bienvenue sur $HOSTNAME
EOF

# Créer un script PHP avec un formulaire et un enregistrement dans la base de données
cat <<EOF | sudo tee /var/www/html/index.php
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulaire sur $(hostname)</title>
    <style>
        table, th, td { border: 1px solid black; border-collapse: collapse; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>Bienvenue sur $(hostname) - <?php echo gethostbyname(gethostname()); ?> </h2>
    <form method="post">
        <label for="nom">Nom:</label>
        <input type="text" id="nom" name="nom" required>
        <br><br>
        <label for="message">Message:</label>
        <textarea id="message" name="message" required></textarea>
        <br><br>
        <button type="submit">Envoyer</button>
    </form>

    <?php
    \$servername = "$DB_HOST";
    \$username = "$DB_USER";
    \$password = "$DB_PASS";
    \$dbname = "$DB_NAME";

    // Connexion à la base distante
    \$conn = new mysqli(\$servername, \$username, \$password, \$dbname);
    if (\$conn->connect_error) {
        die("Erreur de connexion: " . \$conn->connect_error);
    }

    // Insertion du message si le formulaire a été soumis
    if (\$_SERVER["REQUEST_METHOD"] == "POST") {
        \$nom = \$conn->real_escape_string(\$_POST["nom"]);
        \$message = \$conn->real_escape_string(\$_POST["message"]);

        \$sql = "INSERT INTO messages (nom, message) VALUES ('\$nom', '\$message')";
        if (\$conn->query(\$sql) === TRUE) {
            echo "<p>Message enregistré avec succès !</p>";
        } else {
            echo "<p>Erreur: " . \$conn->error . "</p>";
        }
    }

    // Affichage des messages enregistrés
    \$result = \$conn->query("SELECT id, nom, message, created_at FROM messages ORDER BY created_at DESC");
    if (\$result && \$result->num_rows > 0) {
        echo "<h3>Messages enregistrés :</h3>";
        echo "<table><tr><th>ID</th><th>Nom</th><th>Message</th><th>Date</th></tr>";
        while (\$row = \$result->fetch_assoc()) {
            echo "<tr><td>" . \$row["id"] . "</td><td>" . \$row["nom"] . "</td><td>" . \$row["message"] . "</td><td>" . \$row["created_at"] . "</td></tr>";
        }
        echo "</table>";
    } else {
        echo "<p>Aucun message enregistré pour l’instant.</p>";
    }

    \$conn->close();
    ?>
</body>
</html>
EOF

echo "Serveur web prêt avec PHP et un formulaire connecté à MariaDB."