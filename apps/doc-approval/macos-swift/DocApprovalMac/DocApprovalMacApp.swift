import SwiftUI
import DocApprovalCore

private struct AppStateViewModelKey: FocusedValueKey {
    typealias Value = AppStateViewModel
}

extension FocusedValues {
    var appStateViewModel: AppStateViewModel? {
        get { self[AppStateViewModelKey.self] }
        set { self[AppStateViewModelKey.self] = newValue }
    }
}

struct WorkflowCommands: Commands {
    @FocusedValue(\.appStateViewModel) private var viewModel

    var body: some Commands {
        CommandMenu("Document") {
            Button("Analyze Document") { viewModel?.submit() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel?.canSubmit != true)
            Button("Reset") { viewModel?.resetLocal() }
                .keyboardShortcut("r", modifiers: .command)
        }
    }
}

@main
struct DocApprovalMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                .focusedValue(\.appStateViewModel, viewModel)
        }
        .commands {
            WorkflowCommands()
        }
        Settings {
            PreferencesView()
                .environmentObject(settings)
        }
    }
}
