package com.trendx.app.networking

import com.trendx.app.models.AccountType
import com.trendx.app.models.TrendXUser
import com.trendx.app.models.UserGender
import com.trendx.app.models.UserRole
import com.trendx.app.models.UserTier
import kotlinx.serialization.Serializable

// Wire-format DTOs. Kept separate from domain types so handlers can evolve
// without rippling into UI code. SnakeCase → camelCase conversion happens
// automatically thanks to the Json naming strategy on TrendXAPIClient.

@Serializable
data class AuthCredentials(val email: String, val password: String)

@Serializable
data class SignUpPayload(
    val name: String,
    val email: String,
    val password: String,
    val gender: String = "unspecified",
    val birthYear: Int? = null,
    val city: String? = null,
    val region: String? = null,
    val deviceType: String = "android",
    val osVersion: String? = null
)

@Serializable
data class AuthResponse(
    val accessToken: String? = null,
    val refreshToken: String? = null,
    val user: AuthUser
)

@Serializable
data class AuthUser(
    val id: String,
    val email: String? = null
)

@Serializable
data class UserDto(
    val id: String,
    val name: String? = null,
    val email: String? = null,
    val handle: String? = null,
    val bio: String? = null,
    val avatarInitial: String? = null,
    val avatarUrl: String? = null,
    val bannerUrl: String? = null,
    val accountType: String? = null,
    val isVerified: Boolean = false,
    val points: Int = 0,
    val coins: Double = 0.0,
    val followedTopics: List<String> = emptyList(),
    val completedPolls: List<String> = emptyList(),
    val isPremium: Boolean = false,
    val role: String? = null,
    val tier: String? = null,
    val gender: String? = null,
    val birthYear: Int? = null,
    val city: String? = null,
    val region: String? = null,
    val country: String? = null,
    val followersCount: Int = 0,
    val followingCount: Int = 0,
    val viewerFollows: Boolean = false
) {
    fun toDomain(): TrendXUser = TrendXUser(
        id = id,
        name = name ?: "مستخدم",
        email = email.orEmpty(),
        handle = handle,
        bio = bio,
        avatarInitial = avatarInitial ?: (name?.take(1) ?: "م"),
        avatarUrl = avatarUrl,
        bannerUrl = bannerUrl,
        accountType = accountType?.let { runCatching { AccountType.valueOf(it) }.getOrNull() }
            ?: AccountType.individual,
        isVerified = isVerified,
        points = points,
        coins = coins,
        followedTopics = followedTopics,
        completedPolls = completedPolls,
        isPremium = isPremium,
        role = role?.let { runCatching { UserRole.valueOf(it) }.getOrNull() } ?: UserRole.respondent,
        tier = tier?.let { runCatching { UserTier.valueOf(it) }.getOrNull() } ?: UserTier.free,
        gender = gender?.let { runCatching { UserGender.valueOf(it) }.getOrNull() } ?: UserGender.unspecified,
        birthYear = birthYear,
        city = city,
        region = region,
        country = country ?: "SA",
        followersCount = followersCount,
        followingCount = followingCount,
        viewerFollows = viewerFollows
    )
}

@Serializable
data class HandleCheckResponse(
    val ok: Boolean,
    val reason: String? = null,
    val message: String? = null
)

// ---- Poll wire formats ----
//
// Mirrors PollDTO / PollOptionDTO / TopicDTO from
// TRENDX/Repositories/PollRepository.swift. Keep field names camelCase —
// the Json naming strategy converts to snake_case on the wire.

@Serializable
data class PollOptionDto(
    val id: String,
    val text: String,
    val votesCount: Int = 0,
    val percentage: Double = 0.0
) {
    fun toDomain(): com.trendx.app.models.PollOption =
        com.trendx.app.models.PollOption(id, text, votesCount, percentage)
}

@Serializable
data class TopicDto(
    val id: String,
    val name: String,
    val icon: String,
    val color: String? = null,
    val followersCount: Int = 0,
    val postsCount: Int = 0,
    val isFollowing: Boolean = false
) {
    fun toDomain(): com.trendx.app.models.Topic =
        com.trendx.app.models.Topic(
            id = id,
            name = name,
            icon = icon,
            color = color ?: "blue",
            followersCount = followersCount,
            postsCount = postsCount,
            isFollowing = isFollowing
        )
}

