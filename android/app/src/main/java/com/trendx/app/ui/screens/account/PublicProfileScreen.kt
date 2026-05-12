package com.trendx.app.ui.screens.account

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.PeopleAlt
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.AccountType
import com.trendx.app.models.Poll
import com.trendx.app.models.TrendXUser
import com.trendx.app.repositories.ProfilePost
import com.trendx.app.repositories.ProfilePostKind
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.gradient
import com.trendx.app.theme.profileLabel
import com.trendx.app.theme.tint
import com.trendx.app.theme.wash
import com.trendx.app.ui.components.AccountAvatar
import com.trendx.app.ui.components.AccountTypeBadge
import com.trendx.app.ui.components.PollCard
import kotlinx.coroutines.launch

// Faithful Compose port of TRENDX/Screens/PublicProfileScreen.swift.
// Hero branches by `accountType` — individual / organization / government
// — each with a distinct visual identity. Below the hero: optional follow
// button (when not self), stats tiles (متابعون / يتابع / منشورات أو
// تصويتات), an optional government pledge card, and a posts feed with
// real PollCards plus an "أعاد X نشر هذا" eyebrow above repost rows.
@Composable
fun PublicProfileScreen(
    initialUser: TrendXUser,
    isViewerSelf: Boolean,
    onClose: () -> Unit,
    fetchUser: suspend (idOrHandle: String) -> TrendXUser?,
    fetchPosts: suspend (idOrHandle: String) -> List<ProfilePost>?,
    onFollowToggle: suspend (userId: String, currentlyFollowing: Boolean) -> Boolean,
    onOpenPoll: (Poll) -> Unit,
    modifier: Modifier = Modifier
) {
    var user by remember(initialUser.id) { mutableStateOf(initialUser) }
    var posts by remember(initialUser.id) { mutableStateOf<List<ProfilePost>?>(null) }
    var isLoadingPosts by remember(initialUser.id) { mutableStateOf(false) }
    var isFollowBusy by remember(initialUser.id) { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val handleOrId = remember(initialUser.id) {
        initialUser.handle?.takeIf { it.isNotBlank() } ?: initialUser.id
    }

    LaunchedEffect(initialUser.id) {
        fetchUser(handleOrId)?.let { user = it }
        isLoadingPosts = true
        posts = fetchPosts(handleOrId)
        isLoadingPosts = false
    }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 60.dp),
            verticalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            item("hero") {
                when (user.accountType) {
                    AccountType.individual -> IndividualHero(user = user, onBack = onClose)
                    AccountType.organization -> OrganizationHero(user = user, onBack = onClose)
                    AccountType.government -> GovernmentHero(user = user, onBack = onClose)
                }
            }

            if (!isViewerSelf) {
                item("follow") {
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 20.dp)
                            .padding(top = if (user.accountType == AccountType.government) 36.dp else 8.dp)
                    ) {
                        FollowButton(
                            user = user,
                            isBusy = isFollowBusy,
                            onClick = {
                                if (isFollowBusy) return@FollowButton
                                isFollowBusy = true
                                val wasFollowing = user.viewerFollows
                                user = user.copy(
                                    viewerFollows = !wasFollowing,
                                    followersCount = (user.followersCount + if (wasFollowing) -1 else 1)
                                        .coerceAtLeast(0)
                                )
                                scope.launch {
                                    val ok = onFollowToggle(user.id, wasFollowing)
                                    if (!ok) {
                                        user = user.copy(
                                            viewerFollows = wasFollowing,
                                            followersCount = (user.followersCount + if (wasFollowing) 1 else -1)
                                                .coerceAtLeast(0)
                                        )
                                    }
                                    isFollowBusy = false
                                }
                            }
                        )
                    }
                }
            }

            item("stats") {
                Box(modifier = Modifier
                    .padding(horizontal = 20.dp)
                    .padding(top = if (isViewerSelf && user.accountType == AccountType.government) 36.dp else 18.dp,
                        bottom = 0.dp)) {
                    StatsRow(user = user, postsCount = computePostsCount(user, posts))
                }
            }

            if (user.accountType == AccountType.government) {
                item("pledge") {
                    Box(modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp)) {
                        GovernmentPledge()
                    }
                }
            }

            item("posts-header") {
                PostsHeader(tint = user.accountType.tint, isLoading = isLoadingPosts)
            }

            when {
                isLoadingPosts && posts == null -> item("loading") {
                    Box(modifier = Modifier.fillMaxWidth().padding(24.dp),
                        contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = user.accountType.tint,
                            strokeWidth = 2.dp)
                    }
                }
                posts.isNullOrEmpty() -> item("empty") {
                    Box(modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)) {
                        PostsEmptyState(name = user.name)
                    }
                }
                else -> {
                    posts!!.forEach { post ->
                        item(post.id) {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp),
                                modifier = Modifier.padding(horizontal = 20.dp, vertical = 7.dp)) {
                                if (post.kind == ProfilePostKind.Repost) {
                                    RepostEyebrow(reposterName = user.name, caption = post.caption)
                                }
                                PollCard(
                                    poll = post.poll,
                                    onVote = { _, _ -> },
                                    onShare = {},
                                    onBookmark = {},
                                    onRepost = {},
                                    onClick = { onOpenPoll(post.poll) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// ---- Hero variants ----

@Composable
private fun IndividualHero(user: TrendXUser, onBack: () -> Unit) {
    val ambient = Brush.verticalGradient(
        colors = listOf(
            TrendXColors.Primary.copy(alpha = 0.10f),
            TrendXColors.AiViolet.copy(alpha = 0.05f),
            Color.Transparent
        )
    )
    Box(modifier = Modifier
        .fillMaxWidth()
        .background(ambient)
        .statusBarsPadding()) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.fillMaxWidth().padding(top = 22.dp, bottom = 22.dp)
        ) {
            AccountAvatar(user = user, size = 96.dp, showRing = true)
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = user.name,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                            color = TrendXColors.Ink))
                    Spacer(Modifier.width(5.dp))
                    AccountTypeBadge(type = user.accountType, isVerified = user.isVerified,
                        size = 14.dp)
                }
                user.handle?.takeIf { it.isNotBlank() }?.let { handle ->
                    Text(text = "@$handle",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                            color = TrendXColors.TertiaryInk))
                }
            }
            user.bio?.takeIf { it.isNotBlank() }?.let { bio ->
                Text(text = bio,
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                        color = TrendXColors.SecondaryInk, lineHeight = 19.sp),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 36.dp))
            }
        }
        HeroBackButton(onBack = onBack)
    }
}

