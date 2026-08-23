using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace Loop;

public partial class ExecutionViewModel : ObservableObject, IDisposable
{
    private readonly IEmbeddedHost? _host;
    private readonly ISettingsRepository _settings;
    private CancellationTokenSource? _submitCts;

    [ObservableProperty]
    private ExecutionPhase _phase = ExecutionPhase.Idle;

    [ObservableProperty]
    private string _transcript = string.Empty;

    [ObservableProperty]
    private RuntimeStatus _runtimeStatus = RuntimeStatus.Starting;

    [ObservableProperty]
    private bool _showTrace;

    [ObservableProperty]
    private string? _sessionId;

    [ObservableProperty]
    private LoopOutput? _output;

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
        !string.IsNullOrWhiteSpace(Transcript) &&
        Phase is not ExecutionPhase.Loading;

    partial void OnTranscriptChanged(string value)
    {
        if (value.Length > AppConstants.TranscriptMaxLength)
        {
            Transcript = value[..AppConstants.TranscriptMaxLength];
            return;
        }

        SubmitCommand.NotifyCanExecuteChanged();
    }

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

        var trimmedTranscript = Transcript.Trim();

        try
        {
            var result = await Task.Run(
                () => _host.SubmitTranscript(trimmedTranscript),
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

            Output = result.Output ?? LoopOutput.Empty;
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
