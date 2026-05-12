package com.trendx.app.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection

private val LightScheme = lightColorScheme(
    primary       = TrendXColors.Primary,
    onPrimary     = TrendXColors.Surface,
    primaryContainer = TrendXColors.PrimaryLight,
    secondary     = TrendXColors.Accent,
    onSecondary   = TrendXColors.Surface,
    background    = TrendXColors.Background,
    onBackground  = TrendXColors.Ink,
    surface       = TrendXColors.Surface,
    onSurface     = TrendXColors.Ink,
    surfaceVariant = TrendXColors.PaleFill,
    outline       = TrendXColors.Outline,
    error         = TrendXColors.Error,
    onError       = TrendXColors.Surface
)

@Composable
fun TrendXTheme(content: @Composable () -> Unit) {
    // The whole app is RTL-first — match TRENDX/Theme/TrendXTheme.swift
    // `.trendxRTL()` modifier so SwiftUI and Compose render with the same
    // directional reflection. New top-level Composables don't need to opt
    // in individually; this CompositionLocal flips it for the entire tree.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        MaterialTheme(
            colorScheme = LightScheme,
            typography  = TrendXTypography,
            content     = content
        )
    }
}
