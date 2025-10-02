# Hetzner Server Setup for ClaudeOps

## Critical Discovery

**The previous deployment was on Hetzner Rescue System** - a temporary RAM-based Linux environment where all changes are lost on reboot. This explains why it was never production-ready.

## ✅ RECOMMENDED: Web Interface Setup

### Use Hetzner Robot Web Interface

**This is the most reliable method** - manually install via the web interface.

**Recommended OS: Ubuntu 22.04 LTS**
- Long-term support until 2027
- Stable and well-tested
- Easy Node.js 20 installation
- Works perfectly with Claude Code CLI
- Excellent for production deployments

#### Server Hardware (65.21.67.254)
```
CPU: AMD Ryzen 5 3600 6-Core (12 cores)
RAM: 64GB (Non-ECC)
Disk 1: /dev/nvme0n1 - 512GB NVMe
Disk 2: /dev/nvme1n1 - 512GB NVMe
Network: eth0 (65.21.67.254, 2a01:4f9:3081:5251::2/64)
```

### Step 1: Access Hetzner Robot Web Interface

1. Go to: https://robot.your-server.de
2. Log in with your Hetzner credentials
3. Navigate to your server (65.21.67.254)

### Step 2: Select Operating System

1. Click on "Linux" or "Reinstall" tab
2. **Select: Ubuntu 22.04 LTS (Jammy Jellyfish)**
3. Choose architecture: **amd64/x86_64**

### Step 3: Configure Installation Options

**Hostname:** `ClaudeOpsServer` (or your preferred name)

**RAID Configuration (Recommended):**
- Enable: **Software RAID 1** (mirrors data across both drives)
- Provides redundancy - if one drive fails, data is safe

**Partitioning:**
- Use default partitioning (usually sufficient)
- Or customize if needed:
  - `/boot`: 1GB
  - `swap`: 8GB
  - `/`: Remaining space

**SSH Keys:**
- Add your SSH public key for secure access
- Disable password login for better security

### Step 4: Start Installation

1. Review configuration
2. Click "Install" or "Execute"
3. Wait for installation to complete (5-15 minutes)
4. Server will automatically reboot into new OS

### Step 5: Connect to New System

```bash
# Clear old SSH host keys (from rescue system)
ssh-keygen -R 65.21.67.254

# Connect to new Ubuntu system
ssh root@65.21.67.254
```

**Verify installation:**
```bash
# Should show Ubuntu 22.04
cat /etc/os-release

# Should show real disk partitions
df -h

# Check system info
uname -a
hostnamectl
```

---

## Phase 2: Install ClaudeOps on Ubuntu 22.04

Now that you have a persistent Ubuntu installation, follow these steps:

### Step 1: Update System
```bash
# Update package lists
apt update

# Upgrade existing packages
apt upgrade -y

# Install essential tools
apt install -y curl git jq build-essential
```

### Step 2: Install Node.js 20 LTS
```bash
# Add NodeSource repository for Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# Install Node.js
apt install -y nodejs

# Verify installation
node --version   # Should show v20.x.x
npm --version    # Should show 10.x.x or higher
```

### Step 3: Install Claude Code CLI
```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version  # Should show 2.x.x
```

### Step 4: Authenticate Claude CLI
```bash
# Start OAuth authentication flow
claude setup-token

# Follow prompts:
# 1. Open the URL in your browser
# 2. Log in to your Anthropic account
# 3. Copy the verification code back to terminal

# Confirm authentication works:
echo "What is 2+2?" | claude --print
# Should return: "4" or similar response
```

### Step 5: Install ClaudeOps
```bash
# Run ClaudeOps installer
curl -fsSL https://raw.githubusercontent.com/dennisonbertram/claudeops/main/install.sh | bash

# This installs:
# - /usr/local/bin/claudeops (main CLI)
# - /usr/local/bin/claudeops-cron (scheduled checks)
# - /usr/local/bin/claudeops-boot (boot recovery)
# - /usr/local/bin/claudeops-setup (setup wizard)
# - /usr/local/lib/claudeops/ (health check library)
# - /var/log/claudeops/ (log directories)
```

