import Foundation

/// Canonical UI presentation states (Spec 001).
public enum PresentationState: String, Equatable, Sendable {
    case idle
    case loading
    case loaded
    case blocked
    case ended
    case error
}

public struct PresentationSnapshot: Equatable, Sendable {
    public let state: PresentationState
    public let errorMessage: String?
    public let output: Any?

    public init(state: PresentationState, errorMessage: String?, output: Any?) {
        self.state = state
        self.errorMessage = errorMessage
        self.output = output
    }

    public static func == (lhs: PresentationSnapshot, rhs: PresentationSnapshot) -> Bool {
        lhs.state == rhs.state && lhs.errorMessage == rhs.errorMessage
    }
}

public enum CapabilityPhase: String, Equatable, Sendable {
    case invoked
    case result
}

public struct CapabilityProgressStep: Equatable, Sendable {
    public let capabilityId: String
    public let phase: CapabilityPhase
    public let sequence: UInt64
    public let status: String?
    public let output: Any?

    public init(
        capabilityId: String,
        phase: CapabilityPhase,
        sequence: UInt64,
        status: String?,
        output: Any?
    ) {
        self.capabilityId = capabilityId
        self.phase = phase
        self.sequence = sequence
        self.status = status
        self.output = output
    }

    public static func == (lhs: CapabilityProgressStep, rhs: CapabilityProgressStep) -> Bool {
        lhs.capabilityId == rhs.capabilityId
            && lhs.phase == rhs.phase
            && lhs.sequence == rhs.sequence
            && lhs.status == rhs.status
    }
}

/// Minimal embedder event fields required by the mapper.
public struct EmbedderEventLike: Equatable, Sendable {
    public let eventType: String
    public let sequence: UInt64
    public let data: [String: Any]

    public init(eventType: String, sequence: UInt64, data: [String: Any]) {
        self.eventType = eventType
        self.sequence = sequence
        self.data = data
    }

    public static func == (lhs: EmbedderEventLike, rhs: EmbedderEventLike) -> Bool {
        lhs.eventType == rhs.eventType && lhs.sequence == rhs.sequence
    }
}

/// Spec 001/002 presentation + capability progress (language-equivalent of
/// `packages/event-ui-conformance`).
public enum PresentationMapper {
    private static let blockedStates: Set<String> = [
        "blocked", "waiting", "waiting_for_human", "awaiting_human", "awaiting_input",
    ]
    private static let endedStates: Set<String> = [
        "cancelled", "canceled", "closed", "ended",
    ]

    public static func mapPresentationState(_ events: [EmbedderEventLike]) -> PresentationSnapshot {
        if events.isEmpty {
            return PresentationSnapshot(state: .idle, errorMessage: nil, output: nil)
        }

        var state: PresentationState = .idle
        var errorMessage: String?
        var output: Any?

        for event in events {
            switch event.eventType {
            case "error":
                state = .error
                errorMessage = errorMessageFromData(event.data) ?? "execution failed"
            case "capability_invoked":
                if state != .error {
                    state = .loading
                }
            case "state_changed":
                if state == .error { break }
                if isBlockedPayload(event.data) {
                    state = .blocked
                } else if isEndedStatePayload(event.data) {
                    state = .ended
                } else if state != .loaded && state != .ended {
                    state = .loading
                }
            case "capability_result":
                if state == .error { break }
                if hasRenderableOutput(event.data) {
                    state = .loaded
                    output = event.data["output"]
                } else {
                    state = .ended
                    output = nil
                }
            default:
                break
            }
        }

        return PresentationSnapshot(state: state, errorMessage: errorMessage, output: output)
    }

    public static func mapCapabilityProgress(_ events: [EmbedderEventLike]) -> [CapabilityProgressStep] {
        var steps: [CapabilityProgressStep] = []
        for event in events {
            guard let capabilityId = event.data["capability_id"] as? String else { continue }
            switch event.eventType {
            case "capability_invoked":
                steps.append(
                    CapabilityProgressStep(
                        capabilityId: capabilityId,
                        phase: .invoked,
                        sequence: event.sequence,
                        status: nil,
                        output: nil
                    )
                )
            case "capability_result":
                steps.append(
                    CapabilityProgressStep(
                        capabilityId: capabilityId,
                        phase: .result,
                        sequence: event.sequence,
                        status: event.data["status"] as? String,
                        output: event.data["output"]
                    )
                )
            default:
                break
            }
        }
        return steps
    }

    public static func activeCapabilityId(_ events: [EmbedderEventLike]) -> String? {
        let progress = mapCapabilityProgress(events)
        var open: [String: Int] = [:]
        for step in progress {
            switch step.phase {
            case .invoked:
                open[step.capabilityId, default: 0] += 1
            case .result:
                let count = open[step.capabilityId] ?? 0
                if count <= 1 {
                    open.removeValue(forKey: step.capabilityId)
                } else {
                    open[step.capabilityId] = count - 1
                }
            }
        }
        for step in progress.reversed() {
            if step.phase == .invoked, open[step.capabilityId] != nil {
                return step.capabilityId
            }
        }
        return nil
    }

    private static func errorMessageFromData(_ data: [String: Any]) -> String? {
        if let err = data["error"] as? String { return err }
        if let err = data["error"] as? [String: Any], let message = err["message"] as? String {
            return message
        }
        return nil
    }

    private static func runtimeStateToken(_ data: [String: Any]) -> String? {
        (data["state"] as? String)
            ?? (data["status"] as? String)
            ?? (data["runtime_state"] as? String)
    }

    private static func isBlockedPayload(_ data: [String: Any]) -> Bool {
        if data["blocked"] as? Bool == true || data["waiting_for_human"] as? Bool == true {
            return true
        }
        guard let token = runtimeStateToken(data)?.lowercased() else { return false }
        return blockedStates.contains(token)
    }

    private static func isEndedStatePayload(_ data: [String: Any]) -> Bool {
        guard let token = runtimeStateToken(data)?.lowercased() else { return false }
        return endedStates.contains(token)
    }

    private static func hasRenderableOutput(_ data: [String: Any]) -> Bool {
        guard data.keys.contains("output") else { return false }
        let output = data["output"]
        if output == nil || output is NSNull { return false }
        if let dict = output as? [String: Any], dict.isEmpty { return false }
        return true
    }
}
