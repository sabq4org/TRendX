package com.trendx.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.trendx.app.models.Gift
import com.trendx.app.models.Redemption
import com.trendx.app.models.Survey
import com.trendx.app.models.TrendXUser
import com.trendx.app.store.AppViewModel
import com.trendx.app.store.TabItem
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXTheme
import com.trendx.app.ui.components.BetaStatusBanner
import com.trendx.app.ui.components.TrendXTabBar
import com.trendx.app.ui.screens.AccountScreen
import com.trendx.app.ui.screens.GiftRedemptionSuccessSheet
import com.trendx.app.ui.screens.GiftsScreen
import com.trendx.app.ui.screens.HomeScreen
import com.trendx.app.ui.screens.PollAnalyticsScreen
import com.trendx.app.ui.screens.PollDetailNotFound
import com.trendx.app.ui.screens.PollDetailScreen
import com.trendx.app.ui.screens.PollsScreen
import com.trendx.app.ui.screens.account.MyInterestsScreen
import com.trendx.app.ui.screens.account.MyNetworkScreen
import com.trendx.app.ui.screens.account.MyPointsScreen
import com.trendx.app.ui.screens.account.MyRedemptionsScreen
import com.trendx.app.ui.screens.account.MyVotedPollsScreen
import com.trendx.app.ui.screens.account.ProfileEditScreen
import com.trendx.app.ui.screens.account.PublicProfileScreen
import com.trendx.app.ui.screens.auth.LoginScreen
import com.trendx.app.ui.screens.auth.WelcomeAfterSignUpScreen
import com.trendx.app.ui.screens.intelligence.NotificationsInboxScreen
import com.trendx.app.ui.screens.intelligence.OpinionDNAScreen
import com.trendx.app.ui.screens.intelligence.PredictionAccuracyScreen
import com.trendx.app.ui.screens.intelligence.PulseTodayScreen
import com.trendx.app.ui.screens.intelligence.TrendXIndexScreen
import com.trendx.app.ui.screens.intelligence.WeeklyChallengeScreen
import com.trendx.app.ui.screens.surveys.CreatePollSheet
import com.trendx.app.ui.screens.surveys.CreateSurveySheet
import com.trendx.app.ui.screens.surveys.SurveyDetailScreen
import com.trendx.app.ui.screens.surveys.SurveyTakingSheet

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TrendXTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = TrendXColors.Background
                ) {
                    val vm: AppViewModel = viewModel(factory = AppViewModel.Factory(applicationContext))
                    AppRoot(vm)
                }
            }
        }
    }
}

// Equivalent of TRENDX/ContentView.swift. Three top-level surfaces, in
// priority order: post-signup welcome → login sheet → tab interface.
// `isAuthenticated` is implicit on Android — the tab interface always
// renders; `isGuest` swaps the personalized chrome.
@Composable
private fun AppRoot(vm: AppViewModel) {
    val isGuest by vm.isGuest.collectAsState()
    val showWelcome by vm.showWelcomeAfterSignUp.collectAsState()
    val showLogin by vm.showLoginSheet.collectAsState()
    val selectedTab by vm.selectedTab.collectAsState()
    val user by vm.currentUser.collectAsState()
    val topics by vm.topics.collectAsState()
    val voiceLine by vm.voiceLine.collectAsState()
    val appMessage by vm.appMessage.collectAsState()

    Box(modifier = Modifier.fillMaxSize()) {
        when {
            showWelcome -> {
                val followed = topics.filter { it.isFollowing }
                WelcomeAfterSignUpScreen(
                    name = user.name,
                    interests = followed,
                    voiceLine = voiceLine,
                    onContinue = { vm.dismissWelcome() }
                )
            }
            showLogin -> LoginScreen(
                isRemoteEnabled = vm.isRemoteEnabled,
                onSignIn = { email, password, onError ->
                    vm.signIn(email, password) { onError(it) }
                },
                onSignUp = { name, email, password, gender, birthYear, city,
                              interests, voice, onError ->
                    val matchedTopicIds = topics
                        .filter { interests.contains(it.name) }
                        .map { it.id }
                    vm.signUp(
                        name = name, email = email, password = password,
                        gender = gender, birthYear = birthYear, city = city,
                        interestTopicIds = matchedTopicIds,
                        voiceLine = voice,
                        onError = onError
                    )
                },
                onContinueAsGuest = { vm.closeLoginSheet() }
            )
            else -> AuthedShell(
                vm = vm,
                selectedTab = selectedTab,
                isGuest = isGuest,
                onSignInTap = { vm.openLoginSheet() }
            )
        }

        AnimatedVisibility(
            visible = appMessage != null,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 12.dp)
        ) {
            appMessage?.let { msg ->
                BetaStatusBanner(message = msg, onDismiss = { vm.dismissAppMessage() })
            }
        }
    }
}

