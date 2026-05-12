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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.layout.ContentScale
import com.trendx.app.models.AccountType
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.theme.tint

// Mirrors ProfileHeader from TRENDX/Screens/AccountScreen.swift — big
// blue gradient hero with avatar, edit pencil overlay, name, membership
// pill, and "تعديل الملف الشخصي" white pill button.
@Composable
fun ProfileHeader(
    user: TrendXUser,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier
) {
    val membership = if (user.isPremium) "عضو مميز" else "عضو TRENDX"

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 18.dp, shape = RoundedCornerShape(26.dp), clip = false,
                ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
            .clip(RoundedCornerShape(26.dp))
            .background(TrendXGradients.Header)
            .border(1.dp, Color.White.copy(alpha = 0.18f), RoundedCornerShape(26.dp))
    ) {
        // Ambient blobs (approximated, no native blur)
        Canvas(modifier = Modifier.fillMaxWidth().height(280.dp)) {
            drawCircle(color = Color.White.copy(alpha = 0.12f), radius = 110f,
                center = Offset(x = -60f, y = -45f))
            drawCircle(color = TrendXColors.PrimaryLight.copy(alpha = 0.30f),
                radius = 90f, center = Offset(x = size.width + 20f, y = size.height - 40f))
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp, horizontal = 20.dp)
        ) {
            ProfileAvatar(user = user, onEdit = onEdit)
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(text = user.name,
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 24.sp,
                        color = Color.White))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.22f))
                        .border(0.6.dp, Color.White.copy(alpha = 0.35f), CircleShape)
                        .padding(horizontal = 14.dp, vertical = 6.dp)
                ) {
                    Icon(imageVector = if (user.isPremium) Icons.Filled.Star
                                       else Icons.Filled.CheckCircle,
                        contentDescription = null, tint = Color.White,
                        modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(text = membership,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                            color = Color.White, letterSpacing = 0.3.sp))
                }
            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .shadow(elevation = 8.dp, shape = CircleShape, clip = false,
                        ambientColor = TrendXColors.PrimaryDeep, spotColor = TrendXColors.PrimaryDeep)
                    .clip(CircleShape)
                    .background(Color.White)
                    .clickable(onClick = onEdit)
                    .padding(horizontal = 18.dp, vertical = 10.dp)
            ) {
                Text(text = "تعديل الملف الشخصي",
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp,
                        color = TrendXColors.PrimaryDeep))
                Spacer(Modifier.width(6.dp))
                Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
                    tint = TrendXColors.PrimaryDeep, modifier = Modifier.size(10.dp))
            }
        }
    }
}

@Composable
private fun ProfileAvatar(user: TrendXUser, onEdit: () -> Unit) {
    Box(modifier = Modifier.size(96.dp), contentAlignment = Alignment.BottomEnd) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 14.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.PrimaryDeep, spotColor = TrendXColors.PrimaryDeep)
                .size(92.dp)
                .clip(CircleShape)
                .background(Color.White)
                .border(3.dp, Color.White.copy(alpha = 0.55f), CircleShape)
        ) {
            // TrendXProfileImage handles both HTTPS and base64 data: URIs.
            TrendXProfileImage(
                urlString = user.avatarUrl,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(86.dp).clip(CircleShape)
            ) {
                Text(text = user.avatarInitial.ifEmpty { user.name.take(1).ifEmpty { "م" } },
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 36.sp,
                        color = TrendXColors.PrimaryDeep))
            }
        }
        // Edit pencil
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 6.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Accent, spotColor = TrendXColors.Accent)
                .size(28.dp)
                .clip(CircleShape)
                .background(TrendXColors.Accent)
                .border(2.5.dp, Color.White, CircleShape)
                .clickable(onClick = onEdit)
        ) {
            Icon(imageVector = Icons.Filled.Edit, contentDescription = "تعديل",
                tint = Color.White, modifier = Modifier.size(12.dp))
        }
    }
}

