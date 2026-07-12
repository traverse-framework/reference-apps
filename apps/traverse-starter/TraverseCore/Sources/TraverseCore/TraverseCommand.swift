import Foundation

public struct TraverseCommand: Equatable, Sendable {
    public let name: String
    public let payload: [String: String]
    public let sessionId: String?

    public init(name: String, payload: [String: String] = [:], sessionId: String? = nil) {
        self.name = name
        self.payload = payload
        self.sessionId = sessionId
    }

    public static func submit(note: String, sessionId: String? = nil) -> TraverseCommand {
        TraverseCommand(name: "submit", payload: ["note": note], sessionId: sessionId)
    }
}
