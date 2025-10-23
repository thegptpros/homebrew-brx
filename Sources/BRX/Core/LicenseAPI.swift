import Foundation

struct LicenseAPI {
    // Your Supabase configuration
    static let supabaseURL = "https://mraxgilahgpxrichbcdl.supabase.co"
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYXhnaWxhaGdweHJpY2hiY2RsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NzIzNzUsImV4cCI6MjA3NjE0ODM3NX0.rucolTj0cvlUO7xbKXPCne77TCdngHVAVJDzWS3gDfs"
    
    struct ActivationRequest: Codable {
        let licenseKey: String
        let machineId: String
        let hostname: String
        let osVersion: String
    }
    
    struct ActivationResponse: Codable {
        let success: Bool
        let message: String?
        let tier: String?
        let expiresAt: String?
        let seatsUsed: Int?
        let seatsTotal: Int?
        
        enum CodingKeys: String, CodingKey {
            case success
            case message
            case tier
            case expiresAt = "expires_at"
            case seatsUsed = "seats_used"
            case seatsTotal = "seats_total"
        }
    }
    
    /// Activate license online with Supabase
    static func activateOnline(key: String) async throws -> ActivationResponse {
        let machineId = getMachineID()
        let machineName = getMachineName()
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        let request = ActivationRequest(
            licenseKey: key,
            machineId: machineId,
            hostname: machineName,
            osVersion: osVersion
        )
        
        // Call Supabase Edge Function
        let url = URL(string: "https://www.brx.dev/api/activate-license")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LicenseError.activationFailed("Server error")
        }
        
        let activationResponse = try JSONDecoder().decode(ActivationResponse.self, from: data)
        return activationResponse
    }
    
    /// Check in periodically (optional)
    static func checkIn() async throws {
        let machineId = getMachineID()
        
        let url = URL(string: "\(supabaseURL)/functions/v1/license-checkin")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = ["machine_id": machineId]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await URLSession.shared.data(for: urlRequest)
        // Silent check-in, don't care about response
    }
    
    /// Get unique machine ID
    static func getMachineID() -> String {
        // Use IOPlatformUUID (hardware UUID) or create a unique ID
        if let uuid = getMacSerialNumber() {
            return uuid
        }
        
        // Fallback: generate and cache a UUID
        let defaults = UserDefaults.standard
        if let cached = defaults.string(forKey: "brx_machine_id") {
            return cached
        }
        
        let newID = UUID().uuidString
        defaults.set(newID, forKey: "brx_machine_id")
        return newID
    }
    
    /// Get machine name
    static func getMachineName() -> String {
        return ProcessInfo.processInfo.hostName
    }
    
    /// Get Mac serial number (most reliable)
    private static func getMacSerialNumber() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        process.arguments = ["-rd1", "-c", "IOPlatformExpertDevice"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Extract IOPlatformUUID
        let pattern = "\"IOPlatformUUID\" = \"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else {
            return nil
        }
        
        return String(output[range])
    }
}

extension LicenseError {
    static func activationFailed(_ message: String) -> LicenseError {
        return .custom(message)
    }
}

