using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace DocApproval;

public sealed partial class SettingsPage : Page
{
    private SettingsRepository? _settings;

    public SettingsPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is not SettingsRepository settings)
        {
            return;
        }

        _settings = settings;
        WorkspaceBox.Text = settings.Workspace;
        BundlePathBox.Text = settings.BundlePath;
    }

    private void Setting_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (_settings is null)
        {
            return;
        }

        _settings.Workspace = WorkspaceBox.Text;
        _settings.BundlePath = BundlePathBox.Text;
        App.ViewModel.RefreshRuntimeStatus();
    }
}
