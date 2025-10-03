# ClaudeOps Slash Commands

Custom slash commands allow direct interaction with the ClaudeOps server through Claude Code's interface. These commands provide instant access to system health, logs, and diagnostics.

## Available Commands

### 1. `/system-health`
**Purpose:** Run a comprehensive health check of the server

**What it does:**
- Executes `claudeops check` on the remote server
- Provides real-time system diagnostics
- Checks services, databases, endpoints, and resources
- Returns a detailed markdown report

**Usage:**
```
/system-health
```

**Example output:**
```markdown
# Health Check Report - 2025-10-02 14:30

## System Status: 🟢 GREEN

### Services
- ✅ PostgreSQL: Running, 15 connections
- ✅ Frontend: Responding on port 3006
- ✅ Indexer: Running normally

### Resources
- CPU: 25% used
- Memory: 45% used (5.5GB free)
- Disk: 30% used (70GB free)
```

---

### 2. `/system-status`
**Purpose:** Quick system overview and status

**What it does:**
- Runs `claudeops status` for a snapshot view
- Shows service states and recent issues
- Faster than full health check
- Ideal for quick monitoring

**Usage:**
```
/system-status
```

---

### 3. `/system-logs`
**Purpose:** View recent ClaudeOps logs

**What it does:**
- Displays recent health check logs
- Shows historical context and trends
- Useful for debugging recurring issues
- Includes action logs and issue reports

**Usage:**
```
/system-logs
```

---

### 4. `/system-services`
**Purpose:** Check status of all system services

**What it does:**
- Lists all systemd services
- Shows docker containers
- Displays PM2 processes
- Provides service-specific diagnostics

**Usage:**
```
/system-services
```

---

### 5. `/system-restart <service>`
**Purpose:** Restart a specific service (with safety checks)

**What it does:**
- Safely restarts the specified service
- Validates service name before execution
- Logs the restart action
- Verifies service started successfully

**Usage:**
```
/system-restart postgresql
/system-restart nginx
/system-restart app
```

**Safety features:**
- Validates service exists before restarting
- Requires confirmation for critical services
- Logs all restart actions
- Checks service health after restart

---

## How Slash Commands Work

### Architecture

```
┌──────────────┐      SSH      ┌────────────────┐
│ Claude Code  │  ─────────────>│ ClaudeOps      │
│ (Local)      │                 │ Server         │
└──────────────┘                 └────────────────┘
       │                                  │
       │ Reads command                    │
       ▼                                  ▼
┌──────────────┐                 ┌────────────────┐
│ ~/.claude/   │                 │ Execute:       │
│ slash_cmds/  │                 │ claudeops check│
└──────────────┘                 └────────────────┘
```

### Components

1. **Command Definition Files**
   - Location: `~/.claude/slash_commands/`
   - Format: JSON files defining command behavior
   - Synced from `/opt/claudeops/slash_commands/`

2. **SSH Wrapper**
   - Script: `/opt/claudeops/bin/claude-shell.sh`
   - Authenticates as `claudeops` user
   - Executes commands with appropriate permissions
   - Returns formatted output

3. **Sync Script**
   - Script: `/opt/claudeops/bin/sync-slash-commands.sh`
   - Copies command definitions to local machine
   - Updates when new commands are added
   - Runs automatically on deployment

---

## Creating New Slash Commands

### Step 1: Create Command Definition

Create a JSON file in `/opt/claudeops/slash_commands/`:

```json
{
  "name": "system-backup",
  "description": "Create a system backup",
  "instruction": "SSH to 65.21.67.254 as claudeops user and run: /opt/claudeops/bin/backup.sh",
  "context": {
    "type": "server-management",
    "permissions": "claudeops user",
    "safety": "Creates backup in /var/backups/claudeops/"
  }
}
```

### Step 2: Create the Script (if needed)

If your command requires a custom script:

```bash
#!/bin/bash
# /opt/claudeops/bin/backup.sh

BACKUP_DIR="/var/backups/claudeops"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup-$TIMESTAMP.tar.gz" /opt/claudeops/config
echo "Backup created: backup-$TIMESTAMP.tar.gz"
```

### Step 3: Sync to Claude Code

Run the sync script to make the command available:

```bash
/opt/claudeops/bin/sync-slash-commands.sh
```

Or manually copy:

```bash
cp /opt/claudeops/slash_commands/*.json ~/.claude/slash_commands/
```

### Step 4: Test the Command

In Claude Code:
```
/system-backup
```

---

## Command Best Practices

### Security
- ✅ Always use the `claudeops` user (limited permissions)
- ✅ Validate input parameters
- ✅ Log all actions
- ❌ Never run commands as root unnecessarily
- ❌ Avoid exposing sensitive data in output

### Design
- ✅ Clear, descriptive command names
- ✅ Single responsibility per command
- ✅ Idempotent operations when possible
- ✅ Human-readable output
- ❌ Avoid complex multi-step operations

### Error Handling
- ✅ Check if service/file exists before acting
- ✅ Provide clear error messages
- ✅ Return non-zero exit codes on failure
- ✅ Include troubleshooting hints

---

## Storage Locations

### Server (Production)
```
/opt/claudeops/slash_commands/    # Command definitions (JSON)
/opt/claudeops/bin/               # Command scripts
~/.claude/slash_commands/         # Synced to claudeops user
```

### Local (Development)
```
~/.claude/slash_commands/         # Local command definitions
```

---

## Sync Script

The sync script (`/opt/claudeops/bin/sync-slash-commands.sh`) handles:

1. **Automatic Deployment**
   - Runs during `deploy-to-server.sh`
   - Copies all command definitions to server
   - Installs to claudeops user's home

2. **Manual Sync**
   ```bash
   # On server
   /opt/claudeops/bin/sync-slash-commands.sh

   # Or from local machine
   ssh claudeops@65.21.67.254 '/opt/claudeops/bin/sync-slash-commands.sh'
   ```

3. **Bidirectional Support**
   - Server → Local: Download latest commands
   - Local → Server: Push new command definitions

---

## Troubleshooting

### Command Not Found
```bash
# Check if command definition exists
ls ~/.claude/slash_commands/

# Verify command JSON is valid
cat ~/.claude/slash_commands/system-health.json | jq .

# Re-sync commands
/opt/claudeops/bin/sync-slash-commands.sh
```

### Permission Denied
```bash
# Verify claudeops user permissions
ssh claudeops@65.21.67.254 'groups'

# Check script permissions
ssh claudeops@65.21.67.254 'ls -l /opt/claudeops/bin/'

# Add to sudoers if needed (careful!)
sudo visudo -f /etc/sudoers.d/claudeops
```

### SSH Connection Issues
```bash
# Test SSH access
ssh claudeops@65.21.67.254 'echo "Connected"'

# Verify SSH key
ls ~/.ssh/id_*

# Check authorized_keys
ssh claudeops@65.21.67.254 'cat ~/.ssh/authorized_keys'
```

---

## Future Enhancements

- [ ] Command parameters and arguments
- [ ] Interactive commands with user input
- [ ] Command aliases
- [ ] Command categories/grouping
- [ ] Auto-completion
- [ ] Command history and logging
- [ ] Rate limiting for destructive commands
- [ ] Multi-server support

---

*Last updated: 2025-10-02*
