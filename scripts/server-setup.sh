#!/bin/bash
# Claude Code Server Setup Script
# This script installs Claude Code and all necessary dependencies on a Debian/Ubuntu server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "Starting Claude Code server setup..."

# Update system
log "Updating system packages..."
apt update && apt upgrade -y

# Install basic dependencies
log "Installing basic dependencies..."
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    jq

# Install Python and pip
log "Installing Python and pip..."
apt install -y python3 python3-pip python3-venv
update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install NVM and Node.js
log "Installing NVM and Node.js..."
export NVM_DIR="/opt/nvm"
mkdir -p $NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | NVM_DIR=$NVM_DIR bash

# Source NVM for this session
export NVM_DIR="/opt/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install latest LTS Node
log "Installing Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default node

# Make NVM available system-wide
cat > /etc/profile.d/nvm.sh << 'EOF'
export NVM_DIR="/opt/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

# Install Claude Code CLI
log "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

# Create ClaudeOps directory structure
log "Creating ClaudeOps directory structure..."
mkdir -p /opt/claudeops/{bin,config,prompts,lib}
mkdir -p /var/log/claudeops/{health,issues,actions,boot}

# Create state file
echo '{"initialized": "'$(date -Iseconds)'", "version": "1.0.0"}' > /var/log/claudeops/state.json

# Create claude-code configuration directory
mkdir -p /root/.config/claude-code

# Install PM2 for process management
log "Installing PM2 for process management..."
npm install -g pm2
pm2 startup systemd -u root --hp /root

# Install additional useful tools
log "Installing additional tools..."
apt install -y \
    htop \
    ncdu \
    net-tools \
    dnsutils \
    postgresql-client \
    redis-tools \
    nginx \
    certbot \
    python3-certbot-nginx

# Set up basic firewall rules
log "Setting up UFW firewall..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
echo "y" | ufw enable

# Create a claude user for running services (optional, for security)
log "Creating claude service user..."
if ! id -u claude > /dev/null 2>&1; then
    useradd -m -s /bin/bash -d /home/claude claude
    usermod -aG sudo claude
fi

# Set up log rotation for ClaudeOps logs
cat > /etc/logrotate.d/claudeops << 'EOF'
/var/log/claudeops/*/*.md {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 0644 root root
}
EOF

# Create a test script to verify Claude Code installation
cat > /opt/claudeops/test-claude.sh << 'EOF'
#!/bin/bash
echo "Testing Claude Code installation..."

# Test if claude command exists
if command -v claude &> /dev/null; then
    echo "✓ Claude Code CLI is installed"
    claude --version
else
    echo "✗ Claude Code CLI not found"
    exit 1
fi

# Test Node.js
if command -v node &> /dev/null; then
    echo "✓ Node.js is installed: $(node --version)"
else
    echo "✗ Node.js not found"
    exit 1
fi

# Test Python
if command -v python3 &> /dev/null; then
    echo "✓ Python is installed: $(python3 --version)"
else
    echo "✗ Python not found"
    exit 1
fi

# Test PM2
if command -v pm2 &> /dev/null; then
    echo "✓ PM2 is installed"
else
    echo "✗ PM2 not found"
    exit 1
fi

echo ""
echo "All tests passed! Claude Code is ready to use."
EOF

chmod +x /opt/claudeops/test-claude.sh

# Display summary
log "==========================================="
log "Claude Code Server Setup Complete!"
log "==========================================="
log ""
log "Installed components:"
log "  - Node.js (via NVM) at /opt/nvm"
log "  - Python 3 with pip"
log "  - Claude Code CLI (global npm package)"
log "  - PM2 process manager"
log "  - ClaudeOps directories at /opt/claudeops"
log "  - Log directories at /var/log/claudeops"
log ""
log "Next steps:"
log "  1. Configure Claude Code API key:"
log "     claude auth login"
log "  2. Test installation:"
log "     /opt/claudeops/test-claude.sh"
log "  3. Set up ClaudeOps cron jobs and services"
log ""
log "You may need to log out and back in for all paths to be available."