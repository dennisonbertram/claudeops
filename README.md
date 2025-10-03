# ClaudeOps

**Autonomous Server Management with Claude Code**

> What if your server's DevOps engineer was an LLM that runs on cron, reads logs as memory, and takes intelligent action?

## Overview

ClaudeOps transforms Claude Code into an autonomous system administrator. Instead of traditional monitoring dashboards and alert rules, ClaudeOps runs Claude Code on a schedule to:

- 🔍 Check system health (services, databases, endpoints, resources)
- 🧠 Read previous logs to understand context and trends
- 🔧 Take corrective action when issues are detected
- 📝 Document everything in human-readable markdown
- 🚀 Recover services automatically after reboots

## Why ClaudeOps?

Traditional monitoring is **reactive** (alerts when broken) and **rule-based** (if X then Y). ClaudeOps is **proactive** and **intelligent**:

- **Understands Context:** Reads application logs, correlates signals, detects patterns
- **Reasons About Problems:** "Slow queries + rising memory = connection leak?"
- **Takes Appropriate Action:** Restarts when safe, escalates when uncertain
- **Learns from History:** Each run reads previous logs to maintain continuity
- **Speaks Human:** All logs in markdown, all reasoning documented

## How It Works

```
┌─────────────┐
│  Cron Job   │  Every 2 hours (configurable)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│  claudeops-cron.sh                          │
│  • Reads last 3 health check logs          │
│  • Invokes Claude Code with context        │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│  Claude Code                                │
│  • Checks services, databases, endpoints   │
│  • Analyzes logs for errors/patterns       │
│  • Compares to previous state              │
│  • Takes action if needed                  │
│  • Writes structured report                │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│  /var/log/claudeops/                        │
│  ├── health/2025-09-29-1400.md            │
│  ├── issues/database-slow.md               │
│  └── actions/restarted-postgres.md         │
└─────────────────────────────────────────────┘
```

## Installation

📋 **[Complete Installation Guide](INSTALL-VALIDATED.md)** - Tested and validated step-by-step instructions

The complete installation guide includes:
- Prerequisites checklist
- Step-by-step setup instructions (validated on Ubuntu 24.04)
- Post-installation testing
- Troubleshooting tips
- 85% validated via Docker container testing

### Quick Install (Alternative)

```bash
# One-command installation
curl -fsSL https://raw.githubusercontent.com/dennisonbertram/claudeops/main/install.sh | sudo bash

# Run the interactive setup wizard
sudo claudeops setup

# After setup, ClaudeOps runs automatically via cron
# Or run manual health check anytime:
sudo claudeops check

# View status and logs
claudeops status      # Quick status overview
claudeops logs        # Recent health checks
claudeops issues      # Unresolved issues
claudeops actions     # Recent actions taken
```

### Available Commands

```bash
claudeops setup       # Interactive setup wizard
claudeops check       # Run health check now
claudeops boot        # Run boot recovery manually
claudeops status      # Show system status
claudeops logs        # View recent health checks
claudeops issues      # View unresolved issues
claudeops actions     # View recent actions
claudeops config      # View configuration
claudeops version     # Show version info
claudeops help        # Show help
```

## New Features (October 2025)

✅ **Custom Slash Commands** - Direct server access through Claude Code

- `/system-health` - Run comprehensive health checks instantly
- `/system-status` - Quick system overview
- `/system-logs` - View recent ClaudeOps logs
- `/system-services` - Check all service statuses
- `/system-restart` - Safely restart services

✅ **Direct SSH Access** - Secure, limited-privilege access

- Dedicated `claudeops` SSH user for Claude Code
- SSH key authentication (no passwords)
- Command logging and auditing
- Restricted permissions following principle of least privilege

✅ **Git Integration** - Version control for logs and configurations

- GitHub repository for all ClaudeOps artifacts
- Automated log versioning and backup
- Full audit trail of system changes

See [docs/POST_DEPLOYMENT_2025-10-02.md](docs/POST_DEPLOYMENT_2025-10-02.md) for details.

## Project Status

✅ **Production Ready** - Deployed and Operational!

- [x] Architecture designed
- [x] Log structure defined
- [x] Core scripts implementation
  - [x] bin/claudeops - Main CLI utility
  - [x] bin/claudeops-cron - Scheduled health checks
  - [x] bin/claudeops-boot - Boot recovery
  - [x] bin/claudeops-setup - Interactive setup wizard
- [x] Prompt templates (setup, health-check, boot-recovery)
- [x] Health check library (20+ reusable functions)
- [x] Installation script (one-command install)
- [x] Templates (cron job, systemd service)
- [x] Complete server deployment automation
  - [x] `server-setup.sh` - Full server provisioning
  - [x] `deploy-to-server.sh` - One-command deployment
  - [x] Systemd integration for boot recovery
  - [x] Cron configuration for health checks
- [x] **Production Deployment** (Hetzner 65.21.67.254)
  - [x] Custom slash commands
  - [x] Direct SSH access (claudeops user)
  - [x] Git integration with GitHub
  - [x] Comprehensive documentation
- [x] Documentation
  - [x] [Server Setup Guide](docs/CLAUDEOPS_SERVER_SETUP.md)
  - [x] [Slash Commands Guide](docs/SLASH_COMMANDS.md)
  - [x] [SSH Access Guide](docs/SSH_DIRECT_ACCESS.md)
  - [x] [Lessons Learned](docs/LESSONS_LEARNED.md)
  - [x] [Post-Deployment Report](docs/POST_DEPLOYMENT_2025-10-02.md)
- [ ] Community feedback and contributions welcome!

## Use Cases

- **Small Teams:** Replace expensive monitoring services with Claude
- **Side Projects:** Set-and-forget reliability for side hustles
- **Learning:** See how an AI would debug your infrastructure
- **Bare Metal:** Make dedicated servers manageable again
- **Cost Optimization:** Intelligent resource management

## Example Log

```markdown
# Health Check - 2025-09-29 14:00

## Status: ⚠️ WARNING

### Services
- ✅ PostgreSQL: Running, 23 connections
- ✅ Frontend: Responding on port 3006
- ⚠️ Indexer: Running, but slow (5s response time, usually <1s)

### Database
- ✅ Connection pool: 23/100
- ⚠️ Slow queries detected (3 queries >2s in last hour)
- Top slow query: `SELECT * FROM posts WHERE...` (avg 3.2s)

### Resources
- ✅ Disk: 45% used (55GB free)
- ✅ Memory: 62% used (3.8GB free)
- ⚠️ CPU: 85% used (usually <50%)

## Analysis
The indexer is experiencing performance degradation. Correlation:
- Slow database queries started at 13:45
- CPU spike at 13:47
- Indexer slowdown at 13:50

Likely cause: Long-running query is blocking other operations.

## Actions Taken
None yet. Monitoring for 2 more cycles before intervention.

## Recommendations for Next Run
- If slow queries persist, consider:
  1. Adding index on posts.created_at
  2. Restarting Postgres to clear any locks
  3. Checking for missing VACUUM operations
```

## Contributing

This is a brand new project. Contributions, ideas, and feedback welcome!

## License

MIT License - See [LICENSE](LICENSE) file for details

## Authors

- Initial concept: [@dennisonbertram](https://github.com/dennisonbertram)
- Developed in collaboration with Claude Code

---

**Built with Claude Code. Managed by Claude Code. This README was written by Claude Code.** 🤖