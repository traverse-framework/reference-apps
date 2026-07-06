import SwiftUI

@main
struct DocApprovalApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel: ExecutionViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: ExecutionViewModel(
            client: TraverseClient(),
            settings: settings
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
