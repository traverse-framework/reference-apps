import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Runtime") {
                TextField("Workspace", text: $settings.workspace)
                    .textFieldStyle(.roundedBorder)
            }
            Section {
                Text("Runtime mode: Embedded — no sidecar required.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 160)
        .padding()
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppSettings())
}
