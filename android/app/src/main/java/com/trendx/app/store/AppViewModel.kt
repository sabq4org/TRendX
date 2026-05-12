package com.trendx.app.store

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.trendx.app.models.Gift
import com.trendx.app.models.LedgerEntry
import com.trendx.app.models.Poll
import com.trendx.app.models.Redemption
import com.trendx.app.models.Topic
import com.trendx.app.models.TrendXUser
import com.trendx.app.networking.TrendXAPIClient
import com.trendx.app.repositories.AccountRepository
import com.trendx.app.repositories.AuthRepository
import com.trendx.app.repositories.AuthSession
import com.trendx.app.repositories.PollRepository
import com.trendx.app.repositories.ProfilePost
import com.trendx.app.repositories.SessionStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// Equivalent of TRENDX/Stores/AppStore.swift. We keep it intentionally
// thin for the first port — auth state, the four primary tabs, and the
// sample-backed collections so screens render offline. Layered repositories
// and per-domain refresh logic land in subsequent passes (PollRepository,
// SurveyRepository, RewardsRepository, AIRepository, …).
class AppViewModel(context: Context) : ViewModel() {
    private val appContext = context.applicationContext
    private val client = TrendXAPIClient()
    private val sessionStore = SessionStore(appContext)
    private val authRepository = AuthRepository(client, sessionStore)
    private val pollRepository = PollRepository(client)
    private val accountRepository = AccountRepository(client)

    private var session: AuthSession? = null

    /// True when a backend base URL is configured (always the case on
    /// release/debug builds — only false in test fixtures). Surfaced so
    /// the AccountScreen can show the sign-out button only when there's
    /// a real session to sign out of.
    val isRemoteEnabled: Boolean get() = client.config.isConfigured

    // The app shell is always "authenticated" in the same sense as iOS —
    // the tab interface always renders. `isGuest` distinguishes the
    // signed-in state from the read-only fallback.
    private val _isGuest = MutableStateFlow(true)
    val isGuest: StateFlow<Boolean> = _isGuest.asStateFlow()

    private val _showWelcomeAfterSignUp = MutableStateFlow(false)
    val showWelcomeAfterSignUp: StateFlow<Boolean> = _showWelcomeAfterSignUp.asStateFlow()

    private val _showLoginSheet = MutableStateFlow(false)
    val showLoginSheet: StateFlow<Boolean> = _showLoginSheet.asStateFlow()

    private val _selectedTab = MutableStateFlow(TabItem.Home)
    val selectedTab: StateFlow<TabItem> = _selectedTab.asStateFlow()

    private val _currentUser = MutableStateFlow(
        TrendXUser(
            id = "00000000-0000-0000-0000-000000000001",
            name = "ضيف",
            avatarInitial = "ض"
        )
    )
    val currentUser: StateFlow<TrendXUser> = _currentUser.asStateFlow()

    private val _topics = MutableStateFlow(Topic.samples)
    val topics: StateFlow<List<Topic>> = _topics.asStateFlow()

    private val _polls = MutableStateFlow(Poll.samples)
    val polls: StateFlow<List<Poll>> = _polls.asStateFlow()

    private val _gifts = MutableStateFlow(Gift.samples)
    val gifts: StateFlow<List<Gift>> = _gifts.asStateFlow()

    private val _redemptions = MutableStateFlow<List<Redemption>>(emptyList())
    val redemptions: StateFlow<List<Redemption>> = _redemptions.asStateFlow()

    private val _appMessage = MutableStateFlow<String?>(null)
    val appMessage: StateFlow<String?> = _appMessage.asStateFlow()

    init {
        viewModelScope.launch {
            session = authRepository.restoreSession()
            _isGuest.value = client.config.isConfigured && session == null
            session?.let { refreshProfile(it) }
            // Always pull /bootstrap on launch — works for both authed and
            // guest sessions, returns at least the public topics + polls so
            // the Home + Polls feeds show real backend content even before
            // the user signs in. Falls back to samples if the network fails.
            refreshBootstrap()
        }
    }

