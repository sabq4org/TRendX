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
    let poll: PollPayload?
    let leaderText: String?
    let leaderPercentage: Int?
    let choice: String?
    let topicName: String?
    let totalVotes: Int?
    let story: TimelineStoryPayload?

    enum Kind: String, Decodable {
        case poll_published
        case survey_published
        case vote_cast
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
    func timeline(filter: String, cursor: String?, accessToken: String) async throws -> TimelineResponse {
        var path = "/me/timeline?filter=\(filter)"
        if let cursor, let escaped = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "&cursor=\(escaped)"
        }
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
                    filterChips
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    if vm.items.isEmpty && !vm.isLoading {
                        emptyState
                            .padding(.top, 40)
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

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "الكل",        value: "all")
                chip(label: "الحسابات",    value: "accounts")
                chip(label: "القطاعات",    value: "sectors")
                chip(label: "النتائج",     value: "results")
            }
        }
    }

    private func chip(label: String, value: String) -> some View {
        let isSelected = vm.filter == value
        return Button {
            vm.filter = value
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text("رادارك هادئ الآن")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("تابع وزارات وحسابات نشطة وستمتلئ هذه الشاشة بنبض اليوم.")
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
        case .poll_results:
            resultsBody
        case .sector_trending:
            trendingBody
        case .story:
            storyBody
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
