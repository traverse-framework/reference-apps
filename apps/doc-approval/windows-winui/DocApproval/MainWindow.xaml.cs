using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace DocApproval;

public sealed partial class MainWindow : Window
{
    private readonly ExecutionViewModel _viewModel = App.ViewModel;
    private readonly SettingsRepository _settings = App.Settings;

    public MainWindow()
    {
        InitializeComponent();
        ContentFrame.Navigate(typeof(HomePage), _viewModel);
        _viewModel.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is nameof(ExecutionViewModel.RuntimeStatus)
                or nameof(ExecutionViewModel.Workspace)
                or null)
            {
                UpdateStatusHeader();
            }
        };
        UpdateStatusHeader();
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.IsSettingsSelected)
        {
            ContentFrame.Navigate(typeof(SettingsPage), _settings);
            return;
        }

        ContentFrame.Navigate(typeof(HomePage), _viewModel);
    }

    private void UpdateStatusHeader()
    {
        ModeText.Text = _viewModel.RuntimeMode;
        WorkspaceText.Text = _settings.Workspace;
        WorkflowText.Text = _viewModel.WorkflowId;

        switch (_viewModel.RuntimeStatus)
        {
            case RuntimeStatus.Ready:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 0, 188, 212));
                StatusText.Text = "Ready";
                break;
            case RuntimeStatus.Unavailable:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 229, 57, 53));
                StatusText.Text = "Unavailable";
                break;
            default:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 158, 158, 158));
                StatusText.Text = "Starting…";
                break;
        }
    }
}
