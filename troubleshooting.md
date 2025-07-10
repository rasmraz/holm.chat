# Troubleshooting Guide - HOLM.CHAT Flarum Forum

This guide covers common issues you might encounter during or after deployment and their solutions.

## 🚨 Common Deployment Issues

### 1. Permission Denied Errors

**Problem:** Script fails with permission denied errors
```bash
bash: ./deploy-flarum.sh: Permission denied
```

**Solution:**
```bash
# Make script executable
chmod +x deploy-flarum.sh

# Run with sudo
sudo bash deploy-flarum.sh
```

### 2. Package Installation Failures

**Problem:** APT package installation fails
```bash
E: Unable to locate package php8.2
```

**Solution:**
```bash
# Update package lists first
sudo apt update

# Add PHP repository if needed
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update

# Then run the deployment script
sudo bash deploy-flarum.sh
```

### 3. MariaDB Service Won't Start

**Problem:** MariaDB fails to start
```bash
Job for mariadb.service failed
```

**Solution:**
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Try manual start
sudo systemctl start mariadb

# If still failing, check logs
sudo journalctl -u mariadb

# Reset MariaDB if needed
sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

## 🌐 Web Server Issues

### 1. Apache Won't Start

**Problem:** Apache fails to start on port 12000
```bash
Address already in use: AH00072: make_sock: could not bind to address [::]:12000
```

**Solution:**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :12000

# Kill the process if needed
sudo kill -9 <PID>

# Or change the port in deploy-flarum.sh
WEB_PORT="8080"  # Use different port
```

### 2. 403 Forbidden Error

**Problem:** Forum shows "Forbidden" error

**Solution:**
```bash
# Fix file permissions
sudo chown -R www-data:www-data /workspace/flarum
sudo find /workspace/flarum -type d -exec chmod 775 {} \;
sudo find /workspace/flarum -type f -exec chmod 664 {} \;

# Check Apache configuration
sudo apache2ctl configtest

# Restart Apache
sudo service apache2 restart
```

### 3. 500 Internal Server Error

**Problem:** Forum shows HTTP 500 error

**Solution:**
```bash
# Check Apache error logs
sudo tail -f /var/log/apache2/flarum_error.log

# Check Flarum logs
sudo tail -f /workspace/flarum/storage/logs/flarum-*.log

# Common fixes:
# 1. Fix database connection in config.php
# 2. Clear Flarum cache
cd /workspace/flarum && sudo -u www-data php flarum cache:clear

# 3. Check PHP extensions
php -m | grep -E "(mysql|pdo|mbstring|curl|gd|xml)"
```

## 🗄️ Database Issues

### 1. Database Connection Failed

**Problem:** Flarum can't connect to database
```bash
SQLSTATE[HY000] [1698] Access denied for user 'tim'@'localhost'
```

**Solution:**
```bash
# Test database connection manually
mysql -u tim -ppassword123 -e "USE flarum; SHOW TABLES;"

# If fails, recreate user
sudo mysql -u root -e "DROP USER IF EXISTS 'tim'@'localhost';"
sudo mysql -u root -e "CREATE USER 'tim'@'localhost' IDENTIFIED BY 'password123';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON flarum.* TO 'tim'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Update config.php with correct credentials
sudo nano /workspace/flarum/config.php
```

### 2. Database Tables Missing

**Problem:** Database exists but no tables
```bash
Empty set (0.00 sec)
```

**Solution:**
```bash
# Re-run Flarum installation
cd /workspace/flarum

# Create new config file
cat > install-config.json << EOF
{
  "debug": false,
  "database": {
    "driver": "mysql",
    "host": "localhost",
    "port": 3306,
    "database": "flarum",
    "username": "tim",
    "password": "password123",
    "prefix": ""
  },
  "url": "https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev",
  "settings": {
    "forum_title": "HOLM.CHAT"
  },
  "adminUser": {
    "username": "admin",
    "password": "admin123",
    "password_confirmation": "admin123",
    "email": "admin@holm.chat"
  }
}
EOF

# Run installation
sudo -u www-data php flarum install --file=install-config.json
rm install-config.json
```

## 🔧 Configuration Issues

### 1. Wrong Forum URL

**Problem:** Forum redirects to wrong URL or shows broken links

**Solution:**
```bash
# Update URL in database
mysql -u tim -ppassword123 -e "USE flarum; UPDATE settings SET value = 'https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev' WHERE \`key\` = 'base_url';"

