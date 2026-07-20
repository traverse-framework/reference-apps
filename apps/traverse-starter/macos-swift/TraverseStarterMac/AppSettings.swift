import Foundation
import TraverseCore

@MainActor
final class AppSettings: ObservableObject {
    static let appId = "traverse-starter"
    static let noteMaxLength = 2000
    static let defaultWorkspace = "local-default"

    private enum Keys {
        static let workspace = "workspace"
        static let bundlePath = "bundlePath"
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
