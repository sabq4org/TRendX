//
//  AppStore.swift
//  TRENDX
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var currentUser: TrendXUser
    @Published var topics: [Topic]
    @Published var polls: [Poll]
    @Published var surveys: [Survey]
    @Published var gifts: [Gift]
    @Published var redemptions: [Redemption]
    /// Poll IDs the viewer has reposted — derived from `myRepostsKey`.
    /// Mirror-only state: views read from `poll.viewerReposted` (which
    /// `applyRepostFlags` keeps in sync) but the source of truth lives
    /// here so it survives any `polls` rewrite from the bootstrap.
    @Published private(set) var myRepostedPollIds: Set<UUID> = []
    @Published var selectedTab: TabItem = .home
    /// Monotonic counter incremented every time the user taps the
    /// already-selected Home tab. `HomeScreen` observes this through
    /// `.onChange` and uses it to scroll its `ScrollViewReader` back
    /// to the top — the standard "tap the active tab twice to jump
    /// home" gesture iOS users expect from a primary tab.
    @Published var homeScrollToTopTrigger: Int = 0
    @Published var showCreatePoll: Bool = false
    @Published var isAuthenticated: Bool
    @Published var isLoading: Bool = false
    @Published var appMessage: String? {
        didSet {
            // Auto-dismiss after 4s so transient banners like
            // "تم إنشاء كود تجريبي محلياً" don't hang at the top of the
            // app forever. Setting to nil cancels any pending dismissal.
            appMessageDismissTask?.cancel()
            guard appMessage != nil else { return }
            let captured = appMessage
            appMessageDismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self else { return }
                    if self.appMessage == captured { self.appMessage = nil }
                }
            }
        }
    }
    private var appMessageDismissTask: Task<Void, Never>?

    /// Set to `true` immediately after a successful first-time sign-up.
    /// `ContentView` uses this to overlay `WelcomeAfterSignUpScreen`
    /// (an AI-flavoured "preparing your TRENDX" greeting) before
    /// dropping the user into the regular tab interface.
    @Published var showWelcomeAfterSignUp: Bool = false

    /// Becomes true after `signOut()` — the user stays inside the main tab
    /// interface but the personalized chrome (greeting, points, profile)
    /// swaps to sign-in CTAs.
    @Published var isGuest: Bool = false
    /// Drives a sheet presentation of `LoginScreen` from anywhere in the
    /// authed shell (typically triggered by a guest-mode CTA).
    @Published var showLoginSheet: Bool = false

    private let userKey      = "trendx_user_v1"
    private let surveysKey   = "trendx_surveys_v1"
    private let topicsKey = "trendx_topics_v1"
    private let pollsKey = "trendx_polls_v1"
    private let redemptionsKey = "trendx_redemptions_v1"
    /// Local mirror of poll IDs the viewer has reposted. We persist this
    /// separately from the polls array because the `/bootstrap` response
    /// does not carry `viewer_reposted` per poll — without this set the
    /// repost flag would silently reset on every refresh and on app
    /// restart, even though the backend still has the record.
    private let myRepostsKey = "trendx_my_reposts_v1"
    private let client: TrendXAPIClient
    private let authRepository: AuthRepository
    private let pollRepository: PollRepository
    private let surveyRepository: SurveyRepository
    private let rewardsRepository: RewardsRepository
    private let aiRepository: AIRepository
    private var authSession: AuthSession?
    /// Timestamp of the last successful (or attempted) bootstrap. We
    /// throttle background refreshes — triggered by foreground
    /// transitions — to at most one per 90 seconds. Previously every
    /// app-resume kicked off a full /bootstrap which made even quick
    /// tab-out/tab-in flows feel laggy on slower networks.
    private var lastBootstrapAt: Date = .distantPast
    private let bootstrapThrottle: TimeInterval = 90

    /// Public read-only access to the live access token. Layer-3 screens
    /// (Pulse, DNA, Index, …) use this to call `TrendXAPIClient` directly
    /// for read-only intelligence endpoints.
    var accessToken: String? { authSession?.accessToken }
    var apiClient: TrendXAPIClient { client }

    var isRemoteEnabled: Bool {
        client.config.isConfigured
    }
    
    init(client: TrendXAPIClient = TrendXAPIClient()) {
        self.client = client
        self.authRepository = AuthRepository(client: client)
        self.pollRepository = PollRepository(client: client)
        self.surveyRepository = SurveyRepository(client: client)
        self.rewardsRepository = RewardsRepository(client: client)
        self.aiRepository = AIRepository(client: client)
        self.authSession = authRepository.restoreSession()
        // The app shell is always "authenticated" in the sense that we
        // show the tab interface — but when there is no real session we
        // run as a guest (read-only) until the user signs in.
        self.isAuthenticated = true
        self.isGuest = client.config.isConfigured && authSession == nil

        // Load user
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(TrendXUser.self, from: data) {
            self.currentUser = user
        } else {
            self.currentUser = TrendXUser(name: "علي", avatarInitial: "ع", points: 100, coins: 16.67)
        }
        
        // Load topics
        if let data = UserDefaults.standard.data(forKey: topicsKey),
           let topics = try? JSONDecoder().decode([Topic].self, from: data) {
            self.topics = topics
        } else {
            self.topics = Topic.samples
        }
        
        // Load polls — fallback to samples if empty or corrupt
        if let data = UserDefaults.standard.data(forKey: pollsKey),
           let polls = try? JSONDecoder().decode([Poll].self, from: data),
           !polls.isEmpty {
            self.polls = polls
        } else {
            self.polls = Poll.samples
            // persist samples so edits are saved
            if let encoded = try? JSONEncoder().encode(Poll.samples) {
                UserDefaults.standard.set(encoded, forKey: pollsKey)
            }
        }
        
        self.gifts = Gift.samples

        // Load surveys
        if let data = UserDefaults.standard.data(forKey: surveysKey),
           let saved = try? JSONDecoder().decode([Survey].self, from: data),
           !saved.isEmpty {
            self.surveys = saved
        } else {
            self.surveys = Survey.techSamples
            if let encoded = try? JSONEncoder().encode(Survey.techSamples) {
                UserDefaults.standard.set(encoded, forKey: surveysKey)
            }
        }

        if let data = UserDefaults.standard.data(forKey: redemptionsKey),
           let redemptions = try? JSONDecoder().decode([Redemption].self, from: data) {
            self.redemptions = redemptions
        } else {
            self.redemptions = []
        }

        if let data = UserDefaults.standard.data(forKey: myRepostsKey),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            self.myRepostedPollIds = ids
        }
        applyRepostFlags()
        reconcileFollowedTopicsFlags()

        if isAuthenticated {
            Task { await refreshBootstrap() }
        }
    }

    /// Stamp `viewerReposted` on every poll that the user has reposted
    /// locally. Call after any rewrite of `polls` — `init`, bootstrap
    /// refresh, or single-poll replace — so the UI stays consistent
    /// with the source-of-truth set.
    private func applyRepostFlags() {
        guard !myRepostedPollIds.isEmpty else { return }
        for index in polls.indices where myRepostedPollIds.contains(polls[index].id) {
            polls[index].viewerReposted = true
        }
    }

    /// Mirror `currentUser.followedTopics` onto each `topic.isFollowing`
    /// flag. Run after any rewrite of either array (bootstrap refresh,
    /// sign-in) so the UI shows the right state. The two stores are
    /// kept in lockstep on mutations via `toggleFollowTopic` — this
    /// only matters when the topics list is replaced wholesale.
    private func reconcileFollowedTopicsFlags() {
        let followed = Set(currentUser.followedTopics)
        for index in topics.indices {
            topics[index].isFollowing = followed.contains(topics[index].id)
        }
    }

    private func persistMyReposts() {
        if let data = try? JSONEncoder().encode(myRepostedPollIds) {
            UserDefaults.standard.set(data, forKey: myRepostsKey)
        }
    }

    // MARK: - Session

    func signIn(email: String, password: String) async {
        await authenticate {
            try await authRepository.signIn(email: email, password: password)
        }
        if isAuthenticated {
            isGuest = false
            showLoginSheet = false
        }
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        gender: UserGender = .unspecified,
        birthYear: Int? = nil,
        city: String? = nil,
        region: String? = nil
    ) async {
        isLoading = true
        appMessage = nil
        defer { isLoading = false }

        do {
            let session = try await authRepository.signUp(
                name: name,
                email: email,
                password: password,
                gender: gender,
                birthYear: birthYear,
                city: city,
                region: region
            )
            // Stage everything *before* the isAuthenticated flip so SwiftUI
            // batches all the state changes into a single render. Setting
            // showWelcomeAfterSignUp first guarantees ContentView never
            // sees `isAuthenticated == true` and `showWelcomeAfterSignUp ==
            // false` in the same frame, which is what caused the brief
            // flash of the main tab interface between sign-up and welcome.
            authSession = session
            currentUser.name = name
            currentUser.email = session.email.isEmpty ? email : session.email
            currentUser.avatarInitial = String(name.prefix(1))
            currentUser.gender = gender
            currentUser.birthYear = birthYear
            currentUser.city = city
            currentUser.region = region
            if isRemoteEnabled,
               let profile = try? await authRepository.fetchProfile(session: session) {
                currentUser = profile
            }
            persistUser()
            showWelcomeAfterSignUp = true
            isGuest = false
            isAuthenticated = true
            showLoginSheet = false
            await refreshBootstrap()
        } catch {
            appMessage = "تعذر تسجيل الدخول. تحقق من البيانات أو إعداد TRENDX API."
        }
    }

    func signOut() {
        authRepository.signOut()
        authSession = nil
        // After signing out we keep the user *inside* the app as a guest
        // instead of bouncing to the login screen — they continue to see
        // public content (Pulse, polls, gifts catalogue) with a sign-in
        // CTA replacing the personalized header.
        if isRemoteEnabled {
            isGuest = true
            isAuthenticated = true
            currentUser = TrendXUser()
        } else {
            // Offline build — nothing to "log out" from; stay authenticated.
            isGuest = false
            isAuthenticated = true
        }
        myRepostedPollIds.removeAll()
        persistMyReposts()
        appMessage = nil
        showWelcomeAfterSignUp = false
    }

    private func authenticate(_ operation: () async throws -> AuthSession) async {
        isLoading = true
        appMessage = nil
        defer { isLoading = false }

        do {
            let session = try await operation()
            authSession = session
            isAuthenticated = true
            currentUser.email = session.email
            if isRemoteEnabled, let profile = try? await authRepository.fetchProfile(session: session) {
                currentUser = profile
            }
            persistUser()
            await refreshBootstrap()
        } catch {
            appMessage = "تعذر تسجيل الدخول. تحقق من البيانات أو إعداد TRENDX API."
        }
    }

    /// Same as `refreshBootstrap()` but skips the call entirely if we
    /// already ran one recently. Use this from passive triggers like
    /// `scenePhase == .active` so a quick tab-out → tab-in doesn't
    /// kick off a full network round-trip. Pull-to-refresh and
    /// explicit user gestures should keep calling `refreshBootstrap()`.
    func refreshBootstrapIfStale() async {
        if Date().timeIntervalSince(lastBootstrapAt) < bootstrapThrottle {
            return
        }
        await refreshBootstrap()
    }

    func refreshBootstrap() async {
        lastBootstrapAt = Date()
        isLoading = true
        defer { isLoading = false }

        async let bootstrapTask = pollRepository.loadBootstrap(session: authSession)
        async let surveysTask = (try? surveyRepository.loadSurveys(session: authSession)) ?? []
        async let giftsTask = rewardsRepository.loadGifts(session: authSession)
        async let redemptionsTask = rewardsRepository.loadRedemptions(session: authSession)

        do {
            let bootstrap = try await bootstrapTask
            topics = bootstrap.topics
            // Topic.isFollowing is a per-viewer flag — the bootstrap
            // response can't carry it because /bootstrap is the same
            // payload for every caller. Reconcile here against the
            // current user's followedTopics so the UI matches what the
            // user actually follows. Without this, signing out and
            // back in (or any session restore) silently looked like
            // the user lost all their interests.
            reconcileFollowedTopicsFlags()
            polls = bootstrap.polls.isEmpty ? polls : bootstrap.polls
            let remoteSurveys = await surveysTask
            if !remoteSurveys.isEmpty {
                surveys = remoteSurveys
                persistSurveys()
            }
            gifts = await giftsTask
            redemptions = await redemptionsTask
            applyRepostFlags()
            persistTopics()
            persistPolls()
            persistRedemptions()
        } catch {
            appMessage = "تم تشغيل الوضع المحلي الاحتياطي مؤقتاً."
        }
    }
    
    // MARK: - User Actions
    
    func addPoints(_ amount: Int) {
        currentUser.points += amount
        currentUser.coins = Double(currentUser.points) / 6.0
        persistUser()
    }
    
    func deductPoints(_ amount: Int) -> Bool {
        guard currentUser.points >= amount else { return false }
        currentUser.points -= amount
        currentUser.coins = Double(currentUser.points) / 6.0
        persistUser()
        return true
    }
    
    // MARK: - Topic Actions
    
    func toggleFollowTopic(_ topicId: UUID) {
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            topics[index].isFollowing.toggle()
            if topics[index].isFollowing {
                topics[index].followersCount += 1
                if !currentUser.followedTopics.contains(topicId) {
                    currentUser.followedTopics.append(topicId)
                }
            } else {
                topics[index].followersCount = max(0, topics[index].followersCount - 1)
                currentUser.followedTopics.removeAll { $0 == topicId }
            }
            persistTopics()
            persistUser()
        }
    }
    
    var followedTopics: [Topic] {
        topics.filter { $0.isFollowing }
    }

    /// Update user profile fields against the backend and reflect the
    /// response locally. Throws on failure so the calling screen can show
    /// inline validation; on success returns the fresh user record.
    @discardableResult
    func updateProfile(
        name: String? = nil,
        email: String? = nil,
        handle: String? = nil,
        bio: String? = nil,
        avatarInitial: String? = nil,
        avatarUrl: String? = nil,
        bannerUrl: String? = nil,
        accountType: AccountType? = nil,
        gender: String? = nil,
        birthYear: Int? = nil,
        city: String? = nil,
        region: String? = nil,
        country: String? = nil
    ) async throws -> TrendXUser {
        guard let session = authSession, isRemoteEnabled else {
            // Apply locally so the offline flow still updates the UI.
            if let name { currentUser.name = name }
            if let email { currentUser.email = email }
            if let handle { currentUser.handle = handle }
            if let bio { currentUser.bio = bio }
            if let avatarInitial { currentUser.avatarInitial = avatarInitial }
            if let avatarUrl { currentUser.avatarUrl = avatarUrl }
            if let bannerUrl { currentUser.bannerUrl = bannerUrl }
            if let accountType { currentUser.accountType = accountType }
            if let gender, let g = UserGender(rawValue: gender) { currentUser.gender = g }
            if let birthYear { currentUser.birthYear = birthYear }
            if let city { currentUser.city = city }
            if let region { currentUser.region = region }
            if let country { currentUser.country = country }
            persistUser()
            return currentUser
        }
        let updated = try await authRepository.updateProfile(
            name: name,
            email: email,
            handle: handle,
            bio: bio,
            avatarInitial: avatarInitial,
            avatarUrl: avatarUrl,
            bannerUrl: bannerUrl,
            accountType: accountType,
            gender: gender,
            birthYear: birthYear,
            city: city,
            region: region,
            country: country,
            session: session
        )
        currentUser = updated
        persistUser()
        return updated
    }

    /// Check if a candidate @handle is available. Returns nil when free,
    /// or a human-readable Arabic error message when not.
    func checkHandleAvailability(_ candidate: String) async -> String? {
        guard let session = authSession, isRemoteEnabled else { return nil }
        return (try? await authRepository.checkHandleAvailability(candidate, session: session))
            ?? "تعذّر فحص المعرّف الآن — حاول مرة أخرى."
    }

    // MARK: - Follow / Unfollow

    /// Follow another user. Optimistic — updates `currentUser.followingCount`
    /// immediately, then reconciles with the backend response. Returns
    /// the latest viewer→target follow state so calling views can flip.
    @discardableResult
    func follow(userId: UUID) async -> Bool {
        guard let token = accessToken else { return false }
        currentUser.followingCount += 1
        persistUser()
        let result = (try? await apiClient.followUser(id: userId, accessToken: token))
        if result == nil {
            // Rollback on failure.
            currentUser.followingCount = max(0, currentUser.followingCount - 1)
            persistUser()
            return false
        }
        return true
    }

    @discardableResult
    func unfollow(userId: UUID) async -> Bool {
        guard let token = accessToken else { return false }
        currentUser.followingCount = max(0, currentUser.followingCount - 1)
        persistUser()
        let result = (try? await apiClient.unfollowUser(id: userId, accessToken: token))
        if result == nil {
            currentUser.followingCount += 1
            persistUser()
            return false
        }
        return true
    }

    func loadSuggestedFollows() async -> [TrendXUser] {
        guard let token = accessToken else { return [] }
        return (try? await apiClient.suggestedFollows(accessToken: token)) ?? []
    }

    /// Repost a poll to your followers' timelines (optimistic flip).
    /// On success surfaces a transient banner so the user knows where
    /// the repost just landed — their own profile + every follower's
    /// "الرادار" timeline.
    @discardableResult
    func repost(pollId: UUID) async -> Bool {
        guard let token = accessToken else { return false }
        myRepostedPollIds.insert(pollId)
        persistMyReposts()
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].viewerReposted = true
            polls[index].sharesCount += 1
            persistPolls()
        }
        let ok = (try? await apiClient.repostPoll(id: pollId, accessToken: token)) != nil
        if !ok {
            myRepostedPollIds.remove(pollId)
            persistMyReposts()
            if let index = polls.firstIndex(where: { $0.id == pollId }) {
                polls[index].viewerReposted = false
                polls[index].sharesCount = max(0, polls[index].sharesCount - 1)
                persistPolls()
            }
        } else {
            appMessage = "تمت إعادة النشر — ظاهرة في صفحتك وعند متابعيك."
        }
        return ok
    }

    @discardableResult
    func unrepost(pollId: UUID) async -> Bool {
        guard let token = accessToken else { return false }
        myRepostedPollIds.remove(pollId)
        persistMyReposts()
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].viewerReposted = false
            polls[index].sharesCount = max(0, polls[index].sharesCount - 1)
            persistPolls()
        }
        let ok = (try? await apiClient.unrepostPoll(id: pollId, accessToken: token)) != nil
        if !ok {
            myRepostedPollIds.insert(pollId)
            persistMyReposts()
            if let index = polls.firstIndex(where: { $0.id == pollId }) {
                polls[index].viewerReposted = true
                polls[index].sharesCount += 1
                persistPolls()
            }
        } else {
            appMessage = "تم إلغاء إعادة النشر."
        }
        return ok
    }

    func loadUserProfile(idOrHandle: String) async -> TrendXUser? {
        try? await apiClient.userProfile(idOrHandle: idOrHandle, accessToken: accessToken)
    }

    /// Apply onboarding extras gathered by the AI sign-up flow (preferred topics
    /// and a free-text "voice line"). Topics are merged into followedTopics and
    /// reflected in the local topics list so the UI updates immediately. The
    /// voice line is stored in UserDefaults under `trendx_onboarding_voice` and
    /// can later be sent to the backend profile endpoint.
    func applyOnboardingExtras(followedTopics topicIds: [UUID], voiceLine: String) {
        for topicId in topicIds {
            if !currentUser.followedTopics.contains(topicId) {
                currentUser.followedTopics.append(topicId)
            }
            if let index = topics.firstIndex(where: { $0.id == topicId }), !topics[index].isFollowing {
                topics[index].isFollowing = true
                topics[index].followersCount += 1
            }
        }
        persistUser()
        persistTopics()

        let trimmed = voiceLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: "trendx_onboarding_voice")
        } else {
            UserDefaults.standard.removeObject(forKey: "trendx_onboarding_voice")
        }
    }

    // MARK: - Poll Actions
    
    func voteOnPoll(_ pollId: UUID, optionId: UUID, isPublic: Bool = false) {
        guard let pollIndex = polls.firstIndex(where: { $0.id == pollId }),
              !polls[pollIndex].hasUserVoted else { return }
        
        polls[pollIndex].userVotedOptionId = optionId
        polls[pollIndex].totalVotes += 1
        
        if let optionIndex = polls[pollIndex].options.firstIndex(where: { $0.id == optionId }) {
            polls[pollIndex].options[optionIndex].votesCount += 1
        }
        
        // Recalculate percentages
        let total = polls[pollIndex].totalVotes
        for i in polls[pollIndex].options.indices {
            polls[pollIndex].options[i].percentage = Double(polls[pollIndex].options[i].votesCount) / Double(total) * 100
        }

        polls[pollIndex].aiInsight = TrendXAI.postVoteInsight(for: polls[pollIndex])
        
        addPoints(polls[pollIndex].rewardPoints)
        if !currentUser.completedPolls.contains(pollId) {
            currentUser.completedPolls.append(pollId)
        }
        persistPolls()

        guard isRemoteEnabled else { return }
        Task {
            do {
                let mutation = try await pollRepository.vote(
                    pollId: pollId,
                    optionId: optionId,
                    isPublic: isPublic,
                    session: authSession
                )
                replacePoll(mutation.poll.domain)
                currentUser = mutation.user.domain
                persistUser()
                persistPolls()
            } catch {
                appMessage = "تم حفظ التصويت محلياً، وستتم محاولة المزامنة لاحقاً."
            }
        }
    }
    
    func toggleBookmark(_ pollId: UUID) {
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].isBookmarked.toggle()
            persistPolls()
        }
    }

    func sharePoll(_ pollId: UUID) {
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].sharesCount += 1
            persistPolls()
        }
    }
    
    func createPoll(_ poll: Poll) {
        var newPoll = poll
        newPoll.authorName = currentUser.name
        newPoll.authorAvatar = currentUser.avatarInitial
        polls.insert(newPoll, at: 0)
        persistPolls()

        guard isRemoteEnabled else { return }
        Task {
            do {
                let remotePoll = try await pollRepository.createPoll(newPoll, session: authSession)
                replacePoll(remotePoll)
                persistPolls()
            } catch {
                appMessage = "تم نشر الاستطلاع محلياً، ولم تكتمل مزامنته بعد."
            }
        }
    }
    
    var activePolls: [Poll] {
        polls.filter { $0.status == .active && !$0.isExpired }
    }
    
    var completedPolls: [Poll] {
        polls.filter { $0.status == .completed || $0.isExpired || $0.hasUserVoted }
    }
    
    var latestPolls: [Poll] {
        Array(activePolls.prefix(5))
    }

    var votedPolls: [Poll] {
        polls.filter { $0.hasUserVoted }
    }

    var endedPolls: [Poll] {
        polls.filter { $0.status == .completed || $0.isExpired }
    }

    var smartFeedPolls: [Poll] {
        activePolls.sorted { lhs, rhs in
            score(for: lhs) > score(for: rhs)
        }
    }

    func poll(withId id: UUID) -> Poll? {
        polls.first { $0.id == id }
    }

    func redeemGift(_ gift: Gift) -> Redemption? {
        guard gift.isAvailable, deductPoints(gift.pointsRequired) else { return nil }
        let redemption = Redemption(
            giftId: gift.id,
            giftName: gift.name,
            brandName: gift.brandName,
            pointsSpent: gift.pointsRequired,
            valueInRiyal: gift.valueInRiyal
        )
        redemptions.insert(redemption, at: 0)
        persistRedemptions()

        guard isRemoteEnabled else { return redemption }
        Task {
            do {
                let mutation = try await rewardsRepository.redeem(gift, session: authSession)
                currentUser = mutation.user.domain
                redemptions.removeAll { $0.id == redemption.id }
                redemptions.insert(mutation.redemption.domain, at: 0)
                persistUser()
                persistRedemptions()
            } catch {
                appMessage = "تم إنشاء كود تجريبي محلياً، ولم تكتمل مزامنته بعد."
            }
        }
        return redemption
    }

    func giftRecommendationReason(for gift: Gift) -> String {
        TrendXAI.giftReason(gift: gift, userPoints: currentUser.points)
    }

    func composePoll(question: String, topicName: String?, type: PollType) async -> AIComposeResult {
        await aiRepository.composePoll(
            question: question,
            topicName: topicName,
            type: type,
            session: authSession
        )
    }

    func generateInsight(for poll: Poll) async -> String {
        await aiRepository.pollInsight(for: poll, session: authSession)
    }

    private func score(for poll: Poll) -> Int {
        var value = 0
        if let topicId = poll.topicId, currentUser.followedTopics.contains(topicId) { value += 70 }
        if let topicName = poll.topicName, topics.first(where: { $0.name == topicName && $0.isFollowing }) != nil { value += 60 }
        if !poll.hasUserVoted { value += 45 }
        if poll.isEndingSoon { value += 30 }
        value += min(poll.totalVotes, 120) / 4
        value += poll.aiInsight == nil ? 0 : 12
        return value
    }

    private func replacePoll(_ poll: Poll) {
        if let index = polls.firstIndex(where: { $0.id == poll.id }) {
            polls[index] = poll
        } else {
            polls.insert(poll, at: 0)
        }
    }

    private func replaceSurvey(_ survey: Survey) {
        if let index = surveys.firstIndex(where: { $0.id == survey.id }) {
            surveys[index] = survey
        } else {
            surveys.insert(survey, at: 0)
        }
    }

    // MARK: - Survey Actions

    /// Submit a respondent's answers to a survey. The optimistic
    /// counter bump is applied immediately; if the network call
    /// succeeds we award the survey reward and refresh the cached
    /// row. Failure is non-fatal — same offline-first contract as
    /// `voteOnPoll`.
    func submitSurveyResponse(
        surveyId: UUID,
        answers: [SurveyAnswerInput],
        completionSeconds: Int?
    ) {
        guard let surveyIndex = surveys.firstIndex(where: { $0.id == surveyId }) else { return }

        // Optimistic local update
        surveys[surveyIndex].totalResponses += 1
        let isComplete = answers.count >= surveys[surveyIndex].questions.count
        if isComplete {
            let total = surveys[surveyIndex].totalResponses
            let completes = Int((surveys[surveyIndex].completionRate / 100) * Double(total - 1)) + 1
            surveys[surveyIndex].completionRate = total > 0
                ? (Double(completes) / Double(total)) * 100
                : 0
        }
        persistSurveys()

        let reward = isComplete ? surveys[surveyIndex].rewardPoints : 0
        if reward > 0 {
            addPoints(reward)
        }

        guard isRemoteEnabled else { return }
        Task {
            do {
                _ = try await surveyRepository.submitResponse(
                    surveyId: surveyId,
                    answers: answers,
                    completionSeconds: completionSeconds,
                    session: authSession
                )
                if let fresh = try? await surveyRepository.loadSurvey(
                    id: surveyId,
                    session: authSession
                ) {
                    replaceSurvey(fresh)
                    persistSurveys()
                }
            } catch {
                appMessage = "تم حفظ إجاباتك محلياً، وستتم محاولة المزامنة لاحقاً."
            }
        }
    }

    /// Create a new survey from a domain Survey value (used by the
    /// CreateSurveySheet). Optimistically prepends to the local list
    /// then syncs with the backend.
    func createSurvey(_ survey: Survey) {
        var newSurvey = survey
        newSurvey.authorName = currentUser.name
        newSurvey.authorAvatar = currentUser.avatarInitial
        surveys.insert(newSurvey, at: 0)
        persistSurveys()

        guard isRemoteEnabled else { return }
        Task {
            do {
                let remote = try await surveyRepository.createSurvey(newSurvey, session: authSession)
                replaceSurvey(remote)
                persistSurveys()
            } catch {
                appMessage = "تم نشر الاستبيان محلياً، ولم تكتمل مزامنته بعد."
            }
        }
    }

    var activeSurveys: [Survey] {
        surveys.filter { $0.status == .active && !$0.isExpired }
    }

    func survey(withId id: UUID) -> Survey? {
        surveys.first { $0.id == id }
    }

    // MARK: - Persistence
    
    private func persistUser() {
        if let data = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }
    
    private func persistTopics() {
        if let data = try? JSONEncoder().encode(topics) {
            UserDefaults.standard.set(data, forKey: topicsKey)
        }
    }
    
    private func persistPolls() {
        if let data = try? JSONEncoder().encode(polls) {
            UserDefaults.standard.set(data, forKey: pollsKey)
        }
    }

    private func persistSurveys() {
        if let data = try? JSONEncoder().encode(surveys) {
            UserDefaults.standard.set(data, forKey: surveysKey)
        }
    }

    private func persistRedemptions() {
        if let data = try? JSONEncoder().encode(redemptions) {
            UserDefaults.standard.set(data, forKey: redemptionsKey)
        }
    }
}

// MARK: - Tab Items

enum TabItem: String, CaseIterable {
    case home = "الرئيسية"
    case polls = "الاستطلاعات"
    case gifts = "الهدايا"
    case account = "حسابي"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .polls: return "doc.text.fill"
        case .gifts: return "gift.fill"
        case .account: return "person.fill"
        }
    }
    
    var selectedIcon: String {
        icon
    }
}
