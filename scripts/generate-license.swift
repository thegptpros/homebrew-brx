#!/usr/bin/env swift

import Foundation
import CryptoKit

func generateChecksum(from data: String) -> String {
    let hash = SHA256.hash(data: Data(data.utf8))
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
    return String(hashString.prefix(4)).uppercased()
}

func generateLicenseKey() -> String {
    // Generate 3 random segments
    let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    var segments: [String] = []
    for _ in 0..<3 {
        var segment = ""
        for _ in 0..<4 {
            segment.append(chars.randomElement()!)
        }
        segments.append(segment)
    }
    
    // Calculate checksum for the 3 segments
    let dataToCheck = segments.joined(separator: "-")
    let checksum = generateChecksum(from: dataToCheck)
    
    // Build final key
    return "BRX-\(segments[0])-\(segments[1])-\(segments[2])-\(checksum)"
}

// Generate and print a license key
let licenseKey = generateLicenseKey()
print("Generated License Key:")
print(licenseKey)
print("")
print("To activate:")
print("  brx activate --license-key \(licenseKey)")

