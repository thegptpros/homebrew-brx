# BRX Release Checklist - Make It All Work

## Recent Changes Made
1. ✅ Created `swiftui-blank` template (minimal SwiftUI app)
2. ✅ Updated `BuildCommand.swift` to use `swiftui-blank` as default
3. ✅ Fixed `project.yml` with proper build targets to prevent "Supported platforms" error
4. ✅ Updated `ProjectGen.swift` to find xcodegen in common paths
5. ✅ Added proper simulator destination handling in BuildCommand

## Commands to Execute (Run in Terminal)

### 1. Navigate to BRX directory
```bash
cd /Users/zac/Desktop/code/brx
```

### 2. Verify templates exist
```bash
ls -la Templates/swiftui-blank/
# Should show: Sources/, Resources/, project.yml, brx.yml
```

### 3. Build BRX in release mode
```bash
swift build -c release
```

### 4. Copy built binary to your PATH
```bash
cp .build/release/BRX /usr/local/bin/brx
chmod +x /usr/local/bin/brx
```

### 5. Copy templates to user directory
```bash
mkdir -p ~/.local/share/brx
cp -r Templates ~/.local/share/brx/
```

### 6. Verify installation
```bash
which brx
brx --version
```

### 7. Test the build command
```bash
cd ~/Desktop
brx build --name TestApp
```

Expected output:
```
──────────────────────────────────────────────────────────────────────────────────────────
                      ◻︎ brx — build. run. ship. ios. from terminal.
──────────────────────────────────────────────────────────────────────────────────────────

🚀  creating TestApp from swiftui-blank template
⚙️  generating Xcode project
🔨  building project
✅  build succeeded
```

### 8. Test the run command
```bash
cd TestApp
brx run
```

Expected: App launches in simulator with auto-watch enabled

### 9. If tests pass, commit and push
```bash
cd /Users/zac/Desktop/code/brx
git add -A
git commit -m "feat: add swiftui-blank template, fix build destination, prevent platform errors"
git push origin main
```

### 10. Create new release tag
```bash
git tag -a v3.1.3 -m "v3.1.3 - Magical build experience with blank template"
git push origin v3.1.3
```

### 11. GitHub Action will automatically:
- Build the release binary
- Create tarball with Templates/ included
- Upload to GitHub releases
- Update Homebrew formula

### 12. Test Homebrew installation (after release completes)
```bash
brew update
brew upgrade brx
brx --version  # Should show v3.1.3
```

## Critical Files Changed

1. **Templates/swiftui-blank/project.yml** - Added build targets section
2. **Templates/swiftui-blank/Sources/** - Complete minimal SwiftUI app
3. **Sources/BRX/CLI/BuildCommand.swift** - Changed default template, fixed destination
4. **Sources/BRX/Core/ProjectGen.swift** - Better xcodegen path resolution

## What Makes This "Magical"

✨ **One command to build**: `brx build --name MyApp` creates AND builds
✨ **Auto-generates Xcode project**: No manual xcodegen needed
✨ **Blank slate**: Clean SwiftUI template, no todos/cruft
✨ **Templates bundled**: Users don't download separately
✨ **3 free builds**: Freemium model encourages adoption
✨ **Auto-watch on run**: No separate watch command needed

## Troubleshooting

### If "Template not found" error:
```bash
mkdir -p ~/.local/share/brx
cp -r /Users/zac/Desktop/code/brx/Templates ~/.local/share/brx/
```

### If "xcodegen not found" error:
```bash
brew install xcodegen
```

### If "Supported platforms" error:
- Already fixed in v3.1.3 with build targets in project.yml

### If destination errors:
- Already fixed in v3.1.3 with proper UDID resolution

## Next Steps After Release

1. Update brx-site homepage if needed
2. Post to Product Hunt with `/producthunt` promo
3. Monitor admin dashboard for activations
4. Celebrate 🎉

