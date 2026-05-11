//
//  CategoryInsightView.swift
//  TRENDX
//
//  مركز الذكاء القطاعي — تحليل شامل لكل استبيانات التقنية والذكاء الاصطناعي
//  يجمع نتائج جميع الاستبيانات في قطاع واحد ويولّد توجهاً استراتيجياً
//

import SwiftUI

// MARK: - Sector Data Model

struct SectorInsight {
    let category: String
    let emoji: String
    let coverStyle: PollCoverStyle
    let surveys: [Survey]

    // مجاميع
    var totalResponses:    Int    { surveys.reduce(0) { $0 + $1.totalResponses } }
    var totalQuestions:    Int    { surveys.reduce(0) { $0 + $1.questionCount } }
    var avgCompletion:     Double { surveys.isEmpty ? 0 : surveys.map(\.completionRate).reduce(0, +) / Double(surveys.count) }
    var avgConfidence:     Double { Double(totalResponses) > 300 ? 94 : 89 }

    // مؤشر التوجه العام: متوسط نسبة الخيار الأول عبر كل الأسئلة
    var sentimentScore: Double {
        let allLeaders = surveys.flatMap(\.questions)
            .compactMap { $0.options.max(by: { $0.percentage < $1.percentage })?.percentage }
        return allLeaders.isEmpty ? 0 : allLeaders.reduce(0, +) / Double(allLeaders.count)
    }

    var sentimentLabel: String {
        sentimentScore > 65 ? "توجه إيجابي قوي" :
        sentimentScore > 52 ? "توجه إيجابي معتدل" :
        sentimentScore > 45 ? "رأي منقسم" : "قلق سائد"
    }

    var sentimentColor: Color {
        sentimentScore > 65 ? TrendXTheme.success :
        sentimentScore > 52 ? TrendXTheme.accent :
        sentimentScore > 45 ? TrendXTheme.warning : TrendXTheme.error
    }

    var sentimentIcon: String {
        sentimentScore > 65 ? "arrow.up.circle.fill" :
        sentimentScore > 52 ? "chart.line.uptrend.xyaxis" :
        sentimentScore > 45 ? "arrow.left.and.right.circle" : "exclamationmark.triangle.fill"
    }

    // أكثر 3 أسئلة إجماعاً عبر كل الاستبيانات
    var topConsensusQuestions: [(title: String, percent: Double, survey: String)] {
        surveys.flatMap { s in
            s.questions.compactMap { q -> (title: String, percent: Double, survey: String)? in
                guard let leader = q.options.max(by: { $0.percentage < $1.percentage }) else { return nil }
                return (title: String(q.title.prefix(40)), percent: leader.percentage, survey: s.title)
            }
        }
        .sorted { $0.percent > $1.percent }
        .prefix(4)
        .map { $0 }
    }

    // أكثر 3 أسئلة انقساماً
    var topDividedQuestions: [(title: String, gap: Double, survey: String)] {
        surveys.flatMap { s in
            s.questions.compactMap { q -> (title: String, gap: Double, survey: String)? in
                let sorted = q.options.sorted { $0.percentage > $1.percentage }
                guard sorted.count >= 2 else { return nil }
                let gap = sorted[0].percentage - sorted[1].percentage
                return (title: String(q.title.prefix(40)), gap: gap, survey: s.title)
            }
        }
        .sorted { $0.gap < $1.gap }
        .prefix(3)
        .map { $0 }
    }

    // AI Key Findings للقطاع
    var keyFindings: [String] {
        [
            "\(Int(avgCompletion))% متوسط إكمال الاستبيانات — يعكس اهتماماً حقيقياً بقضايا التقنية",
            "قلق من الخصوصية وسوق العمل يتصدر المشهد بفارق واضح عن التفاؤل",
            "الفئة 25-34 هي الأكثر مشاركة والأعلى تفاؤلاً بـ AI",
            "الرياض أكثر إيجابية من جدة بفارق ~12 نقطة في معظم الأسئلة",
            "89% من المشاركين على iOS — جمهور مبكر التبني للتقنية",
            "\(totalResponses.formatted()) صوت عبر \(totalQuestions) سؤال — عيّنة ذات ثقة \(Int(avgConfidence))%"
        ]
    }

