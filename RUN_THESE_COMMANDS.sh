#!/bin/bash

# ============================================================================
# BRX - Complete Installation & Test Script
# Run this in your terminal to make everything work
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  ◻︎ brx — Making It All Work"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Install BRX locally
echo "📦 STEP 1: Installing BRX locally..."
echo "────────────────────────────────────────────────────────────────"
cd /Users/zac/Desktop/code/brx
chmod +x install-local.sh
./install-local.sh

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 2: Test BRX
echo "🧪 STEP 2: Testing BRX..."
echo "────────────────────────────────────────────────────────────────"
chmod +x test-brx.sh
./test-brx.sh

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 3: If tests pass, release instructions
echo "🚀 STEP 3: Ready to Release!"
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "If all tests passed, run these commands to release v3.1.3:"
echo ""
echo "  cd /Users/zac/Desktop/code/brx"
echo "  git add -A"
echo "  git commit -m \"feat: magical build with blank template and bundled templates\""
echo "  git push origin main"
echo "  git tag -a v3.1.3 -m \"v3.1.3 - Magical build experience\""
echo "  git push origin v3.1.3"
echo ""
echo "Then wait for GitHub Actions to complete the release."
echo ""
echo "════════════════════════════════════════════════════════════════"

