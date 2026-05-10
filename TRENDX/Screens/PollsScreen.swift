//
//  PollsScreen.swift
//  TRENDX
//

import SwiftUI

struct PollsScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var selectedPoll: Poll?
    @State private var selectedSurvey: Survey?
    @State private var showSurveys = false
    @State private var showCategoryInsight = false
    @State private var showCreateSurvey = false

    private var activeCount: Int { store.activePolls.count }
    private var votedCount: Int { store.votedPolls.count }
    private var endedCount: Int { store.endedPolls.count }

    private var visiblePolls: [Poll] {
        let base: [Poll]
        switch selectedSegment {
        case 0: base = store.smartFeedPolls
        case 1: base = store.votedPolls
        default: base = store.endedPolls
        }

        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedStandardContains(searchText) ||
            ($0.topicName?.localizedStandardContains(searchText) ?? false) ||
            $0.authorName.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(showSurveys ? "الاستبيانات" : "الاستطلاعات")
                            .font(.trendxHeadline())
                            .foregroundStyle(TrendXTheme.ink)
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(TrendXTheme.aiIndigo)
                            Text(showSurveys ? "استبيانات متعددة الأسئلة" : "مرتّبة ذكياً بواسطة TRENDX AI")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                        }
                    }
                    Spacer()
                    // Toggle بين استطلاعات واستبيانات
                    HStack(spacing: 0) {
                        Button { withAnimation { showSurveys = false } } label: {
                            Text("استطلاعات")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(!showSurveys ? .white : TrendXTheme.secondaryInk)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(!showSurveys ? TrendXTheme.primary : Color.clear)
                                .clipShape(Capsule())
                        }.buttonStyle(.plain)
                        Button { withAnimation { showSurveys = true } } label: {
                            Text("استبيانات")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(showSurveys ? .white : TrendXTheme.secondaryInk)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(showSurveys ? TrendXTheme.primary : Color.clear)
                                .clipShape(Capsule())
                        }.buttonStyle(.plain)
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 20).fill(TrendXTheme.softFill))

                    // "+" — create poll / survey
                    Button {
                        if showSurveys {
                            showCreateSurvey = true
                        } else {
                            store.showCreatePoll = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(TrendXTheme.primaryGradient))
                            .shadow(color: TrendXTheme.primary.opacity(0.30),
                                    radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showSurveys ? "استبيان جديد" : "استطلاع جديد")

                    Spacer()
                }

                HStack(spacing: 0) {
                    PollsSegmentButton(
                        title: "النشطة",
                        count: activeCount,
                        icon: "bolt.fill",
                        isSelected: selectedSegment == 0
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = 0
                        }
                    }

                    PollsSegmentButton(
                        title: "صوّتت",
                        count: votedCount,
                        icon: "checkmark.circle.fill",
                        isSelected: selectedSegment == 1
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = 1
                        }
                    }

                    PollsSegmentButton(
                        title: "منتهية",
                        count: endedCount,
                        icon: "archivebox.fill",
                        isSelected: selectedSegment == 2
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = 2
                        }
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TrendXTheme.softFill)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if !showSurveys {
                        // استطلاعات
                        TrendXSearchBar(text: $searchText, placeholder: "ابحث داخل الاستطلاعات…")
                        if visiblePolls.isEmpty {
                            EmptyStateView(
                                icon: selectedSegment == 0 ? "sparkles" : "checkmark.seal",
                                title: selectedSegment == 0 ? "لحظة هدوء قبل الاتجاه التالي" : "لا توجد نتائج هنا",
                                message: selectedSegment == 0 ? "TRENDX AI يرصد الآن اتجاهات جديدة" : "جرّب تغيير البحث."
                            )
                        } else {
                            ForEach(visiblePolls) { poll in
                                PollListRow(poll: poll) { selectedPoll = poll }
                            }
                        }
                    } else {
                        // استبيانات
                        // زر مركز الذكاء القطاعي
                        Button { showCategoryInsight = true } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(TrendXTheme.primaryGradient)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("مركز الذكاء القطاعي")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(TrendXTheme.ink)
                                    Text("تحليل شامل لكل استبيانات التقنية و AI")
                                        .font(.trendxSmall())
                                        .foregroundStyle(TrendXTheme.aiIndigo)
                                }
                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundStyle(TrendXTheme.aiIndigo)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(TrendXTheme.aiIndigo.opacity(0.07))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(TrendXTheme.aiIndigo.opacity(0.18), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)

                        if store.surveys.isEmpty {
                            EmptyStateView(icon: "doc.text.magnifyingglass", title: "لا توجد استبيانات", message: "ستظهر الاستبيانات المتعددة الأسئلة هنا")
                        } else {
                            ForEach(store.surveys) { survey in
                                SurveyListRow(survey: survey) { selectedSurvey = survey }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 120)
            }
            .refreshable { await store.refreshBootstrap() }
            .background(Color.clear)
        }
        .trendxScreenBackground()
        .sheet(item: $selectedPoll) { poll in
            PollDetailView(pollId: poll.id)
                .environmentObject(store)
                .trendxRTL()
        }
        .sheet(item: $selectedSurvey) { survey in
            SurveyDetailView(survey: survey)
                .environmentObject(store)
        }
        .sheet(isPresented: $showCreateSurvey) {
            CreateSurveySheet()
                .environmentObject(store)
                .trendxRTL()
        }
        .sheet(isPresented: $showCategoryInsight) {
            CategoryInsightView(insight: SectorInsight(
                category: "التقنية والذكاء الاصطناعي",
                emoji: "🧠",
                coverStyle: .tech,
                surveys: Survey.techSamples
            ))
        }
    }
}

