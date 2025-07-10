# Flarum for discuss.holm.chat

This repository contains a one-click installation for Flarum forum software, configured to run at discuss.holm.chat using Docker Compose and Cloudflare Tunnel.

## Features

- Flarum forum software (latest stable version)
- MariaDB database
- Nginx web server
- PHP-FPM
- Cloudflare Tunnel for secure, free hosting
- Docker Compose for easy deployment
- Automatic setup and configuration

## Quick Start

### Prerequisites

- Fedora Linux (or other compatible distribution)
- Root access or sudo privileges
- Git

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/discuss-holm-chat.git
   cd discuss-holm-chat
   ```

2. Edit the `.env` file to set your passwords and email:
   ```bash
   nano .env
   ```

3. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

4. Follow the prompts to authenticate with Cloudflare and create a tunnel.

5. Once complete, your forum will be available at https://discuss.holm.chat

### Accessing Your Forum

After installation, you can access your forum at:
- URL: https://discuss.holm.chat
- Admin panel: https://discuss.holm.chat/admin
- Admin username: admin
- Admin password: [The one you set in .env]

## Management Commands

- Start services: `docker compose up -d`
- Stop services: `docker compose down`
- View logs: `docker compose logs -f`
- Restart services: `docker compose restart`

## Customization

- Flarum configuration: `config/flarum/config.php`
- Nginx configuration: `config/nginx/nginx.conf`
- Cloudflare Tunnel configuration: `config/cloudflared/config.yml`

## Troubleshooting

If you encounter any issues:

1. Check the Docker logs: `docker compose logs -f`
2. Ensure Cloudflare Tunnel is running: `docker compose logs cloudflared`
3. Verify your DNS settings in the Cloudflare dashboard

## License

This project is licensed under the MIT License - see the LICENSE file for details.