import SwiftUI
import DocApprovalCore

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
        GroupBox("Submit Document") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.document)
                    .font(.body)
                    .frame(minHeight: 140)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                Text("\(viewModel.document.count)/\(AppSettings.documentMaxLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(viewModel.isRunning ? "Analyzing…" : "Analyze Document") { viewModel.submit() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(!viewModel.canSubmit)
                    Button("Reset") { viewModel.resetLocal() }
                        .keyboardShortcut("r", modifiers: .command)
                }
                if viewModel.runtimeStatus == .unavailable {
                    Text("Embedded runtime unavailable — run scripts/ci/sync_swift_doc_approval_bundle.sh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var outputSection: some View {
        GroupBox("Analysis Result") {
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
                        Text("Submit a document above to start analysis (⌘↩).")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Analyzing…")
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

    private func outputFields(_ output: DocApprovalOutput) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("Analysis").font(.headline)
                Text("")
            }
            GridRow {
                Text("Document type").foregroundStyle(.secondary)
                Text(output.analysis.docType)
            }
            GridRow {
                Text("Analyze recommendation").foregroundStyle(.secondary)
                Text(output.analysis.recommendation)
            }
            GridRow {
                Text("Analyze confidence").foregroundStyle(.secondary)
                Text(output.analysis.confidence)
            }
            GridRow {
                Text("Parties").foregroundStyle(.secondary)
                Text(output.analysis.parties.isEmpty ? "None" : output.analysis.parties.joined(separator: ", "))
            }
            GridRow {
                Text("Amounts").foregroundStyle(.secondary)
                Text(output.analysis.amounts.isEmpty ? "None" : output.analysis.amounts.joined(separator: ", "))
            }
            GridRow {
                Text("Recommendation").font(.headline)
                Text("")
            }
            GridRow {
                Text("Decision").foregroundStyle(.secondary)
                Text(output.recommendation.recommendation)
            }
            GridRow {
                Text("Rationale").foregroundStyle(.secondary)
                Text(output.recommendation.rationale)
            }
            GridRow {
                Text("Confidence").foregroundStyle(.secondary)
                Text(output.recommendation.confidence)
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
