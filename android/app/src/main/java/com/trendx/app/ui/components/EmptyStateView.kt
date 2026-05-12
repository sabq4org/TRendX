package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors EmptyStateView from SharedComponents.swift.
@Composable
fun EmptyStateView(
    icon: ImageVector,
    title: String,
    message: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(TrendXColors.ElevatedSurface.copy(alpha = 0.78f))
            .border(0.8.dp, TrendXColors.Outline.copy(alpha = 0.7f), RoundedCornerShape(24.dp))
            .padding(34.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null,
            tint = TrendXColors.TertiaryInk, modifier = Modifier.size(48.dp))
        Text(text = title, style = TrendXType.Subheadline, color = TrendXColors.Ink)
        Text(text = message, style = TrendXType.Caption,
            color = TrendXColors.SecondaryInk, textAlign = TextAlign.Center)
        Spacer(Modifier.height(0.dp))
    }
}
