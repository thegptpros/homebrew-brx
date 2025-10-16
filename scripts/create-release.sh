#!/bin/bash
# Create a GitHub release for BRX

set -e

VERSION=${1:-"3.0.0"}

echo "📦 Creating BRX release v${VERSION}"

# Build release binary
echo "🔨 Building..."
make build

# Create archive with binary and templates
echo "📦 Creating archive..."
mkdir -p dist
tar -czf dist/brx-${VERSION}-macos.tar.gz \
  -C .build/release BRX \
  -C ../../.. Templates

# Calculate SHA256
echo ""
echo "✅ Release created: dist/brx-${VERSION}-macos.tar.gz"
echo ""
echo "📊 SHA256:"
shasum -a 256 dist/brx-${VERSION}-macos.tar.gz

echo ""
echo "📝 Next steps:"
echo "  1. Go to: https://github.com/thegptpros/brx/releases/new"
echo "  2. Tag: v${VERSION}"
echo "  3. Upload: dist/brx-${VERSION}-macos.tar.gz"
echo "  4. Update Formula/brx.rb with new SHA256 and version"
echo "  5. Push to homebrew-brx repo"
echo ""

