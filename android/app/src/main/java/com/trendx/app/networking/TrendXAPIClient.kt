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
