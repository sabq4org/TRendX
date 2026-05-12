package com.trendx.app.ui.screens.surveys

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material.icons.filled.QuestionMark
import androidx.compose.material.icons.filled.StarRate
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.content.Intent
import com.trendx.app.models.MemberTier
import com.trendx.app.models.PollOption
import com.trendx.app.models.Survey
import com.trendx.app.models.SurveyQuestion
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.TrendXConfetti

@Composable
fun SurveyTakingSheet(
    survey: Survey,
    currentUserPoints: Int,
    onClose: () -> Unit,
    onSubmit: (answers: List<Pair<String, String>>, completionSeconds: Int) -> Unit,
    modifier: Modifier = Modifier
) {
    var currentIndex by remember { mutableIntStateOf(0) }
    val answers = remember { mutableStateMapOf<String, String>() }
    val startedAt by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var didSubmit by remember { mutableStateOf(false) }
    var submittedSeconds by remember { mutableIntStateOf(0) }

    val questions = survey.questions
    val currentQuestion = questions.getOrNull(currentIndex)
    val isLast = currentIndex == questions.size - 1
    val canAdvance = currentQuestion?.let { answers[it.id] != null } ?: false
    val progress = if (questions.isEmpty()) 0f else currentIndex.toFloat() / questions.size

    DetailScreenScaffold(
        title = if (didSubmit) "تمّت المشاركة" else survey.title,
        onClose = onClose,
        modifier = modifier
    ) {
        Box(modifier = Modifier.fillMaxSize().background(TrendXColors.Background)) {
            when {
                didSubmit -> CompletionView(survey = survey, points = currentUserPoints,
                    elapsedSeconds = submittedSeconds, onClose = onClose)
                currentQuestion != null -> QuestionView(
                    survey = survey,
                    question = currentQuestion,
                    index = currentIndex,
                    progress = progress,
                    selectedOptionId = answers[currentQuestion.id],
                    canAdvance = canAdvance,
                    isLast = isLast,
                    onPick = { answers[currentQuestion.id] = it },
                    onPrev = { if (currentIndex > 0) currentIndex -= 1 },
                    onNext = {
                        if (isLast) {
                            val payload = answers.entries.map { it.key to it.value }
                            val elapsed = ((System.currentTimeMillis() - startedAt) / 1000).toInt()
                                .coerceAtLeast(1)
                            submittedSeconds = elapsed
                            onSubmit(payload, elapsed)
                            didSubmit = true
                        } else currentIndex += 1
                    }
                )
                else -> Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(Icons.Filled.HelpOutline, contentDescription = null,
                        tint = TrendXColors.TertiaryInk, modifier = Modifier.size(38.dp))
                    Spacer(Modifier.height(12.dp))
                    Text("لا توجد أسئلة في هذا الاستبيان",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                            color = TrendXColors.SecondaryInk))
                }
            }
        }
    }
}

@Composable
private fun QuestionView(
    survey: Survey,
    question: SurveyQuestion,
    index: Int,
    progress: Float,
    selectedOptionId: String?,
    canAdvance: Boolean,
    isLast: Boolean,
    onPick: (String) -> Unit,
    onPrev: () -> Unit,
    onNext: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp,
                vertical = 16.dp).padding(bottom = 6.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("سؤال ${index + 1} من ${survey.questions.size}",
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                        color = TrendXColors.SecondaryInk),
                    modifier = Modifier.weight(1f))
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(TrendXColors.Primary.copy(alpha = 0.10f))
                        .padding(horizontal = 8.dp, vertical = 3.dp)
                ) {
                    Text("+${question.rewardPoints} نقطة",
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp,
                            color = TrendXColors.Primary))
                }
            }
            LinearProgressIndicator(
                progress = { progress },
                color = TrendXColors.Primary,
                trackColor = TrendXColors.PaleFill,
                modifier = Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(4.dp))
            )
        }

        Column(
            modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Text(question.title,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 22.sp,
                    color = TrendXColors.Ink, lineHeight = 30.sp))
            question.description?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = TextStyle(fontSize = 14.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 20.sp))
            }
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                question.options.forEach { option ->
                    OptionRow(option, selectedOptionId == option.id) { onPick(option.id) }
                }
            }
        }

        // Footer CTA
        Column(modifier = Modifier.fillMaxWidth().background(TrendXColors.Background)) {
            Box(modifier = Modifier.fillMaxWidth().height(1.dp)
                .background(TrendXColors.Outline.copy(alpha = 0.4f)))
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (index > 0) {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(TrendXColors.Surface)
                            .clickable(onClick = onPrev)
                            .padding(horizontal = 18.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null,
                            tint = TrendXColors.SecondaryInk, modifier = Modifier.size(14.dp))
                        Text("السابق",
                            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                                color = TrendXColors.SecondaryInk))
                    }
                }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .shadow(if (canAdvance) 10.dp else 0.dp, RoundedCornerShape(14.dp),
                            clip = false, ambientColor = TrendXColors.Primary,
                            spotColor = TrendXColors.Primary)
                        .clip(RoundedCornerShape(14.dp))
                        .background(if (canAdvance) TrendXGradients.Primary
                                    else androidx.compose.ui.graphics.SolidColor(
                                        TrendXColors.TertiaryInk.copy(alpha = 0.4f)))
                        .clickable(enabled = canAdvance, onClick = onNext)
                        .padding(vertical = 15.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(if (isLast) "إرسال الإجابات" else "التالي",
                            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 15.sp,
                                color = Color.White))
                        Icon(if (isLast) Icons.Filled.Check
                             else Icons.Filled.KeyboardArrowLeft,
                            contentDescription = null, tint = Color.White,
                            modifier = Modifier.size(13.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun OptionRow(option: PollOption, selected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (selected) TrendXColors.Primary.copy(alpha = 0.08f)
                        else TrendXColors.Surface)
            .border(if (selected) 1.5.dp else 0.dp,
                if (selected) TrendXColors.Primary else Color.Transparent,
                RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(22.dp)
                .border(2.dp,
                    if (selected) TrendXColors.Primary
                    else TrendXColors.TertiaryInk.copy(alpha = 0.5f),
                    CircleShape)
        ) {
            if (selected) {
                Box(modifier = Modifier.size(12.dp).clip(CircleShape)
                    .background(TrendXColors.Primary))
            }
        }
        Text(option.text,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                color = if (selected) TrendXColors.Ink else TrendXColors.SecondaryInk,
                lineHeight = 22.sp),
            modifier = Modifier.weight(1f))
    }
}

