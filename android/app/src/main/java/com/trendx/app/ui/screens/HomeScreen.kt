package com.trendx.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.trendx.app.models.Poll
import com.trendx.app.models.Topic
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.ui.components.AIBriefCard
import com.trendx.app.ui.components.DailyBonusCard
import com.trendx.app.ui.components.EventsHomeEntry
import com.trendx.app.ui.components.HomeHeader
import com.trendx.app.ui.components.HomeMomentumStrip
import com.trendx.app.ui.components.MiniPollCard
import com.trendx.app.ui.components.PollCard
import com.trendx.app.ui.components.PulseHomeCard
import com.trendx.app.ui.components.SectionHeader
import com.trendx.app.ui.components.TopicFilterChip
import com.trendx.app.ui.components.TopicRow
import com.trendx.app.ui.components.TrendXFAB
import com.trendx.app.ui.components.TrendXIndexHomeCard
import com.trendx.app.ui.components.TrendXSearchBar
import com.trendx.app.ui.components.TrendXSegmentedControl
import com.trendx.app.ui.components.WeeklyChallengeHomeCard

// Faithful Compose port of TRENDX/Screens/HomeScreen.swift. Same layout
// the iOS app ships: header → search → segmented control → posts content
// (radar / suggested-follows / events / daily bonus / pulse / AI brief /
// weekly challenge / national index / momentum strip / trends carousel /
// community feed) OR topics content. FAB pinned bottom-trailing.
@Composable
fun HomeScreen(
    user: TrendXUser,
    isGuest: Boolean,
    topics: List<Topic>,
    polls: List<Poll>,
    onSignInTap: () -> Unit,
    onCreatePollTap: () -> Unit,
    onOpenPoll: (Poll) -> Unit,
    onVote: (pollId: String, optionId: String, isPublic: Boolean) -> Unit,
    onShare: (pollId: String) -> Unit,
    onBookmark: (pollId: String) -> Unit,
    onRepost: (pollId: String, repost: Boolean) -> Unit,
    onFollowTopic: (topicId: String) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedSegment by remember { mutableIntStateOf(0) }
    var searchText by remember { mutableStateOf("") }
    var selectedFollowedOnly by remember { mutableStateOf(false) }

    val activePolls = remember(polls) { polls.filter { !it.isExpired } }
    val latestPolls = remember(polls) { polls.take(6) }
    val feedPolls = remember(polls, searchText) {
        if (searchText.isBlank()) polls
        else polls.filter {
            it.title.contains(searchText, ignoreCase = true) ||
                (it.topicName?.contains(searchText, ignoreCase = true) ?: false) ||
                it.authorName.contains(searchText, ignoreCase = true)
        }
    }
    val displayedTopics = remember(topics, searchText, selectedFollowedOnly) {
        val base = if (selectedFollowedOnly) topics.filter { it.isFollowing } else topics
        if (searchText.isBlank()) base
        else base.filter { it.name.contains(searchText, ignoreCase = true) }
    }

    val brief = remember(activePolls.size, topics.size) {
        TrendXAI.dailyBrief(activePollCount = activePolls.size, topicsCount = topics.size)
    }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = 0.dp, bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            item("home-header") {
                HomeHeader(
                    userName = user.name,
                    points = user.points,
                    coins = user.coins,
                    avatarUrl = user.avatarUrl,
                    isGuest = isGuest,
                    onSignInTap = onSignInTap,
                    onNotificationsTap = { /* TODO: notifications inbox */ },
                    onSearchTap = { selectedSegment = 0 },
                    onTimelineTap = if (isGuest) null else { { /* TODO: timeline */ } }
                )
            }

            if (selectedSegment == 0) {
                item("search-bar") {
                    TrendXSearchBar(
                        text = searchText,
                        onTextChange = { searchText = it },
                        placeholder = "ابحث في الرادار أو اسأل TRENDX AI…",
                        modifier = Modifier.padding(horizontal = 20.dp)
                    )
                }
            }

            item("segmented") {
                TrendXSegmentedControl(
                    selectedIndex = selectedSegment,
                    titles = listOf("المنشورات", "المواضيع"),
                    onSelect = { selectedSegment = it }
                )
            }

            if (selectedSegment == 0) {
                postsContent(
                    isGuest = isGuest,
                    polls = polls,
                    activePolls = activePolls,
                    latestPolls = latestPolls,
                    feedPolls = feedPolls,
                    topicsCount = topics.size,
                    points = user.points,
                    brief = brief,
                    onOpenPoll = onOpenPoll,
                    onVote = onVote,
                    onShare = onShare,
                    onBookmark = onBookmark,
                    onRepost = onRepost
                )
            } else {
                topicsContent(
                    topics = displayedTopics,
                    selectedFollowedOnly = selectedFollowedOnly,
                    onSelectAll = { selectedFollowedOnly = false },
                    onSelectFollowed = { selectedFollowedOnly = true },
                    onFollowTopic = onFollowTopic
                )
            }
        }

        // FAB lives above the tab bar (~110dp) and the bottom edge.
        TrendXFAB(
            onClick = onCreatePollTap,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 20.dp, bottom = 110.dp)
        )
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.postsContent(
    isGuest: Boolean,
    polls: List<Poll>,
    activePolls: List<Poll>,
    latestPolls: List<Poll>,
    feedPolls: List<Poll>,
    topicsCount: Int,
    points: Int,
    brief: TrendXAI.AIBrief,
    onOpenPoll: (Poll) -> Unit,
    onVote: (String, String, Boolean) -> Unit,
    onShare: (String) -> Unit,
    onBookmark: (String) -> Unit,
    onRepost: (String, Boolean) -> Unit
) {
    if (!isGuest) {
        item("events-entry") { EventsHomeEntry(onClick = { /* TODO: events */ }) }
    }
    item("daily-bonus") {
        DailyBonusCard(
            canClaim = !isGuest, currentStreak = 3, nextReward = 12,
            onClaim = { /* TODO: claim */ }
        )
    }
    item("pulse-card") { PulseHomeCard(onClick = { /* TODO: pulse */ }) }
    item("ai-brief") { AIBriefCard(brief = brief) }
    item("weekly-challenge") { WeeklyChallengeHomeCard(onClick = { /* TODO */ }) }
    item("trendx-index") { TrendXIndexHomeCard(onClick = { /* TODO: index */ }) }
    item("momentum-strip") {
        HomeMomentumStrip(
            activeCount = activePolls.size,
            topicsCount = topicsCount,
            points = points
        )
    }

    item("trends-header") {
        SectionHeader(
            title = "اتجاهات اليوم",
            subtitle = TrendXAI.trendingSubtitle
        )
    }
    item("trends-row") {
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(horizontal = 20.dp)
        ) {
            items(latestPolls, key = { it.id }) { poll ->
                MiniPollCard(poll = poll, onTap = { onOpenPoll(poll) })
            }
        }
    }

    item("community-header") {
        SectionHeader(
            title = "مجتمعك ينتظر رأيك",
            subtitle = TrendXAI.communitySubtitle,
            showMore = false
        )
    }
    items(feedPolls, key = { it.id }) { poll ->
        Box(modifier = Modifier.padding(horizontal = 20.dp)) {
            PollCard(
                poll = poll,
                onVote = { optionId, isPublic -> onVote(poll.id, optionId, isPublic) },
                onShare = { onShare(poll.id) },
                onBookmark = { onBookmark(poll.id) },
                onRepost = { repost -> onRepost(poll.id, repost) },
                onClick = { onOpenPoll(poll) }
            )
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.topicsContent(
    topics: List<Topic>,
    selectedFollowedOnly: Boolean,
    onSelectAll: () -> Unit,
    onSelectFollowed: () -> Unit,
    onFollowTopic: (String) -> Unit
) {
    item("filter-row") {
        androidx.compose.foundation.layout.Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(horizontal = 20.dp)
        ) {
            TopicFilterChip(
                title = "جميع المواضيع",
                isSelected = !selectedFollowedOnly,
                onClick = onSelectAll
            )
            TopicFilterChip(
                title = "تتابعهم",
                isSelected = selectedFollowedOnly,
                onClick = onSelectFollowed
            )
        }
    }
    items(topics, key = { it.id }) { topic ->
        Box(modifier = Modifier.padding(horizontal = 20.dp)) {
            TopicRow(topic = topic, onFollowTap = { onFollowTopic(topic.id) })
        }
    }
    item("topics-spacer") { Spacer(Modifier.height(12.dp)) }
}
