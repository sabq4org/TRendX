//
//  SurveyAnalyticsView.swift
//  TRENDX
//
//  لوحة التحليل الشامل للاستبانة — تحليل عميق بـ 9 أقسام
//  يربط الأسئلة ببعضها ويكشف الأنماط الخفية في البيانات
//

import SwiftUI

// MARK: - Main View

struct SurveyAnalyticsView: View {
    let survey: Survey
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AnalyticsTab = .overview

    private var analytics: SurveyAnalytics { .mock(for: survey) }

    enum AnalyticsTab: String, CaseIterable {
        case overview   = "الملخص"
        case profile    = "المشاركون"
        case consensus  = "الإجماع"
        case cross      = "الروابط"
        case personas   = "الشخصيات"
        case timeline   = "الزمن"
        case findings   = "الاكتشافات"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundStyle(selectedTab == tab ? .white : TrendXTheme.secondaryInk)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedTab == tab
                                            ? TrendXTheme.primaryGradient
                                            : LinearGradient(colors: [TrendXTheme.softFill], startPoint: .top, endPoint: .bottom))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(TrendXTheme.surface)

                Divider().opacity(0.4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        switch selectedTab {
                        case .overview:   overviewSection
                        case .profile:    profileSection
                        case .consensus:  consensusSection
                        case .cross:      crossSection
                        case .personas:   personasSection
                        case .timeline:   timelineSection
                        case .findings:   findingsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .background(TrendXTheme.background.ignoresSafeArea())
            }
            .navigationTitle("التحليل الشامل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TrendXTheme.primary)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - 1. Overview

    private var overviewSection: some View {
        VStack(spacing: 14) {
            // Hero card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("الملخص التنفيذي")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(TrendXTheme.primary)
                            .textCase(.uppercase)
                        Text(survey.title)
                            .font(.trendxHeadline())
                            .foregroundStyle(TrendXTheme.ink)
                            .lineLimit(2)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .trim(from: 0, to: analytics.completionRate / 100)
                            .stroke(TrendXTheme.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(TrendXTheme.softFill, lineWidth: 5)
                            .frame(width: 52, height: 52)
                        Text("\(Int(analytics.completionRate))%")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(TrendXTheme.primary)
                    }
                }

                if !survey.description.isEmpty {
                    Text(survey.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .lineSpacing(4)
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // 4 main metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SurveyMetricTile(icon: "person.3.fill",
                    value: "\(analytics.totalResponses)",
                    label: "إجمالي المشاركين",
                    sublabel: "استجابة مكتملة",
                    tint: TrendXTheme.primary)
                SurveyMetricTile(icon: "checkmark.circle.fill",
                    value: "\(Int(analytics.completionRate))%",
                    label: "معدل الإكمال",
                    sublabel: "أكملوا كل الأسئلة",
                    tint: TrendXTheme.success)
                SurveyMetricTile(icon: "clock.fill",
                    value: formatSeconds(analytics.avgCompletionSeconds),
                    label: "متوسط وقت الإكمال",
                    sublabel: "\(survey.questionCount) سؤال",
                    tint: TrendXTheme.accent)
                SurveyMetricTile(icon: "checkmark.seal.fill",
                    value: "\(Int(analytics.confidenceLevel))%",
                    label: "مستوى الثقة",
                    sublabel: "±\(String(format: "%.1f", analytics.marginOfError))%",
                    tint: TrendXTheme.aiIndigo)
            }

            // Questions preview
            SurveySectionHeader(title: "أسئلة الاستبانة", subtitle: "\(survey.questionCount) سؤال")
            ForEach(Array(survey.questions.enumerated()), id: \.offset) { i, q in
                HStack(spacing: 12) {
                    Text("\(i + 1)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                    Text(q.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                    Spacer()
                    if let leader = q.options.max(by: { $0.percentage < $1.percentage }) {
                        Text("\(Int(leader.percentage))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(TrendXTheme.primary)
                    }
                }
                .padding(14)
                .background(TrendXTheme.paleFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - 2. Respondent Profile

    private var profileSection: some View {
        VStack(spacing: 14) {
            // بطاقة المشارك النموذجي
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "المشارك النموذجي", subtitle: "بناءً على أعلى التركيزات")
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(TrendXTheme.primaryGradient)
                            .frame(width: 56, height: 56)
                        Text("👤")
                            .font(.system(size: 24))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ذكر · \(analytics.topAgeGroup) سنة · \(analytics.topCity)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(TrendXTheme.ink)
                        Text("يجيب مساءً · \(analytics.topDevice)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        Text("استغرق \(formatSeconds(analytics.avgCompletionSeconds)) لإكمال الاستبانة")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // الجنس
            VStack(alignment: .leading, spacing: 12) {
                SurveySectionHeader(title: "توزيع الجنس", subtitle: nil)
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(TrendXTheme.primaryGradient)
                            .frame(width: geo.size.width * analytics.malePercent / 100)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: [TrendXTheme.aiViolet, TrendXTheme.aiIndigo], startPoint: .leading, endPoint: .trailing))
                    }
                    .frame(height: 32)
                }
                .frame(height: 32)
                HStack {
                    ProfileLegend(color: TrendXTheme.primary, label: "ذكور", value: "\(Int(analytics.malePercent))%")
                    Spacer()
                    ProfileLegend(color: TrendXTheme.aiViolet, label: "إناث", value: "\(Int(analytics.femalePercent))%")
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // الفئات العمرية
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "الفئات العمرية", subtitle: nil)
                let ages: [(String, Double)] = [("18–24", 18), ("25–34", analytics.topAgePercent), ("35–44", 26), ("45+", 13)]
                ForEach(ages, id: \.0) { age, pct in
                    HStack(spacing: 10) {
                        Text(age)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .frame(width: 46, alignment: .trailing)
                        GeometryReader { g in
                            ZStack(alignment: .trailing) {
                                Capsule().fill(TrendXTheme.softFill).frame(height: 20)
                                Capsule()
                                    .fill(pct == analytics.topAgePercent
                                          ? TrendXTheme.primaryGradient
                                          : LinearGradient(colors: [TrendXTheme.primaryLight.opacity(0.55)], startPoint: .trailing, endPoint: .leading))
                                    .frame(width: g.size.width * pct / 100, height: 20)
                            }
                        }
                        .frame(height: 20)
                        Text("\(Int(pct))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(width: 36, alignment: .leading)
                    }
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // الجغرافيا
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "التوزيع الجغرافي", subtitle: nil)
                let geos: [(String, String, Int)] = [
                    ("🇸🇦", "السعودية", Int(Double(analytics.totalResponses) * analytics.topCountryPercent / 100)),
                    ("🇪🇬", "مصر",       Int(Double(analytics.totalResponses) * 0.18)),
                    ("🇦🇪", "الإمارات",  Int(Double(analytics.totalResponses) * 0.09)),
                    ("🌍",  "أخرى",      Int(Double(analytics.totalResponses) * 0.06))
                ]
                let maxGeo = geos.map(\.2).max() ?? 1
                ForEach(geos, id: \.1) { flag, name, count in
                    HStack(spacing: 10) {
                        Text(flag).font(.system(size: 16))
                        Text(name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .frame(width: 60, alignment: .trailing)
                        GeometryReader { g in
                            ZStack(alignment: .trailing) {
                                Capsule().fill(TrendXTheme.softFill).frame(height: 18)
                                Capsule()
                                    .fill(TrendXTheme.accent.opacity(0.85))
                                    .frame(width: g.size.width * Double(count) / Double(maxGeo), height: 18)
                            }
                        }
                        .frame(height: 18)
                        Text("\(count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .frame(width: 36, alignment: .leading)
                    }
                }
            }
            .surfaceCard(padding: 18, radius: 24)
        }
    }

    // MARK: - 3. Consensus Map

    private var consensusSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("خريطة الإجماع")
                    .font(.trendxHeadline())
                    .foregroundStyle(TrendXTheme.ink)
                Text("الأسئلة مرتبة من الأكثر توافقاً إلى الأكثر انقساماً")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            .surfaceCard(padding: 18, radius: 24)

            VStack(spacing: 10) {
                ForEach(Array(analytics.questionConsensus.sorted(by: { $0.leadPercent > $1.leadPercent }).enumerated()), id: \.offset) { i, item in
                    ConsensusRow(rank: i + 1, questionShort: item.questionShort, leadPercent: item.leadPercent, label: item.label)
                }
            }
            .surfaceCard(padding: 16, radius: 24)

            // درجة الإجماع الكلية
            let avgConsensus = analytics.questionConsensus.map(\.leadPercent).reduce(0, +) / Double(max(analytics.questionConsensus.count, 1))
            HStack(spacing: 14) {
                Image(systemName: avgConsensus > 65 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(avgConsensus > 65 ? TrendXTheme.success : TrendXTheme.warning)
                VStack(alignment: .leading, spacing: 3) {
                    Text("درجة الإجماع الكلية: \(Int(avgConsensus))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                    Text(avgConsensus > 70 ? "توافق مجتمعي واضح — نتائج موثوقة للقرار" :
                         avgConsensus > 55 ? "ميل واضح مع هامش نقاش صحي" :
                         "انقسام حقيقي — يعكس تنوعاً في الآراء")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }
            }
            .surfaceCard(padding: 16, radius: 18)
        }
    }

    // MARK: - 4. Cross Analysis

    private var crossSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                    Text("الروابط الخفية بين الأسئلة")
                        .font(.trendxHeadline())
                        .foregroundStyle(TrendXTheme.ink)
                }
                Text("أنماط مكتشفة بواسطة TRENDX AI — غير متاحة في أي منصة أخرى")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            .surfaceCard(padding: 18, radius: 24)

            // Correlation cards
            ForEach(Array(analytics.correlations.enumerated()), id: \.offset) { i, corr in
                CorrelationCard(correlation: corr, index: i)
            }

            // Cross by gender
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "الخيارات حسب الجنس", subtitle: "لكل سؤال")
                ForEach(Array(survey.questions.prefix(3).enumerated()), id: \.offset) { i, q in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("س\(i+1): \(String(q.title.prefix(32)))…")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        if let leader = q.options.max(by: { $0.percentage < $1.percentage }) {
                            HStack(spacing: 6) {
                                CrossGenderBar(gender: "ذكور", percent: min(leader.percentage + Double(i * 5), 95), color: TrendXTheme.primary)
                                CrossGenderBar(gender: "إناث", percent: max(leader.percentage - Double(i * 8), 35), color: TrendXTheme.aiViolet)
                            }
                        }
                    }
                    .padding(12)
                    .background(TrendXTheme.paleFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .surfaceCard(padding: 16, radius: 24)

            // Cross by geography
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "الخيارات حسب المنطقة", subtitle: "الرياض مقابل جدة")
                ForEach(Array(survey.questions.prefix(3).enumerated()), id: \.offset) { i, q in
                    if let leader = q.options.max(by: { $0.percentage < $1.percentage }) {
                        HStack {
                            Text("س\(i+1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(TrendXTheme.mutedInk)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(q.title.prefix(28)) + "…")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(TrendXTheme.secondaryInk)
                                HStack(spacing: 8) {
                                    GeoChip(city: "الرياض", percent: min(Int(leader.percentage) + i * 6, 92))
                                    GeoChip(city: "جدة",    percent: max(Int(leader.percentage) - i * 8, 38))
                                }
                            }
                        }
                        .padding(12)
                        .background(TrendXTheme.paleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .surfaceCard(padding: 16, radius: 24)
        }
    }

    // MARK: - 5. Personas

    private var personasSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(TrendXTheme.aiViolet)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(TrendXTheme.aiViolet.opacity(0.12)))
                    Text("الشخصيات المكتشفة")
                        .font(.trendxHeadline())
                        .foregroundStyle(TrendXTheme.ink)
                }
                Text("TRENDX AI رصد \(analytics.personas.count) أنماط مختلفة في سلوك المجيبين")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            .surfaceCard(padding: 18, radius: 24)

            ForEach(analytics.personas) { persona in
                PersonaCard(persona: persona)
            }
        }
    }

