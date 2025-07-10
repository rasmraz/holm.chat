#!/bin/bash

# HOLM.CHAT Flarum Forum Deployment Script
# This script deploys a complete Flarum forum with all dependencies
# Author: OpenHands AI Assistant
# Date: 2025-07-10

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables
FORUM_TITLE="HOLM.CHAT"
USE_CLOUDFLARE_TUNNEL=false
CLOUDFLARE_TUNNEL_NAME="holm-chat-forum"
CLOUDFLARE_CONFIG_DIR="/workspace/holm.chat/.cloudflare"

# Check for cloudflare tunnel flag
if [ "$1" = "--cloudflare" ] || [ "$2" = "--cloudflare" ]; then
    USE_CLOUDFLARE_TUNNEL=true
    shift # Remove the --cloudflare flag from arguments
fi

# Auto-detect the forum URL or use provided argument
if [ "$USE_CLOUDFLARE_TUNNEL" = true ]; then
    FORUM_URL="" # Will be set after tunnel creation
elif [ -n "$1" ]; then
    FORUM_URL="$1"
elif [ -f "/tmp/oh-server-url" ]; then
    # Try to read from OpenHands server URL file
    FORUM_URL=$(cat /tmp/oh-server-url 2>/dev/null || echo "")
    if [ -z "$FORUM_URL" ]; then
        # Fallback: try to detect from environment or use localhost
        FORUM_URL="http://localhost:12000"
    fi
else
    # Default fallback
    FORUM_URL="http://localhost:12000"
fi

ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@holm.chat"
ADMIN_PASSWORD="admin123"
DB_NAME="flarum"
DB_USER="tim"
DB_PASSWORD="password123"
WEB_PORT="12000"
INSTALL_DIR="/workspace/flarum"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if ss -tuln | grep -q ":$port " || lsof -i :$port >/dev/null 2>&1; then
            print_success "$service is ready!"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service failed to start within expected time"
    return 1
}

# Function to install Cloudflare Tunnel (cloudflared)
install_cloudflared() {
    print_header "Installing Cloudflare Tunnel (cloudflared)"
    
    # Check if already installed
    if command -v cloudflared >/dev/null 2>&1; then
        print_success "cloudflared is already installed"
        return 0
    fi
    
    print_status "Downloading and installing cloudflared..."
    
    # Download cloudflared
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    
    # Install the package
    dpkg -i cloudflared-linux-amd64.deb || apt-get install -f -y
    
    # Clean up
    rm -f cloudflared-linux-amd64.deb
    
    # Verify installation
    if command -v cloudflared >/dev/null 2>&1; then
        print_success "cloudflared installed successfully"
        cloudflared --version
    else
        print_error "Failed to install cloudflared"
        return 1
    fi
}

