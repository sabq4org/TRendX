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
    /// Set to `true` when the screen is presented inside a sheet so the
    /// trailing "إغلاق" button is rendered. The default (`false`) is the
    /// preferred path: push from a `NavigationStack` and let the native
    /// back chevron handle dismissal.
    var presentedAsSheet: Bool = false

    @State private var resolved: TrendXUser?
    @State private var isFollowing: Bool = false
    @State private var followersCount: Int = 0
    @State private var isFollowBusy: Bool = false
    @State private var posts: [ProfileActivity] = []
    @State private var isLoadingPosts: Bool = false
    @State private var events: [TrendXEvent] = []
    @State private var isLoadingEvents: Bool = false
    @State private var selectedEvent: TrendXEvent?

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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if presentedAsSheet {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق") { dismiss() }
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(TrendXTheme.primary)
                }
            }
        }
        .task {
            await refreshIfNeeded()
            await loadPosts()
            await loadEvents()
        }
        .sheet(item: $selectedEvent) { ev in
            NavigationStack {
                EventDetailScreen(event: ev, store: store)
                    .environmentObject(store)
            }
            .trendxRTL()
        }
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

    /// Floating back button rendered on top of the hero. Replaces the
    /// native navigation-bar chevron (we hide it via
    /// `.navigationBarBackButtonHidden`) so the action lives where the
    /// user's eye already is — on the brand banner. RTL note: the
    /// `topLeading` overlay anchors to the *right* side in our
    /// right-to-left layout, which matches the natural "back" direction.
    @ViewBuilder
    private var heroBackButton: some View {
        if !presentedAsSheet {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.black.opacity(0.32)))
                    .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 0.7))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.leading, 14)
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
        .overlay(alignment: .topLeading) { heroBackButton }
    }

    private var organizationHero: some View {
        VStack(spacing: 0) {
            // Banner — branded amber gradient with the org's name
            // overlaying a subtle dot grid. Replaced by `banner_url`
            // when one is uploaded.
            ZStack {
                TrendXProfileImage(urlString: current.bannerUrl) {
                    orgGoldFallback
                }
            }
            .frame(height: 130)
            .clipped()
            .overlay(alignment: .topLeading) { heroBackButton }

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
            // no eyebrow stamp — the verified-shield badge next to the
            // ministry name + the Saudi-green identity already telegraph
            // "official" without a redundant text label.
            ZStack {
                TrendXProfileImage(urlString: current.bannerUrl) {
                    governmentBannerFallback
                }
            }
            .frame(height: 220)
            .clipped()
            .overlay(alignment: .topLeading) { heroBackButton }

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

            if !events.isEmpty || isLoadingEvents {
                eventsSection
                    .padding(.top, 6)
            }

            postsSection
                .padding(.top, 6)
        }
    }

    // MARK: - Events section
    //
    // Only renders when the entity has at least one event published.
    // Tap opens the full `EventDetailScreen` sheet (with the Saudi-map
    // heatmap, RSVP button, etc.).

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(current.accountType.tint)
                Text("الفعاليات")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Spacer(minLength: 0)
                if isLoadingEvents {
                    ProgressView()
                        .tint(current.accountType.tint)
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(events) { event in
                        Button { selectedEvent = event } label: {
                            ProfileEventCard(event: event, tint: current.accountType.tint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Posts section

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(current.accountType.tint)
                Text("المنشورات وإعادات النشر")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Spacer(minLength: 0)
                if isLoadingPosts {
                    ProgressView()
                        .tint(current.accountType.tint)
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 20)

            if posts.isEmpty && !isLoadingPosts {
                postsEmptyState
                    .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(posts) { item in
                        postRow(for: item)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func postRow(for item: ProfileActivity) -> some View {
        let poll = item.poll.domain
        VStack(alignment: .leading, spacing: 8) {
            if item.kind == .repost {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 11, weight: .heavy))
                    Text("أعاد \(current.name) نشر هذا")
                        .font(.system(size: 11.5, weight: .heavy))
                    if let caption = item.caption, !caption.isEmpty {
                        Text("·")
                            .foregroundStyle(TrendXTheme.mutedInk)
                        Text(caption)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(TrendXTheme.aiViolet)
                .padding(.horizontal, 4)
            }

            PollCard(
                poll: poll,
                onVote: { _ in },
                onBookmark: {},
                onShare: {},
                onRepost: nil,
                onAuthorTap: nil
            )
            .allowsHitTesting(false)
        }
    }

    private var postsEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Text("لا توجد منشورات بعد")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
            }
            Text("سيظهر هنا كل ما ينشره \(current.name) من استطلاعات وإعادات نشر، فور وصوله.")
                .font(.system(size: 12, weight: .semibold))
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
            statTile(label: postsLabel, value: "\(postsCount)", icon: "doc.text.fill")
        }
    }

    /// Number to show in the third stat tile.
    ///
    /// Individuals: cast votes — `completedPolls.count` is correct
    /// because their profile activity is "what I voted on", not
    /// "what I published".
    ///
    /// Organizations & governments: published polls. The earlier
    /// version of this view reused `completedPolls.count` for every
    /// account type, which made the Ministry of Media's profile show
    /// "0 منشورات" even though three polls were seeded under its
    /// account — a published organization rarely *votes* on its own
    /// polls, so that counter stays at 0. Now we count the posts the
    /// profile actually surfaces (own polls only, no reposts).
    private var postsCount: Int {
        if current.accountType == .individual {
            return current.completedPolls.count
        }
        return posts.filter { $0.kind == .poll }.count
    }

    private var postsLabel: String {
        current.accountType == .individual ? "تصويتات" : "منشورات"
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

    // MARK: - Data

    private func loadPosts() async {
        guard let token = store.accessToken else { return }
        isLoadingPosts = true
        defer { isLoadingPosts = false }

        let key = current.handle ?? current.id.uuidString
        let backendPosts = (try? await store.apiClient.userPosts(idOrHandle: key, accessToken: token)) ?? []

        // Defensive merge with local state. Two scenarios this guards:
        //  1) Backend returns nothing (older deploy, transient error):
        //     show the profile owner's own polls *and* — when viewing
        //     our own profile — every repost we know about locally.
        //  2) Backend returns posts but doesn't yet include a fresh
        //     repost (e.g. the user tapped repost a moment ago and
        //     the backend's /users/:id/posts is cached or slow): we
        //     splice in the missing local reposts so the card the
        //     user just created appears immediately on their profile.
        let isViewingSelf = current.id == store.currentUser.id

        if backendPosts.isEmpty {
            var fallback: [ProfileActivity] = store.polls
                .filter { $0.publisherId == current.id }
                .map(ProfileActivity.fromLocalPoll)

            if isViewingSelf {
                for repostedId in store.myRepostedPollIds {
                    if let poll = store.polls.first(where: { $0.id == repostedId }) {
                        fallback.append(ProfileActivity.fromLocalRepost(poll))
                    }
                }
            }
            posts = fallback.sorted { $0.occurredAt > $1.occurredAt }
        } else if isViewingSelf {
            // Backend has data — splice in any locally-tracked reposts
            // it didn't return yet so the "just reposted" feedback is
            // never lost on the way back to the profile.
            let backendRepostedPollIds = Set(
                backendPosts
                    .filter { $0.kind == .repost }
                    .map(\.poll.id)
            )
            let missing = store.myRepostedPollIds.subtracting(backendRepostedPollIds)
            var combined = backendPosts
            for repostedId in missing {
                if let poll = store.polls.first(where: { $0.id == repostedId }) {
                    combined.append(ProfileActivity.fromLocalRepost(poll))
                }
            }
            posts = combined.sorted { $0.occurredAt > $1.occurredAt }
        } else {
            posts = backendPosts
        }
    }

    private func loadEvents() async {
        isLoadingEvents = true
        defer { isLoadingEvents = false }
        if let items = try? await store.apiClient.listEvents(
            publisherId: current.id,
            accessToken: store.accessToken
        ) {
            // Strict client-side filter — protects against an older
            // backend deploy that ignores `publisher_id` and returns
            // every event. Without this, the Ministry of Media's
            // press conference shows up on personal profiles, which is
            // a hard bug ("الفعاليات موجودة في كل الصفحات"). Belt and
            // suspenders: the new backend filters too, but the iOS
            // layer must not depend on a redeploy.
            events = items.filter { $0.publisher?.id == current.id }
        }
    }

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

// MARK: - Compact event card for the profile carousel

private struct ProfileEventCard: View {
    let event: TrendXEvent
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                statusDot
                Text(statusLabel)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(statusColor)
                Spacer(minLength: 0)
                if let cat = event.category, !cat.isEmpty {
                    Text(cat)
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(tint.opacity(0.12)))
                        .foregroundStyle(tint)
                }
            }

            Text(event.title)
                .font(.system(size: 13.5, weight: .heavy))
                .foregroundStyle(TrendXTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 4) {
                Label(formatStart(event.startsAt), systemImage: "calendar")
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                if let city = event.city {
                    Label(city, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10, weight: .heavy))
                Text("\(event.attendingCount) مشارك")
                    .font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(tint)
        }
        .padding(12)
        .frame(width: 220, height: 170, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(tint.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: TrendXTheme.shadow, radius: 8, x: 0, y: 3)
        )
    }

    private var statusLabel: String {
        switch event.status {
        case "live": return "مباشر"
        case "closed": return "منتهية"
        default: return "قريباً"
        }
    }

    private var statusColor: Color {
        switch event.status {
        case "live": return .red
        case "closed": return TrendXTheme.tertiaryInk
        default: return tint
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 6, height: 6)
    }

    private func formatStart(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.trendxFractional.date(from: iso)
            ?? ISO8601DateFormatter.trendxInternet.date(from: iso) else { return iso }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.dateFormat = "EEEE d MMM"
        return f.string(from: date)
    }
}
