//
//  SharedComponents.swift
//  TRENDX
//

import SwiftUI

// MARK: - Custom Tab Bar

struct TrendXTabBar: View {
    @Binding var selectedTab: TabItem
    /// Fires when the user taps the *already-selected* tab. Lets the
    /// hosting screen do something useful on the re-tap (e.g. scroll
    /// the home feed back to the top) instead of swallowing it as a
    /// no-op assignment.
    var onReselect: ((TabItem) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    if selectedTab == tab {
                        onReselect?(tab)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(TrendXTheme.elevatedSurface.opacity(0.86))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(TrendXTheme.outline.opacity(0.62), lineWidth: 0.8)
                )
                .shadow(color: TrendXTheme.primaryDeep.opacity(0.18), radius: 22, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(isSelected ? AnyShapeStyle(TrendXTheme.primaryGradient) : AnyShapeStyle(Color.clear))
                    )
                    .shadow(color: isSelected ? TrendXTheme.primary.opacity(0.30) : .clear, radius: 8, x: 0, y: 4)
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? TrendXTheme.primaryDeep : TrendXTheme.tertiaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? TrendXTheme.accent.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Header Components

struct HomeHeader: View {
    let userName: String
    let points: Int
    /// Optional avatar URL — when present the welcome circle renders
    /// the user's actual photo instead of the initial. Accepts both
    /// remote http(s) URLs and inline base64 `data:` URLs (uploaded
    /// via the profile editor's PhotosPicker).
    var avatarUrl: String? = nil
    /// Coin balance (نقاط ÷ ٦) — shown as the middle metric capsule
    /// so the hero has three distinct values instead of the older
    /// static "AI · رادار" label that duplicated the antenna button.
    var coins: Double = 0
    var unreadNotifications: Int = 0
    var isGuest: Bool = false
    var onSignInTap: () -> Void = {}
    let onNotificationsTap: () -> Void
    let onSearchTap: () -> Void
    /// New: opens the Timeline (الرادار) directly from anywhere on
    /// Home — no need to scroll past 200pt of cards to find the
    /// entry point. Hidden when guest because timeline needs auth.
    var onTimelineTap: (() -> Void)? = nil

    private var greeting: TrendXAI.Greeting {
        TrendXAI.greeting(for: userName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if isGuest {
                guestContent
            } else {
                authedContent
            }
        }
        .padding(20)
        .background(
            ZStack {
                TrendXTheme.headerGradient

                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 210, height: 210)
                    .blur(radius: 42)
                    .offset(x: -120, y: -90)

                Circle()
                    .fill(TrendXTheme.info.opacity(0.16))
                    .frame(width: 160, height: 160)
                    .blur(radius: 44)
                    .offset(x: 140, y: 90)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: TrendXTheme.primaryDeep.opacity(0.22), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    @ViewBuilder private var authedContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    .frame(width: 52, height: 52)

                if let avatarUrl, !avatarUrl.isEmpty {
                    TrendXProfileImage(urlString: avatarUrl) {
                        Text(String(userName.prefix(1)))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Text(String(userName.prefix(1)))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(greeting.eyebrow)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))

                Text(greeting.title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)

            if let onTimelineTap {
                HeaderIconButton(icon: "antenna.radiowaves.left.and.right", action: onTimelineTap)
            }

            HeaderIconButton(icon: "magnifyingglass", action: onSearchTap)

            Button(action: onNotificationsTap) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.16)))
                    .overlay(alignment: .topTrailing) {
                        if unreadNotifications > 0 {
                            Text(unreadNotifications > 9 ? "9+" : "\(unreadNotifications)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Capsule().fill(TrendXTheme.accent))
                                .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                                .offset(x: -4, y: 2)
                        }
                    }
            }
            .buttonStyle(.plain)
        }

