package com.trendx.app.ui.screens.intelligence

import androidx.compose.foundation.background
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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.networking.AccuracyLeaderItemDto
import com.trendx.app.networking.UserAccuracyDto
import com.trendx.app.networking.accuracyLeaderboard
import com.trendx.app.networking.myAccuracy
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

@Composable
fun PredictionAccuracyScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var stats by remember { mutableStateOf<UserAccuracyDto?>(null) }
    var leaderboard by remember { mutableStateOf<List<AccuracyLeaderItemDto>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    val accessToken = vm.accessToken

    LaunchedEffect(Unit) {
        val token = accessToken
        if (token == null) { loading = false; return@LaunchedEffect }
        coroutineScope {
            val s = async { runCatching { vm.apiClient.myAccuracy(token) }.getOrNull() }
            val b = async {
                runCatching { vm.apiClient.accuracyLeaderboard(25, token) }.getOrNull()
            }
            stats = s.await()
            leaderboard = b.await()?.items.orEmpty()
        }
        loading = false
    }

    DetailScreenScaffold(title = "دقّة التنبّؤ", onClose = onClose, modifier = modifier) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            AccuracyHeader()
            when {
                loading -> Box(modifier = Modifier.fillMaxWidth().padding(40.dp),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = TrendXColors.Primary)
                }
                else -> {
                    stats?.let {
                        AccuracyStatsCard(it, modifier = Modifier.padding(horizontal = 20.dp))
                    }
                    if (leaderboard.isNotEmpty()) {
                        AccuracyLeaderboardCard(leaderboard,
                            modifier = Modifier.padding(horizontal = 20.dp))
                    }
                    AccuracyExplainerCard(modifier = Modifier.padding(horizontal = 20.dp))
                }
            }
        }
    }
}

@Composable
private fun AccuracyHeader() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text("PREDICTIVE ACCURACY",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                letterSpacing = 1.0.sp, color = TrendXColors.AiViolet))
        Text("دقّة التنبّؤ",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 32.sp,
                color = TrendXColors.Ink))
        Text("حدسك في الرأي العامّ — قابل للقياس.",
            style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk))
    }
}

@Composable
private fun AccuracyStatsCard(s: UserAccuracyDto, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCell(label = "متوسّط الدقّة", value = "${s.averageAccuracy}/100",
                tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
            StatCell(label = "أفضل دقّة", value = "${s.bestAccuracy}/100",
                tint = TrendXColors.AiViolet, modifier = Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCell(label = "إجمالي التنبّؤات", value = "${s.predictions}",
                tint = TrendXColors.Ink, modifier = Modifier.weight(1f))
            StatCell(label = "ترتيبك المئوي",
                value = if (s.rankPercentile > 0) "أعلى من ${s.rankPercentile}%" else "—",
                tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun StatCell(label: String, value: String, tint: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .shadow(12.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(label,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp,
                letterSpacing = 0.6.sp, color = TrendXColors.TertiaryInk))
        Text(value,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 26.sp,
                color = tint))
    }
}

@Composable
private fun AccuracyLeaderboardCard(items: List<AccuracyLeaderItemDto>,
                                     modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(12.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("لوحة الشرف",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.7.sp, color = TrendXColors.Accent))
        Column {
            items.forEachIndexed { idx, item ->
                LeaderboardRow(item = item, position = idx + 1)
                if (idx < items.lastIndex) {
                    HorizontalDivider(color = TrendXColors.Outline,
                        modifier = Modifier.padding(vertical = 4.dp))
                }
            }
        }
    }
}

@Composable
private fun LeaderboardRow(item: AccuracyLeaderItemDto, position: Int) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp)
    ) {
        Text("${item.averageAccuracy}/100",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                color = TrendXColors.Ink))
        Spacer(Modifier.weight(1f))
        Text(item.name,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                color = TrendXColors.Ink))
        Spacer(Modifier.width(10.dp))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(32.dp).clip(CircleShape)
                .background(TrendXColors.Primary.copy(alpha = 0.12f))
        ) {
            Text(item.avatarInitial,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.Primary))
        }
        Spacer(Modifier.width(8.dp))
        val medalBg = when (position) {
            1 -> TrendXColors.Accent
            2 -> TrendXColors.TertiaryInk.copy(alpha = 0.6f)
            3 -> TrendXColors.Accent.copy(alpha = 0.4f)
            else -> Color.Transparent
        }
        val medalFg = if (position <= 3) Color.White else TrendXColors.TertiaryInk
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(28.dp).clip(CircleShape).background(medalBg)
        ) {
            Text("$position",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = medalFg))
        }
    }
}

@Composable
private fun AccuracyExplainerCard(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.05f))
            .padding(14.dp)
    ) {
        Text(
            "الدقّة = 100 - |تخمينك - النسبة الحقيقيّة|. مثال: تنبّأت بـ 60٪ والنتيجة 67٪ → دقّتك 93/100.",
            style = TextStyle(fontSize = 12.sp, color = TrendXColors.SecondaryInk,
                lineHeight = 19.sp)
        )
    }
}
