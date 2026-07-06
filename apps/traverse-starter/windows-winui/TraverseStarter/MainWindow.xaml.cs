using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace TraverseStarter;

public sealed partial class MainWindow : Window
{
    private readonly ExecutionViewModel _viewModel = App.ViewModel;
    private readonly SettingsRepository _settings = App.Settings;

    public MainWindow()
    {
        InitializeComponent();
        BaseUrlText.Text = _settings.BaseUrl;
        ContentFrame.Navigate(typeof(HomePage), _viewModel);
        _viewModel.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is nameof(ExecutionViewModel.RuntimeStatus))
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
        switch (_viewModel.RuntimeStatus)
        {
            case RuntimeStatus.Online:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 0, 188, 212));
                StatusText.Text = "Online";
                break;
            case RuntimeStatus.Offline:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 229, 57, 53));
                StatusText.Text = "Offline";
                break;
            default:
                StatusDot.Fill = new SolidColorBrush(Color.FromArgb(255, 158, 158, 158));
                StatusText.Text = "Checking…";
                break;
        }
    }
}
