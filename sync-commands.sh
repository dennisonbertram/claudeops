#!/bin/bash
# Sync ClaudeOps slash commands to all users

echo "Syncing ClaudeOps slash commands..."

# Source directory
SOURCE="/home/claude/.claude/commands"

# Target directories
TARGETS=(
    "/home/claudeops/.claude/commands"
    "/root/.claude/commands"
)

for target in "${TARGETS[@]}"; do
    echo "Syncing to: $target"
    mkdir -p "$target"
    cp "$SOURCE"/system-*.md "$target/"

    # Set correct ownership
    if [[ "$target" == "/root/.claude/commands" ]]; then
        chown -R root:root "$target"
    elif [[ "$target" == "/home/claudeops/.claude/commands" ]]; then
        chown -R claudeops:claudeops "$target"
    fi
done

echo "✅ Slash commands synced to all users"
