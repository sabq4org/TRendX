package com.trendx.app.ui.screens.intelligence

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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SignalCellularAlt
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.networking.DailyPulseDto
import com.trendx.app.networking.PulseOptionDto
import com.trendx.app.networking.PulseResponseDto
import com.trendx.app.networking.UserStreakDto
import com.trendx.app.networking.myStreak
import com.trendx.app.networking.pulseRespond
import com.trendx.app.networking.pulseToday
import com.trendx.app.networking.pulseTodayAnonymous
import com.trendx.app.networking.pulseYesterday
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlinx.coroutines.async
import kotlinx.coroutines.launch

// 1-for-1 port of TRENDX/Screens/PulseTodayScreen.swift. Reads /pulse/today
// (or /pulse/today/anon as fallback) + /me/streak + /pulse/yesterday and
// posts to /pulse/today/respond.
@Composable
fun PulseTodayScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var pulse by remember { mutableStateOf<DailyPulseDto?>(null) }
    var streak by remember { mutableStateOf<UserStreakDto?>(null) }
    var yesterday by remember { mutableStateOf<DailyPulseDto?>(null) }
    var picked by remember { mutableStateOf<Int?>(null) }
    var predictedPct by remember { mutableStateOf(50f) }
    var isSubmitting by remember { mutableStateOf(false) }
    var lastResponse by remember { mutableStateOf<PulseResponseDto?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var loaded by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()
    val client = vm.apiClient
    val accessToken = vm.accessToken

    suspend fun loadAll() {
        errorMessage = null
        var anon: DailyPulseDto? = null
        try {
            anon = client.pulseTodayAnonymous()
        } catch (t: Throwable) {
            errorMessage = t.message
        }

        val token = accessToken
        if (token != null) {
            scope.launch {
                val pulseDeferred = scope.async { runCatching { client.pulseToday(token) }.getOrNull() }
                val streakDeferred = scope.async { runCatching { client.myStreak(token) }.getOrNull() }
                val yestDeferred = scope.async { runCatching { client.pulseYesterday(token) }.getOrNull() }
                val p = pulseDeferred.await()
                val s = streakDeferred.await()
                val y = yestDeferred.await()
                pulse = p ?: anon
                streak = s
                yesterday = y?.pulse
                if (pulse != null) errorMessage = null
                loaded = true
            }
        } else {
            pulse = anon
            if (anon != null) errorMessage = null
            loaded = true
        }
    }

    LaunchedEffect(Unit) { loadAll() }

    DetailScreenScaffold(title = "نبض اليوم", onClose = onClose, modifier = modifier) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            PulseHeader()

            val current = pulse
            when {
                current != null -> {
                    PulseStatRow(streak = streak, totalResponses = current.totalResponses,
                        rewardPoints = current.rewardPoints)
                    PulseQuestionCard(
                        pulse = current,
                        picked = picked,
                        onPick = { picked = it },
                        predictedPct = predictedPct,
                        onPredictionChange = { predictedPct = it },
                        isSubmitting = isSubmitting,
                        lastResponse = lastResponse,
                        canSubmit = picked != null && !isSubmitting && accessToken != null,
                        onSubmit = {
                            val token = accessToken ?: return@PulseQuestionCard
                            val choice = picked ?: return@PulseQuestionCard
                            scope.launch {
                                isSubmitting = true
                                runCatching {
                                    client.pulseRespond(
                                        optionIndex = choice,
                                        predictedPct = predictedPct.toInt(),
                                        accessToken = token
                                    )
                                }.onSuccess { r ->
                                    lastResponse = r
                                    streak = r.streak
                                    pulse = r.pulse
                                }.onFailure { errorMessage = it.message }
                                isSubmitting = false
                            }
                        },
                        modifier = Modifier.padding(horizontal = 20.dp)
                    )
                    yesterday?.let {
                        PulseYesterdayCard(yesterday = it, modifier = Modifier.padding(horizontal = 20.dp))
                    }
                }
                errorMessage != null && loaded -> PulseErrorState(
                    message = errorMessage ?: "",
                    onRetry = { scope.launch { loadAll() } }
                )
                else -> PulseLoadingState()
            }
        }
    }
}

