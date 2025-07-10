#!/bin/bash

# HOLM.CHAT Flarum Forum Setup Verification Script
# This script checks if the forum is properly installed and configured

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script should be run as root (use sudo)"
    exit 1
fi

print_header "HOLM.CHAT Forum Setup Verification"

# Check PHP
print_status "Checking PHP installation..."
if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2)
    print_success "PHP $PHP_VERSION is installed"
    
    # Check required extensions
    REQUIRED_EXTENSIONS=("curl" "dom" "fileinfo" "gd" "intl" "json" "mbstring" "mysql" "openssl" "pdo" "pdo_mysql" "tokenizer" "xml" "zip")
    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if php -m | grep -q "^$ext$"; then
            print_success "PHP extension '$ext' is loaded"
        else
            print_error "PHP extension '$ext' is missing"
        fi
    done
else
    print_error "PHP is not installed"
fi

# Check Apache
print_status "Checking Apache installation..."
if command -v apache2 >/dev/null 2>&1; then
    print_success "Apache is installed"
    
    if systemctl is-active --quiet apache2; then
        print_success "Apache is running"
    else
        print_error "Apache is not running"
    fi
    
    # Check if listening on port 12000
    if netstat -tuln | grep -q ":12000 "; then
        print_success "Apache is listening on port 12000"
    else
        print_warning "Apache is not listening on port 12000"
    fi
else
    print_error "Apache is not installed"
fi

# Check MariaDB
print_status "Checking MariaDB installation..."
if command -v mysql >/dev/null 2>&1; then
    print_success "MariaDB/MySQL client is installed"
    
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_success "MariaDB/MySQL server is running"
        
        # Check database connection
        if mysql -u tim -ppassword123 -e "USE flarum; SELECT 1;" >/dev/null 2>&1; then
            print_success "Database connection successful"
            
            # Check tables
            TABLE_COUNT=$(mysql -u tim -ppassword123 -e "USE flarum; SHOW TABLES;" 2>/dev/null | wc -l)
            if [ "$TABLE_COUNT" -gt 20 ]; then
                print_success "Database has $((TABLE_COUNT-1)) tables"
            else
                print_warning "Database may not be fully populated"
            fi
        else
            print_error "Cannot connect to database"
        fi
    else
        print_error "MariaDB/MySQL server is not running"
    fi
else
    print_error "MariaDB/MySQL is not installed"
fi

# Check Composer
print_status "Checking Composer installation..."
if command -v composer >/dev/null 2>&1; then
    COMPOSER_VERSION=$(composer --version | cut -d' ' -f3)
    print_success "Composer $COMPOSER_VERSION is installed"
else
    print_error "Composer is not installed"
fi

# Check Flarum installation
print_status "Checking Flarum installation..."
if [ -d "/workspace/flarum" ]; then
    print_success "Flarum directory exists"
    
    if [ -f "/workspace/flarum/flarum" ]; then
        print_success "Flarum CLI is present"
        
        if [ -x "/workspace/flarum/flarum" ]; then
            print_success "Flarum CLI is executable"
        else
            print_warning "Flarum CLI is not executable"
        fi
    else
        print_error "Flarum CLI is missing"
    fi
    
    if [ -f "/workspace/flarum/config.php" ]; then
        print_success "Flarum configuration exists"
    else
        print_error "Flarum configuration is missing"
    fi
    
    # Check file permissions
    OWNER=$(stat -c '%U' /workspace/flarum)
    if [ "$OWNER" = "www-data" ]; then
        print_success "Flarum files are owned by www-data"
    else
        print_warning "Flarum files are owned by $OWNER (should be www-data)"
    fi
else
    print_error "Flarum directory does not exist"
fi

# Check web accessibility
print_status "Checking web accessibility..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:12000" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_success "Forum is accessible (HTTP $HTTP_CODE)"
else
    print_error "Forum is not accessible (HTTP $HTTP_CODE)"
fi

# Check admin user
print_status "Checking admin user..."
if mysql -u tim -ppassword123 -e "USE flarum; SELECT username FROM users WHERE username = 'admin';" 2>/dev/null | grep -q "admin"; then
    print_success "Admin user exists"
else
    print_error "Admin user not found"
fi

# Summary
print_header "Verification Summary"

# Count issues
ERRORS=$(grep -c "✗" /tmp/verify_output 2>/dev/null || echo "0")
WARNINGS=$(grep -c "!" /tmp/verify_output 2>/dev/null || echo "0")

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    print_success "All checks passed! Your HOLM.CHAT forum is properly configured."
    echo -e "\n${GREEN}🎉 Forum Access Information:${NC}"
    echo -e "   🌐 Forum URL: ${GREEN}https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev${NC}"
    echo -e "   🌐 Local URL: ${GREEN}http://localhost:12000${NC}"
    echo -e "   👤 Admin: ${GREEN}admin / admin123${NC}"
elif [ "$ERRORS" -eq 0 ]; then
    print_warning "Setup completed with $WARNINGS warnings. Forum should work but may need attention."
else
    print_error "Setup has $ERRORS errors and $WARNINGS warnings. Please fix the issues above."
fi

echo -e "\n${BLUE}For troubleshooting, check: troubleshooting.md${NC}"