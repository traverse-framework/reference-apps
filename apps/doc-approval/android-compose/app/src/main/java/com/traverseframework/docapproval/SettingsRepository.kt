package com.traverseframework.docapproval

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

interface RuntimeSettings {
    val baseUrl: Flow<String>
    val workspace: Flow<String>
    suspend fun setBaseUrl(url: String)
    suspend fun setWorkspace(workspace: String)
}

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "doc_approval_settings")

class SettingsRepository(private val context: Context) : RuntimeSettings {
    private val baseUrlKey = stringPreferencesKey("runtime_base_url")
    private val workspaceKey = stringPreferencesKey("workspace")

    override val baseUrl: Flow<String> = context.settingsDataStore.data.map { prefs ->
        prefs[baseUrlKey] ?: AppConstants.DEFAULT_BASE_URL
    }

    override val workspace: Flow<String> = context.settingsDataStore.data.map { prefs ->
        prefs[workspaceKey] ?: AppConstants.DEFAULT_WORKSPACE
    }

    override suspend fun setBaseUrl(url: String) {
        context.settingsDataStore.edit { it[baseUrlKey] = url }
    }

    override suspend fun setWorkspace(workspace: String) {
        context.settingsDataStore.edit { it[workspaceKey] = workspace }
    }
}
