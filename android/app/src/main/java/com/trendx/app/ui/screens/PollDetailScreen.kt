package com.trendx.app.ui.screens

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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Poll
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType
import com.trendx.app.theme.surfaceCard
import com.trendx.app.ui.components.AIInsightChip
import com.trendx.app.ui.components.EmptyStateView
import com.trendx.app.ui.components.PollCard
import com.trendx.app.ui.components.SectionHeader
import com.trendx.app.ui.components.StatusBadge
import com.trendx.app.ui.components.StatusBadgeKind

// Faithful port of TRENDX/Screens/PollDetailView.swift. Three sections:
//   1. PollDetailHero — status badge + reward chip + headline + sub-copy
//   2. Full PollCard — same card from the feed, with vote / share / bookmark / repost wired
//   3. PollDetailInsights — metric tiles + AI chip + leader sentence
@Composable
fun PollDetailScreen(
    poll: Poll,
    onClose: () -> Unit,
    onVote: (optionId: String, isPublic: Boolean) -> Unit,
    onShare: () -> Unit,
    onBookmark: () -> Unit,
    onRepost: (Boolean) -> Unit,
    onShowAnalytics: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            DetailToolbar(
                title = "تفاصيل الاستطلاع",
                onClose = onClose,
                onShowAnalytics = onShowAnalytics
            )

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = 20.dp, end = 20.dp, top = 18.dp, bottom = 36.dp
                ),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                item("hero") { PollDetailHero(poll = poll) }
                item("card") {
                    PollCard(
                        poll = poll,
                        onVote = onVote,
                        onShare = onShare,
                        onBookmark = onBookmark,
                        onRepost = onRepost
                    )
                }
                item("insights") { PollDetailInsights(poll = poll) }
            }
        }
    }
}

@Composable
fun PollDetailNotFound(onClose: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
        TrendXAmbientBackground()
        Column(modifier = Modifier.fillMaxSize()) {
            DetailToolbar(title = "تفاصيل الاستطلاع", onClose = onClose,
                onShowAnalytics = null)
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.fillMaxSize().padding(20.dp)
            ) {
                EmptyStateView(
                    icon = Icons.Filled.Visibility,
                    title = "الاستطلاع غير متاح",
                    message = "قد يكون تم حذفه أو لم يعد ضمن بيانات هذا الجهاز."
                )
            }
        }
    }
}

@Composable
private fun DetailToolbar(
    title: String,
    onClose: () -> Unit,
    onShowAnalytics: (() -> Unit)?
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 12.dp)
    ) {
        // Close lives on the visually-leading edge in RTL — Alignment.Start
        // here, which Compose flips to the screen's left under our RTL
        // theme. Matches CLAUDE.md sheet-close convention.
        ToolbarIconButton(
            icon = Icons.Filled.Close,
            label = "إغلاق",
            onClick = onClose
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = title,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 17.sp,
                color = TrendXColors.Ink),
            modifier = Modifier.weight(1f)
        )
        if (onShowAnalytics != null) {
            ToolbarPill(label = "الإحصائيات", icon = Icons.Filled.BarChart, onClick = onShowAnalytics)
        }
    }
}

@Composable
private fun ToolbarIconButton(icon: ImageVector, label: String, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, CircleShape)
            .clickable(onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = label, tint = TrendXColors.Ink,
            modifier = Modifier.size(15.dp))
    }
}

@Composable
private fun ToolbarPill(label: String, icon: ImageVector, onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(TrendXColors.Primary.copy(alpha = 0.10f))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = TrendXColors.Primary,
            modifier = Modifier.size(12.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = label, style = TextStyle(
            fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TrendXColors.Primary))
    }
}

