import SwiftUI

private struct ExecutionViewModelKey: FocusedValueKey {
    typealias Value = ExecutionViewModel
}

extension FocusedValues {
    var executionViewModel: ExecutionViewModel? {
        get { self[ExecutionViewModelKey.self] }
        set { self[ExecutionViewModelKey.self] = newValue }
    }
}

struct WorkflowCommands: Commands {
    @FocusedValue(\.executionViewModel) private var viewModel

    var body: some Commands {
        CommandMenu("Workflow") {
            Button("Submit Note") { viewModel?.submit() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel?.canSubmit != true)
            Button("Reset") { viewModel?.reset() }
                .keyboardShortcut("r", modifiers: .command)
        }
    }
}

@main
struct TraverseStarterMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                .focusedValue(\.executionViewModel, viewModel)
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
