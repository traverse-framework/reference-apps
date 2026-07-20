using Windows.Storage;

namespace TraverseStarter;

public interface ISettingsRepository
{
    string Workspace { get; set; }
    string BundlePath { get; set; }
}

public sealed class SettingsRepository : ISettingsRepository
{
    private const string WorkspaceKey = "workspace";
    private const string BundlePathKey = "bundlePath";

    private readonly ApplicationDataContainer _localSettings;

    public SettingsRepository()
        : this(ApplicationData.Current.LocalSettings)
    {
    }

    internal SettingsRepository(ApplicationDataContainer localSettings)
    {
        _localSettings = localSettings;
        Workspace = Read(WorkspaceKey, AppConstants.DefaultWorkspace);
        BundlePath = Read(BundlePathKey, string.Empty);
    }

    public string Workspace
    {
        get => Read(WorkspaceKey, AppConstants.DefaultWorkspace);
        set => _localSettings.Values[WorkspaceKey] = value;
    }

    public string BundlePath
    {
        get => Read(BundlePathKey, string.Empty);
        set => _localSettings.Values[BundlePathKey] = value;
    }

    private string Read(string key, string fallback)
    {
        return _localSettings.Values[key] as string ?? fallback;
    }
}
