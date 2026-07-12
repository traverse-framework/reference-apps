import XCTest
@testable import DocApprovalMac

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "doc-approval-mac-smoke-\(UUID().uuidString)")!
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertFalse(settings.baseURLString.isEmpty)
    }
}
