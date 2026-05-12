package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.AccountType
import com.trendx.app.models.Poll
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Faithful Compose port of PollCard from
// TRENDX/Components/SharedComponents.swift. Includes:
// - Author row with type-aware avatar + verification badge + topic pill
//   + official inline marker (gov / verified-only) + status badge
// - Title in serif
// - Editorial cover (image OR layered gradient) via TrendXEditorialCover
// - Options list with topic-tinted percentage bars
// - Pre-vote visibility toggle ("تصويتي خاص ↔ تصويتي ظاهر لمتابعيّ")
// - Post-vote AI insight chip
// - Stats footer (votes + deadline + reward chip)
// - Action row (repost gradient pill + share + bookmark)
@Composable
fun PollCard(
    poll: Poll,
    onVote: (optionId: String, isPublic: Boolean) -> Unit,
    onShare: () -> Unit,
    onBookmark: () -> Unit,
    onRepost: (Boolean) -> Unit,
    onAuthorTap: () -> Unit = {},
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val style = poll.topicStyle
    val tint = style.tint
    val isOfficial = poll.authorAccountType == AccountType.government ||
                     poll.voterAudience != "public"
    var voteIsPublic by remember { mutableStateOf(false) }
    var pendingOption by remember { mutableStateOf<String?>(null) }

    val author = remember(poll.authorName, poll.authorAccountType, poll.authorIsVerified) {
        TrendXUser(
            id = poll.publisherId ?: "00000000-0000-0000-0000-000000000000",
            name = poll.authorName,
            handle = poll.authorHandle,
            avatarInitial = poll.authorAvatar,
            avatarUrl = poll.authorAvatarUrl,
            accountType = poll.authorAccountType,
            isVerified = poll.authorIsVerified
        )
    }

    val statusKind = when {
        poll.isExpired -> StatusBadgeKind.Ended
        poll.hasUserVoted -> StatusBadgeKind.Voted
        poll.isEndingSoon -> StatusBadgeKind.Warning
        else -> StatusBadgeKind.Active
    }

    Column(
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(20.dp), clip = false)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        // Author row
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.clickable(onClick = onAuthorTap)
        ) {
            AccountAvatar(user = author, size = 44.dp, showRing = true)
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = poll.authorName, style = TrendXType.BodyBold,
                        color = TrendXColors.Ink, maxLines = 1)
                    Spacer(Modifier.width(4.dp))
                    AccountTypeBadge(type = poll.authorAccountType,
                        isVerified = poll.authorIsVerified, size = 13.dp)
                }
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    poll.topicName?.let { name ->
                        Box(modifier = Modifier
                            .clip(CircleShape)
                            .background(style.wash)
                            .border(0.6.dp, style.hairline, CircleShape)
                            .padding(horizontal = 7.dp, vertical = 2.dp)) {
                            Text(text = name, style = TextStyle(
                                fontFamily = FontFamily.Default,
                                fontWeight = FontWeight.Black,
                                fontSize = 10.5.sp, color = tint))
                        }
                    }
                    if (isOfficial) OfficialInlineMarker(poll = poll)
                    Text(text = poll.timeAgo, style = TrendXType.Small,
                        color = TrendXColors.TertiaryInk)
                }
            }
            StatusBadge(kind = statusKind)
        }

        // Question (serif)
        Text(
            text = poll.title,
            style = TextStyle(
                fontFamily = FontFamily.Serif,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
                color = TrendXColors.Ink,
                lineHeight = 25.sp
            )
        )

        // Editorial cover
        TrendXEditorialCover(imageUrl = poll.imageUrl, style = style, height = 132.dp)

        // Options
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            poll.options.forEach { option ->
                PollOptionRow(
                    option = option,
                    tint = tint,
                    isSelected = pendingOption == option.id || poll.userVotedOptionId == option.id,
                    showResults = poll.hasUserVoted,
                    isUserChoice = poll.userVotedOptionId == option.id,
                    onTap = {
                        if (!poll.hasUserVoted) {
                            pendingOption = option.id
                            onVote(option.id, voteIsPublic)
                        }
                    }
                )
            }
        }

        // Pre-vote visibility toggle — defaults to private. Hidden after vote.
        if (!poll.hasUserVoted) {
            VoteVisibilityToggle(isPublic = voteIsPublic, onToggle = { voteIsPublic = !voteIsPublic })
        }

        // Post-vote AI insight chip
        if (poll.hasUserVoted) {
            val text = poll.aiInsight ?: TrendXAI.encouragement()
            val label = if (poll.aiInsight != null) "رؤية TRENDX AI" else "شكراً من TRENDX AI"
            AIInsightChip(text = text, label = label)
        }

        // Hairline divider
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(0.8.dp)
            .background(TrendXColors.Outline))

        // Stats footer
        Row(verticalAlignment = Alignment.CenterVertically) {
            FooterStat(icon = Icons.Filled.PeopleAlt, text = poll.totalVotes.toString())
            Spacer(Modifier.width(14.dp))
            FooterStat(
                icon = Icons.Filled.AccessTime,
                text = poll.deadlineLabel,
                tint = if (poll.isExpired) TrendXColors.Muted
                else if (poll.isEndingSoon) TrendXColors.Warning
                else TrendXColors.SecondaryInk
            )
            Spacer(Modifier.weight(1f))
            RewardChip(points = poll.rewardPoints)
        }

        // Actions
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            RepostPill(
                isReposted = poll.viewerReposted,
                onClick = { onRepost(!poll.viewerReposted) }
            )
            ActionIconButton(
                icon = Icons.Filled.IosShare,
                onClick = onShare
            )
            ActionIconButton(
                icon = if (poll.isBookmarked) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                tint = if (poll.isBookmarked) TrendXColors.Primary else TrendXColors.SecondaryInk,
                background = if (poll.isBookmarked) TrendXColors.Primary.copy(alpha = 0.10f)
                else TrendXColors.SoftFill,
                onClick = onBookmark
            )
            Spacer(Modifier.weight(1f))
        }
    }
}

