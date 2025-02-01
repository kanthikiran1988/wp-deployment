# WordPress Docker Production Deployment

A production-ready WordPress deployment setup using Docker with automated configuration, SSL support, and performance optimizations. This setup includes automatic resource allocation, multi-environment support, and security hardening.

## 🌟 Features

- **Smart Configuration**
  - Automatic resource detection and allocation
  - Memory optimization for MySQL, PHP, and Nginx
  - Environment-specific configurations (Production/Staging/Development)

- **Performance Optimizations**
  - Redis object caching
  - PHP OpCache with JIT compilation
  - MySQL/MariaDB tuning
  - Nginx with FastCGI caching
  - Automatic resource allocation based on server capabilities

- **Security Features**
  - Automatic SSL certificate management with Let's Encrypt
  - WordPress security keys auto-generation
  - Secure PHP and MySQL configurations
  - HTTP/2 support
  - Automatic admin credential management

- **High Availability**
  - Health checks for all services
  - Automatic container restarts
  - Persistent data volumes
  - Regular backup system

## 📋 Prerequisites

- Docker (version 20.10.0 or higher)
- Docker Compose (version 2.0.0 or higher)
- Domain name pointed to your server
- Open ports 80 and 443
- Minimum recommended specs:
  - 2GB RAM (minimum)
  - 2 CPU cores
  - 20GB storage

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
   The script will:
   - Detect your server resources
   - Ask for domain information
   - Configure WordPress admin credentials
   - Generate secure passwords and keys
   - Create optimized configurations for all services

3. Initialize SSL certificates:
   ```bash
   ./init-letsencrypt.sh
   ```

4. Start the services:
   ```bash
   docker-compose up -d
   ```

5. Access your WordPress site at https://your-domain.com

## 🏗️ System Architecture

### Components

- **WordPress (PHP-FPM)**
  - PHP 8.1 with OpCache and JIT
  - Custom php.ini optimized for your server
  - WP-CLI for management
  - Automated initialization

- **Nginx**
  - HTTP/2 support
  - FastCGI caching
  - Static file optimization
  - SSL termination

- **MariaDB**
  - Optimized InnoDB settings
  - Performance tuning
  - Automated backups
  - Secure defaults

- **Redis**
  - Object caching
  - Session handling
  - Persistent storage

- **Certbot**
  - Automatic SSL management
  - Certificate renewal
  - Staging/Production modes

### Directory Structure
```
.
├── docker-compose.yml      # Main Docker configuration
├── .env                    # Environment variables (auto-generated)
├── configure.sh            # Configuration script
├── init-letsencrypt.sh    # SSL initialization
├── backup.sh              # Backup script
├── wordpress/
│   └── wp-init.sh        # WordPress initialization
├── nginx/
│   └── wordpress.conf    # Nginx configuration
├── php/
│   └── php.ini          # PHP configuration
├── mysql/
│   └── conf.d/
│       └── my.cnf       # MySQL configuration
├── certbot/             # SSL certificates
└── wp-content/          # WordPress content
```

## ⚙️ Configuration

### Environment Types

1. **Production**
   - SSL enabled and enforced
   - Caching enabled
   - Debug disabled
   - Maximum security

2. **Staging**
   - SSL in staging mode
   - Similar to production
   - Limited debugging

3. **Development**
   - SSL optional
   - Debug enabled
   - Development tools

### Resource Allocation

Resources are automatically allocated based on your server's capabilities:

- **MySQL**: 40% of available memory
  - InnoDB buffer pool: 50% of MySQL memory
  - Query cache: 5% of MySQL memory

- **PHP**: 30% of available memory
  - OpCache: Optimized for WordPress
  - Upload limits: Auto-calculated
  - JIT enabled

- **Nginx**: Based on CPU cores
  - Worker processes: Equal to CPU cores
  - Worker connections: 1024 × CPU cores

## 🔒 Security

### SSL/TLS
- Automatic certificate management
- HTTPS enforced
- HSTS enabled
- Modern cipher suites

### WordPress Security
- Auto-generated security keys
- Disabled file editing
- Limited login attempts
- Secure admin credentials

### Database Security
- Random strong passwords
- Remote root access disabled
- Secure defaults

## 💾 Backup and Restore

### Automated Backups
Run the backup script:
```bash
./backup.sh
```

Features:
- Database dumps
- File backups
- Configurable retention
- Compression

### Manual Backup
Database:
```bash
docker-compose exec db mysqldump -u[user] -p[password] wordpress > backup.sql
```

Files:
```bash
tar -czf wp-content-backup.tar.gz wp-content/
```

## 🔧 Maintenance

### Updates
WordPress core, themes, and plugins:
```bash
docker-compose exec wordpress wp core update
docker-compose exec wordpress wp plugin update --all
docker-compose exec wordpress wp theme update --all
```

### Monitoring
View logs:
```bash
# All containers
docker-compose logs -f

# Specific service
docker-compose logs -f [wordpress|db|nginx|redis]
```

### Health Checks
```bash
docker-compose ps
docker stats
```

## 🔍 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   - Check DNS settings
   - Verify ports 80/443
   - Review certbot logs

2. **Database Connection**
   - Check credentials in .env
   - Verify database logs
   - Check network connectivity

3. **Performance Issues**
   - Review resource allocation
   - Check PHP/MySQL logs
   - Monitor cache hit rates

### Debug Mode
Enable WordPress debugging:
1. Set WORDPRESS_DEBUG=1 in .env
2. Restart containers:
```bash
docker-compose restart wordpress
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details. 