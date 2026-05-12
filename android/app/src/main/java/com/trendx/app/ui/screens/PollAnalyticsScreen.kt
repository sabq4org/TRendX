package com.trendx.app.ui.screens

import androidx.compose.foundation.Canvas
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.CallReceived
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Domain
import androidx.compose.material.icons.filled.Female
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material.icons.filled.Male
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.WifiTethering
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Poll
import com.trendx.app.models.PollAnalytics
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.theme.surfaceCard

// Faithful Compose port of TRENDX/Screens/PollAnalyticsView.swift.
// Eight stacked cards: hero, performance, demographics, behavior, reach,
// AI analysis, community, timeline. Numbers come from PollAnalytics.mock
// — deterministic per poll.id, same as iOS.
@Composable
fun PollAnalyticsScreen(
    poll: Poll,
    onClose: () -> Unit,
    onShare: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val analytics = remember(poll.id, poll.totalVotes) { PollAnalytics.mock(poll) }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            AnalyticsToolbar(onClose = onClose, onShare = onShare)
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = 20.dp, end = 20.dp, top = 8.dp, bottom = 36.dp
                ),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                item("hero") { AnalyticsHero(poll = poll, totalVotes = analytics.totalVotes) }
                item("performance") { PerformanceSection(analytics = analytics) }
                item("demographics") { DemographicsSection(analytics = analytics) }
                item("behavior") { BehaviorSection(poll = poll, analytics = analytics) }
                item("reach") { ReachSection(analytics = analytics) }
                item("ai") { AIAnalysisSection(poll = poll, analytics = analytics) }
                item("community") { CommunitySection(analytics = analytics) }
                item("timeline") { TimelineSection(analytics = analytics) }
                item("note") { SampleQualityNote() }
            }
        }
    }
}

@Composable
private fun AnalyticsToolbar(onClose: () -> Unit, onShare: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 12.dp)
    ) {
        ToolbarChip(icon = Icons.Filled.Close, label = "إغلاق", onClick = onClose)
        Spacer(Modifier.width(8.dp))
        Text(
            text = "لوحة التحليل",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 17.sp,
                color = TrendXColors.Ink),
            modifier = Modifier.weight(1f)
        )
        ToolbarChip(icon = Icons.Filled.IosShare, label = "مشاركة", onClick = onShare)
    }
}

@Composable
private fun ToolbarChip(icon: ImageVector, label: String, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, CircleShape)
            .clickable(onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = label, tint = TrendXColors.Primary,
            modifier = Modifier.size(15.dp))
    }
}

@Composable
private fun AnalyticsHero(poll: Poll, totalVotes: Int) {
    Row(
        modifier = Modifier.fillMaxWidth().surfaceCard(padding = 18.dp, radius = 24.dp)
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(text = "قراءة معمّقة",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                    color = TrendXColors.Accent, letterSpacing = 0.6.sp))
            Text(
                text = poll.title,
                style = TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.SemiBold,
                    fontSize = 19.sp, color = TrendXColors.Ink, lineHeight = 25.sp),
                maxLines = 2
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = Icons.Filled.AccessTime, contentDescription = null,
                    tint = if (poll.isEndingSoon) TrendXColors.Warning else TrendXColors.TertiaryInk,
                    modifier = Modifier.size(11.dp))
                Spacer(Modifier.width(4.dp))
                Text(text = poll.deadlineLabel, style = TrendXType.Small,
                    color = if (poll.isEndingSoon) TrendXColors.Warning else TrendXColors.TertiaryInk)
            }
        }
        Column(horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = totalVotes.toString(),
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 28.sp,
                    color = TrendXColors.Primary))
            Text(text = "صوت", style = TrendXType.Small, color = TrendXColors.TertiaryInk)
        }
    }
}

// MARK: - Performance

