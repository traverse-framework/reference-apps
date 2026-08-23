namespace Loop.Tests;

using Xunit;

internal sealed class InMemorySettingsRepository : ISettingsRepository
{
    public string Workspace { get; set; } = AppConstants.DefaultWorkspace;
    public string BundlePath { get; set; } = string.Empty;
}

public class ExecutionViewModelTests
{
    private static LoopOutput SampleOutput { get; } = new(
        [new ActionItem("Prepare launch checklist", "Avery", "Friday")],
        [new Decision("Ship the beta on Friday", "Morgan")],
        ["Confirm support rotation"],
        "Team aligned on beta launch readiness.");

    [Fact]
    public void CanSubmitWhenReadyWithTranscript()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var vm = new ExecutionViewModel(host, new InMemorySettingsRepository())
        {
            Transcript = "meeting transcript",
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
            Transcript = "meeting transcript",
        };

        await vm.SubmitCommand.ExecuteAsync(null);

        Assert.Equal(ExecutionPhase.Succeeded, vm.Phase);
        Assert.Equal("Prepare launch checklist", vm.Output?.ActionItems[0].Task);
        Assert.Equal("Ship the beta on Friday", vm.Output?.Decisions[0].Text);
        Assert.Equal("Team aligned on beta launch readiness.", vm.Output?.Summary);
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
            Transcript = "hello",
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
        var output = new LoopOutput(
            [new ActionItem("Share notes", "Avery", null)],
            [new Decision("Use the lightweight rollout", "Morgan")],
            ["Schedule review"],
            "Rollout plan selected.");

        using var host = EmbeddedHost.CreateTestHost(output);
        var result = host.SubmitTranscript("any transcript");

        Assert.Null(result.Error);
        Assert.Equal("Share notes", result.Output?.ActionItems[0].Task);
        Assert.Contains(result.Events, e => e.EventType == "capability_result");
    }
}
