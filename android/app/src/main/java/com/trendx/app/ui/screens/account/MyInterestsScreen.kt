package com.trendx.app.ui.screens.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.trendx.app.models.Topic
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.EmptyStateView
import com.trendx.app.ui.components.TopicRow

// Mirrors MyInterestsScreen from AccountScreen.swift — same TopicRow as
// the home topics list. Tap "متابعة" / "تتابعه" to flip directly.
@Composable
fun MyInterestsScreen(
    topics: List<Topic>,
    onClose: () -> Unit,
    onFollowToggle: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    DetailScreenScaffold(
        title = "اهتماماتي",
        onClose = onClose,
        modifier = modifier
    ) {
        if (topics.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(20.dp),
                contentAlignment = Alignment.Center) {
                EmptyStateView(
                    icon = Icons.Filled.Favorite,
                    title = "لم تختر اهتمامات بعد",
                    message = "اختر مواضيع تهمّك لتلقّي استطلاعات أقرب لذوقك."
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                    top = 8.dp, bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(topics, key = { it.id }) { topic ->
                    TopicRow(topic = topic, onFollowTap = { onFollowToggle(topic.id) })
                }
            }
        }
    }
}
