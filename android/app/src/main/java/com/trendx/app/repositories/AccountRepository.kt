package com.trendx.app.repositories

import com.trendx.app.models.Poll
import com.trendx.app.models.TrendXUser
import com.trendx.app.networking.FollowListResponse
import com.trendx.app.networking.FollowMutationResponse
import com.trendx.app.networking.LedgerEntryDto
import com.trendx.app.networking.TrendXAPIClient
import com.trendx.app.networking.UserDto
import com.trendx.app.networking.UserPostsResponse
import io.ktor.http.encodeURLPath

// Aggregates the social-graph + ledger endpoints used by the Account
// sub-screens. Each method maps cleanly to a single Hono route in
// backend/railway-api/src/index.ts so the wire format stays predictable.
class AccountRepository(private val client: TrendXAPIClient) {

    suspend fun pointsLedger(session: AuthSession): List<LedgerEntryDto> =
        client.get(path = "/points/ledger", accessToken = session.accessToken)

    suspend fun following(session: AuthSession): List<TrendXUser> {
        val resp: FollowListResponse = client.get(
            path = "/me/following",
            accessToken = session.accessToken
        )
        return resp.items.map { it.toDomain() }
    }

    suspend fun followers(session: AuthSession): List<TrendXUser> {
        val resp: FollowListResponse = client.get(
            path = "/me/followers",
            accessToken = session.accessToken
        )
        return resp.items.map { it.toDomain() }
    }

    suspend fun follow(targetUserId: String, session: AuthSession): Boolean {
        return runCatching {
            client.post<FollowMutationResponse, Map<String, String>>(
                path = "/users/$targetUserId/follow",
                body = emptyMap(),
                accessToken = session.accessToken
            ).ok
        }.getOrDefault(false)
    }

    suspend fun unfollow(targetUserId: String, session: AuthSession): Boolean {
        return runCatching {
            client.post<FollowMutationResponse, Map<String, String>>(
                path = "/users/$targetUserId/unfollow",
                body = emptyMap(),
                accessToken = session.accessToken
            ).ok
        }.getOrDefault(false)
    }

    suspend fun loadUser(idOrHandle: String, session: AuthSession?): TrendXUser? {
        val safe = idOrHandle.encodeURLPath()
        return runCatching {
            val dto: UserDto = client.get(
                path = "/users/$safe",
                accessToken = session?.accessToken
            )
            dto.toDomain()
        }.getOrNull()
    }

    /// Returns the user's own polls + reposts merged in chronological order.
    /// Each `ProfilePost` carries the kind ("poll" or "repost") so the
    /// caller can render a "أعاد النشر" label above repost rows.
    suspend fun loadUserPosts(
        idOrHandle: String,
        session: AuthSession,
        limit: Int = 20
    ): List<ProfilePost> {
        val safe = idOrHandle.encodeURLPath()
        val resp: UserPostsResponse = client.get(
            path = "/users/$safe/posts?limit=$limit",
            accessToken = session.accessToken
        )
        return resp.items.map { item ->
            ProfilePost(
                kind = if (item.kind == "repost") ProfilePostKind.Repost else ProfilePostKind.Poll,
                id = item.id,
                poll = item.poll.toDomain(),
                caption = item.caption
            )
        }
    }
}

data class ProfilePost(
    val kind: ProfilePostKind,
    val id: String,
    val poll: Poll,
    val caption: String?
)

enum class ProfilePostKind { Poll, Repost }
