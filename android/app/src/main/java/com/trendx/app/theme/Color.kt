package com.trendx.app.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// Mirrors TRENDX/Theme/TrendXTheme.swift — keep hex values in lockstep.
object TrendXColors {
    // Backgrounds & Surfaces
    val Background      = Color(0xFFF4F5FA)
    val BackgroundDeep  = Color(0xFFE8EAF2)
    val Surface         = Color(0xFFFFFFFF)
    val ElevatedSurface = Color(0xFFFFFFFF)
    val PaleFill        = Color(0xFFF0F2FA)
    val SoftFill        = Color(0xFFE4E7F5)
    val StrongFill      = Color(0xFFD5D9ED)

    // Text Hierarchy
    val Ink          = Color(0xFF1A1B25)
    val SecondaryInk = Color(0xFF495057)
    val TertiaryInk  = Color(0xFF868E96)
    val MutedInk     = Color(0xFFADB5BD)

    // Brand
    val Primary      = Color(0xFF3B5BDB)
    val PrimaryLight = Color(0xFF4C6EF5)
    val PrimaryDeep  = Color(0xFF364FC7)
    val Accent       = Color(0xFFFA7C12)
    val AccentDeep   = Color(0xFFE8590C)

    // TRENDX AI signature
    val AiIndigo = Color(0xFF4263EB)
    val AiViolet = Color(0xFF7048E8)
    val AiCyan   = Color(0xFF1098AD)
    val AiInk    = Color(0xFF364FC7)

    // Semantic
    val Success = Color(0xFF2F9E44)
    val Warning = Color(0xFFF59F00)
    val Error   = Color(0xFFE03131)
    val Info    = Color(0xFF1971C2)
    val Muted   = Color(0xFF868E96)

    // Account-type accents
    val SaudiGreen      = Color(0xFF0F5132)
    val SaudiGreenDeep  = Color(0xFF0A3D26)
    val SaudiGreenLight = Color(0xFF1B7A45)
    val SaudiGreenWash  = Color(0xFFE8F3EE)
    val OrgGold         = Color(0xFFB45309)
    val OrgGoldLight    = Color(0xFFD97706)
    val OrgGoldWash     = Color(0xFFFEF3C7)

    // Borders & Shadows
    val Outline       = Color(0xFFDEE2E6)
    val StrongOutline = Color(0xFFCED4DA)
    val Shadow        = Color(0x143B5BDB) // Primary @ 8%
    val DeepShadow    = Color(0x26364FC7) // PrimaryDeep @ 15%
}

object TrendXRadius {
    val Card   = 20
    val Tile   = 16
    val Chip   = 12
    val Button = 14
    val Pill   = 50
}

// Common gradients — matches the SwiftUI .topLeading → .bottomTrailing
// linear gradients. Use Brush.linearGradient with default start/end so
// it spans the bounds of the painted shape.
object TrendXGradients {
    val Primary = Brush.linearGradient(listOf(TrendXColors.Primary, TrendXColors.PrimaryLight))
    val Accent  = Brush.linearGradient(listOf(Color(red = 250, green = 191, blue = 76), TrendXColors.Accent))
    val Header  = Brush.linearGradient(
        listOf(TrendXColors.PrimaryDeep, TrendXColors.Primary, TrendXColors.PrimaryLight)
    )
    val SaudiGreen = Brush.linearGradient(
        listOf(TrendXColors.SaudiGreenDeep, TrendXColors.SaudiGreen, TrendXColors.SaudiGreenLight)
    )
    val OrgGold = Brush.linearGradient(listOf(TrendXColors.OrgGold, TrendXColors.OrgGoldLight))
    val Ai = Brush.linearGradient(
        listOf(TrendXColors.AiIndigo, TrendXColors.AiViolet, TrendXColors.AiCyan)
    )
    val AiSoft = Brush.linearGradient(
        listOf(TrendXColors.AiIndigo.copy(alpha = 0.10f), TrendXColors.AiCyan.copy(alpha = 0.06f))
    )
}
