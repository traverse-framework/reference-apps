using System.Net;
using System.Text;

namespace DocApproval.Tests;

public class TraverseClientTests
{
    [Fact]
    public async Task CheckHealthReturnsTrueOn200()
    {
        var client = HttpTestFactory.CreateClient(request =>
        {
            Assert.EndsWith("/healthz", request.RequestUri!.AbsolutePath);
            return new HttpResponseMessage(HttpStatusCode.OK);
        });

        var ok = await client.CheckHealthAsync("http://127.0.0.1:8787");
        Assert.True(ok);
    }

    [Fact]
    public async Task ExecuteReturnsExecutionId()
    {
        var client = HttpTestFactory.CreateClient(request =>
        {
            Assert.Equal(HttpMethod.Post, request.Method);
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("""{"execution_id":"exec_abc"}""", Encoding.UTF8, "application/json"),
            };
        });

        var id = await client.ExecuteAsync(
            "http://127.0.0.1:8787",
            "local-default",
            AppConstants.CapabilityId,
            new Dictionary<string, string> { ["document"] = "contract" });

        Assert.Equal("exec_abc", id);
    }

    [Fact]
    public async Task PollExecutionParsesOutput()
    {
        var client = HttpTestFactory.CreateClient(_ =>
            new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(
                    """
                    {"status":"succeeded","output":{"docType":"invoice","parties":["A"],"amounts":["$100"],"confidence":0.9,"recommendation":"approve"}}
                    """,
                    Encoding.UTF8,
                    "application/json"),
            });

        var result = await client.PollExecutionAsync("http://127.0.0.1:8787", "local-default", "exec_abc");
        Assert.Equal("succeeded", result.Status);
        Assert.Equal("invoice", result.Output?.DocType);
    }
}