@Composable
private fun CompletionView(
    survey: Survey,
    points: Int,
    elapsedSeconds: Int,
    onClose: () -> Unit
) {
    val context = LocalContext.current
    Box(modifier = Modifier.fillMaxSize().background(
        Brush.verticalGradient(listOf(
            TrendXColors.Background,
            TrendXColors.Primary.copy(alpha = 0.08f),
            TrendXColors.Accent.copy(alpha = 0.06f)
        ))
    )) {
        TrendXConfetti(modifier = Modifier.fillMaxSize())
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp).padding(top = 24.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            CompletionSeal()
            CompletionHeadline(survey)
            CompletionStats(survey, elapsedSeconds)
            CompletionTier(points)
            CompletionActions(survey, context, onClose)
        }
    }
}

@Composable
private fun CompletionSeal() {
    Box(contentAlignment = Alignment.Center, modifier = Modifier.size(148.dp)) {
        Box(modifier = Modifier.size(148.dp).clip(CircleShape)
            .background(TrendXColors.Primary.copy(alpha = 0.10f)))
        Box(modifier = Modifier.size(120.dp)
            .border(2.dp, TrendXColors.Primary.copy(alpha = 0.28f), CircleShape))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(22.dp, CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .size(96.dp).clip(CircleShape).background(TrendXGradients.Primary)
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White,
                modifier = Modifier.size(40.dp))
        }
    }
}

@Composable
private fun CompletionHeadline(survey: Survey) {
    Column(horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("صوتك سُجّل ✨",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 26.sp,
                color = TrendXColors.Ink))
        Text("جاوبت على ${survey.questions.size} سؤال — رأيك جزء من نبض الرأي السعودي.",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.5.sp,
                color = TrendXColors.SecondaryInk),
            textAlign = TextAlign.Center)
    }
}

@Composable
private fun CompletionStats(survey: Survey, elapsedSeconds: Int) {
    Row(modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        CompletionStatTile(icon = Icons.Filled.StarRate, value = "+${survey.rewardPoints}",
            label = "نقطة جديدة", tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
        CompletionStatTile(icon = Icons.Filled.QuestionMark, value = "${survey.questions.size}",
            label = "إجابة", tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
        CompletionStatTile(icon = Icons.Filled.AccessTime, value = formatSeconds(elapsedSeconds),
            label = "الوقت", tint = TrendXColors.AiIndigo, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun CompletionStatTile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String, label: String, tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(tint.copy(alpha = 0.08f))
            .border(1.dp, tint.copy(alpha = 0.14f), RoundedCornerShape(16.dp))
            .padding(vertical = 14.dp)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(14.dp))
        Text(value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 20.sp,
            color = TrendXColors.Ink))
        Text(label, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.5.sp,
            color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun CompletionTier(points: Int) {
    val tier = MemberTier.from(points)
    val pointsToNext = tier.pointsToNext(points)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, tier.tint.copy(alpha = 0.16f), RoundedCornerShape(18.dp))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(42.dp).clip(CircleShape).background(tier.gradient)
        ) {
            Icon(tier.icon, contentDescription = null, tint = Color.White,
                modifier = Modifier.size(16.dp))
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("مستواك:",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                        color = TrendXColors.TertiaryInk))
                Text(tier.label,
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = TrendXColors.Ink))
            }
            val next = tier.next
            if (next != null && pointsToNext > 0) {
                Text("يبقى $pointsToNext نقطة للوصول إلى ${next.label}",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                        color = TrendXColors.SecondaryInk))
            } else {
                Text("وصلت لأعلى مستوى — ✦",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                        color = tier.tint))
            }
        }
    }
}

@Composable
private fun CompletionActions(survey: Survey, context: android.content.Context, onClose: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(TrendXColors.Primary.copy(alpha = 0.10f))
                .clickable {
                    val text = "شاركت في «${survey.title}» على TRENDX وحصلت على ${survey.rewardPoints} نقطة. شاركني رأيك!"
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    context.startActivity(Intent.createChooser(intent, "مشاركة"))
                }
                .padding(vertical = 13.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Filled.IosShare, contentDescription = null,
                    tint = TrendXColors.PrimaryDeep, modifier = Modifier.size(13.dp))
                Text("شارك مع صديق",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = TrendXColors.PrimaryDeep))
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(14.dp, RoundedCornerShape(16.dp), clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .clip(RoundedCornerShape(16.dp))
                .background(TrendXGradients.Primary)
                .clickable(onClick = onClose)
                .padding(vertical = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("استكشف استبيانات أخرى",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                        color = Color.White))
                Icon(Icons.Filled.ArrowBack, contentDescription = null,
                    tint = Color.White, modifier = Modifier.size(12.dp))
            }
        }
    }
}

private fun formatSeconds(s: Int): String {
    if (s >= 60) return "${s / 60}د ${s % 60}ث"
    return "${s}ث"
}