    // MARK: - 6. Timeline

    private var timelineSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                SurveySectionHeader(title: "منحنى الرأي عبر الزمن", subtitle: "\(survey.questionCount) أسبوع تتبّع")

                GeometryReader { geo in
                    let pts = analytics.sentimentTimeline.enumerated().map { i, item -> CGPoint in
                        CGPoint(
                            x: geo.size.width * CGFloat(i) / CGFloat(analytics.sentimentTimeline.count - 1),
                            y: geo.size.height * (1 - CGFloat(item.positivePercent) / 100)
                        )
                    }
                    ZStack {
                        // Grid lines
                        ForEach([25, 50, 75], id: \.self) { pct in
                            let y = geo.size.height * (1 - Double(pct) / 100)
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(TrendXTheme.outline.opacity(0.4), style: StrokeStyle(lineWidth: 0.8, dash: [4]))
                        }
                        // Fill
                        if pts.count > 1 {
                            Path { p in
                                p.move(to: CGPoint(x: pts[0].x, y: geo.size.height))
                                p.addLine(to: pts[0])
                                for pt in pts.dropFirst() { p.addLine(to: pt) }
                                p.addLine(to: CGPoint(x: pts.last!.x, y: geo.size.height))
                                p.closeSubpath()
                            }
                            .fill(LinearGradient(
                                colors: [TrendXTheme.primary.opacity(0.20), TrendXTheme.primary.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom))
                        }
                        // Line
                        if pts.count > 1 {
                            Path { p in
                                p.move(to: pts[0])
                                for pt in pts.dropFirst() { p.addLine(to: pt) }
                            }
                            .stroke(TrendXTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                        // Dots
                        ForEach(pts.indices, id: \.self) { i in
                            Circle().fill(TrendXTheme.primary).frame(width: 6, height: 6).position(pts[i])
                        }
                    }
                }
                .frame(height: 140)

                HStack {
                    ForEach([1, 4, 7, 10, 14], id: \.self) { d in
                        Text("ي\(d)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TrendXTheme.mutedInk)
                            .frame(maxWidth: .infinity)
                    }
                }

                if let peak = analytics.sentimentTimeline.max(by: { $0.positivePercent < $1.positivePercent }) {
                    Label("ذروة الإيجابية في اليوم \(peak.day): \(Int(peak.positivePercent))% مؤيد", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.accent)
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // التغير بين أول وآخر يوم
            if let first = analytics.sentimentTimeline.first, let last = analytics.sentimentTimeline.last {
                let delta = last.positivePercent - first.positivePercent
                HStack(spacing: 14) {
                    Image(systemName: delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(delta >= 0 ? TrendXTheme.success : TrendXTheme.error)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("تطور الرأي خلال الاستبانة")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(TrendXTheme.ink)
                        Text("من \(Int(first.positivePercent))% → \(Int(last.positivePercent))% | تغيّر \(delta >= 0 ? "+" : "")\(Int(delta)) نقطة")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                }
                .surfaceCard(padding: 14, radius: 18)
            }
        }
    }

    // MARK: - 7. Findings & Recommendations

    private var findingsSection: some View {
        VStack(spacing: 14) {
            // Key findings
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(TrendXTheme.aiIndigo)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("الاكتشافات الرئيسية")
                            .font(.trendxHeadline())
                            .foregroundStyle(TrendXTheme.ink)
                        Text("مُولَّدة بواسطة TRENDX AI")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.aiIndigo)
                    }
                }
                ForEach(Array(analytics.keyFindings.enumerated()), id: \.offset) { i, finding in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(TrendXTheme.aiIndigo)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                        Text(finding)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(TrendXTheme.ink)
                            .lineSpacing(4)
                    }
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // Recommendations
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(TrendXTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(TrendXTheme.accent.opacity(0.10)))
                    Text("التوصيات للمؤسسة")
                        .font(.trendxHeadline())
                        .foregroundStyle(TrendXTheme.ink)
                }
                ForEach(Array(analytics.recommendations.enumerated()), id: \.offset) { i, rec in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(TrendXTheme.success)
                        Text(rec)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(TrendXTheme.ink)
                            .lineSpacing(4)
                    }
                }
            }
            .surfaceCard(padding: 18, radius: 24)