// Mirrors GuestAccountHero from AccountScreen.swift.
@Composable
fun GuestAccountHero(onSignIn: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 18.dp, shape = RoundedCornerShape(24.dp), clip = false)
            .clip(RoundedCornerShape(24.dp))
            .background(TrendXColors.Surface)
            .padding(20.dp)
    ) {
        // Concentric circles with person+ icon
        Box(modifier = Modifier.size(132.dp), contentAlignment = Alignment.Center) {
            Box(modifier = Modifier
                .size(132.dp)
                .clip(CircleShape)
                .background(TrendXColors.Primary.copy(alpha = 0.10f)))
            Box(modifier = Modifier
                .size(108.dp)
                .clip(CircleShape)
                .border(1.5.dp, TrendXColors.Primary.copy(alpha = 0.18f), CircleShape))
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .shadow(elevation = 18.dp, shape = CircleShape, clip = false,
                        ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                    .size(88.dp)
                    .clip(CircleShape)
                    .background(TrendXGradients.Primary)
            ) {
                Icon(imageVector = Icons.Filled.PersonAdd, contentDescription = null,
                    tint = Color.White, modifier = Modifier.size(36.dp))
            }
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(text = "ابدأ رحلتك مع TRENDX",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                    color = TrendXColors.Ink))
            Text(
                text = "سجّل دخولك للمشاركة في الاستطلاعات، جمع النقاط، واستبدال الهدايا.",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 19.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 30.dp)
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            PitchTile(icon = Icons.Filled.Star, title = "اربح نقاط",
                tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
            PitchTile(icon = Icons.Filled.CardGiftcard, title = "استبدل هدايا",
                tint = TrendXColors.Success, modifier = Modifier.weight(1f))
            PitchTile(icon = Icons.Filled.MonitorHeart, title = "صوّت يومياً",
                tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
        }
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 14.dp, shape = RoundedCornerShape(16.dp), clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .clip(RoundedCornerShape(16.dp))
                .background(TrendXGradients.Primary)
                .clickable(onClick = onSignIn)
                .padding(vertical = 16.dp, horizontal = 18.dp)
        ) {
            Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(8.dp))
            Text(text = "سجّل دخولك الآن",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = Color.White))
            Spacer(Modifier.width(8.dp))
            Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(12.dp))
        }
    }
}

@Composable
private fun PitchTile(icon: ImageVector, title: String, tint: Color, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.12f))
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(16.dp))
        }
        Text(text = title, style = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Black,
            color = TrendXColors.SecondaryInk))
    }
}

// Mirrors StatsGrid + StatPill from AccountScreen.swift.
@Composable
fun StatsGrid(
    points: Int,
    coins: Double,
    voted: Int,
    followed: Int,
    modifier: Modifier = Modifier
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = modifier.fillMaxWidth().padding(horizontal = 20.dp)
    ) {
        StatPill(icon = Icons.Filled.Star, value = points.toString(), label = "نقطة",
            tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
        StatPill(icon = Icons.Filled.MonetizationOn, value = "%.1f".format(coins),
            label = "ريال", tint = TrendXColors.Success, modifier = Modifier.weight(1f))
        StatPill(icon = Icons.Filled.CheckCircle, value = voted.toString(),
            label = "تصويت", tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
        StatPill(icon = Icons.Filled.Favorite, value = followed.toString(),
            label = "اهتمام", tint = TrendXColors.AiViolet, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun StatPill(icon: ImageVector, value: String, label: String,
                     tint: Color, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
            .shadow(elevation = 5.dp, shape = RoundedCornerShape(16.dp), clip = false)
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .padding(vertical = 14.dp, horizontal = 4.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(18.dp))
        Text(text = value, style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp,
            color = TrendXColors.Ink), maxLines = 1)
        Text(text = label, style = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium,
            color = TrendXColors.SecondaryInk))
    }
}

// Mirrors AccountSection from AccountScreen.swift — small caption, then a
// rounded white card containing the rows with hairline dividers between.
@Composable
fun AccountSection(
    title: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = modifier.fillMaxWidth()
    ) {
        Text(text = title,
            style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Bold,
                color = TrendXColors.SecondaryInk),
            modifier = Modifier.padding(horizontal = 24.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .clip(RoundedCornerShape(18.dp))
                .background(TrendXColors.Surface)
                .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(18.dp))
        ) {
            content()
        }
    }
}

