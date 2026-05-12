package com.trendx.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors PollsSegmentButton from PollsScreen.swift — three-segment
// active/voted/ended switcher with a count chip on the trailing edge.
@Composable
fun PollsSegmentButton(
    title: String,
    count: Int,
    icon: ImageVector,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val bg by animateColorAsState(
        targetValue = if (isSelected) TrendXColors.Primary else Color.Transparent,
        label = "polls-seg-bg"
    )
    val fg by animateColorAsState(
        targetValue = if (isSelected) TrendXColors.Surface else TrendXColors.SecondaryInk,
        label = "polls-seg-fg"
    )
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .clickable(onClick = onClick)
            .padding(vertical = 11.dp, horizontal = 6.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = fg,
            modifier = Modifier.size(12.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = title, color = fg, style = TrendXType.Caption)
        Spacer(Modifier.width(6.dp))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .clip(CircleShape)
                .background(if (isSelected) TrendXColors.Surface else TrendXColors.PaleFill)
                .padding(horizontal = 7.dp, vertical = 2.dp)
        ) {
            Text(
                text = count.toString(),
                style = TextStyle(
                    fontWeight = FontWeight.Bold, fontSize = 11.sp,
                    color = if (isSelected) TrendXColors.Primary else TrendXColors.SecondaryInk
                )
            )
        }
    }
}
