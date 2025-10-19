import Foundation
import ArgumentParser

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch",
        abstract: "Watch for changes and rebuild/relaunch"
    )
    
    @Option(name: .long, help: "Target device")
    var device: String?
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        Telemetry.trackCommand("watch")
        
        let spec = try ProjectSpec.load()
        let config = BRXConfig.load()
        let targetDevice = device ?? config.defaults.iosDevice
        
        let udid = try Simulator.ensureDevice(named: targetDevice, platform: .iOS)
        
        Logger.step("👀", "watching Sources/ and Resources/ (device: \(targetDevice))")
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
                        try await self.fullRebuild(spec: spec, udid: udid)
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
    
    private func fastReload(spec: ProjectSpec, udid: String) async throws {
        // Terminate app
        try Simulator.terminate(bundleId: spec.bundleId, onUDID: udid)
        
        // Get existing app path from last build
        let derivedDataPath = "\(FS.currentDirectory())/.brx/DerivedData"
        let appPath = "\(derivedDataPath)/Build/Products/Debug-iphonesimulator/\(spec.name).app"
        
        // Reinstall and launch
        try Simulator.install(appPath: appPath, toUDID: udid)
        _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: udid)
    }
    
    private func fullRebuild(spec: ProjectSpec, udid: String) async throws {
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let scheme = spec.scheme ?? spec.name
        let destination = "platform=iOS Simulator,id=\(udid)"
        
        // Build
        let appPath = try XcodeTools.build(
            project: projectPath,
            scheme: scheme,
            configuration: "Debug",
            destination: destination
        )
        
        // Terminate, install, launch
        try Simulator.terminate(bundleId: spec.bundleId, onUDID: udid)
        try Simulator.install(appPath: appPath, toUDID: udid)
        _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: udid)
    }
}

