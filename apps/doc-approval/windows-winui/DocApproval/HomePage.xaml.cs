using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace DocApproval;

public sealed partial class HomePage : Page
{
    private ExecutionViewModel? _viewModel;

    public HomePage()
    {
        InitializeComponent();
        DocumentBox.TextChanged += (_, _) =>
        {
            if (_viewModel is null)
            {
                return;
            }

            _viewModel.Document = DocumentBox.Text;
            SubmitButton.IsEnabled = _viewModel.CanSubmit;
        };
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is not ExecutionViewModel viewModel)
        {
            return;
        }

        _viewModel = viewModel;
        _viewModel.PropertyChanged += (_, _) => DispatcherQueue.TryEnqueue(UpdateUi);
        DocumentBox.Text = _viewModel.Document;
        UpdateUi();
    }

    private async void SubmitButton_Click(object sender, RoutedEventArgs e)
    {
        if (_viewModel is null)
        {
            return;
        }

        await _viewModel.SubmitCommand.ExecuteAsync(null);
    }

    private void ResetButton_Click(object sender, RoutedEventArgs e)
    {
        _viewModel?.ResetCommand.Execute(null);
        if (_viewModel is not null)
        {
            DocumentBox.Text = _viewModel.Document;
        }
    }

    private void UpdateUi()
    {
        if (_viewModel is null)
        {
            return;
        }

        SubmitButton.IsEnabled = _viewModel.CanSubmit;
        OfflineHint.Visibility = _viewModel.RuntimeStatus == RuntimeStatus.Offline
            ? Visibility.Visible
            : Visibility.Collapsed;

        IdleText.Visibility = Visibility.Collapsed;
        LoadingText.Visibility = Visibility.Collapsed;
        PollingText.Visibility = Visibility.Collapsed;
        ErrorText.Visibility = Visibility.Collapsed;
        OutputGrid.Visibility = Visibility.Collapsed;
        TraceExpander.Visibility = Visibility.Collapsed;

        switch (_viewModel.Phase)
        {
            case ExecutionPhase.Idle:
                IdleText.Visibility = Visibility.Visible;
                IdleText.Text = _viewModel.RuntimeStatus == RuntimeStatus.Offline
                    ? "Connect to the Traverse runtime to see analysis output here."
                    : "Submit a document above to start analysis.";
                break;
            case ExecutionPhase.Loading:
                LoadingText.Visibility = Visibility.Visible;
                break;
            case ExecutionPhase.Polling:
                PollingText.Visibility = Visibility.Visible;
                PollingText.Text = $"Polling execution {_viewModel.PollingExecutionId}…";
                break;
            case ExecutionPhase.Failed:
                ErrorText.Visibility = Visibility.Visible;
                ErrorText.Text = $"Error: {_viewModel.Error}";
                break;
            case ExecutionPhase.Succeeded:
                OutputGrid.Visibility = Visibility.Visible;
                DocTypeValue.Text = _viewModel.Output?.Analysis.DocType ?? string.Empty;
                PartiesValue.Text = _viewModel.Output is null
                    ? string.Empty
                    : string.Join(", ", _viewModel.Output.Analysis.Parties);
                AmountsValue.Text = _viewModel.Output is null
                    ? string.Empty
                    : string.Join(", ", _viewModel.Output.Analysis.Amounts);
                AnalyzeConfidenceValue.Text = _viewModel.Output?.Analysis.Confidence ?? string.Empty;
                AnalyzeRecommendationValue.Text = _viewModel.Output?.Analysis.Recommendation ?? string.Empty;
                RecommendationValue.Text = _viewModel.Output?.Recommendation.Recommendation ?? string.Empty;
                RationaleValue.Text = _viewModel.Output?.Recommendation.Rationale ?? string.Empty;
                ConfidenceValue.Text = _viewModel.Output?.Recommendation.Confidence ?? string.Empty;

                if (_viewModel.Trace.Count > 0)
                {
                    TraceExpander.Visibility = Visibility.Visible;
                    TraceExpander.Header = $"Trace ({_viewModel.Trace.Count} events)";
                    TraceList.ItemsSource = _viewModel.Trace.Select(evt =>
                        $"{evt.Timestamp} · {evt.EventType}");
                }

                break;
        }
    }
}
