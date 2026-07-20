import SwiftUI
import TraverseCore

@main
struct TraverseStarterApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel: AppStateViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        let host = EmbeddedHost.tryCreateProduction(
            bundleRoot: settings.bundleURL,
            workspaceId: settings.workspace
        )
        _viewModel = StateObject(wrappedValue: AppStateViewModel(
            host: host,
            workspaceId: settings.workspace,
            appId: AppSettings.appId,
            noteMaxLength: AppSettings.noteMaxLength
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(viewModel)
                .onChange(of: settings.workspace) { _, workspace in
                    viewModel.updateWorkspace(workspace)
                }
        }
    }
}
