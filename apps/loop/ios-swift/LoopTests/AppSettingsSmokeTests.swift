import XCTest
@testable import Loop

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "loop-smoke-\(UUID().uuidString)")!
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertEqual(AppSettings.appId, "loop")
        XCTAssertTrue(settings.bundlePath.isEmpty)
    }
}
