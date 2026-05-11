//
//  SuggestedFollowsCarousel.swift
//  TRENDX
//
//  Horizontal carousel of "هل تريد متابعة هذه الحسابات؟" surfaced on
//  Home (and reusable after sign-up). Cards are tappable to follow
//  directly from the strip; the name is tappable to open the full
//  profile. Hides itself completely when there are no suggestions.
//

import SwiftUI
import Combine

@MainActor
final class SuggestedFollowsViewModel: ObservableObject {
    @Published private(set) var users: [TrendXUser] = []
    @Published private(set) var isLoading = false
    @Published var followingIds: Set<UUID> = []

    private let store: AppStore

    init(store: AppStore) { self.store = store }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        users = await store.loadSuggestedFollows()
    }

    func follow(_ user: TrendXUser) async {
        // Optimistic UI — flip immediately, then call the server.
        followingIds.insert(user.id)
        let success = await store.follow(userId: user.id)
        if !success { followingIds.remove(user.id) }
    }
}

struct SuggestedFollowsCarousel: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: SuggestedFollowsViewModel
    @State private var selectedUser: TrendXUser?

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: SuggestedFollowsViewModel(store: store))
    }

    var body: some View {
        Group {
            if vm.users.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vm.users) { user in
                                SuggestedFollowCard(
                                    user: user,
                                    isFollowing: vm.followingIds.contains(user.id),
                                    onFollow: { Task { await vm.follow(user) } },
                                    onTap: { selectedUser = user }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .sheet(item: $selectedUser) { user in
                    NavigationStack {
                        PublicProfileScreen(user: user, loadFromBackend: true)
                            .environmentObject(store)
                    }
                    .trendxRTL()
                }
            }
        }
        .task { await vm.load() }
    }

    private var sectionHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(TrendXTheme.aiIndigo.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: "person.2.crop.square.stack.fill")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.aiIndigo)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("ابدأ بمتابعتهم")
                        .font(.trendxSubheadline())
                        .foregroundStyle(TrendXTheme.ink)
                    Text("جهات رسمية وحسابات نشطة في اهتماماتك")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

private struct SuggestedFollowCard: View {
    let user: TrendXUser
    let isFollowing: Bool
    let onFollow: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                VStack(spacing: 10) {
                    AccountAvatar(user: user, size: 64)
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Text(user.name)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(TrendXTheme.ink)
                                .lineLimit(1)
                            AccountTypeBadge(type: user.accountType, isVerified: user.isVerified, size: 11)
                        }
                        if let handle = user.handle, !handle.isEmpty {
                            Text("@\(handle)")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                                .lineLimit(1)
                        }
                    }
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: onFollow) {
                HStack(spacing: 4) {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 10, weight: .heavy))
                    Text(isFollowing ? "متابَع" : "متابعة")
                        .font(.system(size: 11.5, weight: .heavy))
                }
                .foregroundStyle(isFollowing ? user.accountType.tint : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(
                        isFollowing
                        ? AnyShapeStyle(user.accountType.wash)
                        : (user.accountType == .government
                           ? AnyShapeStyle(TrendXTheme.saudiGreenGradient)
                           : (user.accountType == .organization
                              ? AnyShapeStyle(TrendXTheme.orgGoldGradient)
                              : AnyShapeStyle(TrendXTheme.primaryGradient)))
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(isFollowing)
        }
        .frame(width: 148)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(user.accountType.tint.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: TrendXTheme.shadow, radius: 8, x: 0, y: 4)
        )
    }
}
