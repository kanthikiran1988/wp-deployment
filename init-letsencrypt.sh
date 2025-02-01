#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# Set domains array using environment variables
domains=("$DOMAIN" "$DOMAIN_WWW")
email="$DOMAIN_EMAIL"
staging="$SSL_STAGING"

# Create the certbot directory structure
mkdir -p certbot/conf certbot/data

# Stop nginx if it's running
docker-compose down

# Delete any existing certificates (use with caution!)
rm -rf certbot/conf/*

# Download recommended TLS parameters
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem

# Start nginx
docker-compose up -d nginx

# Wait for nginx to start
echo "### Waiting for nginx to start..."
sleep 5

# Request the certificates
if [ "$staging" != "0" ]; then staging_arg="--staging"; fi

# Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Request the certificate
docker-compose run --rm certbot certonly \
    --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size "$SSL_KEY_SIZE" \
    --agree-tos \
    --force-renewal

# Reload nginx
docker-compose exec nginx nginx -s reload 