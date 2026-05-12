package com.trendx.app.ui.screens.surveys

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.PlayCircleFilled
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Survey
import com.trendx.app.models.SurveyQuestion
import com.trendx.app.theme.PollCoverStyle
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.surfaceCard
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.TrendXProfileImage

@Composable
fun SurveyDetailScreen(
    survey: Survey,
    onClose: () -> Unit,
    onStart: () -> Unit,
    onOpenAnalytics: () -> Unit,
    modifier: Modifier = Modifier
) {
    DetailScreenScaffold(title = survey.title, onClose = onClose, modifier = modifier) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            SurveyHero(survey)
            StartCta(survey, onStart)
            QuestionsCard(survey)
            AnalyticsCta(onOpenAnalytics)
        }
    }
}

@Composable
private fun SurveyHero(survey: Survey) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .surfaceCard(padding = 16.dp, radius = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Cover
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(140.dp)
                .clip(RoundedCornerShape(20.dp))
                .background(survey.coverStyle.gradient),
            contentAlignment = Alignment.Center
        ) {
            if (!survey.imageUrl.isNullOrBlank()) {
                TrendXProfileImage(
                    urlString = survey.imageUrl,
                    modifier = Modifier.fillMaxWidth().height(140.dp)
                        .clip(RoundedCornerShape(20.dp)),
                    fallback = { CoverGlyph(survey.coverStyle) }
                )
            } else {
                CoverGlyph(survey.coverStyle)
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(survey.title,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                    color = TrendXColors.Ink, lineHeight = 30.sp))
            if (survey.description.isNotBlank()) {
                Text(survey.description,
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                        color = TrendXColors.SecondaryInk, lineHeight = 19.sp))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatChip(icon = Icons.Filled.PeopleAlt, value = "${survey.totalResponses}",
                    label = "مشارك", tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
                StatChip(icon = Icons.Filled.CheckCircle, value = "${survey.completionRate.toInt()}%",
                    label = "إكمال", tint = TrendXColors.Success, modifier = Modifier.weight(1f))
                StatChip(icon = Icons.Filled.AccessTime, value = formatTime(survey.avgCompletionSeconds),
                    label = "متوسط", tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
                StatChip(icon = Icons.Filled.Star, value = "+${survey.rewardPoints}",
                    label = "نقطة", tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun CoverGlyph(style: PollCoverStyle) {
    Column(horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(style.glyph, contentDescription = null,
            tint = Color.White.copy(alpha = 0.92f), modifier = Modifier.size(32.dp))
        Text(style.heroPhrase,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                color = Color.White))
    }
}

@Composable
private fun StatChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String, label: String, tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp),
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(tint.copy(alpha = 0.07f))
            .padding(vertical = 8.dp, horizontal = 6.dp)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(11.dp))
        Text(value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                color = TrendXColors.Ink))
        Text(label,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 9.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun StartCta(survey: Survey, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(14.dp, RoundedCornerShape(18.dp), clip = false,
                ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXGradients.Primary)
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(Icons.Filled.PlayCircleFilled, contentDescription = null,
            tint = Color.White, modifier = Modifier.size(18.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("ابدأ الإجابة",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 15.sp,
                    color = Color.White))
            Text("${survey.questionCount} أسئلة · مكافأة ${survey.rewardPoints} نقطة",
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.85f)))
        }
        Icon(Icons.Filled.KeyboardArrowLeft, contentDescription = null,
            tint = Color.White, modifier = Modifier.size(12.dp))
    }
}

@Composable
private fun QuestionsCard(survey: Survey) {
    Column(
        modifier = Modifier.fillMaxWidth().surfaceCard(padding = 18.dp, radius = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("أسئلة الاستبيان",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp,
                    color = TrendXColors.Ink),
                modifier = Modifier.weight(1f))
            Text("${survey.questionCount} سؤال",
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk))
        }
        survey.questions.forEachIndexed { idx, q ->
            QuestionRow(idx, q, survey.coverStyle)
        }
    }
}

@Composable
private fun QuestionRow(index: Int, q: SurveyQuestion, accent: PollCoverStyle) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.PaleFill)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(30.dp).clip(CircleShape).background(accent.wash)
        ) {
            Text("${index + 1}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = accent.tint))
        }
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            Text(q.title,
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                    color = TrendXColors.Ink, lineHeight = 18.sp),
                maxLines = 2)
            val leader = q.options.maxByOrNull { it.percentage }
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("${q.options.size} خيارات",
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                        color = TrendXColors.TertiaryInk))
                Text("·", style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
                Text("${q.totalVotes} إجابة",
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                        color = TrendXColors.TertiaryInk))
                if (leader != null) {
                    Text("·", style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
                    Text("مُتصدّر: ${leader.percentage.toInt()}%",
                        style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                            color = accent.tint))
                }
            }
        }
        Icon(Icons.Filled.BarChart, contentDescription = null,
            tint = TrendXColors.MutedInk, modifier = Modifier.size(12.dp))
    }
}

@Composable
private fun AnalyticsCta(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Primary.copy(alpha = 0.08f))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(Icons.Filled.BarChart, contentDescription = null,
            tint = TrendXColors.Primary, modifier = Modifier.size(14.dp))
        Text("فتح التحليل الشامل للاستبيان",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp,
                color = TrendXColors.Primary),
            modifier = Modifier.weight(1f))
        Icon(Icons.Filled.KeyboardArrowLeft, contentDescription = null,
            tint = TrendXColors.Primary, modifier = Modifier.size(11.dp))
    }
}

private fun formatTime(s: Int): String = if (s >= 60) "${s / 60}د" else "${s}ث"
