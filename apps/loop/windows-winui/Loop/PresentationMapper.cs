using System.Text.Json;

namespace Loop;

/// <summary>Canonical UI presentation states (Spec 001).</summary>
public enum PresentationState
{
    Idle,
    Loading,
    Loaded,
    Blocked,
    Ended,
    Error,
}

public static class PresentationStateExtensions
{
    public static string AsWire(this PresentationState state) => state switch
    {
        PresentationState.Idle => "idle",
        PresentationState.Loading => "loading",
        PresentationState.Loaded => "loaded",
        PresentationState.Blocked => "blocked",
        PresentationState.Ended => "ended",
        PresentationState.Error => "error",
        _ => "idle",
    };
}

public sealed record PresentationSnapshot(
    PresentationState State,
    string? ErrorMessage,
    JsonElement? Output);

public enum CapabilityPhase
{
    Invoked,
    Result,
}

public static class CapabilityPhaseExtensions
{
    public static string AsWire(this CapabilityPhase phase) => phase switch
    {
        CapabilityPhase.Invoked => "invoked",
        CapabilityPhase.Result => "result",
        _ => "invoked",
    };
}

public sealed record CapabilityProgressStep(
    string CapabilityId,
    CapabilityPhase Phase,
    ulong Sequence,
    string? Status,
    JsonElement? Output);

/// <summary>Minimal embedder event fields required by the mapper.</summary>
public sealed record EmbedderEventLike(
    string EventType,
    ulong Sequence,
    JsonElement Data);

/// <summary>
/// Spec 001/002 presentation + capability progress (language-equivalent of
/// <c>packages/event-ui-conformance</c>).
/// </summary>
public static class PresentationMapper
{
    private static readonly HashSet<string> BlockedStates = new(StringComparer.OrdinalIgnoreCase)
    {
        "blocked", "waiting", "waiting_for_human", "awaiting_human", "awaiting_input",
    };

    private static readonly HashSet<string> EndedStates = new(StringComparer.OrdinalIgnoreCase)
    {
        "cancelled", "canceled", "closed", "ended",
    };

    public static PresentationSnapshot MapPresentationState(IReadOnlyList<EmbedderEventLike> events)
    {
        if (events.Count == 0)
        {
            return new PresentationSnapshot(PresentationState.Idle, null, null);
        }

        var state = PresentationState.Idle;
        string? errorMessage = null;
        JsonElement? output = null;

        foreach (var eventItem in events)
        {
            switch (eventItem.EventType)
            {
                case "error":
                    state = PresentationState.Error;
                    errorMessage = ErrorMessageFromData(eventItem.Data) ?? "execution failed";
                    break;
                case "capability_invoked":
                    if (state != PresentationState.Error)
                    {
                        state = PresentationState.Loading;
                    }

                    break;
                case "state_changed":
                    if (state == PresentationState.Error)
                    {
                        break;
                    }

                    if (IsBlockedPayload(eventItem.Data))
                    {
                        state = PresentationState.Blocked;
                    }
                    else if (IsEndedStatePayload(eventItem.Data))
                    {
                        state = PresentationState.Ended;
                    }
                    else if (state is not (PresentationState.Loaded or PresentationState.Ended))
                    {
                        state = PresentationState.Loading;
                    }

                    break;
                case "capability_result":
                    if (state == PresentationState.Error)
                    {
                        break;
                    }

                    if (HasRenderableOutput(eventItem.Data))
                    {
                        state = PresentationState.Loaded;
                        output = GetProperty(eventItem.Data, "output");
                    }
                    else
                    {
                        state = PresentationState.Ended;
                        output = null;
                    }

                    break;
            }
        }

        return new PresentationSnapshot(state, errorMessage, output);
    }

    public static IReadOnlyList<CapabilityProgressStep> MapCapabilityProgress(
        IReadOnlyList<EmbedderEventLike> events)
    {
        var steps = new List<CapabilityProgressStep>();
        foreach (var eventItem in events)
        {
            var capabilityId = StringField(eventItem.Data, "capability_id");
            if (capabilityId is null)
            {
                continue;
            }

            switch (eventItem.EventType)
            {
                case "capability_invoked":
                    steps.Add(new CapabilityProgressStep(
                        capabilityId,
                        CapabilityPhase.Invoked,
                        eventItem.Sequence,
                        null,
                        null));
                    break;
                case "capability_result":
                    steps.Add(new CapabilityProgressStep(
                        capabilityId,
                        CapabilityPhase.Result,
                        eventItem.Sequence,
                        StringField(eventItem.Data, "status"),
                        GetProperty(eventItem.Data, "output")));
                    break;
            }
        }

        return steps;
    }

    public static string? ActiveCapabilityId(IReadOnlyList<EmbedderEventLike> events)
    {
        var progress = MapCapabilityProgress(events);
        var open = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var step in progress)
        {
            if (step.Phase == CapabilityPhase.Invoked)
            {
                open[step.CapabilityId] = open.GetValueOrDefault(step.CapabilityId) + 1;
            }
            else
            {
                var count = open.GetValueOrDefault(step.CapabilityId);
                if (count <= 1)
                {
                    open.Remove(step.CapabilityId);
                }
                else
                {
                    open[step.CapabilityId] = count - 1;
                }
            }
        }

        for (var i = progress.Count - 1; i >= 0; i--)
        {
            var step = progress[i];
            if (step.Phase == CapabilityPhase.Invoked && open.ContainsKey(step.CapabilityId))
            {
                return step.CapabilityId;
            }
        }

        return null;
    }

    private static string? ErrorMessageFromData(JsonElement data)
    {
        if (data.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        if (!data.TryGetProperty("error", out var err))
        {
            return null;
        }

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

        return null;
    }

    private static string? StringField(JsonElement data, string key)
    {
        if (data.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        return data.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;
    }

    private static JsonElement? GetProperty(JsonElement data, string key)
    {
        if (data.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        return data.TryGetProperty(key, out var value) ? value.Clone() : null;
    }

    private static string? RuntimeStateToken(JsonElement data) =>
        StringField(data, "state")
        ?? StringField(data, "status")
        ?? StringField(data, "runtime_state");

    private static bool IsBlockedPayload(JsonElement data)
    {
        if (data.ValueKind == JsonValueKind.Object)
        {
            if (data.TryGetProperty("blocked", out var blocked) &&
                blocked.ValueKind is JsonValueKind.True)
            {
                return true;
            }

            if (data.TryGetProperty("waiting_for_human", out var waiting) &&
                waiting.ValueKind is JsonValueKind.True)
            {
                return true;
            }
        }

        var token = RuntimeStateToken(data);
        return token is not null && BlockedStates.Contains(token);
    }

    private static bool IsEndedStatePayload(JsonElement data)
    {
        var token = RuntimeStateToken(data);
        return token is not null && EndedStates.Contains(token);
    }

    private static bool HasRenderableOutput(JsonElement data)
    {
        if (data.ValueKind != JsonValueKind.Object || !data.TryGetProperty("output", out var output))
        {
            return false;
        }

        if (output.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
        {
            return false;
        }

        if (output.ValueKind == JsonValueKind.Object && !output.EnumerateObject().Any())
        {
            return false;
        }

        return true;
    }
}
