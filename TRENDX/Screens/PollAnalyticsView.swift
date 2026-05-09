//
//  PollAnalyticsView.swift
//  TRENDX
//
//  لوحة تحليل الاستطلاع — إحصائيات عميقة موجّهة للمؤسسات والأفراد
//  تغطي: الأداء العام / الديموغرافيا / سلوك التصويت / الانتشار / AI / المجتمع / الزمن
//

import SwiftUI

// MARK: - Mock Analytics Model

struct PollAnalytics {
    let totalVotes: Int
    let totalImpressions: Int
    let conversionRate: Double        // %
    let confidenceLevel: Double       // %
    let marginOfError: Double         // ±%
    let malePercent: Double
    let femalePercent: Double
    let ageGroups: [(label: String, percent: Double)]
    let geoBreakdown: [(country: String, flag: String, count: Int)]
    let peakHours: [(hour: String, weight: Double)]   // relative weight 0–1
    let avgDecisionSeconds: Int
    let mobilePercent: Double
    let readBeforeVotePercent: Double
    let changeVotePercent: Double
    let sharesCount: Int
    let savesCount: Int
    let repostsCount: Int
    let profileVisits: Int
    let newFollowers: Int
    let sectorBenchmarkDelta: Double  // +/- vs sector average
    let communityPointsEarned: Int
    let activeContributors: Int
    let returnRatePercent: Double
    let timelineVotes: [(day: Int, count: Int)]      // day index → cumulative

    static func mock(for poll: Poll) -> PollAnalytics {
        let base = max(poll.totalVotes, 1)

        // Deterministic seed derived from poll.id so numbers stay stable
        // across re-renders, sheet re-opens, and different devices.
        var rng = SeededRandomGenerator(seed: poll.id.stableSeed)

        let impressionNoise = Int.random(in: 40...120, using: &rng)
        let conversionRate  = Double.random(in: 28...52, using: &rng)
        let avgDecision     = Int.random(in: 8...18, using: &rng)
        let benchmarkDelta  = Double(Int.random(in: -8...32, using: &rng))

        return PollAnalytics(
            totalVotes: base,
            totalImpressions: base * 3 + impressionNoise,
            conversionRate: conversionRate,
            confidenceLevel: base > 200 ? 95 : base > 100 ? 90 : 82,
            marginOfError: base > 200 ? 3.2 : base > 100 ? 4.8 : 7.1,
            malePercent: 62,
            femalePercent: 38,
            ageGroups: [
                ("18–24", 18),
                ("25–34", 41),
                ("35–44", 28),
                ("45+",   13)
            ],
            geoBreakdown: [
                ("السعودية", "🇸🇦", Int(Double(base) * 0.68)),
                ("مصر",       "🇪🇬", Int(Double(base) * 0.18)),
                ("الإمارات",  "🇦🇪", Int(Double(base) * 0.09)),
                ("أخرى",      "🌍",  Int(Double(base) * 0.05))
            ],
            peakHours: [
                ("6ص",  0.15), ("9ص",  0.45), ("12م", 0.60),
                ("3م",  0.55), ("6م",  0.70), ("9م",  1.00), ("12ل", 0.30)
            ],
            avgDecisionSeconds: avgDecision,
            mobilePercent: 87,
            readBeforeVotePercent: 34,
            changeVotePercent: 8,
            sharesCount: Int(Double(base) * 0.12),
            savesCount: Int(Double(base) * 0.09),
            repostsCount: Int(Double(base) * 0.06),
            profileVisits: Int(Double(base) * 0.14),
            newFollowers: Int(Double(base) * 0.02),
            sectorBenchmarkDelta: benchmarkDelta,
            communityPointsEarned: base * 50,
            activeContributors: Int(Double(base) * 0.72),
            returnRatePercent: 64,
            timelineVotes: (0..<7).map { day in
                let curve = [8, 22, 38, 55, 68, 80, 100]
                return (day + 1, Int(Double(base) * Double(curve[day]) / 100))
            }
        )
    }
}

// MARK: - Seeded RNG (deterministic per poll)

