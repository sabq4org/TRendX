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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.LocalFireDepartment
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
import com.trendx.app.theme.TrendXType

// Mirrors DailyBonusCard.swift claimable state — gradient hero with
// sparkles, headline, streak chip, and a white "استلم" pill on the
// trailing edge. The justClaimed and hidden states will follow when we
// wire the /me/daily-bonus endpoints.
@Composable
fun DailyBonusCard(
    canClaim: Boolean = true,
    currentStreak: Int = 3,
    nextReward: Int = 12,
    isClaiming: Boolean = false,
    onClaim: () -> Unit,
    modifier: Modifier = Modifier
) {
    if (!canClaim) return

    val gradient = Brush.linearGradient(
        listOf(TrendXColors.AiIndigo, TrendXColors.AiViolet, TrendXColors.Accent)
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 20.dp, shape = RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .padding(16.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(54.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.20f))
        ) {
            Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "هديتك اليومية بانتظارك",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = Color.White)
                )
                if (currentStreak > 0) {
                    Spacer(Modifier.width(6.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.22f))
                            .padding(horizontal = 7.dp, vertical = 2.dp)
                    ) {
                        Icon(imageVector = Icons.Filled.LocalFireDepartment,
                            contentDescription = null, tint = Color.White,
                            modifier = Modifier.size(9.dp))
                        Spacer(Modifier.width(3.dp))
                        Text(
                            text = "سلسلة $currentStreak",
                            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp,
                                color = Color.White)
                        )
                    }
                }
            }
            Text(
                text = "+$nextReward نقطة فوراً، استلمها قبل منتصف الليل",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                    color = Color.White.copy(alpha = 0.88f))
            )
        }
        Spacer(Modifier.width(8.dp))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 8.dp, shape = CircleShape, clip = false)
                .clip(CircleShape)
                .background(Color.White)
                .clickable(enabled = !isClaiming, onClick = onClaim)
                .padding(horizontal = 14.dp, vertical = 9.dp)
        ) {
            Text(
                text = if (isClaiming) "..." else "استلم",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.AiIndigo)
            )
        }
    }
}