@Composable
private fun PulseHeader() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text("نبض اليوم",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                letterSpacing = 1.0.sp, color = TrendXColors.Primary))
        Text("نبض السعودية اليوم",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 32.sp,
                color = TrendXColors.Ink))
        Text("سؤال جديد كل يوم — صوّت، تنبّأ، اكتشف.",
            style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk))
    }
}

@Composable
private fun PulseStatRow(
    streak: UserStreakDto?,
    totalResponses: Int,
    rewardPoints: Int
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        PulseStatCard(
            icon = Icons.Filled.Whatshot,
            tint = TrendXColors.Accent,
            value = "${streak?.currentStreak ?: 0}",
            label = "سلسلة المشاركة",
            modifier = Modifier.weight(1f)
        )
        PulseStatCard(
            icon = Icons.Filled.PeopleAlt,
            tint = TrendXColors.Primary,
            value = "$totalResponses",
            label = "المشاركون اليوم",
            modifier = Modifier.weight(1f)
        )
        PulseStatCard(
            icon = Icons.Filled.SignalCellularAlt,
            tint = TrendXColors.AiViolet,
            value = "+$rewardPoints",
            label = "نقاط المشاركة",
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun PulseStatCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color,
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .shadow(12.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(14.dp))
        Text(value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                color = TrendXColors.Ink))
        Text(label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 10.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun PulseQuestionCard(
    pulse: DailyPulseDto,
    picked: Int?,
    onPick: (Int) -> Unit,
    predictedPct: Float,
    onPredictionChange: (Float) -> Unit,
    isSubmitting: Boolean,
    lastResponse: PulseResponseDto?,
    canSubmit: Boolean,
    onSubmit: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(16.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Filled.Bolt, contentDescription = null,
                tint = TrendXColors.Primary, modifier = Modifier.size(16.dp))
            Text("سؤال اليوم",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    letterSpacing = 0.7.sp, color = TrendXColors.Primary))
        }
        Text(pulse.question,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 22.sp,
                color = TrendXColors.Ink, lineHeight = 30.sp))

        val hasResponded = pulse.userResponded == true || lastResponse != null
        if (hasResponded) {
            val displayPulse = lastResponse?.pulse ?: pulse
            PulseResultsList(pulse = displayPulse,
                myChoice = lastResponse?.let { picked } ?: pulse.userChoice)
            lastResponse?.let { PulseRewardBanner(r = it) }
        } else {
            PulseOptionsList(pulse = pulse, picked = picked, onPick = onPick)
            PulsePredictionSlider(predictedPct = predictedPct, onChange = onPredictionChange)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (canSubmit) TrendXGradients.Primary
                                else androidx.compose.ui.graphics.SolidColor(TrendXColors.Outline))
                    .clickable(enabled = canSubmit, onClick = onSubmit)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(if (isSubmitting) "جارٍ الإرسال…" else "أرسل صوتي",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                        color = Color.White))
            }
        }
    }
}

@Composable
private fun PulseOptionsList(pulse: DailyPulseDto, picked: Int?, onPick: (Int) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        pulse.options.forEach { option ->
            val isPicked = picked == option.index
            val borderColor = if (isPicked) TrendXColors.Primary else TrendXColors.Outline
            val bgColor = if (isPicked) TrendXColors.Primary.copy(alpha = 0.06f)
                          else TrendXColors.PaleFill.copy(alpha = 0.4f)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(bgColor)
                    .border(1.dp, borderColor, RoundedCornerShape(12.dp))
                    .clickable { onPick(option.index) }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(option.text,
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                        color = TrendXColors.Ink),
                    modifier = Modifier.weight(1f))
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(22.dp)
                        .border(2.dp, borderColor, CircleShape)
                ) {
                    if (isPicked) {
                        Box(modifier = Modifier.size(12.dp).clip(CircleShape)
                            .background(TrendXColors.Primary))
                    }
                }
            }
        }
    }
}

