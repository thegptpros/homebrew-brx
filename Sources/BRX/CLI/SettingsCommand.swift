import Foundation
import ArgumentParser

struct SettingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "settings",
        abstract: "View and update configuration"
    )
    
    @Option(name: .long, help: "Theme (proMono or aurora)")
    var theme: String?
    
    @Option(name: .long, help: "Logo mode (on, static, off)")
    var logo: String?
    
    @Option(name: .long, help: "iOS default device")
    var ios: String?
    
    @Option(name: .long, help: "watchOS default device")
    var watch: String?
    
    @Option(name: .long, help: "Telemetry (on or off)")
    var telemetry: String?
    
    @Option(name: .long, help: "Fastlane Apple ID")
    var appleId: String?
    
    @Option(name: .long, help: "Fastlane Team ID")
    var teamId: String?
    
    @Option(name: .long, help: "Fastlane API key path")
    var apiKeyPath: String?
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        var config = BRXConfig.load()
        var changed = false
        
        if let themeValue = theme {
            config.theme = themeValue
            changed = true
            Logger.success("Theme set to '\(themeValue)'")
        }
        
        if let logoValue = logo {
            config.logoMode = logoValue
            changed = true
            Logger.success("Logo mode set to '\(logoValue)'")
        }
        
        if let iosDevice = ios {
            config.defaults.iosDevice = iosDevice
            changed = true
            Logger.success("iOS default device set to '\(iosDevice)'")
        }
        
        if let watchDevice = watch {
            config.defaults.watchDevice = watchDevice
            changed = true
            Logger.success("watchOS default device set to '\(watchDevice)'")
        }
        
        if let telemetryValue = telemetry {
            config.telemetry = telemetryValue.lowercased() == "on"
            changed = true
            Logger.success("Telemetry set to '\(telemetryValue)'")
        }
        
        if let appleIdValue = appleId {
            config.fastlane.appleId = appleIdValue
            changed = true
            Logger.success("Fastlane Apple ID set")
        }
        
        if let teamIdValue = teamId {
            config.fastlane.teamId = teamIdValue
            changed = true
            Logger.success("Fastlane Team ID set")
        }
        
        if let apiKeyPathValue = apiKeyPath {
            config.fastlane.apiKeyPath = apiKeyPathValue
            changed = true
            Logger.success("Fastlane API key path set")
        }
        
        if changed {
            try config.save()
            Terminal.writeLine("")
        } else {
            // Show current settings
            Terminal.writeLine("")
            Terminal.writeLine("\(Theme.current.primary)Current Settings:\(Ansi.reset)")
            Terminal.writeLine("")
            Terminal.writeLine("  Theme:         \(config.theme)")
            Terminal.writeLine("  Logo mode:     \(config.logoMode)")
            Terminal.writeLine("  iOS device:    \(config.defaults.iosDevice)")
            Terminal.writeLine("  watch device:  \(config.defaults.watchDevice)")
            Terminal.writeLine("  Telemetry:     \(config.telemetry ? "on" : "off")")
            Terminal.writeLine("")
            Terminal.writeLine("  Config file:   \(BRXConfig.configPath)")
            Terminal.writeLine("")
        }
    }
}

