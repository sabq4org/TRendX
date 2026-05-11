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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                MemberTierBadge(tier: tier)
                Spacer()
                if let next = tier.next {
                    Text("التالي: \(next.label)")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                } else {
                    Text("أعلى مستوى ✦")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(tier.tint)
                }
            }

            if let next = tier.next {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(tier.pointsToNext(points: points)) نقطة")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(TrendXTheme.ink)
                        Text("للوصول إلى \(next.label)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(TrendXTheme.softFill)
                                .frame(height: 8)
                            Capsule()
                                .fill(tier.gradient)
                                .frame(width: max(geo.size.width * tier.progress(points: points), 10), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(tier.threshold)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Spacer()
                        Text("\(next.threshold)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }
            } else {
                Text("وصلت لأعلى مستوى عضوية — استمتع بالامتيازات الحصرية.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
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
}
