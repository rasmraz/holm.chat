# 🌐 Cloudflare Tunnel Setup for HOLM.CHAT

This guide explains how to use Cloudflare Tunnels to get a **free public URL** for your HOLM.CHAT Flarum forum, accessible from anywhere on the internet!

## 🚀 Quick Start (No Authentication Required)

The easiest way to get started is using Cloudflare's quick tunnels:

```bash
sudo bash deploy-flarum.sh --cloudflare
```

This will:
- ✅ Install cloudflared automatically
- ✅ Create a temporary public tunnel (e.g., `https://abc123.trycloudflare.com`)
- ✅ Configure your forum to use the tunnel URL
- ✅ Make your forum accessible worldwide instantly!

## 🔧 Advanced Setup (Persistent Tunnels)

For production use, you may want a persistent tunnel with a custom domain:

### Prerequisites
1. A Cloudflare account (free)
2. A domain managed by Cloudflare (optional)
3. Cloudflare API token with Tunnel permissions

### Steps

1. **Get your Cloudflare API Token:**
   - Go to https://dash.cloudflare.com/profile/api-tokens
   - Click "Create Token"
   - Use "Custom token" with these permissions:
     - `Zone:Zone:Read` (for your domain)
     - `Zone:DNS:Edit` (for your domain)
     - `Account:Cloudflare Tunnel:Edit`

2. **Set the token and deploy:**
   ```bash
   export CLOUDFLARE_TOKEN="your-token-here"
   sudo bash deploy-flarum.sh --cloudflare
   ```

3. **Optional: Use custom domain:**
   ```bash
   sudo bash deploy-flarum.sh --cloudflare https://forum.yourdomain.com
   ```

## 📁 Configuration Files

The script creates these files in `.cloudflare/`:

- `tunnel.json` - Tunnel metadata and URL
- `config.yml` - Tunnel configuration
- `{tunnel-id}.json` - Tunnel credentials (if using authenticated tunnels)

## 🔄 Managing Your Tunnel

### Check tunnel status:
```bash
# View tunnel logs
tail -f /tmp/tunnel.log

# Check if tunnel is running
ps aux | grep cloudflared
```

### Update tunnel URL:
```bash
sudo bash deploy-flarum.sh --update-url https://new-tunnel-url.com
```

### Restart tunnel:
```bash
# Kill existing tunnel
pkill cloudflared

# Restart with script
sudo bash deploy-flarum.sh --cloudflare
```

## 🌟 Benefits of Cloudflare Tunnels

- **🆓 Free**: No cost for basic tunneling
- **🔒 Secure**: No open ports on your server
- **🌍 Global**: Accessible from anywhere
- **⚡ Fast**: Cloudflare's global CDN
- **🛡️ Protected**: Built-in DDoS protection
- **📱 Mobile-friendly**: Works on all devices

## 🔧 Troubleshooting

### Tunnel not starting:
```bash
# Check logs
cat /tmp/tunnel.log

# Verify cloudflared installation
cloudflared --version

# Test manual tunnel
cloudflared tunnel --url http://localhost:12000
```

### Forum not accessible:
1. Ensure Apache is running on port 12000
2. Check if tunnel URL is correct in forum config
3. Verify tunnel is active: `ps aux | grep cloudflared`

### URL changes:
Quick tunnels get new URLs each time. For persistent URLs:
1. Use authenticated tunnels with API token
2. Or use the `--update-url` option when URL changes

## 📝 Example Configurations

### Basic quick tunnel:
```bash
sudo bash deploy-flarum.sh --cloudflare
# Gets: https://random-id.trycloudflare.com
```

### With custom domain:
```bash
export CLOUDFLARE_TOKEN="your-token"
sudo bash deploy-flarum.sh --cloudflare https://forum.example.com
```

### Update existing installation:
```bash
sudo bash deploy-flarum.sh --update-url https://new-tunnel-url.trycloudflare.com
```

## 🎯 Production Tips

1. **Use authenticated tunnels** for production (more reliable)
2. **Set up monitoring** to restart tunnel if it goes down
3. **Use custom domains** for branding
4. **Enable Cloudflare features** like caching, security rules
5. **Backup tunnel credentials** in `.cloudflare/` directory

## 🤝 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review `/tmp/tunnel.log` for errors
3. Ensure your server can reach the internet
4. Verify Cloudflare API token permissions (if using authenticated tunnels)

---

**🌟 Enjoy your free, globally accessible HOLM.CHAT forum!** 🌟