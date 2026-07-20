import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let appId = "doc-approval"
    static let documentMaxLength = 10_000
    static let defaultWorkspace = "local-default"

    private enum Keys {
        static let workspace = "docApprovalWorkspace"
    }

    @Published var workspace: String {
        didSet { UserDefaults.standard.set(workspace, forKey: Keys.workspace) }
    }

    init(userDefaults: UserDefaults = .standard) {
        workspace = userDefaults.string(forKey: Keys.workspace) ?? Self.defaultWorkspace
    }
}
