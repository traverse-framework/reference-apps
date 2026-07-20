package com.traverseframework.docapproval

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

class ExecutionViewModelFactory(
    private val host: DocApprovalHost,
    private val settings: RuntimeSettings,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(ExecutionViewModel::class.java)) {
            return ExecutionViewModel(host, settings) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
