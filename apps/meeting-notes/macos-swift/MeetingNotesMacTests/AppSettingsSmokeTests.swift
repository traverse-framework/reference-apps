import XCTest
@testable import MeetingNotesMac

final class AppSettingsSmokeTests: XCTestCase {
    @MainActor
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "meeting-notes-mac-smoke-\(UUID().uuidString)")!
        let settings = AppSettings(userDefaults: defaults)
        XCTAssertEqual(settings.workspace, AppSettings.defaultWorkspace)
        XCTAssertEqual(AppSettings.appId, "meeting-notes")
        XCTAssertTrue(settings.bundlePath.isEmpty)
    }
}
