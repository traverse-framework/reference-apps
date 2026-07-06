using Microsoft.UI.Xaml;

namespace DocApproval;

public partial class App : Application
{
    public static SettingsRepository Settings { get; } = new();
    public static ExecutionViewModel ViewModel { get; private set; } = null!;

    public App()
    {
        InitializeComponent();
        ViewModel = new ExecutionViewModel(new TraverseClient(), Settings);
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        var window = new MainWindow();
        window.Activate();
    }
}
