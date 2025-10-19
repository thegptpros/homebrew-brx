import Foundation

enum DeviceCtl {
    static func isAvailable() -> Bool {
        return Shell.which("devicectl") != nil
    }
    
    static func listPhysicalDevices() throws -> [PhysicalDevice] {
        guard isAvailable() else {
            throw DeviceCtlError.notAvailable
        }
        
        let result = try Shell.run("/usr/bin/devicectl", args: ["list", "devices"])
        
        guard result.success else {
            throw DeviceCtlError.listFailed
        }
        
        var devices: [PhysicalDevice] = []
        
        for line in result.stdout.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("--") { continue }
            
            // Parse device info (simple parsing for now)
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 2 {
                let name = parts[0]
                let udid = parts[1]
                devices.append(PhysicalDevice(name: name, udid: udid))
            }
        }
        
        return devices
    }
    
    static func findPhysicalDevice(named name: String) throws -> PhysicalDevice? {
        let devices = try listPhysicalDevices()
        return devices.first { $0.name.lowercased().contains(name.lowercased()) }
    }
    
    static func install(appPath: String, toDevice udid: String) throws {
        let result = try Shell.run("/usr/bin/devicectl", args: [
            "device", "install", "app", "--device", udid, appPath
        ])
        
        guard result.success else {
            throw DeviceCtlError.installFailed(appPath)
        }
    }
    
    static func launch(bundleId: String, onDevice udid: String) throws {
        let result = try Shell.run("/usr/bin/devicectl", args: [
            "device", "process", "launch", "--device", udid, bundleId
        ])
        
        guard result.success else {
            throw DeviceCtlError.launchFailed(bundleId)
        }
    }
    
    static func checkDeviceTrust(udid: String) throws -> Bool {
        let result = try Shell.run("/usr/bin/devicectl", args: [
            "list", "devices", "--device", udid
        ])
        
        // If the command succeeds and returns device info, device is trusted
        return result.success && !result.stdout.isEmpty
    }
}

struct PhysicalDevice {
    let name: String
    let udid: String
}

enum DeviceCtlError: Error, CustomStringConvertible {
    case notAvailable
    case listFailed
    case installFailed(String)
    case launchFailed(String)
    case deviceNotTrusted(String)
    
    var description: String {
        switch self {
        case .notAvailable:
            return "devicectl not available (requires Xcode 15+)"
        case .listFailed:
            return "Failed to list physical devices"
        case .installFailed(let appPath):
            return "Failed to install app to device: \(appPath)"
        case .launchFailed(let bundleId):
            return "Failed to launch app on device: \(bundleId)"
        case .deviceNotTrusted(let udid):
            return "Device not trusted. Please unlock your device and tap 'Trust' when prompted: \(udid)"
        }
    }
}

