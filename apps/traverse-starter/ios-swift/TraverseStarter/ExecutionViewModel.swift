import Foundation

enum ExecutionPhase: Equatable {
    case idle
    case loading
    case polling(executionId: String)
    case succeeded(output: TraverseStarterOutput, trace: [TraceEvent])
    case failed(error: String)
}

enum RuntimeStatus: Equatable {
    case checking
    case online
    case offline
}

@MainActor
final class ExecutionViewModel: ObservableObject {
    @Published private(set) var phase: ExecutionPhase = .idle
    @Published var note: String = ""
    @Published private(set) var runtimeStatus: RuntimeStatus = .checking
    @Published var showTrace = false

    private let client: TraverseClientProtocol
    private let settings: AppSettings
    private var pollTask: Task<Void, Never>?
    private var healthTask: Task<Void, Never>?

    private static let terminalStatuses: Set<String> = ["succeeded", "failed"]
    private static let pollIntervalNanoseconds: UInt64 = 1_000_000_000

    init(client: TraverseClientProtocol, settings: AppSettings) {
        self.client = client
        self.settings = settings
        startHealthChecks()
    }

    deinit {
        pollTask?.cancel()
        healthTask?.cancel()
    }

    var canSubmit: Bool {
        runtimeStatus == .online &&
            !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isRunning
    }

    var isRunning: Bool {
        switch phase {
        case .loading, .polling: return true
        default: return false
        }
    }

    func startHealthChecks() {
        healthTask?.cancel()
        healthTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshHealth()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func refreshHealth() async {
        guard let baseURL = settings.baseURL else {
            runtimeStatus = .offline
            return
        }
        runtimeStatus = .checking
        do {
            let ok = try await client.checkHealth(baseURL: baseURL)
            runtimeStatus = ok ? .online : .offline
        } catch {
            runtimeStatus = .offline
        }
    }

    func submit() {
        guard canSubmit, let baseURL = settings.baseURL else { return }
        pollTask?.cancel()
        phase = .loading
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let workspace = settings.workspace
        pollTask = Task { [weak self] in
            guard let self else { return }
            do {
                let executionId = try await client.execute(
                    workspaceId: workspace,
                    capability: AppSettings.capabilityId,
                    input: ["note": trimmedNote],
                    baseURL: baseURL
                )
                await MainActor.run { self.phase = .polling(executionId: executionId) }
                try await self.pollUntilTerminal(
                    workspaceId: workspace,
                    executionId: executionId,
                    baseURL: baseURL
                )
            } catch {
                await MainActor.run { self.phase = .failed(error: String(describing: error)) }
            }
        }
    }

    func reset() {
        pollTask?.cancel()
        pollTask = nil
        phase = .idle
        showTrace = false
    }

    private func pollUntilTerminal(workspaceId: String, executionId: String, baseURL: URL) async throws {
        while !Task.isCancelled {
            let result = try await client.pollExecution(
                workspaceId: workspaceId,
                executionId: executionId,
                baseURL: baseURL
            )
            if Self.terminalStatuses.contains(result.status) {
                if result.status == "succeeded" {
                    let trace = (try? await client.fetchTrace(
                        workspaceId: workspaceId,
                        executionId: executionId,
                        baseURL: baseURL
                    )) ?? []
                    let output = result.output ?? TraverseStarterOutput(
                        title: "",
                        tags: [],
                        noteType: "",
                        suggestedNextAction: "",
                        status: ""
                    )
                    await MainActor.run {
                        self.phase = .succeeded(output: output, trace: trace)
                    }
                } else {
                    await MainActor.run {
                        self.phase = .failed(error: result.error ?? "execution failed")
                    }
                }
                return
            }
            try await Task.sleep(nanoseconds: Self.pollIntervalNanoseconds)
        }
    }
}
