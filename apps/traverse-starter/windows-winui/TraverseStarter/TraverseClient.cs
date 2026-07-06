using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TraverseStarter;

public interface ITraverseClient
{
    Task<bool> CheckHealthAsync(string baseUrl, CancellationToken cancellationToken = default);
    Task<string> ExecuteAsync(
        string baseUrl,
        string workspaceId,
        string capability,
        IReadOnlyDictionary<string, string> input,
        CancellationToken cancellationToken = default);
    Task<ExecutionPollResult> PollExecutionAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TraceEvent>> FetchTraceAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default);
}

public sealed class TraverseClientException : Exception
{
    public TraverseClientException(string message) : base(message)
    {
    }
}

public sealed class TraverseClient : ITraverseClient, IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly HttpClient _http;

    public TraverseClient(HttpClient? httpClient = null)
    {
        _http = httpClient ?? new HttpClient();
    }

    public async Task<bool> CheckHealthAsync(string baseUrl, CancellationToken cancellationToken = default)
    {
        var response = await _http.GetAsync(NormalizeBaseUrl(baseUrl) + "/healthz", cancellationToken);
        return response.IsSuccessStatusCode;
    }

    public async Task<string> ExecuteAsync(
        string baseUrl,
        string workspaceId,
        string capability,
        IReadOnlyDictionary<string, string> input,
        CancellationToken cancellationToken = default)
    {
        var url = $"{NormalizeBaseUrl(baseUrl)}/v1/workspaces/{workspaceId}/execute";
        var payload = new ExecuteRequest(capability, input);
        using var response = await _http.PostAsJsonAsync(url, payload, JsonOptions, cancellationToken);
        await EnsureSuccessAsync(response);
        var body = await response.Content.ReadFromJsonAsync<ExecuteResponse>(JsonOptions, cancellationToken);
        if (body?.ExecutionId is null)
        {
            throw new TraverseClientException("decode failed");
        }

        return body.ExecutionId;
    }

    public async Task<ExecutionPollResult> PollExecutionAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default)
    {
        var url = $"{NormalizeBaseUrl(baseUrl)}/v1/workspaces/{workspaceId}/executions/{executionId}";
        using var response = await _http.GetAsync(url, cancellationToken);
        await EnsureSuccessAsync(response);
        var body = await response.Content.ReadFromJsonAsync<ExecutionPollResponse>(JsonOptions, cancellationToken);
        if (body?.Status is null)
        {
            throw new TraverseClientException("decode failed");
        }

        return new ExecutionPollResult(
            executionId,
            body.Status,
            body.Output,
            body.Error);
    }

    public async Task<IReadOnlyList<TraceEvent>> FetchTraceAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default)
    {
        var url = $"{NormalizeBaseUrl(baseUrl)}/v1/workspaces/{workspaceId}/traces/{executionId}";
        using var response = await _http.GetAsync(url, cancellationToken);
        await EnsureSuccessAsync(response);
        var trace = await response.Content.ReadFromJsonAsync<List<TraceEvent>>(JsonOptions, cancellationToken);
        return trace ?? [];
    }

    public void Dispose() => _http.Dispose();

    private static string NormalizeBaseUrl(string baseUrl) => baseUrl.Trim().TrimEnd('/');

    private static async Task EnsureSuccessAsync(HttpResponseMessage response)
    {
        if (!response.IsSuccessStatusCode)
        {
            throw new TraverseClientException($"HTTP {(int)response.StatusCode}");
        }

        await Task.CompletedTask;
    }

    private sealed record ExecuteRequest(string Capability, IReadOnlyDictionary<string, string> Input);

    private sealed record ExecuteResponse(
        [property: JsonPropertyName("execution_id")] string ExecutionId);

    private sealed record ExecutionPollResponse(
        string Status,
        TraverseStarterOutput? Output,
        string? Error);
}
