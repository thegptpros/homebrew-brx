import Foundation
import ArgumentParser

struct RunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Build, run on simulator & watch for changes"
    )
    
    @Option(name: .long, help: "Target device (overrides config)")
    var device: String?
    
    @Flag(name: .long, help: "Show verbose xcodebuild output")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Run once without watching for changes")
    var noWatch: Bool = false
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        // Check build limit (allows 10 free builds or unlimited with license)
        let (canBuild, _) = License.canBuild()
        guard canBuild else {
            throw LicenseError.buildLimitReached
        }
        
        Telemetry.trackCommand("run")
        
        // Increment build count immediately (before potentially long build)
        License.incrementBuildCount()
        
        // Load project spec
        let spec = try ProjectSpec.load()
        let config = BRXConfig.load()
        
        // Determine device
        let targetDevice = device ?? config.defaults.iosDevice
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let scheme = spec.scheme ?? spec.name
        
        // Ensure device exists
        let udid = try Simulator.ensureDevice(named: targetDevice, platform: .iOS)
        
        Logger.step("⚙️", "building \(spec.name) (Debug)")
        
        let destination = "platform=iOS Simulator,id=\(udid)"
        let appPath = try XcodeTools.build(
            project: projectPath,
            scheme: scheme,
            configuration: "Debug",
            destination: destination
        )
        
        Logger.step("📱", "booting \(targetDevice) (Simulator)")
        try Simulator.bootIfNeeded(udid: udid)
        
        Logger.step("📦", "installing app...")
        try Simulator.install(appPath: appPath, toUDID: udid)
        
        Logger.step("🚀", "launching app...")
        let (pid, osVersion) = try Simulator.launch(bundleId: spec.bundleId, onUDID: udid)
        
        Logger.success("running \"\(spec.name)\" on \(targetDevice) (ios \(osVersion)) — pid \(pid)")
        Terminal.writeLine("")
        
        // Show build limit message (only for free users)
        License.showBuildLimitMessage()
        
        // Start watching for changes unless --no-watch is specified
        if !noWatch {
            Logger.step("👀", "watching for changes (Press Ctrl+C to stop)")
            Terminal.writeLine("")
            
            let watchPaths = ["./Sources", "./Resources"].filter { FS.exists($0) }
            
            let liveReload = LiveReload(watchPaths: watchPaths) { changeType in
                Task {
                    do {
                        let start = Date()
                        
                        switch changeType {
                        case .assets:
                            // Fast path: just reinstall
                            try await self.fastReload(spec: spec, udid: udid)
                            let elapsed = Date().timeIntervalSince(start)
                            Logger.step("Δ", "assets  → fast install & relaunch (\(Int(elapsed * 1000)) ms)")
                            
                        case .code:
                            // Full rebuild
                            try await self.fullRebuild(spec: spec, config: config, udid: udid, destination: destination)
                            let elapsed = Date().timeIntervalSince(start)
                            Logger.step("Δ", "code    → incremental build, install, launch (\(String(format: "%.1f", elapsed)) s)")
                        }
                    } catch {
                        Logger.error("Reload failed: \(error)")
                    }
                }
            }
            
            liveReload.start()
            
            // Keep the process running indefinitely
            while true {
                try await Task.sleep(nanoseconds: 1_000_000_000_000) // Sleep for ~16 minutes at a time
            }
        }
    }
    
    private func fastReload(spec: ProjectSpec, udid: String) async throws {
        // Terminate app
        try Shell.run("xcrun", args: ["simctl", "terminate", udid, spec.bundleId])
        
        // Find .app path
        let appPath = ".brx/DerivedData/Build/Products/Debug-iphonesimulator/\(spec.name).app"
        
        // Reinstall
        try Simulator.install(appPath: appPath, toUDID: udid)
        
        // Relaunch
        _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: udid)
    }
    
    private func fullRebuild(spec: ProjectSpec, config: BRXConfig, udid: String, destination: String) async throws {
        // Auto-regenerate project if project.yml exists (for new files/directories)
        if FS.exists("project.yml") {
            Logger.step("🔄", "regenerating project for new files")
            try ProjectGen.generate(spec: spec)
        }
        
        // Build
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let scheme = spec.scheme ?? spec.name
        
        let appPath = try XcodeTools.build(
            project: projectPath,
            scheme: scheme,
            configuration: "Debug",
            destination: destination
        )
        
        // Terminate
        try Shell.run("xcrun", args: ["simctl", "terminate", udid, spec.bundleId])
        
        // Install
        try Simulator.install(appPath: appPath, toUDID: udid)
        
        // Launch
        _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: udid)
    }
}

