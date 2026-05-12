package com.trendx.app.models

import kotlinx.serialization.Serializable

// Mirrors TrendXUser in TRENDX/Models/Models.swift. Keep field names
// aligned (camelCase) — the Ktor JsonNamingStrategy.SnakeCase config
// handles the wire-format conversion automatically.
@Serializable
data class TrendXUser(
    val id: String,
    val name: String = "مستخدم",
    val email: String = "",
    val handle: String? = null,
    val bio: String? = null,
    val avatarInitial: String = "م",
    val avatarUrl: String? = null,
    val bannerUrl: String? = null,
    val accountType: AccountType = AccountType.individual,
    val isVerified: Boolean = false,
    val points: Int = 100,
    val coins: Double = 16.67,
    val followedTopics: List<String> = emptyList(),
    val completedPolls: List<String> = emptyList(),
    val isPremium: Boolean = false,
    val role: UserRole = UserRole.respondent,
    val tier: UserTier = UserTier.free,
    val gender: UserGender = UserGender.unspecified,
    val birthYear: Int? = null,
    val city: String? = null,
    val region: String? = null,
    val country: String = "SA",
    val followersCount: Int = 0,
    val followingCount: Int = 0,
    val viewerFollows: Boolean = false
)
