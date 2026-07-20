import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Embedded runtime") {
                TextField("Workspace", text: $settings.workspace)
                    .textFieldStyle(.roundedBorder)
                TextField("Bundle path (optional)", text: $settings.bundlePath)
                    .textFieldStyle(.roundedBorder)
            }
            Section {
                Text("Embedded mode uses the bundled runtime/runtime.wasm. Restart after changing the bundle path.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 180)
        .padding()
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppSettings())
}
