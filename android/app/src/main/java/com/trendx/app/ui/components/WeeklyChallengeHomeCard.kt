package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.PeopleAlt
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

// Mirrors WeeklyChallengeHomeCard.swift — bold gradient card with target
// icon, "تحدّي الأسبوع" + "جديد" chips, headline, and participant count.
@Composable
fun WeeklyChallengeHomeCard(
    question: String = "توقّع نبض الأسبوع واربح نقاطك",
    totalPredictions: Int = 248,
    hasParticipated: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val gradient = Brush.linearGradient(
        listOf(TrendXColors.AiIndigo, TrendXColors.AiViolet)
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .heightIn(min = 96.dp)
            .shadow(elevation = 18.dp, shape = RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.18f))
        ) {
            Icon(imageVector = Icons.Filled.GpsFixed, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Pill("تحدّي الأسبوع", bg = Color.White.copy(alpha = 0.20f), fg = Color.White)
                if (hasParticipated) Pill("شاركت ✓", bg = Color.White.copy(alpha = 0.20f), fg = Color.White)
                else Pill("جديد", bg = Color.White, fg = TrendXColors.AiIndigo)
            }
            Text(text = question,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp, color = Color.White),
                maxLines = 2)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = Icons.Filled.PeopleAlt, contentDescription = null,
                    tint = Color.White.copy(alpha = 0.82f), modifier = Modifier.size(10.dp))
                Spacer(Modifier.width(6.dp))
                Text(text = "$totalPredictions مشارك هذا الأسبوع",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                        color = Color.White.copy(alpha = 0.82f)))
            }
        }
        Spacer(Modifier.width(4.dp))
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = Color.White.copy(alpha = 0.85f), modifier = Modifier.size(13.dp))
    }
}

@Composable
private fun Pill(text: String, bg: Color, fg: Color) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(text = text, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp, color = fg))
    }
}

