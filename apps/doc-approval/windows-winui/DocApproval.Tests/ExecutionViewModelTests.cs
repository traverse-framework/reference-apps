namespace DocApproval.Tests;

internal sealed class InMemorySettingsRepository : ISettingsRepository
{
    public string Workspace { get; set; } = AppConstants.DefaultWorkspace;
    public string BundlePath { get; set; } = string.Empty;
}

public class ExecutionViewModelTests
{
    private static DocApprovalOutput SampleOutput { get; } = new(
        new AnalysisOutput("nda", ["Acme", "Beta"], ["$10"], "0.9", "review"),
        new RecommendationOutput("approve", "Looks fine", "0.8"));

    [Fact]
    public void CanSubmitWhenReadyWithDocument()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var vm = new ExecutionViewModel(host, new InMemorySettingsRepository())
        {
            Document = "contract text",
        };

        Assert.Equal(RuntimeStatus.Ready, vm.RuntimeStatus);
        Assert.Equal(EmbeddedHost.RuntimeModeEmbedded, vm.RuntimeMode);
        Assert.True(vm.CanSubmit);
    }

    [Fact]
    public async Task SubmitTransitionsToSucceededWithScriptedOutput()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var vm = new ExecutionViewModel(host, new InMemorySettingsRepository())
        {
            Document = "contract text",
        };

        await vm.SubmitCommand.ExecuteAsync(null);

        Assert.Equal(ExecutionPhase.Succeeded, vm.Phase);
        Assert.Equal("nda", vm.Output?.Analysis.DocType);
        Assert.Equal("approve", vm.Output?.Recommendation.Recommendation);
        Assert.NotNull(vm.SessionId);
    }

    [Fact]
    public void ResetReturnsToIdle()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var vm = new ExecutionViewModel(host, new InMemorySettingsRepository())
        {
            Phase = ExecutionPhase.Failed,
            Error = "boom",
        };

        vm.ResetCommand.Execute(null);
        Assert.Equal(ExecutionPhase.Idle, vm.Phase);
        Assert.Null(vm.Error);
    }

    [Fact]
    public void UnavailableHostDisablesSubmit()
    {
        var vm = new ExecutionViewModel(null, new InMemorySettingsRepository())
        {
            Document = "hello",
        };

        Assert.Equal(RuntimeStatus.Unavailable, vm.RuntimeStatus);
        Assert.False(vm.CanSubmit);
    }
}

public class EmbeddedHostTests
{
    [Fact]
    public void TestHostReturnsScriptedCapabilityResult()
    {
        var output = new DocApprovalOutput(
            new AnalysisOutput("msa", ["A"], ["1"], "high", "review"),
            new RecommendationOutput("reject", "risk", "med"));

        using var host = EmbeddedHost.CreateTestHost(output);
        var result = host.SubmitDocument("any doc");

        Assert.Null(result.Error);
        Assert.Equal("msa", result.Output?.Analysis.DocType);
        Assert.Contains(result.Events, e => e.EventType == "capability_result");
    }
}