        Text(greeting.whisper)
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundStyle(.white.opacity(0.86))
            .lineSpacing(4)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 10) {
            MetricCapsule(icon: "star.circle.fill", value: "\(points)", label: "نقطة", tint: TrendXTheme.accent)
            MetricCapsule(icon: "dollarsign.circle.fill", value: String(format: "%.1f", coins), label: "ريال", tint: TrendXTheme.success)
            MetricCapsule(icon: "newspaper.fill", value: "مجلة", label: "اليوم", tint: TrendXTheme.warning)
        }
    }

    @ViewBuilder private var guestContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("مرحباً بك في TRENDX")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.82))
                Text("نبض الرأي السعودي")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            HeaderIconButton(icon: "magnifyingglass", action: onSearchTap)
        }

        Text("استكشف الاتجاهات اليومية، توقّع نبض السعودية، واربح نقاطك الأولى — تسجيلك يستغرق دقيقة واحدة.")
            .font(.system(size: 14, weight: .medium, design: .serif))
            .foregroundStyle(.white.opacity(0.88))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)

        Button(action: onSignInTap) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .font(.system(size: 14, weight: .heavy))
                Text("سجّل الآن وابدأ مع TRENDX")
                    .font(.system(size: 14, weight: .heavy))
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(TrendXTheme.primaryDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Capsule().fill(.white))
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

}

private struct HeaderIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }
}

private struct MetricCapsule: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
        )
    }
}

// MARK: - Segmented Control

struct TrendXSegmentedControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                    }
                } label: {
                    HStack(spacing: 6) {
                        if index == 0 {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14))
                        } else {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                        }
                        Text(titles[index])
                            .font(.trendxCaption())
                    }
                    .foregroundStyle(selectedIndex == index ? .white : TrendXTheme.secondaryInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selectedIndex == index ? TrendXTheme.primary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.elevatedSurface)
        )
        .shadow(color: TrendXTheme.shadow, radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - AI Insight Chip

/// A subtle, elegant AI-generated insight chip that appears inside a PollCard.
/// Expandable on tap: collapsed state shows a single line with a sparkles icon.
struct AIInsightChip: View {
    let text: String
    var label: String = "رؤية TRENDX AI"
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(TrendXTheme.aiGradient)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: TrendXTheme.aiIndigo.opacity(0.28), radius: 6, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(
                                TrendXTheme.aiGradient
                            )

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }

                    Text(text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 1)
                        .fixedSize(horizontal: false, vertical: isExpanded)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TrendXTheme.aiGradientSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                TrendXTheme.aiIndigo.opacity(0.28),
                                TrendXTheme.info.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Poll Cover View (editorial hero)

/// Editorial cover that prefers a real publisher-uploaded image when one
/// exists, and falls back to the layered-gradient `PollCoverView` when it
/// doesn't. The topic chip + glyph stay overlaid so the cover always
/// reads as TRENDX-branded content regardless of what photo was uploaded.
///
/// `imageURL` accepts both regular `http(s)` URLs and base64 `data:`
/// URIs — the same dual-mode pipeline avatars use via `TrendXProfileImage`.
struct TrendXEditorialCover: View {
    let imageURL: String?
    let style: PollCoverStyle
    var height: CGFloat = 140
    /// Show the topic chip + label overlay. Disable on tiny thumbnails
    /// where the chip wouldn't fit, or on detail screens that already
    /// render the topic strip elsewhere.
    var showsTopicOverlay: Bool = true

    var body: some View {
        if let raw = imageURL, !raw.isEmpty {
            ZStack(alignment: .bottomLeading) {
                TrendXProfileImage(urlString: raw) {
                    // Fallback to the gradient while the image is loading
                    // or if the URL is bad — never leave a flat color
                    // rectangle behind.
                    PollCoverView(style: style, height: height)
                }
                .frame(height: height)
                .clipped()

                if showsTopicOverlay {
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height * 0.55)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)

                    HStack(spacing: 6) {
                        Image(systemName: style.glyph)
                            .font(.system(size: 11, weight: .heavy))
                        Text(style.label)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.16)))
                    .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 0.6))
                    .padding(12)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 0.8)
            )
            .shadow(color: style.tint.opacity(0.18), radius: 14, x: 0, y: 8)
        } else {
            PollCoverView(style: style, height: height)
        }
    }
}

