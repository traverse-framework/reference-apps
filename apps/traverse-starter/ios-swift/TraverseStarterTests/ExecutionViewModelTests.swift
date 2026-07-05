import Foundation
import XCTest
@testable import TraverseStarter

@MainActor
final class MockTraverseClient: TraverseClientProtocol {
    var healthOK = true
    var executionId = "exec_test"
    var pollResults: [ExecutionPollResult] = []
    var pollIndex = 0
    var trace: [TraceEvent] = []

    func checkHealth(baseURL: URL) async throws -> Bool { healthOK }

    func execute(workspaceId: String, capability: String, input: [String: String], baseURL: URL) async throws -> String {
        executionId
    }

    func pollExecution(workspaceId: String, executionId: String, baseURL: URL) async throws -> ExecutionPollResult {
        defer { pollIndex += 1 }
        if pollIndex < pollResults.count {
            return pollResults[pollIndex]
        }
        return pollResults.last!
    }

    func fetchTrace(workspaceId: String, executionId: String, baseURL: URL) async throws -> [TraceEvent] {
        trace
    }
}

@MainActor
final class ExecutionViewModelTests: XCTestCase {
    func testCanSubmitWhenOnlineWithNote() {
        let settings = AppSettings()
        let client = MockTraverseClient()
        client.healthOK = true
        let vm = ExecutionViewModel(client: client, settings: settings)
        vm.runtimeStatus = .online
        vm.note = "hello"
        XCTAssertTrue(vm.canSubmit)
    }

    func testSubmitTransitionsToSucceeded() async {
        let settings = AppSettings()
        let client = MockTraverseClient()
        client.pollResults = [
            ExecutionPollResult(
                executionId: "exec_test",
                status: "running",
                output: nil,
                error: nil
            ),
            ExecutionPollResult(
                executionId: "exec_test",
                status: "succeeded",
                output: TraverseStarterOutput(
                    title: "Title",
                    tags: ["tag"],
                    noteType: "meeting",
                    suggestedNextAction: "follow up",
                    status: "processed"
                ),
                error: nil
            ),
        ]
        let vm = ExecutionViewModel(client: client, settings: settings)
        vm.runtimeStatus = .online
        vm.note = "note text"
        vm.submit()
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        if case .succeeded(let output, _) = vm.phase {
            XCTAssertEqual(output.title, "Title")
        } else {
            XCTFail("expected succeeded, got \(vm.phase)")
        }
    }

    func testResetReturnsToIdle() {
        let settings = AppSettings()
        let vm = ExecutionViewModel(client: MockTraverseClient(), settings: settings)
        vm.phase = .failed(error: "boom")
        vm.reset()
        XCTAssertEqual(vm.phase, .idle)
    }
}
