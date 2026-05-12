package com.trendx.app.theme

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush

// Equivalent of TrendXAmbientBackground in TRENDX/Theme/TrendXTheme.swift.
// Soft top→bottom gradient + faint dotted texture; intentionally subtle so
// foreground content (cards, headers) carries the color story.
@Composable
fun TrendXAmbientBackground(modifier: Modifier = Modifier) {
    val ambient = Brush.verticalGradient(
        listOf(TrendXColors.Background, TrendXColors.PaleFill, TrendXColors.BackgroundDeep)
    )
    Box(modifier = modifier.fillMaxSize().background(ambient)) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val spacing = 18f
            val dotColor = TrendXColors.Primary.copy(alpha = 0.035f)
            var x = spacing / 2f
            while (x < size.width) {
                var y = spacing / 2f
                while (y < size.height) {
                    drawCircle(color = dotColor, radius = 0.55f, center = Offset(x, y))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}
