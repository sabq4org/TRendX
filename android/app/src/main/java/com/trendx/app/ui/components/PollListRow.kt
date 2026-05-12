package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.trendx.app.models.Poll
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors PollListRow from PollsScreen.swift — compact, list-friendly row
// with leading topic-color stripe, optional cover thumbnail, topic chip +
// status badge, title (3-line serif), stats, and trailing action bubble.
@Composable
fun PollListRow(
    poll: Poll,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val style = poll.topicStyle
    val tint = style.tint
    val statusKind = when {
        poll.isExpired -> StatusBadgeKind.Ended
        poll.hasUserVoted -> StatusBadgeKind.Voted
        poll.isEndingSoon -> StatusBadgeKind.Warning
        else -> StatusBadgeKind.Active
    }
    val hasImage = !poll.imageUrl.isNullOrBlank()

    Row(
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(18.dp), clip = false,
                ambientColor = tint, spotColor = tint)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(18.dp))
            .clickable(onClick = onTap)
    ) {
        // Topic-color stripe — vertical
        Box(modifier = Modifier
            .width(4.dp)
            .fillMaxHeight()
            .background(style.gradient))

        Row(
            verticalAlignment = Alignment.Top,
            modifier = Modifier
                .weight(1f)
                .padding(16.dp)
        ) {
            if (hasImage) {
                Box(modifier = Modifier
                    .size(64.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .border(0.6.dp, TrendXColors.Outline, RoundedCornerShape(14.dp))) {
                    SubcomposeAsyncImage(
                        model = poll.imageUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        loading = { Box(modifier = Modifier
                            .fillMaxSize()
                            .background(style.gradient)) },
                        error = { Box(modifier = Modifier
                            .fillMaxSize()
                            .background(style.gradient)) },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                Spacer(Modifier.width(14.dp))
            }

            Column(verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    poll.topicName?.let { name ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(style.wash)
                                .border(0.6.dp, style.hairline, CircleShape)
                                .padding(horizontal = 9.dp, vertical = 4.dp)
                        ) {
                            Icon(imageVector = style.glyph, contentDescription = null,
                                tint = tint, modifier = Modifier.size(10.dp))
                            Spacer(Modifier.width(5.dp))
                            Text(text = name, style = TextStyle(
                                fontWeight = FontWeight.Black, fontSize = 11.sp, color = tint))
                        }
                    }
                    StatusBadge(kind = statusKind)
                }
                Text(
                    text = poll.title,
                    style = TextStyle(
                        fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.sp,
                        color = TrendXColors.Ink,
                        lineHeight = 20.sp
                    ),
                    maxLines = 3
                )
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Filled.PeopleAlt, contentDescription = null,
                            tint = TrendXColors.SecondaryInk, modifier = Modifier.size(11.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(text = poll.totalVotes.toString(),
                            style = TrendXType.Small, color = TrendXColors.SecondaryInk)
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Filled.AccessTime, contentDescription = null,
                            tint = if (poll.isExpired) TrendXColors.Muted
                            else if (poll.isEndingSoon) TrendXColors.Warning
                            else TrendXColors.SecondaryInk,
                            modifier = Modifier.size(11.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(text = poll.deadlineLabel,
                            style = TrendXType.Small,
                            color = if (poll.isExpired) TrendXColors.Muted
                            else if (poll.isEndingSoon) TrendXColors.Warning
                            else TrendXColors.SecondaryInk)
                    }
                }
            }

            Spacer(Modifier.width(10.dp))

            Column(horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .shadow(elevation = if (poll.isExpired) 0.dp else 6.dp,
                            shape = CircleShape, clip = false,
                            ambientColor = tint, spotColor = tint)
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(if (poll.isExpired) TrendXColors.SoftFill else Color.Transparent)
                ) {
                    if (poll.isExpired) {
                        Icon(imageVector = Icons.Filled.Visibility, contentDescription = null,
                            tint = TrendXColors.Muted, modifier = Modifier.size(13.dp))
                    } else {
                        Box(modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(style.gradient),
                            contentAlignment = Alignment.Center) {
                            Icon(imageVector = Icons.Filled.ArrowBack, contentDescription = null,
                                tint = Color.White, modifier = Modifier.size(13.dp))
                        }
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Filled.Star, contentDescription = null,
                        tint = TrendXColors.Accent, modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(3.dp))
                    Text(text = poll.rewardPoints.toString(),
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp,
                            color = TrendXColors.AccentDeep))
                }
            }
        }
    }
}
