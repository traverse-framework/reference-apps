using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace TraverseStarter;

public sealed partial class HomePage : Page
{
    private ExecutionViewModel? _viewModel;

    public HomePage()
    {
        InitializeComponent();
        NoteBox.TextChanged += (_, _) =>
        {
            if (_viewModel is null)
            {
                return;
            }

            _viewModel.Note = NoteBox.Text;
            NoteCountText.Text = $"{_viewModel.Note.Length}/{AppConstants.NoteMaxLength}";
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
        NoteBox.Text = _viewModel.Note;
        NoteCountText.Text = $"{_viewModel.Note.Length}/{AppConstants.NoteMaxLength}";
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
                    ? "Connect to the Traverse runtime to see workflow output here."
                    : "Submit a note above to start a workflow.";
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
                TitleValue.Text = _viewModel.Output?.Title ?? string.Empty;
                TagsValue.Text = _viewModel.Output is null
                    ? string.Empty
                    : string.Join(", ", _viewModel.Output.Tags);
                NoteTypeValue.Text = _viewModel.Output?.NoteType ?? string.Empty;
                NextActionValue.Text = _viewModel.Output?.SuggestedNextAction ?? string.Empty;
                StatusValue.Text = _viewModel.Output?.Status ?? string.Empty;

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
