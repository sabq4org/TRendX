package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Survey
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.surfaceCard

@Composable
fun SurveyListRow(
    survey: Survey,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .surfaceCard(padding = 14.dp, radius = 20.dp)
            .clickable(onClick = onTap),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Section icon — publisher cover image when present, else gradient
        // tile with the topic glyph. Mirrors iOS exactly.
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(52.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(survey.coverStyle.gradient)
        ) {
            if (!survey.imageUrl.isNullOrBlank()) {
                TrendXProfileImage(
                    urlString = survey.imageUrl,
                    modifier = Modifier.size(52.dp).clip(RoundedCornerShape(14.dp)),
                    fallback = {
                        Icon(survey.coverStyle.glyph, contentDescription = null,
                            tint = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.9f),
                            modifier = Modifier.size(20.dp))
                    }
                )
            } else {
                Icon(survey.coverStyle.glyph, contentDescription = null,
                    tint = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.9f),
                    modifier = Modifier.size(20.dp))
            }
        }

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(survey.coverStyle.wash)
                        .padding(horizontal = 7.dp, vertical = 2.dp)
                ) {
                    Text(survey.coverStyle.label,
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 10.sp,
                            color = survey.coverStyle.tint))
                }
                Text("${survey.questionCount} سؤال",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                        color = TrendXColors.TertiaryInk))
            }
            Text(survey.title,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                    color = TrendXColors.Ink, lineHeight = 19.sp),
                maxLines = 2, overflow = TextOverflow.Ellipsis)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetaChip(icon = Icons.Filled.PeopleAlt, text = "${survey.totalResponses} مشارك")
                MetaChip(icon = Icons.Filled.CheckCircle, text = "${survey.completionRate.toInt()}% إكمال")
                MetaChip(icon = Icons.Filled.Star, text = "+${survey.rewardPoints} نقطة")
            }
        }

        Icon(Icons.Filled.KeyboardArrowLeft, contentDescription = null,
            tint = TrendXColors.MutedInk, modifier = Modifier.size(12.dp))
    }
}

@Composable
private fun MetaChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Icon(icon, contentDescription = null, tint = TrendXColors.TertiaryInk,
            modifier = Modifier.size(10.dp))
        Text(text, style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 10.sp,
            color = TrendXColors.TertiaryInk))
    }
}

// "مركز الذكاء القطاعي" CTA card shown above the surveys list.
@Composable
fun CategoryInsightCTA(onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.AiIndigo.copy(alpha = 0.07f))
            .border(1.dp, TrendXColors.AiIndigo.copy(alpha = 0.18f), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(com.trendx.app.theme.TrendXGradients.Primary)
        ) {
            Icon(Icons.Filled.Insights,
                contentDescription = null, tint = androidx.compose.ui.graphics.Color.White,
                modifier = Modifier.size(20.dp))
        }
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Text("مركز الذكاء القطاعي",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                    color = TrendXColors.Ink))
            Text("تحليل شامل لكل استبيانات التقنية و AI",
                style = TextStyle(fontSize = 11.sp, color = TrendXColors.AiIndigo))
        }
        Icon(Icons.Filled.AutoAwesome,
            contentDescription = null, tint = TrendXColors.AiIndigo,
            modifier = Modifier.size(16.dp))
    }
}
