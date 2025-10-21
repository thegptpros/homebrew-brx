import Foundation
import ArgumentParser

struct RunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Build, run on device/simulator & watch for changes"
    )
    
    @Option(name: .long, help: "Target device (overrides config)")
    var device: String?
    
    @Flag(name: .long, help: "Show verbose xcodebuild output")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Run once without watching for changes")
    var noWatch: Bool = false
    
    @Flag(name: .long, help: "Launch on first connected physical device")
    var realsim: Bool = false
    
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
        
        // Determine device - handle -realsim flag first
        let targetDevice: String
        if realsim {
            // Use first connected physical device
            let physicalDevices = try DeviceCtl.listPhysicalDevices()
            if physicalDevices.isEmpty {
                throw RunCommandError.noDevicesAvailable
            }
            targetDevice = physicalDevices.first!.name
            Logger.step("📱", "using first connected device: \(targetDevice)")
        } else if let deviceArg = device {
            targetDevice = deviceArg
        } else if !config.defaults.iosDevice.isEmpty {
            targetDevice = config.defaults.iosDevice
        } else {
            // Show device selection menu
            targetDevice = try selectDevice()
        }
        
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let scheme = spec.scheme ?? spec.name
        
        // Find or create device (supports both simulators and physical devices)
        let targetDeviceInfo = try DeviceManager.ensureDevice(named: targetDevice)
        
        Logger.step("⚙️", "building \(spec.name) (Debug)")
        
        // Build for the appropriate platform
        let destination: String
        switch targetDeviceInfo.type {
        case .simulator:
            destination = "platform=iOS Simulator,id=\(targetDeviceInfo.udid)"
        case .physical:
            destination = "generic/platform=iOS"
        }
        
        let appPath = try XcodeTools.build(
            project: projectPath,
            scheme: scheme,
            configuration: "Debug",
            destination: destination
        )
        
        // Boot device if needed (only for simulators)
        if targetDeviceInfo.type == .simulator {
            Logger.step("📱", "booting \(targetDevice) (Simulator)")
            try DeviceManager.bootIfNeeded(targetDeviceInfo)
        } else {
            Logger.step("📱", "connecting to \(targetDevice) (Physical Device)")
            
            // Check if device is trusted
            let isTrusted = try DeviceManager.checkDeviceTrust(targetDeviceInfo)
            if !isTrusted {
                Logger.step("🔐", "device trust required")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.warning)⚠️  Device Trust Required\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Unlock your iPhone and tap 'Trust' when prompted\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Then run this command again\(Ansi.reset)")
                Terminal.writeLine("")
                throw DeviceError.deviceNotTrusted(targetDeviceInfo.udid)
            }
        }
        
        Logger.step("📦", "installing app...")
        try DeviceManager.install(appPath: appPath, to: targetDeviceInfo)
        
        Logger.step("🚀", "launching app...")
        
        if targetDeviceInfo.type == .simulator {
            let (pid, osVersion) = try Simulator.launch(bundleId: spec.bundleId, onUDID: targetDeviceInfo.udid)
            Logger.success("running \"\(spec.name)\" on \(targetDevice) (ios \(osVersion)) — pid \(pid)")
        } else {
            try DeviceManager.launch(bundleId: spec.bundleId, on: targetDeviceInfo)
            Logger.success("running \"\(spec.name)\" on \(targetDevice) (Physical Device)")
        }
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
                            try await self.fastReload(spec: spec, device: targetDeviceInfo)
                            let elapsed = Date().timeIntervalSince(start)
                            Logger.step("Δ", "assets  → fast install & relaunch (\(Int(elapsed * 1000)) ms)")
                            
                        case .code:
                            // Full rebuild
                            try await self.fullRebuild(spec: spec, config: config, device: targetDeviceInfo, destination: destination)
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
    
    private func fastReload(spec: ProjectSpec, device: Device) async throws {
        // Terminate app
        switch device.type {
        case .simulator:
            try Shell.run("/usr/bin/xcrun", args: ["simctl", "terminate", device.udid, spec.bundleId])
        case .physical:
            // For physical devices, we'll just reinstall and launch
            break
        }
        
        // Find .app path - use correct platform
        let platform = device.type == .simulator ? "iphonesimulator" : "iphoneos"
        let appPath = ".brx/DerivedData/Build/Products/Debug-\(platform)/\(spec.name).app"
        
        // Reinstall
        try DeviceManager.install(appPath: appPath, to: device)
        
        // Relaunch
        if device.type == .simulator {
            _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: device.udid)
        } else {
            try DeviceManager.launch(bundleId: spec.bundleId, on: device)
        }
    }
    
    private func fullRebuild(spec: ProjectSpec, config: BRXConfig, device: Device, destination: String) async throws {
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
        switch device.type {
        case .simulator:
            try Shell.run("/usr/bin/xcrun", args: ["simctl", "terminate", device.udid, spec.bundleId])
        case .physical:
            // For physical devices, we'll just reinstall and launch
            break
        }
        
        // Install
        try DeviceManager.install(appPath: appPath, to: device)
        
        // Launch
        if device.type == .simulator {
            _ = try Simulator.launch(bundleId: spec.bundleId, onUDID: device.udid)
        } else {
            try DeviceManager.launch(bundleId: spec.bundleId, on: device)
        }
    }
    
    private func selectDevice() throws -> String {
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Select a device:\(Ansi.reset)")
        Terminal.writeLine("")
        
        var devices: [(name: String, type: String)] = []
        
        // List physical devices first
        do {
            let physicalDevices = try DeviceCtl.listPhysicalDevices()
            if !physicalDevices.isEmpty {
                Terminal.writeLine("  \(Theme.current.success)📱 Connected Devices:\(Ansi.reset)")
                for (index, device) in physicalDevices.enumerated() {
                    Terminal.writeLine("    \(Theme.current.primary)[\(index + 1)]\(Ansi.reset) \(device.name)")
                    devices.append((device.name, "physical"))
                }
                Terminal.writeLine("")
            }
        } catch {
            // No physical devices available
        }
        
        // List simulators
        do {
            let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "devices", "--json"])
            if result.success, let data = result.stdout.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let devicesDict = json["devices"] as? [String: [[String: Any]]] {
                
                Terminal.writeLine("  \(Theme.current.muted)📲 Simulators:\(Ansi.reset)")
                var simCount = 0
                for (runtimeKey, sims) in devicesDict where runtimeKey.contains("iOS") {
                    for sim in sims {
                        if let name = sim["name"] as? String, simCount < 5 {
                            let deviceIndex = devices.count + 1
                            Terminal.writeLine("    \(Theme.current.primary)[\(deviceIndex)]\(Ansi.reset) \(name)")
                            devices.append((name, "simulator"))
                            simCount += 1
                        }
                    }
                    if simCount >= 5 { break }
                }
                Terminal.writeLine("")
            }
        } catch {
            // Failed to list simulators
        }
        
        if devices.isEmpty {
            throw RunCommandError.noDevicesAvailable
        }
        
        Terminal.write("\(Theme.current.primary)Choose device number\(Ansi.reset) → ")
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces),
              let choice = Int(input),
              choice > 0, choice <= devices.count else {
            throw RunCommandError.invalidDeviceSelection
        }
        
        let selectedDevice = devices[choice - 1]
        Terminal.writeLine("")
        Logger.step("📱", "selected: \(selectedDevice.name)")
        Terminal.writeLine("")
        
        return selectedDevice.name
    }
}

enum RunCommandError: Error, CustomStringConvertible {
    case noDevicesAvailable
    case invalidDeviceSelection
    
    var description: String {
        switch self {
        case .noDevicesAvailable:
            return "\(Theme.current.error)No devices available\(Ansi.reset)\n\nTry running \(Theme.current.primary)brx devices\(Ansi.reset) to see available devices."
        case .invalidDeviceSelection:
            return "\(Theme.current.error)Invalid selection\(Ansi.reset)\n\nPlease enter a valid device number."
        }
    }
}

