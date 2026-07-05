import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Runtime") {
                TextField("Runtime URL", text: $settings.baseURLString)
                    .textFieldStyle(.roundedBorder)
                TextField("Workspace", text: $settings.workspace)
                    .textFieldStyle(.roundedBorder)
            }
            Section {
                Text("Default: http://127.0.0.1:8787 with workspace local-default")
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