@Composable
private fun PerformanceSection(analytics: PollAnalytics) {
    AnalyticsSection(title = "الأداء العام", icon = Icons.Filled.Speed) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                PerfTile(
                    icon = Icons.Filled.CallReceived,
                    value = "${analytics.conversionRate.toInt()}%",
                    label = "معدل التحويل",
                    sublabel = "من الظهور للتصويت",
                    tint = TrendXColors.Primary,
                    modifier = Modifier.weight(1f)
                )
                PerfTile(
                    icon = Icons.Filled.CheckCircle,
                    value = "${analytics.confidenceLevel.toInt()}%",
                    label = "مستوى الثقة",
                    sublabel = "±%.1f%%".format(analytics.marginOfError),
                    tint = TrendXColors.Success,
                    modifier = Modifier.weight(1f)
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                PerfTile(
                    icon = Icons.Filled.Visibility,
                    value = analytics.totalImpressions.toString(),
                    label = "مرات الظهور",
                    sublabel = "الوصول الكلي",
                    tint = TrendXColors.Info,
                    modifier = Modifier.weight(1f)
                )
                PerfTile(
                    icon = Icons.Filled.TrendingUp,
                    value = if (analytics.sectorBenchmarkDelta > 0)
                        "+${analytics.sectorBenchmarkDelta.toInt()}%"
                    else "${analytics.sectorBenchmarkDelta.toInt()}%",
                    label = "مقارنة بالقطاع",
                    sublabel = if (analytics.sectorBenchmarkDelta > 0) "أعلى من المتوسط"
                               else "أدنى من المتوسط",
                    tint = if (analytics.sectorBenchmarkDelta > 0) TrendXColors.Success
                           else TrendXColors.Error,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

// MARK: - Demographics

@Composable
private fun DemographicsSection(analytics: PollAnalytics) {
    AnalyticsSection(title = "ديموغرافيا المصوّتين", icon = Icons.Filled.Groups) {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Gender
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = "الجنس", style = TrendXType.Caption,
                    color = TrendXColors.TertiaryInk)
                GenderBar(malePercent = analytics.malePercent,
                    femalePercent = analytics.femalePercent)
                Row(modifier = Modifier.fillMaxWidth()) {
                    GenderLegend(icon = Icons.Filled.Male,
                        label = "${analytics.malePercent.toInt()}% ذكور",
                        tint = TrendXColors.Primary)
                    Spacer(Modifier.weight(1f))
                    GenderLegend(icon = Icons.Filled.Female,
                        label = "${analytics.femalePercent.toInt()}% إناث",
                        tint = TrendXColors.AiViolet)
                }
            }
            HairlineDivider()
            // Age groups
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(text = "الفئات العمرية", style = TrendXType.Caption,
                    color = TrendXColors.TertiaryInk)
                val maxAgePercent = analytics.ageGroups.maxOf { it.percent }
                analytics.ageGroups.forEach { group ->
                    AgeGroupRow(label = group.label, percent = group.percent,
                        isLeader = group.percent == maxAgePercent)
                }
            }
            HairlineDivider()
            // Geographic
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(text = "التوزيع الجغرافي", style = TrendXType.Caption,
                    color = TrendXColors.TertiaryInk)
                val maxCount = analytics.geoBreakdown.maxOf { it.count }.coerceAtLeast(1)
                analytics.geoBreakdown.forEach { geo ->
                    GeoRow(country = geo.country, flag = geo.flag,
                        count = geo.count, maxCount = maxCount)
                }
            }
        }
    }
}

@Composable
private fun GenderBar(malePercent: Double, femalePercent: Double) {
    // Compose's `fillMaxWidth(fraction = …)` throws when fraction <= 0,
    // and `weight(...)` does the same — so we always lift each side to a
    // tiny minimum even when the percentage is genuinely zero.
    val maleFraction = (malePercent / 100.0).toFloat().coerceAtLeast(0.001f)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp)
            .clip(RoundedCornerShape(8.dp))
    ) {
        if (malePercent > 0) {
            Box(modifier = Modifier
                .fillMaxWidth(fraction = maleFraction)
                .height(28.dp)
                .background(TrendXColors.Primary))
        }
        if (femalePercent > 0) {
            Box(modifier = Modifier
                .weight(1f)
                .height(28.dp)
                .background(TrendXColors.AiViolet))
        }
    }
}

