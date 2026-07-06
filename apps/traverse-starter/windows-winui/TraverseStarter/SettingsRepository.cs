using Windows.Storage;

namespace TraverseStarter;

public interface ISettingsRepository
{
    string BaseUrl { get; set; }
    string Workspace { get; set; }
}

public sealed class SettingsRepository : ISettingsRepository
{
    private const string BaseUrlKey = "runtimeBaseUrl";
    private const string WorkspaceKey = "workspace";

    private readonly ApplicationDataContainer _localSettings;

    public SettingsRepository()
        : this(ApplicationData.Current.LocalSettings)
    {
    }

    internal SettingsRepository(ApplicationDataContainer localSettings)
    {
        _localSettings = localSettings;
        BaseUrl = Read(BaseUrlKey, AppConstants.DefaultBaseUrl);
        Workspace = Read(WorkspaceKey, AppConstants.DefaultWorkspace);
    }

    public string BaseUrl
    {
        get => Read(BaseUrlKey, AppConstants.DefaultBaseUrl);
        set => _localSettings.Values[BaseUrlKey] = value;
    }

    public string Workspace
    {
        get => Read(WorkspaceKey, AppConstants.DefaultWorkspace);
        set => _localSettings.Values[WorkspaceKey] = value;
    }

    private string Read(string key, string fallback)
    {
        return _localSettings.Values[key] as string ?? fallback;
    }
}