@Composable
private fun OfficialInlineMarker(poll: Poll) {
    val label = when (poll.voterAudience) {
        "verified_citizen" -> "استطلاع وطني"
        "verified" -> "للموثّقين"
        else -> "رسمي"
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(TrendXColors.SaudiGreenWash)
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Icon(imageVector = Icons.Filled.Verified, contentDescription = null,
            tint = TrendXColors.SaudiGreen, modifier = Modifier.size(9.dp))
        Spacer(Modifier.width(3.dp))
        Text(text = label, style = TextStyle(
            fontWeight = FontWeight.Black, fontSize = 9.5.sp, color = TrendXColors.SaudiGreen))
    }
}

@Composable
private fun VoteVisibilityToggle(isPublic: Boolean, onToggle: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(if (isPublic) TrendXColors.Primary.copy(alpha = 0.10f) else TrendXColors.PaleFill)
            .border(
                0.8.dp,
                if (isPublic) TrendXColors.Primary.copy(alpha = 0.22f) else Color.Transparent,
                RoundedCornerShape(10.dp)
            )
            .clickable(onClick = onToggle)
            .padding(horizontal = 11.dp, vertical = 8.dp)
    ) {
        Icon(
            imageVector = if (isPublic) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
            contentDescription = null,
            tint = if (isPublic) TrendXColors.Primary else TrendXColors.SecondaryInk,
            modifier = Modifier.size(11.dp)
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = if (isPublic) "تصويتي ظاهر لمتابعيّ" else "تصويتي خاص",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.5.sp,
                color = if (isPublic) TrendXColors.Primary else TrendXColors.SecondaryInk),
            modifier = Modifier.weight(1f)
        )
        Text(
            text = if (isPublic) "اضغط للإخفاء" else "اضغط للإظهار",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.5.sp,
                color = TrendXColors.TertiaryInk)
        )
    }
}

@Composable
private fun FooterStat(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String,
    tint: Color = TrendXColors.SecondaryInk
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(4.dp))
        Text(text = text, style = TrendXType.Small, color = tint)
    }
}

@Composable
private fun RewardChip(points: Int) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(TrendXColors.Accent.copy(alpha = 0.10f))
            .padding(horizontal = 9.dp, vertical = 4.dp)
    ) {
        Icon(imageVector = Icons.Filled.Star, contentDescription = null,
            tint = TrendXColors.Accent, modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(4.dp))
        Text(text = "+$points",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.5.sp,
                color = TrendXColors.AccentDeep))
    }
}

@Composable
private fun RepostPill(isReposted: Boolean, onClick: () -> Unit) {
    val bg: Brush = if (isReposted)
        Brush.horizontalGradient(listOf(TrendXColors.AiViolet, TrendXColors.AiIndigo))
    else Brush.horizontalGradient(listOf(TrendXColors.AiViolet.copy(alpha = 0.10f),
        TrendXColors.AiViolet.copy(alpha = 0.10f)))

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 7.dp)
    ) {
        Icon(imageVector = Icons.Filled.Repeat, contentDescription = null,
            tint = if (isReposted) Color.White else TrendXColors.AiViolet,
            modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(5.dp))
        Text(
            text = if (isReposted) "أُعيد نشره" else "إعادة نشر",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.5.sp,
                color = if (isReposted) Color.White else TrendXColors.AiViolet)
        )
    }
}

@Composable
private fun ActionIconButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    tint: Color = TrendXColors.SecondaryInk,
    background: Color = TrendXColors.SoftFill
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .background(background)
            .clickable(onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(15.dp))
    }
}
