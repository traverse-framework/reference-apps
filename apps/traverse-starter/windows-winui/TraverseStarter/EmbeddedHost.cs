using System.Text.Json;
using System.Text.Json.Nodes;
using Traverse.Embedder;

namespace TraverseStarter;

/// <summary>Successful or failed embedded workflow run.</summary>
public sealed record HostRunResult(
    string SessionId,
    TraverseStarterOutput? Output,
    IReadOnlyList<TraceEvent> Events,
    string? Error);

/// <summary>
/// Embedded Traverse host boundary for WinUI shells.
/// Production uses <see cref="RuntimeTraverseEmbedder"/>; tests use
/// <see cref="InMemoryTraverseEmbedder"/> — never fake business fields in UI.
/// </summary>
public interface IEmbeddedHost : IDisposable
{
    string WorkspaceId { get; }
    string WorkflowId { get; }
    bool IsReady { get; }
    HostRunResult SubmitNote(string note);
}

/// <summary>Factory helpers for production and test hosts.</summary>
public static class EmbeddedHost
{
    public const string RuntimeModeEmbedded = "Embedded";
    public const string DefaultWorkflowId = "traverse-starter.pipeline";
    public const string DefaultWorkspace = "local-default";
    public const string DefaultAppId = "traverse-starter";

    /// <summary>
    /// Digest of the certified Spec 071 <c>runtime/runtime.wasm</c> artifact
    /// (from Traverse <c>runtime/runtime-release.json</c>).
    /// </summary>
    public const string PinnedRuntimeWasmDigest =
        "sha256:aa801023ba4eb20b8c1b4004bdd964a78fed9540478b252b77eac04c80811852";

