package com.traverseframework.meetingnotes

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.traverseframework.meetingnotes.ui.MainScreen
import com.traverseframework.meetingnotes.ui.MeetingNotesTheme
import com.traverseframework.meetingnotes.ui.SettingsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val settings = SettingsRepository(applicationContext)
        val bundleRoot = BundleAssets.materialize(applicationContext)
        val host: MeetingNotesHost = ProductionMeetingNotesHost.createOrNull(bundleRoot)
            ?: UnavailableMeetingNotesHost
        setContent {
            MeetingNotesTheme {
                val navController = rememberNavController()
                val viewModel: ExecutionViewModel = viewModel(
                    factory = ExecutionViewModelFactory(host, settings),
                )
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()

                NavHost(navController = navController, startDestination = "main") {
                    composable("main") {
                        MainScreen(
                            uiState = uiState,
                            onTranscriptChange = viewModel::updateTranscript,
                            onSubmit = viewModel::submit,
                            onReset = viewModel::reset,
                            onOpenSettings = { navController.navigate("settings") },
                            onTraceToggle = viewModel::toggleTrace,
                        )
                    }
                    composable("settings") {
                        SettingsScreen(
                            settings = settings,
                            currentWorkspace = uiState.workspace,
                            onBack = { navController.popBackStack() },
                        )
                    }
                }
            }
        }
    }
}

/** Fallback when the digest-pinned runtime bundle is missing from assets. */
object UnavailableMeetingNotesHost : MeetingNotesHost {
    override val runtimeMode: String = AppConstants.RUNTIME_MODE_EMBEDDED
    override val isReady: Boolean = false
    override fun submitTranscript(transcript: String): HostRunResult =
        HostRunResult("", null, emptyList(), "embedded runtime unavailable - sync the app bundle")
}