@Composable
private fun GenderLegend(icon: ImageVector, label: String, tint: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(4.dp))
        Text(text = label, style = TrendXType.Small, color = tint)
    }
}

@Composable
private fun AgeGroupRow(label: String, percent: Double, isLeader: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(text = label, style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
            color = TrendXColors.SecondaryInk), modifier = Modifier.width(48.dp))
        Box(
            modifier = Modifier
                .weight(1f)
                .height(18.dp)
                .clip(CircleShape)
                .background(TrendXColors.SoftFill)
        ) {
            if (percent > 0) {
                Box(modifier = Modifier
                    .fillMaxWidth(fraction = (percent / 100.0).toFloat().coerceAtLeast(0.001f))
                    .height(18.dp)
                    .clip(CircleShape)
                    .background(
                        if (isLeader) TrendXGradients.Primary
                        else Brush.horizontalGradient(listOf(
                            TrendXColors.PrimaryLight.copy(alpha = 0.6f),
                            TrendXColors.PrimaryLight.copy(alpha = 0.6f)
                        ))
                    ))
            }
        }
        Text(text = "${percent.toInt()}%", style = TextStyle(fontSize = 12.sp,
            fontWeight = FontWeight.Bold, color = TrendXColors.Primary),
            modifier = Modifier.width(36.dp))
    }
}

@Composable
private fun GeoRow(country: String, flag: String, count: Int, maxCount: Int) {
    val fraction = if (maxCount > 0) (count.toFloat() / maxCount.toFloat()) else 0f
    Row(verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(text = flag, style = TextStyle(fontSize = 16.sp))
        Text(text = country, style = TextStyle(fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold, color = TrendXColors.SecondaryInk),
            modifier = Modifier.width(60.dp))
        Box(
            modifier = Modifier
                .weight(1f)
                .height(16.dp)
                .clip(CircleShape)
                .background(TrendXColors.SoftFill)
        ) {
            // Skip the inner bar entirely when there are no votes for
            // this country — Compose's `fillMaxWidth(fraction = 0f)`
            // throws "fraction must be greater than zero" and crashes
            // the screen on small polls (e.g. "أخرى" → 0 votes when the
            // base sample is < 20).
            if (fraction > 0f) {
                Box(modifier = Modifier
                    .fillMaxWidth(fraction = fraction.coerceAtLeast(0.001f))
                    .height(16.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.Accent.copy(alpha = 0.85f)))
            }
        }
        Text(text = count.toString(), style = TextStyle(fontSize = 12.sp,
            fontWeight = FontWeight.Bold, color = TrendXColors.SecondaryInk),
            modifier = Modifier.width(30.dp))
    }
}

// MARK: - Behavior

