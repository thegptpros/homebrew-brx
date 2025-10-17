#!/bin/bash

echo "🔧 Quick Fix for BRX Templates"
echo "================================"
echo ""

# 1. Copy updated templates to user directory
echo "📦 Copying updated templates..."
mkdir -p ~/.local/share/brx
cp -r /Users/zac/Desktop/code/brx/Templates ~/.local/share/brx/
echo "✓ Templates updated"

# 2. Remove the failed Strong project
echo "🧹 Cleaning up failed build..."
cd ~/Desktop/code || cd ~
if [ -d "Strong" ]; then
    rm -rf Strong
    echo "✓ Removed Strong directory"
fi

# 3. Test again
echo ""
echo "✨ Ready to test! Run:"
echo "   cd ~/Desktop/code"
echo "   brx build --name Strong"
echo ""

