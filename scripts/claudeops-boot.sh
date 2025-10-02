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

# Load the system prompt
SYSTEM_PROMPT=""
if [ -f "$CLAUDEOPS_DIR/prompts/system-prompt.md" ]; then
    SYSTEM_PROMPT=$(cat "$CLAUDEOPS_DIR/prompts/system-prompt.md")
else
    SYSTEM_PROMPT="You are ClaudeOps, an autonomous server administrator."
fi

# Get boot reason if available
BOOT_REASON=$(last reboot | head -1 | cut -d' ' -f5- || echo "Unknown")

# Create the boot recovery prompt for Claude
cat > /tmp/claude-boot-prompt.txt << EOF
$SYSTEM_PROMPT

## Current Session Context
- **Invoked by**: systemd (boot recovery)
- **Boot timestamp**: $(date -Iseconds)
- **Boot reason**: $BOOT_REASON
- **Unresolved issues**: Found below
- **Boot log path**: $BOOT_LOG

## Last Health Check Before Shutdown
$LAST_HEALTH_CONTENT

## Unresolved Issues
$UNRESOLVED_ISSUES

## Your Task: Boot Recovery

The system has just started/restarted. You must ensure all services are properly initialized and the system is healthy. Follow your boot recovery guidelines:

1. **Diagnose the restart**: Check if it was planned or unplanned
2. **Start services in order**: Respect dependencies (databases before apps)
3. **Verify readiness**: Don't proceed until each service is actually ready
4. **Run startup tasks**: Migrations, cache warming, etc.
5. **Test everything**: Verify all critical endpoints respond correctly
6. **Document the process**: Write a complete boot recovery report

Write your boot recovery report to: $BOOT_LOG

CRITICAL: If any essential service fails to start, document the issue clearly and provide specific steps for manual intervention.

Remember: The system depends on you to recover properly from restarts. Be methodical and thorough.
EOF

# Run Claude Code for boot recovery
echo "Running ClaudeOps boot recovery at $(date)..."
claude chat --no-stream < /tmp/claude-boot-prompt.txt

# Clean up
rm -f /tmp/claude-boot-prompt.txt

echo "Boot recovery completed. Report saved to: $BOOT_LOG"