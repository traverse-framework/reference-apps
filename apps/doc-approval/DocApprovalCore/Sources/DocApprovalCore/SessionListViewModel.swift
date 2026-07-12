import Combine
import Foundation

/// Polls pending-review sessions for the approver surface.
@MainActor
public final class SessionListViewModel: ObservableObject {
    @Published public private(set) var sessions: [ApprovalSession] = []
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var loading: Bool = false

    public let appId: String
    public let stateFilter: String

    private let client: DocApprovalClientProtocol
    private var baseURL: URL?
    private var workspaceId: String
    private var pollTask: Task<Void, Never>?

    public init(
        client: DocApprovalClientProtocol,
        baseURL: URL?,
        workspaceId: String,
        appId: String = "doc-approval",
        stateFilter: String = "pending_review"
    ) {
        self.client = client
        self.baseURL = baseURL
        self.workspaceId = workspaceId
        self.appId = appId
        self.stateFilter = stateFilter
        startPolling()
    }

    deinit {
        pollTask?.cancel()
    }

    public func updateConnection(baseURL: URL?, workspaceId: String) {
        self.baseURL = baseURL
        self.workspaceId = workspaceId
        Task { await refresh() }
    }

    public func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    public func refresh() async {
        guard let baseURL else {
            sessions = []
            return
        }
        loading = true
        defer { loading = false }
        do {
            sessions = try await client.listSessions(
                workspaceId: workspaceId,
                appId: appId,
                state: stateFilter,
                baseURL: baseURL
            )
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
