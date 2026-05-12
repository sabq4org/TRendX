package com.trendx.app.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// Equivalent of SwiftUI's `.surfaceCard()` view modifier.
fun Modifier.surfaceCard(
    padding: Dp = 18.dp,
    radius: Dp = TrendXRadius.Card.dp
): Modifier = this
    .shadow(elevation = 7.dp, shape = RoundedCornerShape(radius), clip = false)
    .clip(RoundedCornerShape(radius))
    .background(TrendXColors.Surface)
    .border(0.8.dp, TrendXColors.Outline.copy(alpha = 0.75f), RoundedCornerShape(radius))
    .padding(padding)