@Composable
private fun BehaviorSection(poll: Poll, analytics: PollAnalytics) {
    AnalyticsSection(title = "سلوك التصويت", icon = Icons.Filled.Psychology) {
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            // Peak hours
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = "ساعات الذروة", style = TrendXType.Caption,
                    color = TrendXColors.TertiaryInk)
                Row(verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.fillMaxWidth().height(68.dp)) {
                    analytics.peakHours.forEach { slot ->
                        Column(horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.weight(1f)) {
                            Box(modifier = Modifier
                                .fillMaxWidth()
                                .height((52f * slot.weight.toFloat()).coerceAtLeast(6f).dp)
                                .clip(RoundedCornerShape(4.dp))
                                .background(if (slot.weight >= 0.99) TrendXGradients.Primary
                                    else Brush.verticalGradient(listOf(
                                        TrendXColors.PrimaryLight.copy(alpha = (slot.weight * 0.8).toFloat()),
                                        TrendXColors.PrimaryLight.copy(alpha = (slot.weight * 0.8).toFloat())
                                    ))))
                            Spacer(Modifier.height(4.dp))
                            Text(text = slot.hour, style = TextStyle(fontSize = 9.sp,
                                fontWeight = FontWeight.Medium, color = TrendXColors.MutedInk))
                        }
                    }
                }
                Text(text = "ذروة التصويت بين 8–10 مساءً", style = TrendXType.Small,
                    color = TrendXColors.TertiaryInk)
            }
            HairlineDivider()
            // Behavior stats
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                BehaviorStat(icon = Icons.Filled.Timer,
                    value = "${analytics.avgDecisionSeconds}ث",
                    label = "متوسط وقت القرار",
                    note = if (analytics.avgDecisionSeconds < 12) "قناعة راسخة"
                           else "تأمل قبل التصويت",
                    noteColor = if (analytics.avgDecisionSeconds < 12) TrendXColors.Success
                                else TrendXColors.Warning,
                    modifier = Modifier.weight(1f))
                BehaviorStat(icon = Icons.Filled.WifiTethering,
                    value = "${analytics.mobilePercent.toInt()}%",
                    label = "تصويت من الجوال",
                    note = "جمهور موبايل-فيرست",
                    noteColor = TrendXColors.Info,
                    modifier = Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                BehaviorStat(icon = Icons.Filled.Visibility,
                    value = "${analytics.readBeforeVotePercent.toInt()}%",
                    label = "قرأ التفاصيل أولاً",
                    note = "تصويت مدروس",
                    noteColor = TrendXColors.Success,
                    modifier = Modifier.weight(1f))
                BehaviorStat(icon = Icons.Filled.Repeat,
                    value = "${analytics.changeVotePercent.toInt()}%",
                    label = "غيّر اختياره",
                    note = "قرارات بحذر",
                    noteColor = TrendXColors.MutedInk,
                    modifier = Modifier.weight(1f))
            }
            // Polarization
            val sorted = poll.options.sortedByDescending { it.percentage }
            val leader = sorted.firstOrNull()
            val second = sorted.getOrNull(1)
            if (leader != null && second != null) {
                val gap = leader.percentage - second.percentage
                HairlineDivider()
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(text = "درجة الانقسام", style = TrendXType.Caption,
                            color = TrendXColors.TertiaryInk)
                        Spacer(Modifier.weight(1f))
                        val (label, color) = when {
                            gap > 25 -> "توافق جماعي" to TrendXColors.Success
                            gap > 10 -> "ميل واضح" to TrendXColors.Warning
                            else -> "انقسام حاد" to TrendXColors.Error
                        }
                        Box(modifier = Modifier
                            .clip(CircleShape)
                            .background(color.copy(alpha = 0.12f))
                            .padding(horizontal = 8.dp, vertical = 3.dp)) {
                            Text(text = label, style = TrendXType.Small, color = color)
                        }
                    }
                    Text(text = "«${leader.text}» يتقدم بـ ${gap.toInt()} نقطة على «${second.text}»",
                        style = TrendXType.Small, color = TrendXColors.SecondaryInk)
                }
            }
        }
    }
}

// MARK: - Reach

