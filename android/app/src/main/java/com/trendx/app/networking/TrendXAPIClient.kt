package com.trendx.app.networking

import android.util.Log
import com.trendx.app.config.TrendXAPIConfig
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.HttpResponseValidator
import io.ktor.client.plugins.ResponseException
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logger as KtorLogger
import io.ktor.client.plugins.logging.Logging
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy

// Equivalent of TRENDX/Networking/TrendXAPIClient.swift. Uses kotlinx.serialization
// with the snake_case naming strategy so backend payloads decode straight into
// the camelCase Kotlin data classes — matching the iOS client's
// `convertFromSnakeCase` / `convertToSnakeCase` JSON config.

sealed class TrendXAPIError(message: String) : RuntimeException(message) {
    object NotConfigured : TrendXAPIError("TRENDX API is not configured for this build.")
    object InvalidResponse : TrendXAPIError("The API returned an invalid response.")
    class Server(val status: Int, val payload: String) :
        TrendXAPIError("TRENDX API request failed ($status): $payload")
}

class TrendXAPIClient(
    val config: TrendXAPIConfig = TrendXAPIConfig.current
) {
    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    val json: Json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        encodeDefaults = true
        coerceInputValues = true
        namingStrategy = JsonNamingStrategy.SnakeCase
    }

    // @PublishedApi internal so the inline `get` / `post` below can call
    // through. Logcat tag "TrendXAPI" — `adb logcat -s TrendXAPI` to see
    // every request body, response status, and any non-2xx payload.
    @PublishedApi
    internal val client: HttpClient = HttpClient(OkHttp) {
        expectSuccess = false
        install(ContentNegotiation) { json(this@TrendXAPIClient.json) }
        install(Logging) {
            logger = object : KtorLogger {
                // Log.i so the messages survive Logcat's default INFO+
                // filter — Log.d gets hidden unless you opt in to "Verbose".
                override fun log(message: String) { Log.i("TrendXAPI", message) }
            }
            // ALL = method + URL + headers + body for both request and
            // response. Verbose, but exactly what we need while we're
            // diagnosing why /bootstrap doesn't bring back real data.
            level = LogLevel.ALL
        }
        defaultRequest {
            contentType(ContentType.Application.Json)
        }
        HttpResponseValidator {
            validateResponse { response ->
                val status = response.status.value
                if (status !in 200..299) {
                    val body = runCatching { response.bodyAsText() }.getOrDefault("")
                    Log.w("TrendXAPI", "HTTP $status from ${response.call.request.url}: ${body.take(280)}")
                    throw TrendXAPIError.Server(status, body)
                }
            }
        }
    }

    suspend inline fun <reified T> get(path: String, accessToken: String? = null): T {
        val url = absoluteUrl(path)
        return try {
            client.get(url) {
                accessToken?.let { header(HttpHeaders.Authorization, "Bearer $it") }
            }.body()
        } catch (e: ResponseException) {
            throw TrendXAPIError.Server(e.response.status.value, e.message ?: "")
        }
    }

    suspend inline fun <reified T, reified Body : Any> post(
        path: String,
        body: Body,
        accessToken: String? = null
    ): T {
        val url = absoluteUrl(path)
        return try {
            client.post(url) {
                accessToken?.let { header(HttpHeaders.Authorization, "Bearer $it") }
                setBody(body)
            }.body()
        } catch (e: ResponseException) {
            throw TrendXAPIError.Server(e.response.status.value, e.message ?: "")
        }
    }

    fun absoluteUrl(path: String): String {
        // Plain string concat. Earlier we used Ktor's URLBuilder, which
        // appended an extra path segment to "https://host" (its starting
        // path was already an empty segment), producing "https://host//path"
        // and silent 404s on Railway. String math matches iOS's
        // URL(string:relativeTo:) behavior without the surprise.
        val base = config.baseUrl?.trimEnd('/') ?: throw TrendXAPIError.NotConfigured
        val normalized = if (path.startsWith("/")) path else "/$path"
        return base + normalized
    }
}

// Intelligence-layer endpoints. Mirrors TRENDX/Networking/TrendXIntelligenceAPI.swift
// 1-for-1 — the contracts are identical between iOS and Android because the
// Railway API is the single source of truth.

suspend fun TrendXAPIClient.pulseTodayAnonymous(): DailyPulseDto =
    get("/pulse/today/anon")

suspend fun TrendXAPIClient.pulseToday(accessToken: String): DailyPulseDto =
    get("/pulse/today", accessToken)

suspend fun TrendXAPIClient.pulseYesterday(accessToken: String): PulseYesterdayDto =
    get("/pulse/yesterday", accessToken)

suspend fun TrendXAPIClient.pulseRespond(
    optionIndex: Int,
    predictedPct: Int?,
    accessToken: String
): PulseResponseDto = post(
    "/pulse/today/respond",
    PulseRespondRequest(optionIndex = optionIndex, predictedPct = predictedPct),
    accessToken
)

suspend fun TrendXAPIClient.myStreak(accessToken: String): UserStreakDto =
    get("/me/streak", accessToken)

suspend fun TrendXAPIClient.myOpinionDNA(accessToken: String): OpinionDnaDto =
    get("/me/dna", accessToken)

suspend fun TrendXAPIClient.trendxIndex(): TrendXIndexDto =
    get("/public/index")

suspend fun TrendXAPIClient.myAccuracy(accessToken: String): UserAccuracyDto =
    get("/me/accuracy", accessToken)

suspend fun TrendXAPIClient.accuracyLeaderboard(
    limit: Int = 25,
    accessToken: String
): AccuracyLeaderboardDto =
    get("/accuracy/leaderboard?limit=$limit", accessToken)

suspend fun TrendXAPIClient.thisWeekChallenge(accessToken: String): WeeklyChallengeDto =
    get("/challenges/this-week", accessToken)

suspend fun TrendXAPIClient.predictChallenge(
    id: String,
    predictedPct: Int,
    accessToken: String
): EmptyOk = post(
    "/challenges/$id/predict",
    PredictRequest(predictedPct),
    accessToken
)

suspend fun TrendXAPIClient.notifications(accessToken: String): List<NotificationDto> =
    get<NotificationsListDto>("/me/notifications", accessToken).items

// ---- Survey endpoints ----

suspend fun TrendXAPIClient.listSurveys(accessToken: String?): List<SurveyDto> =
    get("/surveys", accessToken)

suspend fun TrendXAPIClient.getSurvey(id: String, accessToken: String?): SurveyDto =
    get("/surveys/$id", accessToken)

suspend fun TrendXAPIClient.createSurveyRemote(
    request: SurveyCreateRequest,
    accessToken: String
): SurveyCreateResponse = post("/surveys/create", request, accessToken)

suspend fun TrendXAPIClient.respondToSurvey(
    id: String,
    request: SurveyRespondRequest,
    accessToken: String
): EmptyOk = post("/surveys/$id/respond", request, accessToken)

// ---- Poll create ----

suspend fun TrendXAPIClient.createPollRemote(
    request: PollCreateRequest,
    accessToken: String
): PollCreateResponse = post("/polls/create", request, accessToken)