/// A modern editorial cover: mesh-like layered gradient, a fine dot grid for
/// texture, and typographic hierarchy — no floating clip-art icons.
/// Rendered only when a poll explicitly has a cover to show.
struct PollCoverView: View {
    let style: PollCoverStyle
    var height: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Base deep gradient
                LinearGradient(
                    colors: [style.gradient[0], style.gradient[1]],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Layered, highly-blurred color blobs — gives a mesh feel
                Circle()
                    .fill(style.gradient[1].opacity(0.55))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 55)
                    .offset(x: geo.size.width * 0.22, y: -geo.size.height * 0.45)

                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 45)
                    .offset(x: -geo.size.width * 0.28, y: geo.size.height * 0.2)

                Circle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.55)

                // Fine dot-grid pattern — adds editorial "grain"
                Canvas { ctx, size in
                    let spacing: CGFloat = 12
                    var path = Path()
                    var x: CGFloat = spacing / 2
                    while x < size.width {
                        var y: CGFloat = spacing / 2
                        while y < size.height {
                            path.addEllipse(in: CGRect(x: x, y: y, width: 1.2, height: 1.2))
                            y += spacing
                        }
                        x += spacing
                    }
                    ctx.fill(path, with: .color(Color.white.opacity(0.09)))
                }

                // Soft top-light sheen
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .blendMode(.overlay)

                // Watermark glyph — subtle, large, bottom-trailing
                Image(systemName: style.glyph)
                    .font(.system(size: min(geo.size.height * 1.2, 180), weight: .bold))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: geo.size.width * 0.55, y: geo.size.height * 0.15)

                // Editorial content
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.white.opacity(0.95))
                            .frame(width: 5, height: 5)
                        Text("TRENDX")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(.white.opacity(0.14))
                    )
                    .overlay(
                        Capsule().stroke(.white.opacity(0.22), lineWidth: 0.6)
                    )

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(style.heroPhrase)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 3)

                        HStack(spacing: 6) {
                            // Note: no `.tracking()` here — positive letter-spacing
                            // on Arabic text breaks the connected glyphs and the
                            // label renders as detached characters.
                            Text(style.label)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Rectangle()
                                .fill(.white.opacity(0.5))
                                .frame(width: 18, height: 1)

                            Text("قراءة مجتمعية")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                }
                .padding(14)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: style.tint.opacity(0.18), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Poll Card

struct PollCard: View {
    let poll: Poll
    let onVote: (UUID) -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    /// Optional richer vote callback — invoked instead of `onVote` when
    /// the parent wants to pass through the opt-in visibility flag.
    var onVoteWithVisibility: ((UUID, Bool) -> Void)? = nil
    /// Optional repost handler — receives the poll id and the *new*
    /// desired state (true = repost, false = un-repost).
    var onRepost: ((UUID, Bool) -> Void)? = nil
    /// Tapping the author area opens their public profile. Receives the
    /// `@handle` (without the leading @).
    var onAuthorTap: ((String) -> Void)? = nil

    @State private var selectedOption: UUID?
    /// Per-card opt-in switch: "أظهر تصويتي لمتابعيّ". Default OFF —
    /// matches the backend's default `is_public = false`.
    @State private var voteIsPublic: Bool = false

    private var statusKind: StatusBadge.Kind {
        if poll.isExpired { return .ended }
        if poll.hasUserVoted { return .voted }
        if poll.isEndingSoon { return .warning }
        return .active
    }

    private var topicStyle: PollCoverStyle { poll.topicStyle }
    private var tint: Color { topicStyle.tint }
    private var isOfficial: Bool {
        poll.authorAccountType == .government || poll.voterAudience != "public"
    }

    /// String that can be passed to `/users/:idOrHandle`. Prefers the
    /// publisher's UUID (always present when the post comes from the
    /// API) and falls back to the handle.
    private var authorNavigationToken: String? {
        if let id = poll.publisherId?.uuidString { return id }
        if let handle = poll.authorHandle, !handle.isEmpty { return handle }
        return nil
    }

    /// Lightweight `TrendXUser` synthesized from the poll's cached
    /// author fields. Lets us reuse the shared `AccountAvatar` and
    /// `AccountTypeBadge` components instead of duplicating the avatar
    /// + verification logic inline.
    private var authorAsUser: TrendXUser {
        TrendXUser(
            id: poll.publisherId ?? UUID(),
            name: poll.authorName,
            handle: poll.authorHandle,
            avatarInitial: poll.authorAvatar,
            avatarUrl: poll.authorAvatarUrl,
            accountType: poll.authorAccountType,
            isVerified: poll.authorIsVerified
        )
    }

