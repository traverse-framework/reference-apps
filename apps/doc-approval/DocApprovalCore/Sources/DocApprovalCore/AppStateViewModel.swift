import Combine
import Foundation

public enum RuntimeStatus: Equatable, Sendable {
    case starting
    case ready
    case unavailable
}

/// Drives UI state from an embedded Traverse host.
/// Contains no local business-field computation.
@MainActor
public final class AppStateViewModel: ObservableObject {
    @Published public private(set) var currentState: String = "idle"
    @Published public private(set) var output: DocApprovalOutput?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var sessionId: String?
    @Published public private(set) var trace: [TraceEvent] = []
    @Published public private(set) var runtimeStatus: RuntimeStatus = .starting
    @Published public private(set) var submitting: Bool = false
    @Published public var document: String = ""
    @Published public var showTrace: Bool = false

    public let appId: String
    public let documentMaxLength: Int
    public let runtimeMode: String
    public let workflowId: String
    public private(set) var workspaceId: String

    private let host: EmbeddedHostProtocol?

    public init(
        host: EmbeddedHostProtocol?,
        workspaceId: String,
        appId: String = EmbeddedHost.defaultAppId,
        documentMaxLength: Int = 10_000
    ) {
        self.host = host
        self.workspaceId = workspaceId
        self.appId = appId
        self.documentMaxLength = documentMaxLength
        self.runtimeMode = EmbeddedHost.runtimeModeEmbedded
        self.workflowId = host?.workflowId ?? EmbeddedHost.defaultWorkflowId
        self.runtimeStatus = host?.isReady == true ? .ready : .unavailable
    }

    public var canSubmit: Bool {
        runtimeStatus == .ready &&
            !document.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isRunning
    }

    public var isRunning: Bool {
        submitting || currentState == "processing"
    }

    public func updateWorkspace(_ workspaceId: String) {
        self.workspaceId = workspaceId
    }

    public func refreshRuntimeStatus() {
        runtimeStatus = host?.isReady == true ? .ready : .unavailable
    }

    public func submit() {
        guard canSubmit, let host else { return }
        let trimmed = String(document.trimmingCharacters(in: .whitespacesAndNewlines).prefix(documentMaxLength))
        submitting = true
        currentState = "processing"
        errorMessage = nil
        output = nil
        trace = []
        showTrace = false
        sessionId = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await Task.detached {
                    try host.submitDocument(trimmed)
                }.value
                await MainActor.run {
                    self.sessionId = result.sessionId
                    self.trace = result.events
                    self.showTrace = !result.events.isEmpty
                    self.submitting = false
                    if let error = result.error {
                        self.currentState = "error"
                        self.errorMessage = error
                    } else {
                        self.output = result.output ?? .empty
                        self.currentState = "completed"
                    }
                }
            } catch {
                await MainActor.run {
                    self.submitting = false
                    self.currentState = "error"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    public func reset() {
        submitting = false
        currentState = "idle"
        sessionId = nil
        output = nil
        trace = []
        errorMessage = nil
        showTrace = false
    }

    /// Compatibility alias for shell call sites.
    public func resetLocal() {
        reset()
    }
}
