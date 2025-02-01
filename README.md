# WordPress Docker Production Deployment

A production-ready WordPress deployment setup using Docker with automated configuration, SSL support, and performance optimizations.

## 🌟 Features

- **Automated Configuration**: Smart resource allocation based on your server's capabilities
- **Multi-Environment Support**: Production, Staging, and Development environments
- **Performance Optimized**:
  - Redis object caching
  - PHP OpCache configuration
  - MySQL/MariaDB tuning
  - Nginx optimizations
- **Security Focused**:
  - Automatic SSL certificate management with Let's Encrypt
  - Secure PHP and MySQL configurations
  - WordPress security hardening
- **Scalable Architecture**:
  - Separate containers for each service
  - Persistent data volumes
  - Easy backup and restore

## 📋 Prerequisites

- Docker (version 20.10.0 or higher)
- Docker Compose (version 2.0.0 or higher)
- A domain name pointed to your server
- Open ports 80 and 443 on your firewall

## 🚀 Quick Start

1. Clone this repository:
   ```bash
   git clone [repository-url]
   cd wordpress-docker
   ```

2. Run the configuration script:
   ```bash
   ./configure.sh
   ```
   This script will:
   - Detect your server resources
   - Configure optimal settings for your hardware
   - Generate all necessary configuration files
   - Set up directory structure

3. Initialize SSL certificates:
   ```bash
   ./init-letsencrypt.sh
   ```

4. Start the containers:
   ```bash
   docker-compose up -d
   ```

## 🏗️ Architecture

### Container Structure
- **WordPress (PHP-FPM)**
  - PHP 8.1 with optimized configuration
  - Custom php.ini based on server resources
  - OpCache and JIT enabled

- **Nginx**
  - Reverse proxy with SSL termination
  - Static file serving
  - Optimized for WordPress

- **MariaDB**
  - Optimized InnoDB settings
  - Performance tuning based on available memory
  - Secure default configuration

- **Redis**
  - Object caching
  - Session handling
  - Persistent storage

- **Certbot**
  - Automatic SSL certificate management
  - Certificate renewal

### Directory Structure
```
.
├── docker-compose.yml      # Main Docker Compose configuration
├── .env                    # Environment variables
├── configure.sh            # Configuration script
├── init-letsencrypt.sh    # SSL initialization script
├── backup.sh              # Backup script
├── nginx/
│   └── wordpress.conf     # Nginx configuration
├── php/
│   └── php.ini           # PHP configuration
├── mysql/
│   └── conf.d/
│       └── my.cnf        # MySQL configuration
├── certbot/
│   ├── conf/             # SSL certificates
│   ├── data/            # Let's Encrypt verification
│   └── logs/            # Certbot logs
└── wp-content/           # WordPress content directory
```

## ⚙️ Configuration

### Environment Types

1. **Production**
   - SSL enabled
   - Caching enabled
   - Debug disabled
   - Performance optimized

2. **Staging**
   - SSL in staging mode
   - Caching enabled
   - Limited debugging
   - Production-like settings

3. **Development**
   - SSL optional
   - Caching optional
   - Full debugging
   - Development-friendly settings

### Resource Allocation

The configuration script automatically allocates resources based on your server's capabilities:

- **MySQL**: 40% of available memory
  - InnoDB buffer pool: 50% of MySQL memory
  - Query cache: 5% of MySQL memory
  - Other buffers: Proportionally allocated

- **PHP**: 30% of available memory
  - OpCache: Optimized for WordPress
  - Upload limits: Automatically calculated
  - Memory limits: Based on available resources

- **Nginx**: Optimized based on CPU cores
  - Worker processes: Equal to CPU cores
  - Worker connections: 1024 × CPU cores
  - Client max body size: Calculated from available memory

## 🔒 Security

### SSL Certificates
- Automatic generation and renewal via Let's Encrypt
- HTTPS enforced by default
- HSTS enabled
- Modern SSL configuration

### WordPress Security
- Automatic updates disabled (managed through Docker)
- Security keys auto-generated
- File permissions properly set
- PHP functions restricted

### Database Security
- Random strong passwords generated
- Remote root access disabled
- Secure default configuration

## 💾 Backup and Restore

### Automated Backups
Run the backup script:
```bash
./backup.sh
```

This will:
- Backup the database
- Backup wp-content directory
- Compress backups
- Maintain backup rotation

### Manual Backup
Database:
```bash
docker-compose exec db mysqldump -u[user] -p[password] wordpress > backup.sql
```

Files:
```bash
tar -czf wp-content-backup.tar.gz wp-content/
```

### Restore
Database:
```bash
docker-compose exec -T db mysql -u[user] -p[password] wordpress < backup.sql
```

Files:
```bash
tar -xzf wp-content-backup.tar.gz
```

## 🔧 Maintenance

### Updating WordPress
1. Update image version in docker-compose.yml
2. Pull new images:
```bash
docker-compose pull
```
3. Restart containers:
```bash
docker-compose up -d
```

### Monitoring
View logs:
```bash
# All containers
docker-compose logs -f

# Specific container
docker-compose logs -f [wordpress|db|nginx|redis]
```

### Common Tasks
- **Restart services**: `docker-compose restart [service]`
- **Check status**: `docker-compose ps`
- **View resource usage**: `docker stats`

## 🔍 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   - Check DNS settings
   - Verify port 80/443 accessibility
   - Review certbot logs

2. **Database Connection Errors**
   - Verify credentials in .env
   - Check database logs
   - Ensure container is running

3. **Performance Issues**
   - Review resource allocation
   - Check PHP and MySQL logs
   - Monitor container resources

### Debug Mode
To enable WordPress debug mode:
1. Set WORDPRESS_DEBUG=1 in .env
2. Restart containers

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details. 