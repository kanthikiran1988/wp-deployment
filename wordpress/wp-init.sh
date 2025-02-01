#!/bin/bash

# Wait for MySQL to be ready
until wp db check --allow-root 2>/dev/null; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    
    # Install WordPress
    wp core install \
        --url="https://${DOMAIN}" \
        --title="WordPress Site" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Configure WordPress settings
    wp option update blogname "${DOMAIN}" --allow-root
    wp option update blogdescription "My WordPress Site" --allow-root
    wp option update blog_public 1 --allow-root
    wp option update timezone_string "UTC" --allow-root
    
    # Install and activate Redis object cache
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."
fi

# Start PHP-FPM
php-fpm 