import XCTest
@testable import TraverseStarterMac

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaultWorkspaceAndAppId() {
        let defaults = UserDefaults(suiteName: "traverse.starter.mac.smoke")!
        defaults.removePersistentDomain(forName: "traverse.starter.mac.smoke")
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertEqual(AppSettings.appId, "traverse-starter")
        XCTAssertTrue(settings.bundlePath.isEmpty)
    }
}
