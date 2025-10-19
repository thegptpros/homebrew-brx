import Foundation
import ArgumentParser

struct ShipCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ship",
        abstract: "Archive and upload to TestFlight"
    )
    
    @Option(name: .long, help: "Scheme name")
    var scheme: String?
    
    @Option(name: .long, help: "Apple ID email")
    var appleId: String?
    
    @Option(name: .long, help: "App-specific password")
    var appPassword: String?
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        // Require license
        try License.requireLicense()
        
        Telemetry.trackCommand("ship")
        
        let config = BRXConfig.load()
        let spec = try ProjectSpec.load()
        let schemeName = scheme ?? spec.scheme ?? spec.name
        
        Logger.step("📦", "archiving \(spec.name)...")
        
        // Create archive using xcodebuild
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let archivePath = try await XcodeTools.archive(
            project: projectPath,
            scheme: schemeName,
            configuration: "Release"
        )
        
        Logger.step("🔐", "signing with distribution certificate...")
        
        // Export IPA for App Store distribution
        let ipaPath = try await XcodeTools.exportIPA(
            archivePath: archivePath,
            exportMethod: "app-store"
        )
        
        Logger.step("☁️", "uploading to TestFlight...")
        
        // Upload to TestFlight using xcrun altool
        try await XcodeTools.uploadToTestFlight(
            ipaPath: ipaPath,
            appleId: appleId ?? config.fastlane.appleId,
            appPassword: appPassword ?? config.fastlane.appPassword
        )
        
        Logger.step("⏳", "processing build (this may take a moment)...")
        
        Logger.success("build live on TestFlight")
        Terminal.writeLine("  \(Theme.current.primary)🎯\(Ansi.reset)  ready for internal testing")
        Terminal.writeLine("")
        Terminal.writeLine("  \(Theme.current.muted)→ View at: https://appstoreconnect.apple.com\(Ansi.reset)")
        Terminal.writeLine("")
    }
}

