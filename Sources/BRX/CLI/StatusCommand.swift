import Foundation
import ArgumentParser

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show license status and build information"
    )
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        Telemetry.trackCommand("status")
        
        let config = BRXConfig.load()
        let (_, buildsRemaining) = License.canBuild()
        
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)BRX Status\(Ansi.reset)")
        Terminal.writeLine("")
        
        // License Status
        if License.isActivated {
            Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) License: \(Theme.current.success)Active\(Ansi.reset)")
            Terminal.writeLine("  \(Theme.current.muted)→ Key: \(config.license.key)\(Ansi.reset)")
            Terminal.writeLine("  \(Theme.current.muted)→ Activated: \(config.license.activatedAt)\(Ansi.reset)")
            Terminal.writeLine("  \(Theme.current.muted)→ Builds: \(Theme.current.success)Unlimited\(Ansi.reset)")
        } else {
            Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) License: \(Theme.current.error)Not Activated\(Ansi.reset)")
            Terminal.writeLine("  \(Theme.current.muted)→ Builds used: \(config.buildCount)/3\(Ansi.reset)")
            
            if buildsRemaining > 0 {
                Terminal.writeLine("  \(Theme.current.muted)→ Builds remaining: \(Theme.current.primary)\(buildsRemaining)\(Ansi.reset)")
            } else {
                Terminal.writeLine("  \(Theme.current.muted)→ Builds remaining: \(Theme.current.error)0\(Ansi.reset)")
            }
        }
        
        Terminal.writeLine("")
        
        // Next Steps
        if !License.isActivated {
            if buildsRemaining > 0 {
                Terminal.writeLine("\(Theme.current.primary)Next Steps:\(Ansi.reset)")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.muted)→ You have \(buildsRemaining) free build\(buildsRemaining == 1 ? "" : "s") remaining\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Get unlimited builds: \(Theme.current.primary)https://brx.dev\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Activate license: \(Theme.current.primary)brx activate --license-key <your-key>\(Ansi.reset)")
            } else {
                Terminal.writeLine("\(Theme.current.error)Action Required:\(Ansi.reset)")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.muted)→ You've used all 3 free builds\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Purchase license: \(Theme.current.primary)https://brx.dev\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Activate license: \(Theme.current.primary)brx activate --license-key <your-key>\(Ansi.reset)")
            }
        } else {
            Terminal.writeLine("\(Theme.current.success)Ready to build!\(Ansi.reset)")
            Terminal.writeLine("")
            Terminal.writeLine("  \(Theme.current.muted)→ Run: \(Theme.current.primary)brx build --name MyApp\(Ansi.reset)")
            Terminal.writeLine("  \(Theme.current.muted)→ Or: \(Theme.current.primary)brx run\(Ansi.reset)")
        }
        
        Terminal.writeLine("")
    }
}