### Step 6: Configure API Key (Optional - for API mode)
```bash
# Create secure environment file
echo "ANTHROPIC_API_KEY=your-api-key-here" > /etc/claudeops/.env
chmod 600 /etc/claudeops/.env

# Note: This is only needed if using API mode instead of authenticated CLI
```

### Step 7: Run Setup Wizard
```bash
# Interactive setup - Claude will interview you about your system
claudeops setup

# This creates /etc/claudeops/config.json with your service definitions
```

### Step 8: Test Health Check
```bash
# Run manual health check
claudeops check

# View logs
claudeops logs
```

### Step 9: Verify Automated Services
```bash
# Check cron job is installed
crontab -l
# Should show: 0 */2 * * * /usr/local/bin/claudeops-cron

# Check boot recovery service
systemctl status claudeops-boot
systemctl enable claudeops-boot  # Enable if not already
```

---

## ✅ Validation Checklist

Your system is production-ready when:

- ✅ Ubuntu 22.04 installed and accessible via SSH
- ✅ Node.js 20 installed and working
- ✅ Claude Code CLI installed and authenticated
- ✅ ClaudeOps installed and configured
- ✅ Manual health check runs successfully
- ✅ Cron job scheduled for automatic checks
- ✅ Boot recovery service enabled
- ✅ Logs writing to `/var/log/claudeops/`
- ✅ System survives reboots with services intact

---

## Common Issues & Solutions

### Issue: Claude authentication fails
**Cause**: OAuth tokens not set up or expired
**Solution**: Run `claude setup-token` and complete OAuth flow

### Issue: Cron jobs not running
**Solution**: Check `systemctl status cron` and verify with `crontab -l`

### Issue: ClaudeOps commands not found after installation
**Solution**: Run `source ~/.bashrc` or log out and back in to refresh PATH

### Issue: Permission denied on log files
**Solution**: Check that `/var/log/claudeops/` exists and has proper permissions
```bash
mkdir -p /var/log/claudeops/{health,issues,actions,boot}
chmod 755 /var/log/claudeops
```

---

## ❌ What Doesn't Work (Don't Do This)

### Automated installimage via SSH (FAILED)

We attempted to automate the installation using `installimage` command-line tool:

```bash
# THIS DOESN'T WORK - Server not accessible after reboot
ssh root@65.21.67.254 '/root/.oldroot/nfs/install/installimage -a -n ClaudeOpsServer ...'
```

**Why it failed:**
- Server successfully installed Debian 12 with RAID 1 and LVM
- Installation completed without errors
- Server rebooted but became inaccessible via SSH
- Possible causes:
  - SSH host key changes not properly handled
  - Network configuration issues
  - Server waiting at boot menu
  - Console access required for first boot

**Lesson learned:** Use the web interface for Hetzner installations - it's more reliable and provides better visibility into the process.

### Installing on Rescue System (FAILED)

**Don't install ClaudeOps on Hetzner Rescue System:**
- Rescue system is RAM-based and ephemeral
- All installations are lost on reboot
- Only useful for troubleshooting, not production
- Must install permanent OS first

**What happened:**
- Initial deployment completed successfully on rescue system
- Claude performed excellent health analysis
- All appeared to work perfectly
- But everything was lost on reboot (expected behavior)

---

## Timeline

**Web Interface Method (Recommended):**
- OS Installation via web: 10-15 minutes
- System updates: 5 minutes
- Node.js + Claude CLI: 5 minutes
- ClaudeOps installation: 5 minutes
- Configuration & testing: 10 minutes
- **Total**: ~35-40 minutes for production-ready deployment

---

**Document Created**: 2025-09-30
**Last Updated**: 2025-09-30
**Status**: Web interface method validated, automated CLI method documented as failed