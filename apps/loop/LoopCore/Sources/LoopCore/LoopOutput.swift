import Foundation

public struct ActionItem: Equatable, Sendable, Codable {
    public let task: String
    public let owner: String?
    public let due: String?

    public init(task: String, owner: String? = nil, due: String? = nil) {
        self.task = task
        self.owner = owner
        self.due = due
    }
}

public struct Decision: Equatable, Sendable, Codable {
    public let text: String
    public let madeBy: String?

    public init(text: String, madeBy: String? = nil) {
        self.text = text
        self.madeBy = madeBy
    }

    enum CodingKeys: String, CodingKey {
        case text
        case madeBy = "made_by"
    }
}

/// Runtime-owned loop.wf1 output.
public struct LoopOutput: Equatable, Sendable, Codable {
    public let actionItems: [ActionItem]
    public let decisions: [Decision]
    public let followUps: [String]
    public let summary: String

    public init(
        actionItems: [ActionItem],
        decisions: [Decision],
        followUps: [String],
        summary: String
    ) {
        self.actionItems = actionItems
        self.decisions = decisions
        self.followUps = followUps
        self.summary = summary
    }

    public static let empty = LoopOutput(
        actionItems: [],
        decisions: [],
        followUps: [],
        summary: ""
    )

    enum CodingKeys: String, CodingKey {
        case actionItems = "action_items"
        case decisions
        case followUps = "follow_ups"
        case summary
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

public struct AppStateEventPayload: Equatable, Sendable {
    public let state: String?
    public let sessionId: String?
    public let executionId: String?
    public let output: LoopOutput?
    public let errorMessage: String?

    public init(
        state: String? = nil,
        sessionId: String? = nil,
        executionId: String? = nil,
        output: LoopOutput? = nil,
        errorMessage: String? = nil
    ) {
        self.state = state
        self.sessionId = sessionId
        self.executionId = executionId
        self.output = output
        self.errorMessage = errorMessage
    }
}

public enum LoopClientError: Error, Equatable, Sendable {
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

    /// Dictionary mapping (object payloads only).
    public var asDictionary: [String: Any] {
        guard case .object(let object) = self else { return [:] }
        return object.mapValues { $0.asAny }
    }

    public var asAny: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .object(let value): return value.mapValues { $0.asAny }
        case .array(let value): return value.map { $0.asAny }
        case .null: return NSNull()
        }
    }
}

public enum LoopOutputParser {
    public static func parse(_ raw: Any?) -> LoopOutput? {
        guard let dict = raw as? [String: Any],
              let summary = dict["summary"] as? String else {
            return nil
        }
        let actionItems = parseActionItems(dict["action_items"])
        let decisions = parseDecisions(dict["decisions"])
        let followUps = dict["follow_ups"] as? [String] ?? []
        return LoopOutput(
            actionItems: actionItems,
            decisions: decisions,
            followUps: followUps,
            summary: summary
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

    private static func parseActionItems(_ raw: Any?) -> [ActionItem] {
        guard let items = raw as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let task = item["task"] as? String else { return nil }
            return ActionItem(
                task: task,
                owner: item["owner"] as? String,
                due: item["due"] as? String
            )
        }
    }

    private static func parseDecisions(_ raw: Any?) -> [Decision] {
        guard let items = raw as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let text = item["text"] as? String else { return nil }
            return Decision(text: text, madeBy: item["made_by"] as? String)
        }
    }
}
