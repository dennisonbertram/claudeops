#!/bin/bash

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_DIR="/var/log/claudeops"
LOG_FILE="$LOG_DIR/boot-recovery-$(date '+%Y%m%d-%H%M%S').log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "ClaudeOps Boot Recovery Script Starting"
log "=========================================="

log "Waiting 30 seconds for system to stabilize..."
sleep 30

# Load NVM and set PATH - try both user and root locations
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if [ ! -f "$NVM_DIR/nvm.sh" ]; then
    export NVM_DIR="/home/claude/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

export PATH="$NVM_DIR/versions/node/v22.20.0/bin:$PATH"

log "Invoking Claude Code for boot recovery checks..."

claude << 'CLAUDE_EOF'
You are ClaudeOps, running in boot recovery mode. Your task is to:

1. Check why the system restarted (journalctl, uptime, last)
2. Verify all services are healthy
3. Perform system health checks
4. Document findings to /var/log/claudeops/boot-recovery-report-$(date +%Y%m%d-%H%M%S).md
5. Take safe corrective actions if needed

Read /home/claude/CLAUDE.md for your full context.
CLAUDE_EOF

EXIT_CODE=$?

log "Boot recovery checks completed (exit code: $EXIT_CODE)"

# FIXED: Run git commands as claude user for permissions
cd /var/log/claudeops
sudo -u claude git add boot-recovery-*.md boot-recovery-*.log 2>/dev/null || true
sudo -u claude git commit -m "Boot recovery: $(date)" 2>/dev/null || true
sudo -u claude git pull origin main --rebase 2>/dev/null || true
sudo -u claude git push origin main 2>/dev/null || true

log "=========================================="
log "ClaudeOps Boot Recovery Script Finished"
log "=========================================="

exit $EXIT_CODE
