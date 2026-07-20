import Foundation
import XCTest
@testable import TraverseCore

final class EmbeddedHostTests: XCTestCase {
    private var sampleOutput: TraverseStarterOutput {
        TraverseStarterOutput(
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
    }

    func testTestHostReturnsScriptedCapabilityResult() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let result = try host.submitNote("any note")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.output?.process.title, "Title")
        XCTAssertTrue(result.events.contains { $0.event_type == "capability_result" })
    }

    func testPinnedDigestConstant() {
        XCTAssertTrue(EmbeddedHost.pinnedRuntimeWasmDigest.hasPrefix("sha256:"))
        XCTAssertEqual(EmbeddedHost.pinnedRuntimeWasmDigest.count, 71)
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    private var sampleOutput: TraverseStarterOutput {
        TraverseStarterOutput(
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
    }

    func testCanSubmitWhenReadyWithNote() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.note = "hello"
        XCTAssertEqual(vm.runtimeStatus, .ready)
        XCTAssertEqual(vm.runtimeMode, EmbeddedHost.runtimeModeEmbedded)
        XCTAssertTrue(vm.canSubmit)
    }

    func testUnavailableHostDisablesSubmit() {
        let vm = AppStateViewModel(host: nil, workspaceId: "local-default")
        vm.note = "hello"
        XCTAssertEqual(vm.runtimeStatus, .unavailable)
        XCTAssertFalse(vm.canSubmit)
    }

    func testSubmitTransitionsToCompleted() async throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.note = "note text"
        vm.submit()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.currentState, "completed")
        XCTAssertEqual(vm.output?.process.title, "Title")
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

final class TraverseOutputParserTests: XCTestCase {
    func testParsePipelineOutput() {
        let raw: [String: Any] = [
            "validate": ["valid": true, "issues": []],
            "process": [
                "title": "T",
                "tags": ["a"],
                "noteType": "n",
                "suggestedNextAction": "x",
                "status": "done",
            ],
            "summarize": ["summary": "Summary", "wordCount": 1],
        ]
        let output = TraverseOutputParser.parse(raw)
        XCTAssertEqual(output?.process.title, "T")
        XCTAssertEqual(output?.summarize.wordCount, 1)
    }
}
