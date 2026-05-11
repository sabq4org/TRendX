//
//  NotificationsInboxScreen.swift
//  TRENDX
//
//  In-app notification inbox. Pulls /me/notifications from the API,
//  renders a smart card per item (close-to-gift, pulse-pending, weekly
//  challenge, expiring poll in followed topic, fresh rewards). Read
//  state is tracked locally in UserDefaults until we add a server
//  backing table.
//

import SwiftUI
import Combine

struct TrendXNotification: Decodable, Identifiable {
    let id: String
    let kind: String
    let title: String
    let body: String
    let icon: String
    let ctaLabel: String?
    let ctaRoute: String?
    let occurredAt: String
    let refId: String?
}

private struct TrendXNotificationsList: Decodable {
    let items: [TrendXNotification]
}

extension TrendXAPIClient {
    func notifications(accessToken: String) async throws -> [TrendXNotification] {
        let list: TrendXNotificationsList = try await get("/me/notifications", accessToken: accessToken)
        return list.items
    }
}

/// Lightweight ObservableObject the HomeScreen owns to keep the bell-badge
/// unread count up to date without pushing a full view model into the
/// shared header. Reads the same `/me/notifications` payload as the inbox
/// but persists only the read-set in UserDefaults.
@MainActor
final class NotificationsCounter: ObservableObject {
    @Published private(set) var unreadCount: Int = 0

    private let readKey = "trendx_notifications_read_v1"

    func refresh(store: AppStore) async {
        guard let token = store.accessToken else { return }
        let read = Set(UserDefaults.standard.array(forKey: readKey) as? [String] ?? [])
        let items = (try? await store.apiClient.notifications(accessToken: token)) ?? []
        unreadCount = items.filter { !read.contains($0.id) }.count
    }
}

@MainActor
final class NotificationsInboxViewModel: ObservableObject {
    @Published private(set) var notifications: [TrendXNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var readIds: Set<String> = []

    private let store: AppStore
    private let readKey = "trendx_notifications_read_v1"

    init(store: AppStore) {
        self.store = store
        if let data = UserDefaults.standard.array(forKey: readKey) as? [String] {
            readIds = Set(data)
        }
    }

    var unreadCount: Int {
        notifications.filter { !readIds.contains($0.id) }.count
    }

    func load() async {
        guard let token = store.accessToken else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            notifications = try await store.apiClient.notifications(accessToken: token)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func markRead(_ id: String) {
        guard !readIds.contains(id) else { return }
        readIds.insert(id)
        UserDefaults.standard.set(Array(readIds), forKey: readKey)
    }

    func markAllRead() {
        readIds.formUnion(notifications.map(\.id))
        UserDefaults.standard.set(Array(readIds), forKey: readKey)
    }
}

struct NotificationsInboxScreen: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: NotificationsInboxViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: NotificationsInboxViewModel(store: store))
    }

    var body: some View {
        ZStack {
            TrendXTheme.background.ignoresSafeArea()

            if vm.isLoading && vm.notifications.isEmpty {
                ProgressView().tint(TrendXTheme.primary)
            } else if vm.notifications.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(vm.notifications) { notification in
                            NotificationCard(
                                notification: notification,
                                isRead: vm.readIds.contains(notification.id),
                                onTap: { handleTap(notification) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("الإشعارات")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !vm.notifications.isEmpty && vm.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("تعليم الكل كمقروء") {
                        vm.markAllRead()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.primary)
                }
            }
        }
        .task { await vm.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text("لا توجد إشعارات الآن")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("شارك في استطلاع أو افتح تحدّي الأسبوع وسنعلمك بالتطورات.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func handleTap(_ notification: TrendXNotification) {
        vm.markRead(notification.id)
        guard let route = notification.ctaRoute else { return }
        // Simple route mapping — push to the right tab; deep links into
        // specific polls would need a router but for now the tab switch
        // covers the demo flow.
        switch route {
        case "gifts":
            store.selectedTab = .gifts
            dismiss()
        case "pulse", "challenge":
            store.selectedTab = .home
            dismiss()
        case let r where r.hasPrefix("poll:"):
            store.selectedTab = .polls
            dismiss()
        default:
            break
        }
    }
}

private struct NotificationCard: View {
    let notification: TrendXNotification
    let isRead: Bool
    let onTap: () -> Void

    private var kindTint: Color {
        switch notification.kind {
        case "close_to_gift": return TrendXTheme.accent
        case "pulse_pending": return TrendXTheme.primary
        case "challenge_open": return TrendXTheme.aiIndigo
        case "expiring_poll": return TrendXTheme.warning
        case "reward_earned": return TrendXTheme.success
        default: return TrendXTheme.primary
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(kindTint.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: notification.icon)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(kindTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(notification.title)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        if !isRead {
                            Circle()
                                .fill(kindTint)
                                .frame(width: 7, height: 7)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(notification.body)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(relativeTime(notification.occurredAt))
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        if let cta = notification.ctaLabel {
                            Text("·")
                                .font(.system(size: 10.5, weight: .heavy))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                            Text(cta)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(kindTint)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TrendXTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isRead ? TrendXTheme.outline.opacity(0.4)
                                       : kindTint.opacity(0.22),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isRead ? .clear : kindTint.opacity(0.08),
                        radius: 8, x: 0, y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func relativeTime(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: iso)
            ?? ISO8601DateFormatter.trendxInternet.date(from: iso) else {
            return ""
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
