#!/bin/bash
set -e

echo "🧪 BRX End-to-End Test Script"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

test_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# 1. Check if brx is in PATH
test_step "Checking if brx is installed..."
if command -v brx &> /dev/null; then
    BRX_PATH=$(which brx)
    test_pass "brx found at: $BRX_PATH"
else
    test_fail "brx not found in PATH"
    echo "Run: cp .build/release/BRX /usr/local/bin/brx"
    exit 1
fi

# 2. Check version
test_step "Checking brx version..."
if brx --version &> /dev/null; then
    VERSION=$(brx --version 2>&1 | head -1)
    test_pass "Version: $VERSION"
else
    test_fail "Could not get version"
fi

# 3. Check if templates directory exists
test_step "Checking for templates..."
TEMPLATE_PATHS=(
    "$HOME/.local/share/brx/Templates"
    "/opt/homebrew/share/brx/Templates"
    "/usr/local/share/brx/Templates"
    "./Templates"
)

TEMPLATE_FOUND=false
for path in "${TEMPLATE_PATHS[@]}"; do
    if [ -d "$path/swiftui-blank" ]; then
        test_pass "Found swiftui-blank template at: $path"
        TEMPLATE_FOUND=true
        break
    fi
done

if [ "$TEMPLATE_FOUND" = false ]; then
    test_fail "No templates found. Run: cp -r Templates ~/.local/share/brx/"
    exit 1
fi

# 4. Check if xcodegen is installed
test_step "Checking for xcodegen..."
if command -v xcodegen &> /dev/null; then
    test_pass "xcodegen found"
else
    test_fail "xcodegen not found. Run: brew install xcodegen"
    exit 1
fi

# 5. Create test project
test_step "Creating test project..."
TEST_DIR="/tmp/brx-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if brx build --name BRXTest 2>&1 | tee build.log; then
    test_pass "Project created and built"
else
    test_fail "Build failed"
    echo "Build log:"
    cat build.log
    exit 1
fi

# 6. Check if project files exist
test_step "Verifying project structure..."
if [ -d "BRXTest" ]; then
    test_pass "Project directory exists"
else
    test_fail "Project directory not created"
    exit 1
fi

if [ -f "BRXTest/brx.yml" ]; then
    test_pass "brx.yml exists"
else
    test_fail "brx.yml not found"
fi

if [ -f "BRXTest/project.yml" ]; then
    test_pass "project.yml exists"
else
    test_fail "project.yml not found"
fi

if [ -f "BRXTest/BRXTest.xcodeproj/project.pbxproj" ]; then
    test_pass "Xcode project generated"
else
    test_fail "Xcode project not generated"
fi

# 7. Check if app was built
test_step "Verifying build output..."
cd BRXTest
BUILD_DIR=$(find . -name "BRXTest.app" -type d | head -1)
if [ -n "$BUILD_DIR" ]; then
    test_pass "App bundle created: $BUILD_DIR"
else
    test_fail "App bundle not found"
fi

# 8. Test rebuild (should work in existing project)
test_step "Testing rebuild..."
if brx build 2>&1 | tee rebuild.log; then
    test_pass "Rebuild successful"
else
    test_fail "Rebuild failed"
    cat rebuild.log
fi

# Summary
echo ""
echo "================================"
echo "🧪 Test Results"
echo "================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "❌ Some tests failed. Please fix before release."
    exit 1
else
    echo -e "${GREEN}All tests passed! ✨${NC}"
    echo ""
    echo "Ready to release! Run:"
    echo "  git add -A"
    echo "  git commit -m 'feat: magical build experience with templates'"
    echo "  git tag -a v3.1.3 -m 'v3.1.3'"
    echo "  git push origin main"
    echo "  git push origin v3.1.3"
fi

# Cleanup
echo ""
echo "Cleaning up test directory: $TEST_DIR"
cd /
rm -rf "$TEST_DIR"

