//
//  TrendXTheme.swift
//  TRENDX
//

import SwiftUI

enum TrendXTheme {
    // MARK: - Backgrounds & Surfaces
    static let background     = Color(hex: "F4F5FA")   // رمادي فاتح عصري
    static let backgroundDeep = Color(hex: "E8EAF2")
    static let surface        = Color.white
    static let elevatedSurface = Color(hex: "FFFFFF")
    static let paleFill       = Color(hex: "F0F2FA")
    static let softFill       = Color(hex: "E4E7F5")
    static let strongFill     = Color(hex: "D5D9ED")

    // MARK: - Text Hierarchy
    static let ink            = Color(hex: "1A1B25")   // أسود دافئ
    static let secondaryInk   = Color(hex: "495057")
    static let tertiaryInk    = Color(hex: "868E96")
    static let mutedInk       = Color(hex: "ADB5BD")

    // MARK: - Brand Colors
    static let primary        = Color(hex: "3B5BDB")   // أزرق رئيسي
    static let primaryLight   = Color(hex: "4C6EF5")
    static let primaryDeep    = Color(hex: "364FC7")
    static let accent         = Color(hex: "FA7C12")   // برتقالي accent
    static let accentDeep     = Color(hex: "E8590C")

    // MARK: - TRENDX AI — Signature Palette
    static let aiIndigo = Color(hex: "4263EB")
    static let aiViolet = Color(hex: "7048E8")
    static let aiCyan   = Color(hex: "1098AD")
    static let aiInk    = Color(hex: "364FC7")

    // MARK: - Semantic Colors
    static let success = Color(hex: "2F9E44")
    static let warning = Color(hex: "F59F00")
    static let error   = Color(hex: "E03131")
    static let info    = Color(hex: "1971C2")
    static let muted   = Color(hex: "868E96")

    // MARK: - Border & Shadows
    static let outline      = Color(hex: "DEE2E6")
    static let strongOutline = Color(hex: "CED4DA")
    static let shadow       = Color(hex: "3B5BDB").opacity(0.08)
    static let deepShadow   = Color(hex: "364FC7").opacity(0.15)
    
    // MARK: - Corner Radii
    static let cardRadius: CGFloat = 20
    static let tileRadius: CGFloat = 16
    static let chipRadius: CGFloat = 12
    static let buttonRadius: CGFloat = 14
    static let pillRadius: CGFloat = 50
    
    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.98, green: 0.75, blue: 0.30), accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [primaryDeep, primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The signature TRENDX AI gradient — full saturation for icons / accents.
    static var aiGradient: LinearGradient {
        LinearGradient(
            colors: [aiIndigo, aiViolet, aiCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle tint fill used for AI surfaces, chips and ambient areas.
    static var aiGradientSoft: LinearGradient {
        LinearGradient(
            colors: [aiIndigo.opacity(0.10), aiCyan.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers

struct TrendXAmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TrendXTheme.background,
                    TrendXTheme.paleFill,
                    TrendXTheme.backgroundDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient blobs — أزرق هادئ مع لمسة برتقالية
            Circle()
                .fill(TrendXTheme.primary.opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -140, y: -280)

            Circle()
                .fill(TrendXTheme.accent.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 75)
                .offset(x: 160, y: 80)

            Circle()
                .fill(TrendXTheme.primaryDeep.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -140, y: 420)

            Canvas { ctx, size in
                let spacing: CGFloat = 18
                var path = Path()
                var x: CGFloat = spacing / 2
                while x < size.width {
                    var y: CGFloat = spacing / 2
                    while y < size.height {
                        path.addEllipse(in: CGRect(x: x, y: y, width: 1.1, height: 1.1))
                        y += spacing
                    }
                    x += spacing
                }
                ctx.fill(path, with: .color(TrendXTheme.primary.opacity(0.035)))
            }
        }
        .ignoresSafeArea()
    }
}

struct ScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(TrendXAmbientBackground())
    }
}

struct TrendXRTL: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
    }
}

extension View {
    func trendxRTL() -> some View {
        modifier(TrendXRTL())
    }

    func trendxScreenBackground() -> some View {
        modifier(ScreenBackgroundModifier())
    }
}

// MARK: - Card Styles

struct SurfaceCardStyle: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = TrendXTheme.cardRadius

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 7)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(TrendXTheme.outline.opacity(0.75), lineWidth: 0.8)
            )
    }
}

extension View {
    func surfaceCard(padding: CGFloat = 18, radius: CGFloat = TrendXTheme.cardRadius) -> some View {
        modifier(SurfaceCardStyle(padding: padding, radius: radius))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    enum Kind {
        case active, ended, voted, draft, warning

        var tint: Color {
            switch self {
            case .active: return TrendXTheme.success
            case .ended: return TrendXTheme.muted
            case .voted: return TrendXTheme.primary
            case .draft: return TrendXTheme.accent
            case .warning: return TrendXTheme.warning
            }
        }

        var icon: String {
            switch self {
            case .active: return "circle.fill"
            case .ended: return "checkmark.circle.fill"
            case .voted: return "checkmark.seal.fill"
            case .draft: return "pencil.circle.fill"
            case .warning: return "clock.badge.exclamationmark.fill"
            }
        }

        var label: String {
            switch self {
            case .active: return "نشط"
            case .ended: return "منتهي"
            case .voted: return "صوّتت"
            case .draft: return "مسودة"
            case .warning: return "ينتهي قريباً"
            }
        }
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.system(size: 9, weight: .bold))
            Text(kind.label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(kind.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(kind.tint.opacity(0.10))
        )
    }
}

// MARK: - Custom Fonts

extension Font {
    static func trendxTitle() -> Font {
        .system(size: 32, weight: .heavy, design: .serif)
    }
    
    static func trendxHeadline() -> Font {
        .system(size: 24, weight: .heavy, design: .serif)
    }
    
    static func trendxSubheadline() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
    
    static func trendxBody() -> Font {
        .system(size: 16, weight: .regular)
    }
    
    static func trendxBodyBold() -> Font {
        .system(size: 16, weight: .semibold)
    }
    
    static func trendxCaption() -> Font {
        .system(size: 14, weight: .medium)
    }
    
    static func trendxSmall() -> Font {
        .system(size: 12, weight: .medium)
    }
    
    static func trendxMetric() -> Font {
        .system(size: 24, weight: .bold, design: .rounded).monospacedDigit()
    }
}

// MARK: - Color(hex:) Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
