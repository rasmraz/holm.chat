# HOLM.CHAT - Flarum Forum Deployment

🚀 **One-Command Flarum Forum Deployment**

This repository contains everything needed to deploy a complete Flarum forum with a single command. The deployment script automatically installs and configures all dependencies, sets up the database, and gets your forum running.

## 🎯 Quick Start

**Run this single command to deploy everything:**

```bash
sudo bash deploy-flarum.sh
```

That's it! The script will handle everything automatically.

## 📋 What Gets Installed

The deployment script automatically installs and configures:

- ✅ **PHP 8.2** with all required extensions
- ✅ **Apache Web Server** with optimized configuration
- ✅ **MariaDB Database** with proper setup
- ✅ **Composer** for dependency management
- ✅ **Flarum Forum** latest stable version
- ✅ **All Dependencies** and configurations
- ✅ **Security Settings** and optimizations
- ✅ **File Permissions** properly configured

## 🔧 Default Configuration

### Forum Settings
- **Forum Title:** HOLM.CHAT
- **Forum URL:** https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev
- **Local Access:** http://localhost:12000

### Admin Account
- **Username:** admin
- **Email:** admin@holm.chat
- **Password:** admin123

### Database Settings
- **Database Name:** flarum
- **Database User:** tim
- **Database Password:** password123
- **Host:** localhost
- **Port:** 3306

## 📁 Repository Structure

```
holm.chat/
├── deploy-flarum.sh          # Main deployment script (RUN THIS!)
├── apache-flarum.conf        # Apache virtual host configuration
├── setup-database.sql        # Database setup script
├── flarum-config.json        # Flarum installation configuration
├── php-flarum.ini           # Optimized PHP settings
├── troubleshooting.md       # Common issues and solutions
└── README.md               # This file
```

## 🚀 Deployment Process

The `deploy-flarum.sh` script performs these steps automatically:

1. **System Update** - Updates package lists
2. **PHP Installation** - Installs PHP 8.2 with all required extensions
3. **Apache Setup** - Installs and configures Apache web server
4. **MariaDB Installation** - Sets up database server
5. **Composer Installation** - Installs PHP dependency manager
6. **Apache Configuration** - Creates virtual host and enables modules
7. **Service Startup** - Starts MariaDB and Apache services
8. **Database Setup** - Creates database and user with proper permissions
9. **Flarum Download** - Clones Flarum from official repository
10. **Dependency Installation** - Installs all Flarum dependencies
11. **File Permissions** - Sets proper ownership and permissions
12. **Flarum Installation** - Runs Flarum installer with configuration
13. **Final Configuration** - Updates settings and clears cache
14. **Verification** - Tests installation and reports status

## 🔧 Customization

### Changing Configuration

Edit these variables in `deploy-flarum.sh` before running:

```bash
FORUM_TITLE="Your Forum Name"
FORUM_URL="https://your-domain.com"
ADMIN_USERNAME="youradmin"
ADMIN_EMAIL="admin@yourdomain.com"
ADMIN_PASSWORD="yourpassword"
DB_NAME="your_db_name"
DB_USER="your_db_user"
DB_PASSWORD="your_db_password"
WEB_PORT="80"  # or your preferred port
```

### Custom Installation Directory

Change the installation path:

```bash
INSTALL_DIR="/your/custom/path"
```

## 🌐 Accessing Your Forum

After successful deployment:

1. **Visit your forum:** https://work-1-djthutkapmvgbdld.prod-runtime.all-hands.dev
2. **Login as admin** using the credentials above
3. **Access admin panel** by clicking the admin button after login
4. **Customize your forum** through the admin interface

## 🛠️ Manual Configuration

If you need to manually configure anything, here are the key files:

### Apache Configuration
```bash
/etc/apache2/sites-available/flarum.conf
```

### Flarum Configuration
```bash
/workspace/flarum/config.php
```

### PHP Configuration
```bash
/etc/php/8.2/apache2/php.ini
```

## 🔍 Troubleshooting

### Common Issues

**Forum shows 500 error:**
```bash
# Check Apache error logs
tail -f /var/log/apache2/flarum_error.log

# Check Flarum logs
tail -f /workspace/flarum/storage/logs/flarum-*.log
```

**Database connection issues:**
```bash
# Test database connection
mysql -u tim -ppassword123 -e "USE flarum; SHOW TABLES;"
```

**Permission issues:**
```bash
# Fix file permissions
sudo chown -R www-data:www-data /workspace/flarum
sudo find /workspace/flarum -type d -exec chmod 775 {} \;
sudo find /workspace/flarum -type f -exec chmod 664 {} \;
```

**Service not running:**
```bash
# Restart services
sudo service apache2 restart
sudo service mariadb restart
```

### Getting Help

1. Check the `troubleshooting.md` file for detailed solutions
2. Review the deployment script output for error messages
3. Check system logs: `/var/log/apache2/` and `/var/log/mysql/`
4. Verify all services are running: `sudo service --status-all`

## 📊 System Requirements

- **OS:** Ubuntu/Debian Linux
- **RAM:** Minimum 1GB, recommended 2GB+
- **Storage:** Minimum 2GB free space
- **Network:** Internet connection for downloading packages
- **Privileges:** Root/sudo access required

## 🔒 Security Notes

The default configuration includes:

- ✅ Secure database user with limited privileges
- ✅ Apache security headers configured
- ✅ PHP security settings optimized
- ✅ File permissions properly restricted
- ✅ Server signature disabled

**Important:** Change default passwords in production!

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For issues and questions:

1. Check the troubleshooting guide
2. Review Flarum documentation: https://docs.flarum.org/
3. Open an issue in this repository

---

**Made with ❤️ for the HOLM.CHAT community**