            // Export card
            VStack(spacing: 12) {
                Text("تقرير كامل جاهز للتصدير")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TrendXTheme.ink)
                Text("PDF تنفيذي + ملف Excel بكل البيانات الخام")
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                HStack(spacing: 10) {
                    ExportButton(icon: "doc.richtext.fill", label: "تقرير PDF", tint: TrendXTheme.error)
                    ExportButton(icon: "tablecells.fill",   label: "بيانات Excel", tint: TrendXTheme.success)
                    ExportButton(icon: "square.and.arrow.up.fill", label: "مشاركة", tint: TrendXTheme.primary)
                }
            }
            .surfaceCard(padding: 18, radius: 24)
        }
    }

    // MARK: - Helpers

    private func formatSeconds(_ s: Int) -> String {
        s >= 60 ? "\(s / 60) د \(s % 60) ث" : "\(s) ث"
    }
}

// MARK: - Sub-components

private struct SurveySectionHeader: View {
    let title: String
    let subtitle: String?
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(TrendXTheme.ink)
            Spacer()
            if let sub = subtitle {
                Text(sub)
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.tertiaryInk)
            }
        }
    }
}

private struct SurveyMetricTile: View {
    let icon: String; let value: String; let label: String; let sublabel: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(TrendXTheme.secondaryInk)
                Text(sublabel).font(.trendxSmall()).foregroundStyle(TrendXTheme.tertiaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProfileLegend: View {
    let color: Color; let label: String; let value: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.trendxSmall()).foregroundStyle(TrendXTheme.secondaryInk)
            Text(value).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(color)
        }
    }
}

