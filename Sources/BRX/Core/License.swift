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
        
        do {
            try config.save()
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
        
        // Check free build limit
        let config = BRXConfig.load()
        let remaining = max(0, 10 - config.buildCount)
        
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
        let remaining = max(0, 10 - config.buildCount)
        
        if remaining > 0 {
            print("\n\(Theme.current.muted)Free builds remaining: \(remaining)/10\(Ansi.reset)")
            print("\(Theme.current.muted)Get unlimited builds at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)\n")
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
            
            \(Theme.current.error)Free build limit reached (10/10)\(Ansi.reset)
            
            You've used all your free builds! To continue building:
            
              1. Get a license at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)
              2. Activate it: \(Theme.current.primary)brx activate --license-key <your-key>\(Ansi.reset)
            
            \(Theme.current.muted)Licenses start at $39/year or $79 lifetime\(Ansi.reset)
            
            """
        case .invalidKey:
            return "Invalid license key format"
        case .custom(let message):
            return message
        }
    }
}

