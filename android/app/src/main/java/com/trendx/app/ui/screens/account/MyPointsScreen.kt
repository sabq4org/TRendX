package com.trendx.app.ui.screens.account

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.Star
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.LedgerEntry
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.EmptyStateView
import kotlinx.datetime.Clock

// Mirrors MyPointsScreen + PointsLedgerRow from
// TRENDX/Screens/AccountScreen.swift. Hero card with the live points
// total + riyal equivalent, a one-line conversion explainer, then a
// real ledger fetched from `GET /points/ledger`.
@Composable
fun MyPointsScreen(
    points: Int,
    coins: Double,
    onClose: () -> Unit,
    fetchLedger: suspend () -> List<LedgerEntry>?,
    modifier: Modifier = Modifier
) {
    var ledger by remember { mutableStateOf<List<LedgerEntry>?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        isLoading = true
        ledger = fetchLedger()
        isLoading = false
    }

    DetailScreenScaffold(
        title = "النقاط",
        onClose = onClose,
        modifier = modifier
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                top = 8.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item("hero") { PointsHero(points = points, coins = coins) }
            item("conversion") { ConversionCard() }
            item("ledger-title") {
                Text(text = "آخر الحركات",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = TrendXColors.SecondaryInk))
            }
            when {
                isLoading && ledger == null -> item("loading") {
                    Box(modifier = Modifier.fillMaxWidth().padding(24.dp),
                        contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = TrendXColors.Primary,
                            strokeWidth = 2.dp)
                    }
                }
                ledger.isNullOrEmpty() -> item("empty") {
                    EmptyStateView(
                        icon = Icons.Filled.MonetizationOn,
                        title = "لا حركات بعد",
                        message = "كل تصويت وكل استبدال يظهر هنا تلقائياً مع رصيدك بعد العملية."
                    )
                }
                else -> items(ledger!!, key = { it.id }) { entry ->
                    LedgerRow(entry = entry)
                }
            }
        }
    }
}

@Composable
private fun PointsHero(points: Int, coins: Double) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = 18.dp, shape = RoundedCornerShape(24.dp), clip = false,
                ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
            .clip(RoundedCornerShape(24.dp))
            .background(TrendXGradients.Header)
            .padding(vertical = 24.dp, horizontal = 20.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.2f))
        ) {
            Icon(imageVector = Icons.Filled.Star, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(28.dp))
        }
        Text(text = points.toString(),
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 44.sp,
                color = Color.White))
        Text(text = "نقطة TRENDX",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                color = Color.White.copy(alpha = 0.85f)))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.18f))
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Icon(imageVector = Icons.Filled.MonetizationOn, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(6.dp))
            Text(text = "= %.2f ريال".format(coins),
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                    color = Color.White))
        }
    }
}

@Composable
private fun ConversionCard() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(TrendXColors.Success.copy(alpha = 0.10f))
        ) {
            Icon(imageVector = Icons.Filled.MonetizationOn, contentDescription = null,
                tint = TrendXColors.Success, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = "كل ٦ نقاط = ١ ريال",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.Ink))
            Text(text = "نسبة تحويل ثابتة، تحدّث رصيدك تلقائياً عند كل تصويت.",
                style = TrendXType.Small, color = TrendXColors.TertiaryInk)
        }
    }
}

@Composable
private fun LedgerRow(entry: LedgerEntry) {
    val tint = if (entry.isCredit) TrendXColors.Success else TrendXColors.Error
    val sign = if (entry.amount >= 0) "+" else ""
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))
        ) {
            Icon(
                imageVector = if (entry.isCredit) Icons.Filled.AddCircle
                              else Icons.Filled.RemoveCircle,
                contentDescription = null, tint = tint,
                modifier = Modifier.size(18.dp)
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = entry.description?.takeIf { it.isNotBlank() } ?: entry.typeDisplay,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                    color = TrendXColors.Ink),
                maxLines = 2)
            Text(text = entry.typeDisplay + (entry.createdAt?.let { " • " + relativeTime(it) } ?: ""),
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk))
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(text = "$sign${entry.amount}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                    color = tint))
            Text(text = "رصيد: ${entry.balanceAfter}",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.sp,
                    color = TrendXColors.TertiaryInk))
        }
    }
}

private fun relativeTime(then: kotlinx.datetime.Instant): String {
    val seconds = (Clock.System.now() - then).inWholeSeconds.coerceAtLeast(0)
    val minutes = seconds / 60
    if (minutes < 1) return "الآن"
    if (minutes < 60) return "قبل $minutes د"
    val hours = minutes / 60
    if (hours < 24) return "قبل $hours س"
    val days = hours / 24
    if (days < 30) return "قبل $days يوم"
    return "قبل ${days / 30} شهر"
}
