#!/bin/bash
set -e

echo "🚀 Installing BRX Locally"
echo "=========================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR"

# 1. Build BRX
step "Building BRX in release mode..."
swift build -c release
success "Build complete"

# 2. Install binary
step "Installing brx to /usr/local/bin..."
sudo cp .build/release/BRX /usr/local/bin/brx
sudo chmod +x /usr/local/bin/brx
success "Binary installed"

# 3. Install templates
step "Installing templates to ~/.local/share/brx/..."
mkdir -p ~/.local/share/brx
cp -r Templates ~/.local/share/brx/
success "Templates installed"

# 4. Verify installation
step "Verifying installation..."
echo ""
brx --version
echo ""

# 5. Check for xcodegen
step "Checking for xcodegen..."
if command -v xcodegen &> /dev/null; then
    success "xcodegen found"
else
    echo "⚠️  xcodegen not found. Installing via Homebrew..."
    brew install xcodegen
fi

echo ""
echo "================================"
echo -e "${GREEN}✨ Installation complete!${NC}"
echo "================================"
echo ""
echo "Try it out:"
echo "  brx build --name MyApp"
echo "  cd MyApp && brx run"
echo ""
echo "Get a license at: https://brx.dev"
echo ""

