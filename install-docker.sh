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

# Clean up any previous Docker installations
echo -e "\n${BLUE}Cleaning up previous Docker installations...${NORMAL}"
systemctl stop docker || true
systemctl disable docker || true
rm -rf /var/lib/docker
rm -rf /var/run/docker.sock
rm -rf /etc/docker
check_status

# Remove any old Docker installations
echo -e "\n${BLUE}Removing old Docker installations if they exist...${NORMAL}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg > /dev/null 2>&1
done
check_status

# Update package list
echo -e "\n${BLUE}Updating package list...${NORMAL}"
apt-get update
check_status

# Install required packages
echo -e "\n${BLUE}Installing required packages...${NORMAL}"
apt-get install -y ca-certificates curl gnupg
check_status

# Create keyrings directory and import Docker's GPG key
echo -e "\n${BLUE}Setting up Docker GPG key...${NORMAL}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources (using jammy for compatibility)
echo -e "\n${BLUE}Adding Docker repository...${NORMAL}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  jammy stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
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
# Stop the service if it's running
systemctl stop docker || true
# Reset failed state if any
systemctl reset-failed docker.service || true
# Start the service
systemctl start docker
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}Docker service failed to start. Checking logs...${NORMAL}"
    journalctl -xeu docker.service
    echo -e "\n${YELLOW}Attempting to fix common issues...${NORMAL}"
    
    # Create required directories
    mkdir -p /var/lib/docker
    
    # Fix permissions
    chown root:root /var/lib/docker
    chmod 701 /var/lib/docker
    
    # Reload daemon and restart service
    systemctl daemon-reload
    systemctl start docker
    
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}Failed to start Docker service. Please check the logs above for details.${NORMAL}"
        exit 1
    fi
fi
systemctl enable docker
check_status

# Add current user to docker group
echo -e "\n${BLUE}Adding current user to docker group...${NORMAL}"
usermod -aG docker $SUDO_USER
check_status

# Verify installations
echo -e "\n${BLUE}Verifying Docker installation...${NORMAL}"
docker --version
docker compose version

echo -e "\n${GREEN}Docker installation completed successfully!${NORMAL}"
echo -e "${YELLOW}Please log out and log back in for the docker group changes to take effect.${NORMAL}"

# Final verification
echo -e "\n${BLUE}Performing final verification...${NORMAL}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker service is running${NORMAL}"
    docker info || true
else
    echo -e "${RED}Warning: Docker service is not running${NORMAL}"
    echo "Please check the service status with:"
    echo -e "${BLUE}systemctl status docker${NORMAL}"
    echo "And view the logs with:"
    echo -e "${BLUE}journalctl -xeu docker.service${NORMAL}"
fi

echo -e "\nTo verify installation after logging back in, run:"
echo -e "${BLUE}docker run hello-world${NORMAL}"
echo -e "\nTo check Docker service status:"
echo -e "${BLUE}systemctl status docker${NORMAL}" 