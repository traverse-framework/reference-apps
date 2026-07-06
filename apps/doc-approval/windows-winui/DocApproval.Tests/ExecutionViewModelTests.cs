namespace DocApproval.Tests;

public sealed class MockTraverseClient : ITraverseClient
{
    public bool HealthOk { get; set; } = true;
    public string ExecutionId { get; set; } = "exec_test";
    public List<ExecutionPollResult> PollResults { get; init; } = [];
    public int PollIndex { get; set; }
    public IReadOnlyList<TraceEvent> Trace { get; init; } = Array.Empty<TraceEvent>();

    public Task<bool> CheckHealthAsync(string baseUrl, CancellationToken cancellationToken = default) =>
        Task.FromResult(HealthOk);

    public Task<string> ExecuteAsync(
        string baseUrl,
        string workspaceId,
        string capability,
        IReadOnlyDictionary<string, string> input,
        CancellationToken cancellationToken = default) =>
        Task.FromResult(ExecutionId);

    public Task<ExecutionPollResult> PollExecutionAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default)
    {
        var result = PollIndex < PollResults.Count
            ? PollResults[PollIndex]
            : PollResults[^1];
        PollIndex++;
        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<TraceEvent>> FetchTraceAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken = default) =>
        Task.FromResult(Trace);
}

internal sealed class InMemorySettingsRepository : ISettingsRepository
{
    public string BaseUrl { get; set; } = AppConstants.DefaultBaseUrl;
    public string Workspace { get; set; } = AppConstants.DefaultWorkspace;
}

public class ExecutionViewModelTests
{
    [Fact]
    public void CanSubmitWhenOnlineWithDocument()
    {
        var client = new MockTraverseClient { HealthOk = true };
        var settings = new InMemorySettingsRepository();
        var vm = new ExecutionViewModel(client, settings)
        {
            RuntimeStatus = RuntimeStatus.Online,
            Document = "contract text",
        };

        Assert.True(vm.CanSubmit);
    }

    [Fact]
    public async Task SubmitTransitionsToSucceeded()
    {
        var client = new MockTraverseClient
        {
            PollResults =
            [
                new ExecutionPollResult("exec_test", "running", null, null),
                new ExecutionPollResult(
                    "exec_test",
                    "succeeded",
                    new DocApprovalOutput("invoice", ["A", "B"], ["$100"], 0.9, "approve"),
                    null),
            ],
        };
        var settings = new InMemorySettingsRepository();
        var vm = new ExecutionViewModel(client, settings)
        {
            RuntimeStatus = RuntimeStatus.Online,
            Document = "contract text",
        };

        await vm.SubmitCommand.ExecuteAsync(null);
        await Task.Delay(1500);

        Assert.Equal(ExecutionPhase.Succeeded, vm.Phase);
        Assert.Equal("invoice", vm.Output?.DocType);
    }

    [Fact]
    public void ResetReturnsToIdle()
    {
        var vm = new ExecutionViewModel(new MockTraverseClient(), new InMemorySettingsRepository())
        {
            Phase = ExecutionPhase.Failed,
            Error = "boom",
        };

        vm.ResetCommand.Execute(null);
        Assert.Equal(ExecutionPhase.Idle, vm.Phase);
    }
}
