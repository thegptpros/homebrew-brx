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
}

struct PhysicalDevice {
    let name: String
    let udid: String
}

enum DeviceCtlError: Error, CustomStringConvertible {
    case notAvailable
    case listFailed
    
    var description: String {
        switch self {
        case .notAvailable:
            return "devicectl not available (requires Xcode 15+)"
        case .listFailed:
            return "Failed to list physical devices"
        }
    }
}

