//
//  WeeklyChallengeHomeCard.swift
//  TRENDX
//
//  Compact card surfaced on the Home feed. Reads the same /challenges/this-week
//  payload the full screen uses, but renders only the call-to-action.
//

import SwiftUI

struct WeeklyChallengeHomeCard: View {
    @EnvironmentObject private var store: AppStore
    @State private var challenge: TrendXWeeklyChallenge?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TrendXTheme.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            TrendXTheme.aiIndigo,
                            TrendXTheme.aiViolet
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .shadow(color: TrendXTheme.aiIndigo.opacity(0.25), radius: 18, x: 0, y: 10)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "target")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("تحدّي الأسبوع")
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.white.opacity(0.20))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        if challenge?.myPrediction == nil {
                            Text("جديد")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(.white)
                                .foregroundStyle(TrendXTheme.aiIndigo)
                                .clipShape(Capsule())
                        } else {
                            Text("شاركت ✓")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(.white.opacity(0.20))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(challenge?.question ?? "توقّع نبض الأسبوع واربح نقاطك")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(challenge?.totalPredictions ?? 0) مشارك هذا الأسبوع")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.82))
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .frame(minHeight: 96)
        .task { await loadIfNeeded() }
    }

    private func loadIfNeeded() async {
        guard challenge == nil, let token = store.accessToken else { return }
        challenge = try? await store.apiClient.thisWeekChallenge(accessToken: token)
    }
}
