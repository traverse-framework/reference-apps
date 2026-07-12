import SwiftUI
import TraverseCore

@main
struct TraverseStarterApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel: AppStateViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: AppStateViewModel(
            client: TraverseClient(),
            baseURL: settings.baseURL,
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
                .onChange(of: settings.baseURLString) { _, _ in
                    viewModel.updateConnection(baseURL: settings.baseURL, workspaceId: settings.workspace)
                }
                .onChange(of: settings.workspace) { _, workspace in
                    viewModel.updateConnection(baseURL: settings.baseURL, workspaceId: workspace)
                }
        }
    }
}
