package com.trendx.app.models

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.MilitaryTech
import androidx.compose.material.icons.filled.Shield
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

// Mirrors TRENDX/Components/MemberTier.swift — bronze/silver/gold/diamond.
enum class MemberTier(val threshold: Int, val label: String, val tint: Color, val icon: ImageVector) {
    Bronze(0,    "برونزي", Color(red = 0.72f, green = 0.46f, blue = 0.24f), Icons.Filled.Shield),
    Silver(300,  "فضي",    Color(red = 0.62f, green = 0.66f, blue = 0.72f), Icons.Filled.MilitaryTech),
    Gold(1_000,  "ذهبي",   Color(red = 0.92f, green = 0.72f, blue = 0.20f), Icons.Filled.EmojiEvents),
    Diamond(3_000, "ماسي", Color(red = 0.30f, green = 0.62f, blue = 0.92f), Icons.Filled.Diamond);

    val gradient: Brush get() {
        val mix = Color(
            red = tint.red * 0.85f,
            green = tint.green * 0.85f,
            blue = tint.blue * 0.85f
        )
        return Brush.linearGradient(listOf(tint, mix))
    }

    val next: MemberTier? get() = when (this) {
        Bronze -> Silver
        Silver -> Gold
        Gold -> Diamond
        Diamond -> null
    }

    fun progress(points: Int): Float {
        val n = next ?: return 1f
        val span = (n.threshold - threshold).coerceAtLeast(1)
        return ((points - threshold).toFloat() / span.toFloat()).coerceIn(0f, 1f)
    }

    fun pointsToNext(points: Int): Int {
        val n = next ?: return 0
        return (n.threshold - points).coerceAtLeast(0)
    }

    companion object {
        fun from(points: Int): MemberTier = when {
            points >= Diamond.threshold -> Diamond
            points >= Gold.threshold -> Gold
            points >= Silver.threshold -> Silver
            else -> Bronze
        }
    }
}
