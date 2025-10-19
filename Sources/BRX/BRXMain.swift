import Foundation
import ArgumentParser

@main
struct BRX: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "brx",
        abstract: "Build, run, and ship iOS apps from your terminal.",
        version: "3.1.6",
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
            StatusCommand.self
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
        let logo = "◻︎ brx — build. run. ship. ios. from terminal."
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
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Build\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  🚀 \(Theme.current.primary)build\(Ansi.reset)    \(Theme.current.muted)- create project from template & build\(Ansi.reset)")
        Terminal.writeLine("  ▶️  \(Theme.current.primary)run\(Ansi.reset)      \(Theme.current.muted)- build, launch & watch for changes\(Ansi.reset)")
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
        Terminal.writeLine("\(Theme.current.muted)Visit: https://github.com/yourusername/brx\(Ansi.reset)")
        Terminal.writeLine("")
    }
}

