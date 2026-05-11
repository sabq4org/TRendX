//
//  HomeScreen.swift
//  TRENDX
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedSegment = 0
    @State private var selectedTopic: Topic?
    @State private var showFollowedOnly = false
    @State private var searchText = ""
    @State private var selectedPoll: Poll?
    @State private var showNotifications = false
    @StateObject private var notificationsCounter = NotificationsCounter()

    private var feedPolls: [Poll] {
        let base = store.smartFeedPolls
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedStandardContains(searchText) ||
            ($0.topicName?.localizedStandardContains(searchText) ?? false) ||
            $0.authorName.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HomeHeader(
                        userName: store.currentUser.name,
                        points: store.currentUser.points,
                        unreadNotifications: notificationsCounter.unreadCount,
                        onNotificationsTap: {
                            showNotifications = true
                        },
                        onSearchTap: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                selectedSegment = 0
                            }
                        }
                    )

                    if selectedSegment == 0 {
                        TrendXSearchBar(text: $searchText, placeholder: "ابحث في الرادار أو اسأل TRENDX AI…")
                            .padding(.horizontal, 20)
                    }

                    TrendXSegmentedControl(
                        selectedIndex: $selectedSegment,
                        titles: ["المنشورات", "المواضيع"]
                    )
                    .padding(.top, 2)

                    if selectedSegment == 0 {
                        postsContent
                    } else {
                        topicsContent
                    }
                }
                .padding(.bottom, 120)
            }
            .refreshable { await store.refreshBootstrap() }
            .trendxScreenBackground()
            .sheet(item: $selectedPoll) { poll in
                PollDetailView(pollId: poll.id)
                    .environmentObject(store)
                    .trendxRTL()
            }
            .sheet(isPresented: $showNotifications) {
                NavigationStack {
                    NotificationsInboxScreen(store: store)
                        .environmentObject(store)
                }
                .trendxRTL()
            }
            .task { await notificationsCounter.refresh(store: store) }

            FloatingActionButton {
                store.showCreatePoll = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Posts Content

    private var postsContent: some View {
        VStack(spacing: 24) {
            // Daily bonus claim — only renders when claimable or just claimed.
            DailyBonusCard(store: store)
                .padding(.horizontal, 20)

            // Daily Pulse spotlight — same JSON as the Web /pulse page.
            NavigationLink {
                PulseTodayScreen()
                    .environmentObject(store)
                    .trendxRTL()
            } label: {
                PulseHomeCard()
                    .environmentObject(store)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            AIBriefCard(brief: TrendXAI.dailyBrief(activePolls: store.activePolls, topics: store.topics, user: store.currentUser))
                .padding(.horizontal, 20)

            // Weekly Challenge — predict-the-pulse leaderboard
            NavigationLink {
                WeeklyChallengeScreen(client: store.apiClient, accessToken: store.accessToken)
                    .environmentObject(store)
                    .trendxRTL()
            } label: {
                WeeklyChallengeHomeCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            // National TRENDX Index card
            NavigationLink {
                TrendXIndexScreen()
                    .environmentObject(store)
                    .trendxRTL()
            } label: {
                TrendXIndexHomeCard()
                    .environmentObject(store)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            HomeMomentumStrip(
                activeCount: store.activePolls.count,
                topicsCount: store.topics.count,
                points: store.currentUser.points
            )

            VStack(spacing: 14) {
                SectionHeader(
                    title: "اتجاهات اليوم",
                    subtitle: TrendXAI.trendingSubtitle
                ) {
                    store.selectedTab = .polls
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.latestPolls) { poll in
                            MiniPollCard(poll: poll) {
                                selectedPoll = poll
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            VStack(spacing: 14) {
                SectionHeader(
                    title: "مجتمعك ينتظر رأيك",
                    subtitle: TrendXAI.communitySubtitle,
                    showMore: false
                )

                LazyVStack(spacing: 16) {
                    ForEach(feedPolls) { poll in
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
                        .onTapGesture {
                            selectedPoll = poll
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var displayedTopics: [Topic] {
        let base = showFollowedOnly ? store.followedTopics : store.topics
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedStandardContains(searchText) }
    }

    private var topicsContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(TrendXTheme.aiIndigo.opacity(0.10))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(TrendXTheme.aiIndigo)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("استكشاف المواضيع")
                            .font(.trendxSubheadline())
                            .foregroundStyle(TrendXTheme.ink)
                        Text(TrendXAI.topicsSubtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }

                    Spacer()
                }

                TrendXSearchBar(text: $searchText, placeholder: TrendXAI.aiSearchPlaceholder)
            }
            .surfaceCard(padding: 18, radius: 18)
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                TopicFilterChip(title: "جميع المواضيع", isSelected: selectedTopic == nil) {
                    selectedTopic = nil
                    showFollowedOnly = false
                }

                TopicFilterChip(title: "تتابعهم", isSelected: showFollowedOnly) {
                    selectedTopic = nil
                    showFollowedOnly = true
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 12) {
                ForEach(displayedTopics) { topic in
                    TopicRow(topic: topic) {
                        store.toggleFollowTopic(topic.id)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct HomeMomentumStrip: View {
    let activeCount: Int
    let topicsCount: Int
    let points: Int

    var body: some View {
        HStack(spacing: 10) {
            MomentumTile(icon: "bolt.fill", value: "\(activeCount)", label: "نشط الآن", tint: TrendXTheme.warning)
            MomentumTile(icon: "square.grid.2x2.fill", value: "\(topicsCount)", label: "مجال", tint: TrendXTheme.info)
            MomentumTile(icon: "star.circle.fill", value: "\(points)", label: "رصيدك", tint: TrendXTheme.accent)
        }
        .padding(.horizontal, 20)
    }
}

private struct MomentumTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.elevatedSurface.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.86), lineWidth: 0.8)
        )
        .shadow(color: tint.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

struct TopicFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.trendxCaption())
                .foregroundStyle(isSelected ? TrendXTheme.primary : TrendXTheme.secondaryInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? TrendXTheme.primary.opacity(0.08) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeScreen()
        .environmentObject(AppStore())
        .trendxRTL()
}
