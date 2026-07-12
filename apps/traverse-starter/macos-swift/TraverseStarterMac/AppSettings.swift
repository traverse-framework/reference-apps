import Foundation
import TraverseCore

@MainActor
final class AppSettings: ObservableObject {
    static let appId = "traverse-starter"
    static let noteMaxLength = 2000
    static let defaultBaseURL = "http://127.0.0.1:8787"
    static let defaultWorkspace = "local-default"

    private enum Keys {
        static let baseURL = "runtimeBaseURL"
        static let workspace = "workspace"
    }

    @Published var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Keys.baseURL) }
    }

    @Published var workspace: String {
        didSet { UserDefaults.standard.set(workspace, forKey: Keys.workspace) }
    }

    init(userDefaults: UserDefaults = .standard) {
        if userDefaults.string(forKey: Keys.baseURL) == nil,
           let discovered = ServerDiscovery.discover() {
            baseURLString = discovered.baseURL.absoluteString
            workspace = discovered.workspaceDefault
            return
        }
        baseURLString = userDefaults.string(forKey: Keys.baseURL) ?? Self.defaultBaseURL
        workspace = userDefaults.string(forKey: Keys.workspace) ?? Self.defaultWorkspace
    }

    var baseURL: URL? {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
