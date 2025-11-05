import Foundation
import CryptoKit

func generateChecksum(from data: String) -> String {
    let hash = SHA256.hash(data: Data(data.utf8))
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
    return hashString.prefix(4).uppercased()
}

// Generate a test license key
let part1 = "TEST"
let part2 = "1234"
let part3 = "5678"
let dataToCheck = "\(part1)-\(part2)-\(part3)"
let checksum = generateChecksum(from: dataToCheck)

let licenseKey = "BRX-\(part1)-\(part2)-\(part3)-\(checksum)"
print("Generated license key: \(licenseKey)")
print("Data to check: \(dataToCheck)")
print("Checksum: \(checksum)")


