import Foundation

public struct MeetingNotesCommand: Equatable, Sendable {
    public let name: String
    public let payload: [String: String]
    public let sessionId: String?

    public init(name: String, payload: [String: String] = [:], sessionId: String? = nil) {
        self.name = name
        self.payload = payload
        self.sessionId = sessionId
    }

    public static func submit(transcript: String, sessionId: String? = nil) -> MeetingNotesCommand {
        MeetingNotesCommand(name: "submit", payload: ["transcript": transcript], sessionId: sessionId)
    }
}
