using System.Text.Json;
using System.Text.Json.Serialization;

namespace DocApproval;

public sealed record DocApprovalOutput(
    [property: JsonPropertyName("docType")] string DocType,
    [property: JsonPropertyName("parties")] IReadOnlyList<string> Parties,
    [property: JsonPropertyName("amounts")] IReadOnlyList<string> Amounts,
    [property: JsonPropertyName("confidence")] double Confidence,
    [property: JsonPropertyName("recommendation")] string Recommendation);

public sealed record TraceEvent(
    [property: JsonPropertyName("event_type")] string EventType,
    string Timestamp,
    JsonElement? Data);

public sealed record ExecutionPollResult(
    string ExecutionId,
    string Status,
    DocApprovalOutput? Output,
    string? Error);

public enum ExecutionPhase
{
    Idle,
    Loading,
    Polling,
    Succeeded,
    Failed,
}

public enum RuntimeStatus
{
    Checking,
    Online,
    Offline,
}

public sealed class ExecutionUiState
{
    public ExecutionPhase Phase { get; init; } = ExecutionPhase.Idle;
    public string Document { get; init; } = string.Empty;
    public RuntimeStatus RuntimeStatus { get; init; } = RuntimeStatus.Checking;
    public string BaseUrl { get; init; } = AppConstants.DefaultBaseUrl;
    public string Workspace { get; init; } = AppConstants.DefaultWorkspace;
    public bool ShowTrace { get; init; }
    public string? PollingExecutionId { get; init; }
    public DocApprovalOutput? Output { get; init; }
    public IReadOnlyList<TraceEvent> Trace { get; init; } = Array.Empty<TraceEvent>();
    public string? Error { get; init; }

    public bool IsRunning => Phase is ExecutionPhase.Loading or ExecutionPhase.Polling;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Online &&
        !string.IsNullOrWhiteSpace(Document) &&
        !IsRunning;
}
