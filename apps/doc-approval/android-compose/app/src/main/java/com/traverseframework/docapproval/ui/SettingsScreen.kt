package com.traverseframework.docapproval.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.traverseframework.docapproval.RuntimeSettings
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    settings: RuntimeSettings,
    currentWorkspace: String,
    onBack: () -> Unit,
) {
    var workspace by remember(currentWorkspace) { mutableStateOf(currentWorkspace) }
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Embedded runtime settings")
        Text("Runtime mode is Embedded — no HTTP sidecar URL.")
        OutlinedTextField(
            value = workspace,
            onValueChange = { workspace = it },
            label = { Text("Workspace") },
            modifier = Modifier.fillMaxWidth(),
        )
        Button(
            onClick = {
                scope.launch {
                    settings.setWorkspace(workspace.trim())
                    onBack()
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Save")
        }
    }
}