# Update config.php
sudo nano /workspace/flarum/config.php
# Change the 'url' value to correct URL

# Clear cache
cd /workspace/flarum && sudo -u www-data php flarum cache:clear
```

### 2. Admin User Can't Login

**Problem:** Admin credentials don't work

**Solution:**
```bash
# Reset admin password
cd /workspace/flarum
sudo -u www-data php flarum user:create --admin

# Or update existing admin
mysql -u tim -ppassword123 -e "USE flarum; UPDATE users SET password = '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' WHERE username = 'admin';"
# This sets password to 'password'
```

## 📁 File System Issues

### 1. Storage Directory Not Writable

**Problem:** Flarum can't write to storage directory
```bash
The stream or file "/workspace/flarum/storage/logs/flarum.log" could not be opened
```

**Solution:**
```bash
# Fix storage permissions
sudo chown -R www-data:www-data /workspace/flarum/storage
sudo chmod -R 775 /workspace/flarum/storage

# Create missing directories
sudo mkdir -p /workspace/flarum/storage/logs
sudo mkdir -p /workspace/flarum/storage/cache
sudo mkdir -p /workspace/flarum/storage/sessions
sudo chown -R www-data:www-data /workspace/flarum/storage
```

### 2. Assets Not Loading

**Problem:** CSS/JS files return 404 errors

**Solution:**
```bash
# Rebuild assets
cd /workspace/flarum
sudo -u www-data php flarum assets:publish

# Check public directory permissions
sudo chown -R www-data:www-data /workspace/flarum/public
sudo chmod -R 755 /workspace/flarum/public
```

## 🔍 Diagnostic Commands

### Check System Status
```bash
# Check all services
sudo service --status-all | grep -E "(apache2|mariadb|mysql)"

# Check ports
sudo netstat -tulpn | grep -E "(80|443|3306|12000)"

# Check PHP
php --version
php -m | grep -E "(mysql|pdo|curl|gd|mbstring)"
```

### Check Flarum Status
```bash
# Check Flarum installation
cd /workspace/flarum
php flarum info

# Check database tables
mysql -u tim -ppassword123 -e "USE flarum; SHOW TABLES;"

# Check admin user
mysql -u tim -ppassword123 -e "USE flarum; SELECT id, username, email FROM users WHERE username = 'admin';"
```

### Check Logs
```bash
# Apache logs
sudo tail -f /var/log/apache2/flarum_error.log
sudo tail -f /var/log/apache2/flarum_access.log

# Flarum logs
sudo tail -f /workspace/flarum/storage/logs/flarum-*.log

# System logs
sudo journalctl -f
```

## 🛠️ Manual Recovery

### Complete Reset
If everything fails, you can start fresh:

```bash
# Stop services
sudo service apache2 stop
sudo service mariadb stop

# Remove installation
sudo rm -rf /workspace/flarum

# Drop database
sudo mysql -u root -e "DROP DATABASE IF EXISTS flarum;"
sudo mysql -u root -e "DROP USER IF EXISTS 'tim'@'localhost';"

# Re-run deployment
sudo bash deploy-flarum.sh
```

### Backup and Restore
```bash
# Backup database
mysqldump -u tim -ppassword123 flarum > flarum_backup.sql

# Backup files
sudo tar -czf flarum_files_backup.tar.gz /workspace/flarum

# Restore database
mysql -u tim -ppassword123 flarum < flarum_backup.sql

# Restore files
sudo tar -xzf flarum_files_backup.tar.gz -C /
```

## 📞 Getting More Help

### Log Analysis
When reporting issues, include:
1. Output from deployment script
2. Apache error logs
3. Flarum logs
4. System information (`uname -a`, `php --version`)

### Useful Resources
- [Flarum Documentation](https://docs.flarum.org/)
- [Flarum Community](https://discuss.flarum.org/)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

### Emergency Contacts
If you need immediate help:
1. Check the GitHub issues for this repository
2. Post in Flarum community forums
3. Review system logs for specific error messages

---

**Remember:** Most issues are related to permissions, database connections, or service configuration. Start with the basics and work your way up!