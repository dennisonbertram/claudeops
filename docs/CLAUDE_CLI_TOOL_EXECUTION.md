# Claude CLI Tool Execution - Technical Reference

**Document Purpose:** Comprehensive guide to Claude CLI tool execution limitations and solutions discovered during ClaudeOps development.

**Date:** 2025-09-30
**Claude CLI Version:** 2.0.0
**Test Environment:** Hetzner bare metal server (Debian 12 rescue system)

---

## Executive Summary

Claude Code CLI (`@anthropic-ai/claude-code`) is designed for **interactive developer workflows**, not headless server automation. While authentication can be completed on servers, **tool execution requires specific conditions** that are challenging in autonomous server environments.

### Key Findings

| Feature | Works? | Notes |
|---------|--------|-------|
| Installation via npm | ✅ Yes | `npm install -g @anthropic-ai/claude-code` |
| Authentication (`setup-token`) | ✅ Yes | Requires interactive terminal for OAuth |
| Text generation (`--print`) | ✅ Yes | Returns text responses |
| Tool execution in `--print` mode | ❌ No | Tools are not executed, only described |
| Tool execution as root | ❌ No | Security restriction on `--dangerously-skip-permissions` |
| Interactive mode over SSH | ⚠️ Limited | Requires proper TTY allocation |

---

## Authentication

### Problem
Claude CLI uses OAuth authentication that requires:
1. Opening a web browser
2. Logging into Anthropic account
3. Copying verification code back to terminal

### Solution for Servers
```bash
# SSH with TTY allocation
ssh -t user@server

# Run authentication
claude setup-token

# Follow prompts:
# 1. Open URL in browser on your local machine
# 2. Login to Anthropic
# 3. Copy code back to terminal
```

### Authentication Files Created
```
~/.claude.json          # Config and auth tokens
~/.claude/              # Additional data
  ├── projects/
  ├── shell-snapshots/
  ├── statsig/
  └── todos/
```

### Verification
```bash
# Test authentication
echo "What is 2+2?" | claude --print

# Should return: "Four" (or similar)
```

---

## Tool Execution Modes

### Mode 1: `--print` (Non-Interactive)

**Purpose:** Get text output for piping/scripting

**Behavior:**
- Returns text-only responses
- **Does NOT execute tools** (Bash, Read, Write, etc.)
- Claude describes what it would do, but doesn't do it
- Fast, deterministic output

**Example:**
```bash
echo "Create a file /tmp/test.txt" | claude --print
# Output: "I'll create that file..." (but file is NOT created)
```

**Use Cases:**
- ✅ Question answering
- ✅ Code generation
- ✅ Analysis/reasoning
- ❌ Autonomous actions
- ❌ File operations
- ❌ System commands

### Mode 2: Interactive (Default)

**Purpose:** Developer workflow with tool execution

**Behavior:**
- Executes tools (Bash, Read, Write, Edit, etc.)
- Requires TTY (terminal)
- Shows permission prompts
- Maintains session state

**Example:**
```bash
# Interactive session (requires TTY)
claude
> Create a file /tmp/test.txt
# Claude executes: Write tool creates the file
```

**Challenges for Automation:**
- Requires human interaction for permissions
- Needs proper TTY allocation
- Not suitable for cron/systemd

### Mode 3: `--dangerously-skip-permissions`

**Purpose:** Bypass permission prompts (dangerous!)

**Limitations:**
```bash
# As root - DOES NOT WORK
sudo claude --print --dangerously-skip-permissions "..."
# Error: cannot be used with root/sudo privileges

# As regular user - WORKS
claude --print --dangerously-skip-permissions "..."
# Executes tools without prompts
```

**Security Note:** This flag is intentionally blocked for root to prevent accidental system damage.

---

## Permission Modes

Available via `--permission-mode <mode>`:

| Mode | Description | Tool Execution? | Root Support? |
|------|-------------|-----------------|---------------|
| `default` | Standard permission prompts | Yes | Yes (with prompts) |
| `acceptEdits` | Auto-accept file edits | Yes | Yes |
| `bypassPermissions` | Skip all prompts | Yes | ❌ No (same as --dangerously-skip-permissions) |
| `plan` | Planning mode only | No | Yes |

