#!/bin/bash
set -e

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 1
done

# Start PHP-FPM in the background
php-fpm -D

# Wait for PHP-FPM to start
sleep 2

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    # Install WordPress
    wp core install \
        --url="https://${DOMAIN}" \
        --title="Your Site Title" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Include extra configuration
    if [ -f wp-config-extra.php ]; then
        echo "require_once('wp-config-extra.php');" >> wp-config.php
    fi

    # Install and activate Redis Object Cache plugin
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."
fi

# Keep container running
php-fpm 