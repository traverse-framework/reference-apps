import Foundation
import XCTest
@testable import DocApprovalCore

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

enum TestURLSessionFactory {
    static func make() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

final class DocApprovalClientTests: XCTestCase {
    func testCheckHealthReturnsTrueOn200() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.path.hasSuffix("/healthz") == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let client = DocApprovalClient(session: TestURLSessionFactory.make())
        let ok = try await client.checkHealth(baseURL: URL(string: "http://127.0.0.1:8787")!)
        XCTAssertTrue(ok)
    }

    func testSendCommandPostsToAppsCommands() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/apps/doc-approval/commands") == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!
            let body = """
            {"api_version":"v1","status":"accepted","workspace_id":"local-default","app_id":"doc-approval","session_id":"sess-1","command":"submit","state":"processing","execution_id":"exec-1"}
            """.data(using: .utf8)!
            return (response, body)
        }
        let client = DocApprovalClient(session: TestURLSessionFactory.make())
        let accepted = try await client.sendCommand(
            workspaceId: "local-default",
            appId: "doc-approval",
            command: .submit(document: "hello"),
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(accepted.sessionId, "sess-1")
        XCTAssertEqual(accepted.state, "processing")
    }

    func testSessionScopedSendCommandIncludesSessionId() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/apps/doc-approval/commands") == true)
            if let bodyData = request.httpBody,
               let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                XCTAssertEqual(body["session_id"] as? String, "sess-approve")
                XCTAssertEqual(body["command"] as? String, "approve")
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!
            let data = """
            {"api_version":"v1","status":"accepted","workspace_id":"local-default","app_id":"doc-approval","session_id":"sess-approve","command":"approve","state":"approved"}
            """.data(using: .utf8)!
            return (response, data)
        }
        let client = DocApprovalClient(session: TestURLSessionFactory.make())
        let accepted = try await client.sendCommand(
            sessionId: "sess-approve",
            command: "approve",
            payload: [:],
            workspaceId: "local-default",
            appId: "doc-approval",
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(accepted.command, "approve")
    }

    func testListSessionsParsesPendingReview() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.path.contains("/apps/doc-approval/sessions") == true)
            XCTAssertEqual(request.url?.query, "state=pending_review")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = """
            {"sessions":[{"session_id":"s1","state":"pending_review","title":"Contract"}]}
            """.data(using: .utf8)!
            return (response, body)
        }
        let client = DocApprovalClient(session: TestURLSessionFactory.make())
        let sessions = try await client.listSessions(
            workspaceId: "local-default",
            appId: "doc-approval",
            state: "pending_review",
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].sessionId, "s1")
        XCTAssertEqual(sessions[0].title, "Contract")
    }

    func testAppEventsURL() {
        let client = DocApprovalClient()
        let url = client.appEventsURL(
            workspaceId: "local-default",
            appId: "doc-approval",
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(url.path, "/v1/workspaces/local-default/apps/doc-approval/events")
    }
}

final class DocApprovalOutputTests: XCTestCase {
    func testParseOutput() {
        let raw: [String: Any] = [
            "analysis": [
                "docType": "nda",
                "parties": ["A", "B"],
                "amounts": ["$1"],
                "confidence": 0.9,
                "recommendation": "approve",
            ],
            "recommendation": [
                "recommendation": "approve",
                "rationale": "Policy match",
                "confidence": "high",
            ],
        ]
        let output = DocApprovalOutputParser.parse(raw)
        XCTAssertEqual(output?.analysis.docType, "nda")
        XCTAssertEqual(output?.recommendation.recommendation, "approve")
        XCTAssertEqual(output?.analysis.confidence, "0.9")
    }

    func testParseEventPayload() {
        let raw: [String: Any] = [
            "state": "results",
            "session_id": "sess-1",
            "execution_id": "exec-1",
            "output": [
                "analysis": [
                    "docType": "nda",
                    "parties": [] as [String],
                    "amounts": [] as [String],
                    "confidence": 0.5,
                    "recommendation": "review",
                ],
                "recommendation": [
                    "recommendation": "review",
                    "rationale": "Needs human",
                    "confidence": "medium",
                ],
            ],
        ]
        let payload = DocApprovalOutputParser.parseEventPayload(raw)
        XCTAssertEqual(payload?.state, "results")
        XCTAssertEqual(payload?.output?.analysis.docType, "nda")
    }