    /// Pulls topics + polls from `GET /bootstrap` and replaces the local
    /// snapshots. The endpoint is auth-protected (every Railway API route
    /// except /auth, /health, /public, /pulse/today/anon, /embed sits
    /// behind a JWT middleware), so we skip the call entirely for guests
    /// and stay on the bundled `Topic.samples` / `Poll.samples`. Once the
    /// user signs in, this gets called from `signIn` / `signUp` and the
    /// real Railway content replaces the samples in one frame.
    fun refreshBootstrap() {
        val s = session
        if (s == null || !pollRepository.isRemoteEnabled) {
            android.util.Log.i(
                "TrendXBootstrap",
                "Skipping /bootstrap — guest mode (sign in to load real polls)"
            )
            return
        }
        viewModelScope.launch {
            android.util.Log.i("TrendXBootstrap", "Starting /bootstrap fetch as ${s.email}")
            try {
                val bootstrap = pollRepository.loadBootstrap(s)
                if (bootstrap.topics.isNotEmpty()) _topics.value = bootstrap.topics
                if (bootstrap.polls.isNotEmpty()) _polls.value = bootstrap.polls
                android.util.Log.i(
                    "TrendXBootstrap",
                    "Loaded ${bootstrap.polls.size} polls, ${bootstrap.topics.size} topics"
                )
            } catch (t: Throwable) {
                android.util.Log.e("TrendXBootstrap", "Bootstrap failed: ${t.message}", t)
                val detail = (t.message ?: "خطأ غير معروف").take(120)
                postAppMessage("تعذّر تحميل /bootstrap: $detail")
            }
        }
    }

    /// Lookup a poll by id from the cached snapshot. Used by detail screens
    /// that get the id via navigation rather than the full Poll instance.
    fun pollById(id: String): Poll? = _polls.value.firstOrNull { it.id == id }

    fun selectTab(tab: TabItem) { _selectedTab.value = tab }
    fun openLoginSheet() { _showLoginSheet.value = true }
    fun closeLoginSheet() { _showLoginSheet.value = false }
    fun dismissAppMessage() { _appMessage.value = null }
    fun dismissWelcome() { _showWelcomeAfterSignUp.value = false }
    fun postAppMessage(message: String) { _appMessage.value = message }

    /// Optimistic vote with real backend round-trip. We flip the local poll
    /// instantly so the UI feels responsive, then call `/polls/vote` on the
    /// backend. The server's authoritative response replaces the optimistic
    /// row, the user's points + coins are updated from the response payload,
    /// and an AI insight (if any) is folded into the poll. On failure the
    /// optimistic write is rolled back.
    fun voteOnPoll(pollId: String, optionId: String, isPublic: Boolean) {
        val previous = _polls.value
        _polls.value = previous.map { poll ->
            if (poll.id != pollId || poll.hasUserVoted) poll else {
                val updatedOptions = poll.options.map { o ->
                    if (o.id == optionId) o.copy(votesCount = o.votesCount + 1) else o
                }
                val newTotal = poll.totalVotes + 1
                val withPercents = updatedOptions.map { o ->
                    o.copy(percentage = if (newTotal == 0) 0.0 else o.votesCount * 100.0 / newTotal)
                }
                poll.copy(
                    options = withPercents,
                    totalVotes = newTotal,
                    userVotedOptionId = optionId
                )
            }
        }
        val s = session
        if (s == null || !pollRepository.isRemoteEnabled) {
            postAppMessage(
                if (isPublic) "شكراً — رأيك ظاهر لمتابعيك الآن."
                else "سُجِّل تصويتك بشكل خاص."
            )
            return
        }
        viewModelScope.launch {
            try {
                val outcome = pollRepository.vote(pollId, optionId, isPublic, s)
                _polls.value = _polls.value.map { p ->
                    if (p.id == pollId) outcome.poll.copy(
                        aiInsight = outcome.insight ?: outcome.poll.aiInsight
                    ) else p
                }
                outcome.user?.let { _currentUser.value = it }
                postAppMessage("+${outcome.poll.rewardPoints} نقطة. شكراً لمشاركتك!")
            } catch (t: Throwable) {
                _polls.value = previous
                val msg = t.message?.takeIf { it.isNotBlank() } ?: "تعذّر تسجيل التصويت"
                postAppMessage(msg)
            }
        }
    }

    fun toggleBookmark(pollId: String) {
        _polls.value = _polls.value.map { p ->
            if (p.id == pollId) p.copy(isBookmarked = !p.isBookmarked) else p
        }
    }

