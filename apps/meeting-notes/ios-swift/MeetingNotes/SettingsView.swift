import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Embedded runtime") {
                    TextField("Workspace", text: $settings.workspace)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Bundle path (optional)", text: $settings.bundlePath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Text("Embedded mode uses the bundled runtime/runtime.wasm. Restart after changing the bundle path.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
