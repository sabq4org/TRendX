package com.trendx.app.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Newspaper
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.outlined.SportsSoccer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import kotlinx.serialization.Serializable

// Mirrors PollCoverStyle in TRENDX/Models/Models.swift. Keep the topic
// label mapping (Arabic name → enum) identical so iOS-published polls
// resolve to the same visual family on Android.
@Serializable
enum class PollCoverStyle(val rawValue: String) {
    Tech("tech"),
    Economy("economy"),
    Sports("sports"),
    Social("social"),
    Media("media"),
    Health("health"),
    Food("food"),
    Travel("travel"),
    Generic("generic");

    val label: String get() = when (this) {
        Tech -> "تقنية"
        Economy -> "اقتصاد"
        Sports -> "رياضة"
        Social -> "مجتمع"
        Media -> "إعلام"
        Health -> "صحة"
        Food -> "طعام"
        Travel -> "سفر"
        Generic -> "عام"
    }

    val heroPhrase: String get() = when (this) {
        Tech -> "نبض التقنية"
        Economy -> "حركة الاقتصاد"
        Sports -> "روح الرياضة"
        Social -> "صوت المجتمع"
        Media -> "مشهد إعلامي"
        Health -> "صحة وعافية"
        Food -> "مذاق اليوم"
        Travel -> "وجهات ملهمة"
        Generic -> "اتجاه صاعد"
    }

    val tint: Color get() = when (this) {
        Tech -> Color(red = 0.42f, green = 0.32f, blue = 0.88f)
        Economy -> Color(red = 0.10f, green = 0.60f, blue = 0.46f)
        Sports -> Color(red = 0.92f, green = 0.48f, blue = 0.18f)
        Social -> Color(red = 0.10f, green = 0.58f, blue = 0.66f)
        Media -> Color(red = 0.74f, green = 0.30f, blue = 0.66f)
        Health -> Color(red = 0.90f, green = 0.34f, blue = 0.44f)
        Food -> Color(red = 0.92f, green = 0.46f, blue = 0.22f)
        Travel -> Color(red = 0.18f, green = 0.58f, blue = 0.88f)
        Generic -> Color(red = 0.40f, green = 0.44f, blue = 0.58f)
    }

    val gradient: Brush get() = when (this) {
        Tech -> Brush.linearGradient(listOf(
            Color(red = 0.28f, green = 0.22f, blue = 0.68f),
            Color(red = 0.54f, green = 0.36f, blue = 0.92f)
        ))
        Economy -> Brush.linearGradient(listOf(
            Color(red = 0.08f, green = 0.44f, blue = 0.36f),
            Color(red = 0.22f, green = 0.68f, blue = 0.52f)
        ))
        Sports -> Brush.linearGradient(listOf(
            Color(red = 0.92f, green = 0.38f, blue = 0.16f),
            Color(red = 0.98f, green = 0.62f, blue = 0.24f)
        ))
        Social -> Brush.linearGradient(listOf(
            Color(red = 0.08f, green = 0.48f, blue = 0.56f),
            Color(red = 0.30f, green = 0.74f, blue = 0.78f)
        ))
        Media -> Brush.linearGradient(listOf(
            Color(red = 0.56f, green = 0.22f, blue = 0.60f),
            Color(red = 0.88f, green = 0.40f, blue = 0.72f)
        ))
        Health -> Brush.linearGradient(listOf(
            Color(red = 0.86f, green = 0.28f, blue = 0.38f),
            Color(red = 0.96f, green = 0.50f, blue = 0.48f)
        ))
        Food -> Brush.linearGradient(listOf(
            Color(red = 0.88f, green = 0.36f, blue = 0.20f),
            Color(red = 0.98f, green = 0.70f, blue = 0.32f)
        ))
        Travel -> Brush.linearGradient(listOf(
            Color(red = 0.12f, green = 0.46f, blue = 0.78f),
            Color(red = 0.38f, green = 0.74f, blue = 0.94f)
        ))
        Generic -> Brush.linearGradient(listOf(
            Color(red = 0.28f, green = 0.30f, blue = 0.44f),
            Color(red = 0.52f, green = 0.58f, blue = 0.72f)
        ))
    }

    val glyph: ImageVector get() = when (this) {
        Tech -> Icons.Filled.Memory
        Economy -> Icons.Filled.TrendingUp
        Sports -> Icons.Outlined.SportsSoccer
        Social -> Icons.Filled.People
        Media -> Icons.Filled.Newspaper
        Health -> Icons.Filled.Favorite
        Food -> Icons.Filled.Restaurant
        Travel -> Icons.Filled.Flight
        Generic -> Icons.Filled.AutoAwesome
    }

    val wash: Color get() = tint.copy(alpha = 0.10f)
    val hairline: Color get() = tint.copy(alpha = 0.22f)

    companion object {
        fun fromTopic(name: String?): PollCoverStyle {
            val trimmed = name?.trim().orEmpty()
            return when (trimmed) {
                "تقنية" -> Tech
                "اقتصاد" -> Economy
                "رياضة" -> Sports
                "اجتماعية" -> Social
                "إعلام" -> Media
                "صحة" -> Health
                "طعام" -> Food
                "سفر" -> Travel
                else -> Generic
            }
        }
    }
}
