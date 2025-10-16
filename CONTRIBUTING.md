# Contributing to BRX

Thank you for your interest in contributing to BRX! This document provides guidelines and instructions for contributing.

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/brx.git`
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Run tests: `make test`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to your branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## 🏗 Development Setup

### Requirements

- macOS 14+
- Xcode 15+ with Command Line Tools
- Swift 5.9+

### Building

```bash
swift build
```

### Running Tests

```bash
make test
# or
swift test
```

### Installing Locally

```bash
make install
```

This installs to `/usr/local/bin/brx`.

## 📝 Code Style

- Follow Swift API Design Guidelines
- Use SwiftFormat (config in `.swiftformat`)
- Keep functions under 150 lines
- Move complex logic to `Sources/BRX/Core/`
- Add tests for new features

## 🧪 Testing

- Add unit tests for new Core functionality
- Add smoke tests for new templates
- Ensure all tests pass before submitting PR
- Test on actual Xcode installation when possible

## 📦 Adding Templates

New templates should include:

1. `brx.yml` with proper configuration
2. `Sources/` directory with Swift files
3. `Resources/` directory with assets
4. Smoke tests in `Tests/TemplateSmokeTests.swift`

## 🐛 Bug Reports

When filing a bug report, please include:

- BRX version (`brx --version`)
- macOS version
- Xcode version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages or logs

## 💡 Feature Requests

Feature requests are welcome! Please:

- Check existing issues first
- Describe the use case
- Explain why it would be valuable
- Consider if it fits BRX's terminal-first philosophy

## 🔍 Code Review

All submissions require review. We'll:

- Check code quality and style
- Verify tests pass
- Ensure documentation is updated
- Test functionality when possible

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You

Your contributions make BRX better for everyone!

