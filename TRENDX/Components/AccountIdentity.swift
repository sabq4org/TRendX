//
//  AccountIdentity.swift
//  TRENDX
//
//  Shared building blocks for surfacing an account's identity across
//  the app — the inline verification badge, the type-aware avatar
//  (round for individuals, squircle for organizations, formal frame
//  for government), and a small helper that returns the right tint
//  for any account type.
//
//  These are pure presentation. The data comes from `TrendXUser`
//  (account_type + is_verified + avatar_url + avatar_initial).
//

import SwiftUI

// MARK: - Style helpers

extension AccountType {
    var tint: Color {
        switch self {
        case .individual:   return TrendXTheme.primary
        case .organization: return TrendXTheme.orgGold
        case .government:   return TrendXTheme.saudiGreen
        }
    }

    var lightTint: Color {
        switch self {
        case .individual:   return TrendXTheme.primaryLight
        case .organization: return TrendXTheme.orgGoldLight
        case .government:   return TrendXTheme.saudiGreenLight
        }
    }

    var wash: Color {
        switch self {
        case .individual:   return TrendXTheme.primary.opacity(0.10)
        case .organization: return TrendXTheme.orgGoldWash
        case .government:   return TrendXTheme.saudiGreenWash
        }
    }

    /// Inline badge icon used right next to the account name. We only
    /// surface a badge when there's something to say (verified, or
    /// government — government is always shown because it's a status
    /// even before manual verification).
    var inlineBadgeIcon: String {
        switch self {
        case .individual:   return "checkmark.seal.fill"     // shown when verified
        case .organization: return "checkmark.seal.fill"     // shown when verified
        case .government:   return "checkmark.shield.fill"   // always shown
        }
    }

    /// Avatar corner radius — circle for individuals, squircle for
    /// organizations, slightly tighter squircle for government.
    var avatarCornerStyle: AvatarShape {
        switch self {
        case .individual:   return .circle
        case .organization: return .roundedSquare(radius: 10)
        case .government:   return .roundedSquare(radius: 8)
        }
    }

    var profileLabel: String {
        switch self {
        case .individual:   return "حساب فرد"
        case .organization: return "حساب منظّمة"
        case .government:   return "جهة رسمية"
        }
    }
}

enum AvatarShape: Equatable {
    case circle
    case roundedSquare(radius: CGFloat)

    @ViewBuilder
    func clip<V: View>(_ content: V) -> some View {
        switch self {
        case .circle:
            content.clipShape(Circle())
        case .roundedSquare(let r):
            content.clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    var asRoundedRect: RoundedRectangle {
        switch self {
        case .circle:                  return RoundedRectangle(cornerRadius: 999, style: .continuous)
        case .roundedSquare(let r):    return RoundedRectangle(cornerRadius: r, style: .continuous)
        }
    }
}

// MARK: - AccountTypeBadge

/// Tiny verification/status badge that lives inline next to a name.
/// Returns an EmptyView for unverified individuals (no badge needed).
struct AccountTypeBadge: View {
    let type: AccountType
    let isVerified: Bool
    var size: CGFloat = 12

    private var shouldShow: Bool {
        // Government is always shown — it's a status that doesn't need
        // a separate "verified" toggle. Individuals + organizations show
        // the badge only when verified.
        type == .government || isVerified
    }

    var body: some View {
        if shouldShow {
            Image(systemName: type.inlineBadgeIcon)
                .font(.system(size: size, weight: .heavy))
                .foregroundStyle(type.tint)
                .accessibilityLabel(type.profileLabel)
        }
    }
}

// MARK: - AccountAvatar

/// Type-aware avatar. Renders `avatar_url` via AsyncImage when available,
/// falling back to the initial. Government accounts get a thicker
/// Saudi-green ring and a tiny corner emblem; organizations get an
/// amber ring; individuals get the brand ring (or no ring on small
/// sizes).
struct AccountAvatar: View {
    let user: TrendXUser
    var size: CGFloat = 64
    var showRing: Bool = true

    private var shape: AvatarShape { user.accountType.avatarCornerStyle }
    private var ringColor: Color { user.accountType.tint }
    private var ringWidth: CGFloat {
        switch user.accountType {
        case .individual:   return 1.5
        case .organization: return 2
        case .government:   return 2.5
        }
    }

    var body: some View {
        // No corner verification shield — verification is always shown
        // inline via `AccountTypeBadge` next to the name. Doubling it
        // on both the avatar and the name row made the profile look
        // cluttered ("توثيق على اللوقو وتوثيق على الاسم").
        ZStack {
            shape.asRoundedRect
                .fill(user.accountType == .government
                      ? TrendXTheme.saudiGreenGradient
                      : (user.accountType == .organization
                         ? TrendXTheme.orgGoldGradient
                         : TrendXTheme.primaryGradient as LinearGradient))
                .frame(width: size, height: size)

            if let urlString = user.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        shape.clip(
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(size * 0.10) // breathing room around emblems
                        )
                    default:
                        initialView
                    }
                }
                .frame(width: size, height: size)
            } else {
                initialView
            }
        }
        .overlay(
            showRing
            ? AnyView(shape.asRoundedRect.strokeBorder(ringColor.opacity(0.55), lineWidth: ringWidth))
            : AnyView(EmptyView())
        )
    }

    @ViewBuilder
    private var initialView: some View {
        // Government accounts without an uploaded avatar get the
        // stylized institutional emblem (palm + crossed lines) drawn
        // in SwiftUI — no external asset, no hosted URL dependency.
        if user.accountType == .government {
            governmentEmblem
        } else {
            Text(user.avatarInitial.isEmpty ? String(user.name.prefix(1)) : user.avatarInitial)
                .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var governmentEmblem: some View {
        ZStack {
            // Palm leaf — vertical centerpiece.
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.46, weight: .heavy))
                .foregroundStyle(.white)
                .offset(y: -size * 0.06)

            // Crossed swords stand-in — two thin white bars.
            Rectangle()
                .fill(.white.opacity(0.92))
                .frame(width: size * 0.38, height: size * 0.04)
                .rotationEffect(.degrees(18))
                .offset(y: size * 0.22)

            Rectangle()
                .fill(.white.opacity(0.92))
                .frame(width: size * 0.38, height: size * 0.04)
                .rotationEffect(.degrees(-18))
                .offset(y: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - AccountNameRow

/// Convenience row: name + handle + inline badge — used inside cards,
/// timeline items, comments, and profile headers. Keeps the spacing /
/// font sizing consistent everywhere accounts are referenced.
struct AccountNameRow: View {
    let user: TrendXUser
    var nameFont: Font = .system(size: 14, weight: .heavy, design: .rounded)
    var showHandle: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            Text(user.name)
                .font(nameFont)
                .foregroundStyle(TrendXTheme.ink)
                .lineLimit(1)

            AccountTypeBadge(type: user.accountType, isVerified: user.isVerified, size: 13)

            if showHandle, let handle = user.handle, !handle.isEmpty {
                Text("@\(handle)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .lineLimit(1)
            }
        }
    }
}
