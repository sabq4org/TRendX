//
//  PulseTodayScreen.swift
//  TRENDX
//
//  Daily Pulse — one national question per day. Identical contract on
//  iOS and Web (the platform is one product, the surfaces are different).
//  Streak-aware, with the optional prediction game sliders.
//

import SwiftUI

struct PulseTodayScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var pulse: TrendXDailyPulse?
    @State private var streak: TrendXUserStreak?
    @State private var yesterday: TrendXDailyPulse?
    @State private var picked: Int?
    @State private var predictedPct: Double = 50
    @State private var isSubmitting = false
    @State private var lastResponse: TrendXPulseResponse?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                if let pulse {
                    statRow

                    pulseCard(pulse: pulse)
                        .padding(.horizontal, 20)

                    if let yesterday {
                        yesterdayCard(yesterday: yesterday)
                            .padding(.horizontal, 20)
                    }
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(TrendXTheme.error)
                        .padding()
                } else {
                    ProgressView()
                        .padding(40)
                }
            }
            .padding(.bottom, 120)
        }
        .trendxScreenBackground()
        .task {
            await loadAll()
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("نبض اليوم")
                .font(.system(size: 13, weight: .heavy))
                .tracking(2)
                .foregroundStyle(TrendXTheme.primary)
            Text("نبض السعودية اليوم")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
            Text("سؤال جديد كل يوم — صوّت، تنبّأ، اكتشف.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "flame.fill",
                tint: TrendXTheme.accent,
                value: "\(streak?.currentStreak ?? 0)",
                label: "سلسلة المشاركة"
            )
            statCard(
                icon: "person.2.fill",
                tint: TrendXTheme.primary,
                value: "\(pulse?.totalResponses ?? 0)",
                label: "المشاركون اليوم"
            )
            statCard(
                icon: "sparkles",
                tint: TrendXTheme.aiViolet,
                value: "+\(pulse?.rewardPoints ?? 0)",
                label: "نقاط المشاركة"
            )
        }
        .padding(.horizontal, 20)
    }

    private func statCard(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
    }

    private func pulseCard(pulse: TrendXDailyPulse) -> some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                Text("سؤال اليوم")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(TrendXTheme.primary)
                Spacer()
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(TrendXTheme.primary)
            }

            Text(pulse.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(TrendXTheme.ink)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if pulse.userResponded == true || lastResponse != nil {
                resultsList(pulse: lastResponse?.pulse ?? pulse)
                if let r = lastResponse {
                    rewardBanner(r: r)
                }
            } else {
                optionsList(pulse: pulse)

                predictionSlider

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Spacer()
                        Text(isSubmitting ? "جارٍ الإرسال…" : "أرسل صوتي")
                            .font(.system(size: 15, weight: .heavy))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(picked == nil ? TrendXTheme.outline : Color.clear)
                    .background(picked == nil ? AnyView(EmptyView()) : AnyView(TrendXTheme.primaryGradient))
                    .foregroundStyle(.white)
                    .cornerRadius(TrendXTheme.buttonRadius)
                }
                .disabled(picked == nil || isSubmitting)
            }
        }
        .padding(20)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 16, x: 0, y: 6)
    }

    private func optionsList(pulse: TrendXDailyPulse) -> some View {
        VStack(spacing: 10) {
            ForEach(pulse.options) { o in
                Button {
                    picked = o.index
                } label: {
                    HStack {
                        Text(o.text)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TrendXTheme.ink)
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(picked == o.index ? TrendXTheme.primary : TrendXTheme.outline, lineWidth: 2)
                                .frame(width: 22, height: 22)
                            if picked == o.index {
                                Circle()
                                    .fill(TrendXTheme.primary)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(picked == o.index ? TrendXTheme.primary.opacity(0.06) : TrendXTheme.paleFill.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: TrendXTheme.chipRadius)
                            .stroke(picked == o.index ? TrendXTheme.primary : TrendXTheme.outline, lineWidth: 1)
                    )
                    .cornerRadius(TrendXTheme.chipRadius)
                }
            }
        }
    }

    private var predictionSlider: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("لعبة التنبّؤ — اختياري")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(TrendXTheme.aiViolet)
                Spacer()
            }
            Text("كم نسبة من تتوقّع أن يختار الخيار الأكثر تصويتاً؟")
                .font(.system(size: 12))
                .foregroundStyle(TrendXTheme.secondaryInk)
            HStack {
                Text("\(Int(predictedPct))%")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(TrendXTheme.aiViolet)
                    .monospacedDigit()
                    .frame(width: 64, alignment: .leading)
                Slider(value: $predictedPct, in: 0...100, step: 1)
                    .tint(TrendXTheme.aiViolet)
            }
        }
        .padding(14)
        .background(TrendXTheme.aiViolet.opacity(0.06))
        .cornerRadius(TrendXTheme.chipRadius)
    }

    private func resultsList(pulse: TrendXDailyPulse) -> some View {
        VStack(spacing: 10) {
            ForEach(pulse.options) { o in
                let mine = (lastResponse != nil ? picked : pulse.userChoice) == o.index
                let leading = pulse.options.allSatisfy { $0.votes <= o.votes }
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("\(Int(o.percentage))%  \(Text("(\(o.votes))").font(.system(size: 11)).foregroundStyle(TrendXTheme.tertiaryInk))")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                            .monospacedDigit()
                        Spacer()
                        if mine {
                            Text("صوتك")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(TrendXTheme.primary.opacity(0.12))
                                .foregroundStyle(TrendXTheme.primary)
                                .cornerRadius(4)
                        }
                        Text(o.text)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(mine ? TrendXTheme.primary : TrendXTheme.ink)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 99)
                                .fill(TrendXTheme.paleFill)
                            RoundedRectangle(cornerRadius: 99)
                                .fill(mine ? AnyShapeStyle(TrendXTheme.primaryGradient) : (leading ? AnyShapeStyle(TrendXTheme.accent) : AnyShapeStyle(TrendXTheme.outline)))
                                .frame(width: geo.size.width * CGFloat(o.percentage) / 100)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func rewardBanner(r: TrendXPulseResponse) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("شُكراً لمشاركتك! +\(r.reward) نقطة")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(TrendXTheme.success)
            HStack(spacing: 4) {
                Text("سلسلة \(r.streak.currentStreak) يوم")
                if r.streak.isPersonalBest == true {
                    Text("· رقم قياسي شخصي 🏆")
                }
                if let ps = r.predictionScore {
                    Text("· دقّتك \(ps)/100")
                        .foregroundStyle(TrendXTheme.aiViolet)
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(14)
        .background(TrendXTheme.success.opacity(0.08))
        .cornerRadius(TrendXTheme.chipRadius)
    }

    private func yesterdayCard(yesterday: TrendXDailyPulse) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Spacer()
                Text("نبض الأمس")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(TrendXTheme.aiViolet)
            }
            Text(yesterday.question)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(TrendXTheme.ink)
            if let summary = yesterday.aiSummary {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(TrendXTheme.aiViolet.opacity(0.06))
        .cornerRadius(TrendXTheme.cardRadius)
    }

    // MARK: - Actions

    private func loadAll() async {
        guard let token = store.accessToken else { return }
        async let pulseTask = try? store.apiClient.pulseToday(accessToken: token)
        async let streakTask = try? store.apiClient.myStreak(accessToken: token)
        async let yestTask = try? store.apiClient.pulseYesterday(accessToken: token)
        let p = await pulseTask
        let s = await streakTask
        let y = await yestTask
        await MainActor.run {
            self.pulse = p
            self.streak = s
            self.yesterday = y?.pulse
        }
    }

    private func submit() async {
        guard let token = store.accessToken, let picked else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let r = try await store.apiClient.pulseRespond(
                optionIndex: picked,
                predictedPct: Int(predictedPct),
                accessToken: token
            )
            await MainActor.run {
                self.lastResponse = r
                self.streak = r.streak
                self.pulse = r.pulse
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
