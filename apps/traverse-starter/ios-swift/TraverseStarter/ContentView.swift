import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var viewModel: ExecutionViewModel
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    runtimeSection
                    inputSection
                    outputSection
                }
                .padding()
            }
            .navigationTitle("traverse-starter")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
        }
    }

    private var runtimeSection: some View {
        GroupBox("Runtime Environment") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusLabel)
                    Spacer()
                }
                Text(settings.baseURLString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("workspace: \(settings.workspace)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("capability: \(AppSettings.capabilityId)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var inputSection: some View {
        GroupBox("Start Workflow") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.note)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                Text("\(viewModel.note.count)/\(AppSettings.noteMaxLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { viewModel.submit() }) {
                    Text(viewModel.isRunning ? "Running…" : "Start Workflow")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)
                if viewModel.runtimeStatus == .offline {
                    Text("Runtime offline — start with `cargo run -p traverse-cli -- serve`")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var outputSection: some View {
        GroupBox("Execution Output") {
            VStack(alignment: .leading, spacing: 12) {
                switch viewModel.phase {
                case .idle:
                    if viewModel.runtimeStatus == .offline {
                        Text("Connect to the Traverse runtime to see workflow output here.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Submit a note above to start a workflow.")
                            .foregroundStyle(.secondary)
                    }
                case .loading:
                    Text("Starting execution…")
                case .polling(let executionId):
                    Text("Polling execution \(executionId)…")
                        .font(.footnote.monospaced())
                case .failed(let error):
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                case .succeeded(let output, let trace):
                    outputFields(output)
                    if !trace.isEmpty {
                        DisclosureGroup("Trace (\(trace.count) events)", isExpanded: $viewModel.showTrace) {
                            ForEach(Array(trace.enumerated()), id: \.offset) { _, event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(event.timestamp) · \(event.event_type)")
                                        .font(.caption.monospaced())
                                    if let data = event.data {
                                        Text(String(describing: data))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    Button("Reset") { viewModel.reset() }
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func outputFields(_ output: TraverseStarterOutput) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledField("Title", output.title)
            labeledField("Tags", output.tags.joined(separator: ", "))
            labeledField("Note type", output.noteType)
            labeledField("Suggested next action", output.suggestedNextAction)
            labeledField("Status", output.status)
        }
    }

    private func labeledField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
        }
    }

    private var statusColor: Color {
        switch viewModel.runtimeStatus {
        case .online: return .cyan
        case .offline: return .red
        case .checking: return .gray
        }
    }

    private var statusLabel: String {
        switch viewModel.runtimeStatus {
        case .online: return "Online"
        case .offline: return "Offline"
        case .checking: return "Checking…"
        }
    }
}

#Preview {
    let settings = AppSettings()
    ContentView()
        .environmentObject(settings)
        .environmentObject(ExecutionViewModel(client: TraverseClient(), settings: settings))
}
