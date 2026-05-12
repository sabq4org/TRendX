package com.trendx.app.repositories

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

// Equivalent of the AuthSession + UserDefaults persistence in
// TRENDX/Repositories/AuthRepository.swift. We use Jetpack DataStore
// (preferences flavor) — on-disk async, survives process death, and
// flows naturally into ViewModel state via collectAsState.
@Serializable
data class AuthSession(
    val accessToken: String,
    val refreshToken: String? = null,
    val userId: String,
    val email: String
)

private val Context.dataStore by preferencesDataStore(name = "trendx_session")

class SessionStore(private val context: Context) {
    private val sessionKey = stringPreferencesKey("session_v1")
    private val userJsonKey = stringPreferencesKey("user_v1")

    val sessionFlow: Flow<AuthSession?> = context.dataStore.data.map { prefs ->
        prefs[sessionKey]?.let { runCatching { Json.decodeFromString<AuthSession>(it) }.getOrNull() }
    }

    suspend fun currentSession(): AuthSession? = sessionFlow.first()

    suspend fun save(session: AuthSession) {
        context.dataStore.edit { prefs ->
            prefs[sessionKey] = Json.encodeToString(session)
        }
    }

    suspend fun clear() {
        context.dataStore.edit { prefs ->
            prefs.remove(sessionKey)
            prefs.remove(userJsonKey)
        }
    }

    suspend fun saveUserJson(json: String) {
        context.dataStore.edit { prefs -> prefs[userJsonKey] = json }
    }

    suspend fun cachedUserJson(): String? =
        context.dataStore.data.first()[userJsonKey]
}