    func testParseSessionsArray() {
        let raw: [[String: Any]] = [
            ["session_id": "s1", "state": "pending_review"],
        ]
        let sessions = DocApprovalOutputParser.parseSessions(raw)
        XCTAssertEqual(sessions.first?.sessionId, "s1")
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    final class MockClient: DocApprovalClientProtocol, @unchecked Sendable {
        var healthOK = true
        var listed: [ApprovalSession] = []
        func checkHealth(baseURL: URL) async throws -> Bool { healthOK }
        func sendCommand(
            workspaceId: String,
            appId: String,
            command: DocApprovalCommand,
            baseURL: URL
        ) async throws -> CommandAccepted {
            CommandAccepted(
                apiVersion: "v1",
                status: "accepted",
                workspaceId: workspaceId,
                appId: appId,
                sessionId: "sess-1",
                command: command.name,
                state: "processing",
                executionId: "exec-1"
            )
        }
        func sendCommand(
            sessionId: String,
            command: String,
            payload: [String: String],
            workspaceId: String,
            appId: String,
            baseURL: URL
        ) async throws -> CommandAccepted {
            CommandAccepted(
                apiVersion: "v1",
                status: "accepted",
                workspaceId: workspaceId,
                appId: appId,
                sessionId: sessionId,
                command: command,
                state: "processing",
                executionId: nil
            )
        }
        func listSessions(
            workspaceId: String,
            appId: String,
            state: String?,
            baseURL: URL
        ) async throws -> [ApprovalSession] {
            listed
        }
        func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent] {
            []
        }
        func appEventsURL(workspaceId: String, appId: String, baseURL: URL) -> URL {
            URL(string: "http://127.0.0.1:8787/v1/workspaces/\(workspaceId)/apps/\(appId)/events")!
        }
        func subscribeAppEvents(
            workspaceId: String,
            appId: String,
            baseURL: URL,
            onEvent: @escaping @Sendable (String, AppStateEventPayload) -> Void
        ) async throws {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    func testHeartbeatMarksConnectedWithoutChangingState() {
        let vm = AppStateViewModel(
            client: MockClient(),
            baseURL: URL(string: "http://127.0.0.1:8787"),
            workspaceId: "local-default"
        )
        vm.apply(eventType: "heartbeat", payload: AppStateEventPayload())
        XCTAssertTrue(vm.connected)
        XCTAssertEqual(vm.currentState, "idle")
    }

    func testCapabilityResultMapsToResults() {
        let vm = AppStateViewModel(
            client: MockClient(),
            baseURL: URL(string: "http://127.0.0.1:8787"),
            workspaceId: "local-default"
        )
        vm.apply(
            eventType: "capability_result",
            payload: AppStateEventPayload(
                state: "results",
                sessionId: "sess-1",
                executionId: "exec-1",
                output: DocApprovalOutput(
                    analysis: AnalysisOutput(
                        docType: "nda",
                        parties: [],
                        amounts: [],
                        confidence: "0.8",
                        recommendation: "approve"
                    ),
                    recommendation: RecommendationOutput(
                        recommendation: "approve",
                        rationale: "Policy match",
                        confidence: "high"
                    )
                )
            )
        )
        XCTAssertEqual(vm.currentState, "results")
        XCTAssertEqual(vm.output?.analysis.docType, "nda")
    }

    func testCanSubmitWhenOnlineWithDocument() async {
        let vm = AppStateViewModel(
            client: MockClient(),
            baseURL: URL(string: "http://127.0.0.1:8787"),
            workspaceId: "local-default"
        )
        await vm.refreshHealth()
        vm.document = "hello"
        XCTAssertTrue(vm.canSubmit)
    }
}

@MainActor
final class SessionListViewModelTests: XCTestCase {
    func testRefreshLoadsSessions() async {
        let client = AppStateViewModelTests.MockClient()
        client.listed = [ApprovalSession(sessionId: "s1", state: "pending_review", title: "T")]
        let vm = SessionListViewModel(
            client: client,
            baseURL: URL(string: "http://127.0.0.1:8787"),
            workspaceId: "local-default"
        )
        await vm.refresh()
        XCTAssertEqual(vm.sessions.count, 1)
        XCTAssertEqual(vm.sessions[0].title, "T")
    }
}