    var body: some View {
        // Topic colour is now expressed only through the topic pill,
        // the cover hero, and the option progress bars. The card frame,
        // shadow, and author chrome stay neutral so stacking five
        // different topics no longer looks chaotic.
        cardBody
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 0.8)
            )
            .shadow(color: TrendXTheme.shadow, radius: 14, x: 0, y: 7)
            .opacity(poll.isExpired ? 0.82 : 1.0)
    }

    /// Tiny inline pill that crowns the topic row when a poll is from
    /// a government account (or has a non-public audience). Replaces
    /// the heavy ribbon-across-the-top treatment.
    @ViewBuilder
    private var officialInlineMarker: some View {
        if isOfficial {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 9, weight: .heavy))
                Text(officialBannerLabel)
                    .font(.system(size: 9.5, weight: .heavy))
            }
            .foregroundStyle(TrendXTheme.saudiGreen)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(TrendXTheme.saudiGreenWash))
        }
    }

    private var officialBannerLabel: String {
        switch poll.voterAudience {
        case "verified_citizen": return "استطلاع وطني"
        case "verified":         return "للموثّقين"
        default:                  return "رسمي"
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header — tappable when we have a handle to navigate to.
            // Avatar + verification badge come from the shared identity
            // components so visual treatment matches everywhere
            // (timeline, profile, suggested follows, comments).
            Button {
                if let onAuthorTap, let token = authorNavigationToken {
                    onAuthorTap(token)
                }
            } label: {
                HStack(spacing: 10) {
                    AccountAvatar(user: authorAsUser, size: 44, showRing: true)

                    // Spacing of 2 made the author name look glued to
                    // the topic/time row underneath — the descender of
                    // Arabic glyphs (ج، م، ي) literally kissed the
                    // capsule above. 6 gives the row visual breathing
                    // room without inflating the card height.
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text(poll.authorName)
                                .font(.trendxBodyBold())
                                .foregroundStyle(TrendXTheme.ink)
                                .lineLimit(1)

                            AccountTypeBadge(
                                type: poll.authorAccountType,
                                isVerified: poll.authorIsVerified,
                                size: 13
                            )
                        }

                        HStack(spacing: 5) {
                            if let topicName = poll.topicName {
                                // Topic pill uses the topic colour for non-
                                // official polls. For official polls the
                                // pill stays neutral; the official status
                                // is shown by the green pill next to it.
                                Text(topicName)
                                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(tint)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(topicStyle.wash))
                                    .overlay(Capsule().stroke(topicStyle.hairline, lineWidth: 0.6))
                            }

                            officialInlineMarker

                            Text(poll.timeAgo)
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                }

                Spacer(minLength: 0)

                StatusBadge(kind: statusKind)
            }
            }
            .buttonStyle(.plain)
            .disabled(authorNavigationToken == nil)

            // Question
            Text(poll.title)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(TrendXTheme.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            TrendXEditorialCover(
                imageURL: poll.imageURL,
                style: topicStyle,
                height: 132
            )

            // Options with topic-colored tint
            VStack(spacing: 10) {
                ForEach(poll.options) { option in
                    PollOptionRow(
                        option: option,
                        tint: tint,
                        isSelected: selectedOption == option.id || poll.userVotedOptionId == option.id,
                        showResults: poll.hasUserVoted,
                        isUserChoice: poll.userVotedOptionId == option.id
                    ) {
                        if !poll.hasUserVoted {
                            selectedOption = option.id
                            if let richer = onVoteWithVisibility {
                                richer(option.id, voteIsPublic)
                            } else {
                                onVote(option.id)
                            }
                        }
                    }
                }
            }

            // Opt-in vote visibility — only shown before the user has
            // voted, so the choice is made at the moment of action and
            // never retroactively. Defaults to private.
            if !poll.hasUserVoted {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        voteIsPublic.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: voteIsPublic ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 11, weight: .heavy))
                        Text(voteIsPublic ? "تصويتي ظاهر لمتابعيّ" : "تصويتي خاص")
                            .font(.system(size: 11.5, weight: .heavy))
                        Spacer(minLength: 0)
                        Text(voteIsPublic ? "اضغط للإخفاء" : "اضغط للإظهار")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    .foregroundStyle(voteIsPublic ? TrendXTheme.primary : TrendXTheme.secondaryInk)
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(voteIsPublic ? TrendXTheme.primary.opacity(0.10) : TrendXTheme.paleFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(voteIsPublic ? TrendXTheme.primary.opacity(0.22) : Color.clear, lineWidth: 0.8)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // AI Insight after voting
            if poll.hasUserVoted {
                if let insight = poll.aiInsight {
                    AIInsightChip(text: insight, label: "رؤية TRENDX AI")
                } else {
                    AIInsightChip(text: TrendXAI.encouragement(), label: "شكراً من TRENDX AI")
                }
            }

            // Thin hairline
            Rectangle()
                .fill(TrendXTheme.outline)
                .frame(height: 0.8)
                .padding(.top, 2)

            // Footer
            HStack(spacing: 14) {
                Label("\(poll.totalVotes)", systemImage: "person.2.fill")
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.secondaryInk)

                Label(poll.deadlineLabel, systemImage: poll.isExpired ? "clock.badge.xmark.fill" : "clock.fill")
                    .font(.trendxSmall())
                    .foregroundStyle(poll.isExpired ? TrendXTheme.muted : (poll.isEndingSoon ? TrendXTheme.warning : TrendXTheme.secondaryInk))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(TrendXTheme.accent)
                    Text("+\(poll.rewardPoints)")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.accentDeep)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(TrendXTheme.accent.opacity(0.10)))
            }

            // Actions
            HStack(spacing: 12) {
                // Repost — surfaces this poll in the user's followers'
                // timelines as a `repost` activity. Tapping again
                // un-reposts. Optimistic flip via `@State` so the
                // pill animates immediately.
                Button {
                    if let onRepost {
                        onRepost(poll.id, !poll.viewerReposted)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: poll.viewerReposted
                              ? "arrow.2.squarepath" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .heavy))
                        Text(poll.viewerReposted ? "أُعيد نشره" : "إعادة نشر")
                            .font(.system(size: 11.5, weight: .heavy))
                    }
                    .foregroundStyle(poll.viewerReposted ? .white : TrendXTheme.aiViolet)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(poll.viewerReposted
                                  ? AnyShapeStyle(LinearGradient(
                                      colors: [TrendXTheme.aiViolet, TrendXTheme.aiIndigo],
                                      startPoint: .leading, endPoint: .trailing))
                                  : AnyShapeStyle(TrendXTheme.aiViolet.opacity(0.10)))
                    )
                }
                .buttonStyle(.plain)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(TrendXTheme.softFill))
                }
                .buttonStyle(.plain)

                Button(action: onBookmark) {
                    Image(systemName: poll.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(poll.isBookmarked ? TrendXTheme.primary : TrendXTheme.secondaryInk)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(poll.isBookmarked ? TrendXTheme.primary.opacity(0.10) : TrendXTheme.softFill)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(16)
    }
}

