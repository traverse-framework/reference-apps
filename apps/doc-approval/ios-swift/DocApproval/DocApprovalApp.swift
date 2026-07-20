import SwiftUI
import DocApprovalCore

@main
struct DocApprovalApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel: AppStateViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        let host = EmbeddedRuntime.tryMakeProductionHost(workspaceID: settings.workspace)
        _viewModel = StateObject(wrappedValue: AppStateViewModel(
            host: host,
            appId: AppSettings.appId,
            documentMaxLength: AppSettings.documentMaxLength
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(viewModel)
        }
    }
}