@Composable
private fun PulsePredictionSlider(predictedPct: Float, onChange: (Float) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.06f))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("لعبة التنبّؤ — اختياري",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.6.sp, color = TrendXColors.AiViolet))
        Text("كم نسبة من تتوقّع أن يختار الخيار الأكثر تصويتاً؟",
            style = TextStyle(fontSize = 12.sp, color = TrendXColors.SecondaryInk))
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("${predictedPct.toInt()}%",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                    color = TrendXColors.AiViolet),
                modifier = Modifier.width(64.dp))
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                Slider(
                    value = predictedPct,
                    onValueChange = onChange,
                    valueRange = 0f..100f,
                    steps = 99,
                    colors = SliderDefaults.colors(
                        thumbColor = TrendXColors.AiViolet,
                        activeTrackColor = TrendXColors.AiViolet,
                        inactiveTrackColor = TrendXColors.AiViolet.copy(alpha = 0.2f)
                    ),
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun PulseResultsList(pulse: DailyPulseDto, myChoice: Int?) {
    val maxVotes = pulse.options.maxOfOrNull { it.votes } ?: 0
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        pulse.options.forEach { option ->
            val mine = myChoice == option.index
            val leading = option.votes >= maxVotes
            PulseResultRow(option = option, mine = mine, leading = leading)
        }
    }
}

@Composable
private fun PulseResultRow(option: PulseOptionDto, mine: Boolean, leading: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(option.text,
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                    color = if (mine) TrendXColors.Primary else TrendXColors.Ink))
            if (mine) {
                Spacer(Modifier.width(6.dp))
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(TrendXColors.Primary.copy(alpha = 0.12f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text("صوتك",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 9.sp,
                            color = TrendXColors.Primary))
                }
            }
            Spacer(Modifier.weight(1f))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("${option.percentage.toInt()}%  ",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = TrendXColors.Ink))
                Text("(${option.votes})",
                    style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
            }
        }
        Box(modifier = Modifier.fillMaxWidth().height(8.dp)
            .clip(RoundedCornerShape(99.dp)).background(TrendXColors.PaleFill)) {
            val fraction = (option.percentage.toFloat() / 100f).coerceIn(0f, 1f)
            if (fraction > 0f) {
                val fillBrush: Brush = when {
                    mine -> TrendXGradients.Primary
                    leading -> androidx.compose.ui.graphics.SolidColor(TrendXColors.Accent)
                    else -> androidx.compose.ui.graphics.SolidColor(TrendXColors.Outline)
                }
                Box(modifier = Modifier.fillMaxWidth(fraction).height(8.dp)
                    .clip(RoundedCornerShape(99.dp)).background(fillBrush))
            }
        }
    }
}

@Composable
private fun PulseRewardBanner(r: PulseResponseDto) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(TrendXColors.Success.copy(alpha = 0.08f))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text("شُكراً لمشاركتك! +${r.reward} نقطة",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                color = TrendXColors.Success))
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("سلسلة ${r.streak.currentStreak} يوم",
                style = TextStyle(fontSize = 11.sp, color = TrendXColors.SecondaryInk))
            if (r.streak.isPersonalBest == true) {
                Text("· رقم قياسي شخصي 🏆",
                    style = TextStyle(fontSize = 11.sp, color = TrendXColors.SecondaryInk))
            }
            r.predictionScore?.let { ps ->
                Text("· دقّتك $ps/100",
                    style = TextStyle(fontSize = 11.sp, color = TrendXColors.AiViolet))
            }
        }
    }
}

@Composable
private fun PulseYesterdayCard(yesterday: DailyPulseDto, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.06f))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("نبض الأمس",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.7.sp, color = TrendXColors.AiViolet))
        Text(yesterday.question,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 17.sp,
                color = TrendXColors.Ink))
        yesterday.aiSummary?.let { summary ->
            Text(summary,
                style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk,
                    lineHeight = 19.sp))
        }
    }
}

@Composable
private fun PulseLoadingState() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        CircularProgressIndicator(color = TrendXColors.Primary,
            modifier = Modifier.size(32.dp))
        Text("جاري تحميل نبض اليوم…",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun PulseErrorState(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp, horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Icon(Icons.Filled.SignalCellularAlt, contentDescription = null,
            tint = TrendXColors.TertiaryInk, modifier = Modifier.size(30.dp))
        Text("تعذّر تحميل النبض",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                color = TrendXColors.Ink))
        Text(message,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                color = TrendXColors.TertiaryInk),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 30.dp))
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
                .clickable(onClick = onRetry)
                .padding(horizontal = 18.dp, vertical = 10.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(Icons.Filled.Refresh, contentDescription = null,
                    tint = Color.White, modifier = Modifier.size(12.dp))
                Text("إعادة المحاولة",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                        color = Color.White))
            }
        }
    }
}