// Account sub-screen routes. Each sub-screen is rendered as a full-screen
// Surface overlay above the tab interface so dismissal returns to Account.
private enum class AccountSubRoute {
    EditProfile, Network, PublicProfile, OpinionDNA, Index, Accuracy,
    Redemptions, Points, VotedPolls, Interests
}

@Composable
private fun AuthedShell(
    vm: AppViewModel,
    selectedTab: TabItem,
    isGuest: Boolean,
    onSignInTap: () -> Unit
) {
    val user by vm.currentUser.collectAsState()
    val topics by vm.topics.collectAsState()
    val polls by vm.polls.collectAsState()
    val gifts by vm.gifts.collectAsState()
    val redemptions by vm.redemptions.collectAsState()
    val surveys by vm.surveys.collectAsState()

    var openPollId by remember { mutableStateOf<String?>(null) }
    var analyticsPollId by remember { mutableStateOf<String?>(null) }
    var accountRoute by remember { mutableStateOf<AccountSubRoute?>(null) }
    var giftToConfirm by remember { mutableStateOf<Gift?>(null) }
    var lastRedemption by remember { mutableStateOf<Redemption?>(null) }
    var openProfileFor by remember { mutableStateOf<TrendXUser?>(null) }
    var showPulse by remember { mutableStateOf(false) }
    var showWeekly by remember { mutableStateOf(false) }
    var showIndex by remember { mutableStateOf(false) }
    var showNotifications by remember { mutableStateOf(false) }
    var openSurvey by remember { mutableStateOf<Survey?>(null) }
    var takingSurvey by remember { mutableStateOf<Survey?>(null) }
    var showCreatePoll by remember { mutableStateOf(false) }
    var showCreateSurvey by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        when (selectedTab) {
            TabItem.Home -> HomeScreen(
                user = user,
                isGuest = isGuest,
                topics = topics,
                polls = polls,
                onSignInTap = onSignInTap,
                onCreatePollTap = {
                    if (isGuest) onSignInTap() else showCreatePoll = true
                },
                onOpenPoll = { poll -> openPollId = poll.id },
                onVote = { pollId, optionId, isPublic ->
                    if (isGuest) onSignInTap()
                    else vm.voteOnPoll(pollId, optionId, isPublic)
                },
                onShare = { pollId -> vm.sharePoll(pollId) },
                onBookmark = { pollId ->
                    if (isGuest) onSignInTap() else vm.toggleBookmark(pollId)
                },
                onRepost = { pollId, repost ->
                    if (isGuest) onSignInTap() else vm.toggleRepost(pollId, repost)
                },
                onFollowTopic = { topicId ->
                    if (isGuest) onSignInTap() else vm.toggleFollowTopic(topicId)
                },
                onOpenPulse = { showPulse = true },
                onOpenWeekly = { if (isGuest) onSignInTap() else showWeekly = true },
                onOpenIndex = { showIndex = true },
                onOpenNotifications = {
                    if (isGuest) onSignInTap() else showNotifications = true
                }
            )
            TabItem.Polls -> PollsScreen(
                polls = polls,
                surveys = surveys,
                isGuest = isGuest,
                onOpenPoll = { openPollId = it.id },
                onOpenSurvey = { openSurvey = it },
                onCreatePoll = { if (isGuest) onSignInTap() else showCreatePoll = true },
                onCreateSurvey = { if (isGuest) onSignInTap() else showCreateSurvey = true },
                onOpenCategoryInsight = {
                    vm.postAppMessage("مركز الذكاء القطاعي قيد الإنشاء.")
                }
            )
            TabItem.Gifts -> GiftsScreen(
                gifts = gifts,
                points = user.points,
                coins = user.coins,
                onOpenHistory = { accountRoute = AccountSubRoute.Redemptions },
                onSelectGift = { gift ->
                    if (isGuest) onSignInTap() else giftToConfirm = gift
                }
            )
            TabItem.Account -> AccountScreen(
                user = user,
                isGuest = isGuest,
                isRemoteEnabled = vm.isRemoteEnabled,
                topics = topics,
                redemptionCount = redemptions.size,
                lastRedemptionCode = redemptions.firstOrNull()?.code,
                onSignInTap = onSignInTap,
                onSignOut = {
                    accountRoute = null
                    vm.signOut()
                },
                onEditProfile = {
                    if (isGuest) onSignInTap() else accountRoute = AccountSubRoute.EditProfile
                },
                onOpenNetwork = { accountRoute = AccountSubRoute.Network },
                onOpenPublicProfile = { accountRoute = AccountSubRoute.PublicProfile },
                onOpenOpinionDNA = { accountRoute = AccountSubRoute.OpinionDNA },
                onOpenIndex = { accountRoute = AccountSubRoute.Index },
                onOpenPredictionAccuracy = { accountRoute = AccountSubRoute.Accuracy },
                onOpenRedemptions = { accountRoute = AccountSubRoute.Redemptions },
                onOpenPoints = { accountRoute = AccountSubRoute.Points },
                onOpenVotedPolls = { accountRoute = AccountSubRoute.VotedPolls },
                onOpenInterests = { accountRoute = AccountSubRoute.Interests }
            )
        }

        TrendXTabBar(
            selectedTab = selectedTab,
            onSelectTab = { vm.selectTab(it) },
            modifier = Modifier.align(Alignment.BottomCenter)
        )

        // Poll detail
        openPollId?.let { id ->
            val poll = polls.firstOrNull { it.id == id } ?: vm.pollById(id)
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = TrendXColors.Background
            ) {
                if (poll != null) {
                    PollDetailScreen(
                        poll = poll,
                        onClose = { openPollId = null },
                        onVote = { optionId, isPublic ->
                            if (isGuest) { openPollId = null; onSignInTap() }
                            else vm.voteOnPoll(poll.id, optionId, isPublic)
                        },
                        onShare = { vm.sharePoll(poll.id) },
                        onBookmark = {
                            if (isGuest) { openPollId = null; onSignInTap() }
                            else vm.toggleBookmark(poll.id)
                        },
                        onRepost = { repost ->
                            if (isGuest) { openPollId = null; onSignInTap() }
                            else vm.toggleRepost(poll.id, repost)
                        },
                        onShowAnalytics = { analyticsPollId = poll.id }
                    )
                } else {
                    PollDetailNotFound(onClose = { openPollId = null })
                }
            }
        }

        // Poll analytics overlay (above PollDetail).
        analyticsPollId?.let { id ->
            val poll = polls.firstOrNull { it.id == id } ?: vm.pollById(id)
            if (poll != null) {
                Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                    PollAnalyticsScreen(
                        poll = poll,
                        onClose = { analyticsPollId = null },
                        onShare = { vm.sharePoll(poll.id) }
                    )
                }
            } else {
                analyticsPollId = null
            }
        }

        // Account sub-screen overlays.
        accountRoute?.let { route ->
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                val close: () -> Unit = { accountRoute = null }
                when (route) {
                    AccountSubRoute.EditProfile -> ProfileEditScreen(
                        user = user,
                        onClose = close,
                        onSave = { name, email, handle, bio, city, country,
                                   gender, birthYear, accountType, avatarUrl, onError ->
                            vm.updateProfile(
                                name = name, email = email, handle = handle, bio = bio,
                                city = city, country = country,
                                gender = gender, birthYear = birthYear,
                                accountType = accountType, avatarUrl = avatarUrl,
                                onError = onError,
                                onSuccess = { accountRoute = null }
                            )
                        }
                    )
                    AccountSubRoute.Network -> MyNetworkScreen(
                        onClose = close,
                        fetchFollowing = { vm.fetchFollowing() },
                        fetchFollowers = { vm.fetchFollowers() },
                        onFollowToggle = { id, currentlyFollowing ->
                            vm.followUser(id, currentlyFollowing)
                        },
                        onOpenProfile = { selected ->
                            accountRoute = null
                            openProfileFor = selected
                        }
                    )
                    AccountSubRoute.PublicProfile -> PublicProfileScreen(
                        initialUser = user,
                        isViewerSelf = true,
                        onClose = close,
                        fetchUser = { idOrHandle -> vm.fetchUser(idOrHandle) },
                        fetchPosts = { idOrHandle -> vm.fetchUserPosts(idOrHandle) },
                        onFollowToggle = { id, cur -> vm.followUser(id, cur) },
                        onOpenPoll = { p ->
                            accountRoute = null
                            openPollId = p.id
                        }
                    )
                    AccountSubRoute.OpinionDNA -> OpinionDNAScreen(vm = vm, onClose = close)
                    AccountSubRoute.Index -> TrendXIndexScreen(vm = vm, onClose = close)
                    AccountSubRoute.Accuracy -> PredictionAccuracyScreen(vm = vm, onClose = close)
                    AccountSubRoute.Redemptions -> MyRedemptionsScreen(
                        redemptions = redemptions,
                        onClose = close
                    )
                    AccountSubRoute.Points -> MyPointsScreen(
                        points = user.points,
                        coins = user.coins,
                        onClose = close,
                        fetchLedger = { vm.fetchPointsLedger() }
                    )
                    AccountSubRoute.VotedPolls -> MyVotedPollsScreen(
                        polls = polls,
                        onClose = close,
                        onOpenPoll = { p ->
                            accountRoute = null
                            openPollId = p.id
                        }
                    )
                    AccountSubRoute.Interests -> MyInterestsScreen(
                        topics = topics,
                        onClose = close,
                        onFollowToggle = { vm.toggleFollowTopic(it) }
                    )
                }
            }
        }

        // Gift redemption confirmation
        giftToConfirm?.let { gift ->
            val canAfford = user.points >= gift.pointsRequired
            AlertDialog(
                onDismissRequest = { giftToConfirm = null },
                title = { Text("استبدال الهدية") },
                text = {
                    Text(
                        if (canAfford)
                            "${gift.brandName} — ${gift.name}\nتكلفة الاستبدال: ${gift.pointsRequired} نقطة (~${gift.valueInRiyal.toInt()} ر.س)."
                        else
                            "تحتاج ${gift.pointsRequired - user.points} نقطة إضافية لاستبدال هذه الهدية."
                    )
                },
                confirmButton = {
                    if (canAfford) {
                        TextButton(onClick = {
                            val r = vm.redeemGift(gift)
                            giftToConfirm = null
                            r?.let { lastRedemption = it }
                        }) { Text("استبدال") }
                    } else {
                        TextButton(onClick = { giftToConfirm = null }) { Text("حسناً") }
                    }
                },
                dismissButton = if (canAfford) {
                    {
                        TextButton(onClick = { giftToConfirm = null }) { Text("إلغاء") }
                    }
                } else null
            )
        }

        // Redemption success sheet — full-screen overlay above everything.
        lastRedemption?.let { redemption ->
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                GiftRedemptionSuccessSheet(
                    redemption = redemption,
                    remainingPoints = user.points,
                    onDismiss = { lastRedemption = null },
                    onShare = { vm.postAppMessage("شارك كود الهدية مع صديق.") }
                )
            }
        }

        // Profile of someone else — opened from MyNetwork rows + author
        // taps elsewhere. Navigates above account routes; close returns
        // to whichever screen launched it.
        openProfileFor?.let { target ->
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                PublicProfileScreen(
                    initialUser = target,
                    isViewerSelf = target.id == user.id,
                    onClose = { openProfileFor = null },
                    fetchUser = { idOrHandle -> vm.fetchUser(idOrHandle) },
                    fetchPosts = { idOrHandle -> vm.fetchUserPosts(idOrHandle) },
                    onFollowToggle = { id, cur -> vm.followUser(id, cur) },
                    onOpenPoll = { p ->
                        openProfileFor = null
                        openPollId = p.id
                    }
                )
            }
        }

        // Stage 2 intelligence-layer overlays.
        if (showPulse) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                PulseTodayScreen(vm = vm, onClose = { showPulse = false })
            }
        }
        if (showWeekly) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                WeeklyChallengeScreen(vm = vm, onClose = { showWeekly = false })
            }
        }
        if (showIndex) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                TrendXIndexScreen(vm = vm, onClose = { showIndex = false })
            }
        }
        if (showNotifications) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                NotificationsInboxScreen(vm = vm, onClose = { showNotifications = false })
            }
        }

        // Stage 3 — Surveys + Create sheets.
        openSurvey?.let { survey ->
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                SurveyDetailScreen(
                    survey = survey,
                    onClose = { openSurvey = null },
                    onStart = {
                        if (isGuest) { openSurvey = null; onSignInTap() }
                        else takingSurvey = survey
                    },
                    onOpenAnalytics = {
                        vm.postAppMessage("تحليل الاستبيان قيد الإنشاء.")
                    }
                )
            }
        }
        takingSurvey?.let { survey ->
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                SurveyTakingSheet(
                    survey = survey,
                    currentUserPoints = user.points,
                    onClose = { takingSurvey = null },
                    onSubmit = { answers, seconds ->
                        vm.submitSurveyResponse(
                            surveyId = survey.id,
                            answers = answers,
                            completionSeconds = seconds
                        )
                    }
                )
            }
        }
        if (showCreatePoll) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                CreatePollSheet(
                    topics = topics,
                    onClose = { showCreatePoll = false },
                    onPublish = { title, description, topicId, type, durationDays, options, onError ->
                        vm.createPoll(
                            title = title, description = description, topicId = topicId,
                            type = type, durationDays = durationDays, options = options,
                            onSuccess = { showCreatePoll = false },
                            onError = onError
                        )
                    }
                )
            }
        }
        if (showCreateSurvey) {
            Surface(modifier = Modifier.fillMaxSize(), color = TrendXColors.Background) {
                CreateSurveySheet(
                    onClose = { showCreateSurvey = false },
                    onPublish = { title, description, coverStyle, rewardPoints,
                                  durationDays, questions, onError ->
                        vm.createSurvey(
                            title = title, description = description, coverStyle = coverStyle,
                            rewardPoints = rewardPoints, durationDays = durationDays,
                            questions = questions,
                            onSuccess = { showCreateSurvey = false },
                            onError = onError
                        )
                    }
                )
            }
        }
    }
}