    fun sharePoll(pollId: String) {
        postAppMessage("تم نسخ رابط الاستطلاع.")
    }

    fun toggleRepost(pollId: String, repost: Boolean) {
        val previous = _polls.value
        _polls.value = previous.map { p ->
            if (p.id == pollId) p.copy(
                viewerReposted = repost,
                repostsCount = (p.repostsCount + if (repost) 1 else -1).coerceAtLeast(0)
            ) else p
        }
        val s = session ?: return
        if (!pollRepository.isRemoteEnabled) return
        viewModelScope.launch {
            val ok = pollRepository.setReposted(pollId, repost, s)
            if (!ok) _polls.value = previous
        }
    }

    fun toggleFollowTopic(topicId: String) {
        _topics.value = _topics.value.map { t ->
            if (t.id == topicId) t.copy(
                isFollowing = !t.isFollowing,
                followersCount = (t.followersCount + if (!t.isFollowing) 1 else -1).coerceAtLeast(0)
            ) else t
        }
    }

    /// Locally redeem a gift — deducts the points, generates a code, and
    /// pushes a Redemption onto the in-memory history. Returns the new
    /// redemption (or null if the user can't afford it). Real backend
    /// wiring (POST /rewards/redeem) lands in a follow-up pass; for now
    /// the UI shows the success sheet either way.
    fun redeemGift(gift: Gift): Redemption? {
        if (_currentUser.value.points < gift.pointsRequired) {
            postAppMessage("نقاطك أقل من المطلوب لهذه الهدية.")
            return null
        }
        val redemption = Redemption.fromGift(gift)
        _redemptions.value = listOf(redemption) + _redemptions.value
        _currentUser.value = _currentUser.value.let { u ->
            val newPoints = (u.points - gift.pointsRequired).coerceAtLeast(0)
            u.copy(points = newPoints, coins = newPoints / 6.0)
        }
        return redemption
    }

    // ---- Account sub-screen suspend fetches (called from LaunchedEffect) ----

    suspend fun fetchPointsLedger(): List<LedgerEntry>? {
        val s = session ?: return null
        return runCatching {
            accountRepository.pointsLedger(s).map { dto ->
                LedgerEntry(
                    id = dto.id,
                    amount = dto.amount,
                    type = dto.type,
                    refType = dto.refType,
                    refId = dto.refId,
                    description = dto.description,
                    balanceAfter = dto.balanceAfter,
                    createdAt = dto.createdAt?.let {
                        runCatching { kotlinx.datetime.Instant.parse(it) }.getOrNull()
                    }
                )
            }
        }.getOrNull()
    }

    suspend fun fetchFollowing(): List<TrendXUser>? {
        val s = session ?: return null
        return runCatching { accountRepository.following(s) }.getOrNull()
    }

    suspend fun fetchFollowers(): List<TrendXUser>? {
        val s = session ?: return null
        return runCatching { accountRepository.followers(s) }.getOrNull()
    }

    suspend fun fetchUser(idOrHandle: String): TrendXUser? =
        accountRepository.loadUser(idOrHandle, session)

    suspend fun fetchUserPosts(idOrHandle: String): List<ProfilePost>? {
        val s = session ?: return null
        return runCatching { accountRepository.loadUserPosts(idOrHandle, s) }.getOrNull()
    }

    suspend fun followUser(targetUserId: String, currentlyFollowing: Boolean): Boolean {
        val s = session ?: return false
        return if (currentlyFollowing) accountRepository.unfollow(targetUserId, s)
        else accountRepository.follow(targetUserId, s)
    }

