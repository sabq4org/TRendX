//
//  PublicProfileScreen.swift
//  TRENDX
//
//  Public profile view for any account type. The layout branches based
//  on `user.accountType`:
//    - individual:   round avatar, brand-gradient header, casual feel
//    - organization: squircle logo, amber accent, branded banner
//    - government:   formal Saudi-green frame, large institutional
//                    avatar, "العلامة الرسمية" eyebrow, Islamic-pattern
//                    overlay
//
//  Phase 1 surface only — follow/unfollow + activity list arrive in
//  Phase 2 and Phase 3 respectively. For now we render the visual
//  identity and a placeholder for what's coming.
//

import SwiftUI

struct PublicProfileScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let user: TrendXUser
    var loadFromBackend: Bool = false

    @State private var resolved: TrendXUser?
    @State private var isFollowing: Bool = false
    @State private var followersCount: Int = 0
    @State private var isFollowBusy: Bool = false

    private var current: TrendXUser { resolved ?? user }
    private var isSelf: Bool { current.id == store.currentUser.id }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                hero
                content
                Spacer(minLength: 60)
            }
        }
        .background(TrendXTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
        }
        .task { await refreshIfNeeded() }
    }

    // MARK: - Hero (branches by account type)

    @ViewBuilder
    private var hero: some View {
        switch current.accountType {
        case .individual:   individualHero
        case .organization: organizationHero
        case .government:   governmentHero
        }
    }

    private var individualHero: some View {
        VStack(spacing: 14) {
            AccountAvatar(user: current, size: 96)
                .padding(.top, 22)

            VStack(spacing: 6) {
                AccountNameRow(user: current, nameFont: .system(size: 22, weight: .black, design: .rounded), showHandle: false)
                if let handle = current.handle, !handle.isEmpty {
                    Text("@\(handle)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
            }

            if let bio = current.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
        .background(
            LinearGradient(
                colors: [
                    TrendXTheme.primary.opacity(0.10),
                    TrendXTheme.aiViolet.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var organizationHero: some View {
        VStack(spacing: 0) {
            // Banner — branded amber gradient with the org's name
            // overlaying a subtle dot grid. Replaced by `banner_url`
            // when one is uploaded.
            ZStack {
                if let url = current.bannerUrl.flatMap(URL.init(string:)) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            orgGoldFallback
                        }
                    }
                } else {
                    orgGoldFallback
                }
            }
            .frame(height: 130)
            .clipped()

            VStack(spacing: 12) {
                AccountAvatar(user: current, size: 88)
                    .offset(y: -48)
                    .padding(.bottom, -36)

                VStack(spacing: 4) {
                    AccountNameRow(user: current, nameFont: .system(size: 22, weight: .black, design: .rounded), showHandle: false)
                    if let handle = current.handle, !handle.isEmpty {
                        Text("@\(handle)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    Text(current.accountType.profileLabel)
                        .font(.system(size: 11, weight: .heavy))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(TrendXTheme.orgGoldWash))
                        .foregroundStyle(TrendXTheme.orgGold)
                }

                if let bio = current.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .lineSpacing(3)
                }
            }
            .padding(.bottom, 18)
        }
    }

    private var orgGoldFallback: some View {
        ZStack {
            TrendXTheme.orgGoldGradient
            Canvas { ctx, size in
                let spacing: CGFloat = 14
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    var y: CGFloat = 0
                    while y < size.height {
                        path.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                        y += spacing
                    }
                    x += spacing
                }
                ctx.fill(path, with: .color(.white.opacity(0.12)))
            }
        }
    }

    // MARK: - Government hero

    private var governmentHero: some View {
        VStack(spacing: 0) {
            // Saudi-green banner with the Islamic-style geometric overlay,
            // the institutional emblem centered, and the "العلامة الرسمية"
            // eyebrow stamped at the top.
            ZStack {
                if let url = current.bannerUrl.flatMap(URL.init(string:)) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            governmentBannerFallback
                        }
                    }
                } else {
                    governmentBannerFallback
                }
            }
            .frame(height: 220)
            .clipped()
            .overlay(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 10, weight: .heavy))
                    Text("العلامة الرسمية")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.18)))
                .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.8))
                .padding(.top, 12)
            }

            // The institutional info card slides up beneath the banner
            // (overlap by 28pt) so the avatar straddles the seam — gives
            // the page its formal, ministry-website feel.
            VStack(spacing: 14) {
                AccountAvatar(user: current, size: 100)
                    .offset(y: -50)
                    .padding(.bottom, -38)
                    .shadow(color: TrendXTheme.saudiGreen.opacity(0.25), radius: 14, x: 0, y: 8)

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(current.name)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(TrendXTheme.saudiGreenDeep)
                        AccountTypeBadge(type: .government, isVerified: true, size: 16)
                    }

                    if let handle = current.handle, !handle.isEmpty {
                        Text("@\(handle)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TrendXTheme.saudiGreen.opacity(0.7))
                    }

                    Text(current.accountType.profileLabel)
                        .font(.system(size: 11, weight: .heavy))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(TrendXTheme.saudiGreenWash))
                        .foregroundStyle(TrendXTheme.saudiGreenDeep)
                }

                if let bio = current.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13.5, weight: .medium, design: .serif))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 22)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(TrendXTheme.saudiGreen.opacity(0.20), lineWidth: 1)
                    )
                    .shadow(color: TrendXTheme.saudiGreen.opacity(0.12), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 14)
            .offset(y: -28)
            .padding(.bottom, -28)
        }
    }

    private var governmentBannerFallback: some View {
        ZStack {
            TrendXTheme.saudiGreenGradient

            // Islamic-style faint geometric overlay (8-point star tiling).
            Canvas { ctx, size in
                let spacing: CGFloat = 36
                var path = Path()
                var x: CGFloat = 0
                while x < size.width + spacing {
                    var y: CGFloat = 0
                    while y < size.height + spacing {
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + spacing / 2, y: y + spacing / 2))
                        path.move(to: CGPoint(x: x + spacing, y: y))
                        path.addLine(to: CGPoint(x: x + spacing / 2, y: y + spacing / 2))
                        y += spacing
                    }
                    x += spacing
                }
                ctx.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 0.6)
            }
            // The institutional emblem is carried by the AccountAvatar
            // (offset below the banner) so the banner stays a clean
            // patterned backdrop. No duplicated emblem anymore.
        }
    }

    // MARK: - Below-the-fold content

    private var content: some View {
        VStack(spacing: 18) {
            if !isSelf {
                followButton
                    .padding(.horizontal, 20)
                    .padding(.top, current.accountType == .government ? 36 : 8)
            }

            statsRow
                .padding(.horizontal, 20)
                .padding(.top, isSelf && current.accountType == .government ? 36 : 0)

            if current.accountType == .government {
                governmentPledge
                    .padding(.horizontal, 20)
            }

            comingSoonCard
                .padding(.horizontal, 20)
        }
    }

    private var followButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 8) {
                if isFollowBusy {
                    ProgressView()
                        .tint(isFollowing ? current.accountType.tint : .white)
                        .scaleEffect(0.85)
                }
                Image(systemName: isFollowing ? "checkmark" : "plus")
                    .font(.system(size: 13, weight: .heavy))
                Text(isFollowing ? "متابَع" : "متابعة")
                    .font(.system(size: 14, weight: .heavy))
            }
            .foregroundStyle(isFollowing ? current.accountType.tint : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isFollowing
                          ? AnyShapeStyle(current.accountType.wash)
                          : (current.accountType == .government
                             ? AnyShapeStyle(TrendXTheme.saudiGreenGradient)
                             : (current.accountType == .organization
                                ? AnyShapeStyle(TrendXTheme.orgGoldGradient)
                                : AnyShapeStyle(TrendXTheme.primaryGradient))))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(current.accountType.tint.opacity(isFollowing ? 0.32 : 0), lineWidth: 1)
                    )
            )
            .shadow(color: current.accountType.tint.opacity(isFollowing ? 0 : 0.30),
                    radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(isFollowBusy)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(label: "متابعون", value: shortNumber(followersCount), icon: "person.2.fill")
            statTile(label: "يتابع", value: shortNumber(current.followingCount), icon: "person.crop.circle.badge.checkmark")
            statTile(label: current.accountType == .individual ? "تصويتات" : "منشورات",
                     value: "\(current.completedPolls.count)",
                     icon: "doc.text.fill")
        }
    }

    private func shortNumber(_ n: Int) -> String {
        switch n {
        case ..<1_000:     return "\(n)"
        case ..<1_000_000:
            let v = Double(n) / 1_000
            return v < 10 ? String(format: "%.1fK", v) : String(format: "%.0fK", v)
        default:
            let v = Double(n) / 1_000_000
            return String(format: "%.1fM", v)
        }
    }

    private func toggleFollow() async {
        guard !isFollowBusy else { return }
        isFollowBusy = true
        defer { isFollowBusy = false }
        let wasFollowing = isFollowing
        // Optimistic flip.
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isFollowing.toggle()
            followersCount += wasFollowing ? -1 : 1
        }
        let success = wasFollowing
            ? await store.unfollow(userId: current.id)
            : await store.follow(userId: current.id)
        if !success {
            withAnimation { // Rollback on failure
                isFollowing = wasFollowing
                followersCount += wasFollowing ? 1 : -1
            }
        }
    }

    private func statTile(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(current.accountType.tint)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(current.accountType.wash)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(current.accountType.tint.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var governmentPledge: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(TrendXTheme.saudiGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("الحساب الرسمي")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.saudiGreenDeep)
                Text("جميع الاستطلاعات والاستبيانات المنشورة هنا صادرة عن الجهة المعتمدة. تخضع للنزاهة المؤسسية.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TrendXTheme.saudiGreenWash)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(TrendXTheme.saudiGreen.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(current.accountType.tint)
                Text("قريباً")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(current.accountType.tint)
            }
            Text("سترى هنا منشورات \(current.name) — استطلاعاتها، استبياناتها، فعالياتها — فور إطلاق الـTimeline.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(TrendXTheme.outline.opacity(0.5), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Data

    private func refreshIfNeeded() async {
        // Seed state from the user we were initialized with so the
        // button renders the right label immediately.
        if !isFollowBusy {
            isFollowing = current.viewerFollows
            followersCount = current.followersCount
        }

        guard loadFromBackend else { return }
        let key = user.handle ?? user.id.uuidString
        if let fresh = await store.loadUserProfile(idOrHandle: key) {
            resolved = fresh
            isFollowing = fresh.viewerFollows
            followersCount = fresh.followersCount
        }
    }
}
