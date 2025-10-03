# ClaudeOps Custom Slash Commands

Complete documentation for ClaudeOps custom slash commands.

## Overview

ClaudeOps includes 5 custom slash commands for server administration. These commands are available in all Claude Code sessions (SSH, manual, or automated).

## Available Commands

### `/system-status`
**Quick system overview dashboard**

Shows in one screen:
- Hostname and uptime
- CPU load, memory usage, disk usage
- Critical services status (nginx, ssh, cron)
- Last automated health check result

**Usage:**
```
/system-status
```

**Output Format:**
```
🖥️  System: [hostname] - Uptime: [time]
📊 Resources: CPU [load] | Memory [%] | Disk [%]
⚙️  Services: [status of nginx, ssh, cron]
🕐 Last Health Check: [timestamp] - Status: [GREEN/YELLOW/RED]
```

---

### `/system-health`
**Run immediate comprehensive health check**

Performs full health analysis:
- System resources (CPU, memory, disk)
- Critical services status
- Recent error logs (last hour)
- Comparison to baseline from state.json

**Usage:**
```
/system-health
```

**Output:** Detailed health report with overall status indicator (🟢 GREEN / 🟡 YELLOW / 🔴 RED)

**When to use:** 
- When you suspect an issue
- Before/after making changes
- To verify system health on-demand

---

### `/system-logs`
**View recent ClaudeOps logs and reports**

Displays:
- List of 5 most recent health reports
- Summary of latest health report
- Recent cron execution logs
- Current unresolved issues from state.json

**Usage:**
```
/system-logs
```

**When to use:**
- Reviewing what ClaudeOps has been doing
- Checking for recurring issues
- Understanding system trends

---

### `/system-services`
**List all services and their status**

Shows comprehensive service information:
- All active/running services
- Any failed services (RED flag)
- ClaudeOps tracked services (nginx, postgresql, redis, pm2)
- Resource usage by key services

**Usage:**
```
/system-services
```

**When to use:**
- Checking if all expected services are running
- Finding failed services
- Monitoring service resource usage

---

### `/system-restart <service-name>`
**Safely restart a system service**

Restarts a service with comprehensive safety checks:
1. Verifies service exists
2. Shows current status
3. Asks confirmation for critical services
4. Performs restart
5. Verifies restart succeeded
6. Logs action to `/var/log/claudeops/manual-actions.log`

**Usage:**
```
/system-restart nginx
/system-restart postgresql
/system-restart pm2
```

**Safety Features:**
- Requires confirmation before restarting critical services (nginx, ssh, postgresql, redis, pm2)
- Warns about potential impact
- Verifies restart was successful
- Logs all manual restart actions

**When to use:**
- Service is hung/unresponsive
- After configuration changes
- When instructed by error messages

---

## Technical Details

### Storage Locations

Commands are stored in three locations to ensure universal availability:

1. **Original Source:**
   - `/home/claude/.claude/commands/system-*.md`
   - Owned by: claude:claude

2. **SSH User (claudeops):**
   - `/home/claudeops/.claude/commands/system-*.md`
   - Owned by: claudeops:claudeops

3. **Root User (for cron/systemd):**
   - `/root/.claude/commands/system-*.md`
   - Owned by: root:root

### Command Format

Each command is a Markdown file with frontmatter:

```markdown
---
description: Command description shown in help
---

Instructions for Claude when command is invoked...

Bash commands to run:
```bash
command here
```

Formatting instructions for output...
```

### Arguments

Commands support arguments using:
- `$1` - First argument
- `$2` - Second argument
- `$ARGUMENTS` - All arguments as string

Example: `/system-restart nginx` → `$1` = "nginx"

---

## Maintenance

### Adding New Commands

To create a new system command:

1. **Create the command file:**
   ```bash
   nano ~/.claude/commands/system-<name>.md
   ```

2. **Add frontmatter and content:**
   ```markdown
   ---
   description: Your command description
   ---

   Command instructions here...
   ```

3. **Sync to all users:**
   ```bash
   sudo /opt/claudeops/sync-commands.sh
   ```

4. **Test the command:**
   ```
   /system-<name>
   ```

### Updating Existing Commands

1. Edit the source file in `/home/claude/.claude/commands/`
2. Run sync script: `sudo /opt/claudeops/sync-commands.sh`
3. Reload may be needed (exit/reconnect SSH session)

### Sync Script

Location: `/opt/claudeops/sync-commands.sh`

**Purpose:** Copies all `system-*.md` commands from claude's home to claudeops and root users

**When to run:**
- After creating new commands
- After updating existing commands
- If commands are missing from a user

**Usage:**
```bash
sudo /opt/claudeops/sync-commands.sh
```

---

## Troubleshooting

### Commands Not Showing Up

1. **Verify files exist:**
   ```bash
   ls -la ~/.claude/commands/system-*.md
   ```

2. **Check permissions:**
   ```bash
   ls -la ~/.claude/commands/
   # Should be readable by current user
   ```

3. **Reconnect SSH session:**
   - Commands are loaded on Claude Code startup
   - Exit and reconnect to reload

4. **Try tab completion:**
   - Type `/system-` and press Tab
   - Should show all 5 commands

5. **Check Claude Code version:**
   ```bash
   claude --version
   ```
   - Should be 2.0.1 or newer

### Command Fails to Execute

1. **Check bash command syntax** in the .md file
2. **Verify permissions** for commands that need sudo
3. **Check logs** in command output for error messages
4. **Test bash commands manually** before adding to command file

---

## Integration with ClaudeOps

These slash commands complement the automated ClaudeOps system:

**Automated (Every 2 Hours):**
- Cron runs `/opt/claudeops/health-check.sh`
- Performs full health check
- Commits logs to GitHub
- Takes autonomous safe actions

**On-Demand (Slash Commands):**
- `/system-health` - Manual health check
- `/system-status` - Quick status check
- `/system-logs` - Review automated runs
- `/system-services` - Service monitoring
- `/system-restart` - Manual interventions

**On Boot:**
- Systemd runs `/opt/claudeops/boot-recovery.sh`
- Checks why system restarted
- Verifies services started correctly
- Commits report to GitHub

---

## Examples

### Daily Operations

**Morning check:**
```
/system-status
```

**Investigating an issue:**
```
/system-health
/system-logs
/system-services
```

**Restarting a service after config change:**
```
/system-restart nginx
```

**Checking recent automated activity:**
```
/system-logs
```

### Emergency Response

**System feels slow:**
```
/system-health
# Check CPU, memory, disk usage
# Look for resource hogs
```

**Service is down:**
```
/system-services
# Find which service failed
/system-restart <service-name>
# Restart it
```

**After unexpected reboot:**
```
/system-logs
# Check boot recovery report
/system-services
# Verify all services are up
```

---

## Security Notes

- Commands run as the user who invoked them
- `/system-restart` uses sudo (requires appropriate permissions)
- Critical service restarts require confirmation
- All manual actions logged to `/var/log/claudeops/manual-actions.log`
- Commands are stored in user home directories (not system-wide)

---

## See Also

- ClaudeOps System Prompt: `/home/claude/CLAUDE.md`
- Health Check Script: `/opt/claudeops/health-check.sh`
- Boot Recovery Script: `/opt/claudeops/boot-recovery.sh`
- SSH Access Documentation: `/opt/claudeops/SSH_ACCESS.md`
- GitHub Logs Repository: https://github.com/dennisonbertram/claudeops-logs

---

**Created:** October 2, 2025  
**Version:** 1.0  
**Status:** ✅ Active and tested  
**Location:** `/opt/claudeops/SLASH_COMMANDS.md`
