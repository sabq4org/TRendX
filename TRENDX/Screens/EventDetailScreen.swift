//
//  EventDetailScreen.swift
//  TRENDX
//
//  Event detail with the live Saudi map heatmap, RSVP actions, and
//  the countdown. The map is a SwiftUI Canvas drawing — every city in
//  `cityBreakdown` is plotted at its approximate normalized coordinate
//  on a stylized outline of the Kingdom, with dot size scaled to the
//  attendee count.
//

import SwiftUI

struct EventDetailScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let event: TrendXEvent
    @State private var current: TrendXEvent
    @State private var isBusy = false

    init(event: TrendXEvent, store: AppStore) {
        self.event = event
        _current = State(initialValue: event)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                banner
                titleBlock.padding(.horizontal, 20)
                if current.status == "live" { liveCountdown.padding(.horizontal, 20) }
                rsvpRow.padding(.horizontal, 20)
                SaudiMapHeatmap(breakdown: current.cityBreakdown ?? [],
                                accent: current.publisherUser?.accountType.tint ?? TrendXTheme.primary)
                    .padding(.horizontal, 20)
                cityList.padding(.horizontal, 20)
                Spacer(minLength: 40)
            }
        }
        .background(TrendXTheme.background.ignoresSafeArea())
        .navigationTitle("الفعالية")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
        }
        .task { await refresh() }
    }

    // MARK: - Banner

    private var banner: some View {
        ZStack(alignment: .topTrailing) {
            if let url = current.bannerImage.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: bannerFallback
                    }
                }
            } else {
                bannerFallback
            }

            if current.status == "live" {
                HStack(spacing: 5) {
                    Circle().fill(.white).frame(width: 7, height: 7)
                    Text("مباشر الآن")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(.red))
                .padding(14)
            }
        }
        .frame(height: 200)
        .clipped()
    }

    private var bannerFallback: some View {
        let accent = current.publisherUser?.accountType.tint ?? TrendXTheme.aiIndigo
        return ZStack {
            LinearGradient(
                colors: [accent, accent.opacity(0.7), TrendXTheme.aiViolet],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Canvas { ctx, size in
                let spacing: CGFloat = 30
                var path = Path()
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + spacing / 2))
                    y += spacing
                }
                ctx.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)
            }
            VStack(spacing: 6) {
                Image(systemName: current.category == "sports" ? "sportscourt.fill"
                    : (current.category == "cultural" ? "theatermasks.fill"
                       : "calendar.badge.checkmark"))
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(.white)
                Text(current.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(current.title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            if let pub = current.publisherUser {
                AccountNameRow(user: pub, nameFont: .system(size: 13, weight: .heavy))
            }
            if let desc = current.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .lineSpacing(4)
            }

            HStack(spacing: 12) {
                Label(formatDate(current.startsAt), systemImage: "calendar")
                    .font(.system(size: 12, weight: .heavy))
                if let city = current.city {
                    Label(city + (current.venue.map { " · \($0)" } ?? ""), systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .heavy))
                }
            }
            .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var liveCountdown: some View {
        HStack(spacing: 10) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
            Text("نشطة الآن — \(current.attendingCount) مشارك")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [.red, TrendXTheme.accent],
                    startPoint: .leading, endPoint: .trailing
                ))
                .shadow(color: .red.opacity(0.3), radius: 14, x: 0, y: 5)
        )
    }

    private var rsvpRow: some View {
        HStack(spacing: 8) {
            rsvpButton(status: "attending", label: "سأحضر", icon: "checkmark.circle.fill", color: TrendXTheme.success)
            rsvpButton(status: "maybe", label: "ربما", icon: "questionmark.circle.fill", color: TrendXTheme.warning)
            rsvpButton(status: "not_attending", label: "لن أحضر", icon: "xmark.circle.fill", color: TrendXTheme.tertiaryInk)
        }
    }

    private func rsvpButton(status: String, label: String, icon: String, color: Color) -> some View {
        let isActive = current.viewerStatus == status
        return Button {
            Task { await submitRSVP(status) }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                Text(label)
                    .font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(isActive ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.10)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(color.opacity(isActive ? 0 : 0.22), lineWidth: 1)
                    )
            )
            .shadow(color: isActive ? color.opacity(0.32) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var cityList: some View {
        Group {
            if let breakdown = current.cityBreakdown, !breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("من أين يأتي الحضور؟")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                    VStack(spacing: 8) {
                        ForEach(breakdown.prefix(6), id: \.city) { row in
                            HStack {
                                Text(row.city)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundStyle(TrendXTheme.ink)
                                Spacer()
                                Text("\(row.count)")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(TrendXTheme.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TrendXTheme.paleFill)
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Network

    private func refresh() async {
        if let fresh = try? await store.apiClient.eventDetail(id: current.id, accessToken: store.accessToken) {
            current = fresh
        }
    }

    private func submitRSVP(_ status: String) async {
        guard let token = store.accessToken else {
            store.showLoginSheet = true
            return
        }
        isBusy = true
        defer { isBusy = false }
        if let updated = try? await store.apiClient.rsvpEvent(
            id: current.id, status: status, accessToken: token
        ) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                current = updated
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func formatDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: iso)
            ?? ISO8601DateFormatter.trendxInternet.date(from: iso) else { return iso }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Saudi map (Canvas-rendered)

/// A stylized outline of Saudi Arabia with one dot per city in the
/// breakdown. Coordinates are normalized (0..1) within the map's
/// bounding box and were sampled from the cities' real lat/lng.
struct SaudiMapHeatmap: View {
    let breakdown: [TrendXEvent.CityCount]
    let accent: Color

    /// Approximate normalized positions inside the map frame. Origin
    /// is top-left, y grows downward — matches SwiftUI Canvas coords.
    private static let coordinates: [String: CGPoint] = [
        "الرياض":            CGPoint(x: 0.58, y: 0.52),
        "جدة":               CGPoint(x: 0.20, y: 0.55),
        "مكة":               CGPoint(x: 0.24, y: 0.58),
        "مكة المكرمة":       CGPoint(x: 0.24, y: 0.58),
        "المدينة":           CGPoint(x: 0.26, y: 0.40),
        "المدينة المنورة":   CGPoint(x: 0.26, y: 0.40),
        "الدمام":            CGPoint(x: 0.88, y: 0.40),
        "الخبر":             CGPoint(x: 0.90, y: 0.42),
        "الظهران":           CGPoint(x: 0.89, y: 0.41),
        "الطائف":            CGPoint(x: 0.32, y: 0.60),
        "أبها":              CGPoint(x: 0.32, y: 0.82),
        "تبوك":              CGPoint(x: 0.16, y: 0.22),
        "بريدة":             CGPoint(x: 0.50, y: 0.38),
        "حائل":              CGPoint(x: 0.42, y: 0.30),
        "الجبيل":            CGPoint(x: 0.86, y: 0.36),
        "ينبع":              CGPoint(x: 0.18, y: 0.42),
        "نجران":             CGPoint(x: 0.52, y: 0.88),
        "الباحة":            CGPoint(x: 0.30, y: 0.74),
        "جازان":             CGPoint(x: 0.28, y: 0.90),
        "عرعر":              CGPoint(x: 0.48, y: 0.18),
        "سكاكا":             CGPoint(x: 0.36, y: 0.18),
    ]

    private var maxCount: Int {
        max(1, breakdown.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(accent)
                Text("خريطة الحضور")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Spacer()
                Text("\(breakdown.reduce(0) { $0 + $1.count }) مشارك")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(accent)
            }

            GeometryReader { geo in
                ZStack {
                    Canvas { ctx, size in
                        // Stylized country outline — rough polygonal trace of KSA.
                        let pts: [(Double, Double)] = [
                            (0.12, 0.18), (0.20, 0.10), (0.34, 0.08),
                            (0.50, 0.10), (0.58, 0.16), (0.66, 0.18),
                            (0.74, 0.22), (0.82, 0.28), (0.92, 0.36),
                            (0.96, 0.44), (0.94, 0.52), (0.88, 0.60),
                            (0.78, 0.68), (0.66, 0.80), (0.56, 0.90),
                            (0.42, 0.94), (0.30, 0.92), (0.20, 0.84),
                            (0.14, 0.72), (0.10, 0.58), (0.08, 0.46),
                            (0.06, 0.32), (0.12, 0.18),
                        ]
                        var path = Path()
                        if let first = pts.first {
                            path.move(to: CGPoint(x: first.0 * size.width, y: first.1 * size.height))
                            for (x, y) in pts.dropFirst() {
                                path.addLine(to: CGPoint(x: x * size.width, y: y * size.height))
                            }
                            path.closeSubpath()
                        }
                        ctx.fill(path, with: .color(accent.opacity(0.06)))
                        ctx.stroke(path, with: .color(accent.opacity(0.4)),
                                   style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                    }

                    ForEach(breakdown) { row in
                        if let pt = Self.coordinates[row.city] {
                            cityDot(row: row, point: pt, size: geo.size)
                        }
                    }
                }
            }
            .frame(height: 240)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TrendXTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(accent.opacity(0.18), lineWidth: 0.8)
                    )
            )
        }
    }

    private func cityDot(row: TrendXEvent.CityCount, point: CGPoint, size: CGSize) -> some View {
        let ratio = Double(row.count) / Double(maxCount)
        let radius = 10.0 + ratio * 22.0
        return ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .shadow(color: accent.opacity(0.4), radius: 6, x: 0, y: 2)
            if ratio > 0.5 {
                Text(row.city)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(accent))
                    .offset(y: radius + 8)
            }
        }
        .position(x: point.x * size.width, y: point.y * size.height)
    }
}
