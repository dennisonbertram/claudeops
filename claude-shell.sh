#!/bin/bash

# Load NVM - try both locations
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if [ ! -f "$NVM_DIR/nvm.sh" ]; then
    export NVM_DIR="/home/claudeops/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

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
