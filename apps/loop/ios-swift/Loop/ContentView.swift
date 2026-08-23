import SwiftUI
import LoopCore

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
            .navigationTitle("loop")
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
                Text(viewModel.runtimeMode)
                    .font(.headline)
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusLabel)
                    Spacer()
                }
                Text("workspace: \(settings.workspace)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("workflow: \(viewModel.workflowId)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var inputSection: some View {
        GroupBox("Submit Transcript") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.transcript)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                Text("\(viewModel.transcript.count)/\(AppSettings.transcriptMaxLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { viewModel.submit() }) {
                    Text(viewModel.isRunning ? "Processing…" : "Process Transcript")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)
                if viewModel.runtimeStatus == .unavailable {
                    Text("Embedded runtime unavailable — run scripts/ci/sync_swift_loop_bundle.sh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var outputSection: some View {
        GroupBox("Loop Output") {
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
                        Text("Submit a transcript above to run loop.wf1.")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Processing…")
                case "error":
                    Text("Error: \(viewModel.errorMessage ?? "execution failed")")
                        .foregroundStyle(.red)
                    Button("Reset") { viewModel.resetLocal() }
                        .buttonStyle(.bordered)
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

    private func outputFields(_ output: LoopOutput) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            labeledField("Summary", output.summary.isEmpty ? "None recorded" : output.summary)
            sectionList("Action Items") {
                if output.actionItems.isEmpty {
                    Text("None recorded").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(output.actionItems.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("• \(item.task)")
                            HStack(spacing: 8) {
                                if let owner = item.owner { Text(owner).font(.caption).foregroundStyle(.secondary) }
                                if let due = item.due { Text("due \(due)").font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
            }
            sectionList("Decisions") {
                if output.decisions.isEmpty {
                    Text("None recorded").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(output.decisions.enumerated()), id: \.offset) { _, item in
                        Text("• \(item.text)\(item.madeBy.map { " — decided by \($0)" } ?? "")")
                    }
                }
            }
            sectionList("Follow-ups") {
                if output.followUps.isEmpty {
                    Text("None recorded").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(output.followUps.enumerated()), id: \.offset) { _, item in
                        Text("• \(item)")
                    }
                }
            }
        }
    }

    private func labeledField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
        }
    }

    private func sectionList<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            content()
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
