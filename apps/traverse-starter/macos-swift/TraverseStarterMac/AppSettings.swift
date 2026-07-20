import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let appId = "traverse-starter"
    static let noteMaxLength = 2000
    static let defaultWorkspace = "local-default"

    private enum Keys {
        static let workspace = "workspace"
    }

    @Published var workspace: String {
        didSet { UserDefaults.standard.set(workspace, forKey: Keys.workspace) }
    }

    init(userDefaults: UserDefaults = .standard) {
        workspace = userDefaults.string(forKey: Keys.workspace) ?? Self.defaultWorkspace
    }
}
