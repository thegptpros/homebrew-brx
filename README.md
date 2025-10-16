# brx

Build, run, and ship iOS & watchOS apps from your terminal. No UI. Fast. Beautiful.

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/<you>/brx/main/scripts/bootstrap.sh | bash

# Or manual install
make install

# Verify
brx doctor

# Create a new app
brx init --template swiftui-todo --name MyApp
cd MyApp

# Run it
brx run

# Watch for changes
brx watch

# Ship to TestFlight
brx ship
```

## Requirements

- macOS 14+
- Xcode 15+ (full Xcode, not just Command Line Tools)
- Swift 5.9+

## Commands

- `brx init` - Create a new project from template
- `brx run` - Build and run on simulator
- `brx watch` - Live reload on file changes
- `brx devices` - List/manage simulators
- `brx settings` - Configure defaults
- `brx doctor` - Check environment
- `brx ship` - Archive and upload to TestFlight
- `brx publish` - Submit for App Store review

## Configuration

Config stored at `~/.config/brx/config.json`

Default devices:
- iPhone 17 Pro Max (iOS)
- Apple Watch Ultra 2 49mm (watchOS)

## Templates

- `swiftui-todo` - SwiftUI todo list app
- `ball-game` - SpriteKit bouncing ball game
- `watch-counter` - watchOS counter app
- `blank` - Minimal SwiftUI shell

## License

MIT