### Testing Permission Modes as Root
```bash
# acceptEdits - MAY work for file operations
echo "Edit /tmp/test.txt" | claude --print --permission-mode acceptEdits

# bypassPermissions - DOES NOT work as root
echo "Run command" | claude --print --permission-mode bypassPermissions
# Error: cannot be used with root/sudo privileges
```

---

## Architectures for Autonomous Operation

### Architecture 1: Non-Root User with Sudo (Recommended)

**Concept:** Run Claude as regular user, use sudo for root commands

```bash
# Create dedicated user
useradd -m claudeops

# Copy authentication
cp -r ~/.claude* /home/claudeops/
chown -R claudeops:claudeops /home/claudeops/.claude*

# Configure sudo permissions
cat > /etc/sudoers.d/claudeops << 'EOF'
claudeops ALL=(ALL) NOPASSWD: /usr/bin/systemctl *
claudeops ALL=(ALL) NOPASSWD: /usr/bin/journalctl *
# Add other commands as needed
EOF

# Run as claudeops user
sudo -u claudeops claude --dangerously-skip-permissions
```

**Pros:**
- ✅ Tool execution works
- ✅ Can use `--dangerously-skip-permissions`
- ✅ Controlled root access via sudo

**Cons:**
- ⏱️ Setup complexity
- 🔧 Need to configure sudo for each command
- ⚠️ Still requires TTY for full tool execution

### Architecture 2: Expect/Script for TTY Allocation

**Concept:** Use `expect` or `script` to provide TTY for interactive Claude

```bash
# Install expect
apt-get install expect

# Create expect script
cat > run-claude.exp << 'EOF'
#!/usr/bin/expect
set timeout 300
spawn claude
expect ">"
send "Your prompt here\n"
expect ">"
send "exit\n"
expect eof
EOF

chmod +x run-claude.exp
./run-claude.exp
```

**Pros:**
- ✅ Full tool execution
- ✅ Works with interactive Claude

**Cons:**
- 🔧 Complex scripting
- ⏱️ Harder to parse output
- ⚠️ Requires expect installed

### Architecture 3: Tool Execution Parser (Hybrid)

**Concept:** Use API/`--print` for reasoning, parse output, execute tools separately

```bash
# Step 1: Get Claude's plan (API or --print)
RESPONSE=$(echo "$PROMPT" | claude --print)

# Step 2: Parse bash commands from response
grep -oP '(?<=```bash\n).*?(?=\n```)' <<< "$RESPONSE" > commands.sh

# Step 3: Review/approve commands
cat commands.sh

# Step 4: Execute
bash commands.sh

# Step 5: Feed results back to Claude
echo "Results: $(cat output.txt)" | claude --print
```

**Pros:**
- ✅ Works with `--print` mode
- ✅ Explicit approval mechanism
- ✅ Can run as any user

**Cons:**
- 🔧 Requires custom parser
- ⏱️ Development time (3-4 hours)
- 🔄 Multi-turn conversation complexity

### Architecture 4: Anthropic API with Custom Tools

**Concept:** Use Anthropic Messages API directly, implement tool layer

```bash
# Call API with tool definitions
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "tools": [{"name": "bash", "description": "..."}],
    "messages": [...]
  }'

# Parse tool_use blocks
# Execute tools
# Return tool_result blocks
```

**Pros:**
- ✅ Full control
- ✅ Works headlessly
- ✅ API key authentication

**Cons:**
- 🔧 Significant development (~8+ hours)
- 🔧 Need to implement all tools
- 💰 API costs per request

---

## Test Results from ClaudeOps Development

### Test 1: API Wrapper (claude-api)
```bash
# Created wrapper using Anthropic Messages API
echo "Analyze system health" | claude-api --print

✅ Result: Excellent reasoning and analysis
❌ Result: No tool execution (API limitation)
```

### Test 2: Claude CLI --print Mode
```bash
# Using authenticated Claude CLI
echo "Check SSH service" | claude --print

✅ Result: Intelligent analysis
❌ Result: No actual systemctl commands executed
📝 Output: Text describing what it would check
```

### Test 3: Claude CLI Interactive (no TTY)
```bash
# Over SSH without proper TTY
echo "Test" | claude

❌ Result: Hangs waiting for terminal input
```

### Test 4: Permission Modes as Root
```bash
# Test bypass as root
claude --print --permission-mode bypassPermissions "..."

❌ Result: "cannot be used with root/sudo privileges"
```

### Test 5: Health Check with Reasoning Only
```bash
/usr/local/bin/claudeops-cron

✅ Result: Comprehensive analysis
✅ Duration: ~57 seconds
✅ Quality: Excellent (checked services, disk, memory, CPU, logs, network)
✅ Decision-making: Correct ("system healthy, no actions needed")
❌ File creation: Report not written to disk
```

---

## Recommendations for Production

### For ClaudeOps v2.0 (Full Autonomy)

**Best Approach:** Architecture 3 (Tool Execution Parser)

1. Keep current API/CLI wrapper for reasoning
2. Build parser to extract bash commands from responses
3. Add approval/auto-approve mechanism
4. Execute commands and capture output
5. Feed results back for next decision

**Development Time:** 3-4 hours
**Complexity:** Medium
**Reliability:** High

### Quick Win: Monitoring Only (No Actions)

**Current State:** Keep as-is for monitoring/alerting

- Claude analyzes system health
- Generates comprehensive reports (in text)
- No actual system modifications
- Human reviews and takes action

**Development Time:** 0 hours (done)
**Complexity:** Low
**Reliability:** High

---

## Code Examples

### Working: Claude CLI for Analysis (Current ClaudeOps)

```bash
#!/bin/bash
# Source API key
source /etc/claudeops/.env

# Prepare prompt with system context
PROMPT="Analyze this server..."

# Get Claude's analysis
ANALYSIS=$(echo "$PROMPT" | claude --print)

# Log the analysis (human reviews later)
echo "$ANALYSIS" | tee /var/log/claudeops/analysis.txt

# Alert if critical issues mentioned
if echo "$ANALYSIS" | grep -i "critical"; then
    send_alert "$ANALYSIS"
fi
```

### Future: Tool Execution Parser (ClaudeOps v2.0)

```bash
#!/bin/bash
# Parse and execute Claude's commands

# Get Claude's plan
PLAN=$(echo "$PROMPT" | claude --print)

# Extract bash commands
COMMANDS=$(echo "$PLAN" | awk '/```bash/,/```/ {if (!/```/) print}')

