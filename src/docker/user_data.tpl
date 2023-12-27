#!/bin/bash
set -euo pipefail

# Define the log file and function for logging
log_file="/var/log/terraform-tbot.log"

function log {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

EIP_ADDRESS=$(curl -m 10 http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$EIP_ADDRESS" ]; then
    log "Failed to retrieve public IP address."
    exit 1
fi
log "Public IP Address: $EIP_ADDRESS"

# Start the script
log "Starting the script."

# Check for internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    log "Internet connection failed. Please check your network."
    exit 1
fi
log "Internet connection verified."

# Update and install necessary packages
log "Updating and installing necessary packages..."
sudo apt-get update -y && sudo apt-get install -y ca-certificates curl gnupg lsb-release net-tools || {
  log "Failed to install necessary packages."
  exit 1
}

# Add Docker's official GPG key
log "Adding Docker's official GPG key..."
if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    log "Failed to add Docker GPG key."
    exit 1
fi

# Set up the repository
log "Setting up the Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
log "Installing Docker Engine..."
if ! sudo apt-get update -y || ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io; then
    log "Failed to install Docker."
    exit 1
fi

# Check if 'docker' group exists and add it if it doesn't
if ! getent group docker > /dev/null; then
  sudo groupadd docker
fi

# Add the user 'ubuntu' to the 'docker' group
log "Adding the user 'ubuntu' to the 'docker' group..."
sudo usermod -aG docker ubuntu

# Install Docker Compose
log "Installing Docker Compose..."
if ! sudo curl -SL "https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose || ! sudo chmod +x /usr/local/bin/docker-compose; then
    log "Failed to install Docker Compose."
    exit 1
fi

# Verify installation
log "Verifying Docker Compose installation..."
if ! docker-compose --version; then
    log "Docker Compose verification failed."
    exit 1
fi

# Fetch the instance's public IP (Elastic IP if associated)
log "Fetching the instance's public IP..."
EIP_ADDRESS=$(curl -m 10 http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$EIP_ADDRESS" ]; then
    log "Failed to retrieve public IP address."
    exit 1
fi
log "Public IP Address: $EIP_ADDRESS"

# Modify the PS1 variable to include the public IP address
echo "export PS1=\"\\u@\\h ($EIP_ADDRESS) \\W\\\\$ \"" | tee -a /home/ubuntu/.bashrc

log "PS1 prompt changed to include the public IP address."

# Set the TBOT_DOCKER_BRANCH variable to 'master' by default
TBOT_DOCKER_BRANCH="${TBOT_DOCKER_BRANCH:-master}"

# Clone the required repositories
log "Cloning required repositories..."
if ! mkdir -p /home/ubuntu/develop/github || \
   ! git clone -b "$TBOT_DOCKER_BRANCH" https://github.com/PlusGenie/ib-gateway-docker /home/ubuntu/develop/github/ib-gateway-docker; then
    log "Failed to clone one or more repositories."
    exit 1
fi

# Copy and configure dotenv file
log "Copying and configuring dotenv file..."
if ! cp /home/ubuntu/develop/github/ib-gateway-docker/stable/tbot/dotenv /home/ubuntu/develop/github/ib-gateway-docker/.env; then
    log "Failed to copy dotenv file."
    exit 1
fi

log "Replacing variables in dotenv..."
# Replace variables in dotenv
if ! sed -i "s|^TWS_USERID=.*$|TWS_USERID=${TWS_USERID}|" /home/ubuntu/develop/github/ib-gateway-docker/.env || \
   ! sed -i "s|^TWS_PASSWORD=.*$|TWS_PASSWORD=${TWS_PASSWORD}|" /home/ubuntu/develop/github/ib-gateway-docker/.env || \
   ! sed -i "s|^TBOT_IBKR_IPADDR=.*$|TBOT_IBKR_IPADDR=${TBOT_IBKR_IPADDR}|" /home/ubuntu/develop/github/ib-gateway-docker/.env || \
   ! sed -i "s|^NGROK_AUTH=.*$|NGROK_AUTH=${NGROK_AUTH}|" /home/ubuntu/develop/github/ib-gateway-docker/.env; then
    log "Failed to replace variables in dotenv."
    exit 1
fi

# Replace TBOT_NGROK with the public IP
if ! sed -i "s|^TBOT_NGROK=.*$|TBOT_NGROK=http://$EIP_ADDRESS:4040|" /home/ubuntu/develop/github/ib-gateway-docker/.env; then
    log "Failed to set TBOT_NGROK in dotenv."
    exit 1
fi

# Building Docker Images
log "Building Docker images using Docker Compose..."
if ! cd /home/ubuntu/develop/github/ib-gateway-docker || ! docker-compose build; then
    log "Failed to build Docker images with Docker Compose."
    exit 1
fi
log "Docker images built successfully."

# Starting up Docker Containers
log "Starting up Docker containers using Docker Compose..."
if ! docker-compose up -d; then
    log "Failed to start Docker containers with Docker Compose."
    exit 1
fi
log "Docker containers started successfully."

# Change the ownership of all files in the cloned repositories to 'ubuntu' user
log "Changing ownership of files to 'ubuntu' user..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/develop || {
    log "Failed to change file ownership to 'ubuntu' user."
    exit 1
}

log "Script completed successfully."
