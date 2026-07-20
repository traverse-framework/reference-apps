import Foundation
import TraverseEmbedder

/// Successful or failed embedded workflow run.
public struct HostRunResult: Equatable, Sendable {
    public let sessionId: String
    public let output: DocApprovalOutput?
    public let events: [TraceEvent]
    public let error: String?

    public init(
        sessionId: String,
        output: DocApprovalOutput?,
        events: [TraceEvent],
        error: String?
    ) {
        self.sessionId = sessionId
        self.output = output
        self.events = events
        self.error = error
    }
}

/// Embedded Traverse host boundary for SwiftUI shells.
public protocol EmbeddedHostProtocol: AnyObject, Sendable {
    var workspaceId: String { get }
    var workflowId: String { get }
    var isReady: Bool { get }
    func submitDocument(_ document: String) throws -> HostRunResult
}

/// Factory helpers for production and test hosts.
public enum EmbeddedHost {
    public static let runtimeModeEmbedded = "Embedded"
    public static let defaultWorkflowId = "doc-approval.pipeline"
    public static let defaultWorkspace = "local-default"
    public static let defaultAppId = "doc-approval"
    public static let pinnedRuntimeWasmDigest =
        "sha256:aa801023ba4eb20b8c1b4004bdd964a78fed9540478b252b77eac04c80811852"
    public static let defaultRelativeBundlePath = "bundles/doc-approval"

    /// Production host backed by the digest-pinned runtime WASM bridge.
    public static func tryCreateProduction(
        bundleRoot: URL? = nil,
        workspaceId: String? = nil,
        digest: String? = nil
    ) -> EmbeddedHostProtocol? {
        do {
            guard let root = resolveBundleRoot(override: bundleRoot) else { return nil }
            let pinned = digest ?? readPinnedDigest(bundleRoot: root) ?? pinnedRuntimeWasmDigest
            let workspace = (workspaceId?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
                $0.isEmpty ? nil : $0
            } ?? defaultWorkspace
            return try ProductionEmbeddedHost(bundleRoot: root, digest: pinned, workspaceId: workspace)
        } catch {
            return nil
        }
    }

    /// Deterministic test double (spec 068 / #751).
    public static func createTestHost(
        output: DocApprovalOutput,
        workspaceId: String = defaultWorkspace
    ) throws -> EmbeddedHostProtocol {
        let encoder = JSONEncoder()
        let data = try encoder.encode(output)
        let harness = InMemoryTraverseEmbedder().withTargetOutput(data)
        let bundle = try TraverseBundle(rootURL: URL(fileURLWithPath: "test-root"), runtimeWasmDigest: "sha256:test")
        try harness.initialize(bundle: bundle)
        return TestEmbeddedHost(harness: harness, workspaceId: workspaceId, workflowId: defaultWorkflowId)
    }

    public static func resolveBundleRoot(override: URL? = nil) -> URL? {
        if let override {
            let runtime = override.appendingPathComponent("runtime").appendingPathComponent("runtime.wasm")
            if FileManager.default.fileExists(atPath: runtime.path) {
                return override
            }
        }

        let candidates: [URL] = [
            Bundle.main.resourceURL?
                .appendingPathComponent(defaultRelativeBundlePath),
            Bundle.main.bundleURL
                .appendingPathComponent("Contents/Resources")
                .appendingPathComponent(defaultRelativeBundlePath),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(defaultRelativeBundlePath),
        ].compactMap { $0 }

        for candidate in candidates {
            let runtime = candidate.appendingPathComponent("runtime").appendingPathComponent("runtime.wasm")
            if FileManager.default.fileExists(atPath: runtime.path) {
                return candidate
            }
        }
        return nil
    }

    private static func readPinnedDigest(bundleRoot: URL) -> String? {
        let release = bundleRoot.appendingPathComponent("runtime").appendingPathComponent("runtime-release.json")
        guard let data = try? Data(contentsOf: release),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hex = json["sha256"] as? String,
              !hex.isEmpty else {
            return nil
        }
        return hex.hasPrefix("sha256:") ? hex : "sha256:\(hex)"
    }
}

private final class ProductionEmbeddedHost: EmbeddedHostProtocol, @unchecked Sendable {
    let workspaceId: String
    let workflowId: String
    let isReady: Bool
    private let client: WasmiHostBridgeClient
    private let runtime: RuntimeTraverseEmbedder

    init(bundleRoot: URL, digest: String, workspaceId: String) throws {
        self.workspaceId = workspaceId
        self.workflowId = EmbeddedHost.defaultWorkflowId
        let bundle = try TraverseBundle(rootURL: bundleRoot, runtimeWasmDigest: digest)
        self.client = try WasmiHostBridgeClient(bundle: bundle)
        self.runtime = RuntimeTraverseEmbedder(client: client)
        let config = try JSONSerialization.data(withJSONObject: ["workspace_id": workspaceId])
        _ = try runtime.initialize(configJSON: config)
        self.isReady = true
    }

