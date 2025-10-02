#!/bin/bash
# ClaudeOps Boot Recovery Script
# This script runs on system startup to ensure all services are properly initialized

set -e

# Configuration
CLAUDEOPS_DIR="/opt/claudeops"
LOG_DIR="/var/log/claudeops"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BOOT_LOG="$LOG_DIR/boot/${TIMESTAMP}-boot.md"

# Ensure log directory exists
mkdir -p "$LOG_DIR/boot"

# Wait for network to be fully up
sleep 10

# Get last health check and any unresolved issues
LAST_HEALTH=""
if [ -f "$LOG_DIR/health/"*.md ]; then
    LAST_HEALTH=$(ls -t "$LOG_DIR/health/"*.md | head -1)
    if [ -f "$LAST_HEALTH" ]; then
        LAST_HEALTH_CONTENT=$(cat "$LAST_HEALTH")
    fi
fi

UNRESOLVED_ISSUES=""
for issue in $(ls -t "$LOG_DIR/issues/"*.md 2>/dev/null | head -5); do
    if [ -f "$issue" ] && ! grep -q "RESOLVED" "$issue"; then
        UNRESOLVED_ISSUES="$UNRESOLVED_ISSUES

Unresolved issue from $(basename $issue .md):
$(cat "$issue")"
    fi
done

# Create the boot recovery prompt for Claude
cat > /tmp/claude-boot-prompt.txt << 'EOF'
You are ClaudeOps, performing boot recovery after a system restart. Your job is to ensure all services are properly started and the system is healthy.

BOOT TIME: ${TIMESTAMP}

CONTEXT:
Last health check before shutdown:
${LAST_HEALTH_CONTENT}

${UNRESOLVED_ISSUES}

BOOT RECOVERY TASKS:
1. Check system boot logs (journalctl -b)
2. Verify network connectivity
3. Start critical services in order:
   - Database services (PostgreSQL, MySQL, Redis)
   - Application servers (Node.js apps via PM2)
   - Web servers (Nginx, Apache)
   - Monitoring services
4. Wait for services to be ready (check ports, test connections)
5. Run application-specific startup tasks:
   - Database migrations
   - Cache warming
   - Health endpoint verification
6. Verify all cron jobs are registered
7. Check for failed services and attempt recovery
8. Test critical application endpoints

OUTPUT FORMAT:
Write a markdown report to: ${BOOT_LOG}

Include:
- Boot timestamp and reason for restart (if available)
- Services started and their status
- Any errors encountered and how they were resolved
- System health after boot
- Any manual intervention needed

IMPORTANT:
- Start services with proper dependency order
- Wait for databases before starting apps
- Log all actions taken
- Alert if critical services fail to start

Use systemctl, pm2, docker, and other tools as needed.
EOF

# Run Claude Code for boot recovery
echo "Running ClaudeOps boot recovery at $(date)..."
claude chat --no-stream < /tmp/claude-boot-prompt.txt

# Clean up
rm -f /tmp/claude-boot-prompt.txt

echo "Boot recovery completed. Report saved to: $BOOT_LOG"