# Function to setup Cloudflare Tunnel
setup_cloudflare_tunnel() {
    print_header "Setting up Cloudflare Tunnel"
    
    # Create config directory
    mkdir -p "$CLOUDFLARE_CONFIG_DIR"
    
    # Check if tunnel already exists
    if [ -f "$CLOUDFLARE_CONFIG_DIR/tunnel.json" ]; then
        print_status "Using existing tunnel configuration..."
        TUNNEL_ID=$(cat "$CLOUDFLARE_CONFIG_DIR/tunnel.json" | grep -o '"TunnelID":"[^"]*"' | cut -d'"' -f4)
        TUNNEL_URL=$(cat "$CLOUDFLARE_CONFIG_DIR/tunnel.json" | grep -o '"URL":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$TUNNEL_URL" ]; then
            FORUM_URL="$TUNNEL_URL"
            print_success "Using existing tunnel URL: $FORUM_URL"
            return 0
        fi
    fi
    
    print_status "Creating new Cloudflare Tunnel..."
    
    # For demo purposes, create a quick tunnel without authentication
    # This creates a temporary tunnel that works immediately
    print_status "Starting quick tunnel (no authentication required)..."
    
    # Start cloudflared tunnel in background
    cloudflared tunnel --url http://localhost:12000 > /tmp/tunnel.log 2>&1 &
    TUNNEL_PID=$!
    
    # Wait for tunnel to start and extract URL
    sleep 10
    
    # Extract tunnel URL from logs
    if [ -f /tmp/tunnel.log ]; then
        TUNNEL_URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' /tmp/tunnel.log | head -1)
    fi
    
    if [ -n "$TUNNEL_URL" ]; then
        FORUM_URL="$TUNNEL_URL"
        print_success "Cloudflare Tunnel URL: $FORUM_URL"
        
        # Save tunnel info
        cat > "$CLOUDFLARE_CONFIG_DIR/tunnel.json" << EOF
{
    "TunnelID": "quick-tunnel",
    "TunnelName": "$CLOUDFLARE_TUNNEL_NAME",
    "URL": "$TUNNEL_URL",
    "PID": $TUNNEL_PID,
    "Type": "quick"
}
EOF
        
        print_status "Tunnel is running in background (PID: $TUNNEL_PID)"
        return 0
    else
        print_error "Failed to create Cloudflare tunnel"
        print_status "Check /tmp/tunnel.log for details"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh${NC}                                    # Auto-detect URL"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh <URL>${NC}                              # Use specific URL"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh --cloudflare${NC}                       # Use Cloudflare Tunnel"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh --cloudflare <URL>${NC}                 # Use Cloudflare + custom URL"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh --update-url <URL>${NC}                 # Update existing installation URL"
    echo -e "  ${GREEN}bash deploy-flarum.sh --help${NC}                                  # Show this help"
    echo -e ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh${NC}"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh https://your-domain.com${NC}"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh --cloudflare${NC}                       # Get free public URL!"
    echo -e "  ${GREEN}sudo bash deploy-flarum.sh --update-url https://new-domain.com${NC}"
    echo -e ""
    echo -e "${YELLOW}🌟 Use --cloudflare for a free public URL via Cloudflare Tunnel!${NC}"
    echo -e "${YELLOW}Note: If no URL is provided, the script will try to auto-detect or use localhost:12000${NC}"
    echo ""
}

# Main deployment function
main() {
    print_header "HOLM.CHAT Flarum Forum Deployment"
    
    # Setup Cloudflare Tunnel if requested
    if [ "$USE_CLOUDFLARE_TUNNEL" = true ]; then
        install_cloudflared
        setup_cloudflare_tunnel
    fi
    
    # Show the URL being used
    print_status "Forum URL: $FORUM_URL"
    
    # Step 1: Update system packages
    print_header "Step 1: Updating System Packages"
    print_status "Updating package lists..."
    apt update -qq
    print_success "Package lists updated"
    
    # Step 2: Install PHP 8.2 and required extensions
    print_header "Step 2: Installing PHP 8.2 and Extensions"
    print_status "Installing PHP 8.2 with required extensions..."
    
    apt install -y \
        php8.2 \
        php8.2-cli \
        php8.2-common \
        php8.2-curl \
        php8.2-gd \
        php8.2-intl \
        php8.2-mbstring \
        php8.2-mysql \
        php8.2-sqlite3 \
        php8.2-xml \
        php8.2-zip \
        libapache2-mod-php8.2
    
    print_success "PHP 8.2 and extensions installed"
    
    # Step 3: Install Apache Web Server
    print_header "Step 3: Installing Apache Web Server"
    print_status "Installing Apache2..."
    
    apt install -y apache2 > /dev/null 2>&1
    
    # Enable required Apache modules
    a2enmod rewrite > /dev/null 2>&1
    a2enmod php8.2 > /dev/null 2>&1
    a2enmod headers > /dev/null 2>&1
    
    print_success "Apache2 installed and configured"
    
    # Step 4: Install MariaDB
    print_header "Step 4: Installing MariaDB Database Server"
    print_status "Installing MariaDB..."
    
    DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server mariadb-client > /dev/null 2>&1
    
    print_success "MariaDB installed"
    
    # Step 5: Install Composer
    print_header "Step 5: Installing Composer"
    print_status "Downloading and installing Composer..."
    
    if ! command_exists composer; then
        curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
    fi
    
    print_success "Composer installed"
    
    # Step 6: Configure Apache
    print_header "Step 6: Configuring Apache Web Server"
    print_status "Setting up Apache virtual host..."
    
    # Add port configuration
    if ! grep -q "Listen $WEB_PORT" /etc/apache2/ports.conf; then
        echo "Listen $WEB_PORT" >> /etc/apache2/ports.conf
    fi
    
    # Create virtual host configuration
    cat > /etc/apache2/sites-available/flarum.conf << EOF
<VirtualHost *:$WEB_PORT>
    DocumentRoot $INSTALL_DIR/public
    
    <Directory $INSTALL_DIR/public>
        AllowOverride All
        Require all granted
        
        # Enable URL rewriting
        RewriteEngine On
        
        # Handle Angular HTML5 mode
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.php [L]
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # Logging
    ErrorLog \${APACHE_LOG_DIR}/flarum_error.log
    CustomLog \${APACHE_LOG_DIR}/flarum_access.log combined
</VirtualHost>
EOF
    
    # Enable the site and disable default
    a2ensite flarum.conf > /dev/null 2>&1
    a2dissite 000-default > /dev/null 2>&1
    
    print_success "Apache virtual host configured"
    
    # Step 7: Create Installation Directory
    print_header "Step 7: Creating Installation Directory"
    print_status "Creating Flarum installation directory..."
    
    # Create installation directory structure
    mkdir -p "$INSTALL_DIR/public"
    chown -R www-data:www-data "$INSTALL_DIR"
    
    print_success "Installation directory created"
    
    # Step 8: Start Services
    print_header "Step 8: Starting Services"
    print_status "Starting MariaDB..."
    service mariadb start
    wait_for_service "MariaDB" "3306"
    
    print_status "Starting Apache..."
    service apache2 start
    wait_for_service "Apache" "$WEB_PORT"
    
    # Step 9: Setup Database
    print_header "Step 9: Setting Up Database"
    print_status "Creating database and user..."
    
    # Set root password to empty for easier access during installation
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Drop and recreate database to ensure clean installation
    mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null
    mysql -u root -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    # Create user and grant privileges
    mysql -u root -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" 2>/dev/null || true
    mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';" 2>/dev/null
    mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 2>/dev/null
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost';" 2>/dev/null
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Test database connection
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; SELECT 1;" > /dev/null 2>&1; then
        print_success "Database setup completed successfully"
    else
        print_error "Database connection test failed"
        exit 1
    fi
    
    # Step 10: Download and Install Flarum
    print_header "Step 10: Installing Flarum"
    print_status "Cloning Flarum from GitHub..."
    
    # Remove existing installation if present
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone Flarum
    git clone https://github.com/flarum/flarum.git "$INSTALL_DIR" > /dev/null 2>&1
    cd "$INSTALL_DIR"
    
    print_status "Installing Flarum dependencies..."
    composer install --no-dev --optimize-autoloader > /dev/null 2>&1
    
    print_success "Flarum source code and dependencies installed"
    
    # Step 11: Set File Permissions
    print_header "Step 11: Setting File Permissions"
    print_status "Configuring file permissions for web server..."
    
    # Change ownership to www-data
    chown -R www-data:www-data "$INSTALL_DIR"
    
    # Set directory permissions
    find "$INSTALL_DIR" -type d -exec chmod 775 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 664 {} \;
    
    # Make flarum executable
    chmod +x "$INSTALL_DIR/flarum"
    
    print_success "File permissions configured"
    
    # Step 12: Install Flarum
    print_header "Step 12: Running Flarum Installation"
    print_status "Creating Flarum installation configuration..."
    
    # Create installation configuration
    cat > "$INSTALL_DIR/install-config.json" << EOF
{
  "debug": false,
  "database": {
    "driver": "mysql",
    "host": "localhost",
    "port": 3306,
    "database": "$DB_NAME",
    "username": "$DB_USER",
    "password": "$DB_PASSWORD",
    "prefix": ""
  },
  "url": "$FORUM_URL",
  "settings": {
    "forum_title": "$FORUM_TITLE"
  },
  "adminUser": {
    "username": "$ADMIN_USERNAME",
    "password": "$ADMIN_PASSWORD",
    "password_confirmation": "$ADMIN_PASSWORD",
    "email": "$ADMIN_EMAIL"
  }
}
EOF
    
    print_status "Running Flarum installation..."
    cd "$INSTALL_DIR"
    
    # Set proper ownership before installation
    chown -R www-data:www-data "$INSTALL_DIR"
    
    # Run installation as www-data user
    sudo -u www-data php flarum install --file=install-config.json
    
    # Clean up installation config
    rm -f "$INSTALL_DIR/install-config.json"
    
    # Fix config.php with correct database credentials and URL
    print_status "Updating configuration file..."
    cat > "$INSTALL_DIR/config.php" << EOF
<?php return array (
  'debug' => false,
  'database' => 
  array (
    'driver' => 'mysql',
    'database' => '$DB_NAME',
    'prefix' => '',
    'prefix_indexes' => true,
    'host' => 'localhost',
    'port' => 3306,
    'username' => '$DB_USER',
    'password' => '$DB_PASSWORD',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'engine' => 'InnoDB',
    'strict' => false,
  ),
  'url' => '$FORUM_URL',
  'paths' => 
  array (
    'api' => 'api',
    'admin' => 'admin',
  ),
  'headers' => 
  array (
    'poweredByHeader' => true,
    'referrerPolicy' => 'same-origin',
  ),
);
EOF
    
    # Set proper ownership for config file
    chown www-data:www-data "$INSTALL_DIR/config.php"
    chmod 644 "$INSTALL_DIR/config.php"
    
    print_success "Flarum installation completed"
    
    # Step 13: Final Configuration
    print_header "Step 13: Final Configuration"
    print_status "Updating forum URL in database..."
    
    # Update base URL in database
    mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; INSERT INTO settings (\`key\`, \`value\`) VALUES ('base_url', '$FORUM_URL') ON DUPLICATE KEY UPDATE \`value\` = '$FORUM_URL';" 2>/dev/null
    
    # Clear cache and set proper permissions
    cd "$INSTALL_DIR"
    sudo -u www-data php flarum cache:clear > /dev/null 2>&1
    
    # Ensure storage directory is writable
    chmod -R 775 "$INSTALL_DIR/storage"
    chown -R www-data:www-data "$INSTALL_DIR/storage"
    
    # Ensure public/assets is writable
    chmod -R 775 "$INSTALL_DIR/public/assets"
    chown -R www-data:www-data "$INSTALL_DIR/public/assets"
    
    # Restart Apache to ensure all changes take effect
    service apache2 restart || service apache2 start
    sleep 3
    
    print_success "Final configuration completed"
    
    # Step 14: Verification
    print_header "Step 14: Verifying Installation"
    print_status "Testing forum accessibility..."
    
    # Test HTTP response
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WEB_PORT" | grep -q "200"; then
        print_success "Forum is accessible and responding correctly"
    else
        print_warning "Forum may not be fully accessible yet, but installation completed"
    fi
    
    # Verify database tables
    table_count=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null | wc -l)
    if [ "$table_count" -gt 20 ]; then
        print_success "Database tables created successfully ($((table_count-1)) tables)"
    else
        print_warning "Database may not be fully populated"
    fi
    
    # Final Success Message
    print_header "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
    
    echo -e "${GREEN}Your HOLM.CHAT Flarum forum is now ready!${NC}\n"
    
    echo -e "${BLUE}📋 ACCESS INFORMATION:${NC}"
    echo -e "   🌐 Forum URL: ${GREEN}$FORUM_URL${NC}"
    echo -e "   🌐 Local URL: ${GREEN}http://localhost:$WEB_PORT${NC}"
    echo ""
    
    echo -e "${BLUE}👤 ADMIN LOGIN:${NC}"
    echo -e "   👤 Username: ${GREEN}$ADMIN_USERNAME${NC}"
    echo -e "   📧 Email: ${GREEN}$ADMIN_EMAIL${NC}"
    echo -e "   🔑 Password: ${GREEN}$ADMIN_PASSWORD${NC}"
    echo ""
    
    echo -e "${BLUE}🗄️ DATABASE INFO:${NC}"
    echo -e "   🗄️ Database: ${GREEN}$DB_NAME${NC}"
    echo -e "   👤 User: ${GREEN}$DB_USER${NC}"
    echo -e "   🔑 Password: ${GREEN}$DB_PASSWORD${NC}"
    echo -e "   🏠 Host: ${GREEN}localhost${NC}"
    echo ""
    
    echo -e "${BLUE}📁 INSTALLATION PATH:${NC}"
    echo -e "   📁 Flarum: ${GREEN}$INSTALL_DIR${NC}"
    echo -e "   🌐 Web Root: ${GREEN}$INSTALL_DIR/public${NC}"
    echo ""
    
    echo -e "${YELLOW}🚀 NEXT STEPS:${NC}"
    echo -e "   1. Visit the forum URL above"
    echo -e "   2. Login with the admin credentials"
    echo -e "   3. Customize your forum through the admin panel"
    echo -e "   4. Start creating discussions and inviting users!"
    echo ""
    
    print_success "Deployment script completed successfully!"
}

# Function to update URL of existing installation
update_url() {
    local new_url="$1"
    
    if [ -z "$new_url" ]; then
        print_error "Please provide a URL to update to"
        echo "Usage: sudo bash deploy-flarum.sh --update-url <NEW_URL>"
        exit 1
    fi
    
    if [ ! -f "$INSTALL_DIR/config.php" ]; then
        print_error "Flarum installation not found at $INSTALL_DIR"
        exit 1
    fi
    
    print_header "Updating Flarum URL"
    print_status "Updating URL from existing installation to: $new_url"
    
    # Update config.php
    sed -i "s|'url' => '.*'|'url' => '$new_url'|g" "$INSTALL_DIR/config.php"
    
    # Update database
    mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; UPDATE settings SET \`value\` = '$new_url' WHERE \`key\` = 'base_url';" 2>/dev/null
    
    # Clear cache
    cd "$INSTALL_DIR"
    sudo -u www-data php flarum cache:clear > /dev/null 2>&1 || true
    
    # Restart Apache
    service apache2 restart > /dev/null 2>&1 || service apache2 start > /dev/null 2>&1
    
    print_success "URL updated successfully!"
    print_status "New forum URL: $new_url"
}

# Error handling
trap 'print_error "An error occurred during deployment. Check the output above for details."; exit 1' ERR

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Check for update URL flag
if [ "$1" = "--update-url" ]; then
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        echo ""
        show_usage
        exit 1
    fi
    update_url "$2"
    exit 0
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    echo ""
    show_usage
    exit 1
fi

# Run main deployment
main "$@"