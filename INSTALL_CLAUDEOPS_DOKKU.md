# Complete Installation Guide: ClaudeOps + Dokku

**Last Updated:** 2025-10-08
**Target OS:** Ubuntu 24.04 LTS
**Test Server:** Hetzner Bare Metal (65.21.67.254)
**Installation Time:** ~45 minutes
**Difficulty:** Intermediate

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: System Preparation](#step-1-system-preparation)
3. [Step 2: Install ClaudeOps](#step-2-install-claudeops)
4. [Step 3: Install Security & Services](#step-3-install-security--services)
5. [Step 4: Install Dokku](#step-4-install-dokku)
6. [Step 5: Configure ClaudeOps for Dokku](#step-5-configure-claudeops-for-dokku)
7. [Step 6: Deploy First App](#step-6-deploy-first-app)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
- **Minimum:** 4GB RAM, 2 cores, 40GB disk
- **Recommended:** 8GB+ RAM, 4+ cores, 100GB+ disk
- **Production:** 16-64GB RAM, 8-12 cores, 500GB+ disk

### Access Requirements
- Root or sudo access to Ubuntu 24.04 server
- SSH access to server
- GitHub account (for ClaudeOps logs)
- Claude Code API access (https://claude.com)

### Before You Begin
```bash
# Verify OS
lsb_release -a  # Should show Ubuntu 24.04

# Verify sudo
sudo whoami  # Should show: root

# Update system
sudo apt update && sudo apt upgrade -y
```

---

## Step 1: System Preparation

### 1.1 Install Base Dependencies

```bash
# Essential tools
sudo apt install -y curl git build-essential

# Network tools
sudo apt install -y net-tools ca-certificates gnupg lsb-release
```

### 1.2 Install Node.js via NVM

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Load NVM (run as root AND your user)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 22
nvm install 22.20.0
nvm use 22.20.0
nvm alias default 22.20.0

# Verify
node --version  # Should show v22.20.0
npm --version   # Should show 10.9.3
```

**Important:** Run the NVM installation as both root and your regular user if you use a non-root account for deployments.

### 1.3 Install Claude Code CLI

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version

# Authenticate with Claude
claude auth login
# Follow OAuth flow in browser

# Test Claude
claude "print hello world"
```

---

## Step 2: Install ClaudeOps

### 2.1 Clone Repository

```bash
# Clone to /opt/claudeops
cd /opt
sudo git clone https://github.com/dennisonbertram/claudeops.git
cd claudeops

# Make scripts executable
sudo chmod +x *.sh bin/* scripts/*
```

### 2.2 Run Installation Script

```bash
# Run installer
sudo ./install.sh

# This creates:
# - /opt/claudeops/ directory structure
# - claudeops user (for SSH access)
# - /var/log/claudeops/ log directory
# - Cron job (every 2 hours)
# - Systemd boot recovery service
```

### 2.3 Configure GitHub Integration

```bash
# Create GitHub token with repo permissions
# https://github.com/settings/tokens

# Create logs repository
# https://github.com/new

# Configure ClaudeOps
echo "YOUR_GITHUB_TOKEN" | sudo tee /opt/claudeops/.github-token
sudo chmod 400 /opt/claudeops/.github-token
sudo chown root:root /opt/claudeops/.github-token

# Initialize log repository
cd /var/log/claudeops
sudo -u claude git init
sudo -u claude git remote add origin https://github.com/YOUR_USERNAME/claudeops-logs.git
sudo -u claude git branch -M main
```

### 2.4 Verify ClaudeOps Installation

```bash
# Check cron job
sudo crontab -l | grep claudeops
# Should show: 0 */2 * * * ...

# Check systemd service
sudo systemctl status claudeops-boot
# Should show: enabled

# Run manual health check
cd /opt/claudeops
sudo ./health-check.sh

# Check logs
ls -la /var/log/claudeops/health*.log
```

---

## Step 3: Install Security & Services

### 3.1 Install fail2ban

```bash
# Install fail2ban for SSH protection
sudo apt install -y fail2ban

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verify
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

### 3.2 Install Redis

```bash
# Install Redis server
sudo apt install -y redis-server

# Configure to start on boot
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Verify
redis-cli ping  # Should return: PONG
```

---

## Step 4: Install Dokku

### 4.1 Prepare for Dokku

**CRITICAL:** Dokku will take over port 80/443 with its own nginx. Back up any existing nginx config.

```bash
# Backup existing nginx (if any)
if systemctl is-active nginx; then
    sudo mkdir -p /root/nginx-backup-$(date +%Y%m%d)
    sudo cp -r /etc/nginx/* /root/nginx-backup-$(date +%Y%m%d)/
    sudo systemctl stop nginx
    sudo systemctl disable nginx
fi
```

### 4.2 Install Docker CE (Official)

**Important:** Dokku requires official Docker CE, NOT Ubuntu's docker.io package.

```bash
# Remove Ubuntu Docker if installed
sudo apt remove -y docker.io containerd runc

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

# Update and install
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Verify
docker --version
sudo systemctl status docker
```

### 4.3 Install Dokku

```bash
# Download Dokku installation script
wget -NP . https://dokku.com/install/v0.36.7/bootstrap.sh

# Install Dokku (non-interactive)
sudo DOKKU_TAG=v0.36.7 DEBIAN_FRONTEND=noninteractive bash bootstrap.sh

# If installation hangs, kill and reconfigure:
# sudo kill $(pgrep -f "apt install dokku")
# sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
# sudo DEBIAN_FRONTEND=noninteractive apt install -y -f dokku

# Verify
dokku version  # Should show: 0.36.7
```

### 4.4 Install Dokku Plugins

```bash
# PostgreSQL plugin
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres

# Redis plugin
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis

# Let's Encrypt (SSL) plugin
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Verify plugins
sudo dokku plugin:list
# Should show postgres, redis, letsencrypt as enabled
```

### 4.5 Configure SSH Keys for Deployment

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "deploy@dokku"

# Add your public key to Dokku
cat ~/.ssh/id_ed25519.pub | sudo dokku ssh-keys:add $(whoami)

# Verify
sudo dokku ssh-keys:list
```

---

## Step 5: Configure ClaudeOps for Dokku

### 5.1 Update Health Check Script

Create Dokku monitoring functions:

```bash
# Edit health check script
sudo nano /opt/claudeops/health-check.sh
```

Add before the final execution section:

```bash
# Dokku Health Checks
echo "Checking Dokku status..." >&2

if command -v dokku >/dev/null 2>&1; then
    echo "Dokku Apps:" >&2
    dokku apps:list 2>/dev/null || echo "  No apps deployed yet"

    echo "" >&2
    echo "Dokku Services:" >&2
    dokku postgres:list 2>/dev/null || echo "  No PostgreSQL services"
    dokku redis:list 2>/dev/null || echo "  No Redis services"

    echo "" >&2
    echo "Docker System:" >&2
    docker system df 2>/dev/null || echo "  Docker not available"
else
    echo "Dokku not installed" >&2
fi
```

### 5.2 Update CLAUDE.md System Prompt

```bash
# Edit the ClaudeOps system prompt
sudo nano /opt/claudeops/CLAUDE.md
```

Add to the "Server Details" section:

```markdown
**Dokku Platform:**
- Version: 0.36.7
- Plugins: postgres, redis, letsencrypt
- Apps deployed: (check with `dokku apps:list`)
- Databases: (check with `dokku postgres:list`)
- Monitor: `dokku ps:report` for all app statuses

**Dokku Commands Available:**
- `dokku apps:list` - List all applications
- `dokku ps:report <app>` - Check app status
- `dokku postgres:list` - List databases
- `dokku logs <app> --tail 100` - View app logs
- `dokku ps:restart <app>` - Restart an app
- `docker system df` - Check Docker disk usage
```

### 5.3 Test Integration

```bash
# Run manual health check
sudo /opt/claudeops/health-check.sh

# Check that Dokku info appears in log
tail -50 /var/log/claudeops/health-$(date +%Y%m%d-*)
```

---

## Step 6: Deploy First App

### 6.1 Create Test Application

```bash
# Create app
sudo dokku apps:create hello-dokku

# Create database
sudo dokku postgres:create hello-db
sudo dokku postgres:link hello-db hello-dokku

# Set config
sudo dokku config:set hello-dokku PORT=3000
```

### 6.2 Deploy Sample Node.js App

On your local machine:

```bash
# Create sample app
mkdir hello-dokku && cd hello-dokku
npm init -y
npm install express

# Create app.js
cat > app.js <<'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Dokku!',
    timestamp: new Date(),
    database: process.env.DATABASE_URL ? 'connected' : 'not configured'
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
EOF

# Create Procfile
echo "web: node app.js" > Procfile

# Initialize git
git init
git add .
git commit -m "Initial commit"

# Add Dokku remote (replace with your server IP)
git remote add dokku dokku@65.21.67.254:hello-dokku

# Deploy!
git push dokku main
```

### 6.3 Verify Deployment

```bash
# On server, check app status
sudo dokku ps:report hello-dokku

# Check logs
sudo dokku logs hello-dokku --tail 50

# Test endpoint
curl http://65.21.67.254  # Or your server IP

# Should return JSON: {"message": "Hello from Dokku!", ...}
```

---

## Verification

### System Health Checklist

```bash
# ✅ ClaudeOps installed
ls -la /opt/claudeops/
ls -la /var/log/claudeops/

# ✅ Cron job active
sudo crontab -l | grep health-check

# ✅ Boot recovery enabled
sudo systemctl status claudeops-boot

# ✅ Dokku operational
dokku version
dokku apps:list

# ✅ Docker running
sudo systemctl status docker
docker ps

# ✅ Plugins installed
sudo dokku plugin:list | grep -E "postgres|redis|letsencrypt"

# ✅ Services running
sudo systemctl status fail2ban
sudo systemctl status redis-server

# ✅ Ports listening
sudo ss -tlnp | grep -E ':80|:443'

# ✅ First app deployed
curl http://YOUR_SERVER_IP
```

### Expected Output

```
ClaudeOps:
- /opt/claudeops/ exists with scripts
- /var/log/claudeops/ has health logs
- Cron job runs every 2 hours

Dokku:
- Version 0.36.7
- At least 1 test app deployed
- PostgreSQL and Redis plugins available
- Nginx listening on port 80

Services:
- Docker active
- fail2ban protecting SSH
- Redis running on localhost:6379
```

---

## Troubleshooting

### Dokku Installation Hangs

**Problem:** `apt install dokku` waits for interactive input

**Solution:**
```bash
# Kill stuck process
sudo killall apt
sudo kill $(pgrep -f "apt install dokku")

# Clean up and retry
sudo dpkg --configure -a
sudo DEBIAN_FRONTEND=noninteractive apt install -y -f dokku
```

### Docker Permission Errors

**Problem:** `permission denied while trying to connect to Docker daemon`

**Solution:**
```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker
```

### Git Push Fails

**Problem:** `Permission denied (publickey)` when pushing to Dokku

**Solution:**
```bash
# Verify SSH key is added
sudo dokku ssh-keys:list

# Add your key if missing
cat ~/.ssh/id_ed25519.pub | sudo dokku ssh-keys:add $(whoami)

# Test SSH
ssh dokku@YOUR_SERVER_IP apps:list
```

### App Won't Start

**Problem:** App deployed but not accessible

**Solution:**
```bash
# Check app logs
sudo dokku logs YOUR_APP --tail 100

# Check app is running
sudo dokku ps:report YOUR_APP

# Restart app
sudo dokku ps:restart YOUR_APP

# Check nginx config
sudo dokku proxy:report YOUR_APP
```

### ClaudeOps Not Logging

**Problem:** No health check logs appearing

**Solution:**
```bash
# Check cron is running
sudo systemctl status cron

# View cron logs
sudo grep CRON /var/log/syslog

# Run health check manually
cd /opt/claudeops
sudo ./health-check.sh

# Check permissions
ls -la /var/log/claudeops/
sudo chown -R claude:claude /var/log/claudeops/
```

### Nginx Conflicts

**Problem:** Port 80 already in use

**Solution:**
```bash
# Check what's using port 80
sudo ss -tlnp | grep :80

# If old nginx is running
sudo systemctl stop nginx
sudo systemctl disable nginx

# Restart Dokku's nginx
sudo dokku proxy:disable <app>
sudo dokku proxy:enable <app>
```

---

## Next Steps

### Production Hardening

1. **Set up custom domain:**
   ```bash
   sudo dokku domains:add hello-dokku yourdomain.com
   sudo dokku letsencrypt:enable hello-dokku
   ```

2. **Configure email for Let's Encrypt:**
   ```bash
   sudo dokku letsencrypt:set hello-dokku email you@example.com
   ```

3. **Set up automated backups:**
   ```bash
   sudo dokku postgres:backup hello-db
   sudo dokku postgres:backup-schedule hello-db "0 3 * * *"
   ```

4. **Configure firewall:**
   ```bash
   sudo ufw allow 22/tcp   # SSH
   sudo ufw allow 80/tcp   # HTTP
   sudo ufw allow 443/tcp  # HTTPS
   sudo ufw enable
   ```

5. **Monitor with ClaudeOps:**
   - ClaudeOps will automatically check every 2 hours
   - View logs: `ls -la /var/log/claudeops/`
   - GitHub logs: Check your claudeops-logs repository

### Deploy More Apps

Follow the same pattern:
1. `sudo dokku apps:create <app-name>`
2. Create databases if needed
3. `git push dokku main`
4. Add domains and SSL
5. ClaudeOps monitors automatically

---

## Support & Resources

**Documentation:**
- ClaudeOps: https://github.com/dennisonbertram/claudeops
- Dokku: https://dokku.com/docs/getting-started/installation/

**Community:**
- Report issues: https://github.com/dennisonbertram/claudeops/issues
- Dokku Slack: https://slack.dokku.com

**Logs Repository:**
- https://github.com/YOUR_USERNAME/claudeops-logs

---

## Summary

You now have:
- ✅ ClaudeOps monitoring your server every 2 hours
- ✅ Dokku providing Railway-like `git push` deployments
- ✅ Automated SSL with Let's Encrypt
- ✅ PostgreSQL and Redis ready to use
- ✅ AI-powered autonomous administration
- ✅ Full audit trail in GitHub

**Cost:** ~$50/month (server) vs $500+/month (cloud PaaS)
**Capacity:** 10-100+ apps on a single server
**Reliability:** AI monitoring and auto-recovery

---

**Welcome to the future of bare-metal server management!** 🚀

*This guide was created by ClaudeOps and validated on production servers.*