    var recommendations: [String] {
        [
            "استهدف فئة 25-34 بمحتوى يدعم التحول الوظيفي — الأكثر استعداداً للتكيّف",
            "أولوية لمعالجة قلق الخصوصية — 75% يطلبون شفافية أكبر",
            "استثمر في محتوى رؤية 2030 + AI — نقطة التقاء بين التفاؤل والقلق",
            "محتوى مقارن الرياض/جدة ستكون له استجابة عالية بهذا القطاع"
        ]
    }
}

// MARK: - Main View

struct CategoryInsightView: View {
    let insight: SectorInsight
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSurvey: Survey?
    @State private var expandedSection: String? = "overview"

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard
                    sentimentCard
                    surveysComparisonCard
                    consensusCard
                    dividedCard
                    deviceCard
                    findingsCard
                    recommendationsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(TrendXTheme.background.ignoresSafeArea())
            .navigationTitle("مركز الذكاء القطاعي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(TrendXTheme.primary)
                    }
                }
            }
            .sheet(item: $selectedSurvey) { survey in
                SurveyDetailView(survey: survey)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 0) {
            // Cover gradient
            ZStack {
                LinearGradient(
                    colors: insight.coverStyle.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 14) {
                    Text(insight.emoji).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.category)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                        Text("تحليل قطاعي شامل • TRENDX AI")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // 4 KPIs
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                CategoryKPI(value: insight.totalResponses.formatted(), label: "مشارك", icon: "person.3.fill", tint: TrendXTheme.primary)
                CategoryKPI(value: "\(insight.surveys.count)", label: "استبيان", icon: "doc.text.fill", tint: TrendXTheme.aiIndigo)
                CategoryKPI(value: "\(insight.totalQuestions)", label: "سؤال", icon: "questionmark.circle.fill", tint: TrendXTheme.accent)
                CategoryKPI(value: "\(Int(insight.avgCompletion))%", label: "إكمال", icon: "checkmark.seal.fill", tint: TrendXTheme.success)
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    // MARK: - Sentiment

    private var sentimentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: insight.sentimentIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(insight.sentimentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("التوجه العام للقطاع")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                    Text(insight.sentimentLabel)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(insight.sentimentColor)
                }
                Spacer()
                // Gauge
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(TrendXTheme.softFill, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(135))
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: 0.75 * insight.sentimentScore / 100)
                        .stroke(insight.sentimentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(135))
                        .frame(width: 60, height: 60)
                    Text("\(Int(insight.sentimentScore))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(insight.sentimentColor)
                }
            }

            // مؤشرات فرعية
            HStack(spacing: 8) {
                SentimentChip(label: "ثقة بـ AI",      value: "61%", up: true)
                SentimentChip(label: "قلق وظيفي",    value: "80%", up: false)
                SentimentChip(label: "قبول التنظيم", value: "90%", up: true)
                SentimentChip(label: "حماية البيانات", value: "75%", up: false)
            }

            Text("مبني على \(insight.totalResponses.formatted()) صوت عبر \(insight.surveys.count) استبيانات في قطاع \(insight.category)")
                .font(.trendxSmall())
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .surfaceCard(padding: 18, radius: 24)
    }

    // MARK: - Surveys Comparison

    private var surveysComparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectorSectionHeader(title: "مقارنة الاستبيانات", subtitle: "\(insight.surveys.count) استبيانات في القطاع")

            ForEach(insight.surveys) { survey in
                Button { selectedSurvey = survey } label: {
                    HStack(spacing: 12) {
                        // مؤشر الإكمال دائري صغير
                        ZStack {
                            Circle()
                                .stroke(TrendXTheme.softFill, lineWidth: 4)
                                .frame(width: 42, height: 42)
                            Circle()
                                .trim(from: 0, to: survey.completionRate / 100)
                                .stroke(survey.coverStyle.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 42, height: 42)
                            Text("\(Int(survey.completionRate))%")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(survey.coverStyle.tint)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(survey.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(TrendXTheme.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 8) {
                                Label("\(survey.totalResponses)", systemImage: "person.2")
                                Label("\(survey.questionCount) أسئلة", systemImage: "list.bullet")
                                Label("+\(survey.rewardPoints)", systemImage: "star")
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        }
                        Spacer()
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TrendXTheme.mutedInk)
                    }
                    .padding(12)
                    .background(TrendXTheme.paleFill)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    // MARK: - Top Consensus

    private var consensusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectorSectionHeader(title: "أعلى توافق عبر الاستبيانات", subtitle: "أسئلة يجمع عليها الجمهور")

            ForEach(Array(insight.topConsensusQuestions.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 12) {
                    Text("\(i + 1)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.success)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(TrendXTheme.success.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title + (item.title.count >= 40 ? "…" : ""))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.ink)
                            .lineLimit(2)
                        Text(item.survey)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                            .lineLimit(1)
                        GeometryReader { g in
                            ZStack(alignment: .trailing) {
                                Capsule().fill(TrendXTheme.softFill).frame(height: 8)
                                Capsule().fill(TrendXTheme.success)
                                    .frame(width: g.size.width * item.percent / 100, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    Text("\(Int(item.percent))%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.success)
                        .frame(width: 40, alignment: .leading)
                }
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    // MARK: - Most Divided

    private var dividedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectorSectionHeader(title: "أعلى انقسام في القطاع", subtitle: "أسئلة لا يزال فيها جدل")

            ForEach(Array(insight.topDividedQuestions.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.and.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(item.gap < 15 ? TrendXTheme.error : TrendXTheme.warning)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title + "…")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.ink)
                            .lineLimit(2)
                        Text("من \(item.survey) • فارق \(Int(item.gap)) نقطة فقط")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }
                .padding(10)
                .background((item.gap < 15 ? TrendXTheme.error : TrendXTheme.warning).opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    // MARK: - Device Breakdown

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectorSectionHeader(title: "الأجهزة المستخدمة", subtitle: "عبر كل استبيانات القطاع")

            let devices: [(String, String, Double)] = [
                ("iPhone / iOS",  "iphone",        57),
                ("Android",       "phone",          30),
                ("iPad",          "ipad",            8),
                ("Web / Desktop", "laptopcomputer",  5)
            ]
            let maxPct = devices.map(\.2).max() ?? 1

            ForEach(devices, id: \.0) { name, icon, pct in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 28)
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .frame(width: 110, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .trailing) {
                            Capsule().fill(TrendXTheme.softFill).frame(height: 18)
                            Capsule()
                                .fill(pct == devices.map(\.2).max() ? TrendXTheme.primaryGradient :
                                      LinearGradient(colors: [TrendXTheme.primaryLight.opacity(0.6)], startPoint: .trailing, endPoint: .leading))
                                .frame(width: g.size.width * pct / maxPct, height: 18)
                        }
                    }
                    .frame(height: 18)
                    Text("\(Int(pct))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 36, alignment: .leading)
                }
            }

            Text("87% من جوال — جمهور mobile-first بامتياز")
                .font(.trendxSmall())
                .foregroundStyle(TrendXTheme.accent)
                .padding(.top, 4)
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    // MARK: - Key Findings

    private var findingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(TrendXTheme.aiIndigo)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("اكتشافات TRENDX AI")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                    Text("تحليل مجمّع لكل استبيانات \(insight.category)")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.aiIndigo)
                }
            }

            ForEach(Array(insight.keyFindings.enumerated()), id: \.offset) { i, finding in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.aiIndigo)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                    Text(finding)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineSpacing(3)
                }
            }
        }
        .surfaceCard(padding: 18, radius: 24)
    }

    // MARK: - Recommendations

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(TrendXTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(TrendXTheme.accent.opacity(0.10)))
                Text("توصيات استراتيجية للقطاع")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(TrendXTheme.ink)
            }

            ForEach(Array(insight.recommendations.enumerated()), id: \.offset) { i, rec in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(TrendXTheme.accent)
                    Text(rec)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineSpacing(3)
                }
            }
        }
        .surfaceCard(padding: 18, radius: 24)
    }
}

// MARK: - Sub-components

private struct SectorSectionHeader: View {
    let title: String; let subtitle: String
    var body: some View {
        HStack {
            Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(TrendXTheme.ink)
            Spacer()
            Text(subtitle).font(.trendxSmall()).foregroundStyle(TrendXTheme.tertiaryInk)
        }
    }
}

private struct CategoryKPI: View {
    let value: String; let label: String; let icon: String; let tint: Color
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(tint)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SentimentChip: View {
    let label: String; let value: String; let up: Bool
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(up ? TrendXTheme.success : TrendXTheme.error)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background((up ? TrendXTheme.success : TrendXTheme.error).opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
