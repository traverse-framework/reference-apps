using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace DocApproval;

public partial class ExecutionViewModel : ObservableObject, IDisposable
{
    private static readonly HashSet<string> TerminalStatuses = new(StringComparer.Ordinal)
    {
        "succeeded",
        "failed",
    };

    private readonly ITraverseClient _client;
    private readonly ISettingsRepository _settings;
    private CancellationTokenSource? _pollCts;
    private CancellationTokenSource? _healthCts;

    [ObservableProperty]
    private ExecutionPhase _phase = ExecutionPhase.Idle;

    [ObservableProperty]
    private string _document = string.Empty;

    [ObservableProperty]
    private RuntimeStatus _runtimeStatus = RuntimeStatus.Checking;

    [ObservableProperty]
    private bool _showTrace;

    [ObservableProperty]
    private string? _pollingExecutionId;

    [ObservableProperty]
    private DocApprovalOutput? _output;

    [ObservableProperty]
    private IReadOnlyList<TraceEvent> _trace = Array.Empty<TraceEvent>();

    [ObservableProperty]
    private string? _error;

    public ExecutionViewModel(ITraverseClient client, ISettingsRepository settings)
    {
        _client = client;
        _settings = settings;
        StartHealthChecks();
    }

    public string BaseUrl => _settings.BaseUrl;

    public string Workspace => _settings.Workspace;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Online &&
        !string.IsNullOrWhiteSpace(Document) &&
        Phase is not ExecutionPhase.Loading and not ExecutionPhase.Polling;

    partial void OnDocumentChanged(string value) => SubmitCommand.NotifyCanExecuteChanged();

    partial void OnPhaseChanged(ExecutionPhase value) => SubmitCommand.NotifyCanExecuteChanged();

    partial void OnRuntimeStatusChanged(RuntimeStatus value) => SubmitCommand.NotifyCanExecuteChanged();

    [RelayCommand(CanExecute = nameof(CanSubmit))]
    private async Task SubmitAsync()
    {
        if (!CanSubmit)
        {
            return;
        }

        _pollCts?.Cancel();
        _pollCts = new CancellationTokenSource();
        var token = _pollCts.Token;

        Phase = ExecutionPhase.Loading;
        Error = null;
        Output = null;
        Trace = Array.Empty<TraceEvent>();
        ShowTrace = false;

        var baseUrl = _settings.BaseUrl.Trim().TrimEnd('/');
        var workspace = _settings.Workspace;
        var trimmedDocument = Document.Trim();

        try
        {
            var executionId = await _client.ExecuteAsync(
                baseUrl,
                workspace,
                AppConstants.CapabilityId,
                new Dictionary<string, string> { ["document"] = trimmedDocument },
                token);

            Phase = ExecutionPhase.Polling;
            PollingExecutionId = executionId;
            await PollUntilTerminalAsync(baseUrl, workspace, executionId, token);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            Phase = ExecutionPhase.Failed;
            Error = ex.Message;
        }
    }

    [RelayCommand]
    private void Reset()
    {
        _pollCts?.Cancel();
        _pollCts = null;
        Phase = ExecutionPhase.Idle;
        PollingExecutionId = null;
        Output = null;
        Trace = Array.Empty<TraceEvent>();
        Error = null;
        ShowTrace = false;
        Document = string.Empty;
    }

    public async Task RefreshHealthAsync()
    {
        var baseUrl = _settings.BaseUrl.Trim().TrimEnd('/');
        RuntimeStatus = RuntimeStatus.Checking;
        try
        {
            var ok = await _client.CheckHealthAsync(baseUrl);
            RuntimeStatus = ok ? RuntimeStatus.Online : RuntimeStatus.Offline;
        }
        catch
        {
            RuntimeStatus = RuntimeStatus.Offline;
        }
    }

    private void StartHealthChecks()
    {
        _healthCts?.Cancel();
        _healthCts = new CancellationTokenSource();
        var token = _healthCts.Token;
        _ = Task.Run(async () =>
        {
            while (!token.IsCancellationRequested)
            {
                await RefreshHealthAsync();
                try
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), token);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }
        }, token);
    }

    private async Task PollUntilTerminalAsync(
        string baseUrl,
        string workspaceId,
        string executionId,
        CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            var result = await _client.PollExecutionAsync(baseUrl, workspaceId, executionId, cancellationToken);
            if (TerminalStatuses.Contains(result.Status))
            {
                if (result.Status == "succeeded")
                {
                    IReadOnlyList<TraceEvent> trace;
                    try
                    {
                        trace = await _client.FetchTraceAsync(baseUrl, workspaceId, executionId, cancellationToken);
                    }
                    catch
                    {
                        trace = Array.Empty<TraceEvent>();
                    }

                    Output = result.Output ?? DocApprovalOutput.Empty;
                    Trace = trace;
                    Phase = ExecutionPhase.Succeeded;
                }
                else
                {
                    Phase = ExecutionPhase.Failed;
                    Error = result.Error ?? "execution failed";
                }

                return;
            }

            await Task.Delay(TimeSpan.FromSeconds(1), cancellationToken);
        }
    }

    public void Dispose()
    {
        _pollCts?.Cancel();
        _pollCts?.Dispose();
        _healthCts?.Cancel();
        _healthCts?.Dispose();
    }
}
