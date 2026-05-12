//
//  EventsScreen.swift
//  TRENDX
//
//  Phase 4 — public events organized by accounts (typically gov or
//  organizations). List view + detail with the Saudi map RSVP heatmap.
//

import SwiftUI
import Combine

// MARK: - Decoded shapes

struct TrendXEvent: Decodable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let bannerImage: String?
    let category: String?
    let status: String
    let startsAt: String
    let endsAt: String?
    let city: String?
    let venue: String?
    let lat: Double?
    let lng: Double?
    let rsvpCount: Int
    let attendingCount: Int
    let publisher: UserDTO?
    let viewerStatus: String?
    let cityBreakdown: [CityCount]?

    struct CityCount: Decodable, Identifiable, Hashable {
        let city: String
        let count: Int
        var id: String { city }
    }

    var publisherUser: TrendXUser? { publisher?.domain }
}

struct TrendXEventList: Decodable {
    let items: [TrendXEvent]
}

private struct RSVPBody: Encodable { let status: String }

extension TrendXAPIClient {
    func listEvents(
        status: String? = nil,
        publisherId: UUID? = nil,
        accessToken: String?
    ) async throws -> [TrendXEvent] {
        var queryItems: [String] = []
        if let status, !status.isEmpty { queryItems.append("status=\(status)") }
        if let publisherId { queryItems.append("publisher_id=\(publisherId.uuidString)") }
        var path = "/events"
        if !queryItems.isEmpty { path += "?" + queryItems.joined(separator: "&") }
        let list: TrendXEventList = try await get(path, accessToken: accessToken)
        return list.items
    }
    func eventDetail(id: UUID, accessToken: String?) async throws -> TrendXEvent {
        try await get("/events/\(id.uuidString)", accessToken: accessToken)
    }
    func rsvpEvent(id: UUID, status: String, accessToken: String) async throws -> TrendXEvent {
        try await post("/events/\(id.uuidString)/rsvp", accessToken: accessToken, body: RSVPBody(status: status))
    }
}

// MARK: - View model

@MainActor
final class EventsViewModel: ObservableObject {
    @Published private(set) var events: [TrendXEvent] = []
    @Published private(set) var isLoading = false
    @Published var statusFilter: String = "all" // all | upcoming | live | closed

    private let store: AppStore

    init(store: AppStore) { self.store = store }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        let list = (try? await store.apiClient.listEvents(
            status: statusFilter == "all" ? nil : statusFilter,
            accessToken: store.accessToken
        )) ?? []
        events = list
    }
}

// MARK: - List screen

struct EventsScreen: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: EventsViewModel
    @State private var selectedEvent: TrendXEvent?

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: EventsViewModel(store: store))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                filterChips
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if vm.events.isEmpty && !vm.isLoading {
                    emptyState.padding(.top, 40)
                } else {
                    ForEach(vm.events) { event in
                        Button { selectedEvent = event } label: {
                            EventListCard(event: event)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                    if vm.isLoading {
                        ProgressView().tint(TrendXTheme.primary).padding(20)
                    }
                }

                Spacer(minLength: 80)
            }
        }
        .navigationTitle("الفعاليات")
        .navigationBarTitleDisplayMode(.inline)
        .background(TrendXTheme.background.ignoresSafeArea())
        .refreshable { await vm.reload() }
        .task { await vm.reload() }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventDetailScreen(event: event, store: store)
                    .environmentObject(store)
            }
            .trendxRTL()
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "الكل", value: "all")
                filterChip(label: "قريباً", value: "upcoming")
                filterChip(label: "اليوم", value: "live")
                filterChip(label: "منتهية", value: "closed")
            }
        }
    }

    private func filterChip(label: String, value: String) -> some View {
        let isSelected = vm.statusFilter == value
        return Button {
            vm.statusFilter = value
            Task { await vm.reload() }
        } label: {
            Text(label)
                .font(.system(size: 12.5, weight: .heavy))
                .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected
                                    ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                    : AnyShapeStyle(TrendXTheme.surface))
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : TrendXTheme.outline, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text("لا فعاليات حالياً")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
            Text("تابع الجهات الرسمية وستظهر فعالياتها هنا.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - List card

private struct EventListCard: View {
    let event: TrendXEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                statusBadge
                Spacer(minLength: 0)
                if let cat = event.category, !cat.isEmpty {
                    Text(cat)
                        .font(.system(size: 10, weight: .heavy))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(TrendXTheme.aiViolet.opacity(0.12)))
                        .foregroundStyle(TrendXTheme.aiViolet)
                }
            }

            Text(event.title)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let pub = event.publisherUser {
                AccountNameRow(user: pub, nameFont: .system(size: 12, weight: .heavy))
            }

            HStack(spacing: 12) {
                Label(formatStart(event.startsAt), systemImage: "calendar")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.secondaryInk)

                if let city = event.city {
                    Label(city, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }

                Spacer()

                Label("\(event.attendingCount)", systemImage: "person.2.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(TrendXTheme.outline, lineWidth: 0.8)
                )
                .shadow(color: TrendXTheme.shadow, radius: 8, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch event.status {
        case "live":
            HStack(spacing: 5) {
                Circle().fill(.red).frame(width: 6, height: 6)
                Text("مباشر الآن")
                    .font(.system(size: 10, weight: .heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(.red))
        case "closed":
            Text("منتهية")
                .font(.system(size: 10, weight: .heavy))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(TrendXTheme.tertiaryInk.opacity(0.18)))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        default:
            Text("قريباً")
                .font(.system(size: 10, weight: .heavy))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(TrendXTheme.primary.opacity(0.12)))
                .foregroundStyle(TrendXTheme.primary)
        }
    }

    private func formatStart(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: iso)
            ?? ISO8601DateFormatter.trendxInternet.date(from: iso) else { return iso }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "EEE، d MMM"
        return formatter.string(from: date)
    }
}
