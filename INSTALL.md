# ClaudeOps Installation Guide

⚠️ **STATUS: UNVALIDATED SCAFFOLD** ⚠️

This document was created by reverse-engineering an existing ClaudeOps installation.
**IT HAS NOT BEEN TESTED ON A FRESH SYSTEM.**

**Before using this guide:**
1. Review all steps carefully
2. Test on a VM first
3. Document any corrections needed
4. Update this file with validated steps

**Validation Status:** 🔴 NOT TESTED - Use at your own risk

---

## Overview

ClaudeOps is an autonomous server administration system powered by Claude Code that:
- Monitors server health every 2 hours via cron
- Performs boot recovery checks via systemd
- Logs all activity to GitHub
- Provides slash commands for manual operations

**Target OS:** Ubuntu 24.04 (should work on 22.04+ and Debian)
**Required Access:** Root/sudo privileges
**Installation Time:** ~20-30 minutes (estimated, unvalidated)

---

## Validation Plan

Yes, it's absolutely reasonable to spin up a VM and test this! Recommended approach:

1. **Create Ubuntu 24.04 VM** (DigitalOcean, AWS, local VirtualBox, etc.)
2. **Follow this guide step-by-step** as written
3. **Document everything:**
   - Commands that fail
   - Missing dependencies
   - Permission issues
   - Timing problems
   - Unclear instructions
4. **Update this document** with corrections
5. **Repeat until clean installation** achieved
6. **Mark as VALIDATED** ✅

---

## Prerequisites

### 1. System Requirements
```bash
# Verify OS version
lsb_release -a
# Should show: Ubuntu 24.04 or similar

# Verify sudo access
sudo whoami
# Should show: root
```

### 2. Install Node.js via NVM

**⚠️ VALIDATION NEEDED:** Confirm this is the correct path and method

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Install Node.js 22.x
nvm install 22.20.0
nvm use 22.20.0
nvm alias default 22.20.0

# Verify installation
node --version  # Should show: v22.20.0
which node      # Record the path - may differ from /opt/nvm/...
```

**Critical:** Note the actual path from `which node` - you'll need to update all scripts if it differs from `/opt/nvm/versions/node/v22.20.0/bin/node`

### 3. Install Claude Code CLI

**⚠️ VALIDATION NEEDED:** Confirm package name and installation method

```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# Set API key (required)
export ANTHROPIC_API_KEY="your-api-key-here"
# Add to ~/.bashrc or /etc/environment for persistence
```

### 4. Prepare GitHub Repository

1. Create new repo: https://github.com/new
   - Name: `claudeops-logs` (or your choice)
   - Visibility: Private (recommended)
   
2. Create Personal Access Token: https://github.com/settings/tokens/new
   - Scopes: `repo` (full control)
   - Copy token - needed in Step 6

---

## Installation Steps

### Step 1: Create Users

```bash
# Create operational user
sudo useradd -m -s /bin/bash claude
sudo passwd claude

# Create SSH user (we'll change shell later)
sudo useradd -m -s /bin/bash claudeops
sudo passwd claudeops  # Suggested: ClaudeOps2025!

# Verify
id claude
id claudeops
```

### Step 2: Create Directory Structure

```bash
# Main directory
sudo mkdir -p /opt/claudeops/{bin,config,lib,prompts,docs}

# Log directory
sudo mkdir -p /var/log/claudeops/{health,boot,issues,actions}

# Set ownership
sudo chown -R root:root /opt/claudeops
sudo chown -R claude:claude /var/log/claudeops

# Verify
ls -la /opt/claudeops/
ls -la /var/log/claudeops/
```

### Step 3: Download/Create Documentation

**⚠️ VALIDATION BLOCKER:** Need source for these files

Options:
A. Clone from template repo (provide URL)
B. Include full content in this guide
C. Generate during first run

Required files in `/opt/claudeops/`:
- `CLAUDE.md` (~250 lines)
- `README.md` (~300 lines)
- `SLASH_COMMANDS.md` (~370 lines)
- `SSH_ACCESS.md` (~35 lines)

Placeholder:
```bash
# TODO: Provide download method
# Example: git clone https://github.com/org/claudeops-docs /tmp/docs
# sudo cp /tmp/docs/*.md /opt/claudeops/
```

Copy CLAUDE.md to claude home:
```bash
sudo cp /opt/claudeops/CLAUDE.md /home/claude/CLAUDE.md
sudo chown claude:claude /home/claude/CLAUDE.md
```

### Step 4: Create Scripts

**NOTE:** Scripts reference Node path `/opt/nvm/versions/node/v22.20.0/bin/node` - update if yours differs!

**4a. Health Check Script** (`/opt/claudeops/health-check.sh`)

Refer to existing file at `/opt/claudeops/health-check.sh` - it's ~80 lines.

```bash
# Copy from existing system OR create from template
# Key points to verify:
# - Node.js path is correct
# - Runs as claude user
# - Git commands work (no sudo needed)
# - Takes ~6 minutes to complete

