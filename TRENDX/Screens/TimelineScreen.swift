//
//  TimelineScreen.swift
//  TRENDX
//
//  "الرادار" — chronological activity feed aggregating polls /
//  surveys / public votes / poll results / stories from the user's
//  followed accounts and topics.
//
//  Phase 3 surface. Cards branch by `kind`. Cursor pagination via the
//  backend's `next_cutoff`.
//

import SwiftUI
import Combine

// MARK: - Decoded shapes (mirror /me/timeline)

struct TimelinePublisher: Decodable {
    let id: UUID
    let name: String
    let handle: String?
    let accountType: String
    let isVerified: Bool
    let avatarUrl: String?
    let avatarInitial: String

    var asUser: TrendXUser {
        TrendXUser(
            id: id,
            name: name,
            handle: handle?.isEmpty == false ? handle : nil,
            avatarInitial: avatarInitial,
            avatarUrl: avatarUrl?.isEmpty == false ? avatarUrl : nil,
            accountType: AccountType(rawValue: accountType) ?? .individual,
            isVerified: isVerified
        )
    }
}

struct TimelineStoryPayload: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let coverImage: String?
    let coverStyle: String?
    let publisher: TimelinePublisher?
    let itemCount: Int
}

struct TimelineItem: Decodable, Identifiable {
    let id: String
    let kind: Kind
    let occurredAt: String
    let publisher: TimelinePublisher?
    let voter: TimelinePublisher?
    let reposter: TimelinePublisher?
    let poll: PollPayload?
    let leaderText: String?
    let leaderPercentage: Int?
    let choice: String?
    let caption: String?
    let topicName: String?
    let totalVotes: Int?
    let story: TimelineStoryPayload?

    enum Kind: String, Decodable {
        case poll_published
        case survey_published
        case vote_cast
        case repost
        case poll_results
        case sector_trending
        case story
    }

    struct PollPayload: Decodable {
        let id: UUID
        let title: String
        let authorName: String?
        let authorAccountType: String?
        let topicName: String?
        let totalVotes: Int?
        let rewardPoints: Int?
        let coverStyle: String?
    }
}

struct TimelineResponse: Decodable {
    let items: [TimelineItem]
    let nextCutoff: String?
}

extension TrendXAPIClient {
    func timeline(
        filter: String,
        cursor: String?,
        topicId: UUID? = nil,
        accessToken: String
    ) async throws -> TimelineResponse {
        var query = ["filter=\(filter)"]
        if let cursor, let escaped = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            query.append("cursor=\(escaped)")
        }
        if let topicId {
            query.append("topic_id=\(topicId.uuidString)")
        }
        let path = "/me/timeline?" + query.joined(separator: "&")
        return try await get(path, accessToken: accessToken)
    }
}

