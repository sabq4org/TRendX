package com.trendx.app.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Mirrors TRENDX/Theme/TrendXTheme.swift Font extensions. SwiftUI uses the
// system serif for headlines and rounded for subheads; on Android we map to
// FontFamily.Serif / FontFamily.Default so the look stays in the same
// visual neighborhood without bundling custom fonts (yet).
//
// IMPORTANT: never set positive letterSpacing on Arabic Text — it
// disconnects joined glyphs (CLAUDE.md "no positive tracking on Arabic").

object TrendXType {
    val Title = TextStyle(
        fontFamily = FontFamily.Serif,
        fontWeight = FontWeight.Black,
        fontSize = 32.sp
    )
    val Headline = TextStyle(
        fontFamily = FontFamily.Serif,
        fontWeight = FontWeight.Black,
        fontSize = 24.sp
    )
    val Subheadline = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp
    )
    val Body = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp
    )
    val BodyBold = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp
    )
    val Caption = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp
    )
    val Small = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp
    )
    val Metric = TextStyle(
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp
    )
}

internal val TrendXTypography = Typography(
    displayLarge   = TrendXType.Title,
    headlineLarge  = TrendXType.Headline,
    titleLarge     = TrendXType.Subheadline,
    bodyLarge      = TrendXType.Body,
    bodyMedium     = TrendXType.Body,
    labelLarge     = TrendXType.BodyBold,
    labelMedium    = TrendXType.Caption,
    labelSmall     = TrendXType.Small
)
