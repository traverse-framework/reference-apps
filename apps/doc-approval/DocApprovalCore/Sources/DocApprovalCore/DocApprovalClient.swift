import Foundation

public protocol DocApprovalClientProtocol: Sendable {
    func checkHealth(baseURL: URL) async throws -> Bool
    func sendCommand(
        workspaceId: String,
        appId: String,
        command: DocApprovalCommand,
        baseURL: URL
    ) async throws -> CommandAccepted
    /// Session-scoped command dispatch (`sessionId` is required).
    func sendCommand(
        sessionId: String,
        command: String,
        payload: [String: String],
        workspaceId: String,
        appId: String,
        baseURL: URL
    ) async throws -> CommandAccepted
    func listSessions(
        workspaceId: String,
        appId: String,
        state: String?,
        baseURL: URL
    ) async throws -> [ApprovalSession]
    func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent]
    func appEventsURL(workspaceId: String, appId: String, baseURL: URL) -> URL
    func subscribeAppEvents(
        workspaceId: String,
        appId: String,
        baseURL: URL,
        onEvent: @escaping @Sendable (String, AppStateEventPayload) -> Void
    ) async throws
}

public final class DocApprovalClient: DocApprovalClientProtocol, @unchecked Sendable {
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
        command: DocApprovalCommand,
        baseURL: URL
    ) async throws -> CommandAccepted {
        try await postCommand(
            sessionId: command.sessionId,
            command: command.name,
            payload: command.payload,
            workspaceId: workspaceId,
            appId: appId,
            baseURL: baseURL
        )
    }

    public func sendCommand(
        sessionId: String,
        command: String,
        payload: [String: String],
        workspaceId: String,
        appId: String,
        baseURL: URL
    ) async throws -> CommandAccepted {
        try await postCommand(
            sessionId: sessionId,
            command: command,
            payload: payload,
            workspaceId: workspaceId,
            appId: appId,
            baseURL: baseURL
        )
    }

    private func postCommand(
        sessionId: String?,
        command: String,
        payload: [String: String],
        workspaceId: String,
        appId: String,
        baseURL: URL
    ) async throws -> CommandAccepted {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/apps/\(appId)/commands")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "command": command,
            "payload": payload,
        ]
        if let sessionId {
            body["session_id"] = sessionId
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DocApprovalClientError.decode }
        guard (200..<300).contains(http.statusCode) else {
            throw DocApprovalClientError.http(status: http.statusCode)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiVersion = json["api_version"] as? String,
              let status = json["status"] as? String,
              let workspace = json["workspace_id"] as? String,
              let app = json["app_id"] as? String,
              let acceptedSession = json["session_id"] as? String,
              let commandName = json["command"] as? String,
              let state = json["state"] as? String else {
            throw DocApprovalClientError.decode
        }
        return CommandAccepted(
            apiVersion: apiVersion,
            status: status,
            workspaceId: workspace,
            appId: app,
            sessionId: acceptedSession,
            command: commandName,
            state: state,
            executionId: json["execution_id"] as? String
        )
    }

    public func listSessions(
        workspaceId: String,
        appId: String,
        state: String?,
        baseURL: URL
    ) async throws -> [ApprovalSession] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/workspaces/\(workspaceId)/apps/\(appId)/sessions"),
            resolvingAgainstBaseURL: false
        )
        if let state, !state.isEmpty {
            components?.queryItems = [URLQueryItem(name: "state", value: state)]
        }
        guard let url = components?.url else { throw DocApprovalClientError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DocApprovalClientError.decode }
        guard http.statusCode == 200 else { throw DocApprovalClientError.http(status: http.statusCode) }
        let json = try JSONSerialization.jsonObject(with: data)
        return DocApprovalOutputParser.parseSessions(json)
    }

    public func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent] {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/traces/\(executionId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DocApprovalClientError.decode }
        guard http.statusCode == 200 else { throw DocApprovalClientError.http(status: http.statusCode) }
        return try JSONDecoder().decode([TraceEvent].self, from: data)
    }

    public func appEventsURL(workspaceId: String, appId: String, baseURL: URL) -> URL {
        baseURL.appendingPathComponent("v1/workspaces/\(workspaceId)/apps/\(appId)/events")
    }

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
            throw DocApprovalClientError.http(status: http.statusCode)
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
                       let payload = DocApprovalOutputParser.parseEventPayload(json) {
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
