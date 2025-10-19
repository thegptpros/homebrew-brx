import Foundation

enum DeviceCtl {
    static func isAvailable() -> Bool {
        // Check if devicectl is in PATH or in Xcode's usr/bin
        return Shell.which("devicectl") != nil || 
               FileManager.default.fileExists(atPath: "/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl")
    }
    
    private static func devicectlPath() -> String {
        if let path = Shell.which("devicectl") {
            return path
        } else if FileManager.default.fileExists(atPath: "/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl") {
            return "/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl"
        } else {
            return "devicectl" // fallback
        }
    }
    
    static func listPhysicalDevices() throws -> [PhysicalDevice] {
        guard isAvailable() else {
            throw DeviceCtlError.notAvailable
        }
        
        let result = try Shell.run(devicectlPath(), args: ["list", "devices"])
        
        guard result.success else {
            throw DeviceCtlError.listFailed
        }
        
        var devices: [PhysicalDevice] = []
        let lines = result.stdout.components(separatedBy: .newlines)
        
        // Skip header line and separator line
        for i in 2..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            // Parse device info from devicectl output
            // Format: "Name           Hostname                         Identifier                             State                Model"
            // We need to extract the name and identifier, handling spaces in names
            
            // Find the identifier (UUID format) - it's always in the 3rd column
            let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if components.count >= 3 {
                // The identifier is always the 3rd component (index 2)
                let udid = components[2]
                
                // Extract the device name - it's the first part before the hostname
                // The hostname starts with a pattern like "Zacs-iPhone-1.coredevice.local"
                // We want just "Zac's iPhone" (the part before the hostname)
                
                // Find the start of the hostname (it's the part that looks like "Zacs-iPhone-1.coredevice.local")
                let hostnamePattern = #"[A-Za-z0-9-]+\.coredevice\.local"#
                if let hostnameRange = line.range(of: hostnamePattern, options: .regularExpression) {
                    let namePart = String(line[..<hostnameRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if !namePart.isEmpty {
                        devices.append(PhysicalDevice(name: namePart, udid: udid))
                    }
                }
            }
        }
        
        return devices
    }
    
    static func findPhysicalDevice(named name: String) throws -> PhysicalDevice? {
        let devices = try listPhysicalDevices()
        return devices.first { $0.name.lowercased().contains(name.lowercased()) }
    }
    
    static func install(appPath: String, toDevice udid: String) throws {
        let result = try Shell.run(devicectlPath(), args: [
            "device", "install", "app", "--device", udid, appPath
        ])
        
        guard result.success else {
            throw DeviceCtlError.installFailed(appPath)
        }
    }
    
    static func launch(bundleId: String, onDevice udid: String) throws {
        let result = try Shell.run(devicectlPath(), args: [
            "device", "process", "launch", "--device", udid, bundleId
        ])
        
        guard result.success else {
            throw DeviceCtlError.launchFailed(bundleId)
        }
    }
    
    static func checkDeviceTrust(udid: String) throws -> Bool {
        // Try to get device details, which should trigger trust prompt if not trusted
        let result = try Shell.run(devicectlPath(), args: [
            "device", "info", "details", "--device", udid
        ])
        
        // If the command succeeds, device is trusted
        // If it fails with trust-related error, device is not trusted
        return result.success
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

