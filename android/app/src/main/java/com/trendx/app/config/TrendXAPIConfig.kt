package com.trendx.app.config

import com.trendx.app.BuildConfig

// Mirrors TrendXAPIConfig.swift. Default base URL comes from a Gradle
// build property (BuildConfig.API_BASE_URL); pass `-PtrendxApiBaseUrl=...`
// at build time to point at staging or a local backend.
data class TrendXAPIConfig(val baseUrl: String?) {
    val isConfigured: Boolean get() = !baseUrl.isNullOrBlank()

    companion object {
        val current: TrendXAPIConfig = TrendXAPIConfig(
            baseUrl = BuildConfig.API_BASE_URL.takeIf { it.isNotBlank() }
        )
    }
}
