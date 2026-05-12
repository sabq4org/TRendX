package com.trendx.app.ui.screens.account

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.AccountAvatar
import com.trendx.app.ui.components.AccountTypeBadge
import com.trendx.app.ui.components.DetailScreenScaffold
import kotlinx.coroutines.launch

private enum class NetworkTab(val label: String) {
    Following("يتابعهم"), Followers("متابعونك")
}

// Mirrors TRENDX/Screens/MyNetworkScreen.swift. Two-tab list (يتابعهم +
// متابعونك) backed by `/me/following` and `/me/followers`. Each row taps
// into the public profile and exposes an inline follow / unfollow.
@Composable
fun MyNetworkScreen(
    onClose: () -> Unit,
    fetchFollowing: suspend () -> List<TrendXUser>?,
    fetchFollowers: suspend () -> List<TrendXUser>?,
    onFollowToggle: suspend (userId: String, currentlyFollowing: Boolean) -> Boolean,
    onOpenProfile: (TrendXUser) -> Unit,
    modifier: Modifier = Modifier
) {
    var tab by remember { mutableStateOf(NetworkTab.Following) }
    var following by remember { mutableStateOf<List<TrendXUser>?>(null) }
    var followers by remember { mutableStateOf<List<TrendXUser>?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    suspend fun reload() {
        isLoading = true
        following = fetchFollowing()
        followers = fetchFollowers()
        isLoading = false
    }

    LaunchedEffect(Unit) { reload() }

    DetailScreenScaffold(title = "شبكتي", onClose = onClose, modifier = modifier) {
        Column(modifier = Modifier.fillMaxSize()) {
            NetworkTabBar(
                tab = tab,
                followingCount = following?.size ?: 0,
                followersCount = followers?.size ?: 0,
                onSelect = { tab = it }
            )

            val rows = when (tab) {
                NetworkTab.Following -> following
                NetworkTab.Followers -> followers
            }

            when {
                isLoading && rows == null -> Box(modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = TrendXColors.Primary, strokeWidth = 2.dp)
                }
                rows.isNullOrEmpty() -> NetworkEmptyState(tab)
                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                        top = 6.dp, bottom = 60.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(rows, key = { it.id }) { user ->
                        NetworkRow(
                            user = user,
                            mode = tab,
                            onTap = { onOpenProfile(user) },
                            onPrimaryAction = {
                                scope.launch {
                                    val currentlyFollowing = tab == NetworkTab.Following ||
                                        user.viewerFollows
                                    val ok = onFollowToggle(user.id, currentlyFollowing)
                                    if (ok) reload()
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NetworkTabBar(
    tab: NetworkTab,
    followingCount: Int,
    followersCount: Int,
    onSelect: (NetworkTab) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 10.dp)
    ) {
        NetworkTab.entries.forEach { item ->
            val count = if (item == NetworkTab.Following) followingCount else followersCount
            val isSelected = tab == item
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier
                    .weight(1f)
                    .clickable { onSelect(item) }
                    .padding(vertical = 6.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = item.label,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.5.sp,
                            color = if (isSelected) TrendXColors.Primary
                                    else TrendXColors.TertiaryInk))
                    Spacer(Modifier.width(5.dp))
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(if (isSelected) TrendXColors.Primary.copy(alpha = 0.12f)
                                        else TrendXColors.SoftFill)
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(text = count.toString(),
                            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                                color = if (isSelected) TrendXColors.Primary
                                        else TrendXColors.TertiaryInk))
                    }
                }
                Box(modifier = Modifier
                    .height(2.5.dp)
                    .fillMaxWidth()
                    .background(if (isSelected) TrendXColors.Primary else Color.Transparent))
            }
        }
    }
}

@Composable
private fun NetworkEmptyState(tab: NetworkTab) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxSize().padding(horizontal = 38.dp, vertical = 36.dp)
    ) {
        Icon(
            imageVector = if (tab == NetworkTab.Following) Icons.Filled.PersonAdd
                          else Icons.Filled.PeopleAlt,
            contentDescription = null, tint = TrendXColors.TertiaryInk,
            modifier = Modifier.size(32.dp)
        )
        Text(text = if (tab == NetworkTab.Following) "لم تبدأ المتابعة بعد" else "لا متابعون بعد",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                color = TrendXColors.Ink))
        Text(
            text = if (tab == NetworkTab.Following)
                "افتح الرادار أو الصفحة الرئيسية وستلقى اقتراحات لحسابات ووزارات تستحق المتابعة."
            else
                "كلما شاركت رأيك وأصبح حسابك أنشط، زاد من يتابعك من المهتمين بقطاعك.",
            style = TextStyle(fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold,
                color = TrendXColors.SecondaryInk, lineHeight = 18.sp),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun NetworkRow(
    user: TrendXUser,
    mode: NetworkTab,
    onTap: () -> Unit,
    onPrimaryAction: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.6.dp, TrendXColors.Outline.copy(alpha = 0.5f), RoundedCornerShape(16.dp))
            .padding(12.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.weight(1f).clickable(onClick = onTap)
        ) {
            AccountAvatar(user = user, size = 48.dp, showRing = true)
            Spacer(Modifier.width(12.dp))
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = user.name, style = TextStyle(fontWeight = FontWeight.Black,
                        fontSize = 14.sp, color = TrendXColors.Ink), maxLines = 1)
                    Spacer(Modifier.width(4.dp))
                    AccountTypeBadge(type = user.accountType, isVerified = user.isVerified,
                        size = 12.dp)
                }
                user.handle?.takeIf { it.isNotBlank() }?.let { handle ->
                    Text(text = "@$handle", style = TextStyle(fontWeight = FontWeight.SemiBold,
                        fontSize = 11.sp, color = TrendXColors.TertiaryInk))
                }
                user.bio?.takeIf { it.isNotBlank() }?.let { bio ->
                    Text(text = bio, style = TextStyle(fontWeight = FontWeight.Medium,
                        fontSize = 11.sp, color = TrendXColors.SecondaryInk),
                        maxLines = 2)
                }
            }
        }
        Spacer(Modifier.width(8.dp))
        ActionPill(mode = mode, viewerFollows = user.viewerFollows, onClick = onPrimaryAction)
    }
}

@Composable
private fun ActionPill(
    mode: NetworkTab,
    viewerFollows: Boolean,
    onClick: () -> Unit
) {
    when {
        mode == NetworkTab.Following -> Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Error.copy(alpha = 0.08f))
                .clickable(onClick = onClick)
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text(text = "إلغاء", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 11.sp, color = TrendXColors.Error))
        }
        !viewerFollows -> Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
                .clickable(onClick = onClick)
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Icon(imageVector = Icons.Filled.Add, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(9.dp))
            Spacer(Modifier.width(4.dp))
            Text(text = "متابعة", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 11.sp, color = Color.White))
        }
        else -> Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Primary.copy(alpha = 0.10f))
                .padding(horizontal = 10.dp, vertical = 6.dp)
        ) {
            Text(text = "متابَع", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 11.sp, color = TrendXColors.Primary))
        }
    }
}
