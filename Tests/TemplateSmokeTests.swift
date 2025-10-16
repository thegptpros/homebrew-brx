import XCTest
@testable import BRX

final class TemplateSmokeTests: XCTestCase {
    let templates = ["swiftui-todo", "ball-game", "watch-counter", "blank"]
    
    func testTemplatesExist() throws {
        for template in templates {
            let templatePath = "./Templates/\(template)"
            XCTAssertTrue(FS.exists(templatePath), "Template \(template) should exist")
            XCTAssertTrue(FS.exists("\(templatePath)/brx.yml"), "Template should have brx.yml")
        }
    }
    
    func testTemplateInitAndGenerate() throws {
        // This would test that:
        // 1. brx init creates project in tmp dir
        // 2. XcodeGen generates .xcodeproj
        // 3. xcodebuild -list finds shared scheme
        // Skipped for now as it requires full environment
    }
}

