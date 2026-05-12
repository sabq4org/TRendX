package com.trendx.app.ui.components

import androidx.compose.foundation.Canvas
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.MemberTier
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors MemberTierProgressCard + MemberTierBadge from
// TRENDX/Components/MemberTier.swift. Surface card with the tier badge,
// "تبقى N نقطة لـ X" line, and a 4-dot rail showing every milestone with
// a filled progress segment between bronze and the user's current points.
@Composable
fun MemberTierProgressCard(points: Int, modifier: Modifier = Modifier) {
    val tier = MemberTier.from(points)
    val railProgress = run {
        val max = MemberTier.Diamond.threshold
        if (max <= 0) 1f else (points.toFloat() / max.toFloat()).coerceIn(0f, 1f)
    }

    Column(
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, tier.tint.copy(alpha = 0.18f), RoundedCornerShape(18.dp))
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MemberTierBadge(tier = tier)
            Spacer(Modifier.weight(1f))
            Text(
                text = "$points نقطة",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = tier.tint)
            )
        }
        tier.next?.let { next ->
            Text(
                text = "تبقى ${tier.pointsToNext(points)} نقطة للوصول إلى ${next.label}",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                    color = TrendXColors.SecondaryInk)
            )
        }
        TierRail(points = points, currentTier = tier, railProgress = railProgress)
    }
}

@Composable
fun MemberTierBadge(tier: MemberTier, compact: Boolean = false) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .shadow(elevation = 8.dp, shape = CircleShape, clip = false,
                ambientColor = tier.tint, spotColor = tier.tint)
            .clip(CircleShape)
            .background(tier.gradient)
            .padding(
                horizontal = if (compact) 8.dp else 10.dp,
                vertical = if (compact) 3.dp else 4.dp
            )
    ) {
        Icon(imageVector = tier.icon, contentDescription = null, tint = Color.White,
            modifier = Modifier.size(if (compact) 9.dp else 11.dp))
        Spacer(Modifier.width(5.dp))
        Text(text = tier.label,
            style = TextStyle(fontSize = if (compact) 10.sp else 11.sp,
                fontWeight = FontWeight.Black, color = Color.White))
    }
}

@Composable
private fun TierRail(points: Int, currentTier: MemberTier, railProgress: Float) {
    val tiers = MemberTier.entries
    // Force the rail to render LTR even inside our globally-RTL theme so
    // Bronze (lowest threshold) sits on the left and Diamond (highest)
    // on the right. The numeric labels read low→high left→right which is
    // how the iPhone version renders it; auto-flipping the rail to RTL
    // would put Diamond on the left and look "reversed" to anyone who
    // already knows the iOS layout.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            TierRailTrack(points = points, currentTier = currentTier, railProgress = railProgress)
            TierThresholdLabels(points = points, tiers = tiers)
        }
    }
}

@Composable
private fun TierRailTrack(points: Int, currentTier: MemberTier, railProgress: Float) {
    val tiers = MemberTier.entries
    val dotSize = 14.dp
    Box(
        modifier = Modifier.fillMaxWidth().height(dotSize),
        contentAlignment = Alignment.CenterStart
    ) {
        // Track
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(6.dp)
            .clip(CircleShape)
            .background(TrendXColors.SoftFill))
        // Filled portion up to railProgress
        if (railProgress > 0f) {
            Box(modifier = Modifier
                .fillMaxWidth(fraction = railProgress.coerceAtLeast(0.001f))
                .height(6.dp)
                .clip(CircleShape)
                .background(currentTier.gradient))
        }
        // Per-tier dots — positioned with a Layout so we can place each
        // dot at its absolute threshold along the rail.
        Layout(
            content = {
                tiers.forEach { t ->
                    val reached = points >= t.threshold
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(dotSize)
                            .clip(CircleShape)
                            .background(if (reached) t.tint else TrendXColors.Surface)
                            .border(1.5.dp, t.tint, CircleShape)
                    ) {
                        if (reached) {
                            Icon(imageVector = Icons.Filled.Check, contentDescription = null,
                                tint = Color.White, modifier = Modifier.size(7.dp))
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxWidth().height(dotSize)
        ) { measurables, constraints ->
            val maxThreshold = MemberTier.Diamond.threshold
            val placeables = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
            layout(constraints.maxWidth, dotSize.roundToPx()) {
                placeables.forEachIndexed { idx, p ->
                    val tier = tiers[idx]
                    val ratio = tier.threshold.toFloat() / maxThreshold.toFloat()
                    val x = (constraints.maxWidth * ratio - p.width / 2f).toInt()
                        .coerceAtLeast(0)
                        .coerceAtMost(constraints.maxWidth - p.width)
                    p.place(x = x, y = 0)
                }
            }
        }
    }
}

@Composable
private fun TierThresholdLabels(points: Int, tiers: List<MemberTier>) {
    Layout(
        content = {
            tiers.forEach { t ->
                val reached = points >= t.threshold
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(1.dp)
                ) {
                    Text(text = t.label,
                        style = TextStyle(fontSize = 9.sp, fontWeight = FontWeight.Black,
                            color = if (reached) t.tint else TrendXColors.TertiaryInk))
                    Text(text = t.threshold.toString(),
                        style = TextStyle(fontSize = 9.sp, fontWeight = FontWeight.Black,
                            color = TrendXColors.TertiaryInk))
                }
            }
        },
        modifier = Modifier.fillMaxWidth().height(24.dp)
    ) { measurables, constraints ->
        val maxThreshold = MemberTier.Diamond.threshold
        val placeables = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
        layout(constraints.maxWidth, 24.dp.roundToPx()) {
            placeables.forEachIndexed { idx, p ->
                val tier = tiers[idx]
                val ratio = tier.threshold.toFloat() / maxThreshold.toFloat()
                val x = (constraints.maxWidth * ratio - p.width / 2f).toInt()
                    .coerceAtLeast(0)
                    .coerceAtMost(constraints.maxWidth - p.width)
                p.place(x = x, y = 0)
            }
        }
    }
}
