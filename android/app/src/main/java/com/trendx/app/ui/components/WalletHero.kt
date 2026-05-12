package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.MemberTier
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors WalletHero from GiftsScreen.swift — wallet pill + tier badge +
// "جاهز للاستبدال" / "يبقى N نقطة" status, big points number, riyal
// equivalent, and a progress bar to the closest redemption.
@Composable
fun WalletHero(
    points: Int,
    coins: Double,
    minimumForRedeem: Int,
    modifier: Modifier = Modifier
) {
    val progress = if (minimumForRedeem <= 0) 0f
        else (points.toFloat() / minimumForRedeem.toFloat()).coerceIn(0f, 1f)
    val remaining = (minimumForRedeem - points).coerceAtLeast(0)
    val isReady = remaining == 0
    val tier = MemberTier.from(points)

    Column(
        verticalArrangement = Arrangement.spacedBy(18.dp),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 8.dp, shape = RoundedCornerShape(20.dp), clip = false)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
            .padding(20.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            WalletPill()
            Spacer(Modifier.width(8.dp))
            MemberTierBadge(tier = tier, compact = true)
            Spacer(Modifier.weight(1f))
            ReadyChip(isReady = isReady, remaining = remaining)
        }
        Row(verticalAlignment = Alignment.Bottom) {
            Text(text = points.toString(),
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 38.sp,
                    color = TrendXColors.Ink))
            Spacer(Modifier.width(8.dp))
            Text(text = "نقطة",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                    color = TrendXColors.SecondaryInk))
        }
        Text(text = "يعادل %.2f ريال".format(coins),
            style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                color = TrendXColors.TertiaryInk))
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "التقدّم نحو أقرب استبدال",
                    style = TextStyle(fontSize = 12.5.sp, fontWeight = FontWeight.Medium,
                        color = TrendXColors.SecondaryInk))
                Spacer(Modifier.weight(1f))
                Text(text = "${(progress * 100).toInt()}%",
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                        color = TrendXColors.AccentDeep))
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.SoftFill)
            ) {
                if (progress > 0f) {
                    Box(modifier = Modifier
                        .fillMaxWidth(fraction = progress.coerceAtLeast(0.001f))
                        .height(8.dp)
                        .clip(CircleShape)
                        .background(TrendXColors.Accent))
                }
            }
        }
    }
}

@Composable
private fun WalletPill() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(TrendXColors.SoftFill)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Icon(imageVector = Icons.Filled.CreditCard, contentDescription = null,
            tint = TrendXColors.SecondaryInk, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = "محفظة TRENDX",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp,
                color = TrendXColors.SecondaryInk))
    }
}

@Composable
private fun ReadyChip(isReady: Boolean, remaining: Int) {
    val bg = if (isReady) TrendXColors.Success.copy(alpha = 0.10f) else TrendXColors.PaleFill
    val fg = if (isReady) TrendXColors.Success else TrendXColors.SecondaryInk
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(
            text = if (isReady) "جاهز للاستبدال" else "يبقى $remaining نقطة",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp, color = fg)
        )
    }
}
