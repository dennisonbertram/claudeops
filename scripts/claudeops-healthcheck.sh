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

# Load the system prompt
SYSTEM_PROMPT=""
if [ -f "$CLAUDEOPS_DIR/prompts/system-prompt.md" ]; then
    SYSTEM_PROMPT=$(cat "$CLAUDEOPS_DIR/prompts/system-prompt.md")
else
    SYSTEM_PROMPT="You are ClaudeOps, an autonomous server administrator."
fi

# Count unresolved issues
UNRESOLVED_COUNT=$(find "$LOG_DIR/issues" -name "*.md" -type f 2>/dev/null | xargs grep -L "RESOLVED" 2>/dev/null | wc -l || echo "0")

# Get system uptime
UPTIME=$(uptime -p)

# Create the prompt for Claude
cat > /tmp/claude-healthcheck-prompt.txt << EOF
$SYSTEM_PROMPT

## Current Session Context
- **Invoked by**: cron (scheduled health check)
- **Timestamp**: $(date -Iseconds)
- **Previous runs context**: Available below
- **Unresolved issues**: $UNRESOLVED_COUNT
- **System uptime**: $UPTIME
- **Health log path**: $HEALTH_LOG

## Previous Health Checks Context
$CONTEXT

## Your Task

Perform a comprehensive health check following your operational guidelines. Remember to:

1. Check all system resources and services
2. Review logs for errors and patterns
3. Compare with previous health checks for trends
4. Take safe corrective actions when needed
5. Document everything clearly

Write your health check report to: $HEALTH_LOG

The report should follow the format specified in your system prompt. Be thorough but concise. Focus on actionable information.

Remember: You have full system access. You are trusted to keep this server healthy.
EOF

# Run Claude Code with the health check prompt
echo "Running ClaudeOps health check at $(date)..."
claude chat --no-stream < /tmp/claude-healthcheck-prompt.txt

# Clean up
rm -f /tmp/claude-healthcheck-prompt.txt

echo "Health check completed. Report saved to: $HEALTH_LOG"