private struct ConsensusRow: View {
    let rank: Int; let questionShort: String; let leadPercent: Double; let label: String
    private var tint: Color {
        leadPercent > 70 ? TrendXTheme.success : leadPercent > 55 ? TrendXTheme.warning : TrendXTheme.error
    }
    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.mutedInk)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(questionShort)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.ink)
                    .lineLimit(1)
                GeometryReader { g in
                    ZStack(alignment: .trailing) {
                        Capsule().fill(TrendXTheme.softFill).frame(height: 10)
                        Capsule().fill(tint).frame(width: g.size.width * leadPercent / 100, height: 10)
                    }
                }
                .frame(height: 10)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(leadPercent))%")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }
}

private struct CorrelationCard: View {
    let correlation: (q1: String, choice1: String, q2: String, choice2: String, percent: Double)
    let index: Int
    private let tints: [Color] = [TrendXTheme.primary, TrendXTheme.aiIndigo, TrendXTheme.success]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(tints[index % tints.count])
                Text("اكتشاف \(index + 1)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(tints[index % tints.count])
                    .textCase(.uppercase)
                Spacer()
                Text("\(Int(correlation.percent))%")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(tints[index % tints.count])
            }
            HStack(spacing: 8) {
                CorrelationChip(question: correlation.q1, choice: correlation.choice1, tint: tints[index % tints.count])
                Image(systemName: "arrow.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(TrendXTheme.mutedInk)
                CorrelationChip(question: correlation.q2, choice: correlation.choice2, tint: tints[index % tints.count])
            }
            Text("من اختاروا «\(correlation.choice1)» في سؤال \(correlation.q1) اختاروا «\(correlation.choice2)» في سؤال \(correlation.q2) بنسبة \(Int(correlation.percent))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(3)
        }
        .surfaceCard(padding: 16, radius: 20)
    }
}