struct PollsSegmentButton: View {
    let title: String
    let count: Int
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.trendxCaption())
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? TrendXTheme.primary : TrendXTheme.secondaryInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white : TrendXTheme.paleFill)
                    )
            }
            .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? TrendXTheme.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PollListRow: View {
    let poll: Poll
    var onTap: () -> Void = {}

    private var statusKind: StatusBadge.Kind {
        if poll.isExpired { return .ended }
        if poll.hasUserVoted { return .voted }
        if poll.isEndingSoon { return .warning }
        return .active
    }

    private var style: PollCoverStyle { poll.topicStyle }
    private var tint: Color { style.tint }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                // Topic color stripe
                LinearGradient(
                    colors: style.gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 4)

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            if let topicName = poll.topicName {
                                HStack(spacing: 5) {
                                    Image(systemName: style.glyph)
                                        .font(.system(size: 10, weight: .bold))
                                    Text(topicName)
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .tracking(0.2)
                                }
                                .foregroundStyle(tint)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(style.wash)
                                )
                                .overlay(
                                    Capsule().stroke(style.hairline, lineWidth: 0.6)
                                )
                            }

                            StatusBadge(kind: statusKind)

                            Spacer(minLength: 0)
                        }

                        Text(poll.title)
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .foregroundStyle(TrendXTheme.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 14) {
                            Label("\(poll.totalVotes)", systemImage: "person.2.fill")
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.secondaryInk)

                            Label(poll.deadlineLabel, systemImage: poll.isExpired ? "clock.badge.xmark.fill" : "clock.fill")
                                .font(.trendxSmall())
                                .foregroundStyle(poll.isExpired ? TrendXTheme.muted : (poll.isEndingSoon ? TrendXTheme.warning : TrendXTheme.secondaryInk))
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    poll.isExpired
                                        ? AnyShapeStyle(TrendXTheme.softFill)
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                colors: style.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: poll.isExpired ? "eye.fill" : "arrow.left")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(poll.isExpired ? TrendXTheme.muted : .white)
                        }
                        .shadow(color: poll.isExpired ? .clear : tint.opacity(0.30), radius: 6, x: 0, y: 3)

                        HStack(spacing: 3) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(TrendXTheme.accent)
                            Text("\(poll.rewardPoints)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(TrendXTheme.accentDeep)
                        }
                    }
                }
                .padding(16)
            }
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 0.8)
            )
            .shadow(color: tint.opacity(0.08), radius: 10, x: 0, y: 4)
            .opacity(poll.isExpired ? 0.82 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PollsScreen()
        .environmentObject(AppStore())
        .trendxRTL()
}
