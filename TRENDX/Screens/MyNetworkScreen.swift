//
//  MyNetworkScreen.swift
//  TRENDX
//
//  "شبكتي" — two-tab view of the accounts the user follows + the
//  accounts following them. Surfaces the same row-level identity
//  (avatar + name + badge + handle + bio) as the suggested-follows
//  carousel, with a tap-to-open profile + inline follow toggle.
//

import SwiftUI
import Combine

@MainActor
final class MyNetworkViewModel: ObservableObject {
    enum Tab: String, CaseIterable {
        case following
        case followers

        var label: String {
            switch self {
            case .following: return "يتابعهم"
            case .followers: return "متابعونك"
            }
        }
    }

    @Published var tab: Tab = .following
    @Published private(set) var following: [TrendXUser] = []
    @Published private(set) var followers: [TrendXUser] = []
    @Published private(set) var isLoading = false

    private let store: AppStore
    init(store: AppStore) { self.store = store }

    func load() async {
        guard let token = store.accessToken else { return }
        isLoading = true
        defer { isLoading = false }
        async let fol = (try? await store.apiClient.myFollowing(accessToken: token)) ?? []
        async let frs = (try? await store.apiClient.myFollowers(accessToken: token)) ?? []
        let (f, r) = await (fol, frs)
        following = f
        followers = r
    }

    /// Optimistic unfollow from the following list.
    func unfollow(_ user: TrendXUser) async {
        following.removeAll { $0.id == user.id }
        _ = await store.unfollow(userId: user.id)
    }

    func follow(_ user: TrendXUser) async {
        _ = await store.follow(userId: user.id)
        await load()
    }
}

struct MyNetworkScreen: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: MyNetworkViewModel
    @State private var selectedUser: TrendXUser?

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: MyNetworkViewModel(store: store))
    }

    var body: some View {
        ZStack {
            TrendXTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                tabBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        let users = (vm.tab == .following) ? vm.following : vm.followers
                        if users.isEmpty && !vm.isLoading {
                            emptyState
                                .padding(.top, 36)
                        } else {
                            ForEach(users) { user in
                                NetworkRow(
                                    user: user,
                                    mode: vm.tab,
                                    onTap: { selectedUser = user },
                                    onPrimaryAction: {
                                        Task {
                                            if vm.tab == .following {
                                                await vm.unfollow(user)
                                            } else if !user.viewerFollows {
                                                await vm.follow(user)
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                            if vm.isLoading {
                                ProgressView().tint(TrendXTheme.primary).padding(20)
                            }
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 6)
                }
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("شبكتي")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .navigationDestination(item: $selectedUser) { user in
            PublicProfileScreen(user: user, loadFromBackend: true)
                .environmentObject(store)
                .trendxRTL()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MyNetworkViewModel.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        vm.tab = tab
                    }
                } label: {
                    let count = tab == .following ? vm.following.count : vm.followers.count
                    let isSelected = vm.tab == tab
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Text(tab.label)
                                .font(.system(size: 13.5, weight: .heavy))
                            Text("\(count)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(isSelected
                                                           ? TrendXTheme.primary.opacity(0.12)
                                                           : TrendXTheme.softFill))
                        }
                        .foregroundStyle(isSelected ? TrendXTheme.primary : TrendXTheme.tertiaryInk)

                        Rectangle()
                            .fill(isSelected ? TrendXTheme.primary : .clear)
                            .frame(height: 2.5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: vm.tab == .following ? "person.crop.circle.badge.plus" : "person.2.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text(vm.tab == .following ? "لم تبدأ المتابعة بعد" : "لا متابعون بعد")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text(vm.tab == .following
                 ? "افتح الرادار أو الصفحة الرئيسية وستلقى اقتراحات لحسابات ووزارات تستحق المتابعة."
                 : "كلما شاركت رأيك وأصبح حسابك أنشط، زاد من يتابعك من المهتمين بقطاعك.")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 38)
        }
    }
}

// MARK: - Row

private struct NetworkRow: View {
    let user: TrendXUser
    let mode: MyNetworkViewModel.Tab
    let onTap: () -> Void
    let onPrimaryAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    AccountAvatar(user: user, size: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(user.name)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(TrendXTheme.ink)
                                .lineLimit(1)
                            AccountTypeBadge(type: user.accountType, isVerified: user.isVerified, size: 12)
                        }
                        if let handle = user.handle, !handle.isEmpty {
                            Text("@\(handle)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                        }
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(TrendXTheme.secondaryInk)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            actionButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(TrendXTheme.outline.opacity(0.5), lineWidth: 0.6)
                )
        )
    }

    @ViewBuilder
    private var actionButton: some View {
        if mode == .following {
            Button(action: onPrimaryAction) {
                Text("إلغاء")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.error)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(TrendXTheme.error.opacity(0.08)))
            }
            .buttonStyle(.plain)
        } else if !user.viewerFollows {
            Button(action: onPrimaryAction) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .heavy))
                    Text("متابعة")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(TrendXTheme.primaryGradient))
            }
            .buttonStyle(.plain)
        } else {
            Text("متابَع")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(TrendXTheme.primary)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(TrendXTheme.primary.opacity(0.10)))
        }
    }
}
