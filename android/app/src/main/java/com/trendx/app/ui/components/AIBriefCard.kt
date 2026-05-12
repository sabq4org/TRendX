package com.trendx.app.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients

// Mirrors AIBriefCard.swift — AI bubble with sparkles, headline + tag,
// live success-green pulse on the trailing edge, body copy. The pulse
// is the signature "feed is alive" cue from the iOS card.
@Composable
fun AIBriefCard(
    brief: TrendXAI.AIBrief,
    modifier: Modifier = Modifier
) {
    val ambient = Brush.linearGradient(
        listOf(TrendXColors.AiIndigo.copy(alpha = 0.06f),
               TrendXColors.Info.copy(alpha = 0.025f),
               Color.Transparent)
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 16.dp, shape = RoundedCornerShape(22.dp), clip = false,
                ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
            .clip(RoundedCornerShape(22.dp))
            .background(TrendXColors.Surface)
            .background(ambient)
            .border(1.dp, TrendXColors.AiIndigo.copy(alpha = 0.28f), RoundedCornerShape(22.dp))
            .padding(18.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .shadow(elevation = 10.dp, shape = CircleShape, clip = false,
                        ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
                    .size(42.dp)
                    .clip(CircleShape)
                    .background(TrendXGradients.Ai)
            ) {
                Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                    tint = Color.White, modifier = Modifier.size(17.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    text = brief.headline,
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 15.sp,
                        color = TrendXColors.Ink)
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "TRENDX AI",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.5.sp,
                            color = TrendXColors.AiIndigo))
                    Spacer(Modifier.width(6.dp))
                    Box(modifier = Modifier
                        .size(3.dp)
                        .clip(CircleShape)
                        .background(TrendXColors.TertiaryInk.copy(alpha = 0.4f)))
                    Spacer(Modifier.width(6.dp))
                    Text(text = brief.tag,
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                            color = TrendXColors.SecondaryInk))
                }
            }
            LivePulseDot()
        }
        Spacer(Modifier.padding(top = 14.dp))
        Text(
            text = brief.body,
            style = TextStyle(fontWeight = FontWeight.Normal, fontSize = 14.sp,
                color = TrendXColors.SecondaryInk, lineHeight = 20.sp)
        )
    }
}

@Composable
private fun LivePulseDot() {
    val transition = rememberInfiniteTransition(label = "ai-pulse")
    val ringSize by transition.animateFloat(
        initialValue = 10f,
        targetValue = 22f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1800, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ai-pulse-size"
    )
    val ringAlpha by transition.animateFloat(
        initialValue = 0.4f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1800, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ai-pulse-alpha"
    )
    Box(contentAlignment = Alignment.Center, modifier = Modifier.size(22.dp)) {
        Box(modifier = Modifier
            .size(ringSize.dp)
            .clip(CircleShape)
            .border(3.dp, TrendXColors.Success.copy(alpha = ringAlpha), CircleShape))
        Box(modifier = Modifier
            .size(7.dp)
            .clip(CircleShape)
            .background(TrendXColors.Success))
    }
}
