package com.trendx.app.ui.screens.intelligence

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
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.SquareFoot
import androidx.compose.material.icons.filled.Star
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
import com.trendx.app.networking.MyChallengePredictionDto
import com.trendx.app.networking.WeeklyChallengeDto
import com.trendx.app.networking.predictChallenge
import com.trendx.app.networking.thisWeekChallenge
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlinx.coroutines.launch

@Composable
fun WeeklyChallengeScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var challenge by remember { mutableStateOf<WeeklyChallengeDto?>(null) }
    var prediction by remember { mutableStateOf(50f) }
    var isLoading by remember { mutableStateOf(true) }
    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val client = vm.apiClient
    val accessToken = vm.accessToken

    suspend fun load() {
        val token = accessToken
        if (token == null) {
            isLoading = false
            errorMessage = "سجّل الدخول لعرض تحدّي الأسبوع"
            return
        }
        isLoading = true
        runCatching { client.thisWeekChallenge(token) }
            .onSuccess {
                challenge = it
                it.myPrediction?.let { mine -> prediction = mine.predictedPct.toFloat() }
                errorMessage = null
            }
            .onFailure { errorMessage = it.message }
        isLoading = false
    }

    LaunchedEffect(Unit) { load() }

    val backgroundGradient = Brush.verticalGradient(
        colors = listOf(
            TrendXColors.Background,
            TrendXColors.AiIndigo.copy(alpha = 0.05f),
            TrendXColors.Primary.copy(alpha = 0.08f)
        )
    )

    DetailScreenScaffold(title = "تحدّي هذا الأسبوع", onClose = onClose, modifier = modifier) {
        Box(modifier = Modifier.fillMaxSize().background(backgroundGradient)) {
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp).padding(top = 14.dp, bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp)
            ) {
                val c = challenge
                when {
                    c != null -> {
                        WeeklyHero(c)
                        if (c.myPrediction != null) {
                            WeeklyResultCard(c, c.myPrediction)
                        } else {
                            WeeklyPredictionPanel(
                                metricLabel = c.metricLabel,
                                prediction = prediction,
                                onChange = { prediction = it },
                                isSubmitting = isSubmitting,
                                onSubmit = {
                                    val token = accessToken ?: return@WeeklyPredictionPanel
                                    scope.launch {
                                        isSubmitting = true
                                        runCatching {
                                            client.predictChallenge(
                                                id = c.id,
                                                predictedPct = prediction.toInt(),
                                                accessToken = token
                                            )
                                        }.onSuccess { load() }
                                            .onFailure { errorMessage = it.message }
                                        isSubmitting = false
                                    }
                                }
                            )
                        }
                        WeeklyStatsRow(c)
                    }
                    isLoading -> WeeklyLoadingState()
                    else -> WeeklyErrorState(errorMessage)
                }
            }
        }
    }
}

@Composable
private fun WeeklyHero(c: WeeklyChallengeDto) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(22.dp, RoundedCornerShape(28.dp), clip = false,
                ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
            .clip(RoundedCornerShape(28.dp))
            .background(Brush.linearGradient(
                colors = listOf(TrendXColors.AiIndigo, TrendXColors.AiViolet, TrendXColors.Primary)
            ))
            .padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Pill(text = "تحدّي الأسبوع", icon = Icons.Filled.GpsFixed)
            Spacer(Modifier.weight(1f))
            Pill(text = "+${c.rewardPoints}", icon = Icons.Filled.Star)
        }
        Text(c.question,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 22.sp,
                color = Color.White, lineHeight = 30.sp))
        c.description?.let { d ->
            Text(d,
                style = TextStyle(fontSize = 13.sp, color = Color.White.copy(alpha = 0.82f),
                    lineHeight = 19.sp))
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Filled.AccessTime, contentDescription = null,
                tint = Color.White.copy(alpha = 0.92f), modifier = Modifier.size(12.dp))
            Text(remainingLabel(c.closesAt),
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.92f)))
        }
    }
}

@Composable
private fun Pill(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.18f))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Icon(icon, contentDescription = null, tint = Color.White,
            modifier = Modifier.size(11.dp))
        Text(text,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                color = Color.White))
    }
}

@Composable
private fun WeeklyPredictionPanel(
    metricLabel: String,
    prediction: Float,
    onChange: (Float) -> Unit,
    isSubmitting: Boolean,
    onSubmit: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(TrendXColors.Surface)
            .padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        Text("توقّعك لـ $metricLabel",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                color = TrendXColors.SecondaryInk))
        Row(
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("${prediction.toInt()}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 64.sp,
                    color = TrendXColors.Primary))
            Text("%",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 28.sp,
                    color = TrendXColors.Primary),
                modifier = Modifier.padding(bottom = 6.dp))
        }
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            Slider(
                value = prediction,
                onValueChange = onChange,
                valueRange = 0f..100f,
                steps = 99,
                colors = SliderDefaults.colors(
                    thumbColor = TrendXColors.Primary,
                    activeTrackColor = TrendXColors.Primary,
                    inactiveTrackColor = TrendXColors.Primary.copy(alpha = 0.2f)
                )
            )
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            Text("0%", style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                color = TrendXColors.TertiaryInk))
            Spacer(Modifier.weight(1f))
            Text("50%", style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                color = TrendXColors.TertiaryInk))
            Spacer(Modifier.weight(1f))
            Text("100%", style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                color = TrendXColors.TertiaryInk))
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(14.dp, RoundedCornerShape(18.dp), clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .clip(RoundedCornerShape(18.dp))
                .background(TrendXGradients.Primary)
                .clickable(enabled = !isSubmitting, onClick = onSubmit)
                .padding(vertical = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (isSubmitting) {
                    CircularProgressIndicator(color = Color.White,
                        modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                }
                Text(if (isSubmitting) "جاري الإرسال…" else "أرسل توقّعي",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                        color = Color.White))
                if (!isSubmitting) {
                    Icon(Icons.Filled.Send, contentDescription = null, tint = Color.White,
                        modifier = Modifier.size(13.dp))
                }
            }
        }
    }
}