private struct CorrelationChip: View {
    let question: String; let choice: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(question).font(.system(size: 9, weight: .semibold)).foregroundStyle(TrendXTheme.mutedInk)
            Text("«\(choice)»").font(.system(size: 11, weight: .bold)).foregroundStyle(tint)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CrossGenderBar: View {
    let gender: String; let percent: Double; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { g in
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.85))
                        .frame(height: g.size.height * percent / 100)
                }
            }
            .frame(height: 48)
            Text(gender).font(.system(size: 9, weight: .semibold)).foregroundStyle(TrendXTheme.tertiaryInk)
            Text("\(Int(percent))%").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GeoChip: View {
    let city: String; let percent: Int
    var body: some View {
        HStack(spacing: 4) {
            Text(city).font(.system(size: 11, weight: .semibold)).foregroundStyle(TrendXTheme.secondaryInk)
            Text("\(percent)%").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(TrendXTheme.primary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(TrendXTheme.softFill)
        .clipShape(Capsule())
    }
}

private struct PersonaCard: View {
    let persona: RespondentPersona
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [TrendXTheme.aiViolet.opacity(0.2), TrendXTheme.primary.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Text(persona.emoji).font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(persona.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                    Text("\(persona.percent)% من المشاركين")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.primary)
                }
                Spacer()
                // mini donut
                ZStack {
                    Circle().stroke(TrendXTheme.softFill, lineWidth: 4).frame(width: 38, height: 38)
                    Circle()
                        .trim(from: 0, to: Double(persona.percent) / 100)
                        .stroke(TrendXTheme.aiViolet, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 38, height: 38)
                    Text("\(persona.percent)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.aiViolet)
                }
            }
            Text(persona.description)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(3)
            HStack(spacing: 6) {
                ForEach(persona.traits, id: \.self) { trait in
                    Text(trait)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TrendXTheme.aiViolet)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(TrendXTheme.aiViolet.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
        .surfaceCard(padding: 16, radius: 22)
    }
}

private struct ExportButton: View {
    let icon: String; let label: String; let tint: Color
    var body: some View {
        Button {} label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tint.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
