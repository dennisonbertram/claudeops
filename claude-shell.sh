#!/bin/bash

# Load NVM - try multiple locations
for nvm_path in "/opt/nvm" "/root/.nvm" "/home/claudeops/.nvm"; do
    if [ -s "$nvm_path/nvm.sh" ]; then
        export NVM_DIR="$nvm_path"
        . "$NVM_DIR/nvm.sh"
        break
    fi
done

export PATH="$NVM_DIR/versions/node/v22.20.0/bin:$PATH"

echo "================================================"
echo "  Welcome to ClaudeOps Interactive Shell"
echo "  Connected to: $(hostname)"
echo "  Date: $(date)"
echo "================================================"
echo ""
echo "You are now talking directly to Claude."
echo "Type 'exit' or Ctrl+D to disconnect."
echo ""

exec claude
