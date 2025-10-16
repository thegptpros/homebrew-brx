import Foundation
import ArgumentParser

struct PublishCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "publish",
        abstract: "Submit for App Store review"
    )
    
    @Option(name: .long, help: "Apple ID email")
    var appleId: String?
    
    @Option(name: .long, help: "App-specific password")
    var appPassword: String?
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        // Require license
        try License.requireLicense()
        
        Telemetry.trackCommand("publish")
        
        let config = BRXConfig.load()
        
        Logger.step("👀", "submitting for review")
        
        // Submit for App Store review using App Store Connect API
        try await XcodeTools.submitForReview(
            appleId: appleId ?? config.fastlane.appleId,
            appPassword: appPassword ?? config.fastlane.appPassword
        )
        
        Logger.success("submitted for App Store review")
        Terminal.writeLine("")
        Terminal.writeLine("  \(Theme.current.muted)→ Track review at: https://appstoreconnect.apple.com\(Ansi.reset)")
        Terminal.writeLine("")
    }
}

