//
//  MemberTier.swift
//  TRENDX
//
//  Lightweight, client-computed tier system based on points-earned-to-date.
//  We bucket users into Bronze / Silver / Gold / Diamond and expose
//  progress to the next tier so the WalletHero and Account screen can
//  surface a "next tier unlocks at X" hook — the strongest retention
//  signal we can show without backend changes.
//

import SwiftUI

enum MemberTier: String, CaseIterable {
    case bronze, silver, gold, diamond

    var label: String {
        switch self {
        case .bronze: return "برونزي"
        case .silver: return "فضي"
        case .gold: return "ذهبي"
        case .diamond: return "ماسي"
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "shield.fill"
        case .silver: return "rosette"
        case .gold: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }

    var threshold: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 300
        case .gold: return 1_000
        case .diamond: return 3_000
        }
    }

    var tint: Color {
        switch self {
        case .bronze: return Color(red: 0.72, green: 0.46, blue: 0.24)
        case .silver: return Color(red: 0.62, green: 0.66, blue: 0.72)
        case .gold:   return Color(red: 0.92, green: 0.72, blue: 0.20)
        case .diamond:return Color(red: 0.30, green: 0.62, blue: 0.92)
        }
    }

    var gradient: LinearGradient {
        let mix = Color(red: tint.colorComponents.r * 0.85,
                        green: tint.colorComponents.g * 0.85,
                        blue: tint.colorComponents.b * 0.85)
        return LinearGradient(
            colors: [tint, mix],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func from(points: Int) -> MemberTier {
        // Cumulative-points based bucketing. We use current balance as a
        // proxy for lifetime earnings — once a points-ledger query
        // becomes worthwhile we can swap to a true "total earned" figure.
        if points >= MemberTier.diamond.threshold { return .diamond }
        if points >= MemberTier.gold.threshold { return .gold }
        if points >= MemberTier.silver.threshold { return .silver }
        return .bronze
    }

    var next: MemberTier? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .diamond
        case .diamond: return nil
        }
    }

    func progress(points: Int) -> Double {
        guard let next else { return 1 }
        let span = max(1, next.threshold - threshold)
        return min(1, max(0, Double(points - threshold) / Double(span)))
    }

    func pointsToNext(points: Int) -> Int {
        guard let next else { return 0 }
        return max(0, next.threshold - points)
    }
}

// MARK: - Color helper

private extension Color {
    var colorComponents: (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        return (1, 1, 1)
        #endif
    }
}

// MARK: - Tier badge view

struct MemberTierBadge: View {
    let tier: MemberTier
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: tier.icon)
                .font(.system(size: compact ? 9 : 11, weight: .heavy))
            Text(tier.label)
                .font(.system(size: compact ? 10 : 11, weight: .heavy))
                .tracking(0.2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 3 : 4)
        .background(Capsule().fill(tier.gradient))
        .shadow(color: tier.tint.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Tier progress card

struct MemberTierProgressCard: View {
    let points: Int

    private var tier: MemberTier { MemberTier.from(points: points) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                MemberTierBadge(tier: tier)
                Spacer(minLength: 0)
                Text("\(points) نقطة")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(tier.tint)
                    .monospacedDigit()
            }

            if let next = tier.next {
                Text("تبقى \(tier.pointsToNext(points: points)) نقطة للوصول إلى \(next.label)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            tierRail
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(tier.tint.opacity(0.18), lineWidth: 1)
                )
        )
    }

    /// Four-tier rail showing every milestone with a filled progress
    /// segment between the previous tier and the current one. Replaces
    /// the older bar that only knew the *current* tier's bracket and
    /// looked broken to anyone trying to read absolute position
    /// across all tiers ("المؤشر غير").
    private var tierRail: some View {
        let allTiers = MemberTier.allCases
        let railProgress = railFillRatio(points: points)

        return VStack(spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let dotSize: CGFloat = 14
                let trackHeight: CGFloat = 6

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(TrendXTheme.softFill)
                        .frame(height: trackHeight)

                    // Filled portion up to current points.
                    Capsule()
                        .fill(tier.gradient)
                        .frame(width: max(0, width * railProgress), height: trackHeight)

                    // Per-tier dots, positioned by their absolute threshold
                    // along the rail. Solid when reached, hollow otherwise.
                    ForEach(Array(allTiers.enumerated()), id: \.offset) { idx, t in
                        let pos = dotPosition(for: t, width: width, dotSize: dotSize)
                        ZStack {
                            Circle()
                                .fill(points >= t.threshold ? t.tint : TrendXTheme.surface)
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle().stroke(t.tint, lineWidth: 1.5)
                                )
                            if points >= t.threshold {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                        }
                        .offset(x: pos)
                    }
                    .frame(height: dotSize)
                }
                .frame(height: dotSize)
            }
            .frame(height: 14)

            // Threshold labels under each dot.
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .topLeading) {
                    ForEach(Array(allTiers.enumerated()), id: \.offset) { idx, t in
                        let pos = dotPosition(for: t, width: width, dotSize: 0)
                        VStack(spacing: 1) {
                            Text(t.label)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(points >= t.threshold ? t.tint : TrendXTheme.tertiaryInk)
                            Text("\(t.threshold)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                                .monospacedDigit()
                        }
                        .frame(width: 52)
                        .offset(x: pos - 26)
                    }
                }
            }
            .frame(height: 24)
        }
    }

    /// Fraction of the rail to fill — uses the absolute point span
    /// from Bronze threshold (0) to Diamond threshold (3000). Capped
    /// at 1.0 for users who exceed Diamond.
    private func railFillRatio(points: Int) -> Double {
        let max = MemberTier.diamond.threshold
        guard max > 0 else { return 1 }
        return min(1, Swift.max(0, Double(points) / Double(max)))
    }

    private func dotPosition(for tier: MemberTier, width: CGFloat, dotSize: CGFloat) -> CGFloat {
        let max = MemberTier.diamond.threshold
        guard max > 0 else { return 0 }
        let ratio = CGFloat(tier.threshold) / CGFloat(max)
        return ratio * (width - dotSize)
    }
}
