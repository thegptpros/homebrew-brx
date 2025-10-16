import Foundation
import ArgumentParser

struct DoctorCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check environment and dependencies"
    )
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        Telemetry.trackCommand("doctor")
        
        Terminal.writeLine("")
        Logger.step("🩺", "checking environment...")
        Terminal.writeLine("")
        
        var hasErrors = false
        
        // Check xcodebuild
        if XcodeTools.checkXcodeBuild() {
            if let version = XcodeTools.getXcodeVersion() {
                Logger.success("Xcode \(version) installed")
            } else {
                Logger.success("xcodebuild found")
            }
        } else {
            Logger.error("xcodebuild not found")
            Terminal.writeLine("  \(Theme.current.muted)→ Install Xcode from the App Store\(Ansi.reset)")
            hasErrors = true
            throw ExitCode(10) // CLTOnly
        }
        
        // Check for Command Line Tools only
        let xcodeSelectResult = try? Shell.run("/usr/bin/xcode-select", args: ["-p"])
        if let path = xcodeSelectResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
           path.contains("CommandLineTools") {
            Logger.error("Only Command Line Tools installed (full Xcode required)")
            Terminal.writeLine("  \(Theme.current.muted)→ Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app\(Ansi.reset)")
            hasErrors = true
            throw ExitCode(10)
        }
        
        // Check runtimes
        do {
            _ = try Simulator.latestRuntimeID(for: .iOS)
            Logger.success("iOS runtime available")
        } catch {
            Logger.error("No iOS runtime found")
            Terminal.writeLine("  \(Theme.current.muted)→ Install via Xcode > Settings > Platforms\(Ansi.reset)")
            hasErrors = true
            throw ExitCode(11) // NoRuntime
        }
        
        do {
            _ = try Simulator.latestRuntimeID(for: .watchOS)
            Logger.success("watchOS runtime available")
        } catch {
            Logger.warning("No watchOS runtime found (optional)")
        }
        
        // Check/create default simulators
        let config = BRXConfig.load()
        
        do {
            _ = try Simulator.ensureDevice(named: config.defaults.iosDevice, platform: .iOS)
            Logger.success("iOS simulator ready (\(config.defaults.iosDevice))")
        } catch {
            Logger.error("Failed to create iOS simulator")
            Terminal.writeLine("  \(Theme.current.muted)→ Run: xcrun simctl list devicetypes\(Ansi.reset)")
            hasErrors = true
            throw ExitCode(12) // NoSim
        }
        
        do {
            _ = try Simulator.ensureDevice(named: config.defaults.watchDevice, platform: .watchOS)
            Logger.success("watchOS simulator ready (\(config.defaults.watchDevice))")
        } catch {
            Logger.warning("Failed to create watchOS simulator (optional)")
        }
        
        // Check devicectl
        if DeviceCtl.isAvailable() {
            Logger.success("devicectl available (Xcode 15+)")
        } else {
            Logger.warning("devicectl not available (requires Xcode 15+)")
        }
        
        // Check optional tools
        if Shell.which("xcodegen") != nil {
            Logger.success("XcodeGen installed")
        } else {
            Logger.warning("XcodeGen not found (optional)")
            Terminal.writeLine("  \(Theme.current.muted)→ Install with: brew install xcodegen\(Ansi.reset)")
        }
        
        if Shell.which("fastlane") != nil {
            Logger.success("Fastlane installed")
        } else {
            Logger.warning("Fastlane not found (needed for ship/publish)")
            Terminal.writeLine("  \(Theme.current.muted)→ Install with: gem install fastlane\(Ansi.reset)")
        }
        
        Terminal.writeLine("")
        
        if !hasErrors {
            Logger.success("All checks passed! You're ready to use brx.")
            Terminal.writeLine("")
        }
    }
}

