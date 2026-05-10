//
//  WelcomeAfterSignUpScreen.swift
//  TRENDX
//
//  Full-screen "preparing your TRENDX" experience that bridges the
//  smart sign-up flow and the main tab interface. Three short stages
//  (welcome → AI is tuning your dashboard → ready) animate in over a
//  few seconds, then the user can tap "ابدأ التجربة" to dismiss.
//
//  Design intent: keep the AI personality from the sign-up flow alive
//  for one more moment so the transition feels intentional, not
//  abrupt. Tone matches `SmartSignUpFlow` (sparkles avatar, soft
//  spring animations, primaryGradient).
//

import SwiftUI

struct WelcomeAfterSignUpScreen: View {
    @EnvironmentObject private var store: AppStore
    let onContinue: () -> Void

    @State private var stage: Stage = .greeting
    @State private var orbScale: CGFloat = 0.85
    @State private var orbGlow: Double = 0.4

    private enum Stage: Int, CaseIterable {
        case greeting       // "أهلاً بك في TRENDX"
        case tuning         // "أُهيّئ بوصلتك الآن…"
        case ready          // "كلّ شيء جاهز"
    }

    var body: some View {
        ZStack {
            TrendXAmbientBackground()

            VStack(spacing: 32) {
                Spacer(minLength: 60)

                // Animated AI orb
                aiOrb

                // Headline + sub copy that swap with stage
                VStack(spacing: 14) {
                    Text(headline)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(TrendXTheme.ink)
                        .multilineTextAlignment(.center)
                        .id("headline-\(stage.rawValue)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)))

                    Text(subline)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                        .id("subline-\(stage.rawValue)")
                        .transition(.opacity)
                }
                .padding(.horizontal, 24)

                if stage == .ready {
                    insightsRow
                        .padding(.horizontal, 26)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Stage progress dots
                stageDots

                // Continue button (only on .ready)
                if stage == .ready {
                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("ابدأ التجربة")
                                .font(.system(size: 16, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TrendXTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: TrendXTheme.primary.opacity(0.4), radius: 14, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 26)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Reserve the same vertical space so the layout
                    // doesn't jump when the button finally appears.
                    Color.clear.frame(height: 56).padding(.horizontal, 26)
                }

                Spacer(minLength: 30)
            }
        }
        .trendxRTL()
        .onAppear { runAnimation() }
    }

    // MARK: - Stages

    private var headline: String {
        let firstName = store.currentUser.name.split(separator: " ").first.map(String.init)
            ?? store.currentUser.name
        switch stage {
        case .greeting: return "أهلاً \(firstName) ✨"
        case .tuning:   return "أُهيّئ بوصلتك الآن…"
        case .ready:    return "كلّ شيء جاهز"
        }
    }

    private var subline: String {
        switch stage {
        case .greeting:
            return "انضممت لأكثر مجتمع رأي ذكاء في المنطقة — رأيك من اليوم محسوب."
        case .tuning:
            return "أربط اهتماماتك ببيانات اليوم… أبحث عن أوّل اتجاه يستحقّ مشاركتك فيه."
        case .ready:
            return "ابدأ بنبض اليوم، أو استكشف الاتجاهات على لوحتك الشخصية."
        }
    }

    // MARK: - Components

    private var aiOrb: some View {
        ZStack {
            // Outer glow halo
            Circle()
                .fill(TrendXTheme.primary.opacity(orbGlow * 0.25))
                .frame(width: 220, height: 220)
                .blur(radius: 28)
            Circle()
                .fill(TrendXTheme.aiViolet.opacity(orbGlow * 0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: 18, y: -10)

            // Main orb
            Circle()
                .fill(LinearGradient(
                    colors: [TrendXTheme.aiIndigo, TrendXTheme.primary, TrendXTheme.aiViolet],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 132, height: 132)
                .scaleEffect(orbScale)
                .shadow(color: TrendXTheme.primary.opacity(0.55), radius: 28, x: 0, y: 12)
                .overlay(
                    Image(systemName: stage == .ready ? "checkmark" : "sparkles")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.35), radius: 8)
                )
                .animation(.spring(response: 0.7, dampingFraction: 0.55), value: stage)
        }
    }

    private var stageDots: some View {
        HStack(spacing: 8) {
            ForEach(Stage.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= stage.rawValue ? TrendXTheme.primary : TrendXTheme.tertiaryInk.opacity(0.25))
                    .frame(width: s == stage ? 24 : 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: stage)
            }
        }
    }

    private var insightsRow: some View {
        HStack(spacing: 10) {
            insightChip(icon: "waveform.path.ecg", title: "نبض اليوم", tint: TrendXTheme.primary)
            insightChip(icon: "chart.line.uptrend.xyaxis", title: "مؤشّرك", tint: TrendXTheme.aiViolet)
            insightChip(icon: "person.2.fill", title: "مجتمعك", tint: TrendXTheme.accent)
        }
    }

    private func insightChip(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(TrendXTheme.surface)
        .cornerRadius(14)
        .shadow(color: TrendXTheme.shadow, radius: 10, x: 0, y: 3)
    }

    // MARK: - Animation choreography

    private func runAnimation() {
        // Pulse the orb continuously.
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            orbScale = 1.05
            orbGlow = 1.0
        }

        // Step through the stages.
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    stage = .tuning
                }
            }
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    stage = .ready
                }
            }
        }
    }
}

#Preview {
    WelcomeAfterSignUpScreen(onContinue: {})
        .environmentObject(AppStore())
}