struct PollOptionRow: View {
    let option: PollOption
    /// Dynamic tint — drawn from the poll's topic so selected / winning
    /// states echo the card's identity instead of a generic blue.
    var tint: Color = TrendXTheme.primary
    let isSelected: Bool
    let showResults: Bool
    let isUserChoice: Bool
    let onTap: () -> Void

    private var isLeading: Bool {
        // The leading option visually wins when results are shown.
        showResults && option.percentage >= 50
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                if isUserChoice {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tint)
                } else if showResults && isLeading {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tint.opacity(0.85))
                }

                Text(option.text)
                    .font(.system(size: 14.5, weight: isUserChoice ? .semibold : .medium))
                    .foregroundStyle(isUserChoice ? tint : TrendXTheme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if showResults {
                    Text(String(format: "%.0f%%", option.percentage))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(isUserChoice ? tint : TrendXTheme.secondaryInk)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TrendXTheme.softFill)

                        if showResults {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: isUserChoice
                                            ? [tint.opacity(0.22), tint.opacity(0.10)]
                                            : [tint.opacity(0.08), tint.opacity(0.04)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * option.percentage / 100)
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        (isSelected || isUserChoice) ? tint : TrendXTheme.strongOutline,
                        lineWidth: (isSelected || isUserChoice) ? 1.4 : 0.8
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(showResults)
    }
}

// MARK: - Topic Chip

