package com.trendx.app.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.Wallet
import androidx.compose.material.icons.filled.RemoveCircle
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Redemption
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.TrendXConfetti
import kotlinx.coroutines.delay

// Faithful Compose port of TRENDX/Screens/GiftRedemptionSuccessSheet.swift.
// Brand-quality post-redemption celebration: confetti, success seal,
// copy-friendly code capsule, balance tiles, share + done buttons.
@Composable
fun GiftRedemptionSuccessSheet(
    redemption: Redemption,
    remainingPoints: Int,
    onDismiss: () -> Unit,
    onShare: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        // Brand wash background
        Box(modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(
                TrendXColors.Background,
                TrendXColors.Accent.copy(alpha = 0.08f),
                TrendXColors.Primary.copy(alpha = 0.10f)
            ))))
        // Confetti rain
        TrendXConfetti()

        LazyColumn(
            modifier = Modifier.fillMaxSize().statusBarsPadding(),
            contentPadding = PaddingValues(start = 22.dp, end = 22.dp,
                top = 14.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            item("seal") { SuccessSeal() }
            item("headline") {
                HeadlineBlock(brandName = redemption.brandName, giftName = redemption.giftName)
            }
            item("code") { CodeCapsule(redemption = redemption) }
            item("balance") {
                BalanceBlock(spent = redemption.pointsSpent, remaining = remainingPoints)
            }
            item("actions") {
                ActionButtons(onShare = onShare, onDismiss = onDismiss)
            }
        }
    }
}

@Composable
private fun SuccessSeal() {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.size(132.dp)
    ) {
        Box(modifier = Modifier
            .size(132.dp)
            .clip(CircleShape)
            .background(TrendXColors.Success.copy(alpha = 0.12f)))
        Box(modifier = Modifier
            .size(110.dp)
            .clip(CircleShape)
            .border(2.dp, TrendXColors.Success.copy(alpha = 0.30f), CircleShape))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 22.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Success, spotColor = TrendXColors.Success)
                .size(88.dp)
                .clip(CircleShape)
                .background(TrendXColors.Success)
        ) {
            Icon(imageVector = Icons.Filled.Check, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(38.dp))
        }
    }
}

@Composable
private fun HeadlineBlock(brandName: String, giftName: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(text = "استبدلت بنجاح ✨",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 24.sp,
                color = TrendXColors.Ink))
        Text(text = "$brandName — $giftName",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                color = TrendXColors.SecondaryInk),
            textAlign = TextAlign.Center)
    }
}

@Composable
private fun CodeCapsule(redemption: Redemption) {
    val ctx = LocalContext.current
    var didCopy by remember { mutableStateOf(false) }
    LaunchedEffect(didCopy) {
        if (didCopy) {
            delay(1600)
            didCopy = false
        }
    }

    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(22.dp), clip = false)
            .clip(RoundedCornerShape(22.dp))
            .background(TrendXColors.Surface)
            .padding(18.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(imageVector = Icons.Filled.QrCode2, contentDescription = null,
                tint = TrendXColors.TertiaryInk, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(6.dp))
            Text(text = "كود الهدية",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk))
            Spacer(Modifier.weight(1f))
            Box(modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Accent.copy(alpha = 0.12f))
                .padding(horizontal = 8.dp, vertical = 3.dp)) {
                Text(text = "بقيمة ${redemption.valueInRiyal.toInt()} ر.س",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.AccentDeep))
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            // Code display
            Box(
                contentAlignment = Alignment.CenterStart,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(14.dp))
                    .background(TrendXColors.Primary.copy(alpha = 0.08f))
                    .border(1.dp, TrendXColors.Primary.copy(alpha = 0.35f),
                        RoundedCornerShape(14.dp))
                    .padding(horizontal = 16.dp, vertical = 14.dp)
            ) {
                Text(text = redemption.code,
                    style = TextStyle(fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.Black, fontSize = 24.sp,
                        color = TrendXColors.PrimaryDeep, letterSpacing = 2.sp))
            }
            // Copy button
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .shadow(elevation = 10.dp, shape = RoundedCornerShape(14.dp), clip = false,
                        ambientColor = if (didCopy) TrendXColors.Success else TrendXColors.Primary,
                        spotColor = if (didCopy) TrendXColors.Success else TrendXColors.Primary)
                    .size(54.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (didCopy) TrendXColors.Success else TrendXColors.Primary)
                    .clickable {
                        copyToClipboard(ctx, redemption.code)
                        didCopy = true
                    }
            ) {
                Icon(imageVector = if (didCopy) Icons.Filled.Check
                                   else Icons.Filled.ContentCopy,
                    contentDescription = "نسخ", tint = Color.White,
                    modifier = Modifier.size(16.dp))
            }
        }
        if (didCopy) {
            Text(text = "نُسخ إلى الحافظة",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    color = TrendXColors.Success))
        }
    }
}

private fun copyToClipboard(ctx: Context, text: String) {
    val clipboard = ctx.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
    clipboard?.setPrimaryClip(ClipData.newPlainText("TRENDX redemption code", text))
}

@Composable
private fun BalanceBlock(spent: Int, remaining: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()) {
        BalanceTile(icon = Icons.Filled.RemoveCircle, value = "-$spent",
            label = "تم خصمها", tint = TrendXColors.AiViolet, modifier = Modifier.weight(1f))
        BalanceTile(icon = Icons.Filled.Wallet, value = remaining.toString(),
            label = "المتبقي", tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun BalanceTile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(tint.copy(alpha = 0.08f))
            .padding(vertical = 14.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(13.dp))
        Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
            color = TrendXColors.Ink))
        Text(text = label, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp,
            color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun ActionButtons(onShare: () -> Unit, onDismiss: () -> Unit) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(TrendXColors.Primary.copy(alpha = 0.10f))
                .clickable(onClick = onShare)
                .padding(vertical = 13.dp)
        ) {
            Icon(imageVector = Icons.Filled.IosShare, contentDescription = null,
                tint = TrendXColors.PrimaryDeep, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(8.dp))
            Text(text = "شارك مع صديق",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                    color = TrendXColors.PrimaryDeep))
        }
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 14.dp, shape = RoundedCornerShape(16.dp), clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .clip(RoundedCornerShape(16.dp))
                .background(TrendXGradients.Primary)
                .clickable(onClick = onDismiss)
                .padding(vertical = 15.dp)
        ) {
            Text(text = "تم",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = Color.White))
        }
    }
}
