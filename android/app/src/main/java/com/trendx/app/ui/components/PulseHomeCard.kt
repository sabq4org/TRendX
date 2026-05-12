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
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MonitorHeart
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

// Mirrors PulseHomeCard from PulseHomeCard.swift — surface card with
// subtle ambient gradient, primary-colored heart icon, streak chip,
// pulse question, mini stats, and a leading chevron for "drill in".
@Composable
fun PulseHomeCard(
    question: String = "ما النبض اليوم؟ شارك في صوت السعودية",
    totalResponses: Int = 1340,
    rewardPoints: Int = 40,
    streak: Int = 5,
    userResponded: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val ambient = Brush.linearGradient(
        listOf(TrendXColors.Primary.copy(alpha = 0.08f), TrendXColors.AiViolet.copy(alpha = 0.04f))
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
        // Leading icon
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 12.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .size(52.dp)
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
        ) {
            Icon(imageVector = Icons.Filled.MonitorHeart, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                if (streak > 0) Chip("سلسلة $streak", TrendXColors.Accent, Icons.Filled.LocalFireDepartment)
                if (userResponded) Chip("صوّتت ✓", TrendXColors.Success)
                Text(
                    text = "نبض اليوم",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.Primary)
                )
            }
            Text(text = question, color = TrendXColors.Ink,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp),
                maxLines = 2)
            Row {
                Text(text = "$totalResponses مشارك", style = TrendXType.Small,
                    color = TrendXColors.TertiaryInk)
                Spacer(Modifier.width(6.dp))
                Text(text = "·", style = TrendXType.Small, color = TrendXColors.TertiaryInk)
                Spacer(Modifier.width(6.dp))
                Text(text = "+$rewardPoints نقطة", style = TrendXType.Small,
                    color = TrendXColors.TertiaryInk)
            }
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = TrendXColors.Primary, modifier = Modifier.size(14.dp))
    }
}

@Composable
private fun Chip(text: String, tint: Color, icon: androidx.compose.ui.graphics.vector.ImageVector? = null) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(tint.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        icon?.let {
            Icon(imageVector = it, contentDescription = null, tint = tint,
                modifier = Modifier.size(9.dp))
            Spacer(Modifier.width(4.dp))
        }
        Text(text = text, color = tint,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp))
    }
}