struct TopicChip: View {
    let topic: Topic
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: topic.icon)
                    .font(.system(size: 14))
                Text(topic.name)
                    .font(.trendxCaption())
            }
            .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? TrendXTheme.primary : TrendXTheme.softFill)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var showMore: Bool = true
    var onMoreTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.trendxSubheadline())
                    .foregroundStyle(TrendXTheme.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }

            Spacer()

            if showMore {
                Button { onMoreTap?() } label: {
                    HStack(spacing: 3) {
                        Text("عرض الكل")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(TrendXTheme.primary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - AI Brief Card (hero)

/// Elegant AI-driven "brief of the day" card that positions TRENDX as an
/// AI-first product. Signature gradient lives in the icon bubble, a subtle
/// wash fills the card, and a live pulse confirms the feed is alive.
struct AIBriefCard: View {
    let brief: TrendXAI.AIBrief

    @State private var pulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                // Signature AI icon bubble
                ZStack {
                    Circle()
                        .fill(TrendXTheme.aiGradient)
                        .frame(width: 42, height: 42)
                        .shadow(color: TrendXTheme.aiIndigo.opacity(0.35), radius: 10, x: 0, y: 6)

                    Image(systemName: brief.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(brief.headline)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.ink)

                    HStack(spacing: 6) {
                        Text("TRENDX AI")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(TrendXTheme.aiIndigo)

                        Circle()
                            .fill(TrendXTheme.tertiaryInk.opacity(0.4))
                            .frame(width: 3, height: 3)

                        Text(brief.tag)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                }

                Spacer(minLength: 0)

                // Live pulse indicator
                ZStack {
                    Circle()
                        .stroke(TrendXTheme.success.opacity(pulse ? 0 : 0.4), lineWidth: 6)
                        .frame(width: pulse ? 22 : 10, height: pulse ? 22 : 10)

                    Circle()
                        .fill(TrendXTheme.success)
                        .frame(width: 7, height: 7)
                }
                .frame(width: 22, height: 22)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                        pulse = true
                    }
                }
            }

            Text(brief.body)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(TrendXTheme.surface)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                TrendXTheme.aiIndigo.opacity(0.06),
                                TrendXTheme.info.opacity(0.025),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            TrendXTheme.aiIndigo.opacity(0.28),
                            TrendXTheme.info.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: TrendXTheme.aiIndigo.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Topic Row

struct TopicRow: View {
    let topic: Topic
    let onFollowTap: () -> Void

    private var tint: Color { topic.topicColor }
    private var gradient: [Color] { topic.topicGradient }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: topic.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: tint.opacity(0.30), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.name)
                    .font(.trendxBodyBold())
                    .foregroundStyle(TrendXTheme.ink)

                HStack(spacing: 12) {
                    Label("\(topic.followersCount) متابع", systemImage: "person.2")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.tertiaryInk)

                    Label("\(topic.postsCount) منشور", systemImage: "doc.text")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }

            Spacer()

            Button(action: onFollowTap) {
                Text(topic.isFollowing ? "تتابعه" : "متابعة")
                    .font(.trendxCaption())
                    .foregroundStyle(topic.isFollowing ? TrendXTheme.secondaryInk : tint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(topic.isFollowing ? TrendXTheme.softFill : tint.opacity(0.10))
                    )
                    .overlay(
                        Capsule()
                            .stroke(topic.isFollowing ? TrendXTheme.outline : tint.opacity(0.25), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(TrendXTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TrendXTheme.outline, lineWidth: 0.8)
        )
        .shadow(color: tint.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Gift Card

/// Premium gift card with brand-flavored hero, monogram, clear points/value
/// chips and an affordability-aware CTA indicator.
struct GiftCard: View {
    let gift: Gift
    var userPoints: Int = 0
    let onTap: () -> Void

    private var tint: Color { gift.categoryTint }
    private var tintLight: Color { gift.categoryTintLight }
    private var canAfford: Bool { userPoints >= gift.pointsRequired }
    private var progress: Double {
        guard gift.pointsRequired > 0 else { return 1 }
        return min(Double(userPoints) / Double(gift.pointsRequired), 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero visual
                ZStack(alignment: .topLeading) {
                    // Brand-colored gradient
                    LinearGradient(
                        colors: [tint, tintLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)

                    // Watermark icon
                    Image(systemName: gift.categoryIcon)
                        .font(.system(size: 110, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.14))
                        .rotationEffect(.degrees(-10))
                        .offset(x: -28, y: 22)
                        .frame(height: 120, alignment: .bottomLeading)

                    // Glossy shine
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 120)
                    .blendMode(.overlay)

                    // Brand mark + value chip
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            GiftBrandMark(gift: gift, size: 48, monogramFont: 28)
                                .shadow(color: tint.opacity(0.4), radius: 4, x: 0, y: 2)

                            Spacer()

                            // Value chip
                            HStack(spacing: 3) {
                                Text("\(Int(gift.valueInRiyal))")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                Text("ر.س")
                                    .font(.system(size: 10, weight: .bold))
                                    .opacity(0.85)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color.white.opacity(0.22))
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                            )
                        }

                        Spacer()

                        // Category lozenge
                        HStack(spacing: 5) {
                            Image(systemName: gift.categoryIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(gift.category)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.22)))
                    }
                    .padding(14)
                    .frame(height: 120, alignment: .topLeading)
                }

                // Body
                VStack(alignment: .leading, spacing: 10) {
                    if let proof = GiftSocialProof.badge(for: gift) {
                        HStack(spacing: 4) {
                            Image(systemName: proof.icon)
                                .font(.system(size: 9, weight: .heavy))
                            Text(proof.label)
                                .font(.system(size: 10, weight: .heavy))
                        }
                        .foregroundStyle(proof.tint)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(proof.tint.opacity(0.12)))
                    }

                    Text(gift.brandName)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.ink)
                        .lineLimit(1)

                    Text(gift.name)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .lineLimit(1)

                    // Affordability progress (ambient micro-UI)
                    if !canAfford {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(TrendXTheme.softFill)
                                    .frame(height: 4)
                                Capsule()
                                    .fill(tint.opacity(0.9))
                                    .frame(width: max(geo.size.width * progress, 4), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }

                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(TrendXTheme.accent)
                            Text("\(gift.pointsRequired)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(TrendXTheme.accentDeep)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(TrendXTheme.accent.opacity(0.12)))

                        Spacer()

                        // CTA
                        ZStack {
                            Circle()
                                .fill(canAfford ? TrendXTheme.success : TrendXTheme.softFill)
                                .frame(width: 30, height: 30)

                            Image(systemName: canAfford ? "arrow.left" : "lock.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(canAfford ? .white : TrendXTheme.tertiaryInk)
                        }
                        .shadow(
                            color: canAfford ? TrendXTheme.success.opacity(0.35) : .clear,
                            radius: 6, x: 0, y: 3
                        )
                    }
                }
                .padding(12)
            }
            .background(TrendXTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.10), radius: 12, x: 0, y: 6)
            .opacity(canAfford ? 1.0 : 0.92)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.trendxBodyBold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(TrendXTheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: TrendXTheme.buttonRadius, style: .continuous))
            .shadow(color: TrendXTheme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(TrendXTheme.primaryGradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: TrendXTheme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            
            Text(title)
                .font(.trendxSubheadline())
                .foregroundStyle(TrendXTheme.ink)
            
            Text(message)
                .font(.trendxCaption())
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(34)
        .background(TrendXTheme.elevatedSurface.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(TrendXTheme.outline.opacity(0.7), lineWidth: 0.8)
        )
    }
}

// MARK: - Mini Poll Card (for horizontal scroll)

struct MiniPollCard: View {
    let poll: Poll
    let onTap: () -> Void

    private var style: PollCoverStyle { poll.topicStyle }
    private var tint: Color { style.tint }

    private var hasImage: Bool {
        if let url = poll.imageURL, !url.isEmpty { return true }
        return false
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover strip — when the publisher uploaded an image we
                // showcase it as the top third of the card with the
                // topic chip overlaid on a dark gradient. Without an
                // image we fall through to the original topic chip
                // row so the card still reads cleanly.
                if hasImage {
                    ZStack(alignment: .bottomLeading) {
                        TrendXProfileImage(urlString: poll.imageURL) {
                            LinearGradient(
                                colors: style.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                        .frame(height: 84)
                        .clipped()

                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.50)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 84)
                        .allowsHitTesting(false)

                        HStack(spacing: 5) {
                            Image(systemName: style.glyph)
                                .font(.system(size: 9.5, weight: .heavy))
                            Text(poll.topicName ?? style.label)
                                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.18)))
                        .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 0.6))
                        .padding(10)
                    }
                    .frame(height: 84)
                    .clipped()
                }

                VStack(alignment: .leading, spacing: 10) {
                    if !hasImage {
                        // Topic chip + optional AI marker. The chip is the
                        // single source of topic identity on the mini card —
                        // we dropped the heavy leading gradient stripe so
                        // five stacked cards no longer look like a paint
                        // palette.
                        HStack(spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: style.glyph)
                                    .font(.system(size: 10, weight: .bold))
                                Text(poll.topicName ?? style.label)
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(tint)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(style.wash))
                            .overlay(Capsule().stroke(style.hairline, lineWidth: 0.6))

                            Spacer(minLength: 0)

                            if poll.aiInsight != nil {
                                HStack(spacing: 3) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("AI")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .tracking(0.3)
                                }
                                .foregroundStyle(TrendXTheme.aiIndigo)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                                .overlay(Capsule().stroke(TrendXTheme.aiIndigo.opacity(0.18), lineWidth: 0.8))
                            }
                        }
                    }

                    Text(poll.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(TrendXTheme.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(hasImage ? 2 : 3)
                        .lineSpacing(2)

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        Label("\(poll.totalVotes)", systemImage: "person.2.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)

                        HStack(spacing: 3) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(TrendXTheme.accent)
                            Text("+\(poll.rewardPoints)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(TrendXTheme.accentDeep)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(TrendXTheme.primaryGradient))
                            .shadow(color: TrendXTheme.primary.opacity(0.25), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, hasImage ? 12 : 16)
            }
            .frame(width: 248, height: 168)
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 0.8)
            )
            .shadow(color: TrendXTheme.shadow, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Bar

struct TrendXSearchBar: View {
    @Binding var text: String
    var placeholder: String = "البحث..."
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(TrendXTheme.tertiaryInk)
            
            TextField(placeholder, text: $text)
                .font(.trendxBody())
                .foregroundStyle(TrendXTheme.ink)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TrendXTheme.softFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}


// MARK: - Gift brand mark
//
// Renders the brand logo when available (`gift.brandLogo` URL), otherwise
// falls back to the brand monogram on a translucent disc.

struct GiftBrandMark: View {
    let gift: Gift
    var size: CGFloat = 48
    var monogramFont: CGFloat = 22

    private var logoURL: URL? {
        guard !gift.brandLogo.isEmpty else { return nil }
        return URL(string: gift.brandLogo)
    }

    var body: some View {
        Group {
            if let url = logoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(size * 0.18)
                    default:
                        monogramView
                    }
                }
                .frame(width: size, height: size)
                .background(Circle().fill(.white))
                .clipShape(Circle())
            } else {
                monogramView
            }
        }
    }

    private var monogramView: some View {
        ZStack {
            Circle().fill(.white.opacity(0.18))
            Text(gift.brandMonogram)
                .font(.system(size: monogramFont, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}



// MARK: - Gift social proof
//
// Picks a single badge per gift based on weekly redemption volume or how
// recently it was last redeemed. Returns nil when neither signal is
// strong enough to surface (we don't want to brag about cold inventory).

enum GiftSocialProof {
    struct Badge {
        let label: String
        let icon: String
        let tint: Color
    }

    static func badge(for gift: Gift) -> Badge? {
        if gift.weeklyRedemptions >= 5 {
            return Badge(
                label: "شائع هذا الأسبوع",
                icon: "flame.fill",
                tint: TrendXTheme.accent
            )
        }
        if gift.weeklyRedemptions >= 2 {
            return Badge(
                label: "\(gift.weeklyRedemptions) استبدلوها هذا الأسبوع",
                icon: "person.2.fill",
                tint: TrendXTheme.aiIndigo
            )
        }
        if let lastAt = gift.lastRedeemedAt {
            let minutes = Int(Date().timeIntervalSince(lastAt) / 60)
            if minutes < 60 {
                return Badge(label: "استُبدلت قبل \(max(minutes, 1)) دقيقة",
                             icon: "clock.fill",
                             tint: TrendXTheme.success)
            }
            let hours = minutes / 60
            if hours < 24 {
                return Badge(label: "استُبدلت قبل \(hours) ساعة",
                             icon: "clock.fill",
                             tint: TrendXTheme.success)
            }
        }
        return nil
    }
}
