#!/bin/bash
echo "Testing Claude Code installation..."

# Test if claude command exists
if command -v claude &> /dev/null; then
    echo "✓ Claude Code CLI is installed"
    claude --version
else
    echo "✗ Claude Code CLI not found"
    exit 1
fi

# Test Node.js
if command -v node &> /dev/null; then
    echo "✓ Node.js is installed: $(node --version)"
else
    echo "✗ Node.js not found"
    exit 1
fi

# Test Python
if command -v python3 &> /dev/null; then
    echo "✓ Python is installed: $(python3 --version)"
else
    echo "✗ Python not found"
    exit 1
fi

# Test PM2
if command -v pm2 &> /dev/null; then
    echo "✓ PM2 is installed"
else
    echo "✗ PM2 not found"
    exit 1
fi

echo ""
echo "All tests passed! Claude Code is ready to use."
