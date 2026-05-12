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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import com.trendx.app.models.Topic
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors TopicRow from SharedComponents.swift.
@Composable
fun TopicRow(
    topic: Topic,
    onFollowTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val style = topic.coverStyle
    val tint = style.tint

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 8.dp, shape = RoundedCornerShape(16.dp), clip = false,
                ambientColor = tint, spotColor = tint)
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 6.dp, shape = CircleShape, clip = false,
                    ambientColor = tint, spotColor = tint)
                .size(46.dp)
                .clip(CircleShape)
                .background(style.gradient)
        ) {
            Icon(imageVector = style.glyph, contentDescription = null,
                tint = androidx.compose.ui.graphics.Color.White,
                modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = topic.name, style = TrendXType.BodyBold, color = TrendXColors.Ink)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = Icons.Filled.PeopleAlt, contentDescription = null,
                    tint = TrendXColors.TertiaryInk, modifier = Modifier.size(11.dp))
                Spacer(Modifier.width(4.dp))
                Text(text = "${topic.followersCount} متابع",
                    style = TrendXType.Small, color = TrendXColors.TertiaryInk)
                Spacer(Modifier.width(12.dp))
                Icon(imageVector = Icons.Filled.Description, contentDescription = null,
                    tint = TrendXColors.TertiaryInk, modifier = Modifier.size(11.dp))
                Spacer(Modifier.width(4.dp))
                Text(text = "${topic.postsCount} منشور",
                    style = TrendXType.Small, color = TrendXColors.TertiaryInk)
            }
        }
        FollowPill(isFollowing = topic.isFollowing, tint = tint, onClick = onFollowTap)
    }
}

@Composable
private fun FollowPill(
    isFollowing: Boolean,
    tint: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    val bg = if (isFollowing) TrendXColors.SoftFill else tint.copy(alpha = 0.10f)
    val fg = if (isFollowing) TrendXColors.SecondaryInk else tint
    val border = if (isFollowing) TrendXColors.Outline else tint.copy(alpha = 0.25f)

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .border(0.8.dp, border, CircleShape)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = if (isFollowing) "تتابعه" else "متابعة",
            style = TrendXType.Caption,
            color = fg
        )
    }
}