sudo cp /path/to/health-check.sh /opt/claudeops/
sudo chown claude:claude /opt/claudeops/health-check.sh
sudo chmod 755 /opt/claudeops/health-check.sh
```

**⚠️ VALIDATION NEEDED:** Include full script content or provide download URL

**4b. Boot Recovery Script** (`/opt/claudeops/boot-recovery.sh`)

**CRITICAL FIX NEEDED:** Current version has git permission bug. Use this corrected version:

```bash
sudo tee /opt/claudeops/boot-recovery.sh > /dev/null << 'SCRIPT_EOF'
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

export PATH="/opt/nvm/versions/node/v22.20.0/bin:$PATH"

log "Invoking Claude Code for boot recovery checks..."

/opt/nvm/versions/node/v22.20.0/bin/claude << 'CLAUDE_EOF'
You are ClaudeOps, running in boot recovery mode. Your task is to:

1. Check why the system restarted
2. Verify all services are healthy
3. Perform system health checks
4. Document findings to /var/log/claudeops/boot-recovery-report-$(date +%Y%m%d-%H%M%S).md
5. Take safe corrective actions if needed
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
SCRIPT_EOF

sudo chmod 755 /opt/claudeops/boot-recovery.sh
```

**4c. SSH Shell Wrapper** (`/opt/claudeops/claude-shell.sh`)

```bash
sudo tee /opt/claudeops/claude-shell.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash

export PATH="/opt/nvm/versions/node/v22.20.0/bin:$PATH"

echo "================================================"
echo "  Welcome to ClaudeOps Interactive Shell"
echo "  Connected to: $(hostname)"
echo "  Date: $(date)"
echo "================================================"
echo ""
echo "You are now talking directly to Claude."
echo "Type 'exit' or Ctrl+D to disconnect."
echo ""

exec /opt/nvm/versions/node/v22.20.0/bin/claude
SCRIPT_EOF

sudo chmod 755 /opt/claudeops/claude-shell.sh
```

**4d. Sync Commands Script** (`/opt/claudeops/sync-commands.sh`)

```bash
sudo tee /opt/claudeops/sync-commands.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash

echo "Syncing ClaudeOps slash commands..."

SOURCE="/home/claude/.claude/commands"
TARGETS=(
    "/home/claudeops/.claude/commands"
    "/root/.claude/commands"
)

for target in "${TARGETS[@]}"; do
    echo "Syncing to: $target"
    mkdir -p "$target"
    cp "$SOURCE"/system-*.md "$target/" 2>/dev/null || true

    if [[ "$target" == "/root/.claude/commands" ]]; then
        chown -R root:root "$target"
    elif [[ "$target" == "/home/claudeops/.claude/commands" ]]; then
        chown -R claudeops:claudeops "$target"
    fi
done

echo "✅ Commands synced"
SCRIPT_EOF

sudo chown claude:claude /opt/claudeops/sync-commands.sh
sudo chmod 755 /opt/claudeops/sync-commands.sh
```

### Step 5: Create Slash Commands

**⚠️ VALIDATION BLOCKER:** Need full content for all 5 command files

```bash
# Create directory
sudo -u claude mkdir -p /home/claude/.claude/commands

# Create 5 command files:
# - system-status.md
# - system-health.md
# - system-logs.md
# - system-services.md
# - system-restart.md

# TODO: Provide full content or download method
```

Example structure for system-status.md:
```markdown
---
description: Show quick system status summary
---

Instructions for Claude...
bash commands...
formatting guidelines...
```

### Step 6: Setup Git Repository

```bash
# Switch to claude user
sudo su - claude

cd /var/log/claudeops
git init
git config user.email "claudeops@yourdomain.com"
git config user.name "ClaudeOps"

echo "# ClaudeOps Logs" > README.md
git add README.md
git commit -m "Initial commit"

