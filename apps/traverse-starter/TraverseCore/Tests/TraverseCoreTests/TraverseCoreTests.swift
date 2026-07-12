import Foundation
import XCTest
@testable import TraverseCore

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

final class TraverseClientTests: XCTestCase {
    func testCheckHealthReturnsTrueOn200() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.path.hasSuffix("/healthz") == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let client = TraverseClient(session: TestURLSessionFactory.make())
        let ok = try await client.checkHealth(baseURL: URL(string: "http://127.0.0.1:8787")!)
        XCTAssertTrue(ok)
    }

    func testSendCommandPostsToAppsCommands() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/apps/traverse-starter/commands") == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!
            let body = """
            {"api_version":"v1","status":"accepted","workspace_id":"local-default","app_id":"traverse-starter","session_id":"sess-1","command":"submit","state":"processing","execution_id":"exec-1"}
            """.data(using: .utf8)!
            return (response, body)
        }
        let client = TraverseClient(session: TestURLSessionFactory.make())
        let accepted = try await client.sendCommand(
            workspaceId: "local-default",
            appId: "traverse-starter",
            command: .submit(note: "hello"),
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(accepted.sessionId, "sess-1")
        XCTAssertEqual(accepted.state, "processing")
        XCTAssertEqual(accepted.executionId, "exec-1")
    }

    func testAppEventsURL() {
        let client = TraverseClient()
        let url = client.appEventsURL(
            workspaceId: "local-default",
            appId: "traverse-starter",
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(url.path, "/v1/workspaces/local-default/apps/traverse-starter/events")
    }
}

final class TraverseOutputTests: XCTestCase {
    func testParseOutput() {
        let raw: [String: Any] = [
            "validate": ["valid": true, "issues": [] as [String]],
            "process": [
                "title": "T",
                "tags": ["a"],
                "noteType": "n",
                "suggestedNextAction": "x",
                "status": "done",
            ],
            "summarize": ["summary": "A short summary", "wordCount": 3],
        ]
        let output = TraverseOutputParser.parse(raw)
        XCTAssertEqual(output?.process.title, "T")
        XCTAssertEqual(output?.process.tags, ["a"])
        XCTAssertEqual(output?.validate.valid, true)
        XCTAssertEqual(output?.summarize.wordCount, 3)
    }

    func testParseRejectsFlatLegacyOutput() {
        let raw: [String: Any] = [
            "title": "T",
            "tags": ["a"],
            "noteType": "n",
            "suggestedNextAction": "x",
            "status": "done",
        ]
        XCTAssertNil(TraverseOutputParser.parse(raw))
    }

    func testParseEventPayload() {
        let raw: [String: Any] = [
            "state": "results",
            "session_id": "sess-1",
            "execution_id": "exec-1",
            "output": [
                "validate": ["valid": true, "issues": [] as [String]],
                "process": [
                    "title": "T",
                    "tags": [] as [String],
                    "noteType": "n",
                    "suggestedNextAction": "x",
                    "status": "done",
                ],
                "summarize": ["summary": "Summary", "wordCount": 1],
            ],
        ]
        let payload = TraverseOutputParser.parseEventPayload(raw)
        XCTAssertEqual(payload?.state, "results")
        XCTAssertEqual(payload?.output?.process.title, "T")
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    final class MockClient: TraverseClientProtocol, @unchecked Sendable {
        var healthOK = true
        func checkHealth(baseURL: URL) async throws -> Bool { healthOK }
        func sendCommand(
            workspaceId: String,
            appId: String,
            command: TraverseCommand,
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
            // Stay idle until cancelled for unit tests that drive apply() directly.
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
                output: TraverseStarterOutput(
                    validate: ValidateOutput(valid: true, issues: []),
                    process: ProcessOutput(
                        title: "T",
                        tags: [],
                        noteType: "n",
                        suggestedNextAction: "x",
                        status: "done"
                    ),
                    summarize: SummarizeOutput(summary: "Summary", wordCount: 1)
                )
            )
        )
        XCTAssertEqual(vm.currentState, "results")
        XCTAssertEqual(vm.output?.process.title, "T")
        XCTAssertEqual(vm.executionId, "exec-1")
    }

    func testCanSubmitWhenOnlineWithNote() async {
        let client = MockClient()
        let vm = AppStateViewModel(
            client: client,
            baseURL: URL(string: "http://127.0.0.1:8787"),
            workspaceId: "local-default"
        )
        await vm.refreshHealth()
        vm.note = "hello"
        XCTAssertTrue(vm.canSubmit)
    }
}
