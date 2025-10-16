import XCTest
@testable import BRX

final class SettingsTests: XCTestCase {
    func testConfigRoundtrip() throws {
        var config = BRXConfig.defaultConfig
        config.theme = "aurora"
        config.defaults.iosDevice = "iPhone 17 Pro"
        
        // Save
        let tempPath = "/tmp/brx-test-config.json"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: tempPath))
        
        // Load
        let loadedData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        let loadedConfig = try JSONDecoder().decode(BRXConfig.self, from: loadedData)
        
        XCTAssertEqual(loadedConfig.theme, "aurora")
        XCTAssertEqual(loadedConfig.defaults.iosDevice, "iPhone 17 Pro")
        
        // Cleanup
        try? FS.removeItem(tempPath)
    }
}

