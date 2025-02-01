#!/bin/bash

# Text formatting
BOLD='\033[1m'
NORMAL='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'

# Function to get total system memory in MB
get_total_memory() {
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((total_kb / 1024))
}

# Function to get number of CPU cores
get_cpu_cores() {
    nproc
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt=$1
    local default=$2
    local response

    echo -e "${BOLD}${prompt} [${default}]:${NORMAL} "
    read response
    echo "${response:-$default}"
}

# Function to calculate optimal MySQL/MariaDB settings based on available memory
calculate_mysql_settings() {
    local total_mem=$1
    local mysql_mem=$((total_mem * 40 / 100))  # 40% of total memory for MySQL

    # InnoDB buffer pool size (50% of MySQL memory)
    local innodb_buffer_pool_size=$((mysql_mem * 50 / 100))
    # Query cache size (5% of MySQL memory)
    local query_cache_size=$((mysql_mem * 5 / 100))
    # Key buffer size (10% of MySQL memory)
    local key_buffer_size=$((mysql_mem * 10 / 100))

    echo "innodb_buffer_pool_size=${innodb_buffer_pool_size}M"
    echo "query_cache_size=${query_cache_size}M"
    echo "key_buffer_size=${key_buffer_size}M"
}

# Function to calculate optimal PHP settings
calculate_php_settings() {
    local total_mem=$1
    local php_mem=$((total_mem * 30 / 100))  # 30% of total memory for PHP

    echo "memory_limit=${php_mem}M"
    echo "max_execution_time=300"
    echo "upload_max_filesize=$((php_mem / 10))M"
    echo "post_max_size=$((php_mem / 8))M"
}

# Function to calculate optimal Nginx settings
calculate_nginx_settings() {
    local total_mem=$1
    local cpu_cores=$2
    
    local worker_processes=$cpu_cores
    local worker_connections=$((1024 * cpu_cores))
    local client_max_body_size=$((total_mem / 10))

    echo "worker_processes=$worker_processes"
    echo "worker_connections=$worker_connections"
    echo "client_max_body_size=${client_max_body_size}M"
}

# Main configuration script
echo -e "${BOLD}WordPress Docker Configuration Generator${NORMAL}"
echo "----------------------------------------"

# Get system resources
TOTAL_MEM=$(get_total_memory)
CPU_CORES=$(get_cpu_cores)

echo -e "${BLUE}Detected System Resources:${NORMAL}"
echo "Total Memory: ${TOTAL_MEM}MB"
echo "CPU Cores: ${CPU_CORES}"
echo

# Domain Configuration
echo -e "${BOLD}Domain Configuration${NORMAL}"
DOMAIN=$(prompt_with_default "Enter your domain name" "example.com")
DOMAIN_WWW=$(prompt_with_default "Enter www domain" "www.${DOMAIN}")
DOMAIN_EMAIL=$(prompt_with_default "Enter email for SSL certificates" "admin@${DOMAIN}")

# Environment Type
echo -e "\n${BOLD}Environment Configuration${NORMAL}"
ENV_TYPE=$(prompt_with_default "Enter environment type (production/staging/development)" "production")

# Calculate resource allocations
echo -e "\n${BOLD}Calculating optimal resource allocations...${NORMAL}"
MYSQL_SETTINGS=$(calculate_mysql_settings $TOTAL_MEM)
PHP_SETTINGS=$(calculate_php_settings $TOTAL_MEM)
NGINX_SETTINGS=$(calculate_nginx_settings $TOTAL_MEM $CPU_CORES)

# Generate .env file
echo -e "\n${BOLD}Generating .env file...${NORMAL}"
cat > .env << EOL
# Environment Type
WP_ENVIRONMENT_TYPE=${ENV_TYPE}

# Domain Configuration
DOMAIN=${DOMAIN}
DOMAIN_WWW=${DOMAIN_WWW}
DOMAIN_EMAIL=${DOMAIN_EMAIL}

# MySQL Configuration
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=$(openssl rand -base64 24)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)