@Composable
fun SettingsDivider() {
    Box(modifier = Modifier
        .fillMaxWidth()
        .padding(start = 64.dp)
        .height(1.dp)
        .background(TrendXColors.Outline))
}

// Mirrors SettingsRow from AccountScreen.swift.
@Composable
fun SettingsRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String? = null,
    trailingText: String? = null,
    showBadge: Boolean = false,
    showChevron: Boolean = false,
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .let { if (onClick != null) it.clickable(onClick = onClick) else it }
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(iconColor.copy(alpha = 0.10f))
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = iconColor,
                modifier = Modifier.size(15.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = title, style = TextStyle(fontSize = 15.sp,
                fontWeight = FontWeight.Medium, color = TrendXColors.Ink))
            subtitle?.let {
                Text(text = it, style = TrendXType.Small,
                    color = TrendXColors.TertiaryInk, maxLines = 2)
            }
        }
        trailingText?.let {
            Text(text = it, style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = TrendXColors.SecondaryInk))
            Spacer(Modifier.width(6.dp))
        }
        if (showBadge) {
            Box(modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(TrendXColors.Error))
            Spacer(Modifier.width(6.dp))
        }
        Icon(
            imageVector = if (showChevron) Icons.Filled.ChevronLeft else Icons.Outlined.Info,
            contentDescription = null,
            tint = TrendXColors.TertiaryInk.copy(alpha = if (showChevron) 0.9f else 0.7f),
            modifier = Modifier.size(12.dp)
        )
    }
}

// Mirrors MyNetworkEntryCard from AccountScreen.swift.
@Composable
fun MyNetworkEntryCard(
    following: Int,
    followers: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(18.dp), clip = false)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Primary.copy(alpha = 0.18f), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 10.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .size(46.dp)
                .clip(CircleShape)
                .background(Brush.linearGradient(listOf(TrendXColors.AiIndigo, TrendXColors.Primary)))
        ) {
            Icon(imageVector = Icons.Filled.PeopleAlt, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = "شبكتي",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = TrendXColors.Ink))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(text = "$following يتابعهم",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.SecondaryInk))
                Text(text = "$followers متابعونك",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.SecondaryInk))
            }
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = TrendXColors.Primary, modifier = Modifier.size(12.dp))
    }
}

// Mirrors PublicProfileEntryCard from AccountScreen.swift.
@Composable
fun PublicProfileEntryCard(
    user: TrendXUser,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val tint = user.accountType.tint
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(18.dp), clip = false)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, tint.copy(alpha = 0.18f), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        AccountAvatar(user = user, size = 46.dp, showRing = true)
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = "صفحتي العامة",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = TrendXColors.Ink))
            Text(
                text = "هذه هي صفحتك كما يراها الآخرون — منشوراتك وإعادات نشرك",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk),
                maxLines = 2
            )
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = tint, modifier = Modifier.size(12.dp))
    }
}

// Sign-out button — only render in MainActivity when there is a real
// session, mirrors the iOS guard `if store.isRemoteEnabled && !store.isGuest`.
@Composable
fun SignOutButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 15.dp)
    ) {
        Icon(imageVector = Icons.Filled.Logout, contentDescription = null,
            tint = TrendXColors.Error, modifier = Modifier.size(16.dp))
        Spacer(Modifier.width(8.dp))
        Text(text = "تسجيل الخروج",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp,
                color = TrendXColors.Error))
    }
}

// Generic AI/Index entry card used for Opinion DNA and Predictive Accuracy.
@Composable
fun GenericEntryCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    accentBrush: Brush,
    accentColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 12.dp, shape = RoundedCornerShape(20.dp), clip = false,
                ambientColor = accentColor, spotColor = accentColor)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, accentColor.copy(alpha = 0.18f), RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 10.dp, shape = CircleShape, clip = false,
                    ambientColor = accentColor, spotColor = accentColor)
                .size(48.dp)
                .clip(CircleShape)
                .background(accentBrush)
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = Color.White,
                modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = title, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                color = TrendXColors.Ink))
            Text(text = subtitle,
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                    color = TrendXColors.TertiaryInk),
                maxLines = 2)
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = accentColor, modifier = Modifier.size(12.dp))
    }
}
