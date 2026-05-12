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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.content.Intent
import androidx.compose.ui.platform.LocalContext
import com.trendx.app.networking.DnaAxisDto
import com.trendx.app.networking.OpinionDnaDto
import com.trendx.app.networking.myOpinionDNA
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlin.math.abs

@Composable
fun OpinionDNAScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var dna by remember { mutableStateOf<OpinionDnaDto?>(null) }
    var loading by remember { mutableStateOf(true) }
    val accessToken = vm.accessToken

    LaunchedEffect(Unit) {
        val token = accessToken
        if (token == null) { loading = false; return@LaunchedEffect }
        runCatching { vm.apiClient.myOpinionDNA(token) }.onSuccess { dna = it }
        loading = false
    }

    DetailScreenScaffold(title = "هويّتك في الرأي", onClose = onClose, modifier = modifier) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            DnaHeader()
            when {
                loading -> Box(modifier = Modifier.fillMaxWidth().padding(40.dp),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = TrendXColors.AiViolet)
                }
                dna != null -> {
                    DnaArchetypeCard(dna!!, modifier = Modifier.padding(horizontal = 20.dp))
                    DnaAxesGrid(dna!!.axes, modifier = Modifier.padding(horizontal = 20.dp))
                    DnaShareCard(dna!!, modifier = Modifier.padding(horizontal = 20.dp))
                }
                else -> DnaNotReadyCard(modifier = Modifier.padding(horizontal = 20.dp))
            }
        }
    }
}

@Composable
private fun DnaHeader() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text("OPINION DNA",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                letterSpacing = 1.0.sp, color = TrendXColors.AiViolet))
        Text("هويّتك في الرأي",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 32.sp,
                color = TrendXColors.Ink))
        Text("سِتّ محاور تكشف هويّتك الفكريّة من تصويتاتك على TRENDX.",
            style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk,
                lineHeight = 19.sp))
    }
}

@Composable
private fun DnaArchetypeCard(dna: OpinionDnaDto, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Brush.linearGradient(
                colors = listOf(
                    TrendXColors.AiViolet.copy(alpha = 0.08f),
                    TrendXColors.AiCyan.copy(alpha = 0.04f)
                )
            ))
            .border(1.dp, TrendXColors.AiViolet.copy(alpha = 0.18f), RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("شخصيّتك في الرأي",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.8.sp, color = TrendXColors.AiViolet))
        Text(dna.archetype.title,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 36.sp,
                color = TrendXColors.AiViolet))
        Text(dna.archetype.blurb,
            style = TextStyle(fontSize = 14.sp, color = TrendXColors.SecondaryInk,
                lineHeight = 21.sp))
    }
}

@Composable
private fun DnaAxesGrid(axes: List<DnaAxisDto>, modifier: Modifier = Modifier) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = modifier.fillMaxWidth()
    ) {
        axes.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                row.forEach { axis ->
                    Box(modifier = Modifier.weight(1f)) {
                        DnaAxisCard(axis)
                    }
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun DnaAxisCard(a: DnaAxisDto) {
    val tilt = a.score - 50
    val label = if (tilt > 0) a.labelHigh else a.labelLow
    val intensity = when {
        abs(tilt) >= 25 -> "قوي"
        abs(tilt) >= 10 -> "معتدل"
        else -> "متوازن"
    }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(12.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(intensity,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp,
                    letterSpacing = 0.6.sp, color = TrendXColors.AiViolet))
            Spacer(Modifier.weight(1f))
            Text("${a.score}/100",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk))
        }
        Text(label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp,
                color = TrendXColors.Ink, lineHeight = 22.sp))
        DnaBipolarBar(tilt = tilt)
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(a.labelLow,
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 9.sp,
                    color = TrendXColors.TertiaryInk))
            Spacer(Modifier.weight(1f))
            Text(a.labelHigh,
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 9.sp,
                    color = TrendXColors.TertiaryInk))
        }
    }
}

@Composable
private fun DnaBipolarBar(tilt: Int) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(10.dp)
            .clip(RoundedCornerShape(99.dp))
            .background(TrendXColors.PaleFill)
            .drawWithContent {
                drawContent()
                val w = size.width
                val barWidth = (w * abs(tilt) / 100f).coerceAtLeast(0f)
                val mid = w / 2f
                if (tilt >= 0) {
                    drawRect(
                        color = TrendXColors.AiViolet,
                        topLeft = Offset(mid, 0f),
                        size = Size(barWidth, size.height)
                    )
                } else {
                    drawRect(
                        color = TrendXColors.AiViolet,
                        topLeft = Offset(mid - barWidth, 0f),
                        size = Size(barWidth, size.height)
                    )
                }
                drawLine(
                    color = TrendXColors.Outline,
                    start = Offset(mid, 0f),
                    end = Offset(mid, size.height),
                    strokeWidth = 1f
                )
            }
    )
}

@Composable
private fun DnaShareCard(dna: OpinionDnaDto, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.06f))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("جملة المشاركة",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                letterSpacing = 0.6.sp, color = TrendXColors.AiViolet))
        Text("«${dna.shareCaption}»",
            style = TextStyle(fontSize = 14.sp, color = TrendXColors.Ink,
                lineHeight = 21.sp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(TrendXColors.AiViolet)
                .clickable {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, dna.shareCaption)
                    }
                    context.startActivity(Intent.createChooser(intent, "مشاركة"))
                }
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Filled.IosShare, contentDescription = null, tint = Color.White,
                    modifier = Modifier.size(14.dp))
                Text("شارك على شبكاتك",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                        color = Color.White))
            }
        }
    }
}

@Composable
private fun DnaNotReadyCard(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(12.dp, RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Shadow, spotColor = TrendXColors.Shadow)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(Icons.Filled.AutoAwesome, contentDescription = null,
            tint = TrendXColors.AiViolet, modifier = Modifier.size(36.dp))
        Text("لم تكتمل هويّتك بعد",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 18.sp,
                color = TrendXColors.Ink))
        Text("شارك في 3 استطلاعات أو نبضات يوميّة لنبني هويّتك الفكريّة الكاملة.",
            style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk,
                lineHeight = 19.sp),
            textAlign = TextAlign.Center)
    }
}
