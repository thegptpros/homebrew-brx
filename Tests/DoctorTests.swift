import XCTest
@testable import BRX

final class DoctorTests: XCTestCase {
    func testDoctorChecksXcodebuild() {
        XCTAssertTrue(XcodeTools.checkXcodeBuild(), "xcodebuild should be available")
    }
    
    func testDoctorFindsRuntimes() throws {
        let runtimeID = try Simulator.latestRuntimeID(for: .iOS)
        XCTAssertFalse(runtimeID.isEmpty, "Should find iOS runtime")
    }
    
    func testDoctorExitCodes() {
        // This would test that doctor returns proper exit codes
        // 0 = OK, 10 = CLTOnly, 11 = NoRuntime, 12 = NoSim, 13 = DevicectlMissing
        // Actual implementation would use mocks
    }
}

