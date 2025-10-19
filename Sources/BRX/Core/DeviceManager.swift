import Foundation

enum DeviceType {
    case simulator
    case physical
}

struct Device {
    let name: String
    let udid: String
    let type: DeviceType
}

enum DeviceManager {
    static func findDevice(named name: String) throws -> Device {
        // First try to find as a physical device
        if DeviceCtl.isAvailable() {
            if let physicalDevice = try? DeviceCtl.findPhysicalDevice(named: name) {
                return Device(
                    name: physicalDevice.name,
                    udid: physicalDevice.udid,
                    type: .physical
                )
            }
        }
        
        // Fall back to simulator
        let simulatorUDID = try Simulator.findDevice(named: name, platform: .iOS)
        guard let udid = simulatorUDID else {
            throw DeviceError.deviceNotFound(name)
        }
        
        return Device(
            name: name,
            udid: udid,
            type: .simulator
        )
    }
    
    static func ensureDevice(named name: String) throws -> Device {
        // First try to find existing device
        if let existing = try? findDevice(named: name) {
            return existing
        }
        
        // If not found and it's a physical device, throw error
        if DeviceCtl.isAvailable() {
            if let _ = try? DeviceCtl.findPhysicalDevice(named: name) {
                throw DeviceError.deviceNotFound(name)
            }
        }
        
        // Create simulator if not found
        let udid = try Simulator.ensureDevice(named: name, platform: .iOS)
        return Device(
            name: name,
            udid: udid,
            type: .simulator
        )
    }
    
    static func install(appPath: String, to device: Device) throws {
        switch device.type {
        case .simulator:
            try Simulator.install(appPath: appPath, toUDID: device.udid)
        case .physical:
            try DeviceCtl.install(appPath: appPath, toDevice: device.udid)
        }
    }
    
    static func launch(bundleId: String, on device: Device) throws {
        switch device.type {
        case .simulator:
            _ = try Simulator.launch(bundleId: bundleId, onUDID: device.udid)
        case .physical:
            try DeviceCtl.launch(bundleId: bundleId, onDevice: device.udid)
        }
    }
    
    static func bootIfNeeded(_ device: Device) throws {
        switch device.type {
        case .simulator:
            try Simulator.bootIfNeeded(udid: device.udid)
        case .physical:
            // Physical devices don't need booting
            break
        }
    }
    
    static func checkDeviceTrust(_ device: Device) throws -> Bool {
        switch device.type {
        case .simulator:
            return true // Simulators are always "trusted"
        case .physical:
            return try DeviceCtl.checkDeviceTrust(udid: device.udid)
        }
    }
}

enum DeviceError: Error, CustomStringConvertible {
    case deviceNotFound(String)
    case deviceNotTrusted(String)
    
    var description: String {
        switch self {
        case .deviceNotFound(let name):
            return "Device '\(name)' not found. Use 'brx devices list' to see available devices."
        case .deviceNotTrusted(let udid):
            return "Device not trusted. Please unlock your device and tap 'Trust' when prompted: \(udid)"
        }
    }
}
