package com.traverseframework.starter

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

interface RuntimeSettings {
    val workspace: Flow<String>
    suspend fun setWorkspace(workspace: String)
}

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "traverse_settings")

class SettingsRepository(private val context: Context) : RuntimeSettings {
    private val workspaceKey = stringPreferencesKey("workspace")

    override val workspace: Flow<String> = context.settingsDataStore.data.map { prefs ->
        prefs[workspaceKey] ?: AppConstants.DEFAULT_WORKSPACE
    }

    override suspend fun setWorkspace(workspace: String) {
        context.settingsDataStore.edit { it[workspaceKey] = workspace }
    }
}
