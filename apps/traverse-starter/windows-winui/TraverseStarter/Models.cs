using System.Text.Json;
using System.Text.Json.Serialization;

namespace TraverseStarter;

public sealed record ValidateOutput(
    [property: JsonPropertyName("valid")] bool Valid,
    [property: JsonPropertyName("issues")] IReadOnlyList<string> Issues);

public sealed record ProcessOutput(
    [property: JsonPropertyName("title")] string Title,
    [property: JsonPropertyName("tags")] IReadOnlyList<string> Tags,
    [property: JsonPropertyName("noteType")] string NoteType,
    [property: JsonPropertyName("suggestedNextAction")] string SuggestedNextAction,
    [property: JsonPropertyName("status")] string Status);

public sealed record SummarizeOutput(
    [property: JsonPropertyName("summary")] string Summary,
    [property: JsonPropertyName("wordCount")] int WordCount);

/// <summary>Combined pipeline final output (validate → process → summarize).</summary>
public sealed record TraverseStarterOutput(
    [property: JsonPropertyName("validate")] ValidateOutput Validate,
    [property: JsonPropertyName("process")] ProcessOutput Process,
    [property: JsonPropertyName("summarize")] SummarizeOutput Summarize)
{
    public static TraverseStarterOutput Empty { get; } = new(
        new ValidateOutput(false, Array.Empty<string>()),
        new ProcessOutput(string.Empty, Array.Empty<string>(), string.Empty, string.Empty, string.Empty),
        new SummarizeOutput(string.Empty, 0));
}

public sealed record TraceEvent(
    [property: JsonPropertyName("event_type")] string EventType,
    string Timestamp,
    JsonElement? Data);

public sealed record ExecutionPollResult(
    string ExecutionId,
    string Status,
    TraverseStarterOutput? Output,
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
    public string Note { get; init; } = string.Empty;
    public RuntimeStatus RuntimeStatus { get; init; } = RuntimeStatus.Checking;
    public string BaseUrl { get; init; } = AppConstants.DefaultBaseUrl;
    public string Workspace { get; init; } = AppConstants.DefaultWorkspace;
    public bool ShowTrace { get; init; }
    public string? PollingExecutionId { get; init; }
    public TraverseStarterOutput? Output { get; init; }
    public IReadOnlyList<TraceEvent> Trace { get; init; } = Array.Empty<TraceEvent>();
    public string? Error { get; init; }

    public bool IsRunning => Phase is ExecutionPhase.Loading or ExecutionPhase.Polling;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Online &&
        !string.IsNullOrWhiteSpace(Note) &&
        !IsRunning;
}
