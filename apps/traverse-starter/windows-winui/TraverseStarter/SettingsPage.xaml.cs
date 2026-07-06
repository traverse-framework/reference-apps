using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace TraverseStarter;

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
        BaseUrlBox.Text = settings.BaseUrl;
        WorkspaceBox.Text = settings.Workspace;
    }

    private async void Setting_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (_settings is null)
        {
            return;
        }

        _settings.BaseUrl = BaseUrlBox.Text;
        _settings.Workspace = WorkspaceBox.Text;
        await App.ViewModel.RefreshHealthAsync();
    }
}
