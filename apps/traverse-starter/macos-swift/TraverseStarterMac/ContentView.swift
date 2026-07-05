import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var viewModel: ExecutionViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    inputSection
                    outputSection
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 720, minHeight: 560)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusLabel)
                    Text(settings.baseURLString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sidebar: some View {
        List {
            Section("Runtime Environment") {
                LabeledContent("Status", value: statusLabel)
                LabeledContent("Workspace", value: settings.workspace)
                LabeledContent("Capability", value: AppSettings.capabilityId)
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }

    private var inputSection: some View {
        GroupBox("Start Workflow") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.note)
                    .font(.body)
                    .frame(minHeight: 140)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                Text("\(viewModel.note.count)/\(AppSettings.noteMaxLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Start Workflow") { viewModel.submit() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(!viewModel.canSubmit)
                    Button("Reset") { viewModel.reset() }
                        .keyboardShortcut("r", modifiers: .command)
                }
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
                        Text("Submit a note above to start a workflow (⌘↩).")
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func outputFields(_ output: TraverseStarterOutput) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("Title").foregroundStyle(.secondary)
                Text(output.title)
            }
            GridRow {
                Text("Tags").foregroundStyle(.secondary)
                Text(output.tags.joined(separator: ", "))
            }
            GridRow {
                Text("Note type").foregroundStyle(.secondary)
                Text(output.noteType)
            }
            GridRow {
                Text("Next action").foregroundStyle(.secondary)
                Text(output.suggestedNextAction)
            }
            GridRow {
                Text("Status").foregroundStyle(.secondary)
                Text(output.status)
            }
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
