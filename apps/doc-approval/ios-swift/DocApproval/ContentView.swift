import SwiftUI
import DocApprovalCore

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
            .navigationTitle("doc-approval")
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
                Text("app: \(AppSettings.appId)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var inputSection: some View {
        GroupBox("Submit Document") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.document)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                Text("\(viewModel.document.count)/\(AppSettings.documentMaxLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { viewModel.submit() }) {
                    Text(viewModel.isRunning ? "Analyzing…" : "Analyze Document")
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
        GroupBox("Analysis Result") {
            VStack(alignment: .leading, spacing: 12) {
                if let error = viewModel.errorMessage, viewModel.currentState != "results" {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }

                switch viewModel.currentState {
                case "idle":
                    if viewModel.runtimeStatus == .offline {
                        Text("Connect to the Traverse runtime to see analysis output here.")
                            .foregroundStyle(.secondary)
                    } else if viewModel.submitting {
                        Text("Submitting command…")
                    } else if viewModel.errorMessage == nil {
                        Text("Submit a document above to start analysis.")
                            .foregroundStyle(.secondary)
                    }
                case "processing":
                    Text("Analyzing…")
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

    private func outputFields(_ output: DocApprovalOutput) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledField("Document type", output.docType)
            labeledField("Recommendation", output.recommendation)
            labeledField("Confidence", formatConfidence(output.confidence))
            labeledField("Parties", output.parties.isEmpty ? "None" : output.parties.joined(separator: ", "))
            labeledField("Amounts", output.amounts.isEmpty ? "None" : output.amounts.joined(separator: ", "))
        }
    }

    private func formatConfidence(_ value: Double) -> String {
        if value >= 0 && value <= 1 {
            return "\(Int((value * 100).rounded()))%"
        }
        return String(value)
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
        .environmentObject(AppStateViewModel(
            client: DocApprovalClient(),
            baseURL: settings.baseURL,
            workspaceId: settings.workspace
        ))
}