@Composable
private fun OrganizationHero(user: TrendXUser, onBack: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(130.dp)
            .background(TrendXGradients.OrgGold)
            .statusBarsPadding()) {
            DotGridOverlay(spacing = 14f, dotSize = 1.5f, alpha = 0.12f)
            HeroBackButton(onBack = onBack)
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth().padding(bottom = 18.dp)
        ) {
            Box(modifier = Modifier
                .offset(y = (-48).dp)
                .padding(bottom = (-36).dp)) {
                AccountAvatar(user = user, size = 88.dp, showRing = true)
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = user.name,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                            color = TrendXColors.Ink))
                    Spacer(Modifier.width(5.dp))
                    AccountTypeBadge(type = user.accountType, isVerified = user.isVerified,
                        size = 14.dp)
                }
                user.handle?.takeIf { it.isNotBlank() }?.let { handle ->
                    Text(text = "@$handle",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                            color = TrendXColors.TertiaryInk))
                }
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(TrendXColors.OrgGoldWash)
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(text = user.accountType.profileLabel,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = TrendXColors.OrgGold))
                }
            }
            user.bio?.takeIf { it.isNotBlank() }?.let { bio ->
                Text(text = bio,
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                        color = TrendXColors.SecondaryInk, lineHeight = 19.sp),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 36.dp))
            }
        }
    }
}

