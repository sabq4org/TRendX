//
//  WeeklyChallengeScreen.swift
//  TRENDX
//
//  Full-screen prediction challenge for the week. Reads /challenges/this-week,
//  posts to /challenges/{id}/predict. If the user has already predicted, the
//  view switches to a results card showing their guess and (once the
//  challenge is settled) their distance to the actual target.
//

import SwiftUI
import Combine

@MainActor
final class WeeklyChallengeViewModel: ObservableObject {
    @Published var challenge: TrendXWeeklyChallenge?
    @Published var prediction: Double = 50
    @Published var isLoading = true
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let client: TrendXAPIClient
    private let accessToken: String?

    init(client: TrendXAPIClient, accessToken: String?) {
        self.client = client
        self.accessToken = accessToken
    }

    func load() async {
        guard let token = accessToken else {
            isLoading = false
            errorMessage = "سجّل الدخول لعرض تحدّي الأسبوع"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await client.thisWeekChallenge(accessToken: token)
            challenge = result
            if let mine = result.myPrediction {
                prediction = Double(mine.predictedPct)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func submit() async {
        guard let challenge, let token = accessToken else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await client.predictChallenge(
                id: challenge.id,
                predictedPct: Int(prediction.rounded()),
                accessToken: token
            )
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct WeeklyChallengeScreen: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: WeeklyChallengeViewModel
    @Environment(\.dismiss) private var dismiss

    init(client: TrendXAPIClient, accessToken: String?) {
        _vm = StateObject(wrappedValue: WeeklyChallengeViewModel(
            client: client,
            accessToken: accessToken
        ))
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    if let challenge = vm.challenge {
                        heroBanner(challenge: challenge)
                        if let mine = challenge.myPrediction {
                            resultCard(challenge: challenge, mine: mine)
                        } else {
                            predictionPanel(challenge: challenge)
                        }
                        statsRow(challenge: challenge)
                    } else if vm.isLoading {
                        loadingState
                    } else {
                        errorState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("تحدّي هذا الأسبوع")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                TrendXTheme.background,
                TrendXTheme.aiIndigo.opacity(0.05),
                TrendXTheme.primary.opacity(0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Hero

    private func heroBanner(challenge: TrendXWeeklyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label("تحدّي الأسبوع", systemImage: "target")
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.18))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Spacer()

                Label("+\(challenge.rewardPoints)", systemImage: "star.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.18))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Text(challenge.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let description = challenge.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(remainingLabel(closesAt: challenge.closesAt))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.92))
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            TrendXTheme.aiIndigo,
                            TrendXTheme.aiViolet,
                            TrendXTheme.primary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: TrendXTheme.aiIndigo.opacity(0.35), radius: 22, x: 0, y: 12)
        )
    }

    // MARK: - Prediction panel (not yet predicted)

    private func predictionPanel(challenge: TrendXWeeklyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("توقّعك لـ \(challenge.metricLabel)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(TrendXTheme.secondaryInk)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(vm.prediction.rounded()))")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.primaryGradient)
                Text("%")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Slider(value: $vm.prediction, in: 0...100, step: 1)
                .tint(TrendXTheme.primary)
                .environment(\.layoutDirection, .leftToRight)

            HStack {
                Text("0%").font(.system(size: 10, weight: .semibold))
                Spacer()
                Text("50%").font(.system(size: 10, weight: .semibold))
                Spacer()
                Text("100%").font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(TrendXTheme.tertiaryInk)

            Button {
                Task { await vm.submit() }
            } label: {
                HStack(spacing: 8) {
                    if vm.isSubmitting {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    }
                    Text(vm.isSubmitting ? "جاري الإرسال…" : "أرسل توقّعي")
                        .font(.system(size: 15, weight: .heavy))
                    if !vm.isSubmitting {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(TrendXTheme.primaryGradient)
                )
                .shadow(color: TrendXTheme.primary.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(vm.isSubmitting)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TrendXTheme.surface)
        )
    }

    // MARK: - Result card (already predicted)

    private func resultCard(
        challenge: TrendXWeeklyChallenge,
        mine: TrendXMyChallengePrediction
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(TrendXTheme.success)
                Text("تم تسجيل توقّعك")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Spacer()
            }

            HStack(spacing: 16) {
                resultTile(
                    icon: "scope",
                    label: "توقّعك",
                    value: "\(mine.predictedPct)%",
                    tint: TrendXTheme.primary
                )
                if let target = challenge.targetPct {
                    resultTile(
                        icon: "flag.fill",
                        label: "النتيجة الفعلية",
                        value: "\(target)%",
                        tint: TrendXTheme.accent
                    )
                }
                if let distance = mine.distance {
                    resultTile(
                        icon: "ruler.fill",
                        label: "الفارق",
                        value: "\(distance)%",
                        tint: distance <= 5 ? TrendXTheme.success : TrendXTheme.aiViolet
                    )
                }
            }

            if let rank = mine.rank {
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TrendXTheme.accent)
                    Text("ترتيبك: #\(rank)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.ink)
                    Spacer()
                    Text("من \(challenge.totalPredictions) مشارك")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TrendXTheme.accent.opacity(0.10))
                )
            } else {
                Text("سنُعلن النتائج عند إغلاق التحدّي.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TrendXTheme.surface)
        )
    }

    private func resultTile(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }

    // MARK: - Stats

    private func statsRow(challenge: TrendXWeeklyChallenge) -> some View {
        HStack(spacing: 12) {
            statTile(
                icon: "person.2.fill",
                value: "\(challenge.totalPredictions)",
                label: "مشاركين"
            )
            statTile(
                icon: "calendar",
                value: weekShort(challenge.weekStart),
                label: "أسبوع"
            )
            statTile(
                icon: "bolt.fill",
                value: statusLabel(challenge.status),
                label: "الحالة"
            )
        }
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(TrendXTheme.primary)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TrendXTheme.surface)
        )
    }

    // MARK: - Empty / loading / error

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(TrendXTheme.primary)
            Text("جاري تحميل تحدّي الأسبوع…")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var errorState: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            Text(vm.errorMessage ?? "تعذّر تحميل التحدّي")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func remainingLabel(closesAt: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: closesAt)
            ?? ISO8601DateFormatter.trendxInternet.date(from: closesAt) else {
            return "ينتهي قريباً"
        }
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "أُغلق التحدّي" }
        let days = Int(interval / 86_400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86_400)) / 3_600)
        if days >= 1 {
            return "متبقي \(days) يوم و\(hours) ساعة"
        }
        return "متبقي \(hours) ساعة"
    }

    private func weekShort(_ weekStart: String) -> String {
        // Backend returns YYYY-MM-DD; show MM-DD for compactness.
        guard weekStart.count >= 10 else { return weekStart }
        return String(weekStart.dropFirst(5))
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "open": return "مفتوح"
        case "settled": return "أُعلن"
        case "closed": return "أُغلق"
        default: return status
        }
    }
}
