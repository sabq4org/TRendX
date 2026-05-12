package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors

// Mirrors HomeMomentumStrip + MomentumTile from HomeScreen.swift —
// three side-by-side metric tiles below the AI brief.
@Composable
fun HomeMomentumStrip(
    activeCount: Int,
    topicsCount: Int,
    points: Int,
    modifier: Modifier = Modifier
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = modifier.padding(horizontal = 20.dp)
    ) {
        MomentumTile(
            icon = Icons.Filled.Bolt, value = activeCount.toString(),
            label = "نشط الآن", tint = TrendXColors.Warning,
            modifier = Modifier.weight(1f)
        )
        MomentumTile(
            icon = Icons.Filled.GridView, value = topicsCount.toString(),
            label = "مجال", tint = TrendXColors.Info,
            modifier = Modifier.weight(1f)
        )
        MomentumTile(
            icon = Icons.Filled.Stars, value = points.toString(),
            label = "رصيدك", tint = TrendXColors.Accent,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun MomentumTile(
    icon: ImageVector,
    value: String,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(9.dp),
        modifier = modifier
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(18.dp), clip = false,
                ambientColor = tint, spotColor = tint)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.ElevatedSurface.copy(alpha = 0.92f))
            .border(0.8.dp, Color.White.copy(alpha = 0.86f), RoundedCornerShape(18.dp))
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(14.dp))
        }
        Text(
            text = value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 20.sp,
                color = TrendXColors.Ink),
            maxLines = 1
        )
        Text(
            text = label,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                color = TrendXColors.TertiaryInk),
            maxLines = 1
        )
    }
}
