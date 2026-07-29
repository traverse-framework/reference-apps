using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace MeetingNotes;

public sealed partial class HomePage : Page
{
    private ExecutionViewModel? _viewModel;

    public HomePage()
    {
        InitializeComponent();
        TranscriptBox.TextChanged += (_, _) =>
        {
            if (_viewModel is null)
            {
                return;
            }

            _viewModel.Transcript = TranscriptBox.Text;
            if (TranscriptBox.Text != _viewModel.Transcript)
            {
                TranscriptBox.Text = _viewModel.Transcript;
                TranscriptBox.SelectionStart = TranscriptBox.Text.Length;
            }
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
        TranscriptBox.Text = _viewModel.Transcript;
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
            TranscriptBox.Text = _viewModel.Transcript;
        }
    }

    private void UpdateUi()
    {
        if (_viewModel is null)
        {
            return;
        }

        SubmitButton.IsEnabled = _viewModel.CanSubmit;
        OfflineHint.Visibility = _viewModel.RuntimeStatus == RuntimeStatus.Unavailable
            ? Visibility.Visible
            : Visibility.Collapsed;

        IdleText.Visibility = Visibility.Collapsed;
        LoadingText.Visibility = Visibility.Collapsed;
        ErrorText.Visibility = Visibility.Collapsed;
        OutputGrid.Visibility = Visibility.Collapsed;
        TraceExpander.Visibility = Visibility.Collapsed;

        switch (_viewModel.Phase)
        {
            case ExecutionPhase.Idle:
                IdleText.Visibility = Visibility.Visible;
                IdleText.Text = _viewModel.RuntimeStatus == RuntimeStatus.Unavailable
                    ? "Embedded runtime unavailable - sync the WinUI bundle (scripts/ci/sync_winui_meeting_notes_bundle.sh)."
                    : "Submit a transcript above to run meeting-notes.process.";
                break;
            case ExecutionPhase.Loading:
                LoadingText.Visibility = Visibility.Visible;
                break;
            case ExecutionPhase.Failed:
                ErrorText.Visibility = Visibility.Visible;
                ErrorText.Text = $"Error: {_viewModel.Error}";
                break;
            case ExecutionPhase.Succeeded:
                OutputGrid.Visibility = Visibility.Visible;
                SummaryValue.Text = _viewModel.Output?.Summary ?? string.Empty;
                ActionItemsList.ItemsSource = FormatActionItems(_viewModel.Output?.ActionItems);
                DecisionsList.ItemsSource = FormatDecisions(_viewModel.Output?.Decisions);
                FollowUpsList.ItemsSource = FormatStringList(_viewModel.Output?.FollowUps);

                if (_viewModel.Trace.Count > 0)
                {
                    TraceExpander.Visibility = Visibility.Visible;
                    TraceExpander.Header = $"Trace ({_viewModel.Trace.Count} events)";
                    TraceList.ItemsSource = _viewModel.Trace.Select(evt =>
                        $"{evt.Timestamp} - {evt.EventType}");
                }

                break;
        }
    }

    private static IReadOnlyList<string> FormatActionItems(IReadOnlyList<ActionItem>? items)
    {
        if (items is null || items.Count == 0)
        {
            return ["None recorded"];
        }

        return items.Select(item =>
        {
            var details = new[] { item.Owner, item.Due is null ? null : $"due {item.Due}" }
                .Where(value => !string.IsNullOrWhiteSpace(value));
            var suffix = string.Join(" | ", details);
            return string.IsNullOrWhiteSpace(suffix)
                ? item.Task
                : $"{item.Task} ({suffix})";
        }).ToArray();
    }

    private static IReadOnlyList<string> FormatDecisions(IReadOnlyList<Decision>? items)
    {
        if (items is null || items.Count == 0)
        {
            return ["None recorded"];
        }

        return items.Select(item =>
            string.IsNullOrWhiteSpace(item.MadeBy)
                ? item.Text
                : $"{item.Text} - decided by {item.MadeBy}").ToArray();
    }

    private static IReadOnlyList<string> FormatStringList(IReadOnlyList<string>? items)
    {
        if (items is null || items.Count == 0)
        {
            return ["None recorded"];
        }

        return items;
    }
}