@Composable
private fun GovernmentHero(user: TrendXUser, onBack: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(220.dp)
            .background(TrendXGradients.SaudiGreen)
            .statusBarsPadding()) {
            IslamicPatternOverlay()
            HeroBackButton(onBack = onBack)
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier
                .padding(horizontal = 14.dp)
                .offset(y = (-28).dp)
                .fillMaxWidth()
                .shadow(elevation = 20.dp, shape = RoundedCornerShape(24.dp), clip = false,
                    ambientColor = TrendXColors.SaudiGreen, spotColor = TrendXColors.SaudiGreen)
                .clip(RoundedCornerShape(24.dp))
                .background(Color.White)
                .border(1.dp, TrendXColors.SaudiGreen.copy(alpha = 0.20f),
                    RoundedCornerShape(24.dp))
                .padding(horizontal = 20.dp)
                .padding(bottom = 22.dp)
        ) {
            Box(modifier = Modifier
                .offset(y = (-50).dp)
                .padding(bottom = (-38).dp)
                .shadow(elevation = 14.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.SaudiGreen, spotColor = TrendXColors.SaudiGreen)) {
                AccountAvatar(user = user, size = 100.dp, showRing = true)
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = user.name,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                            color = TrendXColors.SaudiGreenDeep))
                    Spacer(Modifier.width(6.dp))
                    Icon(imageVector = Icons.Filled.Verified, contentDescription = null,
                        tint = TrendXColors.SaudiGreen, modifier = Modifier.size(16.dp))
                }
                user.handle?.takeIf { it.isNotBlank() }?.let { handle ->
                    Text(text = "@$handle",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                            color = TrendXColors.SaudiGreen.copy(alpha = 0.7f)))
                }
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(TrendXColors.SaudiGreenWash)
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(text = user.accountType.profileLabel,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = TrendXColors.SaudiGreenDeep))
                }
            }
            user.bio?.takeIf { it.isNotBlank() }?.let { bio ->
                Text(text = bio,
                    style = TextStyle(fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.Medium, fontSize = 13.5.sp,
                        color = TrendXColors.SecondaryInk, lineHeight = 20.sp),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 32.dp))
            }
        }
    }
}

// ---- Back button overlay on the hero ----

@Composable
private fun HeroBackButton(onBack: () -> Unit) {
    // RTL: leading-edge alignment puts this on the right side of the
    // screen — natural "back" direction for an Arabic reader.
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .padding(top = 12.dp, start = 14.dp)
            .size(36.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.32f))
            .border(0.7.dp, Color.White.copy(alpha = 0.32f), CircleShape)
            .clickable(onClick = onBack)
    ) {
        Icon(imageVector = Icons.Filled.ArrowForward, contentDescription = "رجوع",
            tint = Color.White, modifier = Modifier.size(14.dp))
    }
}

// ---- Pattern overlays for hero banners ----

@Composable
private fun DotGridOverlay(spacing: Float, dotSize: Float, alpha: Float) {
    Canvas(modifier = Modifier.fillMaxSize()) {
        val color = Color.White.copy(alpha = alpha)
        var x = 0f
        while (x < size.width) {
            var y = 0f
            while (y < size.height) {
                drawCircle(color = color, radius = dotSize / 2f, center = Offset(x, y))
                y += spacing
            }
            x += spacing
        }
    }
}

@Composable
private fun IslamicPatternOverlay() {
    // 8-point geometric tiling — diagonal cross strokes that fade into
    // the green banner. Mirrors the iOS Canvas in
    // `governmentBannerFallback`.
    Canvas(modifier = Modifier.fillMaxSize()) {
        val spacing = 36f
        val color = Color.White.copy(alpha = 0.08f)
        val stroke = Stroke(width = 0.6f)
        val path = Path()
        var x = 0f
        while (x < size.width + spacing) {
            var y = 0f
            while (y < size.height + spacing) {
                path.moveTo(x, y)
                path.lineTo(x + spacing / 2f, y + spacing / 2f)
                path.moveTo(x + spacing, y)
                path.lineTo(x + spacing / 2f, y + spacing / 2f)
                y += spacing
            }
            x += spacing
        }
        drawPath(path = path, color = color, style = stroke)
    }
}

// ---- Below-the-fold pieces ----

@Composable
private fun FollowButton(user: TrendXUser, isBusy: Boolean, onClick: () -> Unit) {
    val isFollowing = user.viewerFollows
    val tint = user.accountType.tint
    val followBg = user.accountType.gradient
    val washBg = user.accountType.wash
    val fg = if (isFollowing) tint else Color.White

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = if (isFollowing) 0.dp else 12.dp,
                shape = RoundedCornerShape(14.dp), clip = false,
                ambientColor = tint, spotColor = tint)
            .clip(RoundedCornerShape(14.dp))
            .let { if (isFollowing) it.background(washBg) else it.background(followBg) }
            .let {
                if (isFollowing) it.border(1.dp, tint.copy(alpha = 0.32f),
                    RoundedCornerShape(14.dp))
                else it
            }
            .clickable(enabled = !isBusy, onClick = onClick)
            .padding(vertical = 14.dp)
    ) {
        if (isBusy) {
            CircularProgressIndicator(
                color = fg, strokeWidth = 1.6.dp,
                modifier = Modifier.size(13.dp)
            )
            Spacer(Modifier.width(8.dp))
        }
        Icon(imageVector = if (isFollowing) Icons.Filled.Check else Icons.Filled.Add,
            contentDescription = null, tint = fg, modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = if (isFollowing) "متابَع" else "متابعة",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp, color = fg))
    }
}

