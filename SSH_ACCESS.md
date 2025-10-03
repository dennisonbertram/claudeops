# SSH Access to ClaudeOps

## Direct Claude Access via SSH

You can SSH directly into a Claude Code session using the dedicated `claudeops` user.

### Usage

```bash
ssh claudeops@your-server-ip
```

This will automatically launch Claude Code and you'll be talking directly to Claude.

### Setup Details

- **User**: claudeops
- **Shell**: /opt/claudeops/claude-shell.sh
- **Purpose**: Direct SSH access to Claude Code interactive session

### Authentication

- Password authentication (set via: sudo passwd claudeops)
- SSH key authentication (add keys to: /home/claudeops/.ssh/authorized_keys)

### Notes

- Type 'exit' or press Ctrl+D to disconnect
- Each SSH session is a fresh Claude conversation
- For automated health checks, use the cron job (runs every 2 hours)
- For manual health checks, run: sudo /opt/claudeops/health-check.sh

Created: $(date)