# Save for review/approval
echo "$COMMANDS" > /tmp/pending-commands.sh

# Execute (with approval mechanism)
if approve_commands; then
    bash /tmp/pending-commands.sh 2>&1 | tee /tmp/command-output.txt

    # Feed results back
    RESULTS=$(cat /tmp/command-output.txt)
    echo "Command results: $RESULTS" | claude --print
fi
```

---

## Troubleshooting

### Issue: "Invalid API key · Please run /login"
**Cause:** Claude CLI not authenticated
**Solution:** Run `claude setup-token` interactively

### Issue: "Raw mode is not supported"
**Cause:** No TTY available (SSH without -t)
**Solution:** Use `ssh -t` or run in screen/tmux

### Issue: "--dangerously-skip-permissions cannot be used with root"
**Cause:** Security restriction
**Solution:** Run as non-root user or use Architecture 3

### Issue: Commands described but not executed
**Cause:** Using `--print` mode (text-only)
**Solution:** Use interactive mode or build tool parser

### Issue: Claude hangs/no output
**Cause:** Waiting for interactive terminal input
**Solution:** Provide proper TTY or use `--print` mode

---

## Future: Ideal State

**What We Need from Anthropic:**

1. **API with Tool Execution**
   - Messages API with tool_use/tool_result support
   - Server-side tool execution
   - API key authentication (no OAuth required)

2. **Headless CLI Mode**
   - `--headless` flag for full automation
   - API key authentication option
   - Tool execution without TTY

3. **Server Agent Mode**
   - Purpose-built for server automation
   - Long-running daemon
   - Built-in approval mechanisms

**Until Then:**
Use Architecture 3 (Tool Execution Parser) for production autonomous operation.

---

## References

- Claude Code CLI: `@anthropic-ai/claude-code` (npm)
- Documentation: https://docs.anthropic.com/claude-code
- API Docs: https://docs.anthropic.com/api
- ClaudeOps: https://github.com/dennisonbertram/claudeops

---

**Last Updated:** 2025-09-30
**Tested By:** ClaudeOps Development Team
**Server:** Hetzner 65.21.67.254

**Note:** This document will be updated as Claude CLI evolves. Check for newer versions.