    func submitDocument(_ document: String) throws -> HostRunResult {
        let input = try JSONSerialization.data(withJSONObject: ["document": document])
        let submission = try TraverseSubmission(targetID: workflowId, inputJSON: input)
        let accepted = try runtime.submit(submission)
        guard accepted.status.lowercased() == "accepted" else {
            return HostRunResult(
                sessionId: accepted.sessionID,
                output: nil,
                events: [],
                error: "submit \(accepted.status)"
            )
        }
        return try drainEvents(sessionId: accepted.sessionID)
    }

    private func drainEvents(sessionId: String) throws -> HostRunResult {
        var events: [TraceEvent] = []
        var output: DocApprovalOutput?
        var error: String?

        while let bytes = try client.nextEvent() {
            guard let root = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
                continue
            }
            let eventType = (root["type"] as? String)
                ?? (root["event_type"] as? String)
                ?? "event"
            if let eventSession = root["session_id"] as? String,
               eventSession != sessionId {
                continue
            }
            let data = root["data"].map { JSONValue.fromAny($0) } ?? nil
            events.append(TraceEvent(event_type: eventType, timestamp: "\(events.count)", data: data))

            if eventType == "error" {
                error = extractError(root["data"]) ?? "execution failed"
                break
            }
            if eventType == "capability_result" {
                output = parseOutput(root["data"])
                break
            }
        }

        if let error {
            return HostRunResult(sessionId: sessionId, output: nil, events: events, error: error)
        }
        if output == nil, events.isEmpty {
            return HostRunResult(
                sessionId: sessionId,
                output: nil,
                events: events,
                error: "embedder emitted no capability_result"
            )
        }
        return HostRunResult(
            sessionId: sessionId,
            output: output ?? .empty,
            events: events,
            error: nil
        )
    }

    deinit {
        _ = try? runtime.shutdown()
    }
}

private final class TestEmbeddedHost: EmbeddedHostProtocol, @unchecked Sendable {
    let workspaceId: String
    let workflowId: String
    let isReady: Bool = true
    private let harness: InMemoryTraverseEmbedder

    init(harness: InMemoryTraverseEmbedder, workspaceId: String, workflowId: String) {
        self.harness = harness
        self.workspaceId = workspaceId
        self.workflowId = workflowId
    }

    func submitDocument(_ document: String) throws -> HostRunResult {
        let input = try JSONSerialization.data(withJSONObject: ["document": document])
        let submission = try TraverseSubmission(targetID: workflowId, inputJSON: input)
        let accepted = try harness.submit(submission)
        let runtimeEvents = try harness.subscribe()
        var events: [TraceEvent] = []
        var output: DocApprovalOutput?
        var error: String?

        for evt in runtimeEvents {
            if let sid = evt.sessionID, sid != accepted.sessionID { continue }
            let eventType = evt.eventType ?? evt.status
            var data: JSONValue?
            if let out = evt.output,
               let obj = try? JSONSerialization.jsonObject(with: out) {
                data = JSONValue.fromAny(obj)
            }
            events.append(TraceEvent(event_type: eventType, timestamp: "\(evt.sequence)", data: data))
            if eventType == "error" {
                error = evt.errorData.flatMap { String(data: $0, encoding: .utf8) } ?? "execution failed"
                break
            }
            if eventType == "capability_result", let out = evt.output {
                output = (try? JSONDecoder().decode(DocApprovalOutput.self, from: out)) ?? .empty
                break
            }
        }

        if let error {
            return HostRunResult(sessionId: accepted.sessionID, output: nil, events: events, error: error)
        }
        return HostRunResult(
            sessionId: accepted.sessionID,
            output: output ?? .empty,
            events: events,
            error: output == nil ? "embedder emitted no capability_result" : nil
        )
    }

    deinit {
        harness.shutdown()
    }
}

private func parseOutput(_ raw: Any?) -> DocApprovalOutput {
    guard let raw else { return .empty }
    var value = raw
    if let dict = raw as? [String: Any], let nested = dict["output"] {
        value = nested
    }
    if let dict = value as? [String: Any],
       let parsed = DocApprovalOutputParser.parse(dict) {
        return parsed
    }
    if let data = try? JSONSerialization.data(withJSONObject: value),
       let decoded = try? JSONDecoder().decode(DocApprovalOutput.self, from: data) {
        return decoded
    }
    return .empty
}

private func extractError(_ raw: Any?) -> String? {
    guard let dict = raw as? [String: Any] else { return nil }
    if let err = dict["error"] as? String { return err }
    if let err = dict["error"] as? [String: Any], let message = err["message"] as? String {
        return message
    }
    return nil
}

private extension JSONValue {
    static func fromAny(_ value: Any) -> JSONValue {
        switch value {
        case let s as String: return .string(s)
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return .bool(n.boolValue)
            }
            return .number(n.doubleValue)
        case let dict as [String: Any]:
            return .object(dict.mapValues { fromAny($0) })
        case let arr as [Any]:
            return .array(arr.map { fromAny($0) })
        case is NSNull:
            return .null
        default:
            return .null
        }
    }
}
