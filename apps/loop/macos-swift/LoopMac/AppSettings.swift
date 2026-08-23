import Foundation
import LoopCore

@MainActor
final class AppSettings: ObservableObject {
    static let appId = "loop"
    static let transcriptMaxLength = 5_000
    static let defaultWorkspace = "local-default"

    private enum Keys {
        static let workspace = "loopWorkspace"
        static let bundlePath = "loopBundlePath"
    }

    @Published var workspace: String {
        didSet { UserDefaults.standard.set(workspace, forKey: Keys.workspace) }
    }

    @Published var bundlePath: String {
        didSet { UserDefaults.standard.set(bundlePath, forKey: Keys.bundlePath) }
    }

    init(userDefaults: UserDefaults = .standard) {
        workspace = userDefaults.string(forKey: Keys.workspace) ?? Self.defaultWorkspace
        bundlePath = userDefaults.string(forKey: Keys.bundlePath) ?? ""
    }

    var bundleURL: URL? {
        let trimmed = bundlePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(fileURLWithPath: trimmed)
    }
}