@Composable
private fun WeeklyResultCard(c: WeeklyChallengeDto, mine: MyChallengePredictionDto) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(TrendXColors.Surface)
            .padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(Icons.Filled.CheckCircle, contentDescription = null,
                tint = TrendXColors.Success, modifier = Modifier.size(16.dp))
            Text("تم تسجيل توقّعك",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                    color = TrendXColors.Ink))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            ResultTile(icon = Icons.Filled.GpsFixed, label = "توقّعك",
                value = "${mine.predictedPct}%", tint = TrendXColors.Primary,
                modifier = Modifier.weight(1f))
            c.targetPct?.let {
                ResultTile(icon = Icons.Filled.Flag, label = "النتيجة الفعلية",
                    value = "$it%", tint = TrendXColors.Accent,
                    modifier = Modifier.weight(1f))
            }
            mine.distance?.let {
                val tint = if (it <= 5) TrendXColors.Success else TrendXColors.AiViolet
                ResultTile(icon = Icons.Filled.SquareFoot, label = "الفارق",
                    value = "$it%", tint = tint, modifier = Modifier.weight(1f))
            }
        }
        if (mine.rank != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(TrendXColors.Accent.copy(alpha = 0.10f))
                    .padding(14.dp)
            ) {
                Icon(Icons.Filled.EmojiEvents, contentDescription = null,
                    tint = TrendXColors.Accent, modifier = Modifier.size(16.dp))
                Text("ترتيبك: #${mine.rank}",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                        color = TrendXColors.Ink))
                Spacer(Modifier.weight(1f))
                Text("من ${c.totalPredictions} مشارك",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                        color = TrendXColors.TertiaryInk))
            }
        } else {
            Text("سنُعلن النتائج عند إغلاق التحدّي.",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                    color = TrendXColors.SecondaryInk))
        }
    }
}

@Composable
private fun ResultTile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String, value: String, tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(tint.copy(alpha = 0.08f))
            .padding(vertical = 12.dp)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(13.dp))
        Text(value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 18.sp,
                color = TrendXColors.Ink))
        Text(label,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun WeeklyStatsRow(c: WeeklyChallengeDto) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatTile(icon = Icons.Filled.PeopleAlt, value = "${c.totalPredictions}",
            label = "مشاركين", modifier = Modifier.weight(1f))
        StatTile(icon = Icons.Filled.CalendarMonth, value = weekShort(c.weekStart),
            label = "أسبوع", modifier = Modifier.weight(1f))
        StatTile(icon = Icons.Filled.Bolt, value = statusLabel(c.status),
            label = "الحالة", modifier = Modifier.weight(1f))
    }
}

@Composable
private fun StatTile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String, label: String, modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.Surface)
            .padding(vertical = 10.dp)
    ) {
        Icon(icon, contentDescription = null, tint = TrendXColors.Primary,
            modifier = Modifier.size(12.dp))
        Text(value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                color = TrendXColors.Ink))
        Text(label,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 9.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun WeeklyLoadingState() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        CircularProgressIndicator(color = TrendXColors.Primary,
            modifier = Modifier.size(32.dp))
        Text("جاري تحميل تحدّي الأسبوع…",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                color = TrendXColors.SecondaryInk))
    }
}

@Composable
private fun WeeklyErrorState(message: String?) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(message ?: "تعذّر تحميل التحدّي",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                color = TrendXColors.SecondaryInk),
            textAlign = TextAlign.Center)
    }
}

private fun remainingLabel(closesAt: String): String {
    val date = parseIso(closesAt) ?: return "ينتهي قريباً"
    val now = System.currentTimeMillis()
    val interval = (date - now) / 1000L
    if (interval <= 0) return "أُغلق التحدّي"
    val days = (interval / 86_400).toInt()
    val hours = ((interval % 86_400) / 3_600).toInt()
    return if (days >= 1) "متبقي $days يوم و$hours ساعة" else "متبقي $hours ساعة"
}

private fun weekShort(weekStart: String): String {
    if (weekStart.length < 10) return weekStart
    return weekStart.substring(5)
}

private fun statusLabel(status: String): String = when (status) {
    "open" -> "مفتوح"; "settled" -> "أُعلن"; "closed" -> "أُغلق"
    else -> status
}

private fun parseIso(iso: String): Long? = runCatching {
    val instant = java.time.OffsetDateTime.parse(iso).toInstant()
    instant.toEpochMilli()
}.getOrNull()
