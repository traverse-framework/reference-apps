import Foundation

struct DocApprovalOutput: Equatable, Codable {
    let docType: String
    let parties: [String]
    let amounts: [String]
    let confidence: Double
    let recommendation: String
}

struct TraceEvent: Equatable, Codable {
    let event_type: String
    let timestamp: String
    let data: JSONValue?
}

struct ExecutionPollResult: Equatable {
    let executionId: String
    let status: String
    let output: DocApprovalOutput?
    let error: String?
}

enum TraverseClientError: Error, Equatable {
    case http(status: Int)
    case decode
    case invalidURL
}

enum JSONValue: Equatable, Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

enum TraverseOutputParser {
    static func parse(_ raw: Any?) -> DocApprovalOutput? {
        guard let dict = raw as? [String: Any],
              let docType = dict["docType"] as? String,
              let parties = dict["parties"] as? [String],
              let amounts = dict["amounts"] as? [String],
              let confidence = dict["confidence"] as? Double,
              let recommendation = dict["recommendation"] as? String else {
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
}

protocol TraverseClientProtocol: Sendable {
    func checkHealth(baseURL: URL) async throws -> Bool
    func execute(workspaceId: String, capability: String, input: [String: String], baseURL: URL) async throws -> String
    func pollExecution(workspaceId: String, executionId: String, baseURL: URL) async throws -> ExecutionPollResult
    func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent]
}

final class TraverseClient: TraverseClientProtocol, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func checkHealth(baseURL: URL) async throws -> Bool {
        let url = baseURL.appendingPathComponent("healthz")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    func execute(workspaceId: String, capability: String, input: [String: String], baseURL: URL) async throws -> String {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/execute")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["capability": capability, "input": input])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TraverseClientError.decode }
        guard http.statusCode == 200 else { throw TraverseClientError.http(status: http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let executionId = json["execution_id"] as? String else {
            throw TraverseClientError.decode
        }
        return executionId
    }

    func pollExecution(workspaceId: String, executionId: String, baseURL: URL) async throws -> ExecutionPollResult {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/executions/\(executionId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TraverseClientError.decode }
        guard http.statusCode == 200 else { throw TraverseClientError.http(status: http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? String else {
            throw TraverseClientError.decode
        }
        let output = TraverseOutputParser.parse(json["output"])
        let error = json["error"] as? String
        return ExecutionPollResult(
            executionId: executionId,
            status: status,
            output: output,
            error: error
        )
    }

    func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent] {
        let url = baseURL
            .appendingPathComponent("v1/workspaces/\(workspaceId)/traces/\(executionId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TraverseClientError.decode }
        guard http.statusCode == 200 else { throw TraverseClientError.http(status: http.statusCode) }
        return try JSONDecoder().decode([TraceEvent].self, from: data)
    }
}
