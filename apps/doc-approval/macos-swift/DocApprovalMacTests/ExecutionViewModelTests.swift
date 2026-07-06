import Foundation
import XCTest
@testable import DocApprovalMac

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
    func testCanSubmitWhenOnlineWithDocument() async {
        let settings = AppSettings()
        let client = MockTraverseClient()
        client.healthOK = true
        let vm = ExecutionViewModel(client: client, settings: settings)
        await vm.refreshHealth()
        vm.document = "hello"
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
                output: DocApprovalOutput(
                    docType: "invoice",
                    parties: ["Acme"],
                    amounts: ["$500"],
                    confidence: 0.88,
                    recommendation: "approve"
                ),
                error: nil
            ),
        ]
        let vm = ExecutionViewModel(client: client, settings: settings)
        await vm.refreshHealth()
        vm.document = "invoice #123"
        vm.submit()
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        if case .succeeded(let output, _) = vm.phase {
            XCTAssertEqual(output.docType, "invoice")
        } else {
            XCTFail("expected succeeded, got \(vm.phase)")
        }
    }

    func testResetReturnsToIdle() async {
        let settings = AppSettings()
        let client = MockTraverseClient()
        client.pollResults = [
            ExecutionPollResult(
                executionId: "exec_test",
                status: "failed",
                output: nil,
                error: "boom"
            ),
        ]
        let vm = ExecutionViewModel(client: client, settings: settings)
        await vm.refreshHealth()
        vm.document = "doc"
        vm.submit()
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard case .failed = vm.phase else {
            return XCTFail("expected failed, got \(vm.phase)")
        }
        vm.reset()
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertEqual(vm.document, "")
    }
}
