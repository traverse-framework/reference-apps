import Combine
import Foundation

public enum RuntimeStatus: Equatable, Sendable {
    case checking
    case online
    case offline
}

/// Subscribes to runtime app SSE and maps event payloads to render state.
@MainActor
public final class AppStateViewModel: ObservableObject {
    @Published public private(set) var currentState: String = "idle"
    @Published public private(set) var output: DocApprovalOutput?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var connected: Bool = false
    @Published public private(set) var sessionId: String?
    @Published public private(set) var executionId: String?
    @Published public private(set) var trace: [TraceEvent] = []
    @Published public private(set) var runtimeStatus: RuntimeStatus = .checking
    @Published public private(set) var submitting: Bool = false
    @Published public var document: String = ""
    @Published public var showTrace: Bool = false

    public let appId: String
    public let documentMaxLength: Int

    private let client: DocApprovalClientProtocol
    private var baseURL: URL?
    private var workspaceId: String
    private var sseTask: Task<Void, Never>?
    private var healthTask: Task<Void, Never>?

    public init(
        client: DocApprovalClientProtocol,
        baseURL: URL?,
        workspaceId: String,
        appId: String = "doc-approval",
        documentMaxLength: Int = 10_000
    ) {
        self.client = client
        self.baseURL = baseURL
        self.workspaceId = workspaceId
        self.appId = appId
        self.documentMaxLength = documentMaxLength
        startHealthChecks()
        startSSE()
    }

    deinit {
        sseTask?.cancel()
        healthTask?.cancel()
    }

    public var canSubmit: Bool {
        runtimeStatus == .online &&
            !document.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isRunning
    }

    public var isRunning: Bool {
        submitting || currentState == "processing"
    }

    public func updateConnection(baseURL: URL?, workspaceId: String) {
        let changed = self.baseURL != baseURL || self.workspaceId != workspaceId
        self.baseURL = baseURL
        self.workspaceId = workspaceId
        if changed {
            startSSE()
            Task { await refreshHealth() }
        }
    }

    public func startHealthChecks() {
        healthTask?.cancel()
        healthTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshHealth()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    public func refreshHealth() async {
        guard let baseURL else {
            runtimeStatus = .offline
            return
        }
        do {
            let ok = try await client.checkHealth(baseURL: baseURL)
            runtimeStatus = ok ? .online : .offline
        } catch {
            runtimeStatus = .offline
        }
    }

    public func submit() {
        guard canSubmit, let baseURL else { return }
        let trimmed = String(document.trimmingCharacters(in: .whitespacesAndNewlines).prefix(documentMaxLength))
        submitting = true
        errorMessage = nil
        trace = []
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await client.sendCommand(
                    workspaceId: workspaceId,
                    appId: appId,
                    command: .submit(document: trimmed),
                    baseURL: baseURL
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = String(describing: error)
                    self.submitting = false
                }
                return
            }
            await MainActor.run { self.submitting = false }
        }
    }

    public func resetLocal() {
        currentState = "idle"
        output = nil
        errorMessage = nil
        executionId = nil
        sessionId = nil
        trace = []
        showTrace = false
        submitting = false
    }

    private func startSSE() {
        sseTask?.cancel()
        connected = false
        guard let baseURL else { return }
        let workspaceId = self.workspaceId
        let appId = self.appId
        sseTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await client.subscribeAppEvents(
                        workspaceId: workspaceId,
                        appId: appId,
                        baseURL: baseURL
                    ) { [weak self] type, payload in
                        Task { @MainActor in
                            self?.apply(eventType: type, payload: payload)
                        }
                    }
                } catch {
                    await MainActor.run { self.connected = false }
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func apply(eventType: String, payload: AppStateEventPayload) {
        if eventType == "heartbeat" {
            connected = true
            return
        }
        connected = true
        if let state = payload.state, !state.isEmpty {
            currentState = state
        }
        if let sessionId = payload.sessionId {
            self.sessionId = sessionId
        }
        if let executionId = payload.executionId {
            self.executionId = executionId
        }
        if let output = payload.output {
            self.output = output
        }
        if let errorMessage = payload.errorMessage {
            self.errorMessage = errorMessage
        } else if payload.state == "results" {
            self.errorMessage = nil
        }
        if currentState == "results", let executionId, let baseURL {
            Task { [weak self] in
                guard let self else { return }
                let events = (try? await client.fetchTrace(
                    workspaceId: workspaceId,
                    executionId: executionId,
                    baseURL: baseURL
                )) ?? []
                await MainActor.run { self.trace = events }
            }
        }
    }
}
