import Foundation

public struct TraverseStarterOutput: Equatable, Sendable, Codable {
    public let title: String
    public let tags: [String]
    public let noteType: String
    public let suggestedNextAction: String
    public let status: String

    public init(
        title: String,
        tags: [String],
        noteType: String,
        suggestedNextAction: String,
        status: String
    ) {
        self.title = title
        self.tags = tags
        self.noteType = noteType
        self.suggestedNextAction = suggestedNextAction
        self.status = status
    }
}

public struct TraceEvent: Equatable, Sendable, Codable {
    public let event_type: String
    public let timestamp: String
    public let data: JSONValue?

    public init(event_type: String, timestamp: String, data: JSONValue? = nil) {
        self.event_type = event_type
        self.timestamp = timestamp
        self.data = data
    }
}

public struct CommandAccepted: Equatable, Sendable {
    public let apiVersion: String
    public let status: String
    public let workspaceId: String
    public let appId: String
    public let sessionId: String
    public let command: String
    public let state: String
    public let executionId: String?

    public init(
        apiVersion: String,
        status: String,
        workspaceId: String,
        appId: String,
        sessionId: String,
        command: String,
        state: String,
        executionId: String?
    ) {
        self.apiVersion = apiVersion
        self.status = status
        self.workspaceId = workspaceId
        self.appId = appId
        self.sessionId = sessionId
        self.command = command
        self.state = state
        self.executionId = executionId
    }
}

public struct AppStateEventPayload: Equatable, Sendable {
    public let state: String?
    public let sessionId: String?
    public let executionId: String?
    public let output: TraverseStarterOutput?
    public let errorMessage: String?

    public init(
        state: String? = nil,
        sessionId: String? = nil,
        executionId: String? = nil,
        output: TraverseStarterOutput? = nil,
        errorMessage: String? = nil
    ) {
        self.state = state
        self.sessionId = sessionId
        self.executionId = executionId
        self.output = output
        self.errorMessage = errorMessage
    }
}

public enum TraverseClientError: Error, Equatable, Sendable {
    case http(status: Int)
    case decode
    case invalidURL
}

public enum JSONValue: Equatable, Sendable, Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

public enum TraverseOutputParser {
    public static func parse(_ raw: Any?) -> TraverseStarterOutput? {
        guard let dict = raw as? [String: Any],
              let title = dict["title"] as? String,
              let tags = dict["tags"] as? [String],
              let noteType = dict["noteType"] as? String,
              let suggestedNextAction = dict["suggestedNextAction"] as? String,
              let status = dict["status"] as? String else {
            return nil
        }
        return TraverseStarterOutput(
            title: title,
            tags: tags,
            noteType: noteType,
            suggestedNextAction: suggestedNextAction,
            status: status
        )
    }

    public static func parseEventPayload(_ raw: Any?) -> AppStateEventPayload? {
        guard let dict = raw as? [String: Any] else { return nil }
        let state = dict["state"] as? String
        let sessionId = dict["session_id"] as? String
        let executionId = dict["execution_id"] as? String
        let output = parse(dict["output"])
        var errorMessage: String?
        if let error = dict["error"] as? String {
            errorMessage = error
        } else if let errorObj = dict["error"] as? [String: Any],
                  let message = errorObj["message"] as? String {
            errorMessage = message
        }
        return AppStateEventPayload(
            state: state,
            sessionId: sessionId,
            executionId: executionId,
            output: output,
            errorMessage: errorMessage
        )
    }
}
