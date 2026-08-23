using System.Text.Json;
using Xunit;

namespace TraverseStarter.Tests;

public class PresentationMapperTests
{
    [Fact]
    public void EmptyStreamIsIdle()
    {
        var snap = PresentationMapper.MapPresentationState(Array.Empty<EmbedderEventLike>());
        Assert.Equal(PresentationState.Idle, snap.State);
        Assert.Null(snap.ErrorMessage);
    }

    [Fact]
    public void HappyPathLoads()
    {
        var events = new[]
        {
            new EmbedderEventLike(
                "capability_invoked",
                1,
                JsonDocument.Parse("""{"capability_id":"fixture.process"}""").RootElement),
            new EmbedderEventLike(
                "capability_result",
                2,
                JsonDocument.Parse("""{"capability_id":"fixture.process","output":{"ok":true}}""").RootElement),
        };

        Assert.Equal(PresentationState.Loaded, PresentationMapper.MapPresentationState(events).State);
        Assert.Null(PresentationMapper.ActiveCapabilityId(events));
        Assert.Equal(
            new[] { "fixture.process", "fixture.process" },
            PresentationMapper.MapCapabilityProgress(events).Select(s => s.CapabilityId).ToArray());
    }

    [Fact]
    public void BlockedWaitingForHuman()
    {
        var events = new[]
        {
            new EmbedderEventLike(
                "capability_invoked",
                1,
                JsonDocument.Parse("""{"capability_id":"fixture.approve"}""").RootElement),
            new EmbedderEventLike(
                "state_changed",
                2,
                JsonDocument.Parse("""{"state":"waiting_for_human"}""").RootElement),
        };

        Assert.Equal(PresentationState.Blocked, PresentationMapper.MapPresentationState(events).State);
        Assert.Equal("fixture.approve", PresentationMapper.ActiveCapabilityId(events));
    }
}
