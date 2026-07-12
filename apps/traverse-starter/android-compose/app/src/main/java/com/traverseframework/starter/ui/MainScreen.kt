package com.traverseframework.starter.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.traverseframework.starter.ExecutionPhase
import com.traverseframework.starter.ExecutionUiState
import com.traverseframework.starter.RuntimeStatus
import com.traverseframework.starter.TraverseStarterOutput

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    uiState: ExecutionUiState,
    onNoteChange: (String) -> Unit,
    onSubmit: () -> Unit,
    onReset: () -> Unit,
    onOpenSettings: () -> Unit,
    onTraceToggle: (Boolean) -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("traverse-starter") },
                actions = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(end = 12.dp),
                    ) {
                        StatusDot(uiState.runtimeStatus)
                        Text(
                            text = statusLabel(uiState.runtimeStatus),
                            style = MaterialTheme.typography.labelMedium,
                            modifier = Modifier.padding(start = 8.dp),
                        )
                        Button(onClick = onOpenSettings, modifier = Modifier.padding(start = 8.dp)) {
                            Text("Settings")
                        }
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            RuntimeCard(uiState)
            InputCard(uiState, onNoteChange, onSubmit)
            OutputCard(uiState, onReset, onTraceToggle)
        }
    }
}

@Composable
private fun RuntimeCard(uiState: ExecutionUiState) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Runtime Environment", style = MaterialTheme.typography.titleMedium)
            Text(uiState.baseUrl, style = MaterialTheme.typography.bodySmall)
            Text("workspace: ${uiState.workspace}", style = MaterialTheme.typography.bodySmall)
            Text("capability: ${com.traverseframework.starter.AppConstants.CAPABILITY_ID}", style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun InputCard(
    uiState: ExecutionUiState,
    onNoteChange: (String) -> Unit,
    onSubmit: () -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Start Workflow", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = uiState.note,
                onValueChange = onNoteChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(140.dp),
                placeholder = { Text("Enter a note…") },
            )
            Text("${uiState.note.length}/${com.traverseframework.starter.AppConstants.NOTE_MAX_LENGTH}")
            Button(onClick = onSubmit, enabled = uiState.canSubmit, modifier = Modifier.fillMaxWidth()) {
                Text(if (uiState.isRunning) "Running…" else "Start Workflow")
            }
            if (uiState.runtimeStatus == RuntimeStatus.Offline) {
                Text(
                    "Runtime offline — start with cargo run -p traverse-cli -- serve",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun OutputCard(
    uiState: ExecutionUiState,
    onReset: () -> Unit,
    onTraceToggle: (Boolean) -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Execution Output", style = MaterialTheme.typography.titleMedium)
            when (val phase = uiState.phase) {
                ExecutionPhase.Idle -> {
                    Text(
                        if (uiState.runtimeStatus == RuntimeStatus.Offline) {
                            "Connect to the Traverse runtime to see workflow output here."
                        } else {
                            "Submit a note above to start a workflow."
                        },
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
                ExecutionPhase.Loading -> Text("Starting execution…")
                is ExecutionPhase.Polling -> Text("Polling execution ${phase.executionId}…")
                is ExecutionPhase.Failed -> Text("Error: ${phase.error}", color = MaterialTheme.colorScheme.error)
                is ExecutionPhase.Succeeded -> {
                    OutputFields(phase.output)
                    if (phase.trace.isNotEmpty()) {
                        Button(onClick = { onTraceToggle(!uiState.showTrace) }) {
                            Text("Trace (${phase.trace.size} events)")
                        }
                        if (uiState.showTrace) {
                            phase.trace.forEach { event ->
                                Text("${event.timestamp} · ${event.event_type}", style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                    Button(onClick = onReset) { Text("Reset") }
                }
            }
        }
    }
}

@Composable
private fun OutputFields(output: TraverseStarterOutput) {
    Field("Valid", if (output.validate.valid) "yes" else "no")
    Field("Issues", output.validate.issues.joinToString(", ").ifEmpty { "None" })
    Field("Title", output.process.title)
    Field("Note type", output.process.noteType)
    Field("Status", output.process.status)
    Field("Next action", output.process.suggestedNextAction)
    Field("Tags", output.process.tags.joinToString(", "))
    Field("Summary", output.summarize.summary)
    Field("Word count", output.summarize.wordCount.toString())
}

@Composable
private fun Field(label: String, value: String) {
    Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    Text(value)
    Spacer(modifier = Modifier.height(4.dp))
}

@Composable
private fun StatusDot(status: RuntimeStatus) {
    val color = when (status) {
        RuntimeStatus.Online -> Color(0xFF06B6D4)
        RuntimeStatus.Offline -> Color(0xFFEF4444)
        RuntimeStatus.Checking -> Color.Gray
    }
    Box(
        modifier = Modifier
            .size(10.dp)
            .clip(CircleShape)
            .background(color),
    )
}

private fun statusLabel(status: RuntimeStatus): String = when (status) {
    RuntimeStatus.Online -> "Online"
    RuntimeStatus.Offline -> "Offline"
    RuntimeStatus.Checking -> "Checking…"
}
