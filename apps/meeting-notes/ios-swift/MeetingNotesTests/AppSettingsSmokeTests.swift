import XCTest
@testable import MeetingNotes

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "meeting-notes-smoke-\(UUID().uuidString)")!
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertEqual(AppSettings.appId, "meeting-notes")
        XCTAssertTrue(settings.bundlePath.isEmpty)
    }
}
