package com.trendx.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Topic
import com.trendx.app.models.TrendXUser
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.AIInsightChip
import com.trendx.app.ui.components.AccountSection
import com.trendx.app.ui.components.GenericEntryCard
import com.trendx.app.ui.components.GuestAccountHero
import com.trendx.app.ui.components.MemberTierProgressCard
import com.trendx.app.ui.components.MyNetworkEntryCard
import com.trendx.app.ui.components.ProfileHeader
import com.trendx.app.ui.components.PublicProfileEntryCard
import com.trendx.app.ui.components.SettingsDivider
import com.trendx.app.ui.components.SettingsRow
import com.trendx.app.ui.components.SignOutButton
import com.trendx.app.ui.components.StatsGrid
import com.trendx.app.ui.components.TrendXIndexHomeCard

// Faithful Compose port of TRENDX/Screens/AccountScreen.swift. Same
// stack: profile hero (guest or authed) → stats → tier rail → social
// graph cards → AI/Index/Accuracy entry cards → AI summary chip →
// عام / المساعدة والدعم / القوانين sections → sign-out → version.
@Composable
fun AccountScreen(
    user: TrendXUser,
    isGuest: Boolean,
    isRemoteEnabled: Boolean,
    topics: List<Topic>,
    redemptionCount: Int = 0,
    lastRedemptionCode: String? = null,
    onSignInTap: () -> Unit,
    onSignOut: () -> Unit,
    onEditProfile: () -> Unit = {},
    onOpenNetwork: () -> Unit = {},
    onOpenPublicProfile: () -> Unit = {},
    onOpenOpinionDNA: () -> Unit = {},
    onOpenIndex: () -> Unit = {},
    onOpenPredictionAccuracy: () -> Unit = {},
    onOpenRedemptions: () -> Unit = {},
    onOpenPoints: () -> Unit = {},
    onOpenVotedPolls: () -> Unit = {},
    onOpenInterests: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val followedTopicNames = remember(topics, user.followedTopics) {
        topics.filter { it.isFollowing }.map { it.name }
    }
    val favoriteTopicsLine = if (followedTopicNames.isEmpty())
        "لم تحدد اهتمامات بعد"
    else followedTopicNames.take(3).joinToString("، ")

    val votedCount = user.completedPolls.size
    val followedCount = user.followedTopics.size
    val aiSummary = "رادارك الحالي يركز على: $favoriteTopicsLine. شاركت في $votedCount استطلاع واستبدلت $redemptionCount هدية حتى الآن."

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        LazyColumn(
            modifier = Modifier.fillMaxSize().statusBarsPadding(),
            contentPadding = PaddingValues(top = 16.dp, bottom = 140.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // Hero — guest or authed
            item("hero") {
                if (isGuest) {
                    GuestAccountHero(onSignIn = onSignInTap)
                } else {
                    ProfileHeader(user = user, onEdit = onEditProfile)
                }
            }

            item("stats") {
                StatsGrid(points = user.points, coins = user.coins,
                    voted = votedCount, followed = followedCount)
            }

            item("tier") {
                Box(modifier = Modifier.padding(horizontal = 20.dp)) {
                    MemberTierProgressCard(points = user.points)
                }
            }

            if (!isGuest) {
                item("network") {
                    MyNetworkEntryCard(
                        following = user.followingCount,
                        followers = user.followersCount,
                        onClick = onOpenNetwork
                    )
                }
                item("public-profile") {
                    PublicProfileEntryCard(user = user, onClick = onOpenPublicProfile)
                }
            }

            item("dna") {
                GenericEntryCard(
                    title = "بصمة الرأي",
                    subtitle = "الموضوعات الأقرب لك ونمط تصويتك على TRENDX",
                    icon = Icons.Filled.AutoAwesome,
                    accentBrush = TrendXGradients.Ai,
                    accentColor = TrendXColors.AiViolet,
                    onClick = onOpenOpinionDNA
                )
            }
            item("index") {
                Box(modifier = Modifier.fillMaxWidth()) {
                    TrendXIndexHomeCard(onClick = onOpenIndex)
                }
            }
            item("accuracy") {
                GenericEntryCard(
                    title = "دقة توقّعاتك",
                    subtitle = "كم مرة تنبّأت بالنتيجة الصحيحة قبل بقية المجتمع؟",
                    icon = Icons.Filled.TrendingUp,
                    accentBrush = Brush.linearGradient(listOf(
                        TrendXColors.Success, TrendXColors.AiCyan
                    )),
                    accentColor = TrendXColors.Success,
                    onClick = onOpenPredictionAccuracy
                )
            }

            item("ai-summary") {
                Box(modifier = Modifier.padding(horizontal = 20.dp)) {
                    AIInsightChip(text = aiSummary, label = "ملخص TRENDX AI")
                }
            }

            item("section-general") {
                AccountSection(title = "عام") {
                    SettingsRow(
                        icon = Icons.Filled.CardGiftcard,
                        iconColor = TrendXColors.AiViolet,
                        title = "الهدايا المكتسبة",
                        subtitle = lastRedemptionCode ?: "سيظهر آخر كود استبدال هنا",
                        trailingText = redemptionCount.toString(),
                        showChevron = true,
                        onClick = onOpenRedemptions
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Star,
                        iconColor = TrendXColors.Accent,
                        title = "النقاط",
                        trailingText = user.points.toString(),
                        showChevron = true,
                        onClick = onOpenPoints
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Description,
                        iconColor = TrendXColors.Success,
                        title = "استطلاعاتي المصوّت عليها",
                        trailingText = votedCount.toString(),
                        showChevron = true,
                        onClick = onOpenVotedPolls
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Settings,
                        iconColor = TrendXColors.Primary,
                        title = "اهتماماتي",
                        subtitle = favoriteTopicsLine,
                        showChevron = true,
                        onClick = onOpenInterests
                    )
                }
            }

            item("section-help") {
                AccountSection(title = "المساعدة والدعم") {
                    SettingsRow(
                        icon = Icons.Filled.Book,
                        iconColor = TrendXColors.Primary,
                        title = "دليل المجتمع",
                        subtitle = "احترام، وضوح، وعدم تكرار الأسئلة"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Info,
                        iconColor = TrendXColors.Info,
                        title = "من نحن",
                        subtitle = "TRENDX يجمع الرأي، المكافآت، والرؤى المحلية"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Help,
                        iconColor = TrendXColors.Accent,
                        title = "الأسئلة الشائعة",
                        subtitle = "التصويت يمنح نقاطاً، والهدايا تخصم من رصيدك"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.ChatBubble,
                        iconColor = TrendXColors.Info,
                        title = "الشكاوى والمقترحات",
                        subtitle = "قريباً: نموذج تواصل داخل التطبيق"
                    )
                }
            }

            item("section-legal") {
                AccountSection(title = "القوانين") {
                    SettingsRow(
                        icon = Icons.Filled.Lock,
                        iconColor = TrendXColors.Success,
                        title = "سياسة الخصوصية",
                        subtitle = "البيانات محفوظة محلياً على هذا الجهاز"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon = Icons.Filled.Description,
                        iconColor = TrendXColors.Primary,
                        title = "الشروط والأحكام",
                        subtitle = "نسخة أولية لتجربة TRENDX"
                    )
                }
            }

            if (isRemoteEnabled && !isGuest) {
                item("signout") { SignOutButton(onClick = onSignOut) }
            }

            item("version") {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                ) {
                    Text(text = "TRENDX",
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp,
                            color = TrendXColors.SecondaryInk))
                    Text(text = "الإصدار 1.0.0",
                        style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium,
                            color = TrendXColors.TertiaryInk))
                }
            }
        }
    }
}

