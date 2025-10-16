import Foundation

struct SimRuntime: Codable {
    let identifier: String
    let version: String
    let isAvailable: Bool
    let name: String
}

struct SimDevice: Codable {
    let udid: String
    let name: String
    let state: String
    let deviceTypeIdentifier: String?
}

struct SimDeviceType: Codable {
    let identifier: String
    let name: String
}

enum Platform {
    case iOS
    case watchOS
    
    var identifier: String {
        switch self {
        case .iOS: return "com.apple.CoreSimulator.SimRuntime.iOS"
        case .watchOS: return "com.apple.CoreSimulator.SimRuntime.watchOS"
        }
    }
}

enum Simulator {
    // MARK: - Runtime Management
    
    static func latestRuntimeID(for platform: Platform) throws -> String {
        let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "runtimes", "--json"])
        
        guard result.success else {
            throw SimulatorError.runtimeListFailed
        }
        
        let data = result.stdout.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let runtimesArray = json["runtimes"] as! [[String: Any]]
        
        let availableRuntimes = runtimesArray
            .filter { ($0["isAvailable"] as? Bool) == true }
            .filter { ($0["identifier"] as? String)?.contains(platform.identifier) == true }
            .sorted { (r1, r2) -> Bool in
                let v1 = r1["version"] as? String ?? ""
                let v2 = r2["version"] as? String ?? ""
                return v1.compare(v2, options: .numeric) == .orderedDescending
            }
        
        guard let latest = availableRuntimes.first,
              let identifier = latest["identifier"] as? String else {
            throw SimulatorError.noRuntimeAvailable(platform)
        }
        
        return identifier
    }
    
    // MARK: - Device Type Resolution
    
    static func deviceTypeID(matching regex: String, for platform: Platform) throws -> String {
        let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "devicetypes", "--json"])
        
        guard result.success else {
            throw SimulatorError.deviceTypeListFailed
        }
        
        let data = result.stdout.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let typesArray = json["devicetypes"] as! [[String: Any]]
        
        let pattern = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
        
        for type in typesArray {
            guard let name = type["name"] as? String,
                  let identifier = type["identifier"] as? String else { continue }
            
            let range = NSRange(name.startIndex..., in: name)
            if pattern.firstMatch(in: name, options: [], range: range) != nil {
                return identifier
            }
        }
        
        throw SimulatorError.noDeviceTypeMatching(regex)
    }
    
    // MARK: - Device Management
    
    static func ensureDevice(named name: String, platform: Platform) throws -> String {
        // First, check if device already exists
        if let existing = try? findDevice(named: name, platform: platform) {
            return existing
        }
        
        // Get latest runtime and device type
        let runtimeID = try latestRuntimeID(for: platform)
        
        let regex: String
        switch platform {
        case .iOS:
            if name.contains("Pro Max") {
                regex = "iPhone.*Pro Max"
            } else {
                regex = name
            }
        case .watchOS:
            if name.contains("Ultra") {
                regex = "Apple Watch Ultra.*49mm"
            } else {
                regex = name
            }
        }
        
        let deviceTypeID = try deviceTypeID(matching: regex, for: platform)
        
        // Create the device
        let result = try Shell.run("/usr/bin/xcrun", args: [
            "simctl", "create", name, deviceTypeID, runtimeID
        ])
        
        guard result.success else {
            throw SimulatorError.createFailed(name)
        }
        
        let udid = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.debug("Created simulator: \(name) (\(udid))")
        return udid
    }
    
    static func findDevice(named name: String, platform: Platform) throws -> String? {
        let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "devices", "--json"])
        
        guard result.success else {
            throw SimulatorError.deviceListFailed
        }
        
        let data = result.stdout.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let devicesDict = json["devices"] as! [String: [[String: Any]]]
        
        for (runtimeKey, devices) in devicesDict {
            guard runtimeKey.contains(platform.identifier) else { continue }
            
            for device in devices {
                if let deviceName = device["name"] as? String,
                   deviceName == name,
                   let udid = device["udid"] as? String {
                    return udid
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Device Operations
    
    static func bootIfNeeded(udid: String) throws {
        let result = try Shell.run("/usr/bin/xcrun", args: [
            "simctl", "bootstatus", udid, "-b"
        ])
        
        if !result.success && !result.stderr.contains("Unable to lookup in current state: Booted") {
            throw SimulatorError.bootFailed(udid)
        }
    }
    
    static func install(appPath: String, toUDID udid: String) throws {
        let result = try Shell.run("/usr/bin/xcrun", args: [
            "simctl", "install", udid, appPath
        ])
        
        guard result.success else {
            throw SimulatorError.installFailed(appPath)
        }
    }
    
    static func launch(bundleId: String, onUDID udid: String) throws -> (pid: Int, os: String) {
        let result = try Shell.run("/usr/bin/xcrun", args: [
            "simctl", "launch", udid, bundleId, "--console"
        ])
        
        guard result.success else {
            throw SimulatorError.launchFailed(bundleId)
        }
        
        // Parse PID from output like "com.example.app: 12345"
        let components = result.stdout.components(separatedBy: ":")
        let pidString = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pid = Int(pidString) ?? 0
        
        // Get OS version
        let osResult = try? Shell.run("/usr/bin/xcrun", args: [
            "simctl", "getenv", udid, "SIMULATOR_RUNTIME_VERSION"
        ])
        let os = osResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
        
        return (pid, os)
    }
    
    static func terminate(bundleId: String, onUDID udid: String) throws {
        _ = try? Shell.run("/usr/bin/xcrun", args: [
            "simctl", "terminate", udid, bundleId
        ])
    }
}

enum SimulatorError: Error, CustomStringConvertible {
    case runtimeListFailed
    case noRuntimeAvailable(Platform)
    case deviceTypeListFailed
    case noDeviceTypeMatching(String)
    case deviceListFailed
    case createFailed(String)
    case bootFailed(String)
    case installFailed(String)
    case launchFailed(String)
    
    var description: String {
        switch self {
        case .runtimeListFailed:
            return "Failed to list runtimes"
        case .noRuntimeAvailable(let platform):
            return "No runtime available for \(platform)"
        case .deviceTypeListFailed:
            return "Failed to list device types"
        case .noDeviceTypeMatching(let regex):
            return "No device type matching '\(regex)'"
        case .deviceListFailed:
            return "Failed to list devices"
        case .createFailed(let name):
            return "Failed to create simulator '\(name)'"
        case .bootFailed(let udid):
            return "Failed to boot simulator \(udid)"
        case .installFailed(let path):
            return "Failed to install app at \(path)"
        case .launchFailed(let bundleId):
            return "Failed to launch \(bundleId)"
        }
    }
}