@Composable
private fun StatsRow(user: TrendXUser, postsCount: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()) {
        StatTile(
            label = "متابعون", value = shortNumber(user.followersCount),
            icon = Icons.Filled.PeopleAlt, tint = user.accountType.tint,
            wash = user.accountType.wash, modifier = Modifier.weight(1f)
        )
        StatTile(
            label = "يتابع", value = shortNumber(user.followingCount),
            icon = Icons.Outlined.PeopleAlt, tint = user.accountType.tint,
            wash = user.accountType.wash, modifier = Modifier.weight(1f)
        )
        StatTile(
            label = if (user.accountType == AccountType.individual) "تصويتات" else "منشورات",
            value = postsCount.toString(),
            icon = Icons.Filled.Description, tint = user.accountType.tint,
            wash = user.accountType.wash, modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun StatTile(
    label: String, value: String, icon: ImageVector,
    tint: Color, wash: Color, modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(wash)
            .border(1.dp, tint.copy(alpha = 0.18f), RoundedCornerShape(16.dp))
            .padding(vertical = 14.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(13.dp))
        Text(text = value, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 18.sp,
            color = TrendXColors.Ink))
        Text(text = label, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.5.sp,
            color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun GovernmentPledge() {
    Row(
        verticalAlignment = Alignment.Top,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.SaudiGreenWash)
            .border(1.dp, TrendXColors.SaudiGreen.copy(alpha = 0.22f), RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Icon(imageVector = Icons.Filled.Info, contentDescription = null,
            tint = TrendXColors.SaudiGreen, modifier = Modifier.size(16.dp))
        Spacer(Modifier.width(12.dp))
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = "الحساب الرسمي",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.SaudiGreenDeep))
            Text(
                text = "جميع الاستطلاعات والاستبيانات المنشورة هنا صادرة عن الجهة المعتمدة. تخضع للنزاهة المؤسسية.",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 18.sp)
            )
        }
    }
}

@Composable
private fun PostsHeader(tint: Color, isLoading: Boolean) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp)
    ) {
        Icon(imageVector = Icons.Filled.Description, contentDescription = null,
            tint = tint, modifier = Modifier.size(12.dp))
        Spacer(Modifier.width(8.dp))
        Text(text = "المنشورات وإعادات النشر",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                color = TrendXColors.Ink))
        Spacer(Modifier.weight(1f))
        if (isLoading) {
            CircularProgressIndicator(color = tint, strokeWidth = 1.6.dp,
                modifier = Modifier.size(14.dp))
        }
    }
}

@Composable
private fun PostsEmptyState(name: String) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline.copy(alpha = 0.5f), RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(imageVector = Icons.Filled.Inbox, contentDescription = null,
                tint = TrendXColors.TertiaryInk, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(6.dp))
            Text(text = "لا توجد منشورات بعد",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.Ink))
        }
        Text(text = "سيظهر هنا كل ما ينشره $name من استطلاعات وإعادات نشر، فور وصوله.",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk, lineHeight = 18.sp))
    }
}

@Composable
private fun RepostEyebrow(reposterName: String, caption: String?) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp)
    ) {
        Icon(imageVector = Icons.Filled.Repeat, contentDescription = null,
            tint = TrendXColors.AiViolet, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = "أعاد $reposterName نشر هذا",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.5.sp,
                color = TrendXColors.AiViolet))
        caption?.takeIf { it.isNotBlank() }?.let {
            Spacer(Modifier.width(6.dp))
            Text(text = "·", style = TextStyle(color = TrendXColors.MutedInk, fontSize = 11.sp))
            Spacer(Modifier.width(6.dp))
            Text(text = it,
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                    color = TrendXColors.SecondaryInk),
                maxLines = 1)
        }
    }
}

private fun computePostsCount(user: TrendXUser, posts: List<ProfilePost>?): Int {
    return if (user.accountType == AccountType.individual) {
        user.completedPolls.size
    } else {
        posts?.count { it.kind == ProfilePostKind.Poll } ?: 0
    }
}

private fun shortNumber(n: Int): String = when {
    n < 1_000 -> n.toString()
    n < 1_000_000 -> {
        val v = n / 1_000.0
        if (v < 10) "%.1fK".format(v) else "%.0fK".format(v)
    }
    else -> "%.1fM".format(n / 1_000_000.0)
}
