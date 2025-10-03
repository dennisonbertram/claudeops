#!/bin/bash
# Test ClaudeOps functionality
# This script tests if Claude can properly execute system administration tasks

set -e

echo "======================================"
echo "Testing ClaudeOps Functionality"
echo "======================================"
echo ""

# Configuration
CLAUDEOPS_DIR="/opt/claudeops"
LOG_DIR="/var/log/claudeops"

# Load the system prompt
SYSTEM_PROMPT=""
if [ -f "$CLAUDEOPS_DIR/prompts/system-prompt.md" ]; then
    SYSTEM_PROMPT=$(cat "$CLAUDEOPS_DIR/prompts/system-prompt.md")
    echo "✓ System prompt loaded"
else
    echo "✗ System prompt not found at $CLAUDEOPS_DIR/prompts/system-prompt.md"
    SYSTEM_PROMPT="You are ClaudeOps, an autonomous server administrator."
fi

# Create a simple test prompt
cat > /tmp/claudeops-test.txt << EOF
$SYSTEM_PROMPT

## Test Task

This is a test to verify ClaudeOps is properly configured. Please perform these simple tasks:

1. **System Information**:
   - Show the hostname: \`hostname\`
   - Show the OS version: \`lsb_release -a\` or \`cat /etc/os-release\`
   - Show current date and time: \`date\`

2. **Resource Check**:
   - Display memory usage: \`free -h\`
   - Display disk usage: \`df -h /\`
   - Show system uptime: \`uptime\`

3. **Service Check**:
   - List running services: \`systemctl list-units --state=running --type=service | head -10\`
   - Check if Claude Code is accessible: \`which claude\`
   - Check Node.js version: \`node --version\`

4. **File System Test**:
   - Create a test file: \`echo "ClaudeOps test at \$(date)" > /tmp/claudeops-test.log\`
   - Read it back: \`cat /tmp/claudeops-test.log\`
   - Clean up: \`rm /tmp/claudeops-test.log\`

5. **Summary**:
   Provide a brief summary confirming:
   - You can execute system commands
   - You understand your role as ClaudeOps
   - The system appears healthy

Format your response as a simple test report. No need to write to log files for this test.
EOF

echo ""
echo "Running ClaudeOps test..."
echo "------------------------"
echo ""

# Run Claude with the test prompt
if command -v claude &> /dev/null; then
    claude chat --no-stream < /tmp/claudeops-test.txt
    echo ""
    echo "======================================"
    echo "✓ ClaudeOps test completed successfully!"
    echo "======================================"
else
    echo "✗ Claude command not found. Please run: claude auth login"
    echo "  to configure your Anthropic API key first."
    exit 1
fi

# Clean up
rm -f /tmp/claudeops-test.txt

echo ""
echo "Next steps:"
echo "1. Run a manual health check: /opt/claudeops/bin/claudeops-healthcheck.sh"
echo "2. Check cron job status: crontab -l"
echo "3. View health logs: ls -la /var/log/claudeops/health/"