# WordPress Configuration
WORDPRESS_DEBUG=$([ "$ENV_TYPE" = "development" ] && echo "1" || echo "0")
WORDPRESS_CONFIG_EXTRA=
  define('WP_MEMORY_LIMIT', '${PHP_SETTINGS%% *}');
  define('WP_MAX_MEMORY_LIMIT', '$((TOTAL_MEM / 2))M');
  define('AUTOMATIC_UPDATER_DISABLED', true);
  define('WP_CACHE', true);
  define('WP_REDIS_HOST', 'redis');
  define('WP_REDIS_PORT', 6379);

# SSL Configuration
SSL_STAGING=$([ "$ENV_TYPE" = "production" ] && echo "0" || echo "1")
SSL_KEY_SIZE=4096

# Nginx Configuration
NGINX_RESOLVER=8.8.8.8 8.8.4.4
NGINX_RESOLVER_TIMEOUT=5s
SSL_SESSION_TIMEOUT=1d
SSL_SESSION_CACHE=shared:SSL:50m
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
$(echo "$NGINX_SETTINGS" | grep "client_max_body_size")

# PHP Configuration
$(echo "$PHP_SETTINGS")
PHP_MAX_INPUT_VARS=3000

# Backup Configuration
BACKUP_RETENTION_DAYS=7
BACKUP_PATH=/backup

# Security Configuration (auto-generated)
$(for key in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
    echo "${key}=$(openssl rand -base64 48)"
done)
EOL

# Generate MySQL configuration
echo -e "\n${BOLD}Generating MySQL configuration...${NORMAL}"
mkdir -p mysql/conf.d
cat > mysql/conf.d/my.cnf << EOL
[mysqld]
# Basic Settings
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
datadir = /var/lib/mysql
log-error = /var/log/mysql/error.log

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# InnoDB Settings
$(echo "$MYSQL_SETTINGS" | grep "innodb_buffer_pool_size")
innodb_log_file_size = $((TOTAL_MEM / 16))M
innodb_log_buffer_size = $((TOTAL_MEM / 64))M
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_thread_concurrency = $((CPU_CORES * 2))

# Connection Settings
max_connections = $((TOTAL_MEM / 10))
max_allowed_packet = 64M
thread_cache_size = $((CPU_CORES * 8))
table_open_cache = $((TOTAL_MEM / 4))
table_definition_cache = $((TOTAL_MEM / 8))

# Query Cache
$(echo "$MYSQL_SETTINGS" | grep "query_cache_size")
query_cache_limit = $((TOTAL_MEM / 256))M

# Temporary Tables
tmp_table_size = $((TOTAL_MEM / 16))M
max_heap_table_size = $((TOTAL_MEM / 16))M

# Search Settings
ft_min_word_len = 3

# Slow Query Log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Security Settings
local-infile = 0
skip-symbolic-links

[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4
EOL

# Generate PHP configuration
echo -e "\n${BOLD}Generating PHP configuration...${NORMAL}"
mkdir -p php
cat > php/php.ini << EOL
[PHP]
; Memory
memory_limit = ${PHP_SETTINGS%% *}
max_execution_time = 300
max_input_time = 300

; Uploads
upload_max_filesize = $((TOTAL_MEM / 20))M
post_max_size = $((TOTAL_MEM / 16))M
max_input_vars = 3000

; Error reporting
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log

; Date
date.timezone = UTC

; Session
session.save_handler = redis
session.save_path = "tcp://redis:6379"
session.gc_maxlifetime = 1440
session.gc_probability = 1
session.gc_divisor = 100

; OpCache
opcache.enable = 1
opcache.memory_consumption = $((TOTAL_MEM / 8))
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.enable_cli = 1
opcache.jit = 1255
opcache.jit_buffer_size = $((TOTAL_MEM / 8))M

; Security
expose_php = Off
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
allow_url_fopen = Off
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source
EOL

# Create necessary directories
mkdir -p {nginx,certbot/{conf,data,logs},wp-content}

echo -e "\n${GREEN}Configuration completed successfully!${NORMAL}"
echo -e "Please review the generated configurations in:"
echo "- .env"
echo "- mysql/conf.d/my.cnf"
echo "- php/php.ini"
echo
echo -e "${BOLD}Next steps:${NORMAL}"
echo "1. Review and adjust the generated configurations if needed"
echo "2. Run './init-letsencrypt.sh' to set up SSL certificates"
echo "3. Start your containers with 'docker-compose up -d'"
echo
echo -e "${RED}Note: Keep your .env file secure as it contains sensitive information${NORMAL}" 