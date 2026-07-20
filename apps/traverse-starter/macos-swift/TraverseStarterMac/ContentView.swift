import SwiftUI
import TraverseCore

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var viewModel: AppStateViewModel

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
                    Text(viewModel.runtimeMode)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sidebar: some View {
        List {
            Section("Runtime Environment") {
                LabeledContent("Mode", value: viewModel.runtimeMode)
                LabeledContent("Status", value: statusLabel)
                LabeledContent("Workspace", value: settings.workspace)
                LabeledContent("Workflow", value: viewModel.workflowId)
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
                    Button(viewModel.isRunning ? "Running…" : "Start Workflow") { viewModel.submit() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(!viewModel.canSubmit)
                    Button("Reset") { viewModel.resetLocal() }
                        .keyboardShortcut("r", modifiers: .command)
                }
                if viewModel.runtimeStatus == .unavailable {
                    Text("Embedded runtime unavailable — run scripts/ci/sync_swift_starter_bundle.sh")
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
                if let error = viewModel.errorMessage, viewModel.currentState == "error" {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }

                switch viewModel.currentState {
                case "idle":
                    if viewModel.runtimeStatus == .unavailable {
                        Text("Embedded runtime unavailable — sync the Swift bundle to see output here.")
                            .foregroundStyle(.secondary)
                    } else if viewModel.errorMessage == nil {
                        Text("Submit a note above to start a workflow (⌘↩).")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Processing…")
                case "error":
                    Text("Error: \(viewModel.errorMessage ?? "execution failed")")
                        .foregroundStyle(.red)
                case "completed", "results":
                    if let output = viewModel.output {
                        outputFields(output)
                    }
                    if !viewModel.trace.isEmpty {
                        DisclosureGroup("Trace (\(viewModel.trace.count) events)", isExpanded: $viewModel.showTrace) {
                            ForEach(Array(viewModel.trace.enumerated()), id: \.offset) { _, event in
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
                default:
                    Text("State: \(viewModel.currentState)")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func outputFields(_ output: TraverseStarterOutput) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("Valid").foregroundStyle(.secondary)
                Text(output.validate.valid ? "yes" : "no")
            }
            GridRow {
                Text("Issues").foregroundStyle(.secondary)
                Text(output.validate.issues.isEmpty ? "None" : output.validate.issues.joined(separator: ", "))
            }
            GridRow {
                Text("Title").foregroundStyle(.secondary)
                Text(output.process.title)
            }
            GridRow {
                Text("Note type").foregroundStyle(.secondary)
                Text(output.process.noteType)
            }
            GridRow {
                Text("Status").foregroundStyle(.secondary)
                Text(output.process.status)
            }
            GridRow {
                Text("Next action").foregroundStyle(.secondary)
                Text(output.process.suggestedNextAction)
            }
            GridRow {
                Text("Tags").foregroundStyle(.secondary)
                Text(output.process.tags.joined(separator: ", "))
            }
            GridRow {
                Text("Summary").foregroundStyle(.secondary)
                Text(output.summarize.summary)
            }
            GridRow {
                Text("Word count").foregroundStyle(.secondary)
                Text(String(output.summarize.wordCount))
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.runtimeStatus {
        case .ready: return .cyan
        case .unavailable: return .red
        case .starting: return .gray
        }
    }

    private var statusLabel: String {
        switch viewModel.runtimeStatus {
        case .ready: return "Ready"
        case .unavailable: return "Unavailable"
        case .starting: return "Starting…"
        }
    }
}

#Preview {
    let settings = AppSettings()
    ContentView()
        .environmentObject(settings)
        .environmentObject(AppStateViewModel(host: nil, workspaceId: settings.workspace))
}
