using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace DocApproval;

public partial class ExecutionViewModel : ObservableObject, IDisposable
{
    private readonly IEmbeddedHost? _host;
    private readonly ISettingsRepository _settings;
    private CancellationTokenSource? _submitCts;

    [ObservableProperty]
    private ExecutionPhase _phase = ExecutionPhase.Idle;

    [ObservableProperty]
    private string _document = string.Empty;

    [ObservableProperty]
    private RuntimeStatus _runtimeStatus = RuntimeStatus.Starting;

    [ObservableProperty]
    private bool _showTrace;

    [ObservableProperty]
    private string? _sessionId;

    [ObservableProperty]
    private DocApprovalOutput? _output;

    [ObservableProperty]
    private IReadOnlyList<TraceEvent> _trace = Array.Empty<TraceEvent>();

    [ObservableProperty]
    private string? _error;

    public ExecutionViewModel(IEmbeddedHost? host, ISettingsRepository settings)
    {
        _host = host;
        _settings = settings;
        RuntimeMode = EmbeddedHost.RuntimeModeEmbedded;
        WorkflowId = host?.WorkflowId ?? AppConstants.CapabilityId;
        RuntimeStatus = host?.IsReady == true ? RuntimeStatus.Ready : RuntimeStatus.Unavailable;
    }

    public string RuntimeMode { get; }

    public string WorkflowId { get; }

    public string Workspace => _settings.Workspace;

    public bool CanSubmit =>
        RuntimeStatus == RuntimeStatus.Ready &&
        !string.IsNullOrWhiteSpace(Document) &&
        Phase is not ExecutionPhase.Loading;

    partial void OnDocumentChanged(string value) => SubmitCommand.NotifyCanExecuteChanged();

    partial void OnPhaseChanged(ExecutionPhase value) => SubmitCommand.NotifyCanExecuteChanged();

    partial void OnRuntimeStatusChanged(RuntimeStatus value) => SubmitCommand.NotifyCanExecuteChanged();

    [RelayCommand(CanExecute = nameof(CanSubmit))]
    private async Task SubmitAsync()
    {
        if (!CanSubmit || _host is null)
        {
            return;
        }

        _submitCts?.Cancel();
        _submitCts = new CancellationTokenSource();

        Phase = ExecutionPhase.Loading;
        Error = null;
        Output = null;
        Trace = Array.Empty<TraceEvent>();
        ShowTrace = false;
        SessionId = null;

        var trimmedDocument = Document.Trim();

        try
        {
            var result = await Task.Run(
                () => _host.SubmitDocument(trimmedDocument),
                _submitCts.Token);

            SessionId = result.SessionId;
            Trace = result.Events;
            ShowTrace = result.Events.Count > 0;

            if (result.Error is not null)
            {
                Phase = ExecutionPhase.Failed;
                Error = result.Error;
                return;
            }

            Output = result.Output ?? DocApprovalOutput.Empty;
            Phase = ExecutionPhase.Succeeded;
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
        _submitCts?.Cancel();
        _submitCts = null;
        Phase = ExecutionPhase.Idle;
        SessionId = null;
        Output = null;
        Trace = Array.Empty<TraceEvent>();
        Error = null;
        ShowTrace = false;
    }

    public void RefreshRuntimeStatus()
    {
        RuntimeStatus = _host?.IsReady == true ? RuntimeStatus.Ready : RuntimeStatus.Unavailable;
        OnPropertyChanged(nameof(Workspace));
    }

    public void Dispose()
    {
        _submitCts?.Cancel();
        _submitCts?.Dispose();
        _host?.Dispose();
    }
}
