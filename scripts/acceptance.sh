#!/bin/bash
# Acceptance test script for brx

set -euo pipefail

echo "🧪 Running brx acceptance tests..."
echo ""

# Install
echo "1. Installing brx..."
make install

# Run basic command
echo ""
echo "2. Running brx (main menu)..."
brx || true

# Run doctor
echo ""
echo "3. Running doctor..."
brx doctor

# Init a project
echo ""
echo "4. Creating test project..."
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

brx init --template swiftui-todo --name TestApp

# Enter project
cd TestApp

# Check files exist
echo ""
echo "5. Checking project structure..."
test -f brx.yml || (echo "❌ brx.yml not found" && exit 1)
test -d Sources || (echo "❌ Sources/ not found" && exit 1)

# List devices
echo ""
echo "6. Listing devices..."
brx devices list

# Note: We skip actual run/build to avoid requiring full simulator setup
echo ""
echo "✅ All acceptance tests passed!"
echo ""
echo "To complete testing, run manually:"
echo "  cd $TMPDIR/TestApp"
echo "  brx run"
echo "  brx watch"

