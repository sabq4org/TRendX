//
//  SurveyDetailView.swift
//  TRENDX
//
//  صفحة الاستبيان — قائمة الأسئلة + زر التحليل الشامل
//

import SwiftUI

// MARK: - SurveyListRow (يستخدم في PollsScreen)

struct SurveyListRow: View {
    let survey: Survey
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // أيقونة القسم
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(
                            colors: survey.coverStyle.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: survey.coverStyle.glyph)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(survey.coverStyle.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(survey.coverStyle.tint)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(survey.coverStyle.wash))
                        Text("\(survey.questionCount) سؤال")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    Text(survey.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Label("\(survey.totalResponses) مشارك", systemImage: "person.2.fill")
                        Label("\(Int(survey.completionRate))% إكمال", systemImage: "checkmark.circle")
                        Label("+\(survey.rewardPoints) نقطة", systemImage: "star.fill")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.mutedInk)
            }
        }
        .buttonStyle(.plain)
        .surfaceCard(padding: 14, radius: 20)
    }
}

// MARK: - SurveyDetailView

struct SurveyDetailView: View {
    let survey: Survey
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAnalytics = false
    @State private var showTakingSheet = false
    @State private var selectedPoll: Poll?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Hero
                    surveyHero

                    // CTA: ابدأ الاستبيان
                    Button { showTakingSheet = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ابدأ الإجابة")
                                    .font(.system(size: 15, weight: .bold))
                                Text("\(survey.questionCount) أسئلة · مكافأة \(survey.rewardPoints) نقطة")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(TrendXTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: TrendXTheme.primary.opacity(0.3), radius: 14, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)

                    // الأسئلة
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("أسئلة الاستبيان")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(TrendXTheme.ink)
                            Spacer()
                            Text("\(survey.questionCount) سؤال")
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                        }
                        ForEach(Array(survey.questions.enumerated()), id: \.offset) { i, q in
                            QuestionRow(index: i, poll: q) {
                                selectedPoll = q
                            }
                        }
                    }
                    .surfaceCard(padding: 18, radius: 24)

                    // زر التحليل الشامل (ثانوي)
                    Button { showAnalytics = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                                .font(.system(size: 14, weight: .bold))
                            Text("فتح التحليل الشامل للاستبيان")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(TrendXTheme.primary)
                        .padding(14)
                        .background(TrendXTheme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(TrendXTheme.background.ignoresSafeArea())
            .navigationTitle(survey.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
            }
            .sheet(isPresented: $showAnalytics) {
                SurveyAnalyticsView(survey: survey)
            }
            .sheet(isPresented: $showTakingSheet) {
                SurveyTakingSheet(survey: survey)
                    .environmentObject(store)
                    .trendxRTL()
            }
            .sheet(item: $selectedPoll) { poll in
                PollDetailView(pollId: poll.id)
                    .environmentObject(store)
                    .trendxRTL()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Hero

    private var surveyHero: some View {
        VStack(spacing: 0) {
            // Cover
            ZStack {
                LinearGradient(
                    colors: survey.coverStyle.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(spacing: 8) {
                    Image(systemName: survey.coverStyle.glyph)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(survey.coverStyle.heroPhrase)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
            }
            .padding(.bottom, 16)

            // Title & meta
            VStack(alignment: .leading, spacing: 8) {
                Text(survey.title)
                    .font(.trendxHeadline())
                    .foregroundStyle(TrendXTheme.ink)

                if !survey.description.isEmpty {
                    Text(survey.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .lineSpacing(4)
                }

                // Stats row
                HStack(spacing: 12) {
                    SurveyStatChip(icon: "person.2.fill",      value: "\(survey.totalResponses)",          label: "مشارك",      tint: TrendXTheme.primary)
                    SurveyStatChip(icon: "checkmark.circle",   value: "\(Int(survey.completionRate))%",    label: "إكمال",      tint: TrendXTheme.success)
                    SurveyStatChip(icon: "clock",              value: formatTime(survey.avgCompletionSeconds), label: "متوسط", tint: TrendXTheme.accent)
                    SurveyStatChip(icon: "star.fill",          value: "+\(survey.rewardPoints)",           label: "نقطة",       tint: TrendXTheme.accent)
                }
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }

    private func formatTime(_ s: Int) -> String {
        s >= 60 ? "\(s / 60)د" : "\(s)ث"
    }
}

// MARK: - QuestionRow

private struct QuestionRow: View {
    let index: Int
    let poll: Poll
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // رقم السؤال
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(poll.topicStyle.tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(poll.topicStyle.wash))

                VStack(alignment: .leading, spacing: 5) {
                    Text(poll.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)

                    HStack(spacing: 6) {
                        Text("\(poll.options.count) خيارات")
                        Text("·")
                        Text("\(poll.totalVotes) تصويت")
                        if let leader = poll.options.max(by: { $0.percentage < $1.percentage }) {
                            Text("·")
                            Text("مُتصدّر: \(Int(leader.percentage))%")
                                .foregroundStyle(poll.topicStyle.tint)
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                }

                Spacer()

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.mutedInk)
            }
            .padding(12)
            .background(TrendXTheme.paleFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sub-components

private struct SurveyStatChip: View {
    let icon: String; let value: String; let label: String; let tint: Color
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