/// A small deterministic RNG so analytics tied to a `poll.id` stay
/// identical between renders and app launches without persistence.
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state which would lock SplitMix64.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private extension UUID {
    /// Stable 64-bit seed derived from a UUID's first 8 bytes.
    var stableSeed: UInt64 {
        let bytes = uuid
        var seed: UInt64 = 0
        seed |= UInt64(bytes.0)  << 56
        seed |= UInt64(bytes.1)  << 48
        seed |= UInt64(bytes.2)  << 40
        seed |= UInt64(bytes.3)  << 32
        seed |= UInt64(bytes.4)  << 24
        seed |= UInt64(bytes.5)  << 16
        seed |= UInt64(bytes.6)  << 8
        seed |= UInt64(bytes.7)
        return seed
    }
}

// MARK: - Main View

struct PollAnalyticsView: View {
    let poll: Poll
    @Environment(\.dismiss) private var dismiss

    /// Generated once per `poll.id` so re-renders keep the same numbers.
    private var analytics: PollAnalytics {
        PollAnalytics.mock(for: poll)
    }

    private var shareSummary: String {
        let leader = poll.options.max { $0.percentage < $1.percentage }
        var lines: [String] = []
        lines.append("استطلاع TRENDX: \(poll.title)")
        lines.append("• إجمالي الأصوات: \(analytics.totalVotes)")
        lines.append("• مستوى الثقة: \(Int(analytics.confidenceLevel))% (هامش ±\(String(format: "%.1f", analytics.marginOfError))%)")
        if let leader {
            lines.append("• الأعلى: «\(leader.text)» بنسبة \(Int(leader.percentage))%")
        }
        lines.append("مدعوم بـ TRENDX AI")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    analyticsHero
                    performanceSection
                    demographicsSection
                    behaviorSection
                    reachSection
                    aiAnalysisSection
                    communitySection
                    timelineSection
                    sampleQualityNote
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(TrendXTheme.background.ignoresSafeArea())
            .navigationTitle("لوحة التحليل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: shareSummary,
                        subject: Text("ملخص استطلاع TRENDX"),
                        message: Text(poll.title)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(TrendXTheme.primary)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Hero

    private var analyticsHero: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("قراءة معمّقة")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(TrendXTheme.accent)
                Text(poll.title)
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(TrendXTheme.ink)
                    .lineLimit(2)
                    .lineSpacing(2)
                Label(poll.deadlineLabel, systemImage: "clock.fill")
                    .font(.trendxSmall())
                    .foregroundStyle(poll.isEndingSoon ? TrendXTheme.warning : TrendXTheme.tertiaryInk)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(analytics.totalVotes)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.primary)
                Text("صوت")
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.tertiaryInk)
            }
        }
        .surfaceCard(padding: 18, radius: 24)
    }

    // MARK: - Section 1: Performance

    private var performanceSection: some View {
        AnalyticsSection(title: "الأداء العام", icon: "gauge.open.with.lines.needle.67percent") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerfTile(
                    icon: "arrow.turn.up.right",
                    value: "\(Int(analytics.conversionRate))%",
                    label: "معدل التحويل",
                    sublabel: "من الظهور للتصويت",
                    tint: TrendXTheme.primary
                )
                PerfTile(
                    icon: "checkmark.seal.fill",
                    value: "\(Int(analytics.confidenceLevel))%",
                    label: "مستوى الثقة",
                    sublabel: "±\(String(format: "%.1f", analytics.marginOfError))%",
                    tint: TrendXTheme.success
                )
                PerfTile(
                    icon: "eye.fill",
                    value: "\(analytics.totalImpressions)",
                    label: "مرات الظهور",
                    sublabel: "الوصول الكلي",
                    tint: TrendXTheme.info
                )
                PerfTile(
                    icon: "chart.line.uptrend.xyaxis",
                    value: analytics.sectorBenchmarkDelta > 0 ? "+\(Int(analytics.sectorBenchmarkDelta))%" : "\(Int(analytics.sectorBenchmarkDelta))%",
                    label: "مقارنة بالقطاع",
                    sublabel: analytics.sectorBenchmarkDelta > 0 ? "أعلى من المتوسط" : "أدنى من المتوسط",
                    tint: analytics.sectorBenchmarkDelta > 0 ? TrendXTheme.success : TrendXTheme.error
                )
            }
        }
    }

    // MARK: - Section 2: Demographics

    private var demographicsSection: some View {
        AnalyticsSection(title: "ديموغرافيا المصوّتين", icon: "person.2.fill") {
            VStack(spacing: 16) {
                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("الجنس")
                        .font(.trendxCaption())
                        .foregroundStyle(TrendXTheme.tertiaryInk)

                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(TrendXTheme.primary)
                                .frame(width: geo.size.width * analytics.malePercent / 100)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(TrendXTheme.aiViolet)
                        }
                        .frame(height: 28)
                    }
                    .frame(height: 28)

                    HStack {
                        Label("\(Int(analytics.malePercent))% ذكور", systemImage: "figure.stand")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.primary)
                        Spacer()
                        Label("\(Int(analytics.femalePercent))% إناث", systemImage: "figure.stand.dress")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.aiViolet)
                    }
                }

                Divider().opacity(0.5)

                // Age groups
                VStack(alignment: .leading, spacing: 10) {
                    Text("الفئات العمرية")
                        .font(.trendxCaption())
                        .foregroundStyle(TrendXTheme.tertiaryInk)

                    ForEach(analytics.ageGroups, id: \.label) { group in
                        HStack(spacing: 10) {
                            Text(group.label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(TrendXTheme.secondaryInk)
                                .frame(width: 48, alignment: .trailing)

                            GeometryReader { geo in
                                ZStack(alignment: .trailing) {
                                    Capsule()
                                        .fill(TrendXTheme.softFill)
                                        .frame(height: 18)
                                    Capsule()
                                        .fill(group.percent == analytics.ageGroups.max(by: { $0.percent < $1.percent })?.percent
                                              ? TrendXTheme.primaryGradient
                                              : LinearGradient(colors: [TrendXTheme.primaryLight.opacity(0.6)], startPoint: .trailing, endPoint: .leading))
                                        .frame(width: geo.size.width * group.percent / 100, height: 18)
                                }
                            }
                            .frame(height: 18)

                            Text("\(Int(group.percent))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(TrendXTheme.primary)
                                .frame(width: 36, alignment: .leading)
                        }
                    }
                }

                Divider().opacity(0.5)

                // Geographic
                VStack(alignment: .leading, spacing: 10) {
                    Text("التوزيع الجغرافي")
                        .font(.trendxCaption())
                        .foregroundStyle(TrendXTheme.tertiaryInk)

                    let maxCount = analytics.geoBreakdown.map(\.count).max() ?? 1
                    ForEach(analytics.geoBreakdown, id: \.country) { geo in
                        HStack(spacing: 10) {
                            Text(geo.flag)
                                .font(.system(size: 16))
                            Text(geo.country)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(TrendXTheme.secondaryInk)
                                .frame(width: 60, alignment: .trailing)

                            GeometryReader { proxy in
                                Capsule()
                                    .fill(TrendXTheme.softFill)
                                    .frame(height: 16)
                                    .overlay(alignment: .trailing) {
                                        Capsule()
                                            .fill(TrendXTheme.accent.opacity(0.85))
                                            .frame(
                                                width: proxy.size.width * Double(geo.count) / Double(maxCount),
                                                height: 16
                                            )
                                    }
                            }
                            .frame(height: 16)

                            Text("\(geo.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(TrendXTheme.secondaryInk)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section 3: Behavior

    private var behaviorSection: some View {
        AnalyticsSection(title: "سلوك التصويت", icon: "brain.head.profile") {
            VStack(spacing: 14) {
                // Peak hours mini chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("ساعات الذروة")
                        .font(.trendxCaption())
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(analytics.peakHours, id: \.hour) { slot in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(slot.weight == 1.0
                                          ? TrendXTheme.primaryGradient
                                          : LinearGradient(colors: [TrendXTheme.primaryLight.opacity(slot.weight * 0.8)], startPoint: .top, endPoint: .bottom))
                                    .frame(height: max(6, 52 * slot.weight))
                                Text(slot.hour)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(TrendXTheme.mutedInk)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 68)
                    Text("ذروة التصويت بين 8–10 مساءً")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }

                Divider().opacity(0.5)

                // Behavior stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    BehaviorStat(icon: "timer", value: "\(analytics.avgDecisionSeconds)ث", label: "متوسط وقت القرار",
                                 note: analytics.avgDecisionSeconds < 12 ? "قناعة راسخة" : "تأمل قبل التصويت",
                                 noteColor: analytics.avgDecisionSeconds < 12 ? TrendXTheme.success : TrendXTheme.warning)
                    BehaviorStat(icon: "iphone", value: "\(Int(analytics.mobilePercent))%", label: "تصويت من الجوال",
                                 note: "جمهور موبايل-فيرست", noteColor: TrendXTheme.info)
                    BehaviorStat(icon: "doc.text.magnifyingglass", value: "\(Int(analytics.readBeforeVotePercent))%", label: "قرأ التفاصيل أولاً",
                                 note: "تصويت مدروس", noteColor: TrendXTheme.success)
                    BehaviorStat(icon: "arrow.2.circlepath", value: "\(Int(analytics.changeVotePercent))%", label: "غيّر اختياره",
                                 note: "قرارات بحذر", noteColor: TrendXTheme.mutedInk)
                }

                // Polarization indicator
                if let leader = poll.options.max(by: { $0.percentage < $1.percentage }),
                   let second = poll.options.sorted(by: { $0.percentage > $1.percentage }).dropFirst().first {
                    let gap = leader.percentage - second.percentage
                    Divider().opacity(0.5)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("درجة الانقسام")
                                .font(.trendxCaption())
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                            Spacer()
                            Text(gap > 25 ? "توافق جماعي" : gap > 10 ? "ميل واضح" : "انقسام حاد")
                                .font(.trendxSmall())
                                .foregroundStyle(gap > 25 ? TrendXTheme.success : gap > 10 ? TrendXTheme.warning : TrendXTheme.error)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill((gap > 25 ? TrendXTheme.success : gap > 10 ? TrendXTheme.warning : TrendXTheme.error).opacity(0.12)))
                        }
                        Text("«\(leader.text)» يتقدم بـ \(Int(gap)) نقطة على «\(second.text)»")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                }
            }
        }
    }

    // MARK: - Section 4: Reach

    private var reachSection: some View {
        AnalyticsSection(title: "الانتشار والتأثير", icon: "antenna.radiowaves.left.and.right") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ReachTile(icon: "square.and.arrow.up", value: analytics.sharesCount, label: "مشاركة", tint: TrendXTheme.info)
                ReachTile(icon: "bookmark.fill", value: analytics.savesCount, label: "حفظ", tint: TrendXTheme.accent)
                ReachTile(icon: "arrow.2.squarepath", value: analytics.repostsCount, label: "إعادة نشر", tint: TrendXTheme.aiViolet)
                ReachTile(icon: "person.crop.circle.badge.checkmark", value: analytics.profileVisits, label: "زيارة الملف", tint: TrendXTheme.success)
                ReachTile(icon: "person.badge.plus", value: analytics.newFollowers, label: "متابع جديد", tint: TrendXTheme.primary)
                ReachTile(icon: "chart.bar.fill", value: Int(analytics.returnRatePercent), label: "% معدل العودة", tint: TrendXTheme.accentDeep)
            }
        }
    }

    // MARK: - Section 5: AI Analysis

    private var aiAnalysisSection: some View {
        AnalyticsSection(title: "تحليل TRENDX AI", icon: "sparkles") {
            VStack(spacing: 14) {
                // Main AI insight
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(TrendXTheme.aiIndigo.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: "brain")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TrendXTheme.aiIndigo)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("قراءة ذكية")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(TrendXTheme.aiIndigo)
                            .textCase(.uppercase)
                        Text(TrendXAI.postVoteInsight(for: poll))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(TrendXTheme.ink)
                            .lineSpacing(4)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TrendXTheme.aiIndigo.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(TrendXTheme.aiIndigo.opacity(0.18), lineWidth: 1))
                )

                // Sector benchmark
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(analytics.sectorBenchmarkDelta > 0 ? TrendXTheme.success : TrendXTheme.error)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill((analytics.sectorBenchmarkDelta > 0 ? TrendXTheme.success : TrendXTheme.error).opacity(0.10)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("البنشمارك القطاعي")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Text("استطلاعك أعلى من \(analytics.sectorBenchmarkDelta > 0 ? "87%" : "52%") من الاستطلاعات المشابهة هذا الشهر")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                    Spacer()
                    Text(analytics.sectorBenchmarkDelta > 0 ? "+\(Int(analytics.sectorBenchmarkDelta))%" : "\(Int(analytics.sectorBenchmarkDelta))%")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(analytics.sectorBenchmarkDelta > 0 ? TrendXTheme.success : TrendXTheme.error)
                }
                .padding(14)
                .background(TrendXTheme.paleFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Sample quality card
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("جودة العيّنة")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Text("استطلاعك وصل لـ \(analytics.totalVotes) مصوّت بمستوى ثقة \(Int(analytics.confidenceLevel))% وهامش خطأ ±\(String(format: "%.1f", analytics.marginOfError))%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                }
                .padding(14)
                .background(TrendXTheme.paleFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Section 6: Community

    private var communitySection: some View {
        AnalyticsSection(title: "أثر المجتمع", icon: "person.3.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CommunityTile(icon: "star.circle.fill", value: "\(analytics.communityPointsEarned)",
                              label: "نقطة أكسبها المجتمع", tint: TrendXTheme.accent)
                CommunityTile(icon: "person.crop.circle.badge.checkmark", value: "\(analytics.activeContributors)",
                              label: "مساهم نشط (5+ استطلاعات)", tint: TrendXTheme.primary)
                CommunityTile(icon: "arrow.clockwise", value: "\(Int(analytics.returnRatePercent))%",
                              label: "معدل العودة للمنصة", tint: TrendXTheme.success)
                CommunityTile(icon: "building.2.fill", value: "\(Int(analytics.conversionRate))%",
                              label: "تحويل للمتابعة المؤسسية", tint: TrendXTheme.aiViolet)
            }
        }
    }

    // MARK: - Section 7: Timeline

    private var timelineSection: some View {
        AnalyticsSection(title: "منحنى الزمن", icon: "chart.line.uptrend.xyaxis") {
            VStack(alignment: .leading, spacing: 12) {
                Text("تراكم الأصوات يوماً بيوم")
                    .font(.trendxCaption())
                    .foregroundStyle(TrendXTheme.tertiaryInk)

                GeometryReader { geo in
                    let maxVal = analytics.timelineVotes.map(\.count).max() ?? 1
                    let points = analytics.timelineVotes.enumerated().map { (i, item) -> CGPoint in
                        let x = geo.size.width * CGFloat(i) / CGFloat(analytics.timelineVotes.count - 1)
                        let y = geo.size.height * (1 - CGFloat(item.count) / CGFloat(maxVal))
                        return CGPoint(x: x, y: y)
                    }

                    ZStack {
                        // Fill area
                        if points.count > 1 {
                            Path { path in
                                path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                                path.addLine(to: points[0])
                                for pt in points.dropFirst() { path.addLine(to: pt) }
                                path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                                path.closeSubpath()
                            }
                            .fill(LinearGradient(
                                colors: [TrendXTheme.primary.opacity(0.18), TrendXTheme.primary.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom))
                        }

                        // Line
                        if points.count > 1 {
                            Path { path in
                                path.move(to: points[0])
                                for pt in points.dropFirst() { path.addLine(to: pt) }
                            }
                            .stroke(TrendXTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }

                        // Dots
                        ForEach(points.indices, id: \.self) { i in
                            Circle()
                                .fill(TrendXTheme.primary)
                                .frame(width: 7, height: 7)
                                .position(points[i])
                        }
                    }
                }
                .frame(height: 100)

                // Day labels
                HStack {
                    ForEach(analytics.timelineVotes, id: \.day) { item in
                        Text("ي\(item.day)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TrendXTheme.mutedInk)
                            .frame(maxWidth: .infinity)
                    }
                }

                if let peak = analytics.timelineVotes.max(by: { $0.count < $1.count }) {
                    Label("ذروة الانتشار في اليوم \(peak.day) — \(peak.count) تصويت تراكمي", systemImage: "bolt.fill")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.accent)
                }
            }
        }
    }

    // MARK: - Sample Note

    private var sampleQualityNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.mutedInk)
            Text("البيانات الديموغرافية مبنية على ملفات أعضاء TrendX. كلما كبرت العيّنة ارتفع مستوى الدقة.")
                .font(.trendxSmall())
                .foregroundStyle(TrendXTheme.mutedInk)
                .lineSpacing(3)
        }
        .padding(14)
        .background(TrendXTheme.softFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Reusable Sub-components

private struct AnalyticsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(TrendXTheme.primary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
            }
            content()
        }
        .surfaceCard(padding: 18, radius: 24)
    }
}

private struct PerfTile: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                Text(sublabel)
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.tertiaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BehaviorStat: View {
    let icon: String
    let value: String
    let label: String
    let note: String
    let noteColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineLimit(1)
            Text(note)
                .font(.trendxSmall())
                .foregroundStyle(noteColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ReachTile: View {
    let icon: String
    let value: Int
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(TrendXTheme.tertiaryInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CommunityTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
