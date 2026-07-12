import XCTest
@testable import TraverseStarter

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaultWorkspaceAndAppId() {
        let defaults = UserDefaults(suiteName: "traverse.starter.ios.smoke")!
        defaults.removePersistentDomain(forName: "traverse.starter.ios.smoke")
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertEqual(AppSettings.appId, "traverse-starter")
    }
}
