import Foundation
import XCTest
@testable import DocApprovalCore

final class EmbeddedHostTests: XCTestCase {
    private var sampleOutput: DocApprovalOutput {
        DocApprovalOutput(
            analysis: AnalysisOutput(
                docType: "nda",
                parties: ["A", "B"],
                amounts: ["$1"],
                confidence: "0.9",
                recommendation: "approve"
            ),
            recommendation: RecommendationOutput(
                recommendation: "approve",
                rationale: "Policy match",
                confidence: "high"
            )
        )
    }

    func testTestHostReturnsScriptedCapabilityResult() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let result = try host.submitDocument("any document")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.output?.analysis.docType, "nda")
        XCTAssertTrue(result.events.contains { $0.event_type == "capability_result" })
    }

    func testPinnedDigestConstant() {
        XCTAssertTrue(EmbeddedHost.pinnedRuntimeWasmDigest.hasPrefix("sha256:"))
        XCTAssertEqual(EmbeddedHost.pinnedRuntimeWasmDigest.count, 71)
    }
}

@MainActor
final class AppStateViewModelTests: XCTestCase {
    private var sampleOutput: DocApprovalOutput {
        DocApprovalOutput(
            analysis: AnalysisOutput(
                docType: "nda",
                parties: ["A", "B"],
                amounts: ["$1"],
                confidence: "0.9",
                recommendation: "approve"
            ),
            recommendation: RecommendationOutput(
                recommendation: "approve",
                rationale: "Policy match",
                confidence: "high"
            )
        )
    }

    func testCanSubmitWhenReadyWithDocument() throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.document = "hello"
        XCTAssertEqual(vm.runtimeStatus, .ready)
        XCTAssertEqual(vm.runtimeMode, EmbeddedHost.runtimeModeEmbedded)
        XCTAssertTrue(vm.canSubmit)
    }

    func testUnavailableHostDisablesSubmit() {
        let vm = AppStateViewModel(host: nil, workspaceId: "local-default")
        vm.document = "hello"
        XCTAssertEqual(vm.runtimeStatus, .unavailable)
        XCTAssertFalse(vm.canSubmit)
    }

    func testSubmitTransitionsToCompleted() async throws {
        let host = try EmbeddedHost.createTestHost(output: sampleOutput)
        let vm = AppStateViewModel(host: host, workspaceId: "local-default")
        vm.document = "document text"
        vm.submit()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.currentState, "completed")
        XCTAssertEqual(vm.output?.analysis.docType, "nda")
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

final class DocApprovalOutputParserTests: XCTestCase {
    func testParsePipelineOutput() {
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
}
