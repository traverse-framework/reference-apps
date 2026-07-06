package com.traverseframework.docapproval

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
import com.traverseframework.docapproval.ui.DocApprovalTheme
import com.traverseframework.docapproval.ui.MainScreen
import com.traverseframework.docapproval.ui.SettingsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val settings = SettingsRepository(applicationContext)
        setContent {
            DocApprovalTheme {
                val navController = rememberNavController()
                val viewModel: ExecutionViewModel = viewModel(
                    factory = ExecutionViewModelFactory(TraverseClient(), settings),
                )
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()

                NavHost(navController = navController, startDestination = "main") {
                    composable("main") {
                        MainScreen(
                            uiState = uiState,
                            onDocumentChange = viewModel::updateDocument,
                            onSubmit = viewModel::submit,
                            onReset = viewModel::reset,
                            onOpenSettings = { navController.navigate("settings") },
                            onTraceToggle = viewModel::toggleTrace,
                        )
                    }
                    composable("settings") {
                        SettingsScreen(
                            settings = settings,
                            currentBaseUrl = uiState.baseUrl,
                            currentWorkspace = uiState.workspace,
                            onBack = { navController.popBackStack() },
                        )
                    }
                }
            }
        }
    }
}
