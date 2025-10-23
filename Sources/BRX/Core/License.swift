import Foundation
import CryptoKit

enum License {
    static var isActivated: Bool {
        let config = BRXConfig.load()
        return !config.license.key.isEmpty && validate(key: config.license.key)
    }
    
    static func activate(key: String) -> Bool {
        guard validate(key: key) else {
            return false
        }
        
        // Save to config
        var config = BRXConfig.load()
        config.license.key = key
        config.license.activatedAt = ISO8601DateFormatter().string(from: Date())
        config.license.machineId = getMachineID()
        config.license.lastValidated = ISO8601DateFormatter().string(from: Date())
        
        do {
            try config.save()
        } catch {
            Logger.error("Failed to save license: \(error)")
            return false
        }
        
        return true
    }
    
    static func activateWithDetails(key: String, tier: String?, expiresAt: String?, seatsUsed: Int?, seatsTotal: Int?) -> Bool {
        guard validate(key: key) else {
            return false
        }
        
        // Save to config with full details
        var config = BRXConfig.load()
        config.license.key = key
        config.license.activatedAt = ISO8601DateFormatter().string(from: Date())
        config.license.machineId = getMachineID()
        config.license.lastValidated = ISO8601DateFormatter().string(from: Date())
        config.license.tier = tier
        config.license.expiresAt = expiresAt
        config.license.seatsUsed = seatsUsed
        config.license.seatsTotal = seatsTotal
        
        do {
            try config.save()
        } catch {
            Logger.error("Failed to save license: \(error)")
            return false
        }
        
        return true
    }
    
    static func activateOffline(key: String) -> Bool {
        guard validateOffline(key: key) else {
            return false
        }
        
        // Check if license is expired
        if isExpired() {
            return false
        }
        
        // Check machine binding
        let currentMachineId = getMachineID()
        let config = BRXConfig.load()
        
        if let boundMachineId = config.license.machineId, boundMachineId != currentMachineId {
            return false
        }
        
        // Save to config with limited info
        var newConfig = config
        newConfig.license.key = key
        newConfig.license.activatedAt = ISO8601DateFormatter().string(from: Date())
        newConfig.license.machineId = currentMachineId
        newConfig.license.lastValidated = ISO8601DateFormatter().string(from: Date())
        
        do {
            try newConfig.save()
        } catch {
            Logger.error("Failed to save license: \(error)")
            return false
        }
        
        return true
    }
    
    static func validate(key: String) -> Bool {
        // License key format: BRX-XXXX-XXXX-XXXX-XXXX
        let pattern = "^BRX-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: key, range: NSRange(key.startIndex..., in: key)) != nil else {
            return false
        }
        
        // Extract the parts
        let parts = key.split(separator: "-").map(String.init)
        guard parts.count == 5, parts[0] == "BRX" else {
            return false
        }
        
        // Validate checksum (last segment should be a valid checksum of first 3 segments)
        let dataToCheck = "\(parts[1])-\(parts[2])-\(parts[3])"
        let checksum = generateChecksum(from: dataToCheck)
        
        return checksum == parts[4]
    }
    
    static func validateOffline(key: String) -> Bool {
        // Basic format validation only for offline mode
        return validate(key: key)
    }
    
    static func isExpired() -> Bool {
        let config = BRXConfig.load()
        guard let expiresAt = config.license.expiresAt else {
            return false // Lifetime licenses don't expire
        }
        
        let formatter = ISO8601DateFormatter()
        guard let expirationDate = formatter.date(from: expiresAt) else {
            return false
        }
        
        return expirationDate < Date()
    }
    
    static func getMachineID() -> String {
        // Get unique machine identifier
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "-json"]
        
        do {
            let pipe = Pipe()
            process.standardOutput = pipe
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hardware = json["SPHardwareDataType"] as? [[String: Any]],
               let first = hardware.first,
               let serialNumber = first["serial_number"] as? String {
                return serialNumber
            }
        } catch {
            // Fallback to hostname
        }
        
        // Fallback to hostname
        let hostname = ProcessInfo.processInfo.hostName
        return hostname
    }
    
    static func shouldValidateOnline() -> Bool {
        let config = BRXConfig.load()
        guard let lastValidated = config.license.lastValidated else {
            return true // Never validated, should validate
        }
        
        let formatter = ISO8601DateFormatter()
        guard let lastValidationDate = formatter.date(from: lastValidated) else {
            return true // Invalid date, should validate
        }
        
        // Validate every 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return lastValidationDate < sevenDaysAgo
    }
    
    static func generateChecksum(from data: String) -> String {
        let hash = SHA256.hash(data: Data(data.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Take first 4 characters and convert to uppercase alphanumeric
        return hashString.prefix(4).uppercased()
    }
    
    static func requireLicense() throws {
        guard isActivated else {
            throw LicenseError.notActivated
        }
    }
    
    // Check if user can build (licensed or within free build limit)
    static func canBuild() -> (allowed: Bool, buildsRemaining: Int) {
        // If licensed, unlimited builds
        if isActivated {
            return (true, -1) // -1 indicates unlimited
        }
        
        // Check free build limit (3 free builds)
        let config = BRXConfig.load()
        let remaining = max(0, 3 - config.buildCount)
        
        return (remaining > 0, remaining)
    }
    
    // Increment build count for free users
    static func incrementBuildCount() {
        guard !isActivated else {
            return // Don't track builds for licensed users
        }
        
        var config = BRXConfig.load()
        config.buildCount += 1
        
        do {
            try config.save()
        } catch {
            Logger.warning("Failed to update build count: \(error)")
        }
    }
    
    // Show message after successful build
    static func showBuildLimitMessage() {
        guard !isActivated else {
            return // Don't show message to licensed users
        }
        
        let config = BRXConfig.load()
        let remaining = max(0, 3 - config.buildCount)
        
        if remaining > 0 {
            Terminal.writeLine("")
            Terminal.writeLine("\(Theme.current.muted)Free builds remaining: \(Theme.current.primary)\(remaining)\(Theme.current.muted)/3\(Ansi.reset)")
            Terminal.writeLine("\(Theme.current.muted)Get unlimited builds: \(Theme.current.primary)https://brx.dev\(Ansi.reset)")
            Terminal.writeLine("\(Theme.current.muted)Check status: \(Theme.current.primary)brx status\(Ansi.reset)")
            Terminal.writeLine("")
        }
    }
}

enum LicenseError: Error, CustomStringConvertible {
    case notActivated
    case invalidKey
    case buildLimitReached
    case custom(String)
    
    var description: String {
        switch self {
        case .notActivated:
            return """
            
            \(Theme.current.error)License required\(Ansi.reset)
            
            BRX requires a valid license to use. Please activate your license:
            
              \(Theme.current.primary)brx activate --license-key <your-key>\(Ansi.reset)
            
            Purchase a license at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)
            
            """
        case .buildLimitReached:
            return """
            
            \(Theme.current.error)Free build limit reached (3/3)\(Ansi.reset)
            
            You've used all your free builds! To continue building:
            
              1. Get a license at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)
              2. Activate it: \(Theme.current.primary)brx activate --license-key <your-key>\(Ansi.reset)
            
            \(Theme.current.muted)Licenses start at $39/year or $79 lifetime\(Ansi.reset)
            \(Theme.current.muted)Check your status: \(Theme.current.primary)brx status\(Ansi.reset)
            
            """
        case .invalidKey:
            return "Invalid license key format"
        case .custom(let message):
            return message
        }
    }
}

