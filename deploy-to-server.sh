#!/bin/bash
# Deploy ClaudeOps to Server
# This script deploys all ClaudeOps components to the target server

set -e

# Configuration
SERVER_IP="65.21.67.254"
SERVER_USER="root"
# Password should be provided as environment variable for security
# Usage: SERVER_PASS="your_password" ./deploy-to-server.sh
# Better practice: Use SSH key authentication instead of passwords
if [ -z "$SERVER_PASS" ]; then
    echo "ERROR: SERVER_PASS environment variable not set"
    echo "Usage: SERVER_PASS='your_password' ./deploy-to-server.sh"
    echo "Or better: Set up SSH key authentication"
    exit 1
fi

echo "======================================"
echo "Deploying ClaudeOps to $SERVER_IP"
echo "======================================"

# First, copy all setup scripts to the server
echo "Copying setup scripts to server..."
scp scripts/server-setup.sh ${SERVER_USER}@${SERVER_IP}:/tmp/
scp scripts/claudeops-healthcheck.sh ${SERVER_USER}@${SERVER_IP}:/tmp/
scp scripts/claudeops-boot.sh ${SERVER_USER}@${SERVER_IP}:/tmp/
scp scripts/claudeops-boot.service ${SERVER_USER}@${SERVER_IP}:/tmp/
scp scripts/test-claudeops.sh ${SERVER_USER}@${SERVER_IP}:/tmp/

# Copy the system prompt
echo "Copying ClaudeOps system prompt..."
scp prompts/claudeops-system-prompt.md ${SERVER_USER}@${SERVER_IP}:/tmp/

# Now SSH into the server and run the setup
echo "Connecting to server to run setup..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
set -e

echo "Starting server setup..."

# Make setup script executable and run it
chmod +x /tmp/server-setup.sh
/tmp/server-setup.sh

# Copy ClaudeOps scripts to their proper locations
echo "Installing ClaudeOps scripts..."
cp /tmp/claudeops-healthcheck.sh /opt/claudeops/bin/
cp /tmp/claudeops-boot.sh /opt/claudeops/bin/
cp /tmp/test-claudeops.sh /opt/claudeops/bin/
chmod +x /opt/claudeops/bin/*.sh

# Copy the system prompt
echo "Installing ClaudeOps system prompt..."
cp /tmp/claudeops-system-prompt.md /opt/claudeops/prompts/system-prompt.md

# Install systemd service for boot recovery
echo "Installing systemd service..."
cp /tmp/claudeops-boot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable claudeops-boot.service

# Set up cron job for health checks (every 2 hours)
echo "Setting up cron job for health checks..."
(crontab -l 2>/dev/null || true; echo "0 */2 * * * /opt/claudeops/bin/claudeops-healthcheck.sh >> /var/log/claudeops/cron.log 2>&1") | crontab -

# Clean up temporary files
rm -f /tmp/server-setup.sh /tmp/claudeops-*.sh /tmp/claudeops-*.service

echo ""
echo "======================================"
echo "ClaudeOps deployment complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. SSH into the server: ssh root@65.21.67.254"
echo "2. Configure Claude API key: claude auth login"
echo "3. Test basic installation: /opt/claudeops/test-claude.sh"
echo "4. Test ClaudeOps functionality: /opt/claudeops/bin/test-claudeops.sh"
echo "5. Run manual health check: /opt/claudeops/bin/claudeops-healthcheck.sh"
echo ""
echo "The system will:"
echo "- Run health checks every 2 hours via cron"
echo "- Perform boot recovery on system restart"
echo "- Log all activities to /var/log/claudeops/"

ENDSSH

echo ""
echo "Deployment script finished!"