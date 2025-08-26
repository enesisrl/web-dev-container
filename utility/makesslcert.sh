#!/bin/bash

# richiede mkcert
if ! command -v mkcert &> /dev/null
then
    echo "mkcert non trovato. Installa mkcert prima di eseguire questo script."
    exit 1
fi

# Input cartella progetto e dominio
read -p "Percorso root progetto (es. /var/www/html/giefferacing): " ROOT_DIR
read -p "Dominio locale (es. giefferacing.test): " DOMAIN

# Directory per SSL
SSL_DIR="../conf/apache/ssl"
mkdir -p "$SSL_DIR"

SSL_DIR_VHOST="/etc/apache2/ssl"


# Genera certificato con mkcert
mkcert -cert-file "$SSL_DIR/$DOMAIN.crt" -key-file "$SSL_DIR/$DOMAIN.key" "$DOMAIN" "*.${DOMAIN}"

echo "Certificati generati:"
echo " - $SSL_DIR/$DOMAIN.crt"
echo " - $SSL_DIR/$DOMAIN.key"

# File vhost SSL
VHOST_SSL_CONF="../conf/apache/vhosts-ssl.conf"

cat >> "$VHOST_SSL_CONF" <<EOL

<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $ROOT_DIR

    SSLEngine on
    SSLCertificateFile $SSL_DIR_VHOST/$DOMAIN.crt
    SSLCertificateKeyFile $SSL_DIR_VHOST/$DOMAIN.key

    <Directory "$ROOT_DIR">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

EOL

echo "VirtualHost SSL aggiunto in $VHOST_SSL_CONF"
echo "Ricorda di abilitare mod_ssl e di riavviare Apache nel container."