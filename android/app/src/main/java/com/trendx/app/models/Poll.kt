package com.trendx.app.models

import com.trendx.app.theme.PollCoverStyle
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlin.time.Duration.Companion.days

@Serializable
data class PollOption(
    val id: String,
    val text: String,
    val votesCount: Int = 0,
    val percentage: Double = 0.0
)

@Serializable
data class Poll(
    val id: String,
    val title: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val coverStyle: PollCoverStyle? = null,
    val authorName: String = "مستخدم",
    val authorAvatar: String = "م",
    val authorAvatarUrl: String? = null,
    val authorIsVerified: Boolean = false,
    val options: List<PollOption> = emptyList(),
    val topicId: String? = null,
    val topicName: String? = null,
    val type: PollType = PollType.SingleChoice,
    val status: PollStatus = PollStatus.Active,
    val totalVotes: Int = 0,
    val rewardPoints: Int = 50,
    val durationDays: Int = 7,
    val createdAt: Instant = Clock.System.now(),
    val expiresAt: Instant = Clock.System.now().plus(7.days),
    val userVotedOptionId: String? = null,
    val isBookmarked: Boolean = false,
    val sharesCount: Int = 0,
    val repostsCount: Int = 0,
    val viewsCount: Int = 0,
    val savesCount: Int = 0,
    val authorAccountType: AccountType = AccountType.individual,
    val authorHandle: String? = null,
    val publisherId: String? = null,
    val voterAudience: String = "public",
    val viewerReposted: Boolean = false,
    val aiInsight: String? = null
) {
    val hasUserVoted: Boolean get() = userVotedOptionId != null
    val isExpired: Boolean get() = Clock.System.now() > expiresAt
    val topicStyle: PollCoverStyle get() =
        coverStyle ?: PollCoverStyle.fromTopic(topicName)
    val shouldShowCover: Boolean get() = imageUrl != null || coverStyle != null

    /// Whole days until `expiresAt`. Negative-clamped so an expired poll
    /// reports zero rather than a misleading negative number.
    val remainingDays: Int get() {
        val seconds = (expiresAt - Clock.System.now()).inWholeSeconds
        if (seconds <= 0) return 0
        return (seconds / 86_400).toInt()
    }

    /// Whole hours until `expiresAt`.
    val remainingHours: Int get() {
        val seconds = (expiresAt - Clock.System.now()).inWholeSeconds
        if (seconds <= 0) return 0
        return (seconds / 3_600).toInt()
    }

    val isEndingSoon: Boolean get() = !isExpired && remainingDays == 0

    /// Mirrors `Poll.deadlineLabel` from iOS — "يبقى N يوم" / "ينتهي خلال
    /// N ساعة" / "ينتهي قريباً" / "انتهى". Kept identical so Arabic copy
    /// reads the same on both platforms.
    val deadlineLabel: String get() {
        if (isExpired) return "انتهى"
        if (remainingDays >= 1) return "يبقى $remainingDays يوم"
        if (remainingHours >= 1) return "ينتهي خلال $remainingHours ساعة"
        return "ينتهي قريباً"
    }

    /// "منذ ٣ أيام" / "قبل ساعتين" — coarse RTL-friendly relative time.
    /// The iOS app uses RelativeDateTimeFormatter with the "ar" locale;
    /// we approximate with the same vocabulary.
    val timeAgo: String get() {
        val seconds = (Clock.System.now() - createdAt).inWholeSeconds.coerceAtLeast(0)
        val minutes = seconds / 60
        if (minutes < 1) return "الآن"
        if (minutes < 60) return "قبل $minutes دقيقة"
        val hours = minutes / 60
        if (hours < 24) return "قبل $hours ساعة"
        val days = hours / 24
        if (days < 30) return "قبل $days يوم"
        val months = days / 30
        if (months < 12) return "قبل $months شهر"
        return "قبل ${months / 12} سنة"
    }

    companion object {
        // Mirrors Poll.samples from iOS so the offline feed is never empty.
        // Keep at least the first 3 in lockstep with iOS so demo screenshots
        // line up across platforms.
        val samples: List<Poll> = listOf(
            Poll(
                id = pollId(1),
                title = "ما رأيك في عالم التقنية والتقنيين؟",
                coverStyle = PollCoverStyle.Tech,
                authorName = "TrendX Official",
                authorAvatar = "T",
                authorIsVerified = true,
                options = listOf(
                    PollOption(optId(1, 1), "مهم جداً للمستقبل", 35, 70.0),
                    PollOption(optId(1, 2), "مهم بشكل متوسط", 10, 20.0),
                    PollOption(optId(1, 3), "ليس مهماً", 5, 10.0)
                ),
                topicName = "تقنية",
                totalVotes = 50,
                aiInsight = "تحليل ذكي: الأغلبية (70%) ترى أن التقنية ركيزة للمستقبل."
            ),
            Poll(
                id = pollId(2),
                title = "ما هي القفزة التي تعكس التحول الحقيقي في جاذبية المملكة للاستثمار بنظرك؟",
                coverStyle = PollCoverStyle.Economy,
                authorName = "TrendX Official",
                authorAvatar = "T",
                authorIsVerified = true,
                options = listOf(
                    PollOption(optId(2, 1), "الريادة عالمياً في جودة البنية التحتية", 6, 54.55),
                    PollOption(optId(2, 2), "نمو صافي التدفقات 90% في الربع الأخير 2025", 4, 36.36),
                    PollOption(optId(2, 3), "تراجع خروج رؤوس الأموال للخارج بنسبة 84%", 2, 18.18),
                    PollOption(optId(2, 4), "القفز 38 مركزاً في الأداء الاقتصادي العالمي", 5, 45.45)
                ),
                topicName = "اقتصاد",
                totalVotes = 11,
                aiInsight = "تتصدّر البنية التحتية رأي المستطلَعين كمؤشر الثقة الأبرز."
            ),
            Poll(
                id = pollId(3),
                title = "أين تقضي إجازة العيد غالباً؟",
                coverStyle = PollCoverStyle.Social,
                authorName = "Mahmoud Hafez",
                authorAvatar = "م",
                options = listOf(
                    PollOption(optId(3, 1), "في جزيرة القطن (السرير)", 2, 16.67),
                    PollOption(optId(3, 2), "التنزه مع الأصدقاء", 2, 16.67),
                    PollOption(optId(3, 3), "زيارات عائلية", 8, 66.67),
                    PollOption(optId(3, 4), "السينما أهم شيء", 0, 0.0),
                    PollOption(optId(3, 5), "أمام التلفزيون مع الكعك", 3, 25.0)
                ),
                topicName = "اجتماعية",
                totalVotes = 12,
                rewardPoints = 30
            )
        )

        private fun pollId(n: Int) = "10000000-0000-0000-0000-${"%012d".format(n)}"
        private fun optId(p: Int, i: Int) =
            "10000000-0000-0000-${"%04d".format(p)}-${"%012d".format(i)}"
    }
}
