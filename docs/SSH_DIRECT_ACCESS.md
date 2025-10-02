# SSH Direct Access to ClaudeOps Server

This document describes the direct SSH access setup that allows Claude Code to connect to the ClaudeOps server as the `claudeops` user.

## Overview

The ClaudeOps server has a dedicated `claudeops` user that provides:
- Direct SSH access for Claude Code
- Limited, safe system permissions
- Ability to run diagnostics and monitoring commands
- Logging and auditing of all actions

## Architecture

```
┌─────────────────┐
│  Claude Code    │  Your local machine
│  (Local)        │
└────────┬────────┘
         │ SSH (Key Auth)
         │
         ▼
┌─────────────────┐
│  claudeops user │  Server: 65.21.67.254
│  (Server)       │  User: claudeops
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ClaudeOps      │
│  Commands       │  /opt/claudeops/bin/
│  • check        │
│  • status       │
│  • logs         │
└─────────────────┘
```

---

## Setup Guide

### Server-Side Setup

#### 1. Create the `claudeops` User

```bash
# Create system user
sudo useradd -r -m -d /home/claudeops -s /bin/bash claudeops

# Create SSH directory
sudo mkdir -p /home/claudeops/.ssh
sudo chmod 700 /home/claudeops/.ssh
```

#### 2. Configure SSH Access

```bash
# Add your SSH public key to authorized_keys
sudo tee /home/claudeops/.ssh/authorized_keys <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx your-email@example.com
EOF

# Set proper permissions
sudo chmod 600 /home/claudeops/.ssh/authorized_keys
sudo chown -R claudeops:claudeops /home/claudeops/.ssh
```

#### 3. Grant ClaudeOps Permissions

The `claudeops` user needs access to:
- Read ClaudeOps logs: `/var/log/claudeops/`
- Execute ClaudeOps commands: `/opt/claudeops/bin/`
- Read system status (no sudo needed for basic commands)

```bash
# Add to claudeops group (if it exists)
sudo usermod -aG claudeops claudeops

# Set ACLs for log directory
sudo setfacl -R -m u:claudeops:rx /var/log/claudeops/
sudo setfacl -d -R -m u:claudeops:rx /var/log/claudeops/

# Ensure claudeops can read its own files
sudo chown -R claudeops:claudeops /opt/claudeops/
```

#### 4. Configure Sudoers (Optional, for specific commands)

If you need the `claudeops` user to run specific commands with sudo:

```bash
sudo visudo -f /etc/sudoers.d/claudeops
```

Add restricted sudo access:
```
# ClaudeOps user - limited sudo access
claudeops ALL=(ALL) NOPASSWD: /opt/claudeops/bin/claudeops check
claudeops ALL=(ALL) NOPASSWD: /opt/claudeops/bin/claudeops status
claudeops ALL=(ALL) NOPASSWD: /opt/claudeops/bin/claudeops logs
claudeops ALL=(ALL) NOPASSWD: /bin/systemctl status *
claudeops ALL=(ALL) NOPASSWD: /bin/systemctl restart postgresql
claudeops ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
```

**Important:** Only grant sudo access to specific, safe commands.

---

### Local Setup (Claude Code)

#### 1. Install SSH Key

Ensure your SSH key is installed:

```bash
# Check if you have an SSH key
ls ~/.ssh/id_ed25519

# If not, generate one
ssh-keygen -t ed25519 -C "your-email@example.com"
```

#### 2. Test SSH Connection

```bash
# Test connection
ssh claudeops@65.21.67.254 'echo "Connected successfully"'

# Should output: Connected successfully
```

#### 3. Configure SSH Config (Optional)

Add to `~/.ssh/config`:

```
Host claudeops
    HostName 65.21.67.254
    User claudeops
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now you can connect with just:
```bash
ssh claudeops
```

---

## The claude-shell.sh Wrapper

### Purpose

The `claude-shell.sh` script provides a safe, controlled way for Claude Code to execute commands on the server.

### Location
```
/opt/claudeops/bin/claude-shell.sh
```

### Features

1. **Command Whitelisting**
   - Only allows approved commands
   - Prevents dangerous operations
   - Logs all command executions

2. **Environment Setup**
   - Sets correct PATH
   - Loads necessary environment variables
   - Ensures proper permissions

3. **Error Handling**
   - Validates commands before execution
   - Provides clear error messages
   - Returns appropriate exit codes

4. **Logging**
   - Logs all commands to `/var/log/claudeops/claude-shell.log`
   - Includes timestamp and user
   - Helps with auditing and debugging

### Example Implementation

```bash
#!/bin/bash
# /opt/claudeops/bin/claude-shell.sh

# Logging
LOG_FILE="/var/log/claudeops/claude-shell.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log the command
echo "[$TIMESTAMP] Command: $*" >> "$LOG_FILE"

# Whitelist of allowed commands
ALLOWED_COMMANDS=(
    "claudeops check"
    "claudeops status"
    "claudeops logs"
    "systemctl status"
    "docker ps"
    "pm2 list"
)

# Validate command
COMMAND="$*"
ALLOWED=false

for allowed_cmd in "${ALLOWED_COMMANDS[@]}"; do
    if [[ "$COMMAND" == "$allowed_cmd"* ]]; then
        ALLOWED=true
        break
    fi
done

