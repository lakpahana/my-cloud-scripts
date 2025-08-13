#!/bin/sh
set -e

# Function to print error messages
error() {
    echo "Error: $1" >&2
    exit 1
}

# Check if script is run as root
if [ "$(id -u)" = 0 ]; then
    error "This script should not be run as root or with sudo"
fi

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed. Version: $(docker --version)"
    read -p "Do you want to proceed with reinstallation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Installing Docker..."

# Add Docker's official GPG key:
sudo apt-get update || error "Failed to update package index"
sudo apt-get install -y ca-certificates curl || error "Failed to install prerequisites"
sudo install -m 0755 -d /etc/apt/keyrings || error "Failed to create keyrings directory"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || error "Failed to download Docker's GPG key"
sudo chmod a+r /etc/apt/keyrings/docker.asc || error "Failed to set permissions on Docker's GPG key"

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update || error "Failed to update package index"

# Install Docker packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose || error "Failed to install Docker packages"

# Add user to docker group
echo "Setting up Docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER || error "Failed to add user to docker group"

# Verify installation
echo "Verifying Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
    error "Docker installation failed. 'docker' command not found"
fi

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker || error "Failed to start Docker service"
sudo systemctl enable docker || error "Failed to enable Docker service"

# Verify Docker is running
echo "Verifying Docker daemon..."
if ! sudo docker run hello-world >/dev/null 2>&1; then
    error "Docker installation verification failed. Could not run test container"
fi

echo "Docker installation completed successfully!"
echo "Note: You need to log out and back in for the docker group changes to take effect."
echo "To verify after logging back in, run: docker run hello-world"