# Add remote (replace YOUR_PAT_TOKEN)
git remote add origin https://YOUR_PAT_TOKEN@github.com/username/claudeops-logs.git
git branch -M main
git push -u origin main

exit

# Store token reference
echo "YOUR_PAT_TOKEN" | sudo tee /opt/claudeops/.github-token
sudo chmod 400 /opt/claudeops/.github-token
sudo chown root:root /opt/claudeops/.github-token
```

**⚠️ VALIDATION NEEDED:** Confirm embedded token method works

### Step 7: Install Systemd Service

```bash
sudo tee /etc/systemd/system/claudeops-boot.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=ClaudeOps Boot Recovery Service
Documentation=file:///home/claude/CLAUDE.md
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/claudeops/boot-recovery.sh
StandardOutput=journal
StandardError=journal
TimeoutStartSec=600
RemainAfterExit=no
User=root
Group=root
Restart=no

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo systemctl daemon-reload
sudo systemctl enable claudeops-boot.service

# Verify (should show "loaded" and "enabled")
sudo systemctl status claudeops-boot.service
```

### Step 8: Install Cron Job

```bash
sudo tee /etc/cron.d/claudeops-health-check > /dev/null << 'CRON_EOF'
0 */2 * * * claude /opt/claudeops/health-check.sh
CRON_EOF

sudo chmod 644 /etc/cron.d/claudeops-health-check

# Verify syntax
cat /etc/cron.d/claudeops-health-check
```

### Step 9: Update SSH Shell

```bash
# Now that claude-shell.sh exists, update shell
sudo usermod -s /opt/claudeops/claude-shell.sh claudeops

# Verify
grep claudeops /etc/passwd
# Should show: /opt/claudeops/claude-shell.sh
```

### Step 10: Sync Commands

```bash
sudo /opt/claudeops/sync-commands.sh

# Verify
ls -la /home/claudeops/.claude/commands/
ls -la /root/.claude/commands/
```

### Step 11: Initialize State

```bash
sudo -u claude tee /var/log/claudeops/state.json > /dev/null << 'STATE_EOF'
{
  "last_run": {
    "timestamp": "never",
    "type": "manual",
    "status": "pending",
    "overall_health": "unknown",
    "duration_seconds": 0
  },
  "system_baseline": {},
  "health_history": [],
  "known_services": {},
  "unresolved_issues": [],
  "trends": {},
  "system_info": {},
  "metadata": {
    "claudeops_version": "1.0",
    "first_run": "pending",
    "total_runs": 0
  }
}
STATE_EOF
```

---

## Testing & Validation

### Test 1: User Accounts
```bash
id claude && echo "✓"
id claudeops && echo "✓"
```

### Test 2: SSH Access
```bash
ssh claudeops@localhost
# Should launch Claude
# Try: /system-status
# Exit
```

### Test 3: Manual Health Check
```bash
sudo su - claude
/opt/claudeops/health-check.sh
# Wait ~6 minutes
ls -lt /var/log/claudeops/health-*.log | head -1
```

### Test 4: Git Integration
```bash
sudo su - claude
cd /var/log/claudeops
git log -1
git status
```

### Test 5: Cron (wait for 2-hour mark)
```bash
sudo journalctl -u cron -f
```

### Test 6: Boot Recovery
```bash
sudo reboot
# After reboot:
sudo journalctl -u claudeops-boot.service
```

---

## Troubleshooting

### "claude: command not found"
Update PATH in scripts to match your Node installation

### Git permission errors
```bash
sudo chown -R claude:claude /var/log/claudeops/
```

### Cron not running
```bash
sudo systemctl status cron
sudo journalctl -u cron -n 50
```

---

## Validation Checklist

- [ ] Fresh VM created
- [ ] All prerequisites installed
- [ ] All steps completed without errors
- [ ] Health check runs successfully
- [ ] Git commits work
- [ ] SSH access works
- [ ] Slash commands work
- [ ] Cron executes on schedule
- [ ] Boot recovery works
- [ ] 24-hour stability test

---

## Document Status

**Version:** 0.1-SCAFFOLD  
**Created:** 2025-10-03  
**Status:** 🔴 UNVALIDATED  
**Tested:** Never

**To Validate:**
1. Spin up Ubuntu 24.04 VM
2. Follow guide completely
3. Document all issues
4. Fix and iterate
5. Update this document
6. Mark validated

---

**Ready for VM validation testing?**
