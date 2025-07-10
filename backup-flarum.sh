#!/bin/bash

# HOLM.CHAT Flarum Forum Backup Script
# This script creates a complete backup of your Flarum forum

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/workspace/backups"
FLARUM_DIR="/workspace/flarum"
DB_NAME="flarum"
DB_USER="tim"
DB_PASSWORD="password123"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="flarum_backup_$TIMESTAMP"

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

# Create backup directory
print_status "Creating backup directory..."
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup database
print_status "Backing up database..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/$BACKUP_NAME/database.sql"
print_success "Database backup completed"

# Backup Flarum files
print_status "Backing up Flarum files..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME/flarum_files.tar.gz" -C "$(dirname $FLARUM_DIR)" "$(basename $FLARUM_DIR)"
print_success "Files backup completed"

# Backup Apache configuration
print_status "Backing up Apache configuration..."
cp /etc/apache2/sites-available/flarum.conf "$BACKUP_DIR/$BACKUP_NAME/apache_flarum.conf" 2>/dev/null || print_warning "Apache config not found"

# Create backup info file
cat > "$BACKUP_DIR/$BACKUP_NAME/backup_info.txt" << EOF
HOLM.CHAT Flarum Backup Information
===================================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Flarum Directory: $FLARUM_DIR
Database Name: $DB_NAME
Database User: $DB_USER

Files Included:
- database.sql (Complete database dump)
- flarum_files.tar.gz (All Flarum files and directories)
- apache_flarum.conf (Apache virtual host configuration)
- backup_info.txt (This file)

Restore Instructions:
1. Extract flarum_files.tar.gz to desired location
2. Import database.sql to MySQL/MariaDB
3. Copy apache_flarum.conf to Apache sites-available
4. Update file permissions and restart services
EOF

# Create compressed backup
print_status "Creating compressed backup archive..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

print_success "Backup completed successfully!"
echo -e "${GREEN}Backup saved to: $BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"

# Show backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${BLUE}Backup size: $BACKUP_SIZE${NC}"

# List all backups
echo -e "\n${BLUE}Available backups:${NC}"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No previous backups found"