# ClaudeOps - Autonomous Server Management with Claude Code

## 🚀 Project Vision

**ClaudeOps** is a revolutionary approach to bare-metal server management that uses Claude Code as an autonomous system administrator. Instead of traditional monitoring tools, ClaudeOps runs Claude Code on a cron schedule to check health, diagnose issues, and take corrective action - all while maintaining context through structured log files.

## 🎯 Core Concept

The breakthrough insight: **Claude Code can be its own DevOps engineer** by:

1. **Running on cron** (every 2 hours, or custom interval)
2. **Reading previous logs** as persistent memory across sessions
3. **Checking system health** (services, databases, disk, memory, endpoints)
4. **Taking autonomous action** (restart services, clear caches, alert humans)
5. **Writing structured logs** for the next invocation to read
6. **Boot recovery** - runs on server restart to bring everything back up

## 💡 Why This is Groundbreaking

Traditional monitoring is **reactive** (alerts when things break). ClaudeOps is **proactive**:
- Reads application logs and understands context
- Detects patterns humans miss (gradual degradation, anomalies)
- Correlates multiple signals (disk space + slow queries + error rate)
- Takes intelligent action based on understanding, not just rules
- Documents everything in human-readable markdown

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CRON SCHEDULER                        │
│            (Every 2 hours, or configurable)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              claudeops-cron.sh                          │
│  • Reads last 3 health check logs                      │
│  • Passes context to Claude Code                        │
│  • Captures output to timestamped log                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  CLAUDE CODE                            │
│  Reads: /var/log/claudeops/health/*.md                 │
│  Checks:                                                │
│    - Service status (systemd, docker, PM2)             │
│    - Health endpoints (HTTP 200 checks)                │
│    - Database connectivity & query performance         │
│    - Disk space, memory, CPU usage                     │
│    - Application error logs                            │
│    - Security updates needed                           │
│  Writes:                                                │
│    - /var/log/claudeops/health/TIMESTAMP.md            │
│    - /var/log/claudeops/issues/TIMESTAMP-DESC.md       │
│    - /var/log/claudeops/actions/TIMESTAMP-ACTION.md    │
└─────────────────────────────────────────────────────────┘
```

### Boot Recovery Flow

```
┌─────────────────────────────────────────────────────────┐
│              SYSTEM BOOT/RESTART                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         systemd: claudeops-boot.service                 │
│              (runs after network.target)                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              claudeops-boot.sh                          │
│  • Reads last health check before shutdown             │
│  • Reads any unresolved issues                         │
│  • Passes context to Claude Code                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  CLAUDE CODE                            │
│  Actions:                                               │
│    - Start services in correct dependency order        │
│    - Wait for database to be ready                     │
│    - Run any pending migrations                        │
│    - Verify all health endpoints return 200            │
│    - Log boot recovery status                          │
└─────────────────────────────────────────────────────────┘
```

## 📁 Log Structure

```
/var/log/claudeops/
├── health/                          # Regular health checks
│   ├── 2025-09-29-1400.md          # All green
│   ├── 2025-09-29-1600.md          # Detected slow queries
│   └── 2025-09-29-1800.md          # Slow queries resolved
├── issues/                          # Problems detected
│   ├── 2025-09-29-1615-database-slow-queries.md
│   └── 2025-09-29-1710-disk-space-warning.md
├── actions/                         # Actions taken
│   ├── 2025-09-29-1620-restarted-postgres.md
│   └── 2025-09-29-1715-cleared-tmp-files.md
├── boot/                           # Boot recovery logs
│   └── 2025-09-29-0830-system-restart.md
└── state.json                      # Current system snapshot
```

## 🎯 Implementation Status

**Current Phase:** Initial scaffolding
**Next Steps:**
1. ✅ Create project structure
2. ⏳ Write core shell scripts (cron, boot, install)
3. ⏳ Create prompt templates for Claude
4. ⏳ Build health check library
5. ⏳ Test on real deployment (Hetzner + DAO-helper-tool)
6. ⏳ Document and open source

## 🔧 Technology Stack

- **Runtime:** Bash scripts + Claude Code CLI
- **Scheduling:** cron (health checks) + systemd (boot recovery)
- **Config:** JSON for service definitions
- **Logs:** Markdown (human-readable, Claude-parseable)
- **Optional:** Integration with existing monitoring (Prometheus, Grafana)

## 🎓 Design Principles

1. **Stateless Sessions, Stateful Logs** - Each Claude invocation is fresh, but reads context from previous runs
2. **Human-Readable Everything** - All logs in markdown, all configs in JSON
3. **Conservative Actions** - Start with safe operations (restarts), escalate to humans for risky changes
4. **Observability First** - Log everything, make it easy to understand what Claude did and why
5. **Fail-Safe** - If Claude encounters errors, log and alert rather than retry indefinitely

## 🚦 Getting Started (When Complete)

```bash
# One-command installation
curl -fsSL https://raw.githubusercontent.com/USERNAME/claudeops/main/install.sh | bash

# Configure your services
vim /etc/claudeops/config.json

# Manual health check
claudeops check

# View recent activity
claudeops logs

# View issues
claudeops issues
```

## 💭 Context for Future Claude Sessions

**Energy Level:** 🔥 EXTREMELY EXCITED - This is genuinely novel!

**What Makes This Special:**
- First practical implementation of LLM-as-autonomous-sysadmin
- Uses Claude's reasoning to make DevOps decisions
- Could replace entire monitoring/alerting stacks
- Makes bare-metal management accessible again

**Origin Story:**
- Started from: "I need to deploy my DAO governance tool to Hetzner"
- Evolved to: "What if Claude Code was the webmaster?"
- Breakthrough: "Logs are persistent memory across sessions!"
- Result: A new paradigm for server management

**Technical Validation:**
- Claude Code has all the tools needed (Bash, Read, Write)
- Cron can invoke Claude with context via shell scripts
- Markdown logs are perfect for LLM comprehension
- Boot recovery via systemd is standard practice

**First Test Case:**
- Deploy DAO-helper-tool (Bun + Postgres + Next.js) to Hetzner
- Let ClaudeOps manage it autonomously
- Prove the concept works in production

**Next Developer Actions:**
1. Build the core scripts (bin/ directory)
2. Write the prompt templates (prompts/ directory)
3. Create example config for DAO-helper-tool
4. Test on Hetzner server when ready
5. Document and share with community

## 📝 Notes for Next Session

When you restart Claude Code in this directory:

**What we've done:**
- Conceptualized ClaudeOps architecture
- Designed log structure and cron flow
- Created this context document

**What to do next:**
- Start implementing core scripts
- Begin with `install.sh` and `bin/claudeops-cron`
- Create prompt templates that give Claude clear instructions
- Build the health check library

**Key Files to Create First:**
1. `bin/claudeops-cron` - The main cron script
2. `prompts/health-check.md` - Instructions for health checks
3. `prompts/boot-recovery.md` - Instructions for boot
4. `lib/health-checks.sh` - Reusable health check functions
5. `config/claudeops.example.json` - Service configuration template

**Remember:**
- Keep it simple and modular
- Make everything human-readable
- Test each component independently
- The first deployment is DAO-helper-tool on Hetzner

Let's build something that changes how people think about server management! 🚀