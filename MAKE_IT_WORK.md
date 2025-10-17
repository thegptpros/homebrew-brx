# 🚀 Make BRX Work - Complete Guide

## What We Fixed Today

### 1. ✅ Created Blank Template
- Added `Templates/swiftui-blank/` with minimal SwiftUI app
- Clean starting point (no todo cruft)
- Includes proper `project.yml` for XcodeGen

### 2. ✅ Fixed "Supported Platforms" Error
- Added `build.targets` section to `project.yml`
- Now generates proper Xcode scheme

### 3. ✅ Fixed Build Destination Error
- Updated `BuildCommand.swift` to get simulator UDID
- Constructs proper destination string for xcodebuild

### 4. ✅ Updated GitHub Actions
- Now packages Templates/ in release tarball
- Users get templates automatically with Homebrew

### 5. ✅ Template Search Paths
- Checks Homebrew location (`/opt/homebrew/share/brx/Templates`)
- Checks user directory (`~/.local/share/brx/Templates`)
- Works for development and production

## 🎯 Quick Start (You Need To Run These)

### Option A: Local Development Install
```bash
cd /Users/zac/Desktop/code/brx
chmod +x install-local.sh
./install-local.sh
```

This will:
1. Build BRX in release mode
2. Copy to /usr/local/bin/brx
3. Copy templates to ~/.local/share/brx/
4. Verify xcodegen is installed

### Option B: Test Everything
```bash
cd /Users/zac/Desktop/code/brx
chmod +x test-brx.sh
./test-brx.sh
```

This will:
1. Check brx is installed
2. Verify templates exist
3. Create a test project
4. Build it
5. Verify the app was created

## 🚀 Release to Homebrew

Once tests pass:

```bash
cd /Users/zac/Desktop/code/brx

# 1. Commit all changes
git add -A
git commit -m "feat: magical build experience with blank template and fixed destinations"

# 2. Push to main
git push origin main

# 3. Create and push new version tag
git tag -a v3.1.3 -m "v3.1.3 - Blank template, fixed platforms, bundled templates"
git push origin v3.1.3
```

### GitHub Actions will automatically:
1. Build the release binary
2. Package it with Templates/
3. Create a GitHub release
4. Upload `brx-3.1.3-macos.tar.gz`

### Then update Homebrew formula:
```bash
# Download the release
curl -L https://github.com/thegptpros/homebrew-brx/releases/download/v3.1.3/brx-3.1.3-macos.tar.gz -o brx.tar.gz

# Get SHA256
shasum -a 256 brx.tar.gz

# Update Formula/brx.rb with new version and SHA
# Then commit and push
```

## 🧪 Testing Commands

After install, test the magic:

```bash
# Test 1: Create new project
cd ~/Desktop
brx build --name MagicTest

# Expected output:
# ──────────────────────────────────────────────────────────────────────────────────────────
#                       ◻︎ brx — build. run. ship. ios. from terminal.
# ──────────────────────────────────────────────────────────────────────────────────────────
# 
# 🚀  creating MagicTest from swiftui-blank template
# ⚙️  generating Xcode project
# 🔨  building project
# ✅  created ./MagicTest  • built successfully
# →  Next: cd MagicTest && brx run

# Test 2: Run the app
cd MagicTest
brx run

# Should:
# - Build the project
# - Launch in simulator
# - Start watching for changes

# Test 3: Rebuild in existing project
brx build

# Should:
# - Detect existing project
# - Build without creating new files
```

## 📁 Key Files Changed

1. **Templates/swiftui-blank/**
   - New minimal template
   - `project.yml` with build targets fix
   - Complete SwiftUI app structure

2. **Sources/BRX/CLI/BuildCommand.swift**
   - Changed default template to `swiftui-blank`
   - Fixed destination parameter
   - Auto-generates project with xcodegen

3. **.github/workflows/release.yml**
   - Now bundles Templates/ in release
   - Creates proper tarball structure

4. **Formula/brx.rb**
   - Already handles templates correctly
   - Installs to Homebrew share directory

## 🎯 What Makes This Magical

✨ **One Command**: `brx build --name MyApp` does everything
✨ **Auto-Generate**: No manual xcodegen needed
✨ **Clean Template**: Blank slate, not todo demo
✨ **3 Free Builds**: Try before you buy
✨ **Templates Bundled**: No separate download
✨ **Auto-Watch**: No separate watch command

## 🐛 Common Issues & Fixes

### "Template not found"
```bash
cp -r /Users/zac/Desktop/code/brx/Templates ~/.local/share/brx/
```

### "xcodegen not found"
```bash
brew install xcodegen
```

### "Supported platforms" error
Already fixed in v3.1.3! The `project.yml` now includes proper build targets.

### "Destination requires at least one parameter"
Already fixed in v3.1.3! BuildCommand now constructs proper destination.

### "spawn /bin/zsh ENOENT"
Restart your terminal/Cursor. This is a shell environment issue.

## ✅ Verification Checklist

Before releasing v3.1.3:

- [ ] Run `./install-local.sh` successfully
- [ ] Run `./test-brx.sh` - all tests pass
- [ ] Manually test: `brx build --name TestApp`
- [ ] Manually test: `cd TestApp && brx run`
- [ ] Verify app launches in simulator
- [ ] Commit and push all changes
- [ ] Create and push v3.1.3 tag
- [ ] Wait for GitHub Action to complete
- [ ] Update Homebrew formula
- [ ] Test Homebrew install: `brew upgrade brx`

## 🎉 Next Steps After Release

1. Test Homebrew installation
2. Update brx-site if needed
3. Post to Product Hunt
4. Monitor admin dashboard
5. Celebrate! 🎊

