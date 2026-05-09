//
//  GiftsScreen.swift
//  TRENDX
//

import SwiftUI

// MARK: - Main Screen

struct GiftsScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var selectedCategory: GiftCategory = .all
    @State private var sortMode: GiftSortMode = .ai
    @State private var selectedGift: Gift?
    @State private var lastRedemption: Redemption?
    @State private var showHistory = false

    /// A realistic minimum-for-redemption tier used to drive the progress bar.
    /// Picks the cheapest gift in the catalog (or a sensible default).
    private var minimumForRedeem: Int {
        store.gifts.map(\.pointsRequired).min() ?? 120
    }

    private var filteredGifts: [Gift] {
        var gifts = store.gifts

        if !searchText.isEmpty {
            gifts = gifts.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.brandName.localizedStandardContains(searchText)
            }
        }

        if let category = selectedCategory.rawValue {
            gifts = gifts.filter { $0.category == category }
        }

        switch sortMode {
        case .ai:
            return gifts.sorted { aiScore($0) > aiScore($1) }
        case .affordable:
            return gifts.sorted { lhs, rhs in
                let lhsAffordable = store.currentUser.points >= lhs.pointsRequired
                let rhsAffordable = store.currentUser.points >= rhs.pointsRequired
                if lhsAffordable != rhsAffordable {
                    return lhsAffordable && !rhsAffordable
                }
                return lhs.pointsRequired < rhs.pointsRequired
            }
        case .value:
            return gifts.sorted {
                ($0.valueInRiyal / Double($0.pointsRequired)) > ($1.valueInRiyal / Double($1.pointsRequired))
            }
        }
    }

    /// AI-picked gifts: prioritize ones the user can almost afford
    /// (between 70% and 110% of current points) and best value-per-point.
    private var aiPicks: [Gift] {
        let points = store.currentUser.points
        let withAffinity: [(gift: Gift, score: Double)] = store.gifts.map { gift in
            let ratio = points > 0 ? Double(gift.pointsRequired) / Double(points) : 2.0
            let closeness: Double = {
                if ratio <= 1.0 { return 1.0 - (1.0 - ratio) * 0.3 }  // can afford
                if ratio <= 1.5 { return 1.2 - (ratio - 1.0) }         // almost
                return max(0.1, 1.0 / ratio)                            // far
            }()
            let valueRatio = gift.valueInRiyal / max(Double(gift.pointsRequired), 1)
            return (gift, closeness * 0.7 + valueRatio * 3.0)
        }
        return withAffinity
            .sorted { $0.score > $1.score }
            .prefix(6)
            .map(\.gift)
    }

    private func aiScore(_ gift: Gift) -> Double {
        let points = store.currentUser.points
        let ratio = points > 0 ? Double(gift.pointsRequired) / Double(points) : 2.0
        let closeness = ratio <= 1.0 ? 1.0 : max(0.1, 1.4 - ratio)
        let valueRatio = gift.valueInRiyal / max(Double(gift.pointsRequired), 1)
        return closeness * 0.7 + valueRatio * 3.0
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                GiftsHeader {
                    showHistory = true
                }
                    .padding(.horizontal, 20)

                WalletHero(
                    points: store.currentUser.points,
                    coins: store.currentUser.coins,
                    minimumForRedeem: minimumForRedeem
                )
                .padding(.horizontal, 20)

                AIPicksStrip(gifts: aiPicks, userPoints: store.currentUser.points) { gift in
                    selectedGift = gift
                }

                GiftsSearchBar(text: $searchText)
                    .padding(.horizontal, 20)

                GiftCategoriesStrip(selected: $selectedCategory)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("كتالوج الهدايا")
                            .font(.trendxSubheadline())
                            .foregroundStyle(TrendXTheme.ink)
                        Text("\(filteredGifts.count) هدية متاحة")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }

                    Spacer()

                    Menu {
                        Button("ترتيب TRENDX AI") { sortMode = .ai }
                        Button("المتاح أولاً") { sortMode = .affordable }
                        Button("الأعلى قيمة") { sortMode = .value }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .semibold))
                            Text("ترتيب")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(TrendXTheme.surface))
                        .overlay(
                            Capsule()
                                .stroke(TrendXTheme.outline, lineWidth: 0.8)
                        )
                    }
                }
                .padding(.horizontal, 20)

                if filteredGifts.isEmpty {
                    EmptyStateView(
                        icon: "gift",
                        title: "لا توجد هدايا مطابقة",
                        message: "جرّب فئة أخرى أو ابحث باسم علامة تجارية."
                    )
                    .padding(.top, 20)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ], spacing: 16) {
                        ForEach(filteredGifts) { gift in
                            GiftCard(gift: gift, userPoints: store.currentUser.points) {
                                selectedGift = gift
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 140)
        }
        .trendxScreenBackground()
        .confirmationDialog(
            "استبدال الهدية",
            isPresented: Binding(
                get: { selectedGift != nil },
                set: { if !$0 { selectedGift = nil } }
            ),
            presenting: selectedGift
        ) { gift in
            if store.currentUser.points >= gift.pointsRequired {
                Button("استبدال \(gift.name)") {
                    lastRedemption = store.redeemGift(gift)
                    selectedGift = nil
                }
            }
            Button("إلغاء", role: .cancel) {
                selectedGift = nil
            }
        } message: { gift in
            Text(store.giftRecommendationReason(for: gift))
        }
        .alert("تم الاستبدال", isPresented: Binding(get: { lastRedemption != nil }, set: { if !$0 { lastRedemption = nil } })) {
            Button("حسناً") {
                lastRedemption = nil
            }
        } message: {
            if let lastRedemption {
                Text("كود الهدية: \(lastRedemption.code)")
            }
        }
        .sheet(isPresented: $showHistory) {
            RedemptionHistoryView(redemptions: store.redemptions)
                .trendxRTL()
        }
    }
}

