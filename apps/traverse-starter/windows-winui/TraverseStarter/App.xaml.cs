using Microsoft.UI.Xaml;

namespace TraverseStarter;

public partial class App : Application
{
    public static SettingsRepository Settings { get; } = new();
    public static ExecutionViewModel ViewModel { get; private set; } = null!;

    public App()
    {
        InitializeComponent();
        var bundleOverride = string.IsNullOrWhiteSpace(Settings.BundlePath)
            ? null
            : Settings.BundlePath;
        var host = EmbeddedHost.TryCreateProduction(bundleOverride, Settings.Workspace);
        ViewModel = new ExecutionViewModel(host, Settings);
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        var window = new MainWindow();
        window.Activate();
    }
}
