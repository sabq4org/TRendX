//
//  HomeScreen.swift
//  TRENDX
//

import SwiftUI
import Combine

struct HomeScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedSegment = 0
    @State private var selectedTopic: Topic?
    @State private var showFollowedOnly = false
    @State private var searchText = ""
    @State private var selectedPoll: Poll?
    @State private var showNotifications = false
    @State private var selectedAuthorHandle: String?
    @State private var selectedAuthorUser: TrendXUser?
    @State private var showTimeline = false
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
            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // Anchor the very top of the feed so re-tapping the
                // Home tab can scroll back here. The id has to live on
                // a real view inside the scroll content, not on the
                // ScrollView itself.
                Color.clear.frame(height: 0).id("home-top")
                VStack(spacing: 18) {
                    HomeHeader(
                        userName: store.currentUser.name,
                        points: store.currentUser.points,
                        avatarUrl: store.currentUser.avatarUrl,
                        coins: store.currentUser.coins,
                        unreadNotifications: notificationsCounter.unreadCount,
                        isGuest: store.isGuest,
                        onSignInTap: {
                            store.showLoginSheet = true
                        },
                        onNotificationsTap: {
                            showNotifications = true
                        },
                        onSearchTap: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                selectedSegment = 0
                            }
                        },
                        onTimelineTap: store.isGuest ? nil : { showTimeline = true }
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
            .navigationDestination(item: $selectedAuthorUser) { user in
                PublicProfileScreen(user: user, loadFromBackend: true)
                    .environmentObject(store)
                    .trendxRTL()
            }
            .navigationDestination(isPresented: $showTimeline) {
                TimelineScreen(store: store)
                    .environmentObject(store)
                    .trendxRTL()
            }
            .task { await notificationsCounter.refresh(store: store) }
            .onChange(of: store.homeScrollToTopTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.4)) {
                    proxy.scrollTo("home-top", anchor: .top)
                }
            }
            }

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
            // 🔥 The radar pulse + suggested-follows + events make the
            // social-graph layer impossible to miss. The pulse shows
            // live activity from people the user follows rather than
            // a passive "tap to open" entry card.
            if !store.isGuest {
                RadarPulseSection(store: store)

                SuggestedFollowsCarousel(store: store)

                NavigationLink {
                    EventsScreen(store: store)
                        .environmentObject(store)
                        .trendxRTL()
                } label: {
                    EventsHomeEntry()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }

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
                            },
                            onVoteWithVisibility: { optionId, isPublic in
                                store.voteOnPoll(poll.id, optionId: optionId, isPublic: isPublic)
                            },
                            onRepost: { pollId, repost in
                                Task {
                                    if repost {
                                        await store.repost(pollId: pollId)
                                    } else {
                                        await store.unrepost(pollId: pollId)
                                    }
                                }
                            },
                            onAuthorTap: { handle in
                                selectedAuthorHandle = handle
                                Task {
                                    if let user = await store.loadUserProfile(idOrHandle: handle) {
                                        await MainActor.run { selectedAuthorUser = user }
                                    }
                                }
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

// MARK: - Radar Pulse Section
//
// Live preview of the 4 most recent timeline activities (reposts from
// followed accounts, polls from followed accounts/topics, public votes,
// recent results, stories). Replaces the previous static "TimelineHomeEntry"
// gateway card so the user sees actual movement from their network without
// an extra tap.

@MainActor
private final class RadarPulseViewModel: ObservableObject {
    @Published private(set) var items: [TimelineItem] = []
    @Published private(set) var isLoading = false

    private let store: AppStore
    init(store: AppStore) { self.store = store }

    func load() async {
        guard let token = store.accessToken else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await store.apiClient.timeline(
                filter: "all",
                cursor: nil,
                accessToken: token
            )
            items = Array(response.items.prefix(4))
        } catch {
            items = []
        }
    }
}

