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
                    Text("Embedded")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sidebar: some View {
        List {
            Section("Runtime") {
                LabeledContent("Status", value: statusLabel)
                LabeledContent("Mode", value: "Embedded")
                LabeledContent("Workspace", value: settings.workspace)
                LabeledContent("App", value: AppSettings.appId)
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
                    Text("Runtime unavailable — check bundle resources.")
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
                        Text("Submit a document above to start analysis (⌘↩).")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Analyzing…")
                case "error":
                    Text("Error: \(viewModel.errorMessage ?? "execution failed")")
                        .foregroundStyle(.red)
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
        targetOutput: DocApprovalOutput(
            analysis: AnalysisOutput(
                docType: "nda", parties: ["A", "B"], amounts: ["$1"],
                confidence: "high", recommendation: "approve"
            ),
            recommendation: RecommendationOutput(
                recommendation: "approve", rationale: "Policy match", confidence: "high"
            )
        )
    )
    ContentView()
        .environmentObject(settings)
        .environmentObject(AppStateViewModel(
            host: host,
            appId: AppSettings.appId,
            documentMaxLength: AppSettings.documentMaxLength
        ))
}
