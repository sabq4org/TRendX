//
//  GiftRedemptionSuccessSheet.swift
//  TRENDX
//
//  Celebratory sheet shown after a successful gift redemption. Replaces
//  the system .alert with a brand-quality moment: confetti, the gift code
//  in a large copy-friendly capsule, and the user's new balance.
//

import SwiftUI
import UIKit

struct GiftRedemptionSuccessSheet: View {
    let redemption: Redemption
    let remainingPoints: Int
    let onDismiss: () -> Void

    @State private var didCopy = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TrendXTheme.background,
                    TrendXTheme.accent.opacity(0.08),
                    TrendXTheme.primary.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ConfettiOverlay()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    successSeal
                        .padding(.top, 14)

                    headlineBlock

                    codeCapsule

                    balanceBlock

                    actionButtons

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 22)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 14)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
                animateContent = true
            }
        }
    }

    // MARK: - Seal

    private var successSeal: some View {
        ZStack {
            Circle()
                .fill(TrendXTheme.success.opacity(0.12))
                .frame(width: 132, height: 132)
            Circle()
                .stroke(TrendXTheme.success.opacity(0.30), lineWidth: 2)
                .frame(width: 110, height: 110)
            Circle()
                .fill(TrendXTheme.success)
                .frame(width: 88, height: 88)
                .shadow(color: TrendXTheme.success.opacity(0.50), radius: 22, x: 0, y: 12)
            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(.white)
        }
        .scaleEffect(animateContent ? 1 : 0.6)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateContent)
    }

    // MARK: - Headline

    private var headlineBlock: some View {
        VStack(spacing: 8) {
            Text("استبدلت بنجاح ✨")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)

            Text("\(redemption.brandName) — \(redemption.giftName)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Code capsule

    private var codeCapsule: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("كود الهدية", systemImage: "barcode.viewfinder")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Spacer()
                Text("بقيمة \(Int(redemption.valueInRiyal)) ر.س")
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(TrendXTheme.accent.opacity(0.12)))
                    .foregroundStyle(TrendXTheme.accentDeep)
            }

            HStack(spacing: 12) {
                Text(redemption.code)
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundStyle(TrendXTheme.primaryDeep)
                    .kerning(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(TrendXTheme.primary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                            )
                            .foregroundStyle(TrendXTheme.primary.opacity(0.35))
                    )

                Button {
                    UIPasteboard.general.string = redemption.code
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        didCopy = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            didCopy = false
                        }
                    }
                } label: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(didCopy ? AnyShapeStyle(TrendXTheme.success)
                                              : AnyShapeStyle(TrendXTheme.primaryGradient))
                        )
                        .shadow(color: (didCopy ? TrendXTheme.success : TrendXTheme.primary).opacity(0.35),
                                radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }

            if didCopy {
                Text("نُسخ إلى الحافظة")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.success)
                    .transition(.opacity)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(TrendXTheme.surface)
                .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Balance block

    private var balanceBlock: some View {
        HStack(spacing: 12) {
            balanceTile(
                icon: "minus.circle.fill",
                value: "-\(redemption.pointsSpent)",
                label: "تم خصمها",
                tint: TrendXTheme.aiViolet
            )
            balanceTile(
                icon: "wallet.pass.fill",
                value: "\(remainingPoints)",
                label: "المتبقي",
                tint: TrendXTheme.primary
            )
        }
    }

    private func balanceTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                let share = "كود هديتي من TRENDX: \(redemption.code) (\(redemption.brandName))"
                let activity = UIActivityViewController(activityItems: [share], applicationActivities: nil)
                presentSheet(activity)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("شارك مع صديق")
                        .font(.system(size: 14, weight: .heavy))
                }
                .foregroundStyle(TrendXTheme.primaryDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TrendXTheme.primary.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onDismiss()
            } label: {
                Text("تم")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(TrendXTheme.primaryGradient)
                    )
                    .shadow(color: TrendXTheme.primary.opacity(0.35), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func presentSheet(_ vc: UIViewController) {
        let scenes = UIApplication.shared.connectedScenes
        guard let scene = scenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        presenter.present(vc, animated: true)
    }
}

// MARK: - Confetti overlay

private struct ConfettiOverlay: View {
    struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let color: Color
        let size: CGFloat
        let rotation: Double
        let shape: Int
    }

    private let particles: [Particle]

    init() {
        let colors: [Color] = [
            TrendXTheme.primary, TrendXTheme.accent, TrendXTheme.success,
            TrendXTheme.aiIndigo, TrendXTheme.aiViolet,
            Color(red: 0.95, green: 0.55, blue: 0.20),
            Color(red: 0.92, green: 0.44, blue: 0.60)
        ]
        self.particles = (0..<54).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                delay: Double.random(in: 0...0.45),
                duration: Double.random(in: 1.6...2.6),
                color: colors.randomElement() ?? TrendXTheme.primary,
                size: CGFloat.random(in: 5...11),
                rotation: Double.random(in: -180...180),
                shape: Int.random(in: 0...2)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPiece(
                        particle: p,
                        size: geo.size
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct ConfettiPiece: View {
    let particle: ConfettiOverlay.Particle
    let size: CGSize

    @State private var animated = false

    var body: some View {
        Group {
            switch particle.shape {
            case 0:
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 1.7)
            case 1:
                Circle().fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            default:
                Capsule().fill(particle.color)
                    .frame(width: particle.size * 0.6, height: particle.size * 1.6)
            }
        }
        .opacity(animated ? 0.0 : 0.95)
        .position(
            x: particle.x * size.width,
            y: animated ? size.height + 40 : -20
        )
        .rotationEffect(.degrees(animated ? particle.rotation * 3 : particle.rotation))
        .onAppear {
            withAnimation(
                .easeOut(duration: particle.duration)
                .delay(particle.delay)
            ) {
                animated = true
            }
        }
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow)
    }
}
