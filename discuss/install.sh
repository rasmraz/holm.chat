#!/bin/bash
set -e

# Display banner
echo "=================================================="
echo "  Flarum Installation for discuss.holm.chat"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing Docker..."
  dnf -y install dnf-plugins-core
  dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
  echo "Docker Compose not found. Installing Docker Compose..."
  dnf -y install docker-compose-plugin
fi

# Start Docker if not running
if ! systemctl is-active --quiet docker; then
  echo "Starting Docker service..."
  systemctl start docker
fi

# Add current user to docker group if not already
if ! groups | grep -q docker; then
  echo "Adding current user to docker group..."
  usermod -aG docker $(whoami)
  echo "You may need to log out and back in for this to take effect."
fi

# Check if .env file exists and has been modified
if [ -f .env ] && grep -q "your_secure_db_password" .env; then
  echo "Please update the .env file with your secure passwords and settings before continuing."
  echo "Edit the .env file and run this script again."
  exit 1
fi

# Create directories if they don't exist
mkdir -p src config/flarum/extensions config/flarum/storage

# Download and install Cloudflared
echo "Installing Cloudflared..."
if ! command -v cloudflared &> /dev/null; then
  curl -L --output cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
  dnf -y install ./cloudflared.rpm
  rm cloudflared.rpm
fi

# Check if Cloudflare credentials exist
if [ ! -f config/cloudflared/credentials.json ]; then
  echo "Cloudflare credentials not found. Please authenticate with Cloudflare..."
  
  # Login to Cloudflare
  cloudflared tunnel login
  
  # Create a new tunnel if TUNNEL_ID is not set
  source .env
  if [ -z "$TUNNEL_ID" ] || [ "$TUNNEL_ID" == "your_tunnel_id" ]; then
    echo "Creating a new Cloudflare Tunnel..."
    TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME | grep -oP 'Created tunnel \K[a-z0-9-]+')
    TUNNEL_NAME=$(cloudflared tunnel list | grep $TUNNEL_ID | awk '{print $2}')
    
    # Update .env file with the new tunnel ID
    sed -i "s/TUNNEL_ID=.*/TUNNEL_ID=$TUNNEL_ID/" .env
    sed -i "s/TUNNEL_NAME=.*/TUNNEL_NAME=$TUNNEL_NAME/" .env
    
    # Create DNS record
    echo "Creating DNS record for discuss.holm.chat..."
    cloudflared tunnel route dns $TUNNEL_ID discuss.holm.chat
  fi
  
  # Copy credentials to the config directory
  mkdir -p ~/.cloudflared
  cp ~/.cloudflared/*.json config/cloudflared/credentials.json
fi

# Pull Docker images
echo "Pulling Docker images..."
docker compose pull

# Build and start the containers
echo "Building and starting containers..."
docker compose up -d --build

echo ""
echo "=================================================="
echo "  Installation Complete!"
echo "=================================================="
echo ""
echo "Your Flarum forum is now being set up at: https://discuss.holm.chat"
echo ""
echo "It may take a few minutes for the initial setup to complete."
echo "You can check the logs with: docker compose logs -f"
echo ""
echo "Admin login:"
echo "  Username: admin"
echo "  Password: [The one you set in .env]"
echo ""
echo "To stop the services: docker compose down"
echo "To start the services: docker compose up -d"
echo ""
echo "Enjoy your new Flarum forum!"