import Foundation
import ArgumentParser

struct SetupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "setup",
        abstract: "Interactive setup for deployment credentials"
    )
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        var config = BRXConfig.load()
        
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)🚀 BRX Deployment Setup\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("Configure your App Store Connect credentials for TestFlight and App Store deployment.")
        Terminal.writeLine("")
        
        // Apple ID
        Terminal.writeLine("\(Theme.current.primary)1. Apple ID Email\(Ansi.reset)")
        Terminal.writeLine("   Enter your Apple ID email address:")
        let appleId = readLine() ?? ""
        
        if !appleId.isEmpty {
            config.fastlane.appleId = appleId
            Logger.success("Apple ID set to: \(appleId)")
        }
        
        Terminal.writeLine("")
        
        // Team ID
        Terminal.writeLine("\(Theme.current.primary)2. Team ID\(Ansi.reset)")
        Terminal.writeLine("   Enter your Apple Developer Team ID (found in App Store Connect):")
        let teamId = readLine() ?? ""
        
        if !teamId.isEmpty {
            config.fastlane.teamId = teamId
            Logger.success("Team ID set to: \(teamId)")
        }
        
        Terminal.writeLine("")
        
        // App-specific password
        Terminal.writeLine("\(Theme.current.primary)3. App-Specific Password\(Ansi.reset)")
        Terminal.writeLine("   Generate an app-specific password at:")
        Terminal.writeLine("   https://appleid.apple.com/account/manage")
        Terminal.writeLine("   Enter your app-specific password:")
        let appPassword = readLine() ?? ""
        
        if !appPassword.isEmpty {
            config.fastlane.appPassword = appPassword
            Logger.success("App-specific password configured")
        }
        
        Terminal.writeLine("")
        
        // Save configuration
        try config.save()
        
        Terminal.writeLine("\(Theme.current.primary)✅ Setup Complete!\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("You can now use:")
        Terminal.writeLine("  \(Theme.current.primary)brx ship\(Ansi.reset)    - Upload to TestFlight")
        Terminal.writeLine("  \(Theme.current.primary)brx publish\(Ansi.reset) - Submit to App Store")
        Terminal.writeLine("")
        Terminal.writeLine("To update settings later, use: \(Theme.current.primary)brx settings\(Ansi.reset)")
    }
}
