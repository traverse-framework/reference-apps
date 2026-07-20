import Combine
import Foundation

public enum RuntimeStatus: Equatable, Sendable {
    case ready
    case unavailable
}

/// Drives the UI from embedded runtime events.
/// No business logic resides here — all state comes from the runtime.
@MainActor
public final class AppStateViewModel: ObservableObject {
    @Published public private(set) var currentState: String = "idle"
    @Published public private(set) var output: TraverseStarterOutput?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var sessionId: String?
    @Published public private(set) var trace: [TraceEvent] = []
    @Published public private(set) var runtimeStatus: RuntimeStatus
    @Published public private(set) var submitting: Bool = false
    @Published public var note: String = ""
    @Published public var showTrace: Bool = false

    public let appId: String
    public let noteMaxLength: Int

    private let host: (any EmbeddedRuntimeHostProtocol)?

    public init(
        host: (any EmbeddedRuntimeHostProtocol)?,
        appId: String = EmbeddedRuntime.defaultAppID,
        noteMaxLength: Int = 2000
    ) {
        self.host = host
        self.appId = appId
        self.noteMaxLength = noteMaxLength
        self.runtimeStatus = host?.isReady == true ? .ready : .unavailable
    }

    public var canSubmit: Bool {
        runtimeStatus == .ready &&
            !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isRunning
    }

    public var isRunning: Bool {
        submitting || currentState == "processing"
    }

    public func submit() {
        guard canSubmit, let host else { return }
        let trimmed = String(
            note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(noteMaxLength)
        )
        submitting = true
        errorMessage = nil
        trace = []
        currentState = "processing"
        Task { [weak self, host] in
            guard let self else { return }
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try host.submit(note: trimmed)
                }.value
                await MainActor.run { self.apply(result: result) }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(describing: error)
                    self.submitting = false
                    self.currentState = "error"
                }
            }
        }
    }

    public func resetLocal() {
        currentState = "idle"
        output = nil
        errorMessage = nil
        sessionId = nil
        trace = []
        showTrace = false
        submitting = false
    }

    func apply(result: HostRunResult) {
        sessionId = result.sessionID
        trace = result.events
        submitting = false
        if let error = result.error {
            errorMessage = error
            currentState = "error"
        } else {
            output = result.output
            currentState = "results"
            errorMessage = nil
        }
    }
}
