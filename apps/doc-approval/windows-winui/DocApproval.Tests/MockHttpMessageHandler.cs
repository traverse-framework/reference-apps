using System.Net;

namespace DocApproval.Tests;

internal sealed class MockHttpMessageHandler : HttpMessageHandler
{
    private readonly Func<HttpRequestMessage, HttpResponseMessage> _handler;

    public MockHttpMessageHandler(Func<HttpRequestMessage, HttpResponseMessage> handler)
    {
        _handler = handler;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        return Task.FromResult(_handler(request));
    }
}

internal static class HttpTestFactory
{
    public static TraverseClient CreateClient(Func<HttpRequestMessage, HttpResponseMessage> handler)
    {
        return new TraverseClient(new HttpClient(new MockHttpMessageHandler(handler)));
    }
}
