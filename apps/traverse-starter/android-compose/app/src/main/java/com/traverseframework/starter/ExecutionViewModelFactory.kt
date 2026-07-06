package com.traverseframework.starter

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

class ExecutionViewModelFactory(
    private val client: TraverseClient,
    private val settings: RuntimeSettings,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(ExecutionViewModel::class.java)) {
            return ExecutionViewModel(client, settings) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
