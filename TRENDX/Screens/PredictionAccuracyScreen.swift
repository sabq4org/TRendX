//
//  PredictionAccuracyScreen.swift
//  TRENDX
//
//  Predictive Accuracy stats + leaderboard. Same shape as the dashboard's
//  /accuracy page so the user sees identical rankings on every surface.
//

import SwiftUI

struct PredictionAccuracyScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var stats: TrendXUserAccuracy?
    @State private var board: TrendXAccuracyLeaderboard?
    @State private var loading = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                if loading {
                    ProgressView().padding(40)
                } else {
                    if let stats {
                        statsCard(stats: stats).padding(.horizontal, 20)
                    }
                    if let board {
                        leaderboardCard(items: board.items).padding(.horizontal, 20)
                    }
                    explainerCard.padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 120)
        }
        .trendxScreenBackground()
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PREDICTIVE ACCURACY")
                .font(.system(size: 13, weight: .heavy))
                .tracking(2)
                .foregroundStyle(TrendXTheme.aiViolet)
            Text("دقّة التنبّؤ")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
            Text("حدسك في الرأي العامّ — قابل للقياس.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func statsCard(stats: TrendXUserAccuracy) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            statCell(label: "متوسّط الدقّة", value: "\(stats.averageAccuracy)/100", tint: TrendXTheme.primary)
            statCell(label: "أفضل دقّة", value: "\(stats.bestAccuracy)/100", tint: TrendXTheme.aiViolet)
            statCell(label: "إجمالي التنبّؤات", value: "\(stats.predictions)", tint: TrendXTheme.ink)
            statCell(label: "ترتيبك المئوي", value: stats.rankPercentile > 0 ? "أعلى من \(stats.rankPercentile)%" : "—", tint: TrendXTheme.accent)
        }
    }

    private func statCell(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text(value)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
    }

    private func leaderboardCard(items: [TrendXAccuracyLeaderItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("لوحة الشرف")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(TrendXTheme.accent)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, it in
                    HStack {
                        Text("\(it.averageAccuracy)/100")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                            .monospacedDigit()
                        Spacer()
                        Text(it.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TrendXTheme.ink)
                        ZStack {
                            Circle()
                                .fill(TrendXTheme.primary.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Text(it.avatarInitial)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(TrendXTheme.primary)
                        }
                        Text("\(idx + 1)")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 28, height: 28)
                            .background(idx == 0 ? TrendXTheme.accent : idx == 1 ? TrendXTheme.tertiaryInk.opacity(0.6) : idx == 2 ? TrendXTheme.accent.opacity(0.4) : Color.clear)
                            .foregroundStyle(idx < 3 ? .white : TrendXTheme.tertiaryInk)
                            .clipShape(Circle())
                    }
                    .padding(.vertical, 10)
                    if idx < items.count - 1 {
                        Divider().background(TrendXTheme.outline)
                    }
                }
            }
        }
        .padding(16)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
    }

    private var explainerCard: some View {
        Text("الدقّة = 100 - |تخمينك - النسبة الحقيقيّة|. مثال: تنبّأت بـ 60٪ والنتيجة 67٪ → دقّتك 93/100.")
            .font(.system(size: 12))
            .foregroundStyle(TrendXTheme.secondaryInk)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(TrendXTheme.aiViolet.opacity(0.05))
            .cornerRadius(TrendXTheme.cardRadius)
    }

    @MainActor
    private func load() async {
        guard let token = store.accessToken else { loading = false; return }
        loading = true
        async let s = try? store.apiClient.myAccuracy(accessToken: token)
        async let b = try? store.apiClient.accuracyLeaderboard(limit: 25, accessToken: token)
        let (sV, bV) = await (s, b)
        self.stats = sV
        self.board = bV
        self.loading = false
    }
}

// MARK: - Account entry cards

struct OpinionDNAEntryCard: View {
    @EnvironmentObject private var store: AppStore
    @State private var dna: TrendXOpinionDNA?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius)
                .fill(LinearGradient(
                    colors: [TrendXTheme.aiViolet.opacity(0.10), TrendXTheme.aiCyan.opacity(0.05)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                ))
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [TrendXTheme.aiIndigo, TrendXTheme.aiViolet, TrendXTheme.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPINION DNA")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(TrendXTheme.aiViolet)
                    Text(dna?.archetype.title ?? "اكتشف هويّتك في الرأي")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                    Text(dna?.archetype.blurb ?? "شارك في 3 استطلاعات لنبني هويّتك الفكريّة.")
                        .font(.system(size: 11))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.aiViolet)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 4)
        .task { await load() }
    }

    private func load() async {
        guard let token = store.accessToken else { return }
        let v = try? await store.apiClient.myOpinionDNA(accessToken: token)
        await MainActor.run { self.dna = v }
    }
}

struct AccuracyEntryCard: View {
    @EnvironmentObject private var store: AppStore
    @State private var stats: TrendXUserAccuracy?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius)
                .fill(TrendXTheme.surface)
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [TrendXTheme.accent, TrendXTheme.accentDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Image(systemName: "target")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACCURACY")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(TrendXTheme.accent)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(stats?.averageAccuracy ?? 0)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(TrendXTheme.accent)
                            .monospacedDigit()
                        Text("/100")
                            .font(.system(size: 12))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    Text("أعلى من \(stats?.rankPercentile ?? 0)% من المتنبّئين")
                        .font(.system(size: 11))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.accent)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 4)
        .task { await load() }
    }

    private func load() async {
        guard let token = store.accessToken else { return }
        let v = try? await store.apiClient.myAccuracy(accessToken: token)
        await MainActor.run { self.stats = v }
    }
}
