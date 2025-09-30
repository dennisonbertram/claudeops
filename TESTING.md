# Testing ClaudeOps Locally

This guide will help you test ClaudeOps on your local Mac before deploying to a production server.

## Prerequisites

- macOS (or Linux)
- Claude Code CLI installed: `npm install -g @anthropics/claude-code`
- Bash shell
- sudo access (for some operations)

## Quick Local Test

### 1. Test the Health Check Library

```bash
# Source the library
source lib/health-checks.sh

# Test some functions
check_network 8.8.8.8
check_dns google.com
check_disk_space /
check_memory_usage
get_top_memory_consumers 5
```

### 2. Test the Main CLI (without installation)

```bash
# Make sure you're in the claudeOps directory
cd /Users/dennisonbertram/Develop/claudeOps

# Test the main command
./bin/claudeops help
./bin/claudeops version
```

### 3. Create a Test Configuration

```bash
# Create test directories (no sudo needed for local test)
mkdir -p /tmp/claudeops-test/{health,issues,actions,boot}
mkdir -p /tmp/claudeops-test/config

# Copy example config
cp config/claudeops.example.json /tmp/claudeops-test/config/config.json

# Edit it to match your local system (optional)
# For testing, you can use the example as-is
```

### 4. Test Health Check (Dry Run)

```bash
# Set environment variables to use test directories
export CONFIG_FILE="/tmp/claudeops-test/config/config.json"
export LOG_BASE="/tmp/claudeops-test"

# Run a health check
./bin/claudeops-cron
```

This will:
- Read the config
- Run Claude Code to perform health checks
- Create a health check log in `/tmp/claudeops-test/health/`
- Show you what ClaudeOps would do in production

### 5. Review the Output

```bash
# View the generated health check
ls -la /tmp/claudeops-test/health/
cat /tmp/claudeops-test/health/*.md

# View any issues detected
ls -la /tmp/claudeops-test/issues/
cat /tmp/claudeops-test/issues/*.md 2>/dev/null || echo "No issues found"

# View any actions taken
ls -la /tmp/claudeops-test/actions/
cat /tmp/claudeops-test/actions/*.md 2>/dev/null || echo "No actions taken"
```

### 6. Test Boot Recovery (Dry Run)

```bash
# Run boot recovery script
./bin/claudeops-boot

# View the boot recovery log
cat /tmp/claudeops-test/boot/*.md
```

## Testing on a Real Server (Non-Production)

If you have a test server (like a Hetzner VPS):

### 1. Install ClaudeOps

```bash
curl -fsSL https://raw.githubusercontent.com/dennisonbertram/claudeops/main/install.sh | sudo bash
```

### 2. Run Setup Wizard

```bash
sudo claudeops setup
```

The setup wizard will:
- Interview you about your system
- Detect running services
- Create a custom configuration
- Run an initial health check

### 3. Manual Health Check

```bash
sudo claudeops check
```

### 4. View Status

```bash
claudeops status
claudeops logs
claudeops issues
```

## Expected Behavior

### First Run (No Previous Logs)
- Claude will note this is the first run
- Will establish baseline health metrics
- Will document all detected services
- Should complete within 5-10 minutes

### Subsequent Runs (With History)
- Claude will read the last 3 health check logs
- Will compare current state to previous runs
- Will detect trends (improving, degrading, stable)
- Should complete within 5-10 minutes

### If Issues Detected
- Claude will create an issue log with details
- Will determine severity (INFO, WARNING, CRITICAL)
- Will decide on action (NONE, MONITOR, SAFE_ACTION, ESCALATE)
- May take autonomous action if configured to auto-approve

## Troubleshooting

### "Claude Code CLI not found"
```bash
npm install -g @anthropics/claude-code
```

### "Permission denied"
Make sure scripts are executable:
```bash
chmod +x bin/*
```

### "Config file not found"
Set the environment variable:
```bash
export CONFIG_FILE="/path/to/config.json"
```

### Claude Times Out or Errors
- Check your API quota
- Verify internet connectivity
- Look at `/var/log/claudeops/claudeops.log` for details

## What to Look For

✅ **Good Signs:**
- Health check log created successfully
- Status shows "HEALTHY" or "WARNING" (not CRITICAL)
- Claude documents its reasoning clearly
- Actions taken are appropriate and documented

⚠️ **Warning Signs:**
- Health check takes > 15 minutes
- Claude gets confused about system state
- Same issue detected repeatedly without action
- Inappropriate actions (restarting critical services unnecessarily)

🚨 **Critical Issues:**
- Script crashes or hangs
- Logs not created
- Claude takes destructive actions
- False positives/negatives in health checks

## Next Steps After Testing

Once you're confident it works:

1. **Deploy to Production**: Use on real infrastructure
2. **Monitor for 1 Week**: Watch how it behaves with real issues
3. **Tune Configuration**: Adjust thresholds and auto-approve list
4. **Share Feedback**: Open GitHub issues for improvements

## Development Testing

If you're modifying ClaudeOps:

### Test Individual Components

```bash
# Test health check functions
bash -c 'source lib/health-checks.sh; check_network 8.8.8.8'

# Test prompt templates
cat prompts/health-check.md

# Validate JSON config
cat config/claudeops.example.json | jq .
```

### Test Installation Script (in VM)

```bash
# Don't run on your main system!
# Use a disposable VM or container

sudo bash install.sh
```

## Cleanup After Testing

```bash
# Remove test directories
rm -rf /tmp/claudeops-test

# Uninstall (if installed)
sudo rm /usr/local/bin/claudeops*
sudo rm -rf /usr/local/lib/claudeops
sudo rm -rf /usr/local/share/claudeops
sudo rm /etc/cron.d/claudeops
sudo systemctl disable claudeops-boot.service
sudo rm /etc/systemd/system/claudeops-boot.service
sudo rm -rf /var/log/claudeops
sudo rm -rf /etc/claudeops
```

## Questions or Issues?

Open an issue on GitHub: https://github.com/dennisonbertram/claudeops/issues