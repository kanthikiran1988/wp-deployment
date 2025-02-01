#!/bin/bash

# Text formatting
BOLD='\033[1m'
NORMAL='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

# Function to check and configure Docker permissions
setup_docker_permissions() {
    echo -e "\n${BOLD}Checking Docker Permissions${NORMAL}"
    echo "----------------------------------------"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NORMAL}"
        exit 1
    fi

    # Check Docker service status
    if ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}Docker service is not running. Attempting to start...${NORMAL}"
        sudo systemctl start docker
        sleep 2  # Give it a moment to start
    fi

    # Test Docker access with sudo first
    if ! sudo docker info &>/dev/null; then
        echo -e "${RED}Error: Cannot connect to Docker daemon even with sudo${NORMAL}"
        echo "Please check if Docker service is running:"
        echo "sudo systemctl status docker"
        exit 1
    fi

    # Now check if user is in docker group
    if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
        echo -e "${YELLOW}User is not in docker group. Using sudo for Docker commands...${NORMAL}"
        # Create a function to use sudo with docker
        docker() {
            sudo docker "$@"
        }
        export -f docker
        echo -e "${GREEN}✓ Docker configured to run with sudo${NORMAL}"
    else
        # Try normal docker access
        if ! docker info &>/dev/null; then
            echo -e "${YELLOW}Cannot connect to Docker daemon without sudo. Using sudo for this session...${NORMAL}"
            # Create a function to use sudo with docker
            docker() {
                sudo docker "$@"
            }
            export -f docker
            echo -e "${GREEN}✓ Docker configured to run with sudo${NORMAL}"
            echo -e "${YELLOW}Note: Log out and log back in for docker group changes to take effect${NORMAL}"
        else
            echo -e "${GREEN}✓ Docker permissions are correctly configured${NORMAL}"
        fi
    fi
}

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
    local value

    # Print prompts to stderr so they don't get captured in variable assignment
    echo -e "\n${YELLOW}➤${NORMAL} ${prompt}" >&2
    echo -e "${BLUE}Default value:${NORMAL} ${default}" >&2
    echo -ne "${GREEN}Type your value and press Enter (or just press Enter for default):${NORMAL} " >&2
    
    read -r response
    
    if [ -z "$response" ]; then
        echo -e "${BLUE}Using default value:${NORMAL} ${default}" >&2
        value="$default"
    else
        echo -e "${BLUE}Using value:${NORMAL} ${response}" >&2
        value="$response"
    fi

    # Return only the actual value, without any prompts or messages
    printf '%s' "$value"
}

# Function to prompt for environment type with clear options
prompt_for_environment() {
    local env_type=""
    
    echo -e "\n${YELLOW}➤${NORMAL} Please select your environment type:"
    echo -e "${BLUE}Available options:${NORMAL}"
    echo "   1) Production (optimized for performance, SSL enabled)"
    echo "   2) Staging (testing environment with staging SSL)"
    echo "   3) Development (debugging enabled, no SSL required)"
    echo -ne "${GREEN}Please enter 1, 2, or 3 and press Enter [1]:${NORMAL} "
    
    read -r choice
    
    case "${choice:-1}" in
        1) 
            env_type="production"
            echo -e "${BLUE}Selected:${NORMAL} Production Environment"
            ;;
        2)
            env_type="staging"
            echo -e "${BLUE}Selected:${NORMAL} Staging Environment"
            ;;
        3)
            env_type="development"
            echo -e "${BLUE}Selected:${NORMAL} Development Environment"
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default: Production${NORMAL}"
            env_type="production"
            ;;
    esac
    
    # Add a newline for better formatting
    echo ""
    
    # Return the selected environment type
    echo "$env_type"
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

# Main script starts here
setup_docker_permissions
clear
echo -e "${BOLD}WordPress Docker Configuration Generator${NORMAL}"
echo -e "${BLUE}This script will help you configure your WordPress deployment${NORMAL}"
echo "=========================================================="

# Get system resources
echo -e "\n${BOLD}Step 1: System Resource Detection${NORMAL}"
echo "----------------------------------------"
TOTAL_MEM=$(get_total_memory)
CPU_CORES=$(get_cpu_cores)

echo -e "${BLUE}Detected System Resources:${NORMAL}"
echo "• Total Memory: ${TOTAL_MEM}MB"
echo "• CPU Cores: ${CPU_CORES}"
echo -e "${GREEN}✓ System resources detected successfully${NORMAL}"

