//
//  PollDetailView.swift
//  TRENDX
//

import SwiftUI

struct PollDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let pollId: UUID
    @State private var showAnalytics = false

    private var poll: Poll? {
        store.poll(withId: pollId)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let poll {
                    VStack(spacing: 18) {
                        PollDetailHero(poll: poll)

                        PollCard(
                            poll: poll,
                            onVote: { optionId in
                                store.voteOnPoll(poll.id, optionId: optionId)
                            },
                            onBookmark: {
                                store.toggleBookmark(poll.id)
                            },
                            onShare: {
                                store.sharePoll(poll.id)
                            }
                        )

                        PollDetailInsights(poll: store.poll(withId: pollId) ?? poll)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                } else {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "الاستطلاع غير متاح",
                        message: "قد يكون تم حذفه أو لم يعد ضمن بيانات هذا الجهاز."
                    )
                    .padding(20)
                }
            }
            .trendxScreenBackground()
            .navigationTitle("تفاصيل الاستطلاع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let poll {
                        Button {
                            showAnalytics = true
                        } label: {
                            Label("الإحصائيات", systemImage: "chart.bar.xaxis")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(TrendXTheme.primary)
                        .sheet(isPresented: $showAnalytics) {
                            PollAnalyticsView(poll: poll)
                        }
                    }
                }
            }
        }
    }
}

private struct PollDetailHero: View {
    let poll: Poll

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                StatusBadge(kind: poll.isExpired ? .ended : (poll.hasUserVoted ? .voted : (poll.isEndingSoon ? .warning : .active)))

                Spacer()

                Label("+\(poll.rewardPoints)", systemImage: "star.circle.fill")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.accentDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(TrendXTheme.accent.opacity(0.12)))
            }

            Text("قراءة أعمق للصوت الجماعي")
                .font(.trendxHeadline())
                .foregroundStyle(TrendXTheme.ink)

            Text("افتح النتائج، راقب الفروقات، واجعل صوتك جزءاً من تحليل TRENDX AI المحلي.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(4)
        }
        .surfaceCard(padding: 18, radius: 24)
    }
}

private struct PollDetailInsights: View {
    let poll: Poll

    private var leader: PollOption? {
        poll.options.max { $0.percentage < $1.percentage }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "لوحة التحليل",
                subtitle: "مبنية على نتائج هذا الجهاز",
                showMore: false
            )
            .padding(.horizontal, -20)

            HStack(spacing: 10) {
                DetailMetricTile(icon: "person.2.fill", value: "\(poll.totalVotes)", label: "تصويت", tint: TrendXTheme.primary)
                DetailMetricTile(icon: "clock.fill", value: poll.deadlineLabel, label: "الوقت", tint: poll.isEndingSoon ? TrendXTheme.warning : TrendXTheme.success)
            }

            if poll.viewsCount + poll.sharesCount + poll.savesCount > 0 {
                HStack(spacing: 10) {
                    DetailMetricTile(icon: "eye.fill", value: PollDetailFormatter.compact(poll.viewsCount), label: "مشاهدة", tint: TrendXTheme.aiIndigo)
                    DetailMetricTile(icon: "square.and.arrow.up.fill", value: PollDetailFormatter.compact(poll.sharesCount), label: "مشاركة", tint: TrendXTheme.aiViolet)
                    DetailMetricTile(icon: "bookmark.fill", value: PollDetailFormatter.compact(poll.savesCount), label: "حفظ", tint: TrendXTheme.accent)
                }
            }

            if let leader {
                AIInsightChip(
                    text: poll.aiInsight ?? TrendXAI.postVoteInsight(for: poll),
                    label: "تحليل TRENDX AI"
                )

                Text("الخيار المتصدر: \(leader.text) بنسبة \(Int(leader.percentage))%.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .padding(.horizontal, 4)
            }
        }
        .surfaceCard(padding: 16, radius: 24)
    }
}

private struct DetailMetricTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))

            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(label)
                .font(.trendxSmall())
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TrendXTheme.paleFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private enum PollDetailFormatter {
    static func compact(_ value: Int) -> String {
        switch value {
        case ..<1_000: return "\(value)"
        case ..<1_000_000:
            let v = Double(value) / 1_000
            return v < 10 ? String(format: "%.1fK", v) : String(format: "%.0fK", v)
        default:
            let v = Double(value) / 1_000_000
            return String(format: "%.1fM", v)
        }
    }
}

