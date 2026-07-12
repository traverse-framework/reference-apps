import Foundation

public struct DocApprovalCommand: Equatable, Sendable {
    public let name: String
    public let payload: [String: String]
    public let sessionId: String?

    public init(name: String, payload: [String: String] = [:], sessionId: String? = nil) {
        self.name = name
        self.payload = payload
        self.sessionId = sessionId
    }

    public static func submit(document: String, sessionId: String? = nil) -> DocApprovalCommand {
        DocApprovalCommand(name: "submit", payload: ["document": document], sessionId: sessionId)
    }

    public static func approve(sessionId: String) -> DocApprovalCommand {
        DocApprovalCommand(name: "approve", payload: [:], sessionId: sessionId)
    }

    public static func reject(sessionId: String, reason: String = "") -> DocApprovalCommand {
        var payload: [String: String] = [:]
        if !reason.isEmpty { payload["reason"] = reason }
        return DocApprovalCommand(name: "reject", payload: payload, sessionId: sessionId)
    }
}
