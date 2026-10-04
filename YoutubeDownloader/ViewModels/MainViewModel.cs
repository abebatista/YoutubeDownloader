using System;
using System.Threading.Tasks;
using Avalonia;
using YoutubeDownloader.Framework;
using YoutubeDownloader.Localization;
using YoutubeDownloader.Services;
using YoutubeDownloader.Utils.Extensions;
using YoutubeDownloader.ViewModels.Components;

namespace YoutubeDownloader.ViewModels;

public partial class MainViewModel(
    ViewModelManager viewModelManager,
    SnackbarManager snackbarManager,
    LocalizationManager localizationManager,
    SettingsService settingsService,
    UpdateService updateService
) : ViewModelBase
{
    public string Title { get; } = $"{Program.Name} v{Program.VersionString}";

    public DashboardViewModel Dashboard { get; } = viewModelManager.GetDashboardViewModel();

    private async Task CheckForUpdatesAsync()
    {
        try
        {
            var updateVersion = await updateService.CheckForUpdatesAsync();
            if (updateVersion is null)
                return;

            snackbarManager.Notify(
                string.Format(
                    localizationManager.UpdateDownloadingMessage,
                    Program.Name,
                    updateVersion
                )
            );
            await updateService.PrepareUpdateAsync(updateVersion);

            snackbarManager.Notify(
                localizationManager.UpdateReadyMessage,
                localizationManager.UpdateInstallNowButton,
                () =>
                {
                    updateService.FinalizeUpdate(true);

                    if (Application.Current?.ApplicationLifetime?.TryShutdown(2) != true)
                        Environment.Exit(2);
                }
            );
        }
        catch
        {
            // Failure to update shouldn't crash the application
            snackbarManager.Notify(localizationManager.UpdateFailedMessage);
        }
    }

    public override Task InitializeAsync() => CheckForUpdatesAsync();

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            // Save settings
            settingsService.Save();

            // Finalize pending updates
            updateService.FinalizeUpdate(false);
        }

        base.Dispose(disposing);
    }
}
