#!/bin/bash

# HOLM.CHAT Flarum Forum Restore Script
# This script restores a Flarum forum from backup

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Check if backup file provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <backup_file.tar.gz>"
    echo "Available backups:"
    ls -1 /workspace/backups/*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="/workspace/backups"
RESTORE_DIR="/tmp/flarum_restore_$$"
FLARUM_DIR="/workspace/flarum"
DB_NAME="flarum"
DB_USER="tim"
DB_PASSWORD="password123"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

print_status "Starting restore from: $BACKUP_FILE"

# Create temporary restore directory
mkdir -p "$RESTORE_DIR"
cd "$RESTORE_DIR"

# Extract backup
print_status "Extracting backup archive..."
tar -xzf "$BACKUP_FILE"

# Find the backup directory
BACKUP_FOLDER=$(find . -maxdepth 1 -type d -name "flarum_backup_*" | head -1)
if [ -z "$BACKUP_FOLDER" ]; then
    print_error "Invalid backup file format"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

cd "$BACKUP_FOLDER"

# Show backup info
if [ -f "backup_info.txt" ]; then
    print_status "Backup Information:"
    cat backup_info.txt
    echo ""
fi

# Confirm restore
read -p "Do you want to continue with the restore? This will overwrite existing data! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Restore cancelled"
    rm -rf "$RESTORE_DIR"
    exit 0
fi

# Stop services
print_status "Stopping services..."
service apache2 stop 2>/dev/null || true
print_success "Services stopped"

# Backup current installation (just in case)
if [ -d "$FLARUM_DIR" ]; then
    print_status "Creating safety backup of current installation..."
    mv "$FLARUM_DIR" "${FLARUM_DIR}_backup_$(date +%s)" 2>/dev/null || true
fi

# Restore database
if [ -f "database.sql" ]; then
    print_status "Restoring database..."
    
    # Drop and recreate database
    mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    mysql -u root -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    # Import database
    mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < database.sql
    print_success "Database restored"
else
    print_warning "Database backup not found in archive"
fi

# Restore files
if [ -f "flarum_files.tar.gz" ]; then
    print_status "Restoring Flarum files..."
    
    # Extract files to parent directory of target
    tar -xzf flarum_files.tar.gz -C "$(dirname $FLARUM_DIR)"
    print_success "Files restored"
else
    print_error "Flarum files backup not found in archive"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

# Restore Apache configuration
if [ -f "apache_flarum.conf" ]; then
    print_status "Restoring Apache configuration..."
    cp apache_flarum.conf /etc/apache2/sites-available/flarum.conf
    a2ensite flarum.conf > /dev/null 2>&1
    print_success "Apache configuration restored"
fi

# Fix permissions
print_status "Setting file permissions..."
chown -R www-data:www-data "$FLARUM_DIR"
find "$FLARUM_DIR" -type d -exec chmod 775 {} \;
find "$FLARUM_DIR" -type f -exec chmod 664 {} \;
chmod +x "$FLARUM_DIR/flarum"
print_success "Permissions set"

# Clear cache
print_status "Clearing Flarum cache..."
cd "$FLARUM_DIR"
sudo -u www-data php flarum cache:clear > /dev/null 2>&1 || true
print_success "Cache cleared"

# Start services
print_status "Starting services..."
service mariadb start
service apache2 start
print_success "Services started"

# Clean up
rm -rf "$RESTORE_DIR"

# Test installation
print_status "Testing restored installation..."
sleep 3
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:12000" | grep -q "200"; then
    print_success "Forum is accessible and responding"
else
    print_warning "Forum may not be fully accessible yet"
fi

print_success "Restore completed successfully!"
echo -e "${GREEN}Your HOLM.CHAT forum has been restored from backup${NC}"
echo -e "${BLUE}Forum URL: https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev${NC}"
echo -e "${BLUE}Local URL: http://localhost:12000${NC}"