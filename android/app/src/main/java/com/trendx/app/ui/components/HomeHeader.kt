package com.trendx.app.ui.components

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.SettingsInputAntenna
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXAI
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType

// Faithful Compose port of HomeHeader from
// TRENDX/Components/SharedComponents.swift. Same gradient hero, ambient
// blurred blobs, brand mark, greeting tower, three metric capsules, and
// trailing icon trio (timeline + search + bell with optional badge).
@Composable
fun HomeHeader(
    userName: String,
    points: Int,
    coins: Double,
    avatarUrl: String? = null,
    unreadNotifications: Int = 0,
    isGuest: Boolean = false,
    onSignInTap: () -> Unit = {},
    onNotificationsTap: () -> Unit,
    onSearchTap: () -> Unit,
    onTimelineTap: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val greeting = TrendXAI.greeting(userName)

    Box(
        modifier = modifier
            .statusBarsPadding()
            .padding(horizontal = 20.dp)
            .padding(top = 14.dp, bottom = 2.dp)
            .fillMaxWidth()
            .shadow(elevation = 22.dp, shape = RoundedCornerShape(32.dp), clip = false,
                ambientColor = TrendXColors.PrimaryDeep, spotColor = TrendXColors.PrimaryDeep)
            .clip(RoundedCornerShape(32.dp))
            .background(TrendXGradients.Header)
            .border(1.dp, Color.White.copy(alpha = 0.22f), RoundedCornerShape(32.dp))
    ) {
        // Ambient blurred blobs — approximated with a Canvas that draws
        // softened circles. The real blur radius isn't free in Compose,
        // so we cheat with a large radial-feeling stroke + low alpha.
        Canvas(modifier = Modifier.fillMaxWidth().height(220.dp)) {
            drawCircle(
                color = Color.White.copy(alpha = 0.16f),
                radius = 105f,
                center = Offset(x = -60f, y = -45f)
            )
            drawCircle(
                color = TrendXColors.Info.copy(alpha = 0.18f),
                radius = 80f,
                center = Offset(x = size.width + 20f, y = size.height - 40f)
            )
        }

        Column(modifier = Modifier.padding(20.dp)) {
            if (isGuest) {
                GuestRow(onSearchTap = onSearchTap)
                Spacer(Modifier.height(14.dp))
                Text(
                    text = "استكشف الاتجاهات اليومية، توقّع نبض السعودية، واربح نقاطك الأولى — تسجيلك يستغرق دقيقة واحدة.",
                    style = TextStyle(
                        fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.Medium,
                        fontSize = 14.sp,
                        color = Color.White.copy(alpha = 0.88f),
                        lineHeight = 20.sp
                    )
                )
                Spacer(Modifier.height(16.dp))
                GuestSignInPill(onClick = onSignInTap)
            } else {
                AuthedRow(
                    userName = userName,
                    avatarUrl = avatarUrl,
                    greeting = greeting,
                    unreadNotifications = unreadNotifications,
                    onSearchTap = onSearchTap,
                    onNotificationsTap = onNotificationsTap,
                    onTimelineTap = onTimelineTap
                )
                Spacer(Modifier.height(14.dp))
                Text(
                    text = greeting.whisper,
                    style = TextStyle(
                        fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.Medium,
                        fontSize = 15.sp,
                        color = Color.White.copy(alpha = 0.86f),
                        lineHeight = 21.sp
                    ),
                    maxLines = 2
                )
                Spacer(Modifier.height(16.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    MetricCapsule(
                        icon = Icons.Filled.Star,
                        value = points.toString(),
                        label = "نقطة",
                        tint = TrendXColors.Accent,
                        modifier = Modifier.weight(1f)
                    )
                    MetricCapsule(
                        icon = Icons.Filled.MonetizationOn,
                        value = "%.1f".format(coins),
                        label = "ريال",
                        tint = TrendXColors.Success,
                        modifier = Modifier.weight(1f)
                    )
                    MetricCapsule(
                        icon = Icons.Filled.AutoAwesome,
                        value = "مجلة",
                        label = "اليوم",
                        tint = TrendXColors.Warning,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun AuthedRow(
    userName: String,
    avatarUrl: String?,
    greeting: TrendXAI.Greeting,
    unreadNotifications: Int,
    onSearchTap: () -> Unit,
    onNotificationsTap: () -> Unit,
    onTimelineTap: (() -> Unit)?
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.18f))
                .border(1.dp, Color.White.copy(alpha = 0.45f), CircleShape)
        ) {
            // TrendXProfileImage falls back to the initial when avatarUrl
            // is null/blank, OR when a base64 data: URI fails to decode.
            // Same behavior as iOS — fresh sign-up keeps the brand
            // gradient + initial until the user picks a photo.
            TrendXProfileImage(
                urlString = avatarUrl,
                contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                modifier = Modifier.size(50.dp).clip(CircleShape)
            ) {
                Text(
                    text = userName.take(1).ifEmpty { "م" },
                    style = TextStyle(
                        fontWeight = FontWeight.Black,
                        fontSize = 20.sp,
                        color = Color.White
                    )
                )
            }
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = greeting.eyebrow,
                style = TextStyle(
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.78f)
                )
            )
            Spacer(Modifier.height(3.dp))
            Text(
                text = greeting.title,
                style = TextStyle(
                    fontWeight = FontWeight.Black,
                    fontSize = 24.sp,
                    color = Color.White
                ),
                maxLines = 1
            )
        }

        onTimelineTap?.let {
            HeaderIconButton(icon = Icons.Filled.SettingsInputAntenna, onClick = it)
            Spacer(Modifier.width(8.dp))
        }
        HeaderIconButton(icon = Icons.Filled.Search, onClick = onSearchTap)
        Spacer(Modifier.width(8.dp))
        Box {
            HeaderIconButton(icon = Icons.Filled.Notifications, onClick = onNotificationsTap)
            if (unreadNotifications > 0) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .size(width = 18.dp, height = 16.dp)
                        .clip(CircleShape)
                        .background(TrendXColors.Accent)
                        .border(1.5.dp, Color.White.copy(alpha = 0.9f), CircleShape)
                ) {
                    Text(
                        text = if (unreadNotifications > 9) "9+" else unreadNotifications.toString(),
                        style = TextStyle(
                            fontWeight = FontWeight.Black,
                            fontSize = 9.sp,
                            color = Color.White
                        )
                    )
                }
            }
        }
    }
}

