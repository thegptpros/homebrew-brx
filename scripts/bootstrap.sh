#!/bin/bash
set -euo pipefail

echo "🚀 Installing brx..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

# Check we're not using CLT only
XCODE_PATH=$(xcode-select -p)
if [[ "$XCODE_PATH" == *"CommandLineTools"* ]]; then
    echo "❌ Only Command Line Tools found. Please install full Xcode."
    echo "   Run: sudo xcode-select -s /Applications/Xcode.app"
    exit 1
fi

# Download and install
LATEST_VERSION=$(curl -s https://api.github.com/repos/YOUR_USERNAME/brx/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL="https://github.com/YOUR_USERNAME/brx/releases/download/${LATEST_VERSION}/brx-${LATEST_VERSION}-macos.tar.gz"

echo "📦 Downloading brx ${LATEST_VERSION}..."
curl -fsSL "${DOWNLOAD_URL}" -o /tmp/brx.tar.gz

echo "📂 Extracting..."
tar -xzf /tmp/brx.tar.gz -C /tmp

echo "🔧 Installing to /usr/local/bin..."
sudo install -m 0755 /tmp/BRX /usr/local/bin/brx

# Cleanup
rm /tmp/brx.tar.gz /tmp/BRX

# Run doctor
echo ""
echo "✅ brx installed successfully!"
echo ""
echo "Running initial setup..."
brx doctor

echo ""
echo "🎉 All done! Try: brx init --template swiftui-todo --name MyApp"