    public const string DefaultRelativeBundlePath =
        "Assets/bundles/traverse-starter";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    /// <summary>Production host backed by the digest-pinned runtime WASM bridge.</summary>
    public static IEmbeddedHost? TryCreateProduction(
        string? bundleRoot = null,
        string? workspaceId = null,
        string? digest = null)
    {
        try
        {
            var root = ResolveBundleRoot(bundleRoot);
            if (root is null)
            {
                return null;
            }

            var pinned = digest ?? ReadPinnedDigest(root) ?? PinnedRuntimeWasmDigest;
            var workspace = string.IsNullOrWhiteSpace(workspaceId)
                ? DefaultWorkspace
                : workspaceId.Trim();
            return new ProductionEmbeddedHost(root, pinned, workspace);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>Deterministic test double (spec 068 / #751).</summary>
    public static IEmbeddedHost CreateTestHost(
        TraverseStarterOutput output,
        string workspaceId = DefaultWorkspace)
    {
        var harness = new InMemoryTraverseEmbedder()
            .WithTargetOutput(JsonSerializer.Serialize(output, JsonOptions));
        harness.Initialize(new TraverseBundle("test-root", "sha256:test"));
        return new TestEmbeddedHost(harness, workspaceId, DefaultWorkflowId);
    }

    public static string? ResolveBundleRoot(string? overridePath = null)
    {
        if (!string.IsNullOrWhiteSpace(overridePath))
        {
            var candidate = Path.GetFullPath(overridePath);
            if (File.Exists(Path.Combine(candidate, "runtime", "runtime.wasm")))
            {
                return candidate;
            }
        }

        var baseDir = AppContext.BaseDirectory;
        var fromBase = Path.GetFullPath(Path.Combine(baseDir, DefaultRelativeBundlePath));
        if (File.Exists(Path.Combine(fromBase, "runtime", "runtime.wasm")))
        {
            return fromBase;
        }

        // Walk up for repo-relative Assets during local `dotnet run`.
        var dir = new DirectoryInfo(baseDir);
        while (dir is not null)
        {
            var nested = Path.Combine(dir.FullName, DefaultRelativeBundlePath);
            if (File.Exists(Path.Combine(nested, "runtime", "runtime.wasm")))
            {
                return Path.GetFullPath(nested);
            }

            dir = dir.Parent;
        }

        return null;
    }

    private static string? ReadPinnedDigest(string bundleRoot)
    {
        var releasePath = Path.Combine(bundleRoot, "runtime", "runtime-release.json");
        if (!File.Exists(releasePath))
        {
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(releasePath));
            if (doc.RootElement.TryGetProperty("sha256", out var sha) &&
                sha.ValueKind == JsonValueKind.String &&
                sha.GetString() is { Length: > 0 } hex)
            {
                return hex.StartsWith("sha256:", StringComparison.Ordinal)
                    ? hex
                    : "sha256:" + hex;
            }
        }
        catch
        {
            // fall through
        }

        return null;
    }

    private sealed class ProductionEmbeddedHost : IEmbeddedHost
    {
        private readonly WasmtimeRuntimeBridge _bridge;
        private readonly WasmtimeBridgeClient _client;
        private readonly RuntimeTraverseEmbedder _runtime;
        private bool _disposed;

        public ProductionEmbeddedHost(string bundleRoot, string digest, string workspaceId)
        {
            WorkspaceId = workspaceId;
            WorkflowId = DefaultWorkflowId;
            var bundle = new TraverseBundle(bundleRoot, digest);
            _bridge = new WasmtimeRuntimeBridge(bundle);
            _client = new WasmtimeBridgeClient(_bridge);
            _runtime = new RuntimeTraverseEmbedder(_client);
            var config = new JsonObject { ["workspace_id"] = workspaceId }.ToJsonString();
            _runtime.Initialize(config);
            IsReady = true;
        }

        public string WorkspaceId { get; }
        public string WorkflowId { get; }
        public bool IsReady { get; }

        public HostRunResult SubmitNote(string note)
        {
            var input = new JsonObject { ["note"] = note }.ToJsonString();
            var accepted = _runtime.Submit(new TraverseSubmission(WorkflowId, input));
            if (!string.Equals(accepted.Status, "accepted", StringComparison.OrdinalIgnoreCase))
            {
                return new HostRunResult(
                    accepted.SessionId,
                    null,
                    Array.Empty<TraceEvent>(),
                    $"submit {accepted.Status}");
            }

            return DrainEvents(accepted.SessionId);
        }

        private HostRunResult DrainEvents(string sessionId)
        {
            var events = new List<TraceEvent>();
            TraverseStarterOutput? output = null;
            string? error = null;

            while (_client.NextEvent() is { } bytes)
            {
                using var doc = JsonDocument.Parse(bytes);
                var root = doc.RootElement;
                var eventType = root.TryGetProperty("type", out var typeEl) &&
                    typeEl.ValueKind == JsonValueKind.String
                        ? typeEl.GetString() ?? "event"
                        : root.TryGetProperty("event_type", out var et) &&
                          et.ValueKind == JsonValueKind.String
                            ? et.GetString() ?? "event"
                            : "event";
                var eventSession = root.TryGetProperty("session_id", out var sid) &&
                    sid.ValueKind == JsonValueKind.String
                        ? sid.GetString()
                        : null;
                if (eventSession is not null &&
                    !string.Equals(eventSession, sessionId, StringComparison.Ordinal))
                {
                    continue;
                }

                JsonElement? data = root.TryGetProperty("data", out var dataEl)
                    ? dataEl.Clone()
                    : null;
                events.Add(new TraceEvent(eventType, events.Count.ToString(), data));

                if (eventType == "error")
                {
                    error = ExtractError(data) ?? "execution failed";
                    break;
                }

                if (eventType == "capability_result")
                {
                    output = ParseOutput(data);
                    break;
                }
            }

            if (error is not null)
            {
                return new HostRunResult(sessionId, null, events, error);
            }

            if (output is null && events.Count == 0)
            {
                return new HostRunResult(
                    sessionId,
                    null,
                    events,
                    "embedder emitted no capability_result");
            }

            return new HostRunResult(sessionId, output ?? TraverseStarterOutput.Empty, events, null);
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _disposed = true;
            try
            {
                _runtime.Shutdown();
            }
            catch
            {
                // best-effort
            }

            _bridge.Dispose();
        }
    }

    private sealed class TestEmbeddedHost : IEmbeddedHost
    {
        private readonly InMemoryTraverseEmbedder _harness;

        public TestEmbeddedHost(
            InMemoryTraverseEmbedder harness,
            string workspaceId,
            string workflowId)
        {
            _harness = harness;
            WorkspaceId = workspaceId;
            WorkflowId = workflowId;
            IsReady = true;
        }

        public string WorkspaceId { get; }
        public string WorkflowId { get; }
        public bool IsReady { get; }

        public HostRunResult SubmitNote(string note)
        {
            var input = new JsonObject { ["note"] = note }.ToJsonString();
            var accepted = _harness.Submit(new TraverseSubmission(WorkflowId, input));
            var runtimeEvents = _harness.Subscribe();
            var events = new List<TraceEvent>();
            TraverseStarterOutput? output = null;
            string? error = null;

            foreach (var evt in runtimeEvents)
            {
                if (evt.SessionId is not null &&
                    !string.Equals(evt.SessionId, accepted.SessionId, StringComparison.Ordinal))
                {
                    continue;
                }

                var eventType = evt.EventType ?? evt.Status;
                JsonElement? data = null;
                if (evt.Output is not null)
                {
                    using var parsed = JsonDocument.Parse(evt.Output);
                    data = parsed.RootElement.Clone();
                }

                events.Add(new TraceEvent(eventType, evt.Sequence.ToString(), data));

                if (string.Equals(eventType, "error", StringComparison.Ordinal))
                {
                    error = evt.ErrorData ?? "execution failed";
                    break;
                }

                if (string.Equals(eventType, "capability_result", StringComparison.Ordinal) &&
                    evt.Output is not null)
                {
                    output = JsonSerializer.Deserialize<TraverseStarterOutput>(evt.Output, JsonOptions)
                        ?? TraverseStarterOutput.Empty;
                    break;
                }
            }

            if (error is not null)
            {
                return new HostRunResult(accepted.SessionId, null, events, error);
            }

            return new HostRunResult(
                accepted.SessionId,
                output ?? TraverseStarterOutput.Empty,
                events,
                output is null ? "embedder emitted no capability_result" : null);
        }

        public void Dispose() => _harness.Shutdown();
    }

    private static TraverseStarterOutput ParseOutput(JsonElement? data)
    {
        if (data is null)
        {
            return TraverseStarterOutput.Empty;
        }

        var element = data.Value;
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty("output", out var nested))
        {
            element = nested;
        }

        if (element.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
        {
            return TraverseStarterOutput.Empty;
        }

        return JsonSerializer.Deserialize<TraverseStarterOutput>(element.GetRawText(), JsonOptions)
            ?? TraverseStarterOutput.Empty;
    }

    private static string? ExtractError(JsonElement? data)
    {
        if (data is null || data.Value.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        if (data.Value.TryGetProperty("error", out var err))
        {
            if (err.ValueKind == JsonValueKind.String)
            {
                return err.GetString();
            }

            if (err.ValueKind == JsonValueKind.Object &&
                err.TryGetProperty("message", out var message) &&
                message.ValueKind == JsonValueKind.String)
            {
                return message.GetString();
            }
        }

        return null;
    }
}