@Serializable
data class PollDto(
    val id: String,
    val title: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val coverStyle: String? = null,
    val authorName: String? = null,
    val authorAvatar: String? = null,
    val authorAvatarUrl: String? = null,
    val authorIsVerified: Boolean = false,
    val options: List<PollOptionDto> = emptyList(),
    val topicId: String? = null,
    val topicName: String? = null,
    val type: String? = null,
    val status: String? = null,
    val totalVotes: Int = 0,
    val rewardPoints: Int = 50,
    val durationDays: Int = 7,
    val createdAt: String? = null,
    val expiresAt: String? = null,
    val userVotedOptionId: String? = null,
    val isBookmarked: Boolean = false,
    val totalShares: Int = 0,
    val totalViews: Int = 0,
    val totalSaves: Int = 0,
    val authorAccountType: String? = null,
    val authorHandle: String? = null,
    val publisherId: String? = null,
    val voterAudience: String = "public",
    val viewerReposted: Boolean = false,
    val aiInsight: String? = null
) {
    fun toDomain(): com.trendx.app.models.Poll {
        val now = kotlinx.datetime.Clock.System.now()
        val created = createdAt?.let { runCatching { kotlinx.datetime.Instant.parse(it) }.getOrNull() } ?: now
        val expires = expiresAt?.let { runCatching { kotlinx.datetime.Instant.parse(it) }.getOrNull() }
            ?: created.plus(kotlin.time.Duration.parse("${durationDays}d"))
        return com.trendx.app.models.Poll(
            id = id,
            title = title,
            description = description,
            imageUrl = imageUrl,
            coverStyle = coverStyle?.let {
                runCatching { com.trendx.app.theme.PollCoverStyle.valueOf(it.replaceFirstChar { c -> c.uppercase() }) }
                    .getOrNull()
            },
            authorName = authorName ?: "TrendX User",
            authorAvatar = authorAvatar ?: "T",
            authorAvatarUrl = authorAvatarUrl,
            authorIsVerified = authorIsVerified,
            options = options.map { it.toDomain() },
            topicId = topicId,
            topicName = topicName,
            type = com.trendx.app.models.PollType.fromRaw(type),
            status = com.trendx.app.models.PollStatus.fromRaw(status),
            totalVotes = totalVotes,
            rewardPoints = rewardPoints,
            durationDays = durationDays,
            createdAt = created,
            expiresAt = expires,
            userVotedOptionId = userVotedOptionId,
            isBookmarked = isBookmarked,
            sharesCount = totalShares,
            viewsCount = totalViews,
            savesCount = totalSaves,
            authorAccountType = authorAccountType?.let {
                runCatching { com.trendx.app.models.AccountType.valueOf(it) }.getOrNull()
            } ?: com.trendx.app.models.AccountType.individual,
            authorHandle = authorHandle?.takeIf { it.isNotBlank() },
            publisherId = publisherId,
            voterAudience = voterAudience,
            viewerReposted = viewerReposted,
            aiInsight = aiInsight
        )
    }
}

@Serializable
data class BootstrapResponse(
    val topics: List<TopicDto> = emptyList(),
    val polls: List<PollDto> = emptyList()
)

@Serializable
data class VoteRequest(
    val pollId: String,
    val optionId: String,
    val isPublic: Boolean = false,
    val secondsToVote: Int? = null
)

@Serializable
data class VoteResponse(
    val poll: PollDto,
    val user: UserDto? = null,
    val insight: String? = null
)

@Serializable
data class RepostResponse(
    val ok: Boolean = true,
    val repostsCount: Int? = null
)

// ---- Account / social-graph wire formats ----

@Serializable
data class LedgerEntryDto(
    val id: String,
    val userId: String,
    val amount: Int,
    val type: String,
    val refType: String? = null,
    val refId: String? = null,
    val description: String? = null,
    val balanceAfter: Int = 0,
    val createdAt: String? = null
)

@Serializable
data class FollowListResponse(val items: List<UserDto> = emptyList())

@Serializable
data class FollowMutationResponse(
    val ok: Boolean = true,
    val followersCount: Int? = null,
    val followingCount: Int? = null
)

/// Mirrors the response from `GET /users/:idOrHandle/posts`. Each item is
/// either a poll the user authored or a poll they reposted; the wrapper
/// shape is identical to the iOS `ProfileActivity` enum.
@Serializable
data class UserPostsResponse(val items: List<UserPostItemDto> = emptyList())

@Serializable
data class UserPostItemDto(
    val kind: String,             // "poll" or "repost"
    val id: String,
    val occurredAt: String? = null,
    val poll: PollDto,
    val caption: String? = null
)

// ---- Intelligence layer (Pulse / DNA / Index / Accuracy / Challenge / Notifications) ----

@Serializable
data class PulseOptionDto(
    val index: Int,
    val text: String,
    val votes: Int = 0,
    val percentage: Double = 0.0
)

