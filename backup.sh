#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_PATH}/database"
mkdir -p "${BACKUP_PATH}/wordpress"

# Set timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup database
echo "Creating database backup..."
docker-compose exec -T db mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "${BACKUP_PATH}/database/wordpress_db_${TIMESTAMP}.sql"

# Backup WordPress files
echo "Creating WordPress files backup..."
tar -czf "${BACKUP_PATH}/wordpress/wp-content_${TIMESTAMP}.tar.gz" wp-content/

# Compress database backup
gzip "${BACKUP_PATH}/database/wordpress_db_${TIMESTAMP}.sql"

# Clean up old backups
echo "Cleaning up old backups..."
find "${BACKUP_PATH}/database" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
find "${BACKUP_PATH}/wordpress" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete

# Create backup log
echo "Backup completed at $(date)" >> "${BACKUP_PATH}/backup.log"

# Set proper permissions
chmod 600 "${BACKUP_PATH}/database/wordpress_db_${TIMESTAMP}.sql.gz"
chmod 600 "${BACKUP_PATH}/wordpress/wp-content_${TIMESTAMP}.tar.gz"

echo "Backup completed successfully!" 