if [ $TOTAL_MEM -lt 1024 ]; then
    echo -e "\n${RED}⚠️ Warning: Your system has less than 1GB of RAM (${TOTAL_MEM}MB)${NORMAL}"
    echo -e "This might affect WordPress performance. Recommended minimum is 2GB RAM."
    echo -ne "${YELLOW}Do you want to continue anyway? (y/n):${NORMAL} "
    read continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        echo -e "${RED}Configuration aborted. Please use a server with more RAM.${NORMAL}"
        exit 1
    fi
fi

# Domain Configuration
echo -e "\n${BOLD}Step 2: Domain Configuration${NORMAL}"
echo "----------------------------------------"
echo -e "${BLUE}Please provide your domain information:${NORMAL}"
echo -e "${YELLOW}Example: If your website is https://example.com, just enter 'example.com'${NORMAL}"

# Store the values in variables without capturing the prompts
DOMAIN=$(prompt_with_default "Enter your main domain name (without www)" "example.com")
DOMAIN_WWW=$(prompt_with_default "Enter your www domain (press Enter to use www.${DOMAIN})" "www.${DOMAIN}")
DOMAIN_EMAIL=$(prompt_with_default "Enter the email address for SSL certificates" "admin@${DOMAIN}")

echo -e "\n${YELLOW}The www subdomain will be automatically configured${NORMAL}"
DOMAIN_WWW=$(prompt_with_default "Enter your www domain (press Enter to use www.${DOMAIN})" "www.${DOMAIN}")

echo -e "\n${YELLOW}This email will be used for SSL certificate notifications${NORMAL}"
DOMAIN_EMAIL=$(prompt_with_default "Enter the email address for SSL certificates" "admin@${DOMAIN}")

echo -e "\n${YELLOW}WordPress Admin Configuration${NORMAL}"
WP_ADMIN_USER=$(prompt_with_default "Enter WordPress admin username" "admin")
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_EMAIL=$(prompt_with_default "Enter WordPress admin email" "${DOMAIN_EMAIL}")

# Environment Type
echo -e "\n${BOLD}Step 3: Environment Configuration${NORMAL}"
echo "----------------------------------------"
echo -e "${BLUE}Select the environment type for your WordPress installation:${NORMAL}"

# Display options first
echo -e "${BLUE}Available options:${NORMAL}"
echo "   1) Production (optimized for performance, SSL enabled)"
echo "   2) Staging (testing environment with staging SSL)"
echo "   3) Development (debugging enabled, no SSL required)"
echo -ne "${GREEN}Please enter 1, 2, or 3 and press Enter [1]:${NORMAL} "

# Read the choice directly
read -r choice

# Process the choice
case "${choice:-1}" in
    1) 
        ENV_TYPE="production"
        echo -e "${BLUE}Selected:${NORMAL} Production Environment"
        ;;
    2)
        ENV_TYPE="staging"
        echo -e "${BLUE}Selected:${NORMAL} Staging Environment"
        ;;
    3)
        ENV_TYPE="development"
        echo -e "${BLUE}Selected:${NORMAL} Development Environment"
        ;;
    *)
        ENV_TYPE="production"
        echo -e "${RED}Invalid choice. Using default: Production${NORMAL}"
        ;;
esac

# Add a newline for better formatting
echo ""

# Database Configuration
echo -e "\n${BOLD}Step 4: Database Configuration${NORMAL}"
echo "----------------------------------------"
echo -e "${BLUE}Configuring MySQL with optimal settings for your hardware:${NORMAL}"
echo -e "• Allocating 40% of total memory ($(((TOTAL_MEM * 40 / 100)))MB) for MySQL"
MYSQL_SETTINGS=$(calculate_mysql_settings $TOTAL_MEM)

# PHP Configuration
echo -e "\n${BOLD}Step 5: PHP Configuration${NORMAL}"
echo "----------------------------------------"
echo -e "${BLUE}Configuring PHP with optimal settings for your hardware:${NORMAL}"
echo -e "• Allocating 30% of total memory ($(((TOTAL_MEM * 30 / 100)))MB) for PHP"
PHP_SETTINGS=$(calculate_php_settings $TOTAL_MEM)

# Nginx Configuration
echo -e "\n${BOLD}Step 6: Nginx Configuration${NORMAL}"
echo "----------------------------------------"
echo -e "${BLUE}Configuring Nginx with optimal settings for your hardware:${NORMAL}"
NGINX_SETTINGS=$(calculate_nginx_settings $TOTAL_MEM $CPU_CORES)

# Generate Configurations
echo -e "\n${BOLD}Step 7: Generating Configuration Files${NORMAL}"
echo "----------------------------------------"

