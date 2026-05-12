package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors TopicFilterChip in HomeScreen.swift — flat capsule for the
// "جميع المواضيع" / "تتابعهم" filter row above the topics list.
@Composable
fun TopicFilterChip(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Text(
        text = title,
        color = if (isSelected) TrendXColors.Primary else TrendXColors.SecondaryInk,
        style = TrendXType.Caption,
        modifier = modifier
            .clip(CircleShape)
            .background(if (isSelected) TrendXColors.Primary.copy(alpha = 0.08f) else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp)
    )
}
