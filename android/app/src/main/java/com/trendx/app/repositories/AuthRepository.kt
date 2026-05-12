package com.trendx.app.repositories

import com.trendx.app.models.TrendXUser
import com.trendx.app.models.UserGender
import com.trendx.app.networking.AuthCredentials
import com.trendx.app.networking.AuthResponse
import com.trendx.app.networking.HandleCheckResponse
import com.trendx.app.networking.SignUpPayload
import com.trendx.app.networking.TrendXAPIClient
import com.trendx.app.networking.UserDto
import io.ktor.http.encodeURLParameter

// Mirrors TRENDX/Repositories/AuthRepository.swift. When the backend isn't
// configured (rare on Android — BuildConfig sets it at build time), we
// synthesize a local session so screens can still render with samples.
class AuthRepository(
    private val client: TrendXAPIClient,
    private val sessionStore: SessionStore
) {
    val isRemoteEnabled: Boolean get() = client.config.isConfigured

    suspend fun restoreSession(): AuthSession? = sessionStore.currentSession()

    suspend fun signIn(email: String, password: String): AuthSession {
        if (!isRemoteEnabled) {
            return localSession(email).also { sessionStore.save(it) }
        }
        val response: AuthResponse = client.post(
            "/auth/signin",
            body = AuthCredentials(email, password)
        )
        return response.toSession().also { sessionStore.save(it) }
    }

    suspend fun signUp(
        name: String,
        email: String,
        password: String,
        gender: UserGender = UserGender.unspecified,
        birthYear: Int? = null,
        city: String? = null,
        region: String? = null,
        osVersion: String? = null
    ): AuthSession {
        if (!isRemoteEnabled) {
            return localSession(email).also { sessionStore.save(it) }
        }
        val response: AuthResponse = client.post(
            "/auth/signup",
            body = SignUpPayload(
                name = name,
                email = email,
                password = password,
                gender = gender.name,
                birthYear = birthYear,
                city = city,
                region = region,
                osVersion = osVersion
            )
        )
        return response.toSession().also { sessionStore.save(it) }
    }

    suspend fun signOut() = sessionStore.clear()

    suspend fun fetchProfile(session: AuthSession): TrendXUser {
        val dto: UserDto = client.get("/profile", accessToken = session.accessToken)
        return dto.toDomain()
    }

    /// POST `/profile` with the editable subset of fields. Backend reads
    /// snake_case (the Json naming strategy converts automatically). All
    /// fields are optional — only the ones the user actually changed are
    /// sent, blank strings are normalized to empty strings (the backend
    /// treats them the same as null on PATCH-style updates).
    suspend fun updateProfile(
        name: String? = null,
        email: String? = null,
        handle: String? = null,
        bio: String? = null,
        avatarUrl: String? = null,
        bannerUrl: String? = null,
        accountType: String? = null,
        gender: String? = null,
        birthYear: Int? = null,
        city: String? = null,
        country: String? = null,
        session: AuthSession
    ): TrendXUser {
        val payload = ProfileUpdatePayload(
            name = name,
            email = email,
            handle = handle,
            bio = bio,
            avatarUrl = avatarUrl,
            bannerUrl = bannerUrl,
            accountType = accountType,
            gender = gender,
            birthYear = birthYear,
            city = city,
            country = country
        )
        val dto: UserDto = client.post(
            path = "/profile",
            body = payload,
            accessToken = session.accessToken
        )
        return dto.toDomain()
    }

    suspend fun checkHandleAvailability(candidate: String, session: AuthSession): String? {
        val escaped = candidate.encodeURLParameter()
        val response: HandleCheckResponse = client.get(
            "/handles/check?handle=$escaped",
            accessToken = session.accessToken
        )
        return if (response.ok) null else (response.message ?: "هذا المعرّف غير متاح.")
    }

    private fun AuthResponse.toSession() = AuthSession(
        accessToken = accessToken.orEmpty(),
        refreshToken = refreshToken,
        userId = user.id,
        email = user.email.orEmpty()
    )

    private fun localSession(email: String) = AuthSession(
        accessToken = "local-beta-token",
        refreshToken = null,
        userId = "00000000-0000-0000-0000-000000000001",
        email = email
    )
}

@kotlinx.serialization.Serializable
private data class ProfileUpdatePayload(
    val name: String? = null,
    val email: String? = null,
    val handle: String? = null,
    val bio: String? = null,
    val avatarUrl: String? = null,
    val bannerUrl: String? = null,
    val accountType: String? = null,
    val gender: String? = null,
    val birthYear: Int? = null,
    val city: String? = null,
    val country: String? = null
)