@Serializable
data class DailyPulseDto(
    val id: String,
    val pulseDate: String,
    val question: String,
    val description: String? = null,
    val options: List<PulseOptionDto> = emptyList(),
    val totalResponses: Int = 0,
    val status: String = "open",
    val closesAt: String,
    val rewardPoints: Int = 0,
    val topicId: String? = null,
    val aiSummary: String? = null,
    val userResponded: Boolean? = null,
    val userChoice: Int? = null
)

@Serializable
data class UserStreakDto(
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val totalPulses: Int = 0,
    val freezesLeft: Int = 0,
    val lastPulseDate: String? = null,
    val status: String? = null,
    val isPersonalBest: Boolean? = null,
    val delta: String? = null
)

@Serializable
data class PulseRespondRequest(
    val optionIndex: Int,
    val predictedPct: Int? = null
)

@Serializable
data class PulseResponseDto(
    val pulse: DailyPulseDto,
    val reward: Int = 0,
    val streak: UserStreakDto,
    val predictionScore: Int? = null
)

@Serializable
data class PulseYesterdayDto(val pulse: DailyPulseDto? = null)

@Serializable
data class DnaAxisDto(
    val key: String,
    val labelHigh: String,
    val labelLow: String,
    val score: Int
)

@Serializable
data class DnaArchetypeDto(val title: String, val blurb: String)

@Serializable
data class OpinionDnaDto(
    val computedAt: String,
    val sampleSize: Int = 0,
    val axes: List<DnaAxisDto> = emptyList(),
    val archetype: DnaArchetypeDto,
    val shareCaption: String
)

@Serializable
data class IndexMetricDto(
    val slug: String,
    val name: String,
    val value: Int,
    val change24h: Int = 0,
    val direction: String = "flat",
    val sampleSize: Int = 0,
    val blurb: String
)

@Serializable
data class TrendXIndexDto(
    val computedAt: String,
    val composite: Int,
    val compositeChange24h: Int = 0,
    val totalResponses: Int = 0,
    val metrics: List<IndexMetricDto> = emptyList()
)

@Serializable
data class UserAccuracyDto(
    val predictions: Int = 0,
    val scored: Int = 0,
    val averageAccuracy: Int = 0,
    val bestAccuracy: Int = 0,
    val rankPercentile: Int = 0
)

@Serializable
data class AccuracyLeaderItemDto(
    val userId: String,
    val name: String,
    val avatarInitial: String,
    val predictions: Int = 0,
    val averageAccuracy: Int = 0
)

@Serializable
data class AccuracyLeaderboardDto(val items: List<AccuracyLeaderItemDto> = emptyList())

@Serializable
data class MyChallengePredictionDto(
    val predictedPct: Int,
    val distance: Int? = null,
    val rank: Int? = null
)

@Serializable
data class WeeklyChallengeDto(
    val id: String,
    val weekStart: String,
    val question: String,
    val description: String? = null,
    val metricLabel: String,
    val closesAt: String,
    val status: String = "open",
    val targetPct: Int? = null,
    val rewardPoints: Int = 0,
    val totalPredictions: Int = 0,
    val myPrediction: MyChallengePredictionDto? = null
)

@Serializable
data class PredictRequest(val predictedPct: Int)

@Serializable
data class EmptyOk(val ok: Boolean = true)

@Serializable
data class NotificationDto(
    val id: String,
    val kind: String,
    val title: String,
    val body: String,
    val icon: String,
    val ctaLabel: String? = null,
    val ctaRoute: String? = null,
    val occurredAt: String,
    val refId: String? = null
)

@Serializable
data class NotificationsListDto(val items: List<NotificationDto> = emptyList())

// ---- Survey DTOs ----

@Serializable
data class SurveyQuestionOptionDto(
    val id: String,
    val text: String,
    val votesCount: Int = 0,
    val percentage: Double = 0.0,
    val displayOrder: Int = 0
)

@Serializable
data class SurveyQuestionDto(
    val id: String,
    val title: String,
    val description: String? = null,
    val type: String = "single_choice",
    val options: List<SurveyQuestionOptionDto> = emptyList(),
    val displayOrder: Int = 0,
    val rewardPoints: Int = 25,
    val isRequired: Boolean = true
)