struct RadarPulseSection: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: RadarPulseViewModel
    /// State-driven sheets — tapping a radar row opens the relevant
    /// detail surface directly instead of bouncing the user through
    /// the full `TimelineScreen` first. Mirrors `TimelineScreen.handleTap`
    /// so the routing rules stay consistent between the two surfaces.
    @State private var selectedPollId: SelectedRadarPoll?
    @State private var selectedSurvey: Survey?
    @State private var selectedStory: TimelineStoryPayload?

    private struct SelectedRadarPoll: Identifiable, Hashable {
        let id: UUID
    }

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: RadarPulseViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 12) {
            sectionHeader

            if vm.items.isEmpty {
                emptyState
                    .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.items) { item in
                        Button { handleTap(on: item) } label: {
                            RadarPulseRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .task { await vm.load() }
        .sheet(item: $selectedPollId) { wrapper in
            PollDetailView(pollId: wrapper.id)
                .environmentObject(store)
                .trendxRTL()
        }
        .sheet(item: $selectedSurvey) { survey in
            SurveyDetailView(survey: survey)
                .environmentObject(store)
                .trendxRTL()
        }
        .sheet(item: $selectedStory) { story in
            StorySheet(story: story)
                .environmentObject(store)
                .trendxRTL()
        }
    }

    /// Route a row tap to the right destination based on its kind.
    /// Same matrix as `TimelineScreen.handleTap` — polls open
    /// `PollDetailView`, surveys open `SurveyDetailView`, stories open
    /// `StorySheet`. We deliberately *do not* route to the full radar
    /// here: the user already chose a specific item, so taking them
    /// through the radar first would just be an extra tap.
    private func handleTap(on item: TimelineItem) {
        switch item.kind {
        case .poll_published, .vote_cast, .repost, .poll_results, .sector_trending:
            if let id = item.poll?.id {
                selectedPollId = SelectedRadarPoll(id: id)
            }
        case .survey_published:
            // The Survey model lives in `store.surveys` (refreshed on
            // bootstrap). If the radar mentions a survey that isn't in
            // the local cache yet — surveys table grew faster than the
            // home feed pulled — swallow the tap silently.
            if let surveyId = item.survey?.id,
               let survey = store.surveys.first(where: { $0.id == surveyId }) {
                selectedSurvey = survey
            }
        case .story:
            if let story = item.story { selectedStory = story }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [TrendXTheme.aiIndigo, TrendXTheme.aiViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 38, height: 38)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                // Tiny "live" dot
                Circle()
                    .fill(TrendXTheme.success)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .offset(x: 14, y: -14)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("نبض من تتابعهم")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                Text("نشاط لحظي من حساباتك ومجالاتك")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
            }

            Spacer(minLength: 0)

            NavigationLink {
                TimelineScreen(store: store)
                    .environmentObject(store)
                    .trendxRTL()
            } label: {
                HStack(spacing: 4) {
                    Text("الرادار")
                        .font(.system(size: 11.5, weight: .heavy))
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .heavy))
                }
                .foregroundStyle(TrendXTheme.aiIndigo)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(TrendXTheme.aiIndigo.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            VStack(alignment: .leading, spacing: 3) {
                Text("رادارك هادئ الآن")
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Text("تابع جهات وحسابات نشطة لتمتلئ هذه المنطقة.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(TrendXTheme.outline.opacity(0.6), lineWidth: 0.8)
                )
        )
    }
}

/// Compact 1-row preview of a single timeline activity. Tap behavior
/// is owned by the enclosing `NavigationLink` (always routes to the
/// full `TimelineScreen` for now — deeper drill-downs come later).
private struct RadarPulseRow: View {
    let item: TimelineItem

    private var kindAccent: Color {
        switch item.kind {
        case .poll_published, .survey_published: return TrendXTheme.primary
        case .vote_cast:        return TrendXTheme.aiIndigo
        case .repost:           return TrendXTheme.aiViolet
        case .poll_results:     return TrendXTheme.success
        case .sector_trending:  return TrendXTheme.accent
        case .story:            return TrendXTheme.aiViolet
        }
    }

    private var kindIcon: String {
        switch item.kind {
        case .poll_published:   return "doc.text.fill"
        case .survey_published: return "list.bullet.clipboard.fill"
        case .vote_cast:        return "checkmark.bubble.fill"
        case .repost:           return "arrow.2.squarepath"
        case .poll_results:     return "chart.bar.xaxis"
        case .sector_trending:  return "flame.fill"
        case .story:            return "book.fill"
        }
    }

    private var primaryText: String {
        switch item.kind {
        case .poll_published:
            return item.poll?.title ?? "استطلاع جديد"
        case .survey_published:
            return item.survey?.title ?? "استبيان جديد"
        case .vote_cast:
            if let choice = item.choice, let voter = item.voter {
                return "\(voter.name) صوّت: \(choice)"
            }
            return "صوت جديد من شخص تتابعه"
        case .repost:
            return item.poll?.title ?? "إعادة نشر"
        case .poll_results:
            if let leader = item.leaderText, let pct = item.leaderPercentage {
                return "النتيجة: \(leader) (\(pct)%)"
            }
            return item.poll?.title ?? "نتائج جاهزة"
        case .sector_trending:
            return item.topicName.map { "اتجاه ساخن في \($0)" } ?? "اتجاه ساخن"
        case .story:
            return item.story?.title ?? "قصّة جديدة"
        }
    }

    private var subtitle: String? {
        switch item.kind {
        case .poll_published, .survey_published:
            return item.publisher?.name
        case .repost:
            return item.reposter.map { "\($0.name) أعاد النشر" }
        case .poll_results:
            return item.poll?.title
        case .vote_cast:
            return item.poll?.title
        case .sector_trending:
            return item.totalVotes.map { "\($0) صوت في آخر 24 ساعة" }
        case .story:
            return item.story?.publisher?.name
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            ZStack {
                Circle()
                    .fill(kindAccent.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: kindIcon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(kindAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(primaryText)
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.left")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(TrendXTheme.mutedInk)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(kindAccent.opacity(0.16), lineWidth: 0.8)
                )
                .shadow(color: kindAccent.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Events Home Entry

private struct EventsHomeEntry: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [TrendXTheme.accent, Color(red: 0.95, green: 0.55, blue: 0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .shadow(color: TrendXTheme.accent.opacity(0.35), radius: 10, x: 0, y: 5)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("الفعاليات")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                Text("سجّل حضورك في فعاليات الجهات والمنظمات — خريطة حيّة لكل فعالية")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(TrendXTheme.accent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(TrendXTheme.accent.opacity(0.20), lineWidth: 1)
                )
                .shadow(color: TrendXTheme.accent.opacity(0.10), radius: 12, x: 0, y: 5)
        )
    }
}
