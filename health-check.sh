#!/bin/bash

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_DIR="/var/log/claudeops"
LOG_FILE="$LOG_DIR/health-$TIMESTAMP.log"
REPORT_FILE="$LOG_DIR/health-report-$TIMESTAMP.md"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "ClaudeOps Health Check Starting"
log "=========================================="

# Load NVM and set PATH - try multiple locations
export HOME=/home/claude

# Try common NVM locations in order
for nvm_path in "/opt/nvm" "$HOME/.nvm" "/root/.nvm"; do
    if [ -s "$nvm_path/nvm.sh" ]; then
        export NVM_DIR="$nvm_path"
        . "$NVM_DIR/nvm.sh"
        break
    fi
done

# Add node to PATH
export PATH="$NVM_DIR/versions/node/v22.20.0/bin:$PATH"

log "Node path: $(which node)"
log "Node version: $(node --version)"
log "Claude path: $(which claude)"

log "Invoking Claude Code for health check..."

# Invoke Claude with full system context
claude << 'CLAUDE_EOF'
You are ClaudeOps running a scheduled health check. 

Read your CLAUDE.md context from /home/claude/CLAUDE.md and perform:

1. System resource monitoring (CPU, memory, disk)
2. Service status checks
3. Log analysis for errors
4. Compare to previous runs in /var/log/claudeops/
5. Generate health report with status (GREEN/YELLOW/RED)
6. Save report to /var/log/claudeops/health-report-$(date +%Y%m%d-%H%M%S).md
7. Take safe corrective actions if needed

Be thorough and autonomous.
CLAUDE_EOF

EXIT_CODE=$?
log "Health check completed (exit code: $EXIT_CODE)"

# Git commit as claude user
cd /var/log/claudeops
git add health-*.md health-*.log 2>/dev/null || true
git commit -m "Health check: $(date)" 2>/dev/null || true
git pull origin main --rebase 2>/dev/null || true
git push origin main 2>/dev/null || true

log "=========================================="
log "ClaudeOps Health Check Finished"
log "=========================================="

exit $EXIT_CODE
