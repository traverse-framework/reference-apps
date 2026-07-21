namespace DocApproval;

public interface ISettingsRepository
{
    string Workspace { get; set; }
    string BundlePath { get; set; }
}