echo -e "Generating .env file..."
{
    echo "# Environment Type"
    echo "WP_ENVIRONMENT_TYPE=${ENV_TYPE}"
    echo
    echo "# Domain Configuration"
    echo "DOMAIN=${DOMAIN}"
    echo "DOMAIN_WWW=${DOMAIN_WWW}"
    echo "DOMAIN_EMAIL=${DOMAIN_EMAIL}"
    echo
    echo "# WordPress Admin Configuration"
    echo "WORDPRESS_ADMIN_USER=${WP_ADMIN_USER}"
    echo "WORDPRESS_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}"
    echo "WORDPRESS_ADMIN_EMAIL=${WP_ADMIN_EMAIL}"
    echo
    echo "# MySQL Configuration"
    echo "MYSQL_DATABASE=wordpress_db"
    echo "MYSQL_USER=wordpress_user"
    echo "MYSQL_PASSWORD=$(openssl rand -base64 24)"
    echo "MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)"
    echo
    echo "# WordPress Configuration"
    echo "WORDPRESS_DEBUG=$([ "$ENV_TYPE" = "development" ] && echo "1" || echo "0")"
    echo "WORDPRESS_CONFIG_EXTRA=\"define('WP_MEMORY_LIMIT', '${PHP_SETTINGS%% *}');"
    echo "define('WP_MAX_MEMORY_LIMIT', '$((TOTAL_MEM / 2))M');"
    echo "define('AUTOMATIC_UPDATER_DISABLED', true);"
    echo "define('WP_CACHE', true);"
    echo "define('WP_REDIS_HOST', 'redis');"
    echo "define('WP_REDIS_PORT', 6379);\""
    echo
    echo "# SSL Configuration"
    echo "SSL_STAGING=$([ "$ENV_TYPE" = "production" ] && echo "0" || echo "1")"
    echo "SSL_KEY_SIZE=4096"
    echo
    echo "# Nginx Configuration"
    echo "NGINX_RESOLVER=\"8.8.8.8 8.8.4.4\""
    echo "NGINX_RESOLVER_TIMEOUT=5s"
    echo "SSL_SESSION_TIMEOUT=1d"
    echo "SSL_SESSION_CACHE=shared:SSL:50m"
    echo "NGINX_HTTP_PORT=80"
    echo "NGINX_HTTPS_PORT=443"
    echo "NGINX_CLIENT_MAX_BODY_SIZE=$((TOTAL_MEM / 10))M"
    echo
    echo "# PHP Configuration"
    echo "${PHP_SETTINGS}"
    echo "PHP_MAX_INPUT_VARS=3000"
    echo
    echo "# Backup Configuration"
    echo "BACKUP_RETENTION_DAYS=7"
    echo "BACKUP_PATH=/backup"
    echo
    echo "# Security Configuration (auto-generated)"
    for key in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
        echo "${key}=$(openssl rand -base64 48)"
    done
} > .env
echo -e "${GREEN}✓ .env file generated${NORMAL}"

echo -e "Generating MySQL configuration..."
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
echo -e "${GREEN}✓ MySQL configuration generated${NORMAL}"

echo -e "Generating PHP configuration..."
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
echo -e "${GREEN}✓ PHP configuration generated${NORMAL}"

# Create necessary directories
echo -e "\n${BOLD}Step 8: Creating Directory Structure${NORMAL}"
echo "----------------------------------------"
echo "Creating required directories..."
mkdir -p {nginx,certbot/{conf,data,logs},wp-content,wordpress}
chmod +x wordpress/wp-init.sh
echo -e "${GREEN}✓ Directories created${NORMAL}"

# Final Summary
echo -e "\n${BOLD}Configuration Complete!${NORMAL}"
echo "=========================================================="
echo -e "${GREEN}The following files have been generated:${NORMAL}"
echo "• .env (environment variables and secrets)"
echo "• mysql/conf.d/my.cnf (MySQL configuration)"
echo "• php/php.ini (PHP configuration)"
echo
echo -e "${BOLD}Next Steps:${NORMAL}"
echo "1. Review the generated configurations in the files above"
echo "2. Run: ./init-letsencrypt.sh to set up SSL certificates"
echo "3. Run: docker-compose up -d to start your containers"
echo
echo -e "${RED}Important:${NORMAL}"
echo "• Keep your .env file secure - it contains sensitive information"
echo "• Make sure to backup your configuration files"
echo "• For production deployment, review security settings"
echo
echo -e "${YELLOW}WordPress Admin Credentials (SAVE THESE):${NORMAL}"
echo "• Username: ${WP_ADMIN_USER}"
echo "• Password: ${WP_ADMIN_PASSWORD}"
echo "• Email: ${WP_ADMIN_EMAIL}"
echo -e "${RED}Make sure to save these credentials before proceeding!${NORMAL}"
echo
echo -e "${BLUE}Need help? Check the README.md file for more information${NORMAL}" 