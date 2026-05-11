//
//  DailyBonusCard.swift
//  TRENDX
//
//  Hero card on Home that surfaces the daily-bonus claim flow. Hidden
//  when the user already claimed today (server-side check) — the
//  refresh path on the parent keeps it in sync after a redemption or
//  background return.
//

import SwiftUI
import Combine

struct TrendXDailyBonus: Decodable {
    let canClaim: Bool
    let currentStreak: Int
    let nextReward: Int
    let lastClaimedAt: String?
}

private struct TrendXDailyBonusClaim: Decodable {
    let awarded: Int
    let newStreak: Int
}

extension TrendXAPIClient {
    func dailyBonus(accessToken: String) async throws -> TrendXDailyBonus {
        try await get("/me/daily-bonus", accessToken: accessToken)
    }

    func claimDailyBonus(accessToken: String) async throws -> Int {
        let result: TrendXDailyBonusClaim = try await post(
            "/me/daily-bonus/claim",
            accessToken: accessToken,
            body: EmptyBody()
        )
        return result.awarded
    }
}

private struct EmptyBody: Encodable {}

@MainActor
final class DailyBonusViewModel: ObservableObject {
    @Published private(set) var bonus: TrendXDailyBonus?
    @Published private(set) var claimedAmount: Int?
    @Published private(set) var isClaiming = false

    private let store: AppStore

    init(store: AppStore) { self.store = store }

    func load() async {
        guard let token = store.accessToken else { return }
        bonus = try? await store.apiClient.dailyBonus(accessToken: token)
    }

    func claim() async {
        guard let token = store.accessToken else { return }
        isClaiming = true
        defer { isClaiming = false }
        do {
            let awarded = try await store.apiClient.claimDailyBonus(accessToken: token)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                claimedAmount = awarded
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await load()
            await store.refreshBootstrap()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

struct DailyBonusCard: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var vm: DailyBonusViewModel

    init(store: AppStore) {
        _vm = StateObject(wrappedValue: DailyBonusViewModel(store: store))
    }

    var body: some View {
        Group {
            if let bonus = vm.bonus, bonus.canClaim {
                claimableCard(bonus: bonus)
            } else if let amount = vm.claimedAmount {
                justClaimedCard(amount: amount)
            }
            // Hidden when not claimable and no recent claim — keeps Home clean.
        }
        .task { await vm.load() }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: vm.bonus?.canClaim)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: vm.claimedAmount)
    }

    // MARK: - States

    private func claimableCard(bonus: TrendXDailyBonus) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.20))
                    .frame(width: 54, height: 54)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("هديتك اليومية بانتظارك")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                    if bonus.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("سلسلة \(bonus.currentStreak)")
                                .font(.system(size: 10, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.22)))
                    }
                }

                Text("+\(bonus.nextReward) نقطة فوراً، استلمها قبل منتصف الليل")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button {
                Task { await vm.claim() }
            } label: {
                HStack(spacing: 5) {
                    if vm.isClaiming {
                        ProgressView().tint(TrendXTheme.aiIndigo).scaleEffect(0.7)
                    }
                    Text(vm.isClaiming ? "..." : "استلم")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.aiIndigo)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(.white))
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(vm.isClaiming)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [TrendXTheme.aiIndigo, TrendXTheme.aiViolet, TrendXTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: TrendXTheme.aiIndigo.opacity(0.30), radius: 20, x: 0, y: 10)
        )
    }

    private func justClaimedCard(amount: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.success.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(TrendXTheme.success)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("حصلت على +\(amount) نقطة 🎉")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Text("نراك بكرة لاستلام الهدية القادمة — السلسلة تتضاعف.")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(TrendXTheme.success.opacity(0.22), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
