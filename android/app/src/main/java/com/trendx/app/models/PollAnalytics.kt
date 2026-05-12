package com.trendx.app.models

// Mirrors `struct PollAnalytics` + `mock(for:)` from
// TRENDX/Screens/PollAnalyticsView.swift. The numbers are intentionally
// deterministic per poll.id (SplitMix64 seeded from the UUID's first 8
// bytes) so the analytics dashboard reads the same on iOS and Android
// and stays stable across re-renders. When the backend's
// `/analytics/poll/:id` ships, swap `mock(for:)` for the real fetch.
data class PollAnalytics(
    val totalVotes: Int,
    val totalImpressions: Int,
    val conversionRate: Double,
    val confidenceLevel: Double,
    val marginOfError: Double,
    val malePercent: Double,
    val femalePercent: Double,
    val ageGroups: List<AgeGroup>,
    val geoBreakdown: List<GeoBreakdown>,
    val peakHours: List<PeakHour>,
    val avgDecisionSeconds: Int,
    val mobilePercent: Double,
    val readBeforeVotePercent: Double,
    val changeVotePercent: Double,
    val sharesCount: Int,
    val savesCount: Int,
    val repostsCount: Int,
    val profileVisits: Int,
    val newFollowers: Int,
    val sectorBenchmarkDelta: Double,
    val communityPointsEarned: Int,
    val activeContributors: Int,
    val returnRatePercent: Double,
    val timelineVotes: List<TimelinePoint>
) {
    data class AgeGroup(val label: String, val percent: Double)
    data class GeoBreakdown(val country: String, val flag: String, val count: Int)
    data class PeakHour(val hour: String, val weight: Double)
    data class TimelinePoint(val day: Int, val count: Int)

    companion object {
        fun mock(poll: Poll): PollAnalytics {
            val base = poll.totalVotes.coerceAtLeast(1)
            // Deterministic SplitMix64 seeded from poll id — matches
            // iOS's SeededRandomGenerator one-for-one so screenshots
            // line up across both platforms.
            val rng = SplitMix64(seedFrom(poll.id))
            val impressionNoise = rng.nextInt(40, 121)
            val conversionRate = rng.nextDouble(28.0, 52.0)
            val avgDecision = rng.nextInt(8, 19)
            val benchmarkDelta = rng.nextInt(-8, 33).toDouble()

            return PollAnalytics(
                totalVotes = base,
                totalImpressions = base * 3 + impressionNoise,
                conversionRate = conversionRate,
                confidenceLevel = when {
                    base > 200 -> 95.0
                    base > 100 -> 90.0
                    else -> 82.0
                },
                marginOfError = when {
                    base > 200 -> 3.2
                    base > 100 -> 4.8
                    else -> 7.1
                },
                malePercent = 62.0,
                femalePercent = 38.0,
                ageGroups = listOf(
                    AgeGroup("18–24", 18.0),
                    AgeGroup("25–34", 41.0),
                    AgeGroup("35–44", 28.0),
                    AgeGroup("45+", 13.0)
                ),
                geoBreakdown = listOf(
                    GeoBreakdown("السعودية", "🇸🇦", (base * 0.68).toInt()),
                    GeoBreakdown("مصر", "🇪🇬", (base * 0.18).toInt()),
                    GeoBreakdown("الإمارات", "🇦🇪", (base * 0.09).toInt()),
                    GeoBreakdown("أخرى", "🌍", (base * 0.05).toInt())
                ),
                peakHours = listOf(
                    PeakHour("6ص", 0.15), PeakHour("9ص", 0.45), PeakHour("12م", 0.60),
                    PeakHour("3م", 0.55), PeakHour("6م", 0.70),
                    PeakHour("9م", 1.00), PeakHour("12ل", 0.30)
                ),
                avgDecisionSeconds = avgDecision,
                mobilePercent = 87.0,
                readBeforeVotePercent = 34.0,
                changeVotePercent = 8.0,
                sharesCount = (base * 0.12).toInt(),
                savesCount = (base * 0.09).toInt(),
                repostsCount = (base * 0.06).toInt(),
                profileVisits = (base * 0.14).toInt(),
                newFollowers = (base * 0.02).toInt(),
                sectorBenchmarkDelta = benchmarkDelta,
                communityPointsEarned = base * 50,
                activeContributors = (base * 0.72).toInt(),
                returnRatePercent = 64.0,
                timelineVotes = run {
                    val curve = intArrayOf(8, 22, 38, 55, 68, 80, 100)
                    (0 until 7).map { day ->
                        TimelinePoint(day = day + 1,
                            count = (base * curve[day] / 100))
                    }
                }
            )
        }

        private fun seedFrom(id: String): ULong {
            // Use the first 8 bytes of the UUID hex (no dashes) as the seed.
            val hex = id.replace("-", "").take(16).padEnd(16, '0')
            var seed: ULong = 0u
            for (i in 0 until 8) {
                val byte = hex.substring(i * 2, i * 2 + 2).toIntOrNull(16) ?: 0
                seed = seed or (byte.toULong() shl ((7 - i) * 8))
            }
            return if (seed == 0uL) 0x9E3779B97F4A7C15uL else seed
        }
    }
}

// SplitMix64 — same algorithm Swift uses. Pure-Kotlin so the seeded
// numbers come out byte-identical to iOS for any given poll.id.
internal class SplitMix64(seed: ULong) {
    private var state: ULong = if (seed == 0uL) 0x9E3779B97F4A7C15uL else seed

    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var z = state
        z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9uL
        z = (z xor (z shr 27)) * 0x94D049BB133111EBuL
        return z xor (z shr 31)
    }

    fun nextInt(min: Int, maxExclusive: Int): Int {
        val span = (maxExclusive - min).coerceAtLeast(1).toULong()
        return ((next() % span).toLong() + min).toInt()
    }

    fun nextDouble(min: Double, max: Double): Double {
        // 53 bits of randomness → uniform [0, 1) → scale into [min, max).
        val frac = (next() shr 11).toDouble() / (1uL shl 53).toDouble()
        return min + frac * (max - min)
    }
}
