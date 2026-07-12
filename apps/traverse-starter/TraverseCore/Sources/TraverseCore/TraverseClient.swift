import Foundation

public protocol TraverseClientProtocol: Sendable {
    func checkHealth(baseURL: URL) async throws -> Bool
    func sendCommand(
        workspaceId: String,
        appId: String,
        command: TraverseCommand,
        baseURL: URL
    ) async throws -> CommandAccepted
    func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent]
    func appEventsURL(workspaceId: String, appId: String, baseURL: URL) -> URL
    func subscribeAppEvents(
        workspaceId: String,
        appId: String,
        baseURL: URL,
        onEvent: @escaping @Sendable (String, AppStateEventPayload) -> Void
    ) async throws
}

public final class TraverseClient: TraverseClientProtocol, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func checkHealth(baseURL: URL) async throws -> Bool {
        let url = baseURL.appendingPathComponent("healthz")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    public func sendCommand(
        workspaceId: String,
        appId: String,
        command: TraverseCommand,
        baseURL: URL
    ) async throws -> CommandAccepted {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/apps/\(appId)/commands")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "command": command.name,
            "payload": command.payload,
        ]
        if let sessionId = command.sessionId {
            body["session_id"] = sessionId
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TraverseClientError.decode }
        guard (200..<300).contains(http.statusCode) else {
            throw TraverseClientError.http(status: http.statusCode)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiVersion = json["api_version"] as? String,
              let status = json["status"] as? String,
              let workspace = json["workspace_id"] as? String,
              let app = json["app_id"] as? String,
              let sessionId = json["session_id"] as? String,
              let commandName = json["command"] as? String,
              let state = json["state"] as? String else {
            throw TraverseClientError.decode
        }
        return CommandAccepted(
            apiVersion: apiVersion,
            status: status,
            workspaceId: workspace,
            appId: app,
            sessionId: sessionId,
            command: commandName,
            state: state,
            executionId: json["execution_id"] as? String
        )
    }

    public func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent] {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/traces/\(executionId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TraverseClientError.decode }
        guard http.statusCode == 200 else { throw TraverseClientError.http(status: http.statusCode) }
        return try JSONDecoder().decode([TraceEvent].self, from: data)
    }

    public func appEventsURL(workspaceId: String, appId: String, baseURL: URL) -> URL {
        baseURL.appendingPathComponent("v1/workspaces/\(workspaceId)/apps/\(appId)/events")
    }

    /// Streams app SSE events until cancelled. Calls `onEvent` for each named event.
    public func subscribeAppEvents(
        workspaceId: String,
        appId: String,
        baseURL: URL,
        onEvent: @escaping @Sendable (String, AppStateEventPayload) -> Void
    ) async throws {
        let url = appEventsURL(workspaceId: workspaceId, appId: appId, baseURL: baseURL)
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await session.bytes(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw TraverseClientError.http(status: http.statusCode)
        }

        var eventType = "message"
        var dataLines: [String] = []

        for try await line in bytes.lines {
            if Task.isCancelled { break }
            if line.isEmpty {
                if !dataLines.isEmpty {
                    let raw = dataLines.joined(separator: "\n")
                    dataLines = []
                    let type = eventType
                    eventType = "message"
                    if type == "heartbeat" {
                        onEvent(type, AppStateEventPayload())
                        continue
                    }
                    if let data = raw.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data),
                       let payload = TraverseOutputParser.parseEventPayload(json) {
                        onEvent(type, payload)
                    }
                }
                continue
            }
            if line.hasPrefix(":") { continue }
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces))
            }
        }
    }
}
