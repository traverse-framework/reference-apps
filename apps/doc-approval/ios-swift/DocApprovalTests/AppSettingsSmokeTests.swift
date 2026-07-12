import XCTest
@testable import DocApproval

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "doc-approval-smoke-\(UUID().uuidString)")!
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertFalse(settings.baseURLString.isEmpty)
    }
}
