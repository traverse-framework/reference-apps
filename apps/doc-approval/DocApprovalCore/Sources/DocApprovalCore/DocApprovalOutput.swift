import Foundation

public struct DocApprovalOutput: Equatable, Sendable, Codable {
    public let docType: String
    public let parties: [String]
    public let amounts: [String]
    public let confidence: Double
    public let recommendation: String

    public init(
        docType: String,
        parties: [String],
        amounts: [String],
        confidence: Double,
        recommendation: String
    ) {
        self.docType = docType
        self.parties = parties
        self.amounts = amounts
        self.confidence = confidence
        self.recommendation = recommendation
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
    public let output: DocApprovalOutput?
    public let errorMessage: String?

    public init(
        state: String? = nil,
        sessionId: String? = nil,
        executionId: String? = nil,
        output: DocApprovalOutput? = nil,
        errorMessage: String? = nil
    ) {
        self.state = state
        self.sessionId = sessionId
        self.executionId = executionId
        self.output = output
        self.errorMessage = errorMessage
    }
}

public struct ApprovalSession: Equatable, Sendable, Identifiable, Codable {
    public var id: String { sessionId }
    public let sessionId: String
    public let state: String
    public let title: String?

    public init(sessionId: String, state: String, title: String? = nil) {
        self.sessionId = sessionId
        self.state = state
        self.title = title
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case state
        case title
    }
}

public enum DocApprovalClientError: Error, Equatable, Sendable {
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

public enum DocApprovalOutputParser {
    public static func parse(_ raw: Any?) -> DocApprovalOutput? {
        guard let dict = raw as? [String: Any],
              let docType = dict["docType"] as? String,
              let parties = dict["parties"] as? [String],
              let amounts = dict["amounts"] as? [String],
              let recommendation = dict["recommendation"] as? String else {
            return nil
        }
        let confidence: Double
        if let value = dict["confidence"] as? Double {
            confidence = value
        } else if let value = dict["confidence"] as? Int {
            confidence = Double(value)
        } else if let value = dict["confidence"] as? NSNumber {
            confidence = value.doubleValue
        } else {
            return nil
        }
        return DocApprovalOutput(
            docType: docType,
            parties: parties,
            amounts: amounts,
            confidence: confidence,
            recommendation: recommendation
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

    public static func parseSessions(_ raw: Any?) -> [ApprovalSession] {
        let items: [[String: Any]]
        if let array = raw as? [[String: Any]] {
            items = array
        } else if let dict = raw as? [String: Any],
                  let array = dict["sessions"] as? [[String: Any]] {
            items = array
        } else {
            return []
        }
        return items.compactMap { item in
            let sessionId = (item["session_id"] as? String) ?? (item["id"] as? String)
            guard let sessionId, let state = item["state"] as? String else { return nil }
            return ApprovalSession(
                sessionId: sessionId,
                state: state,
                title: item["title"] as? String
            )
        }
    }
}
