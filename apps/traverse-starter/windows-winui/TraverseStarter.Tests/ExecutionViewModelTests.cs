namespace TraverseStarter.Tests;

using Xunit;

internal sealed class InMemorySettingsRepository : ISettingsRepository
{
    public string Workspace { get; set; } = AppConstants.DefaultWorkspace;
    public string BundlePath { get; set; } = string.Empty;
}

public class ExecutionViewModelTests
{
    private static TraverseStarterOutput SampleOutput { get; } = new(
        new ValidateOutput(true, Array.Empty<string>()),
        new ProcessOutput("Title", ["tag"], "meeting", "follow up", "processed"),
        new SummarizeOutput("A short summary", 3));

    [Fact]
    public void CanSubmitWhenReadyWithNote()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var settings = new InMemorySettingsRepository();
        var vm = new ExecutionViewModel(host, settings)
        {
            Note = "hello",
        };

        Assert.Equal(RuntimeStatus.Ready, vm.RuntimeStatus);
        Assert.Equal(EmbeddedHost.RuntimeModeEmbedded, vm.RuntimeMode);
        Assert.True(vm.CanSubmit);
    }

    [Fact]
    public async Task SubmitTransitionsToSucceededWithScriptedOutput()
    {
        using var host = EmbeddedHost.CreateTestHost(SampleOutput);
        var settings = new InMemorySettingsRepository();
        var vm = new ExecutionViewModel(host, settings)
        {
            Note = "note text",
        };

        await vm.SubmitCommand.ExecuteAsync(null);

        Assert.Equal(ExecutionPhase.Succeeded, vm.Phase);
        Assert.Equal("Title", vm.Output?.Process.Title);
        Assert.True(vm.Output?.Validate.Valid);
        Assert.Equal(3, vm.Output?.Summarize.WordCount);
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
            Note = "hello",
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
        var output = new TraverseStarterOutput(
            new ValidateOutput(true, ["ok"]),
            new ProcessOutput("FromRuntime", ["a", "b"], "type", "next", "done"),
            new SummarizeOutput("sum", 1));

        using var host = EmbeddedHost.CreateTestHost(output);
        var result = host.SubmitNote("any note");

        Assert.Null(result.Error);
        Assert.Equal("FromRuntime", result.Output?.Process.Title);
        Assert.Contains(result.Events, e => e.EventType == "capability_result");
    }

    [Fact]
    public void PinnedDigestMatchesReleaseMetadataConstant()
    {
        Assert.StartsWith("sha256:", EmbeddedHost.PinnedRuntimeWasmDigest);
        Assert.Equal(71, EmbeddedHost.PinnedRuntimeWasmDigest.Length);
    }
}
