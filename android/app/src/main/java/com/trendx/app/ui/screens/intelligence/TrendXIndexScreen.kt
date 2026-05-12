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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingFlat
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.SignalCellularAlt
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.networking.IndexMetricDto
import com.trendx.app.networking.TrendXIndexDto
import com.trendx.app.networking.trendxIndex
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlinx.coroutines.launch

@Composable
fun TrendXIndexScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var index by remember { mutableStateOf<TrendXIndexDto?>(null) }
    var loading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    suspend fun load() {
        loading = true
        errorMessage = null
        runCatching { vm.apiClient.trendxIndex() }
            .onSuccess { index = it }
            .onFailure { errorMessage = it.message }
        loading = false
    }

    LaunchedEffect(Unit) { load() }

    DetailScreenScaffold(title = "نبض السعودية", onClose = onClose, modifier = modifier) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            IndexHeader()
            when {
                loading -> Box(modifier = Modifier.fillMaxWidth().padding(40.dp),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = TrendXColors.Primary)
                }
                index != null -> {
                    IndexCompositeCard(index!!, modifier = Modifier.padding(horizontal = 20.dp))
                    IndexMetricsList(index!!.metrics, modifier = Modifier.padding(horizontal = 20.dp))
                    Text("البيانات مفتوحة للاستشهاد بشرط ذكر TRENDX كمصدر",
                        style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp))
                }
                else -> IndexErrorState(errorMessage) { scope.launch { load() } }
            }
        }
    }
}

@Composable
private fun IndexHeader() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text("TRENDX INDEX",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                letterSpacing = 1.0.sp, color = TrendXColors.Primary))
        Text("نبض السعودية",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 32.sp,
                color = TrendXColors.Ink))
        Text("لقطة يوميّة لاتجاهات الرأي في ست محاور رئيسية.",
            style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk))
    }
}

@Composable
private fun IndexCompositeCard(index: TrendXIndexDto, modifier: Modifier = Modifier) {
    val change = index.compositeChange24h
    val (dirIcon, dirColor) = directionFor(change)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(16.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("المؤشّر المركّب",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.8.sp, color = TrendXColors.Primary))
        Row(verticalAlignment = Alignment.Bottom) {
            Text("${index.composite}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 84.sp,
                    color = TrendXColors.Primary))
            Text(" / 100",
                style = TextStyle(fontSize = 18.sp, color = TrendXColors.TertiaryInk),
                modifier = Modifier.padding(bottom = 12.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(dirIcon, contentDescription = null, tint = dirColor,
                modifier = Modifier.size(16.dp))
            Text("${if (change > 0) "+" else ""}$change عن الأمس",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = dirColor))
        }
        Text("استناداً إلى ${index.totalResponses} إجابة في آخر 7 أيام",
            style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun IndexMetricsList(metrics: List<IndexMetricDto>, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        metrics.forEach { m -> IndexMetricCard(m) }
    }
}

@Composable
private fun IndexMetricCard(m: IndexMetricDto) {
    val (dirIcon, dirColor) = when (m.direction) {
        "up" -> Icons.AutoMirrored.Filled.TrendingUp to TrendXColors.Success
        "down" -> Icons.AutoMirrored.Filled.TrendingDown to TrendXColors.Error
        else -> Icons.AutoMirrored.Filled.TrendingFlat to TrendXColors.TertiaryInk
    }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(10.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(m.name,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                    color = TrendXColors.Primary),
                modifier = Modifier.weight(1f))
            Icon(dirIcon, contentDescription = null, tint = dirColor,
                modifier = Modifier.size(16.dp))
        }
        Row(verticalAlignment = Alignment.Bottom) {
            Text("${m.value}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 40.sp,
                    color = TrendXColors.Ink))
            Text(" / 100",
                style = TextStyle(fontSize = 14.sp, color = TrendXColors.TertiaryInk),
                modifier = Modifier.padding(bottom = 6.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("${m.sampleSize} إجابة",
                style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
            Text("·",
                style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
            Text("${if (m.change24h > 0) "+" else ""}${m.change24h}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    color = dirColor))
        }
        Text(m.blurb,
            style = TextStyle(fontSize = 12.sp, color = TrendXColors.SecondaryInk,
                lineHeight = 18.sp))
        Box(modifier = Modifier.fillMaxWidth().height(6.dp)
            .clip(RoundedCornerShape(99.dp)).background(TrendXColors.PaleFill)) {
            val fraction = (m.value.toFloat() / 100f).coerceIn(0f, 1f)
            if (fraction > 0f) {
                Box(modifier = Modifier.fillMaxWidth(fraction).height(6.dp)
                    .clip(RoundedCornerShape(99.dp)).background(TrendXGradients.Primary))
            }
        }
    }
}

@Composable
private fun IndexErrorState(message: String?, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(Icons.Filled.SignalCellularAlt, contentDescription = null,
            tint = TrendXColors.TertiaryInk, modifier = Modifier.size(32.dp))
        Text("تعذّر تحميل المؤشّر",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                color = TrendXColors.Ink))
        message?.let {
            Text(it,
                style = TextStyle(fontSize = 12.sp, color = TrendXColors.TertiaryInk),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 30.dp))
        }
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
                .clickable(onClick = onRetry)
                .padding(horizontal = 18.dp, vertical = 9.dp),
            contentAlignment = Alignment.Center
        ) {
            Text("إعادة المحاولة",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = Color.White))
        }
    }
}

private fun directionFor(change: Int): Pair<ImageVector, Color> = when {
    change > 0 -> Icons.AutoMirrored.Filled.TrendingUp to TrendXColors.Success
    change < 0 -> Icons.AutoMirrored.Filled.TrendingDown to TrendXColors.Error
    else -> Icons.AutoMirrored.Filled.TrendingFlat to TrendXColors.TertiaryInk
}
