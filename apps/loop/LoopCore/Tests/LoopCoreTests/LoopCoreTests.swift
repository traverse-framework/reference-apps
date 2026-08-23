import Foundation
import XCTest
@testable import LoopCore

final class EmbeddedHostTests: XCTestCase {
    private var sampleOutput: LoopOutput {
        LoopOutput(
            actionItems: [ActionItem(task: "Ship clients", owner: "Alex", due: "Friday")],
            decisions: [Decision(text: "Use embedded runtime", madeBy: "Team")],
            followUps: ["Schedule review"],
            summary: "Discussed Wave 2 ports"
        )
    }

    func testTestHostReturnsScriptedCapabilityResult() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let result = try host.submitTranscript("any transcript")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.output?.summary, "Discussed Wave 2 ports")
        XCTAssertTrue(result.events.contains { $0.event_type == "capability_result" })
    }

    func testPinnedDigestConstant() {
        XCTAssertTrue(EmbeddedHost.pinnedRuntimeWasmDigest.hasPrefix("sha256:"))
        XCTAssertEqual(EmbeddedHost.pinnedRuntimeWasmDigest.count, 71)
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    private var sampleOutput: LoopOutput {
        LoopOutput(
            actionItems: [ActionItem(task: "Ship clients")],
            decisions: [],
            followUps: [],
            summary: "Discussed Wave 2 ports"
        )
    }

    func testCanSubmitWhenReadyWithTranscript() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.transcript = "hello"
        XCTAssertEqual(vm.runtimeStatus, .ready)
        XCTAssertEqual(vm.runtimeMode, EmbeddedHost.runtimeModeEmbedded)
        XCTAssertTrue(vm.canSubmit)
    }

    func testUnavailableHostDisablesSubmit() {
        let vm = AppStateViewModel(host: nil, workspaceId: "local-default")
        vm.transcript = "hello"
        XCTAssertEqual(vm.runtimeStatus, .unavailable)
        XCTAssertFalse(vm.canSubmit)
    }

    func testSubmitTransitionsToCompleted() async throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.transcript = "meeting transcript"
        vm.submit()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.currentState, "completed")
        XCTAssertEqual(vm.output?.summary, "Discussed Wave 2 ports")
        XCTAssertNotNil(vm.sessionId)
    }

    func testResetReturnsToIdle() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.errorMessage = "boom"
        vm.reset()
        XCTAssertEqual(vm.currentState, "idle")
        XCTAssertNil(vm.errorMessage)
    }
}

final class LoopOutputParserTests: XCTestCase {
    func testParseProcessOutput() {
        let raw: [String: Any] = [
            "action_items": [
                ["task": "Ship clients", "owner": "Alex", "due": "Friday"],
            ],
            "decisions": [
                ["text": "Use embedded runtime", "made_by": "Team"],
            ],
            "follow_ups": ["Schedule review"],
            "summary": "Discussed Wave 2 ports",
        ]
        let output = LoopOutputParser.parse(raw)
        XCTAssertEqual(output?.summary, "Discussed Wave 2 ports")
        XCTAssertEqual(output?.actionItems.first?.task, "Ship clients")
        XCTAssertEqual(output?.decisions.first?.madeBy, "Team")
        XCTAssertEqual(output?.followUps, ["Schedule review"])
    }
}
