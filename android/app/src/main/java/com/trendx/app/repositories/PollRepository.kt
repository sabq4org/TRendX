package com.trendx.app.repositories

import com.trendx.app.models.Poll
import com.trendx.app.models.Topic
import com.trendx.app.models.TrendXUser
import com.trendx.app.networking.BootstrapResponse
import com.trendx.app.networking.PollDto
import com.trendx.app.networking.RepostResponse
import com.trendx.app.networking.TrendXAPIClient
import com.trendx.app.networking.TrendXAPIError
import com.trendx.app.networking.VoteRequest
import com.trendx.app.networking.VoteResponse

// Mirrors TRENDX/Repositories/PollRepository.swift. The vote/repost
// endpoints require an auth session — the bootstrap will accept either.

data class PollBootstrap(val topics: List<Topic>, val polls: List<Poll>)

data class VoteOutcome(
    val poll: Poll,
    val user: TrendXUser?,
    val insight: String?
)

class PollRepository(private val client: TrendXAPIClient) {

    val isRemoteEnabled: Boolean get() = client.config.isConfigured

    /// Fetches `/bootstrap` and returns whatever the backend says. Throws
    /// on network/parse error so the caller can decide whether to fall back
    /// to samples or surface the failure. Previously we swallowed errors
    /// here and silently kept `Poll.samples`, which made it impossible to
    /// tell the difference between "backend down" and "real polls loaded."
    suspend fun loadBootstrap(session: AuthSession?): PollBootstrap {
        if (!isRemoteEnabled) {
            return PollBootstrap(topics = Topic.samples, polls = Poll.samples)
        }
        val response: BootstrapResponse = client.get(
            "/bootstrap",
            accessToken = session?.accessToken
        )
        return PollBootstrap(
            topics = response.topics.map { it.toDomain() },
            polls = response.polls.map { it.toDomain() }
        )
    }

    suspend fun listPolls(status: String = "active", session: AuthSession?): List<Poll> {
        if (!isRemoteEnabled) return Poll.samples
        val response: List<PollDto> = client.get(
            "/polls?status=$status",
            accessToken = session?.accessToken
        )
        return response.map { it.toDomain() }
    }

    suspend fun getPoll(id: String, session: AuthSession?): Poll? {
        if (!isRemoteEnabled) return Poll.samples.firstOrNull { it.id == id }
        return runCatching {
            val dto: PollDto = client.get("/polls/$id", accessToken = session?.accessToken)
            dto.toDomain()
        }.getOrNull()
    }

    suspend fun vote(
        pollId: String,
        optionId: String,
        isPublic: Boolean,
        session: AuthSession
    ): VoteOutcome {
        if (!isRemoteEnabled) throw TrendXAPIError.NotConfigured
        val response: VoteResponse = client.post(
            path = "/polls/vote",
            body = VoteRequest(pollId = pollId, optionId = optionId, isPublic = isPublic),
            accessToken = session.accessToken
        )
        return VoteOutcome(
            poll = response.poll.toDomain(),
            user = response.user?.toDomain(),
            insight = response.insight
        )
    }

    suspend fun setReposted(pollId: String, repost: Boolean, session: AuthSession): Boolean {
        if (!isRemoteEnabled) return true
        val path = if (repost) "/polls/$pollId/repost" else "/polls/$pollId/unrepost"
        return runCatching {
            client.post<RepostResponse, Map<String, String>>(
                path = path,
                body = emptyMap(),
                accessToken = session.accessToken
            ).ok
        }.getOrDefault(false)
    }
}