@Composable
private fun GuestRow(onSearchTap: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.18f))
        ) {
            Icon(
                imageVector = Icons.Filled.AutoAwesome,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(20.dp)
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "مرحباً بك في TRENDX",
                style = TextStyle(
                    fontWeight = FontWeight.Black,
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.82f)
                )
            )
            Spacer(Modifier.height(3.dp))
            Text(
                text = "نبض الرأي السعودي",
                style = TextStyle(
                    fontWeight = FontWeight.Black,
                    fontSize = 22.sp,
                    color = Color.White
                ),
                maxLines = 1
            )
        }
        HeaderIconButton(icon = Icons.Filled.Search, onClick = onSearchTap)
    }
}

@Composable
private fun GuestSignInPill(onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(50))
            .background(Color.White)
            .clickable(onClick = onClick)
            .padding(vertical = 13.dp, horizontal = 18.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.PersonAdd,
            contentDescription = null,
            tint = TrendXColors.PrimaryDeep,
            modifier = Modifier.size(14.dp)
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = "سجّل الآن وابدأ مع TRENDX",
            style = TextStyle(
                fontWeight = FontWeight.Black,
                fontSize = 14.sp,
                color = TrendXColors.PrimaryDeep
            )
        )
        Spacer(Modifier.width(8.dp))
        Icon(
            imageVector = Icons.Filled.ChevronLeft,
            contentDescription = null,
            tint = TrendXColors.PrimaryDeep,
            modifier = Modifier.size(11.dp)
        )
    }
}

@Composable
private fun HeaderIconButton(icon: ImageVector, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(38.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.16f))
            .clickable(onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = Color.White,
            modifier = Modifier.size(14.dp))
    }
}

@Composable
private fun MetricCapsule(
    icon: ImageVector,
    value: String,
    label: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.13f))
            .border(0.7.dp, Color.White.copy(alpha = 0.18f), RoundedCornerShape(16.dp))
            .padding(horizontal = 10.dp, vertical = 9.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(12.dp)
        )
        Spacer(Modifier.width(6.dp))
        Column {
            Text(
                text = value,
                style = TextStyle(
                    fontWeight = FontWeight.Black,
                    fontSize = 13.sp,
                    color = Color.White
                ),
                maxLines = 1
            )
            Text(
                text = label,
                style = TextStyle(
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.70f)
                ),
                maxLines = 1
            )
        }
    }
}