private enum GiftSortMode {
    case ai, affordable, value
}

// MARK: - Header

private struct GiftsHeader: View {
    let onHistoryTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("الهدايا")
                    .font(.trendxHeadline())
                    .foregroundStyle(TrendXTheme.ink)

                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(TrendXTheme.aiIndigo)
                    Text("هدايا مختارة لك بواسطة TRENDX AI")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }

            Spacer()

            Button(action: onHistoryTap) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(TrendXTheme.surface))
                    .overlay(Circle().stroke(TrendXTheme.outline, lineWidth: 0.8))
            }
        }
    }
}

// MARK: - Wallet Hero

struct WalletHero: View {
    let points: Int
    let coins: Double
    let minimumForRedeem: Int

    private var progress: Double {
        guard minimumForRedeem > 0 else { return 0 }
        return min(Double(points) / Double(minimumForRedeem), 1.0)
    }

    private var remaining: Int {
        max(minimumForRedeem - points, 0)
    }

    private var isReady: Bool { remaining == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("محفظة TRENDX")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(TrendXTheme.secondaryInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(TrendXTheme.softFill))

                Spacer()

                Text(isReady ? "جاهز للاستبدال" : "يبقى \(remaining) نقطة")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isReady ? TrendXTheme.success : TrendXTheme.secondaryInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isReady ? TrendXTheme.success.opacity(0.10) : TrendXTheme.paleFill)
                    )
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(points)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                    .monospacedDigit()
                Text("نقطة")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }

            Text("يعادل \(String(format: "%.2f", coins)) ريال")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(TrendXTheme.tertiaryInk)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("التقدّم نحو أقرب استبدال")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.accentDeep)
                        .monospacedDigit()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(TrendXTheme.softFill)
                            .frame(height: 8)

                        Capsule()
                            .fill(TrendXTheme.accent)
                            .frame(width: max(geo.size.width * progress, 10), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(TrendXTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TrendXTheme.outline, lineWidth: 0.8)
        )
        .shadow(color: TrendXTheme.shadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - AI Picks Strip

struct AIPicksStrip: View {
    let gifts: [Gift]
    let userPoints: Int
    var onSelect: (Gift) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(TrendXTheme.aiIndigo.opacity(0.10))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(TrendXTheme.aiIndigo)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("مختارة لك")
                            .font(.trendxSubheadline())
                            .foregroundStyle(TrendXTheme.ink)
                        Text("TRENDX AI يختار الأقرب لرصيدك")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gifts) { gift in
                        AIPickCard(gift: gift, userPoints: userPoints) {
                            onSelect(gift)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct AIPickCard: View {
    let gift: Gift
    let userPoints: Int
    let onTap: () -> Void

    private var canAfford: Bool { userPoints >= gift.pointsRequired }
    private var tint: Color { gift.categoryTint }
    private var tintLight: Color { gift.categoryTintLight }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint, tintLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 74, height: 74)

                        Text(gift.brandMonogram)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    if canAfford {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(TrendXTheme.success)
                            .background(
                                Circle()
                                    .fill(TrendXTheme.surface)
                                    .frame(width: 18, height: 18)
                            )
                            .offset(x: 4, y: -4)
                    }
                }

                VStack(spacing: 4) {
                    Text(gift.brandName)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(1)

                    Text(gift.category)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(TrendXTheme.accent)
                    Text("\(gift.pointsRequired)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(TrendXTheme.accentDeep)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(TrendXTheme.accent.opacity(0.12)))
            }
            .frame(width: 136)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 0.8)
            )
            .shadow(color: TrendXTheme.shadow, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Bar

private struct GiftsSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)

            TextField("ابحث عن علامة أو هدية…", text: $text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(TrendXTheme.ink)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TrendXTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TrendXTheme.outline, lineWidth: 0.8)
        )
    }
}