@Composable
private fun PollDetailHero(poll: Poll) {
    val statusKind = when {
        poll.isExpired -> StatusBadgeKind.Ended
        poll.hasUserVoted -> StatusBadgeKind.Voted
        poll.isEndingSoon -> StatusBadgeKind.Warning
        else -> StatusBadgeKind.Active
    }
    Column(
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth().surfaceCard(padding = 18.dp, radius = 24.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            StatusBadge(kind = statusKind)
            Spacer(modifier = Modifier.weight(1f))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(TrendXColors.Accent.copy(alpha = 0.12f))
                    .padding(horizontal = 10.dp, vertical = 6.dp)
            ) {
                Icon(imageVector = Icons.Filled.Star, contentDescription = null,
                    tint = TrendXColors.Accent, modifier = Modifier.size(12.dp))
                Spacer(Modifier.width(4.dp))
                Text(text = "+${poll.rewardPoints}",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                        color = TrendXColors.AccentDeep))
            }
        }
        Text(text = "قراءة أعمق للصوت الجماعي", style = TrendXType.Headline,
            color = TrendXColors.Ink)
        Text(
            text = "افتح النتائج، راقب الفروقات، واجعل صوتك جزءاً من تحليل TRENDX AI المحلي.",
            style = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Medium,
                color = TrendXColors.SecondaryInk, lineHeight = 20.sp)
        )
    }
}

@Composable
private fun PollDetailInsights(poll: Poll) {
    val leader = poll.options.maxByOrNull { it.percentage }
    Column(
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth().surfaceCard(padding = 16.dp, radius = 24.dp)
    ) {
        // SectionHeader is intentionally borderless inside the card —
        // mirrors the iOS treatment of the analytics tile header.
        Box(modifier = Modifier.padding(start = 0.dp)) {
            SectionHeader(title = "لوحة التحليل",
                subtitle = "مبنية على نتائج هذا الجهاز",
                showMore = false)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DetailMetricTile(
                icon = Icons.Filled.PeopleAlt,
                value = poll.totalVotes.toString(),
                label = "تصويت",
                tint = TrendXColors.Primary,
                modifier = Modifier.weight(1f)
            )
            DetailMetricTile(
                icon = Icons.Filled.AccessTime,
                value = poll.deadlineLabel,
                label = "الوقت",
                tint = if (poll.isEndingSoon) TrendXColors.Warning else TrendXColors.Success,
                modifier = Modifier.weight(1f)
            )
        }
        if (poll.viewsCount + poll.sharesCount + poll.savesCount > 0) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DetailMetricTile(icon = Icons.Filled.Visibility,
                    value = compact(poll.viewsCount), label = "مشاهدة",
                    tint = TrendXColors.AiIndigo, modifier = Modifier.weight(1f))
                DetailMetricTile(icon = Icons.Filled.IosShare,
                    value = compact(poll.sharesCount), label = "مشاركة",
                    tint = TrendXColors.AiViolet, modifier = Modifier.weight(1f))
                DetailMetricTile(icon = Icons.Filled.Bookmark,
                    value = compact(poll.savesCount), label = "حفظ",
                    tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
            }
        }
        leader?.let {
            AIInsightChip(
                text = poll.aiInsight ?: TrendXAI.encouragement(),
                label = "تحليل TRENDX AI"
            )
            Text(
                text = "الخيار المتصدر: ${it.text} بنسبة ${it.percentage.toInt()}%.",
                style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                    color = TrendXColors.SecondaryInk),
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }
    }
}

@Composable
private fun DetailMetricTile(
    icon: ImageVector,
    value: String,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = modifier
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.PaleFill)
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(14.dp))
        }
        Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
            color = TrendXColors.Ink), maxLines = 1)
        Text(text = label, style = TrendXType.Small, color = TrendXColors.TertiaryInk)
    }
}

private fun compact(value: Int): String = when {
    value < 1_000 -> value.toString()
    value < 1_000_000 -> {
        val v = value / 1_000.0
        if (v < 10) "%.1fK".format(v) else "%.0fK".format(v)
    }
    else -> "%.1fM".format(value / 1_000_000.0)
}
