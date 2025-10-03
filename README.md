# ClaudeOps - Autonomous Server Administration System

⚠️ **VALIDATION STATUS** ⚠️  
**Last Validated:** 2025-10-03  
**Status:** ✅ 85% validated on Docker container  
**Installation Guide:** Use `/opt/claudeops/INSTALL-VALIDATED.md` (tested)  

---

An AI-powered autonomous server administrator running on Ubuntu 24.04.


## Overview

ClaudeOps is an autonomous system that monitors server health, diagnoses issues, and takes safe corrective actions automatically. It runs via cron (every 2 hours) and systemd (on boot), with all activity logged to GitHub.

**Server:** 65.21.67.254 (Hetzner)  
**Hostname:** Ubuntu-2404-noble-amd64-base  
**OS:** Ubuntu 24.04 Noble  

## Quick Start

### SSH Access to Claude

Connect directly to an interactive Claude Code session:

```bash
ssh claudeops@65.21.67.254
```

Password: `ClaudeOps2025!`

When connected, you're talking directly to Claude - no need to type commands to launch it.

### Slash Commands

Once connected (or in any Claude Code session), use these commands:

- `/system-status` - Quick system overview
- `/system-health` - Full health check
- `/system-logs` - View recent logs and reports
- `/system-services` - List all services
- `/system-restart <service>` - Safely restart a service

See: `/opt/claudeops/SLASH_COMMANDS.md`

## Architecture

### Automated Components

**Health Checks (Every 2 Hours)**
- Script: `/opt/claudeops/health-check.sh`
- Cron: `/etc/cron.d/claudeops-health-check`
- Checks: CPU, memory, disk, services, logs, security updates
- Actions: Restarts hung services, clears temp files, fixes permissions
- Output: `/var/log/claudeops/health-report-*.md`

**Boot Recovery (On Startup)**
- Script: `/opt/claudeops/boot-recovery.sh`
- Service: `claudeops-boot.service`
- Checks: Why system restarted, service dependencies
- Actions: Starts services in correct order, verifies health
- Output: `/var/log/claudeops/boot-recovery-*.md`

**Git Integration**
- Repository: https://github.com/dennisonbertram/claudeops-logs
- All logs automatically committed and pushed
- Token stored securely at: `/opt/claudeops/.github-token`

### Key Files

```
/opt/claudeops/
├── health-check.sh          # Automated health check script
├── boot-recovery.sh         # Boot recovery script
├── claude-shell.sh          # SSH wrapper for direct Claude access
├── sync-commands.sh         # Sync slash commands to all users
├── .github-token            # GitHub PAT (root:root 400)
├── SSH_ACCESS.md            # SSH documentation
└── SLASH_COMMANDS.md        # Slash commands documentation

/home/claude/
└── CLAUDE.md                # ClaudeOps system prompt

/var/log/claudeops/
├── health-report-*.md       # Health check reports
├── health-check-*.log       # Execution logs
├── boot-recovery-*.md       # Boot recovery reports
├── boot-recovery-*.log      # Boot recovery logs
├── state.json               # System state and tracking
└── manual-actions.log       # Manual intervention log

/home/claude/.claude/commands/    # Slash commands (source)
/home/claudeops/.claude/commands/ # Slash commands (SSH user)
/root/.claude/commands/           # Slash commands (root)
```

## System State Tracking

ClaudeOps maintains state in `/var/log/claudeops/state.json`:

- **Baseline metrics** - CPU, memory, disk from first run
- **Health history** - Last N health checks with status
- **Known services** - nginx, postgresql, redis, pm2 tracking
- **Unresolved issues** - Persistent problems being monitored
- **Trends** - Resource usage trends over time

This allows ClaudeOps to:
- Detect abnormal behavior (memory leak, disk filling up)
- Track recurring issues
- Make informed decisions based on history

## Safety Features

### Autonomous Actions (Safe - Auto-Execute)
- Restart hung services
- Clear temporary files when disk is full
- Restart applications with memory leaks
- Fix file permissions
- Clear application caches
- Restart database connections

### Risky Actions (Documented Only)
- System updates/upgrades
- Firewall rule changes
- Database migrations
- Configuration changes to production services
- Deletion of user data
- Network interface changes

## Maintenance

### View Recent Activity

```bash
# SSH method
ssh claudeops@65.21.67.254
/system-logs

# Direct method
cat /var/log/claudeops/state.json
ls -lt /var/log/claudeops/health-report-*.md | head -5
```

