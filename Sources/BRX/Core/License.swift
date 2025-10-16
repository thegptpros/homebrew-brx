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
}

enum LicenseError: Error, CustomStringConvertible {
    case notActivated
    case invalidKey
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
        case .invalidKey:
            return "Invalid license key format"
        case .custom(let message):
            return message
        }
    }
}