@Composable
private fun ReachSection(analytics: PollAnalytics) {
    AnalyticsSection(title = "الانتشار والتأثير", icon = Icons.Filled.WifiTethering) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ReachTile(Icons.Filled.IosShare, analytics.sharesCount, "مشاركة",
                    TrendXColors.Info, Modifier.weight(1f))
                ReachTile(Icons.Filled.Bookmark, analytics.savesCount, "حفظ",
                    TrendXColors.Accent, Modifier.weight(1f))
                ReachTile(Icons.Filled.Repeat, analytics.repostsCount, "إعادة نشر",
                    TrendXColors.AiViolet, Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ReachTile(Icons.Filled.Verified, analytics.profileVisits, "زيارة الملف",
                    TrendXColors.Success, Modifier.weight(1f))
                ReachTile(Icons.Filled.PersonAdd, analytics.newFollowers, "متابع جديد",
                    TrendXColors.Primary, Modifier.weight(1f))
                ReachTile(Icons.Filled.BarChart, analytics.returnRatePercent.toInt(),
                    "% معدل العودة", TrendXColors.AccentDeep, Modifier.weight(1f))
            }
        }
    }
}

// MARK: - AI Analysis

@Composable
private fun AIAnalysisSection(poll: Poll, analytics: PollAnalytics) {
    AnalyticsSection(title = "تحليل TRENDX AI", icon = Icons.Filled.AutoAwesome) {
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            // Main AI insight
            Row(verticalAlignment = Alignment.Top,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(TrendXColors.AiIndigo.copy(alpha = 0.06f))
                    .border(1.dp, TrendXColors.AiIndigo.copy(alpha = 0.18f),
                        RoundedCornerShape(16.dp))
                    .padding(14.dp)) {
                Box(contentAlignment = Alignment.Center,
                    modifier = Modifier.size(36.dp).clip(CircleShape)
                        .background(TrendXColors.AiIndigo.copy(alpha = 0.12f))) {
                    Icon(imageVector = Icons.Filled.Psychology, contentDescription = null,
                        tint = TrendXColors.AiIndigo, modifier = Modifier.size(15.dp))
                }
                Spacer(Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(text = "قراءة ذكية", style = TextStyle(fontWeight = FontWeight.Black,
                        fontSize = 11.sp, color = TrendXColors.AiIndigo))
                    Text(text = poll.aiInsight ?: TrendXAI.encouragement(),
                        style = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Medium,
                            color = TrendXColors.Ink, lineHeight = 20.sp))
                }
            }
            // Sector benchmark
            InsightCard(
                icon = Icons.Filled.BarChart,
                iconTint = if (analytics.sectorBenchmarkDelta > 0) TrendXColors.Success
                else TrendXColors.Error,
                eyebrow = "البنشمارك القطاعي",
                title = "استطلاعك أعلى من ${if (analytics.sectorBenchmarkDelta > 0) "87%" else "52%"} من الاستطلاعات المشابهة هذا الشهر",
                trailing = {
                    Text(
                        text = if (analytics.sectorBenchmarkDelta > 0)
                            "+${analytics.sectorBenchmarkDelta.toInt()}%"
                        else "${analytics.sectorBenchmarkDelta.toInt()}%",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                            color = if (analytics.sectorBenchmarkDelta > 0) TrendXColors.Success
                                    else TrendXColors.Error)
                    )
                }
            )
            // Sample quality
            InsightCard(
                icon = Icons.Filled.GpsFixed,
                iconTint = TrendXColors.Primary,
                eyebrow = "جودة العيّنة",
                title = "استطلاعك وصل لـ ${analytics.totalVotes} مصوّت بمستوى ثقة ${analytics.confidenceLevel.toInt()}% وهامش خطأ ±%.1f%%".format(analytics.marginOfError),
                trailing = null
            )
        }
    }
}

@Composable
private fun InsightCard(
    icon: ImageVector,
    iconTint: Color,
    eyebrow: String,
    title: String,
    trailing: (@Composable () -> Unit)?
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.PaleFill)
            .padding(14.dp)
    ) {
        Box(contentAlignment = Alignment.Center,
            modifier = Modifier.size(32.dp).clip(CircleShape)
                .background(iconTint.copy(alpha = 0.10f))) {
            Icon(imageVector = icon, contentDescription = null, tint = iconTint,
                modifier = Modifier.size(14.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = eyebrow, style = TrendXType.Small, color = TrendXColors.TertiaryInk)
            Text(text = title, style = TextStyle(fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold, color = TrendXColors.SecondaryInk))
        }
        trailing?.let {
            Spacer(Modifier.width(10.dp))
            it()
        }
    }
}

