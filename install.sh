#!/usr/bin/env bash
set -euo pipefail

# ClaudeOps Installer
# One-command installation for autonomous server management with Claude Code

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/claudeops"
LOG_DIR="/var/log/claudeops"
CRON_FILE="/etc/cron.d/claudeops"
SYSTEMD_FILE="/etc/systemd/system/claudeops-boot.service"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Where to download from
REPO_URL="${REPO_URL:-https://github.com/dennisonbertram/claudeops}"
BRANCH="${BRANCH:-main}"

echo -e "${BLUE}"
cat << "EOF"
  ____ _                 _       ___
 / ___| | __ _ _   _  __| | ___ / _ \ _ __  ___
| |   | |/ _` | | | |/ _` |/ _ \ | | | '_ \/ __|
| |___| | (_| | |_| | (_| |  __/ |_| | |_) \__ \
 \____|_|\__,_|\__,_|\__,_|\___|\___/| .__/|___/
                                      |_|
EOF
echo -e "${NC}"
echo "ClaudeOps v${VERSION} - Autonomous Server Management"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This installer must be run as root${NC}"
    echo "Please run: sudo bash install.sh"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y git
    elif command -v yum &> /dev/null; then
        yum install -y git
    else
        echo -e "${RED}ERROR: Could not install git. Please install it manually.${NC}"
        exit 1
    fi
fi

# Check if Claude Code is installed
echo "Checking for Claude Code CLI..."
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Claude Code CLI not found!${NC}"
    echo ""
    echo "ClaudeOps requires the Claude Code CLI to function."
    echo ""
    echo "Installation options:"
    echo "  1. npm install -g @anthropic-ai/claude-code"
    echo "  2. Visit: https://docs.anthropic.com/claude-code"
    echo ""
    read -p "Would you like me to install it via npm now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v npm &> /dev/null; then
            npm install -g @anthropic-ai/claude-code
        else
            echo -e "${RED}ERROR: npm not found. Please install Node.js and npm first.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Installation aborted. Please install Claude Code CLI first.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Claude Code CLI found${NC}"
echo ""

# Clone or update repository
TEMP_DIR=$(mktemp -d)
echo "Downloading ClaudeOps..."

if [ -d "$TEMP_DIR/claudeops" ]; then
    cd "$TEMP_DIR/claudeops"
    git pull
else
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/claudeops"
    cd "$TEMP_DIR/claudeops"
fi

echo -e "${GREEN}✓ Downloaded ClaudeOps${NC}"
echo ""

# Install binaries
echo "Installing binaries to $INSTALL_DIR..."
cp bin/claudeops "$INSTALL_DIR/"
cp bin/claudeops-setup "$INSTALL_DIR/"
cp bin/claudeops-cron "$INSTALL_DIR/"
cp bin/claudeops-boot "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/claudeops"
chmod +x "$INSTALL_DIR/claudeops-setup"
chmod +x "$INSTALL_DIR/claudeops-cron"
chmod +x "$INSTALL_DIR/claudeops-boot"
echo -e "${GREEN}✓ Binaries installed${NC}"

# Install library
echo "Installing health check library..."
mkdir -p /usr/local/lib/claudeops
cp lib/health-checks.sh /usr/local/lib/claudeops/
chmod +x /usr/local/lib/claudeops/health-checks.sh
echo -e "${GREEN}✓ Library installed${NC}"

# Install prompts
echo "Installing prompt templates..."
mkdir -p /usr/local/share/claudeops/prompts
cp prompts/*.md /usr/local/share/claudeops/prompts/
echo -e "${GREEN}✓ Prompts installed${NC}"

# Install config template
echo "Installing configuration template..."
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cp config/claudeops.example.json "$CONFIG_DIR/config.json.example"
    echo -e "${GREEN}✓ Config template installed at $CONFIG_DIR/config.json.example${NC}"
else
    echo -e "${YELLOW}! Config already exists, skipping${NC}"
fi

# Create log directories
echo "Creating log directories..."
mkdir -p "$LOG_DIR"/{health,issues,actions,boot}
chmod 755 "$LOG_DIR"
echo -e "${GREEN}✓ Log directories created${NC}"

# Ask about cron installation
echo ""
read -p "Install cron job for automatic health checks? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp templates/claudeops.cron "$CRON_FILE"
    chmod 644 "$CRON_FILE"
    echo -e "${GREEN}✓ Cron job installed${NC}"
    echo "  Health checks will run every 2 hours"
    echo "  Edit $CRON_FILE to change schedule"
else
    echo -e "${YELLOW}! Cron job not installed${NC}"
    echo "  You can install it later by copying templates/claudeops.cron to /etc/cron.d/"
fi

# Ask about boot recovery
echo ""
read -p "Install systemd service for boot recovery? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp templates/claudeops-boot.service "$SYSTEMD_FILE"
    systemctl daemon-reload
    systemctl enable claudeops-boot.service
    echo -e "${GREEN}✓ Boot recovery service installed and enabled${NC}"
    echo "  Services will be recovered automatically after reboot"
else
    echo -e "${YELLOW}! Boot recovery not installed${NC}"
    echo "  You can install it later by copying templates/claudeops-boot.service to /etc/systemd/system/"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Installation complete
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete! 🎉               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Run the setup wizard:"
echo -e "     ${BLUE}sudo claudeops-setup${NC}"
echo ""
echo "  2. This will interview you about your system and create:"
echo "     - Configuration file: $CONFIG_DIR/config.json"
echo "     - Initial health check baseline"
echo ""
echo "  3. After setup, ClaudeOps will:"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "     - ✓ Run health checks every 2 hours (via cron)"
    echo "     - ✓ Recover services after reboot (via systemd)"
else
    echo "     - Run when you manually execute: claudeops-cron"
fi
echo ""
echo "Documentation:"
echo "  - Config example: $CONFIG_DIR/config.json.example"
echo "  - Logs: $LOG_DIR/"
echo "  - Prompts: /usr/local/share/claudeops/prompts/"
echo ""
echo -e "${BLUE}Ready to begin? Run: sudo claudeops-setup${NC}"
echo ""