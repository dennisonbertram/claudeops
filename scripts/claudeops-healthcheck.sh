#!/bin/bash
# ClaudeOps Health Check Script
# This script runs Claude Code to perform system health checks

set -e

# Configuration
CLAUDEOPS_DIR="/opt/claudeops"
LOG_DIR="/var/log/claudeops"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
HEALTH_LOG="$LOG_DIR/health/${TIMESTAMP}.md"

# Ensure log directory exists
mkdir -p "$LOG_DIR/health"

# Get last 3 health checks for context
CONTEXT=""
for log in $(ls -t "$LOG_DIR/health"/*.md 2>/dev/null | head -3); do
    if [ -f "$log" ]; then
        CONTEXT="$CONTEXT

Previous health check from $(basename $log .md):
$(cat "$log")"
    fi
done

# Create the prompt for Claude
cat > /tmp/claude-healthcheck-prompt.txt << 'EOF'
You are ClaudeOps, an autonomous server administrator. Perform a comprehensive health check of this server and write a detailed report.

CONTEXT FROM PREVIOUS RUNS:
${CONTEXT}

HEALTH CHECK TASKS:
1. Check system resources (CPU, memory, disk usage)
2. Verify all critical services are running (use systemctl, docker ps, pm2 list)
3. Check network connectivity and DNS resolution
4. Review recent system logs for errors (/var/log/syslog, journalctl -xe)
5. Check for security updates (apt list --upgradable)
6. Monitor database connections if applicable
7. Verify web services are responding (curl localhost endpoints)
8. Check disk I/O and any slow queries
9. Review cron jobs and scheduled tasks

OUTPUT FORMAT:
Write a markdown report with:
- Timestamp and server info
- System health summary (GREEN/YELLOW/RED status)
- Detailed findings for each check
- Any issues discovered
- Actions taken (if any)
- Recommendations for manual intervention (if needed)

If you find critical issues:
1. Try to fix them automatically if safe to do so
2. Document what you did in the action log
3. Alert if manual intervention is required

Write your report to: ${HEALTH_LOG}

Remember: You have full bash access. Use it wisely to diagnose and fix issues.
EOF

# Run Claude Code with the health check prompt
echo "Running ClaudeOps health check at $(date)..."
claude chat --no-stream < /tmp/claude-healthcheck-prompt.txt

# Clean up
rm -f /tmp/claude-healthcheck-prompt.txt

echo "Health check completed. Report saved to: $HEALTH_LOG"