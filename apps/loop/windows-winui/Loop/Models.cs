using System.Text.Json;
using System.Text.Json.Serialization;

namespace Loop;

public sealed record ActionItem(
    [property: JsonPropertyName("task")] string Task,
    [property: JsonPropertyName("owner")] string? Owner,
    [property: JsonPropertyName("due")] string? Due);

public sealed record Decision(
    [property: JsonPropertyName("text")] string Text,
    [property: JsonPropertyName("made_by")] string? MadeBy);

public sealed record LoopOutput(
    [property: JsonPropertyName("action_items")] IReadOnlyList<ActionItem> ActionItems,
    [property: JsonPropertyName("decisions")] IReadOnlyList<Decision> Decisions,
    [property: JsonPropertyName("follow_ups")] IReadOnlyList<string> FollowUps,
    [property: JsonPropertyName("summary")] string Summary)
{
    public static LoopOutput Empty { get; } = new(
        Array.Empty<ActionItem>(),
        Array.Empty<Decision>(),
        Array.Empty<string>(),
        string.Empty);
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
    public string Transcript { get; init; } = string.Empty;
    public RuntimeStatus RuntimeStatus { get; init; } = RuntimeStatus.Starting;
    public string Workspace { get; init; } = AppConstants.DefaultWorkspace;
    public string WorkflowId { get; init; } = AppConstants.CapabilityId;
    public string RuntimeMode { get; init; } = EmbeddedHost.RuntimeModeEmbedded;
    public bool ShowTrace { get; init; }
    public string? SessionId { get; init; }
    public LoopOutput? Output { get; init; }
    public IReadOnlyList<TraceEvent> Trace { get; init; } = Array.Empty<TraceEvent>();
    public string? Error { get; init; }

    public bool IsRunning => Phase is ExecutionPhase.Loading;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Ready &&
        !string.IsNullOrWhiteSpace(Transcript) &&
        !IsRunning;
}
