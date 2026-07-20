import Foundation
import TraverseEmbedder

/// Result of a single document submission through the embedded runtime.
public struct HostRunResult: Sendable {
    public let sessionID: String
    public let output: DocApprovalOutput?
    public let events: [TraceEvent]
    public let error: String?

    public init(sessionID: String, output: DocApprovalOutput?, events: [TraceEvent], error: String?) {
        self.sessionID = sessionID
        self.output = output
        self.events = events
        self.error = error
    }
}

/// Embedding boundary — all workflow execution comes from the runtime.
/// Production: `RuntimeTraverseEmbedder`. Tests: `InMemoryTraverseEmbedder`.
public protocol EmbeddedRuntimeHostProtocol: Sendable {
    var workspaceID: String { get }
    var workflowID: String { get }
    var isReady: Bool { get }
    func submit(document: String) throws -> HostRunResult
    func shutdown()
}

public enum EmbeddedRuntime {
    public static let runtimeMode = "Embedded"
    public static let defaultWorkflowID = "doc-approval.pipeline"
    public static let defaultWorkspace = "local-default"
    public static let defaultAppID = "doc-approval"

    /// Digest of the certified `runtime/runtime.wasm` artifact
    /// (from `runtime/runtime-release.json` in TRAVERSE_REPO).
    public static let pinnedRuntimeWasmDigest =
        "sha256:aa801023ba4eb20b8c1b4004bdd964a78fed9540478b252b77eac04c80811852"

    /// Relative subpath inside the app bundle where the Traverse bundle lives.
    public static let bundleSubpath = "bundles/doc-approval"

    // MARK: - Factory

    /// Deterministic test host backed by `InMemoryTraverseEmbedder`.
    public static func makeTestHost(
        targetOutput: DocApprovalOutput,
        workspaceID: String = defaultWorkspace
    ) throws -> any EmbeddedRuntimeHostProtocol {
        let encoded = try JSONEncoder().encode(targetOutput)
        let harness = InMemoryTraverseEmbedder().withTargetOutput(encoded)
        try harness.initialize(bundle: TraverseBundle(
            rootURL: URL(fileURLWithPath: "/dev/null"),
            runtimeWasmDigest: "sha256:test-\(workspaceID)"
        ))
        return InMemoryEmbeddedHost(harness: harness, workspaceID: workspaceID)
    }

    /// Production host backed by `RuntimeTraverseEmbedder`.
    /// Returns `nil` if the bundle is missing or the WASM bridge fails to initialise.
    public static func tryMakeProductionHost(
        bundleURL: URL? = nil,
        workspaceID: String = defaultWorkspace,
        digest: String? = nil
    ) -> (any EmbeddedRuntimeHostProtocol)? {
        let root = bundleURL ?? resolveDefaultBundleURL()
        guard let root else { return nil }
        let pinned = digest ?? readPinnedDigest(from: root) ?? pinnedRuntimeWasmDigest
        return try? ProductionEmbeddedHost(bundleURL: root, workspaceID: workspaceID, digest: pinned)
    }

    // MARK: - Bundle resolution

