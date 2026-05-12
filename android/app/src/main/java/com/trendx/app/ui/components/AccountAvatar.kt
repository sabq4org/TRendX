package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.AccountType
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.avatarCornerRadius
import com.trendx.app.theme.gradient
import com.trendx.app.theme.tint

// Mirrors AccountAvatar in TRENDX/Components/AccountIdentity.swift —
// type-aware avatar (round / squircle), brand gradient fill, optional
// ring, and an asynchronously-loaded photo when `avatarUrl` is set.
@Composable
fun AccountAvatar(
    user: TrendXUser,
    size: Dp = 64.dp,
    showRing: Boolean = true,
    modifier: Modifier = Modifier
) {
    val cornerRadius = user.accountType.avatarCornerRadius.dp
    val shape = RoundedCornerShape(cornerRadius)
    val ringWidth = when (user.accountType) {
        AccountType.individual -> 1.5.dp
        AccountType.organization -> 2.dp
        AccountType.government -> 2.5.dp
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(size)
            .clip(shape)
            .background(user.accountType.gradient)
            .let { if (showRing) it.border(ringWidth, user.accountType.tint.copy(alpha = 0.55f), shape) else it }
    ) {
        if (!user.avatarUrl.isNullOrBlank()) {
            // TrendXProfileImage handles both HTTPS URLs and base64
            // data: URIs (the format ProfileEditScreen produces when
            // the user picks a photo from the gallery).
            TrendXProfileImage(
                urlString = user.avatarUrl,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(size).clip(shape)
            ) {
                Text(
                    text = user.avatarInitial.ifEmpty { user.name.take(1).ifEmpty { "م" } },
                    style = TextStyle(
                        fontFamily = FontFamily.Default,
                        fontWeight = FontWeight.Black,
                        fontSize = (size.value * 0.42f).sp,
                        color = TrendXColors.Surface
                    )
                )
            }
        } else if (user.accountType == AccountType.government) {
            // Government accounts without an uploaded logo get the
            // institutional emblem stand-in (palm leaf icon, white).
            Icon(
                imageVector = Icons.Filled.AccountBalance,
                contentDescription = null,
                tint = TrendXColors.Surface,
                modifier = Modifier.size(size * 0.45f)
            )
        } else {
            val initial = user.avatarInitial.ifEmpty { user.name.take(1).ifEmpty { "م" } }
            Text(
                text = initial,
                style = TextStyle(
                    fontFamily = FontFamily.Default,
                    fontWeight = FontWeight.Black,
                    fontSize = (size.value * 0.42f).sp,
                    color = TrendXColors.Surface
                )
            )
        }
    }
}

// Mirrors AccountTypeBadge from iOS — shows a small inline mark next to
// the account name. Government always shows; others only when verified.
@Composable
fun AccountTypeBadge(
    type: AccountType,
    isVerified: Boolean,
    size: Dp = 12.dp
) {
    val shouldShow = type == AccountType.government || isVerified
    if (!shouldShow) return
    Icon(
        imageVector = when (type) {
            AccountType.government -> Icons.Filled.Verified
            else -> Icons.Filled.CheckCircle
        },
        contentDescription = null,
        tint = type.tint,
        modifier = Modifier.size(size)
    )
}