// MARK: - Community

@Composable
private fun CommunitySection(analytics: PollAnalytics) {
    AnalyticsSection(title = "أثر المجتمع", icon = Icons.Filled.Groups) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                CommunityTile(icon = Icons.Filled.Star,
                    value = analytics.communityPointsEarned.toString(),
                    label = "نقطة أكسبها المجتمع", tint = TrendXColors.Accent,
                    modifier = Modifier.weight(1f))
                CommunityTile(icon = Icons.Filled.Verified,
                    value = analytics.activeContributors.toString(),
                    label = "مساهم نشط (5+ استطلاعات)", tint = TrendXColors.Primary,
                    modifier = Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                CommunityTile(icon = Icons.Filled.Repeat,
                    value = "${analytics.returnRatePercent.toInt()}%",
                    label = "معدل العودة للمنصة", tint = TrendXColors.Success,
                    modifier = Modifier.weight(1f))
                CommunityTile(icon = Icons.Filled.Domain,
                    value = "${analytics.conversionRate.toInt()}%",
                    label = "تحويل للمتابعة المؤسسية", tint = TrendXColors.AiViolet,
                    modifier = Modifier.weight(1f))
            }
        }
    }
}

// MARK: - Timeline

@Composable
private fun TimelineSection(analytics: PollAnalytics) {
    AnalyticsSection(title = "منحنى الزمن", icon = Icons.Filled.Timeline) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(text = "تراكم الأصوات يوماً بيوم", style = TrendXType.Caption,
                color = TrendXColors.TertiaryInk)
            TimelineChart(points = analytics.timelineVotes)
            // Day labels
            Row(modifier = Modifier.fillMaxWidth()) {
                analytics.timelineVotes.forEach { item ->
                    Text(text = "ي${item.day}", style = TextStyle(fontSize = 10.sp,
                        fontWeight = FontWeight.Medium, color = TrendXColors.MutedInk),
                        textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
                }
            }
            val peak = analytics.timelineVotes.maxByOrNull { it.count }
            peak?.let {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Filled.Bolt, contentDescription = null,
                        tint = TrendXColors.Accent, modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(
                        text = "ذروة الانتشار في اليوم ${it.day} — ${it.count} تصويت تراكمي",
                        style = TrendXType.Small, color = TrendXColors.Accent
                    )
                }
            }
        }
    }
}

@Composable
private fun TimelineChart(points: List<PollAnalytics.TimelinePoint>) {
    val maxVal = points.maxOf { it.count }.coerceAtLeast(1)
    Canvas(modifier = Modifier.fillMaxWidth().height(100.dp)) {
        val width = size.width
        val height = size.height
        if (points.size < 2) return@Canvas
        val coords = points.mapIndexed { i, item ->
            val x = width * i / (points.size - 1).toFloat()
            val y = height * (1f - item.count / maxVal.toFloat())
            Offset(x, y)
        }
        // Fill area
        val fill = Path().apply {
            moveTo(coords.first().x, height)
            coords.forEach { lineTo(it.x, it.y) }
            lineTo(coords.last().x, height)
            close()
        }
        drawPath(
            path = fill,
            brush = Brush.verticalGradient(
                listOf(TrendXColors.Primary.copy(alpha = 0.18f),
                    TrendXColors.Primary.copy(alpha = 0.02f))
            )
        )
        // Line
        val line = Path().apply {
            moveTo(coords.first().x, coords.first().y)
            coords.drop(1).forEach { lineTo(it.x, it.y) }
        }
        drawPath(path = line, color = TrendXColors.Primary,
            style = Stroke(width = 2.5.dp.toPx()))
        // Dots
        coords.forEach { drawCircle(color = TrendXColors.Primary, radius = 3.5.dp.toPx(),
            center = it) }
    }
}

