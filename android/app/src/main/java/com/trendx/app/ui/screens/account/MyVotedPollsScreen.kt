package com.trendx.app.ui.screens.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Verified
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.trendx.app.models.Poll
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.EmptyStateView
import com.trendx.app.ui.components.PollListRow

// Mirrors MyVotedPollsScreen from AccountScreen.swift — list of polls
// the user has actually voted on. Tapping a row opens the detail.
@Composable
fun MyVotedPollsScreen(
    polls: List<Poll>,
    onClose: () -> Unit,
    onOpenPoll: (Poll) -> Unit,
    modifier: Modifier = Modifier
) {
    val voted = remember(polls) { polls.filter { it.hasUserVoted } }
    DetailScreenScaffold(
        title = "استطلاعاتي المصوّت عليها",
        onClose = onClose,
        modifier = modifier
    ) {
        if (voted.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(20.dp),
                contentAlignment = Alignment.Center) {
                EmptyStateView(
                    icon = Icons.Filled.Verified,
                    title = "لم تصوّت بعد",
                    message = "صوّت في أي استطلاع لتظهر هنا. كل تصويت يمنحك نقاطاً ويثري التحليل."
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                    top = 8.dp, bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(voted, key = { it.id }) { poll ->
                    PollListRow(poll = poll, onTap = { onOpenPoll(poll) })
                }
            }
        }
    }
}
