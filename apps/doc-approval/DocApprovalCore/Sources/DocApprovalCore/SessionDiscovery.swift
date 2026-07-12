import Foundation

/// Reads `.traverse/server.json` when available (macOS / desktop). Returns nil on iOS.
public enum SessionDiscovery {
    public struct ServerInfo: Equatable, Sendable {
        public let baseURL: URL
        public let workspaceDefault: String

        public init(baseURL: URL, workspaceDefault: String) {
            self.baseURL = baseURL
            self.workspaceDefault = workspaceDefault
        }
    }

    public static func discover(startingAt directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> ServerInfo? {
        #if os(macOS)
        var current = directory
        for _ in 0..<8 {
            let candidate = current.appendingPathComponent(".traverse/server.json")
            if let info = read(at: candidate) {
                return info
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return nil
        #else
        return nil
        #endif
    }

    public static func read(at fileURL: URL) -> ServerInfo? {
        #if os(macOS)
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = json["base_url"] as? String,
              let url = URL(string: base) else {
            return nil
        }
        let workspace = (json["workspace_default"] as? String) ?? "local-default"
        return ServerInfo(baseURL: url, workspaceDefault: workspace)
        #else
        return nil
        #endif
    }
}
