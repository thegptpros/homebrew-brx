import Foundation

struct BRXConfig: Codable {
    struct Defaults: Codable {
        var iosDevice: String
        var watchDevice: String
        
        enum CodingKeys: String, CodingKey {
            case iosDevice = "ios_device"
            case watchDevice = "watch_device"
        }
    }
    
    struct Fastlane: Codable {
        var appleId: String
        var teamId: String
        var apiKeyPath: String
        var appPassword: String
        
        enum CodingKeys: String, CodingKey {
            case appleId = "apple_id"
            case teamId = "team_id"
            case apiKeyPath = "api_key_path"
            case appPassword = "app_password"
        }
    }
    
    struct LicenseInfo: Codable {
        var key: String
        var activatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case key
            case activatedAt = "activated_at"
        }
    }
    
    var defaults: Defaults
    var theme: String
    var logoMode: String
    var telemetry: Bool
    var fastlane: Fastlane
    var license: LicenseInfo
    
    enum CodingKeys: String, CodingKey {
        case defaults
        case theme
        case logoMode = "logo_mode"
        case telemetry
        case fastlane
        case license
    }
    
    static let defaultConfig = BRXConfig(
        defaults: Defaults(
            iosDevice: "iPhone 17 Pro Max",
            watchDevice: "Apple Watch Ultra 2 (49mm)"
        ),
        theme: "proMono",
        logoMode: "on",
        telemetry: false,
        fastlane: Fastlane(
            appleId: "",
            teamId: "",
            apiKeyPath: "",
            appPassword: ""
        ),
        license: LicenseInfo(
            key: "",
            activatedAt: ""
        )
    )
    
    static var configPath: String {
        return "\(FS.homeDirectory())/.config/brx/config.json"
    }
    
    static func load() -> BRXConfig {
        let path = configPath
        
        if !FS.exists(path) {
            return createDefault()
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let config = try JSONDecoder().decode(BRXConfig.self, from: data)
            return config
        } catch {
            Logger.warning("Failed to load config, using defaults")
            return defaultConfig
        }
    }
    
    @discardableResult
    static func createDefault() -> BRXConfig {
        let config = defaultConfig
        do {
            try config.save()
            Logger.debug("Created default config at \(configPath)")
        } catch {
            Logger.warning("Failed to create default config: \(error)")
        }
        return config
    }
    
    func save() throws {
        let path = BRXConfig.configPath
        let dir = (path as NSString).deletingLastPathComponent
        
        if !FS.exists(dir) {
            try FS.createDirectory(dir)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: path))
    }
}

