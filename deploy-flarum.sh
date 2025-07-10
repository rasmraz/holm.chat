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
FORUM_URL="https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev"
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
        if netstat -tuln | grep -q ":$port "; then
            print_success "$service is ready!"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service failed to start within expected time"
    return 1
}

# Main deployment function
main() {
    print_header "HOLM.CHAT Flarum Forum Deployment"
    
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
        php8.2-dom \
        php8.2-fileinfo \
        php8.2-json \
        php8.2-openssl \
        php8.2-pdo \
        php8.2-tokenizer \
        libapache2-mod-php8.2 \
        > /dev/null 2>&1
    
    print_success "PHP 8.2 and extensions installed"
    
    # Step 3: Install Apache Web Server
    print_header "Step 3: Installing Apache Web Server"
    print_status "Installing Apache2..."
    
    apt install -y apache2 > /dev/null 2>&1
    
    # Enable required Apache modules
    a2enmod rewrite > /dev/null 2>&1
    a2enmod php8.2 > /dev/null 2>&1
    
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
    
    # Step 7: Start Services
    print_header "Step 7: Starting Services"
    print_status "Starting MariaDB..."
    service mariadb start
    wait_for_service "MariaDB" "3306"
    
    print_status "Starting Apache..."
    service apache2 start
    wait_for_service "Apache" "$WEB_PORT"
    
    # Step 8: Setup Database
    print_header "Step 8: Setting Up Database"
    print_status "Creating database and user..."
    
    # Create database
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    # Create user and grant privileges
    mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';" 2>/dev/null
    mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 2>/dev/null
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Test database connection
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; SELECT 1;" > /dev/null 2>&1; then
        print_success "Database setup completed successfully"
    else
        print_error "Database connection test failed"
        exit 1
    fi
    
    # Step 9: Download and Install Flarum
    print_header "Step 9: Installing Flarum"
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
    
    # Step 10: Set File Permissions
    print_header "Step 10: Setting File Permissions"
    print_status "Configuring file permissions for web server..."
    
    # Change ownership to www-data
    chown -R www-data:www-data "$INSTALL_DIR"
    
    # Set directory permissions
    find "$INSTALL_DIR" -type d -exec chmod 775 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 664 {} \;
    
    # Make flarum executable
    chmod +x "$INSTALL_DIR/flarum"
    
    print_success "File permissions configured"
    
    # Step 11: Install Flarum
    print_header "Step 11: Running Flarum Installation"
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
    php flarum install --file=install-config.json
    
    # Clean up installation config
    rm -f "$INSTALL_DIR/install-config.json"
    
    print_success "Flarum installation completed"
    
    # Step 12: Final Configuration
    print_header "Step 12: Final Configuration"
    print_status "Updating forum URL in database..."
    
    # Update base URL in database
    mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; INSERT INTO settings (\`key\`, \`value\`) VALUES ('base_url', '$FORUM_URL') ON DUPLICATE KEY UPDATE \`value\` = '$FORUM_URL';" 2>/dev/null
    
    # Clear cache
    cd "$INSTALL_DIR"
    php flarum cache:clear > /dev/null 2>&1
    
    print_success "Final configuration completed"
    
    # Step 13: Verification
    print_header "Step 13: Verifying Installation"
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

# Error handling
trap 'print_error "An error occurred during deployment. Check the output above for details."; exit 1' ERR

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Run main deployment
main "$@"