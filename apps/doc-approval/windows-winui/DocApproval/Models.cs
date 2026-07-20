using System.Text.Json;
using System.Text.Json.Serialization;

namespace DocApproval;

public sealed record AnalysisOutput(
    [property: JsonPropertyName("docType")] string DocType,
    [property: JsonPropertyName("parties")] IReadOnlyList<string> Parties,
    [property: JsonPropertyName("amounts")] IReadOnlyList<string> Amounts,
    [property: JsonPropertyName("confidence")] string Confidence,
    [property: JsonPropertyName("recommendation")] string Recommendation);

public sealed record RecommendationOutput(
    [property: JsonPropertyName("recommendation")] string Recommendation,
    [property: JsonPropertyName("rationale")] string Rationale,
    [property: JsonPropertyName("confidence")] string Confidence);

/// <summary>Combined pipeline final output (analyze → recommend).</summary>
public sealed record DocApprovalOutput(
    [property: JsonPropertyName("analysis")] AnalysisOutput Analysis,
    [property: JsonPropertyName("recommendation")] RecommendationOutput Recommendation)
{
    public static DocApprovalOutput Empty { get; } = new(
        new AnalysisOutput(string.Empty, Array.Empty<string>(), Array.Empty<string>(), string.Empty, string.Empty),
        new RecommendationOutput(string.Empty, string.Empty, string.Empty));
}

public sealed record TraceEvent(
    [property: JsonPropertyName("event_type")] string EventType,
    string Timestamp,
    JsonElement? Data);

public enum ExecutionPhase
{
    Idle,
    Loading,
    Succeeded,
    Failed,
}

public enum RuntimeStatus
{
    Starting,
    Ready,
    Unavailable,
}

public sealed class ExecutionUiState
{
    public ExecutionPhase Phase { get; init; } = ExecutionPhase.Idle;
    public string Document { get; init; } = string.Empty;
    public RuntimeStatus RuntimeStatus { get; init; } = RuntimeStatus.Starting;
    public string Workspace { get; init; } = AppConstants.DefaultWorkspace;
    public string WorkflowId { get; init; } = AppConstants.CapabilityId;
    public string RuntimeMode { get; init; } = EmbeddedHost.RuntimeModeEmbedded;
    public bool ShowTrace { get; init; }
    public string? SessionId { get; init; }
    public DocApprovalOutput? Output { get; init; }
    public IReadOnlyList<TraceEvent> Trace { get; init; } = Array.Empty<TraceEvent>();
    public string? Error { get; init; }

    public bool IsRunning => Phase is ExecutionPhase.Loading;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Ready &&
        !string.IsNullOrWhiteSpace(Document) &&
        !IsRunning;
}
