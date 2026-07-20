import SwiftUI
import TraverseCore

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var viewModel: AppStateViewModel
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
        GroupBox("Runtime") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusLabel)
                    Spacer()
                }
                Text("Mode: Embedded")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("workspace: \(settings.workspace)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("app: \(AppSettings.appId)")
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
                if viewModel.runtimeStatus == .unavailable {
                    Text("Runtime unavailable — check bundle resources.")
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
                if let error = viewModel.errorMessage, viewModel.currentState != "results" {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }

                switch viewModel.currentState {
                case "idle":
                    if viewModel.runtimeStatus == .unavailable {
                        Text("Runtime unavailable — check bundle resources.")
                            .foregroundStyle(.secondary)
                    } else if viewModel.submitting {
                        Text("Submitting…")
                    } else if viewModel.errorMessage == nil {
                        Text("Submit a note above to start a workflow.")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Processing…")
                case "error":
                    Text("Error: \(viewModel.errorMessage ?? "execution failed")")
                        .foregroundStyle(.red)
                    Button("Reset") { viewModel.resetLocal() }
                        .buttonStyle(.bordered)
                case "results":
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
                    Button("Reset") { viewModel.resetLocal() }
                        .buttonStyle(.bordered)
                default:
                    Text("State: \(viewModel.currentState)")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func outputFields(_ output: TraverseStarterOutput) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledField("Valid", output.validate.valid ? "yes" : "no")
            labeledField(
                "Issues",
                output.validate.issues.isEmpty ? "None" : output.validate.issues.joined(separator: ", ")
            )
            labeledField("Title", output.process.title)
            labeledField("Note type", output.process.noteType)
            labeledField("Status", output.process.status)
            labeledField("Suggested next action", output.process.suggestedNextAction)
            labeledField("Tags", output.process.tags.joined(separator: ", "))
            labeledField("Summary", output.summarize.summary)
            labeledField("Word count", String(output.summarize.wordCount))
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
        case .ready: return .cyan
        case .unavailable: return .red
        }
    }

    private var statusLabel: String {
        switch viewModel.runtimeStatus {
        case .ready: return "Ready"
        case .unavailable: return "Unavailable"
        }
    }
}

#Preview {
    let settings = AppSettings()
    let host = try? EmbeddedRuntime.makeTestHost(
        targetOutput: TraverseStarterOutput(
            validate: ValidateOutput(valid: true, issues: []),
            process: ProcessOutput(title: "Preview", tags: [], noteType: "note", suggestedNextAction: "n/a", status: "done"),
            summarize: SummarizeOutput(summary: "A preview summary", wordCount: 3)
        )
    )
    ContentView()
        .environmentObject(settings)
        .environmentObject(AppStateViewModel(
            host: host,
            appId: AppSettings.appId,
            noteMaxLength: AppSettings.noteMaxLength
        ))
}