@Composable
private fun SampleQualityNote() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.SoftFill)
            .padding(14.dp)
    ) {
        Icon(imageVector = Icons.Filled.Info, contentDescription = null,
            tint = TrendXColors.MutedInk, modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(8.dp))
        Text(
            text = "البيانات الديموغرافية مبنية على ملفات أعضاء TrendX. كلما كبرت العيّنة ارتفع مستوى الدقة.",
            style = TrendXType.Small,
            color = TrendXColors.MutedInk
        )
    }
}

// MARK: - Reusable

@Composable
private fun AnalyticsSection(
    title: String,
    icon: ImageVector,
    content: @Composable () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth().surfaceCard(padding = 18.dp, radius = 24.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(contentAlignment = Alignment.Center,
                modifier = Modifier.size(28.dp).clip(CircleShape)
                    .background(TrendXColors.Primary.copy(alpha = 0.10f))) {
                Icon(imageVector = icon, contentDescription = null,
                    tint = TrendXColors.Primary, modifier = Modifier.size(13.dp))
            }
            Spacer(Modifier.width(8.dp))
            Text(text = title, style = TextStyle(fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold, color = TrendXColors.Ink))
        }
        content()
    }
}

@Composable
private fun PerfTile(
    icon: ImageVector,
    value: String,
    label: String,
    sublabel: String,
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
        Box(contentAlignment = Alignment.Center,
            modifier = Modifier.size(30.dp).clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(14.dp))
        }
        Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
            color = tint), maxLines = 1)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = label, style = TextStyle(fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold, color = TrendXColors.SecondaryInk))
            Text(text = sublabel, style = TrendXType.Small,
                color = TrendXColors.TertiaryInk)
        }
    }
}

@Composable
private fun BehaviorStat(
    icon: ImageVector,
    value: String,
    label: String,
    note: String,
    noteColor: Color,
    modifier: Modifier = Modifier
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.PaleFill)
            .padding(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(imageVector = icon, contentDescription = null,
                tint = TrendXColors.TertiaryInk, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(6.dp))
            Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 18.sp,
                color = TrendXColors.Ink))
        }
        Text(text = label, style = TextStyle(fontSize = 11.sp,
            fontWeight = FontWeight.Medium, color = TrendXColors.SecondaryInk),
            maxLines = 1)
        Text(text = note, style = TrendXType.Small, color = noteColor, maxLines = 1)
    }
}

@Composable
private fun ReachTile(
    icon: ImageVector,
    value: Int,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.PaleFill)
            .padding(vertical = 12.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(15.dp))
        Text(text = value.toString(), style = TextStyle(fontWeight = FontWeight.Black,
            fontSize = 16.sp, color = TrendXColors.Ink))
        Text(text = label, style = TextStyle(fontSize = 9.5.sp, fontWeight = FontWeight.Medium,
            color = TrendXColors.TertiaryInk), textAlign = TextAlign.Center, maxLines = 2)
    }
}

@Composable
private fun CommunityTile(
    icon: ImageVector,
    value: String,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.PaleFill)
            .padding(12.dp)
    ) {
        Box(contentAlignment = Alignment.Center,
            modifier = Modifier.size(30.dp).clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(14.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp), modifier = Modifier.weight(1f)) {
            Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                color = TrendXColors.Ink), maxLines = 1)
            Text(text = label, style = TextStyle(fontSize = 10.sp,
                fontWeight = FontWeight.Medium, color = TrendXColors.TertiaryInk), maxLines = 2)
        }
    }
}

@Composable
private fun HairlineDivider() {
    Box(modifier = Modifier
        .fillMaxWidth()
        .height(0.5.dp)
        .background(TrendXColors.Outline.copy(alpha = 0.5f)))
}
