import Foundation
import ArgumentParser

@main
struct BRX: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "brx",
        abstract: "Build, run, and ship iOS apps from your terminal.",
        version: "3.2.0",
        subcommands: [
            BuildCommand.self,
            RunCommand.self,
            WatchCommand.self,
            DevicesCommand.self,
            SettingsCommand.self,
            DoctorCommand.self,
            ShipCommand.self,
            PublishCommand.self,
            ActivateCommand.self,
            StatusCommand.self,
            WelcomeCommand.self
        ]
    )
    
    func run() async throws {
        // Load or create config
        _ = BRXConfig.load()
        
        // Show beautiful menu with ASCII art first (only on main menu)
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)░██                                        \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░██                                        \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░████████  ░██░████ ░██    ░██             \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░██    ░██ ░███      ░██  ░██              \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░██    ░██ ░██        ░█████                \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░███   ░██ ░██       ░██  ░██              \(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.primary)░██░█████  ░██      ░██    ░██ ░██████████  \(Ansi.reset)")
        Terminal.writeLine("")
        let width = Terminal.width
        let version = Self.configuration.version
        let logo = "◻︎ brx — build. run. ship. ios. from terminal. v\(version)"
        let padding = max(0, (width - logo.count) / 2)
        Terminal.writeLine(String(repeating: "─", count: width))
        Terminal.write(String(repeating: " ", count: padding))
        Terminal.writeLine(logo)
        Terminal.writeLine(String(repeating: "─", count: width))
        
        // Show license status
        let (_, buildsRemaining) = License.canBuild()
        Terminal.writeLine("")
        if License.isActivated {
            Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) License: \(Theme.current.success)Active\(Ansi.reset) • \(Theme.current.success)Unlimited builds\(Ansi.reset)")
        } else {
            if buildsRemaining > 0 {
                Terminal.writeLine("  \(Theme.current.muted)○\(Ansi.reset) License: \(Theme.current.muted)Free\(Ansi.reset) • \(Theme.current.primary)\(buildsRemaining)\(Ansi.reset)\(Theme.current.muted) build\(buildsRemaining == 1 ? "" : "s") remaining\(Ansi.reset)")
            } else {
                Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) License: \(Theme.current.error)Required\(Ansi.reset) • \(Theme.current.error)0 builds remaining\(Ansi.reset)")
            }
        }
        
        // Show available devices
        Terminal.writeLine("")
        Terminal.writeLine("  \(Theme.current.primary)Devices Available:\(Ansi.reset)")
        Terminal.writeLine("")
        
        // Show connected physical devices first
        do {
            let physicalDevices = try DeviceCtl.listPhysicalDevices()
            if !physicalDevices.isEmpty {
                Terminal.writeLine("  \(Theme.current.success)📱 Connected:\(Ansi.reset)")
                for device in physicalDevices {
                    Terminal.writeLine("    • \(Theme.current.primary)\(device.name)\(Ansi.reset)")
                }
                Terminal.writeLine("")
            }
        } catch {
            // Silently skip if no physical devices or devicectl unavailable
        }
        
        // Show default simulator
        do {
            let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "devices", "--json"])
            if result.success, let data = result.stdout.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let devicesDict = json["devices"] as? [String: [[String: Any]]] {
                
                // Find iPhone 17 Pro Max or first available iOS device
                for (runtimeKey, devices) in devicesDict where runtimeKey.contains("iOS") {
                    for device in devices {
                        if let name = device["name"] as? String,
                           let state = device["state"] as? String,
                           state == "Booted" || name.contains("iPhone 17 Pro Max") {
                            Terminal.writeLine("  \(Theme.current.muted)📲 Default Simulator:\(Ansi.reset)")
                            Terminal.writeLine("    • \(Theme.current.primary)\(name)\(Ansi.reset)")
                            Terminal.writeLine("")
                            break
                        }
                    }
                    break
                }
            }
        } catch {
            // Silently skip if can't list simulators
        }
        
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Build\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  🚀 \(Theme.current.primary)build\(Ansi.reset)    \(Theme.current.muted)- create project from template & build\(Ansi.reset)")
        Terminal.writeLine("  ▶️  \(Theme.current.primary)run\(Ansi.reset)      \(Theme.current.muted)- build, launch & watch for changes\(Ansi.reset)")
        Terminal.writeLine("  📱 \(Theme.current.primary)run --realsim\(Ansi.reset) \(Theme.current.muted)- launch on connected iPhone\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Test & Deploy\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  🚢 \(Theme.current.primary)ship\(Ansi.reset)     \(Theme.current.muted)- archive & upload to TestFlight\(Ansi.reset)")
        Terminal.writeLine("  🏪 \(Theme.current.primary)publish\(Ansi.reset)  \(Theme.current.muted)- submit for App Store review\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)BRX Settings\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  📊 \(Theme.current.primary)status\(Ansi.reset)   \(Theme.current.muted)- show license status & build count\(Ansi.reset)")
        Terminal.writeLine("  ⚙️  \(Theme.current.primary)settings\(Ansi.reset) \(Theme.current.muted)- configure defaults & preferences\(Ansi.reset)")
        Terminal.writeLine("  📱 \(Theme.current.primary)devices\(Ansi.reset)  \(Theme.current.muted)- list/manage simulators & devices\(Ansi.reset)")
        Terminal.writeLine("  🔍 \(Theme.current.primary)doctor\(Ansi.reset)   \(Theme.current.muted)- check environment & dependencies\(Ansi.reset)")
        Terminal.writeLine("  🔑 \(Theme.current.primary)activate\(Ansi.reset) \(Theme.current.muted)- activate license\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.muted)Run \(Theme.current.primary)brx <command> --help\(Theme.current.muted) for detailed help\(Ansi.reset)")
        Terminal.writeLine("\(Theme.current.muted)Visit: https://github.com/thegptpros/brx\(Ansi.reset)")
        Terminal.writeLine("")
        
        // Interactive prompt
        Terminal.write("\(Theme.current.primary)What would you like to do?\(Ansi.reset) ")
        Terminal.write("\(Theme.current.muted)(e.g. 'run', 'build', 'devices')\(Ansi.reset) → ")
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
            return
        }
        
        if input.isEmpty {
            return
        }
        
        // Map common inputs to commands
        switch input {
        case "run", "r":
            try await RunCommand().run()
        case "realsim", "rs":
            try await RunCommand(realsim: true).run()
        case "build", "b":
            try await BuildCommand().run()
        case "ship", "s":
            try await ShipCommand().run()
        case "publish", "p":
            try await PublishCommand().run()
        case "devices", "d":
            try await DevicesCommand.List().run()
        case "status":
            try await StatusCommand().run()
        case "activate", "a":
            try await ActivateCommand().run()
        case "doctor", "doc":
            try await DoctorCommand().run()
        case "settings", "set":
            try await SettingsCommand().run()
        default:
            Terminal.writeLine("")
            Terminal.writeLine("\(Theme.current.error)Unknown command: \(input)\(Ansi.reset)")
            Terminal.writeLine("")
            Terminal.writeLine("Available commands: run, realsim, build, ship, publish, devices, status, activate, doctor, settings")
            Terminal.writeLine("")
        }
    }
}

