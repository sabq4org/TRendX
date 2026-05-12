package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType

// Mirrors TrendXIndexHomeCard.swift — pairs visually with PulseHomeCard
// using the AI palette. Big composite score with "/100" subscript.
@Composable
fun TrendXIndexHomeCard(
    composite: Int = 67,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val ambient = Brush.linearGradient(
        listOf(TrendXColors.AiViolet.copy(alpha = 0.08f), TrendXColors.AiCyan.copy(alpha = 0.04f))
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(20.dp), clip = false)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .background(ambient)
            .clickable(onClick = onClick)
            .padding(18.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 12.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.AiViolet, spotColor = TrendXColors.AiViolet)
                .size(52.dp)
                .clip(CircleShape)
                .background(TrendXGradients.Ai)
        ) {
            Icon(imageVector = Icons.Filled.TrendingUp, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(TrendXColors.AiViolet.copy(alpha = 0.12f))
                        .padding(horizontal = 8.dp, vertical = 3.dp)
                ) {
                    Text(text = "نبض السعودية",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp,
                            color = TrendXColors.AiViolet))
                }
                Text(text = "مؤشر TRENDX",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.AiViolet))
            }
            Row(verticalAlignment = Alignment.Bottom) {
                Text(text = composite.toString(),
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 36.sp,
                        color = TrendXColors.AiViolet))
                Text(text = " / 100",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                        color = TrendXColors.TertiaryInk))
            }
            Text(text = "نبض الرأي العام · يُحدَّث يوميّاً",
                style = TrendXType.Small, color = TrendXColors.TertiaryInk)
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = TrendXColors.AiViolet, modifier = Modifier.size(14.dp))
    }
}
