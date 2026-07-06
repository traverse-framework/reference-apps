package com.traverseframework.starter.ui

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
import com.traverseframework.starter.AppConstants
import com.traverseframework.starter.SettingsRepository
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    settings: RuntimeSettings,
    currentBaseUrl: String,
    currentWorkspace: String,
    onBack: () -> Unit,
) {
    var baseUrl by remember(currentBaseUrl) { mutableStateOf(currentBaseUrl) }
    var workspace by remember(currentWorkspace) { mutableStateOf(currentWorkspace) }
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Runtime settings")
        OutlinedTextField(
            value = baseUrl,
            onValueChange = { baseUrl = it },
            label = { Text("Runtime URL") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = workspace,
            onValueChange = { workspace = it },
            label = { Text("Workspace") },
            modifier = Modifier.fillMaxWidth(),
        )
        Text("Emulator default: ${AppConstants.DEFAULT_BASE_URL} (host loopback)")
        Button(
            onClick = {
                scope.launch {
                    settings.setBaseUrl(baseUrl.trim())
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