    /// Push edits to `/profile`. Optimistically updates `currentUser` so
    /// the UI flips immediately; rolls back on failure. iOS exposes the
    /// same set of editable fields — name, email, handle, bio, city,
    /// country, gender, birthYear, accountType, and an avatar (uploaded
    /// as a `data:image/jpeg;base64,…` URL).
    fun updateProfile(
        name: String,
        email: String,
        handle: String?,
        bio: String?,
        city: String?,
        country: String?,
        gender: String?,
        birthYear: Int?,
        accountType: String?,
        avatarUrl: String?,
        onError: (String) -> Unit,
        onSuccess: () -> Unit
    ) {
        val s = session
        if (s == null) {
            onError("لازم تسجّل دخول لتعديل ملفك.")
            return
        }
        val previous = _currentUser.value
        val parsedGender = gender?.let {
            runCatching { com.trendx.app.models.UserGender.valueOf(it) }.getOrNull()
        }
        val parsedAccount = accountType?.let {
            runCatching { com.trendx.app.models.AccountType.valueOf(it) }.getOrNull()
        }
        _currentUser.value = previous.copy(
            name = name,
            email = email,
            handle = handle,
            bio = bio,
            city = city,
            avatarUrl = avatarUrl ?: previous.avatarUrl,
            gender = parsedGender ?: previous.gender,
            birthYear = birthYear ?: previous.birthYear,
            country = country ?: previous.country,
            accountType = parsedAccount ?: previous.accountType
        )
        viewModelScope.launch {
            try {
                val updated = authRepository.updateProfile(
                    name = name, email = email, handle = handle, bio = bio,
                    city = city, country = country,
                    gender = gender, birthYear = birthYear,
                    accountType = accountType, avatarUrl = avatarUrl,
                    session = s
                )
                _currentUser.value = updated
                postAppMessage("تم حفظ التعديلات.")
                onSuccess()
            } catch (t: Throwable) {
                _currentUser.value = previous
                val msg = t.message?.takeIf { it.isNotBlank() } ?: "تعذّر حفظ التعديلات"
                onError(msg)
            }
        }
    }

    fun signIn(email: String, password: String, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                val newSession = authRepository.signIn(email, password)
                session = newSession
                _isGuest.value = false
                _showLoginSheet.value = false
                refreshProfile(newSession)
                refreshBootstrap()
            } catch (t: Throwable) {
                onError(t.message ?: "تعذّر تسجيل الدخول")
            }
        }
    }

    fun signUp(
        name: String,
        email: String,
        password: String,
        gender: com.trendx.app.models.UserGender = com.trendx.app.models.UserGender.unspecified,
        birthYear: Int? = null,
        city: String? = null,
        interestTopicIds: List<String> = emptyList(),
        voiceLine: String? = null,
        onError: (String) -> Unit,
        onSuccess: () -> Unit = {}
    ) {
        viewModelScope.launch {
            try {
                val newSession = authRepository.signUp(
                    name = name, email = email, password = password,
                    gender = gender, birthYear = birthYear, city = city
                )
                session = newSession
                // Match iOS ordering — flip welcome BEFORE flipping guest
                // so the Compose recomposition lands both in one frame
                // and the tab interface never flashes through.
                _showWelcomeAfterSignUp.value = true
                _isGuest.value = false
                _showLoginSheet.value = false
                refreshProfile(newSession)
                refreshBootstrap()
                // Apply on-device extras (followed topics + voice line) so
                // the welcome screen and the home feed reflect the chips
                // the user picked during sign-up. Backend topic-follow
                // wiring lands in a follow-up pass.
                if (interestTopicIds.isNotEmpty()) {
                    _topics.value = _topics.value.map { t ->
                        if (t.id in interestTopicIds) t.copy(isFollowing = true) else t
                    }
                    _currentUser.value = _currentUser.value.copy(
                        followedTopics = interestTopicIds
                    )
                }
                _voiceLine.value = voiceLine?.takeIf { it.isNotBlank() }
                onSuccess()
            } catch (t: Throwable) {
                onError(t.message ?: "تعذّر إنشاء الحساب")
            }
        }
    }

    /// On-device tagline the user can optionally pick during sign-up
    /// ("في كلمة واحدة، ما يهمّك هذا العام؟"). Surfaces back on the
    /// welcome screen as a personalised AI quote.
    private val _voiceLine = MutableStateFlow<String?>(null)
    val voiceLine: StateFlow<String?> = _voiceLine.asStateFlow()

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
            session = null
            _isGuest.value = true
            _currentUser.value = TrendXUser(
                id = "00000000-0000-0000-0000-000000000001",
                name = "ضيف",
                avatarInitial = "ض"
            )
        }
    }

    private suspend fun refreshProfile(session: AuthSession) {
        if (!client.config.isConfigured) return
        runCatching { authRepository.fetchProfile(session) }
            .onSuccess { _currentUser.value = it }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            require(modelClass.isAssignableFrom(AppViewModel::class.java)) {
                "Unknown ViewModel class: ${modelClass.name}"
            }
            return AppViewModel(context) as T
        }
    }
}
