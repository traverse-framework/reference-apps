import Foundation
import XCTest
@testable import TraverseCore

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
}

final class EmbeddedRuntimeTests: XCTestCase {
    private static let sampleOutput = TraverseStarterOutput(
        validate: ValidateOutput(valid: true, issues: []),
        process: ProcessOutput(
            title: "Title",
            tags: ["tag"],
            noteType: "meeting",
            suggestedNextAction: "follow up",
            status: "processed"
        ),
        summarize: SummarizeOutput(summary: "A short summary", wordCount: 3)
    )

    func testTestHostReturnsScriptedCapabilityResult() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let result = try host.submit(note: "any note")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.output?.process.title, "Title")
        XCTAssertEqual(result.output?.summarize.wordCount, 3)
        XCTAssertTrue(result.events.contains { $0.event_type == "capability_result" })
    }

    func testTestHostIsReady() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        XCTAssertTrue(host.isReady)
        XCTAssertEqual(host.workspaceID, EmbeddedRuntime.defaultWorkspace)
        XCTAssertEqual(host.workflowID, EmbeddedRuntime.defaultWorkflowID)
    }

    func testPinnedDigestFormat() {
        XCTAssertTrue(EmbeddedRuntime.pinnedRuntimeWasmDigest.hasPrefix("sha256:"))
        XCTAssertEqual(EmbeddedRuntime.pinnedRuntimeWasmDigest.count, 71)
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    private static let sampleOutput = TraverseStarterOutput(
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

    func testReadyStatusWhenHostIsReady() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let vm = AppStateViewModel(host: host)
        XCTAssertEqual(vm.runtimeStatus, .ready)
    }

    func testUnavailableStatusWhenHostIsNil() {
        let vm = AppStateViewModel(host: nil)
        XCTAssertEqual(vm.runtimeStatus, .unavailable)
    }

    func testCanSubmitWhenReadyWithNote() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let vm = AppStateViewModel(host: host)
        vm.note = "hello"
        XCTAssertTrue(vm.canSubmit)
    }

    func testCannotSubmitWhenUnavailable() {
        let vm = AppStateViewModel(host: nil)
        vm.note = "hello"
        XCTAssertFalse(vm.canSubmit)
    }

    func testApplyResultSetsResults() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let vm = AppStateViewModel(host: host)
        let result = HostRunResult(
            sessionID: "sess-1",
            output: Self.sampleOutput,
            events: [],
            error: nil
        )
        vm.apply(result: result)
        XCTAssertEqual(vm.currentState, "results")
        XCTAssertEqual(vm.output?.process.title, "T")
        XCTAssertEqual(vm.sessionId, "sess-1")
        XCTAssertNil(vm.errorMessage)
    }

    func testApplyResultWithErrorSetsErrorState() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let vm = AppStateViewModel(host: host)
        let result = HostRunResult(sessionID: "sess-e", output: nil, events: [], error: "boom")
        vm.apply(result: result)
        XCTAssertEqual(vm.currentState, "error")
        XCTAssertEqual(vm.errorMessage, "boom")
    }

    func testResetLocalRestoresIdle() throws {
        let host = try EmbeddedRuntime.makeTestHost(targetOutput: Self.sampleOutput)
        let vm = AppStateViewModel(host: host)
        vm.apply(result: HostRunResult(
            sessionID: "s", output: Self.sampleOutput, events: [], error: nil
        ))
        vm.resetLocal()
        XCTAssertEqual(vm.currentState, "idle")
        XCTAssertNil(vm.output)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.sessionId)
    }
}
