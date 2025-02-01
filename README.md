# WordPress Docker Production Setup

This repository contains a production-ready Docker setup for WordPress with Nginx, PHP-FPM, and MariaDB.

## Prerequisites

- Docker
- Docker Compose
- SSL certificates for your domain

## Directory Structure

```
.
├── docker-compose.yml
├── .env
├── nginx/
│   └── wordpress.conf
├── ssl/
│   ├── fullchain.pem
│   └── privkey.pem
└── wp-content/
```

## Setup Instructions

1. Clone this repository
2. Create the required directories:
   ```bash
   mkdir -p nginx ssl wp-content
   ```

3. Copy your SSL certificates to the `ssl` directory:
   ```bash
   cp path/to/your/fullchain.pem ssl/
   cp path/to/your/privkey.pem ssl/
   ```

4. Update the `.env` file with your secure passwords and configuration

5. Start the containers:
   ```bash
   docker-compose up -d
   ```

6. Access your WordPress site at https://your-domain.com

## Migration Steps

1. Export your existing WordPress database from Plesk
2. Copy your existing wp-content directory from Plesk
3. Import the database using:
   ```bash
   docker exec -i wordpress_db mysql -u[user] -p[password] [database_name] < backup.sql
   ```
4. Copy your wp-content files to the wp-content directory

## Maintenance

### Backup

To backup your WordPress site:

1. Backup the database:
   ```bash
   docker exec wordpress_db mysqldump -u[user] -p[password] [database_name] > backup.sql
   ```

2. Backup wp-content:
   ```bash
   tar -czf wp-content-backup.tar.gz wp-content/
   ```

### Updates

To update the containers:

```bash
docker-compose pull
docker-compose up -d
```

## Security Notes

- Change all default passwords in the .env file
- Keep your SSL certificates up to date
- Regularly update WordPress core, themes, and plugins
- Take regular backups
- Monitor your logs for suspicious activity

## Troubleshooting

### Check container logs:
```bash
docker-compose logs -f [service_name]
```

### Restart services:
```bash
docker-compose restart [service_name]
```

### Check container status:
```bash
docker-compose ps
``` 