    static func resolveDefaultBundleURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: "doc-approval",
            withExtension: nil,
            subdirectory: "bundles"
        ), FileManager.default.fileExists(
            atPath: url.appendingPathComponent("runtime/runtime.wasm").path
        ) {
            return url
        }
        return nil
    }

    static func readPinnedDigest(from bundleRoot: URL) -> String? {
        let releasePath = bundleRoot
            .appendingPathComponent("runtime")
            .appendingPathComponent("runtime-release.json")
        guard let data = try? Data(contentsOf: releasePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sha = json["sha256"] as? String, !sha.isEmpty else {
            return nil
        }
        return sha.hasPrefix("sha256:") ? sha : "sha256:" + sha
    }

    // MARK: - Production host

    private final class ProductionEmbeddedHost: EmbeddedRuntimeHostProtocol, @unchecked Sendable {
        private let runtime: RuntimeTraverseEmbedder
        let workspaceID: String
        let workflowID: String
        let isReady: Bool

        init(bundleURL: URL, workspaceID: String, digest: String) throws {
            self.workspaceID = workspaceID
            self.workflowID = EmbeddedRuntime.defaultWorkflowID
            let bundle = try TraverseBundle(rootURL: bundleURL, runtimeWasmDigest: digest)
            let rt = try RuntimeTraverseEmbedder(bundle: bundle)
            let configJSON = try JSONSerialization.data(withJSONObject: ["workspace_id": workspaceID])
            _ = try rt.initialize(configJSON: configJSON)
            self.runtime = rt
            self.isReady = true
        }

        func submit(document: String) throws -> HostRunResult {
            let inputJSON = try JSONSerialization.data(withJSONObject: ["document": document])
            let submission = try TraverseSubmission(targetID: workflowID, inputJSON: inputJSON)
            let accepted = try runtime.submit(submission)
            return drainEvents(sessionID: accepted.sessionID)
        }

        private func drainEvents(sessionID: String) -> HostRunResult {
            var events: [TraceEvent] = []
            var output: DocApprovalOutput?
            var error: String?

            let runtimeEvents = (try? runtime.subscribe()) ?? []
            for event in runtimeEvents {
                if let sid = event.sessionID, sid != sessionID { continue }
                let type = event.eventType ?? event.status
                let data = event.output.flatMap { d -> JSONValue? in
                    guard let json = try? JSONSerialization.jsonObject(with: d) else { return nil }
                    return jsonToJSONValue(json)
                }
                events.append(TraceEvent(event_type: type, timestamp: String(event.sequence), data: data))
                if type == "error" {
                    error = event.errorData
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "execution failed"
                    break
                }
                if type == "capability_result", let outputData = event.output {
                    output = DocApprovalOutputParser.parse(
                        try? JSONSerialization.jsonObject(with: outputData)
                    )
                    break
                }
            }

            if let error {
                return HostRunResult(sessionID: sessionID, output: nil, events: events, error: error)
            }
            return HostRunResult(
                sessionID: sessionID,
                output: output ?? DocApprovalOutput.empty,
                events: events,
                error: output == nil && events.isEmpty ? "embedder emitted no capability_result" : nil
            )
        }

        func shutdown() { _ = try? runtime.shutdown() }
    }

    // MARK: - InMemory host (tests)

    final class InMemoryEmbeddedHost: EmbeddedRuntimeHostProtocol, @unchecked Sendable {
        private let harness: InMemoryTraverseEmbedder
        let workspaceID: String
        let workflowID: String
        let isReady: Bool

        init(harness: InMemoryTraverseEmbedder, workspaceID: String) {
            self.harness = harness
            self.workspaceID = workspaceID
            self.workflowID = EmbeddedRuntime.defaultWorkflowID
            self.isReady = true
        }

        func submit(document: String) throws -> HostRunResult {
            let inputJSON = try JSONSerialization.data(withJSONObject: ["document": document])
            let submission = try TraverseSubmission(targetID: workflowID, inputJSON: inputJSON)
            let accepted = try harness.submit(submission)
            let runtimeEvents = try harness.subscribe(after: 0)
            return buildResult(sessionID: accepted.sessionID, events: runtimeEvents)
        }

        private func buildResult(sessionID: String, events: [TraverseRuntimeEvent]) -> HostRunResult {
            var traceEvents: [TraceEvent] = []
            var output: DocApprovalOutput?
            var error: String?

            for event in events {
                if let sid = event.sessionID, sid != sessionID { continue }
                let type = event.eventType ?? event.status
                let data = event.output.flatMap { d -> JSONValue? in
                    guard let json = try? JSONSerialization.jsonObject(with: d) else { return nil }
                    return jsonToJSONValue(json)
                }
                traceEvents.append(TraceEvent(event_type: type, timestamp: String(event.sequence), data: data))
                if type == "error" {
                    error = event.errorData.flatMap { String(data: $0, encoding: .utf8) } ?? "execution failed"
                    break
                }
                if type == "capability_result", let outputData = event.output {
                    output = DocApprovalOutputParser.parse(
                        try? JSONSerialization.jsonObject(with: outputData)
                    )
                    break
                }
            }

            if let error {
                return HostRunResult(sessionID: sessionID, output: nil, events: traceEvents, error: error)
            }
            return HostRunResult(
                sessionID: sessionID,
                output: output ?? DocApprovalOutput.empty,
                events: traceEvents,
                error: output == nil ? "embedder emitted no capability_result" : nil
            )
        }

        func shutdown() { harness.shutdown() }
    }
}

// MARK: - Helpers

private func jsonToJSONValue(_ raw: Any) -> JSONValue {
    switch raw {
    case let string as String: return .string(string)
    case let number as Double: return .number(number)
    case let bool as Bool: return .bool(bool)
    case let dict as [String: Any]:
        return .object(dict.mapValues { jsonToJSONValue($0) })
    case let array as [Any]:
        return .array(array.map { jsonToJSONValue($0) })
    default: return .null
    }
}