// MARK: - View model

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var items: [TimelineItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var filter: String = "all"
    /// Only meaningful when `filter == "sectors"`. nil means "all
    /// sectors at once"; setting a UUID drills into a single topic.
    @Published var focusedTopicId: UUID?

    private var cursor: String?
    private let store: AppStore

    init(store: AppStore) { self.store = store }

    func reload() async {
        cursor = nil
        items = []
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading, let token = store.accessToken else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await store.apiClient.timeline(
                filter: filter,
                cursor: cursor,
                topicId: filter == "sectors" ? focusedTopicId : nil,
                accessToken: token
            )
            items.append(contentsOf: response.items)
            cursor = response.nextCutoff
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}

// MARK: - Screen

struct TimelineScreen: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: TimelineViewModel(store: store))
    }

    var body: some View {
        ZStack {
            TrendXTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerStrip
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Sector chips appear only on the "sectors" tab —
                    // give the user a way to drill into a single topic
                    // without leaving the radar.
                    if vm.filter == "sectors" {
                        sectorChipsStrip
                    }

                    if vm.items.isEmpty && !vm.isLoading {
                        emptyState(for: vm.filter)
                            .padding(.top, 28)
                    } else {
                        ForEach(vm.items) { item in
                            TimelineCard(item: item)
                                .padding(.horizontal, 20)
                        }

                        if vm.isLoading {
                            ProgressView().tint(TrendXTheme.primary).padding(20)
                        } else if vm.items.count >= 10 {
                            Button {
                                Task { await vm.loadMore() }
                            } label: {
                                Text("عرض المزيد")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundStyle(TrendXTheme.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(TrendXTheme.primary.opacity(0.10)))
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 12)
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
            .refreshable { await vm.reload() }
        }
        .navigationTitle("الرادار")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.reload() }
    }

    // MARK: - Header

    /// Compact eyebrow + tab strip. The eyebrow line — "نبض المملكة
    /// الحي" — gives the screen a clear identity so the user knows
    /// what they're looking at without scrolling.
    private var headerStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.aiIndigo)
                Text("نبض المملكة الحي")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.aiIndigo)
                Spacer(minLength: 0)
            }

            filterChips
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "اللحظة",   value: "all")
                chip(label: "من أتابع", value: "accounts")
                chip(label: "القطاعات", value: "sectors")
                chip(label: "النتائج",  value: "results")
            }
        }
    }

    private func chip(label: String, value: String) -> some View {
        let isSelected = vm.filter == value
        return Button {
            vm.filter = value
            // Drop any sector focus when switching tabs so the user
            // gets the broad view of the new tab they just opened.
            if value != "sectors" { vm.focusedTopicId = nil }
            Task { await vm.reload() }
        } label: {
            Text(label)
                .font(.system(size: 12.5, weight: .heavy))
                .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected
                                    ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                    : AnyShapeStyle(TrendXTheme.surface))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : TrendXTheme.outline, lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sector chips
    //
    // When the user lands on the "القطاعات" tab they get a chip strip
    // of every topic with an "كل القطاعات" entry at the start. Tapping
    // a chip narrows the feed via the backend's topic_id query.

    private var sectorChipsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                sectorChip(name: "كل القطاعات", icon: "circle.grid.3x3.fill", topicId: nil)
                ForEach(store.topics) { topic in
                    sectorChip(name: topic.name, icon: nil, emoji: topic.icon, topicId: topic.id)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func sectorChip(name: String, icon: String? = nil, emoji: String? = nil, topicId: UUID?) -> some View {
        let isSelected = vm.focusedTopicId == topicId
        return Button {
            vm.focusedTopicId = topicId
            Task { await vm.reload() }
        } label: {
            HStack(spacing: 5) {
                if let emoji {
                    Text(emoji).font(.system(size: 12))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .heavy))
                }
                Text(name)
                    .font(.system(size: 12, weight: .heavy))
            }
            .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected
                                ? AnyShapeStyle(TrendXTheme.aiIndigo)
                                : AnyShapeStyle(TrendXTheme.surface))
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : TrendXTheme.outline, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty states (per tab)
    //
    // Each tab has its own zero-content treatment because they mean
    // different things — "اللحظة" empty is genuinely unusual and
    // signals an API error, while "من أتابع" empty is the normal
    // starting state for any new user and should onboard them, not
    // apologize.

    @ViewBuilder
    private func emptyState(for filter: String) -> some View {
        switch filter {
        case "accounts":
            accountsEmptyState
        case "sectors":
            sectorsEmptyState
        case "results":
            resultsEmptyState
        default:
            liveEmptyState
        }
    }

    private var liveEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text("الرادار صامت الآن")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("اسحب للأسفل لإعادة التحديث — قد يكون اتصالك بطيئاً أو الخدمة قيد التحديث.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var accountsEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.crop.square.stack.fill")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(TrendXTheme.aiIndigo)
            Text("ابدأ ببناء شبكتك")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
            Text("تابع جهات حكومية وحسابات إعلامية وشخصيات نشطة — وستمتلئ هذي الشاشة بنبضهم اللحظي.")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Inline suggested-follows carousel — turns the empty
            // state from a dead end into a one-tap launchpad.
            SuggestedFollowsCarousel(store: store)
        }
        .padding(.top, 6)
    }

    private var sectorsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.group.fill")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(TrendXTheme.aiIndigo)
            Text("لا توجد استطلاعات نشطة في هذا القطاع")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("اختر قطاعاً آخر من الأعلى، أو عُد للحظة لترى ما يصوّت عليه السعوديون الآن.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var resultsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(TrendXTheme.success)
            Text("لا توجد نتائج هذا الأسبوع")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("ستظهر هنا الاستطلاعات التي حُسمت في آخر سبعة أيام مع المتصدر في كل واحدة.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - TimelineCard

private struct TimelineCard: View {
    let item: TimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            kindHeader
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(kindAccent.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: kindAccent.opacity(0.10), radius: 12, x: 0, y: 5)
        )
    }

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

    private var kindLabel: String {
        switch item.kind {
        case .poll_published:   return "استطلاع جديد"
        case .survey_published: return "استبيان جديد"
        case .vote_cast:        return "تصويت من متابعتك"
        case .repost:           return "إعادة نشر"
        case .poll_results:     return "نتائج استطلاع"
        case .sector_trending:  return "ترند في قطاعك"
        case .story:            return "قصّة جديدة"
        }
    }

    private var kindHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: kindIcon)
                .font(.system(size: 10, weight: .heavy))
            Text(kindLabel)
                .font(.system(size: 11, weight: .heavy))
            Spacer(minLength: 0)
            Text(relativeTime(item.occurredAt))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .foregroundStyle(kindAccent)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .poll_published, .survey_published:
            publishedBody
        case .vote_cast:
            voteBody
        case .repost:
            repostBody
        case .poll_results:
            resultsBody
        case .sector_trending:
            trendingBody
        case .story:
            storyBody
        }
    }

    private var repostBody: some View {
        HStack(alignment: .top, spacing: 12) {
            if let r = item.reposter {
                AccountAvatar(user: r.asUser, size: 40)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let r = item.reposter {
                    HStack(spacing: 4) {
                        Text(r.name)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                        AccountTypeBadge(type: r.asUser.accountType, isVerified: r.isVerified, size: 11)
                        Text("أعاد نشر")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }
                if let caption = item.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .lineLimit(2)
                }
                if let title = item.poll?.title {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(TrendXTheme.aiViolet.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(TrendXTheme.aiViolet.opacity(0.18), lineWidth: 0.8)
                                )
                        )
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var publishedBody: some View {
        HStack(alignment: .top, spacing: 12) {
            if let pub = item.publisher {
                AccountAvatar(user: pub.asUser, size: 44)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let pub = item.publisher {
                    AccountNameRow(user: pub.asUser, nameFont: .system(size: 13, weight: .heavy))
                }
                if let title = item.poll?.title {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                if let topic = item.poll?.topicName {
                    Text("في قطاع \(topic)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var voteBody: some View {
        HStack(alignment: .top, spacing: 12) {
            if let voter = item.voter {
                AccountAvatar(user: voter.asUser, size: 40)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let voter = item.voter {
                    HStack(spacing: 4) {
                        Text(voter.name)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                        AccountTypeBadge(type: voter.asUser.accountType, isVerified: voter.isVerified, size: 11)
                        Text("صوّت")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }
                if let title = item.poll?.title {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                }
                if let choice = item.choice {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 11, weight: .heavy))
                        Text("اختار: \(choice)")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .foregroundStyle(TrendXTheme.aiIndigo)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var resultsBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = item.poll?.title {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                    .lineLimit(2)
            }
            if let leader = item.leaderText, let pct = item.leaderPercentage {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(TrendXTheme.success)
                    Text("الفائز:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                    Text(leader)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                    Text("(\(pct)%)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(TrendXTheme.success)
                }
            }
        }
    }

    private var trendingBody: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(TrendXTheme.accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(TrendXTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                if let topic = item.topicName {
                    Text("اتجاه ساخن في \(topic)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                }
                if let votes = item.totalVotes {
                    Text("\(votes) صوت في آخر 24 ساعة")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var storyBody: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(
                        colors: [TrendXTheme.aiViolet, TrendXTheme.aiIndigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                Image(systemName: "book.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let title = item.story?.title {
                    Text(title)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                }
                if let pub = item.story?.publisher {
                    AccountNameRow(user: pub.asUser, nameFont: .system(size: 12, weight: .heavy))
                }
                if let count = item.story?.itemCount, count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 10, weight: .heavy))
                        Text("\(count) عنصر")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    .foregroundStyle(TrendXTheme.aiViolet)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func relativeTime(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: iso)
            ?? ISO8601DateFormatter.trendxInternet.date(from: iso) else { return "" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ar")
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