// MARK: - Categories

enum GiftCategory: Hashable, CaseIterable {
    case all, sweets, cafes, cars, jewellery, shopping

    var label: String {
        switch self {
        case .all:       return "الكل"
        case .sweets:    return "حلويات"
        case .cafes:     return "مقاهي"
        case .cars:      return "سيارات"
        case .jewellery: return "Jewellery"
        case .shopping:  return "تسوق"
        }
    }

    /// Nil for "all" — everything else maps to the stored category string.
    var rawValue: String? {
        switch self {
        case .all:       return nil
        case .sweets:    return "حلويات"
        case .cafes:     return "مقاهي"
        case .cars:      return "سيارات"
        case .jewellery: return "Jewellery"
        case .shopping:  return "تسوق"
        }
    }

    var icon: String {
        switch self {
        case .all:       return "square.grid.2x2.fill"
        case .sweets:    return "birthday.cake.fill"
        case .cafes:     return "cup.and.saucer.fill"
        case .cars:      return "car.fill"
        case .jewellery: return "diamond.fill"
        case .shopping:  return "bag.fill"
        }
    }

    var tint: Color {
        switch self {
        case .all:       return TrendXTheme.primary
        case .sweets:    return Color(red: 0.92, green: 0.44, blue: 0.60)
        case .cafes:     return Color(red: 0.56, green: 0.36, blue: 0.24)
        case .cars:      return Color(red: 0.28, green: 0.40, blue: 0.58)
        case .jewellery: return Color(red: 0.78, green: 0.58, blue: 0.22)
        case .shopping:  return Color(red: 0.18, green: 0.62, blue: 0.58)
        }
    }
}

private struct GiftCategoriesStrip: View {
    @Binding var selected: GiftCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GiftCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selected == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selected = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct CategoryChip: View {
    let category: GiftCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(category.label)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(isSelected ? category.tint : TrendXTheme.secondaryInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(isSelected ? category.tint.opacity(0.10) : TrendXTheme.surface)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? category.tint.opacity(0.18) : TrendXTheme.outline, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RedemptionHistoryView: View {
    let redemptions: [Redemption]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if redemptions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "لا يوجد سجل بعد",
                        message: "استبدل أول هدية وسيظهر كودها هنا للرجوع إليه لاحقاً."
                    )
                    .padding(20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(redemptions) { redemption in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(redemption.brandName)
                                            .font(.trendxBodyBold())
                                            .foregroundStyle(TrendXTheme.ink)
                                        Text(redemption.giftName)
                                            .font(.trendxSmall())
                                            .foregroundStyle(TrendXTheme.tertiaryInk)
                                    }

                                    Spacer()

                                    Text(redemption.code)
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundStyle(TrendXTheme.primaryDeep)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(TrendXTheme.accent.opacity(0.14)))
                                }

                                HStack {
                                    Label("\(redemption.pointsSpent) نقطة", systemImage: "star.circle.fill")
                                    Spacer()
                                    Text("\(Int(redemption.valueInRiyal)) ر.س")
                                }
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.secondaryInk)
                            }
                            .surfaceCard(padding: 16, radius: 18)
                        }
                    }
                    .padding(20)
                }
            }
            .trendxScreenBackground()
            .navigationTitle("سجل الاستبدال")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GiftsScreen()
        .environmentObject(AppStore())
        .trendxRTL()
}
