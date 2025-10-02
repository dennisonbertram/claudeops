# ClaudeOps Server Setup Documentation

## Overview

ClaudeOps transforms any Linux server into an autonomously managed system using Claude Code as the system administrator. This document covers the complete setup process for deploying ClaudeOps to a bare-metal server.

## Server Details

- **IP Address**: 65.21.67.254 (example)
- **Provider**: Hetzner
- **OS**: Ubuntu/Debian (assumed)
- **Purpose**: Autonomous server management via Claude Code

## Components Installed

### Core Infrastructure

1. **Node.js** (via NVM at `/opt/nvm`)
   - Latest LTS version
   - System-wide availability via `/etc/profile.d/nvm.sh`

2. **Python 3** with pip
   - Set as default python interpreter
   - Virtual environment support

3. **Claude Code CLI**
   - Installed globally via npm
   - Requires API key configuration post-install

4. **PM2 Process Manager**
   - Manages Node.js applications
   - Configured with systemd startup

### ClaudeOps Components

#### Directory Structure
```
/opt/claudeops/
├── bin/                 # Executable scripts
├── config/              # Configuration files
├── prompts/             # Claude prompts
└── lib/                 # Shared libraries

/var/log/claudeops/
├── health/              # Health check reports
├── issues/              # Detected problems
├── actions/             # Actions taken
├── boot/                # Boot recovery logs
└── state.json           # System state
```

#### Scripts

1. **`claudeops-healthcheck.sh`**
   - Runs every 2 hours via cron
   - Performs comprehensive system health checks
   - Takes autonomous corrective actions
   - Maintains context from previous runs

2. **`claudeops-boot.sh`**
   - Executes on system startup via systemd
   - Ensures all services start correctly
   - Handles dependency order
   - Recovers from unexpected shutdowns

3. **`test-claude.sh`**
   - Verifies installation integrity
   - Tests all components
   - Located at `/opt/claudeops/test-claude.sh`

### Security Configuration

- **UFW Firewall** enabled with:
  - SSH (22)
  - HTTP (80)
  - HTTPS (443)
  - Default deny incoming
  - Default allow outgoing

- **Log Rotation** configured for ClaudeOps logs
  - 30-day retention
  - Daily rotation
  - Compression enabled

### Additional Tools

- System monitoring: `htop`, `ncdu`
- Network tools: `net-tools`, `dnsutils`
- Database clients: `postgresql-client`, `redis-tools`
- Web server: `nginx` with `certbot` for SSL

## Deployment Process

### Prerequisites

- Root access to target server
- Claude API key (obtain from Anthropic)

### Deployment Steps

1. **Run deployment script from local machine:**
   ```bash
   cd /Users/dennisonbertram/Develop/claudeOps
   SERVER_PASS="your_password" ./deploy-to-server.sh
   ```

   **Note:** For better security, use SSH key authentication instead of passwords.

2. **SSH into server and configure Claude:**
   ```bash
   ssh root@65.21.67.254
   claude auth login
   # Enter your API key when prompted
   ```

3. **Verify installation:**
   ```bash
   /opt/claudeops/test-claude.sh
   ```

4. **Test health check manually:**
   ```bash
   /opt/claudeops/bin/claudeops-healthcheck.sh
   ```

## Automated Operations

### Health Checks (Cron)

- **Schedule**: Every 2 hours (0 */2 * * *)
- **Log Location**: `/var/log/claudeops/health/`
- **Context**: Reads last 3 health checks
- **Actions**: Automatic remediation when safe

### Boot Recovery (Systemd)

- **Service**: `claudeops-boot.service`
- **Trigger**: System startup after network
- **Log Location**: `/var/log/claudeops/boot/`
- **Purpose**: Ensure all services start properly

## Monitoring and Logs

### Log Files

All logs are in markdown format for human readability:

- **Health Reports**: `/var/log/claudeops/health/YYYY-MM-DD-HHMMSS.md`
- **Issues**: `/var/log/claudeops/issues/TIMESTAMP-description.md`
- **Actions**: `/var/log/claudeops/actions/TIMESTAMP-action.md`
- **Boot Logs**: `/var/log/claudeops/boot/TIMESTAMP-boot.md`

### Viewing Logs

```bash
# View latest health check
ls -t /var/log/claudeops/health/*.md | head -1 | xargs cat

# View all issues
ls /var/log/claudeops/issues/

# View cron execution log
tail -f /var/log/claudeops/cron.log
```

## Troubleshooting

### Claude Code Not Working

1. Check API key configuration:
   ```bash
   claude auth status
   ```

2. Verify Node.js installation:
   ```bash
   source /opt/nvm/nvm.sh
   node --version
   ```

3. Test Claude manually:
   ```bash
   echo "What is 2+2?" | claude chat
   ```

### Health Checks Not Running

1. Check cron job:
   ```bash
   crontab -l
   ```

2. View cron logs:
   ```bash
   grep CRON /var/log/syslog
   ```

3. Run health check manually:
   ```bash
   /opt/claudeops/bin/claudeops-healthcheck.sh
   ```

### Boot Recovery Issues

1. Check service status:
   ```bash
   systemctl status claudeops-boot.service
   ```

2. View service logs:
   ```bash
   journalctl -u claudeops-boot.service
   ```

## Future Enhancements

### Planned Features

1. **Web Dashboard**: View health status via browser
2. **Slack/Discord Integration**: Alert notifications
3. **Custom Health Checks**: Application-specific monitoring
4. **Metrics Collection**: Prometheus/Grafana integration
5. **Multi-Server Management**: Central control plane

### Configuration Expansion

Future versions will support:
- Custom check intervals
- Service-specific health endpoints
- Database-specific monitoring
- Application deployment automation

## Security Considerations

### API Key Protection

- Store Claude API key securely
- Never commit keys to version control
- Consider using environment variables or secrets manager

### Access Control

- Limit SSH access to specific IPs if possible
- Use SSH keys instead of passwords
- Regular security updates: `apt update && apt upgrade`

### Monitoring Access

- ClaudeOps runs as root (required for system management)
- Consider creating dedicated service user for specific tasks
- Review action logs regularly

## Support and Contributing

### Getting Help

- Check logs in `/var/log/claudeops/`
- Run test script: `/opt/claudeops/test-claude.sh`
- Review this documentation

### Contributing

This project demonstrates a novel approach to server management. Contributions welcome:
- Additional health checks
- Integration with monitoring systems
- Security enhancements
- Documentation improvements

## Conclusion

ClaudeOps represents a paradigm shift in server management, using AI reasoning instead of rule-based monitoring. The system provides:

- **Autonomous operation**: Self-healing capabilities
- **Context awareness**: Learns from previous runs
- **Human-readable logs**: All outputs in markdown
- **Boot resilience**: Automatic recovery from restarts
- **Extensibility**: Easy to add new checks and actions

This setup transforms your server into a self-managing system, with Claude Code acting as an intelligent, always-on system administrator.