@Serializable
data class SurveyDto(
    val id: String,
    val title: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val coverStyle: String? = null,
    val authorName: String? = null,
    val authorAvatar: String? = null,
    val authorAvatarUrl: String? = null,
    val authorIsVerified: Boolean = false,
    val authorAccountType: String? = null,
    val authorHandle: String? = null,
    val publisherId: String? = null,
    val questions: List<SurveyQuestionDto> = emptyList(),
    val topicName: String? = null,
    val totalResponses: Int = 0,
    val completionRate: Double = 0.0,
    val avgCompletionSeconds: Int = 180,
    val status: String = "active",
    val createdAt: String? = null,
    val expiresAt: String? = null,
    val rewardPoints: Int = 150
)

@Serializable
data class SurveyResponseAnswerRequest(
    val questionId: String,
    val optionId: String,
    val seconds: Int? = null
)

@Serializable
data class SurveyRespondRequest(
    val answers: List<SurveyResponseAnswerRequest>,
    val completionSeconds: Int? = null
)

@Serializable
data class SurveyCreateMetaRequest(
    val title: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val coverStyle: String? = null,
    val topicId: String? = null,
    val rewardPoints: Int? = null,
    val durationDays: Int? = null
)

@Serializable
data class SurveyCreateOptionRequest(val text: String)

@Serializable
data class SurveyCreateQuestionRequest(
    val title: String,
    val type: String = "single_choice",
    val rewardPoints: Int? = null,
    val options: List<SurveyCreateOptionRequest>
)

@Serializable
data class SurveyCreateRequest(
    val survey: SurveyCreateMetaRequest,
    val questions: List<SurveyCreateQuestionRequest>
)

@Serializable
data class SurveyCreateResponse(val survey: SurveyDto)

// ---- Poll create DTO ----

@Serializable
data class PollCreateOptionRequest(val text: String)

@Serializable
data class PollCreateRequest(
    val title: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val topicId: String? = null,
    val type: String = "single_choice",
    val durationDays: Int = 7,
    val options: List<PollCreateOptionRequest>
)

@Serializable
data class PollCreateResponse(val poll: PollDto)

// ---- Survey domain mapper ----

fun SurveyDto.toDomain(): com.trendx.app.models.Survey {
    val style = runCatching {
        coverStyle?.let { raw ->
            com.trendx.app.theme.PollCoverStyle.values().firstOrNull { it.rawValue == raw }
        }
    }.getOrNull()
        ?: com.trendx.app.theme.PollCoverStyle.fromTopic(topicName)

    val createdInstant = runCatching {
        createdAt?.let { kotlinx.datetime.Instant.parse(it) }
    }.getOrNull() ?: kotlinx.datetime.Clock.System.now()

    val expiresInstant = runCatching {
        expiresAt?.let { kotlinx.datetime.Instant.parse(it) }
    }.getOrNull() ?: createdInstant.plus(kotlin.time.Duration.parse("PT336H"))

    val accountType = runCatching {
        authorAccountType?.let { com.trendx.app.models.AccountType.valueOf(it) }
    }.getOrNull() ?: com.trendx.app.models.AccountType.individual

    val statusEnum = com.trendx.app.models.PollStatus.fromRaw(status)

    return com.trendx.app.models.Survey(
        id = id,
        title = title,
        description = description.orEmpty(),
        imageUrl = imageUrl,
        authorName = authorName ?: "TrendX Research",
        authorAvatar = authorAvatar ?: (authorName?.take(1) ?: "T"),
        authorAvatarUrl = authorAvatarUrl,
        authorIsVerified = authorIsVerified,
        authorAccountType = accountType,
        authorHandle = authorHandle,
        publisherId = publisherId,
        coverStyle = style,
        questions = questions.sortedBy { it.displayOrder }.map { q ->
            com.trendx.app.models.SurveyQuestion(
                id = q.id,
                title = q.title,
                description = q.description,
                type = when (q.type.lowercase()) {
                    "multiple_choice" -> com.trendx.app.models.PollType.MultipleChoice
                    "rating" -> com.trendx.app.models.PollType.Rating
                    "linear_scale" -> com.trendx.app.models.PollType.LinearScale
                    else -> com.trendx.app.models.PollType.SingleChoice
                },
                options = q.options.sortedBy { it.displayOrder }.map { o ->
                    com.trendx.app.models.PollOption(
                        id = o.id, text = o.text, votesCount = o.votesCount,
                        percentage = o.percentage
                    )
                },
                displayOrder = q.displayOrder,
                rewardPoints = q.rewardPoints,
                isRequired = q.isRequired
            )
        },
        topicName = topicName,
        totalResponses = totalResponses,
        completionRate = completionRate,
        avgCompletionSeconds = avgCompletionSeconds,
        status = statusEnum,
        createdAt = createdInstant,
        expiresAt = expiresInstant,
        rewardPoints = rewardPoints
    )
}
