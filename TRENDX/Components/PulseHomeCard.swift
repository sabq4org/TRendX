//
//  PulseHomeCard.swift
//  TRENDX
//
//  Compact "نبض اليوم" card for the Home feed and Account screen.
//  Tappable wrapper navigates to PulseTodayScreen for the full flow.
//

import SwiftUI

struct PulseHomeCard: View {
    @EnvironmentObject private var store: AppStore
    @State private var pulse: TrendXDailyPulse?
    @State private var streak: TrendXUserStreak?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius)
                .fill(TrendXTheme.surface)

            // Subtle ambient gradient
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [TrendXTheme.primary.opacity(0.08), TrendXTheme.aiViolet.opacity(0.04)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            HStack(spacing: 14) {
                // Trailing chevron (RTL — leading in screen sense)
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        if let s = streak, s.currentStreak > 0 {
                            Label("سلسلة \(s.currentStreak)", systemImage: "flame.fill")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(TrendXTheme.accent.opacity(0.12))
                                .foregroundStyle(TrendXTheme.accent)
                                .cornerRadius(99)
                        }
                        if pulse?.userResponded == true {
                            Text("صوّتت ✓")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(TrendXTheme.success.opacity(0.12))
                                .foregroundStyle(TrendXTheme.success)
                                .cornerRadius(99)
                        }
                        Text("نبض اليوم")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1.4)
                            .foregroundStyle(TrendXTheme.primary)
                    }
                    Text(pulse?.question ?? "بانتظار نبض اليوم…")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    HStack(spacing: 4) {
                        Text("\(pulse?.totalResponses ?? 0) مشارك")
                            .monospacedDigit()
                        Text("·")
                        Text("+\(pulse?.rewardPoints ?? 40) نقطة")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                }

                ZStack {
                    Circle()
                        .fill(TrendXTheme.primaryGradient)
                        .frame(width: 52, height: 52)
                        .shadow(color: TrendXTheme.primary.opacity(0.4), radius: 12, x: 0, y: 4)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 4)
        .task { await load() }
    }

    private func load() async {
        guard let token = store.accessToken else { return }
        async let p = try? store.apiClient.pulseToday(accessToken: token)
        async let s = try? store.apiClient.myStreak(accessToken: token)
        let (pulseV, streakV) = await (p, s)
        await MainActor.run {
            self.pulse = pulseV
            self.streak = streakV
        }
    }
}

struct TrendXIndexHomeCard: View {
    @EnvironmentObject private var store: AppStore
    @State private var index: TrendXIndex?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius)
                .fill(TrendXTheme.surface)
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.aiViolet)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("مؤشّر TRENDX")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(TrendXTheme.aiViolet)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("/100")
                            .font(.system(size: 12))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Text("\(index?.composite ?? 50)")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(TrendXTheme.aiViolet)
                            .monospacedDigit()
                    }
                    Text("نبض الرأي العام · يحدّث يوميّاً")
                        .font(.system(size: 11))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [TrendXTheme.aiIndigo, TrendXTheme.aiViolet, TrendXTheme.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 4)
        .task { await load() }
    }

    private func load() async {
        let v = try? await store.apiClient.trendxIndex()
        await MainActor.run { self.index = v }
    }
}
