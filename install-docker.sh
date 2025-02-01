#!/bin/bash

# Text formatting
BOLD='\033[1m'
NORMAL='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NORMAL}"
    else
        echo -e "${RED}✗ Failed${NORMAL}"
        exit 1
    fi
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root or with sudo${NORMAL}"
    exit 1
fi

echo -e "${BOLD}Docker Installation Script for Ubuntu 24.04${NORMAL}"
echo "=========================================================="

# Update package list
echo -e "\n${BLUE}Updating package list...${NORMAL}"
apt-get update
check_status

# Install required packages
echo -e "\n${BLUE}Installing required packages...${NORMAL}"
apt-get install -y ca-certificates curl gnupg lsb-release
check_status

# Add Docker's official GPG key
echo -e "\n${BLUE}Adding Docker's official GPG key...${NORMAL}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
check_status

# Add Docker repository
echo -e "\n${BLUE}Setting up Docker repository...${NORMAL}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
check_status

# Update package list again
echo -e "\n${BLUE}Updating package list with Docker repository...${NORMAL}"
apt-get update
check_status

# Install Docker
echo -e "\n${BLUE}Installing Docker...${NORMAL}"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check_status

# Start and enable Docker service
echo -e "\n${BLUE}Starting Docker service...${NORMAL}"
systemctl start docker
systemctl enable docker
check_status

# Add current user to docker group
echo -e "\n${BLUE}Adding current user to docker group...${NORMAL}"
usermod -aG docker $SUDO_USER
check_status

# Install Docker Compose
echo -e "\n${BLUE}Installing Docker Compose...${NORMAL}"
apt-get install -y docker-compose-plugin
check_status

# Verify installations
echo -e "\n${BLUE}Verifying Docker installation...${NORMAL}"
docker --version
docker compose version

echo -e "\n${GREEN}Docker installation completed successfully!${NORMAL}"
echo -e "${YELLOW}Please log out and log back in for the docker group changes to take effect.${NORMAL}"
echo -e "\nTo verify installation after logging back in, run:"
echo -e "${BLUE}docker run hello-world${NORMAL}"
echo -e "\nTo check Docker service status:"
echo -e "${BLUE}systemctl status docker${NORMAL}" 