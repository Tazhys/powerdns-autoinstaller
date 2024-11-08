#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Variables
PDNS_API_KEY=$(openssl rand -hex 32)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
MYSQL_PDMS_PASSWORD=$(openssl rand -base64 12)
OUTPUT_FILE="pdns_credentials.txt"
EXTERNAL_SUBNET="IP_BLOCK_HERE"  # Adjust as needed
EXTRA_IP=""         # Additional allowed IP

echo "Updating system packages..."
apt update && apt upgrade -y

echo "Disabling systemd-resolved to avoid port 53 conflict..."
systemctl disable --now systemd-resolved
rm -rf /etc/resolv.conf
echo "nameserver 8.8.8.8" | tee /etc/resolv.conf

echo "Installing PowerDNS dependencies and MySQL..."
apt install -y pdns-server pdns-backend-mysql mariadb-server

echo "Securing MySQL installation..."
mysql_secure_installation <<EOF

Y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
Y
Y
Y
Y
EOF

echo "Configuring MySQL for PowerDNS..."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE powerdns;
CREATE USER 'powerdns'@'localhost' IDENTIFIED BY '$MYSQL_PDMS_PASSWORD';
GRANT ALL ON powerdns.* TO 'powerdns'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Installing PowerDNS schema..."
mysql -upowerdns -p"$MYSQL_PDMS_PASSWORD" powerdns < /usr/share/doc/pdns-backend-mysql/schema.mysql.sql

echo "Configuring PowerDNS..."
cat > /etc/powerdns/pdns.conf <<EOF
launch=gmysql
gmysql-host=127.0.0.1
gmysql-user=powerdns
gmysql-password=$MYSQL_PDMS_PASSWORD
gmysql-dbname=powerdns

api=yes
api-key=$PDNS_API_KEY
webserver=yes
webserver-address=0.0.0.0
webserver-port=8081
webserver-allow-from=127.0.0.1,::1,$EXTERNAL_SUBNET,$EXTRA_IP
EOF

echo "Generating self-signed SSL certificate..."
openssl req -x509 -newkey rsa:4096 -keyout /etc/powerdns/api.key -out /etc/powerdns/api.crt -days 365 -nodes -subj "/CN=PowerDNS"

echo "Setting up SSL certificates..."
ln -sf /etc/powerdns/api.key /etc/ssl/private/api.key
ln -sf /etc/powerdns/api.crt /etc/ssl/certs/api.crt

echo "Restarting PowerDNS service..."
systemctl restart pdns

# Print and save credentials
echo "Saving credentials to $OUTPUT_FILE..."
cat > "$OUTPUT_FILE" <<EOF
MySQL Root Password: $MYSQL_ROOT_PASSWORD
PowerDNS MySQL Password: $MYSQL_PDMS_PASSWORD
PowerDNS API Key: $PDNS_API_KEY
EOF

echo "Installation complete!"
echo "Credentials:"
cat "$OUTPUT_FILE"