if [ "$ALLOWED" = false ]; then
    echo "Error: Command not allowed: $COMMAND"
    echo "[$TIMESTAMP] DENIED: $COMMAND" >> "$LOG_FILE"
    exit 1
fi

# Execute command
eval "$COMMAND"
EXIT_CODE=$?

# Log result
echo "[$TIMESTAMP] Exit code: $EXIT_CODE" >> "$LOG_FILE"
exit $EXIT_CODE
```

### Usage

From Claude Code (via SSH):
```bash
ssh claudeops@65.21.67.254 '/opt/claudeops/bin/claude-shell.sh claudeops check'
```

Or as the claudeops user:
```bash
/opt/claudeops/bin/claude-shell.sh claudeops status
```

---

## Security Considerations

### Principle of Least Privilege

The `claudeops` user follows the principle of least privilege:

✅ **CAN do:**
- Read ClaudeOps logs
- Execute ClaudeOps diagnostic commands
- View system status (systemctl status, docker ps, etc.)
- Read application logs (if granted via ACLs)

❌ **CANNOT do:**
- Modify system configurations
- Install packages
- Delete user data
- Change network settings
- Access other users' files

### SSH Key Security

- ✅ Use ED25519 keys (modern, secure)
- ✅ Protect private key with passphrase
- ✅ Regularly rotate keys
- ✅ Use `authorized_keys` options for restrictions:
  ```
  command="/opt/claudeops/bin/claude-shell.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAA...
  ```

### Logging and Auditing

All SSH sessions and commands are logged:

1. **SSH Login Logs**
   ```bash
   sudo tail -f /var/log/auth.log | grep claudeops
   ```

2. **Command Execution Logs**
   ```bash
   tail -f /var/log/claudeops/claude-shell.log
   ```

3. **ClaudeOps Action Logs**
   ```bash
   ls -la /var/log/claudeops/actions/
   ```

### Network Security

- ✅ Use SSH key authentication (no passwords)
- ✅ Disable root SSH login
- ✅ Configure firewall to allow only necessary ports
- ✅ Consider fail2ban for brute force protection
- ✅ Use VPN or restrict SSH access by IP (optional)

---

## Common Operations

### Check System Health
```bash
ssh claudeops@65.21.67.254 'claudeops check'
```

### View Recent Logs
```bash
ssh claudeops@65.21.67.254 'claudeops logs'
```

### Check Service Status
```bash
ssh claudeops@65.21.67.254 'systemctl status postgresql'
```

### View Docker Containers
```bash
ssh claudeops@65.21.67.254 'docker ps'
```

### Interactive Session
```bash
ssh claudeops@65.21.67.254
# Now you're on the server as claudeops user
claudeops status
exit
```

---

## Troubleshooting

### Cannot Connect via SSH

```bash
# Check if SSH service is running
sudo systemctl status ssh

# Verify firewall allows SSH
sudo ufw status

# Check SSH configuration
sudo cat /etc/ssh/sshd_config | grep -i "PasswordAuthentication\|PubkeyAuthentication"

# Test connection with verbose output
ssh -v claudeops@65.21.67.254
```

### Permission Denied

```bash
# Check authorized_keys permissions
ls -la /home/claudeops/.ssh/

# Should be:
# drwx------ (700) for .ssh/
# -rw------- (600) for authorized_keys

# Fix if needed
sudo chmod 700 /home/claudeops/.ssh
sudo chmod 600 /home/claudeops/.ssh/authorized_keys
sudo chown -R claudeops:claudeops /home/claudeops/.ssh
```

### Command Not Found

```bash
# Check PATH
ssh claudeops@65.21.67.254 'echo $PATH'

# Add to .bashrc if needed
echo 'export PATH="/opt/claudeops/bin:$PATH"' | sudo tee -a /home/claudeops/.bashrc

# Source it
ssh claudeops@65.21.67.254 'source ~/.bashrc && claudeops status'
```

### Logs Not Accessible

```bash
# Check ACLs
getfacl /var/log/claudeops/

# Set ACLs
sudo setfacl -R -m u:claudeops:rx /var/log/claudeops/
sudo setfacl -d -R -m u:claudeops:rx /var/log/claudeops/

# Or change ownership
sudo chown -R root:claudeops /var/log/claudeops/
sudo chmod -R g+rx /var/log/claudeops/
```

---

## Best Practices

### For Server Administrators

1. **Regular Auditing**
   - Review SSH logs weekly
   - Monitor command execution patterns
   - Check for unusual activity

2. **Key Rotation**
   - Rotate SSH keys every 6-12 months
   - Remove old/unused keys from authorized_keys
   - Document which keys belong to which systems

3. **Backup Access**
   - Ensure you have alternative access methods
   - Don't rely solely on the claudeops user
   - Keep root access available via console

### For Claude Code Users

1. **Secure Your Keys**
   - Never share private keys
   - Use strong passphrases
   - Store keys securely (encrypted disk)

2. **Verify Commands**
   - Review commands before execution
   - Understand what each command does
   - Use the wrapper script for safety

3. **Log Review**
   - Periodically review action logs
   - Verify expected behavior
   - Report anomalies

---

## Future Enhancements

- [ ] Multi-factor authentication (SSH + TOTP)
- [ ] IP whitelisting for SSH access
- [ ] Session recording/playback
- [ ] Rate limiting on command execution
- [ ] Integration with audit logging systems (SIEM)
- [ ] Automated key rotation

---

*Last updated: 2025-10-02*
