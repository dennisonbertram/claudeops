# ClaudeOps First Deployment - Hetzner Server
## Date: 2025-09-30
## Server: 65.21.67.254 (static.254.67.21.65.clients.your-server.de)

---

## Pre-Installation System State

### System Information
```
Hostname: rescue
Kernel: Linux 6.12.19 #1 SMP Wed Sep  3 09:40:41 UTC 2025 x86_64
Environment: Hetzner Rescue System (minimal Linux)
```

### Resources
```
RAM: 62GB total, 62GB available (only 747MB used)
Disk: 32GB overlay filesystem (1% used)
CPU: Multi-core (exact count TBD)
Network: IPv4 65.21.67.254, IPv6 2a01:4f9:3081:5251::/64
```

### Running Services
```
Basic systemd services only:
- ssh.service (OpenBSD Secure Shell server)
- systemd-journald.service
- systemd-resolved.service (DNS)
- systemd-timesyncd.service (NTP)
- dbus.service
- haveged.service (entropy daemon)
```

### Application State
```
/home/: Empty
/opt/: Contains some vendor tools (dell, deskview, wdc)
/var/www/: Contains minimal html directory
```

**Conclusion:** This is essentially a clean slate - perfect for testing ClaudeOps from scratch.

---

## Installation Process

### Step 1: Prerequisites Check
```
Git: ✓ version 2.39.5
Curl: ✓ version 7.88.1
Node.js: ✗ Not installed
npm: ✗ Not installed
Claude Code CLI: ✗ Not installed
```

### Step 2: Installing Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
```
**Result:** ✓ Node.js 20.19.5 installed successfully

### Step 3: Installing Claude Code CLI

**First Attempt (Wrong Package Name):**
```bash
npm install -g @anthropics/claude-code  # ❌ WRONG SCOPE
```
**Result:** ❌ FAILED - Package not found

**Corrected Attempt:**
```bash
npm install -g @anthropic-ai/claude-code  # ✓ CORRECT SCOPE
```
**Result:** ✓ SUCCESS
```
Claude Code v2.0.0 installed
Location: /usr/bin/claude
```

**Lesson Learned:** The correct npm package is `@anthropic-ai/claude-code` (not `@anthropics`)

---

## ClaudeOps Installation