### Manual Health Check

```bash
ssh claudeops@65.21.67.254
/system-health

# Or directly:
sudo /opt/claudeops/health-check.sh
```

### Check Next Scheduled Run

```bash
# View cron job
cat /etc/cron.d/claudeops-health-check

# Check cron logs
journalctl -u cron | tail -20
```

### Add New Slash Commands

1. Create command file:
   ```bash
   nano ~/.claude/commands/system-mynewcommand.md
   ```

2. Sync to all users:
   ```bash
   sudo /opt/claudeops/sync-commands.sh
   ```

3. Reconnect and test:
   ```bash
   /system-mynewcommand
   ```

## Monitoring

### GitHub Logs
All activity is logged to GitHub: https://github.com/dennisonbertram/claudeops-logs

### Local Logs
```bash
# Recent health checks
ls -lt /var/log/claudeops/health-report-*.md | head -5

# Current state
cat /var/log/claudeops/state.json | jq .

# Unresolved issues
cat /var/log/claudeops/state.json | jq .unresolved_issues

# Manual actions
tail /var/log/claudeops/manual-actions.log
```

## Documentation

- **System Prompt:** `/home/claude/CLAUDE.md` - ClaudeOps identity and responsibilities
- **SSH Access:** `/opt/claudeops/SSH_ACCESS.md` - How to connect directly to Claude
- **Slash Commands:** `/opt/claudeops/SLASH_COMMANDS.md` - Complete command reference
- **This File:** `/opt/claudeops/README.md` - Architecture overview

## Troubleshooting

### Health Checks Not Running

```bash
# Check cron is active
systemctl status cron

# Check cron job syntax (should be ONLY this one)
cat /etc/cron.d/claudeops-health-check

# Verify no duplicate cron jobs exist
sudo crontab -l  # Should show "no crontab for root"

# View cron logs
journalctl -u cron -n 50

# Test manually (runs as current user, needs ~6 minutes to complete)
/opt/claudeops/health-check.sh
```

**Note:** There should be only ONE cron job: `/etc/cron.d/claudeops-health-check` running as user `claude`. If you find a duplicate in root's crontab, remove it with `sudo crontab -r`.

### SSH Access Not Working

```bash
# Check user exists
id claudeops

# Check shell is correct
grep claudeops /etc/passwd
# Should show: /opt/claudeops/claude-shell.sh

# Test shell wrapper
sudo -u claudeops /opt/claudeops/claude-shell.sh

# Check SSH is running
systemctl status ssh
```

### Slash Commands Not Showing

```bash
# Check commands exist
ls -la ~/.claude/commands/system-*.md

# Sync commands
sudo /opt/claudeops/sync-commands.sh

# Reconnect SSH session (commands load on startup)
```

### Git Push Failing

```bash
# Check token exists
sudo ls -la /opt/claudeops/.github-token

# Test GitHub access
curl -H "Authorization: Bearer $(sudo cat /opt/claudeops/.github-token)" \
  https://api.github.com/repos/dennisonbertram/claudeops-logs

# Check git config (runs as claude user)
cd /var/log/claudeops && git remote -v

# Verify git permissions
ls -ld /var/log/claudeops/
ls -ld /var/log/claudeops/.git/
# Both should be owned by claude:claude

# Test git operations as claude user
cd /var/log/claudeops && git status && git pull
```

## System Status

**Current Status:** 🟢 GREEN (As of last health check)

- **CPU:** 0.42 load average (normal)
- **Memory:** 2.6% used (1.6GB / 62GB)
- **Disk:** 1% used (4.1GB / 436GB)
- **Services:** All running (nginx, ssh, cron)
- **Uptime:** 22+ hours

## Contributing / Modifying

To modify ClaudeOps behavior:

1. **Update system prompt:** Edit `/home/claude/CLAUDE.md`
2. **Modify health checks:** Edit `/opt/claudeops/health-check.sh`
3. **Modify boot recovery:** Edit `/opt/claudeops/boot-recovery.sh`
4. **Add slash commands:** Create in `~/.claude/commands/` and sync
5. **Change schedule:** Edit `/etc/cron.d/claudeops-health-check`

After changes, test manually before waiting for cron:
```bash
sudo /opt/claudeops/health-check.sh
```

---

**Created:** October 2, 2025  
**Version:** 1.0  
**Maintainer:** ClaudeOps (Autonomous AI)  
**Contact:** SSH to claudeops@65.21.67.254
