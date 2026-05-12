package com.trendx.app.ui.screens.intelligence

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.HourglassBottom
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Whatshot
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.networking.NotificationDto
import com.trendx.app.networking.notifications
import com.trendx.app.store.AppViewModel
import com.trendx.app.theme.TrendXColors
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.ToolbarTextPill
import kotlinx.coroutines.launch
import java.time.OffsetDateTime
import java.time.temporal.ChronoUnit

private const val READ_PREFS = "trendx_notifications_v1"
private const val READ_KEY = "trendx_notifications_read_v1"

class NotificationsReadStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(READ_PREFS, Context.MODE_PRIVATE)

    fun read(): Set<String> = prefs.getStringSet(READ_KEY, emptySet()) ?: emptySet()

    fun markRead(id: String) {
        val current = read().toMutableSet()
        if (current.add(id)) prefs.edit().putStringSet(READ_KEY, current).apply()
    }

    fun markAllRead(ids: List<String>) {
        val current = read().toMutableSet()
        if (current.addAll(ids)) prefs.edit().putStringSet(READ_KEY, current).apply()
    }
}

@Composable
fun NotificationsInboxScreen(
    vm: AppViewModel,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val store = remember { NotificationsReadStore(context) }
    var notifications by remember { mutableStateOf<List<NotificationDto>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var readIds by remember { mutableStateOf(store.read()) }
    val scope = rememberCoroutineScope()
    val accessToken = vm.accessToken

    suspend fun load() {
        val token = accessToken ?: return
        isLoading = true
        runCatching { vm.apiClient.notifications(token) }
            .onSuccess { notifications = it }
        isLoading = false
    }

    LaunchedEffect(Unit) { load() }

    val unreadCount = notifications.count { it.id !in readIds }

    DetailScreenScaffold(
        title = "الإشعارات",
        onClose = onClose,
        trailing = {
            if (notifications.isNotEmpty() && unreadCount > 0) {
                ToolbarTextPill(label = "تعليم الكل كمقروء") {
                    store.markAllRead(notifications.map { it.id })
                    readIds = store.read()
                }
            }
        },
        modifier = modifier
    ) {
        Box(modifier = Modifier.fillMaxSize().background(TrendXColors.Background)) {
            when {
                isLoading && notifications.isEmpty() -> Box(Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = TrendXColors.Primary)
                }
                notifications.isEmpty() -> NotificationsEmptyState()
                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize()
                        .padding(horizontal = 20.dp, vertical = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(notifications, key = { it.id }) { n ->
                        NotificationCard(
                            notification = n,
                            isRead = n.id in readIds,
                            onTap = {
                                store.markRead(n.id)
                                readIds = store.read()
                                handleRoute(n.ctaRoute, vm, onClose)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationsEmptyState() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Filled.Notifications, contentDescription = null,
                tint = TrendXColors.TertiaryInk, modifier = Modifier.size(36.dp))
            Text("لا توجد إشعارات الآن",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = TrendXColors.Ink))
            Text("شارك في استطلاع أو افتح تحدّي الأسبوع وسنعلمك بالتطورات.",
                style = TextStyle(fontSize = 13.sp, color = TrendXColors.SecondaryInk),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 30.dp))
        }
    }
}

@Composable
private fun NotificationCard(
    notification: NotificationDto,
    isRead: Boolean,
    onTap: () -> Unit
) {
    val tint = kindTint(notification.kind)
    val borderColor = if (isRead) TrendXColors.Outline.copy(alpha = 0.4f)
                      else tint.copy(alpha = 0.22f)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(8.dp, RoundedCornerShape(16.dp), clip = false,
                ambientColor = if (isRead) Color.Transparent else tint.copy(alpha = 0.2f),
                spotColor = if (isRead) Color.Transparent else tint.copy(alpha = 0.2f))
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, borderColor, RoundedCornerShape(16.dp))
            .clickable(onClick = onTap)
            .padding(14.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(42.dp).clip(CircleShape)
                .background(tint.copy(alpha = 0.14f))
        ) {
            Icon(kindIcon(notification.icon), contentDescription = null,
                tint = tint, modifier = Modifier.size(16.dp))
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp),
            modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(notification.title,
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                        color = TrendXColors.Ink),
                    modifier = Modifier.weight(1f))
                if (!isRead) {
                    Box(modifier = Modifier.size(7.dp).clip(CircleShape).background(tint))
                }
            }
            Text(notification.body,
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.5.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 18.sp))
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(top = 2.dp)) {
                Text(relativeTime(notification.occurredAt),
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.5.sp,
                        color = TrendXColors.TertiaryInk))
                notification.ctaLabel?.let { cta ->
                    Text("·",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.5.sp,
                            color = TrendXColors.TertiaryInk))
                    Text(cta,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = tint))
                }
            }
        }
    }
}

private fun kindTint(kind: String): Color = when (kind) {
    "close_to_gift" -> TrendXColors.Accent
    "pulse_pending" -> TrendXColors.Primary
    "challenge_open" -> TrendXColors.AiIndigo
    "expiring_poll" -> TrendXColors.Warning
    "reward_earned" -> TrendXColors.Success
    "new_from_following" -> TrendXColors.Primary
    "event_started" -> Color(red = 242, green = 140, blue = 51)
    "national_poll" -> TrendXColors.SaudiGreen
    "sector_takeover" -> TrendXColors.SaudiGreen
    else -> TrendXColors.Primary
}

private fun kindIcon(systemName: String): ImageVector = when (systemName) {
    "gift", "gift.fill" -> Icons.Filled.CardGiftcard
    "bolt.heart.fill", "bolt.fill" -> Icons.Filled.Bolt
    "target" -> Icons.Filled.GpsFixed
    "flame.fill" -> Icons.Filled.Whatshot
    "star.fill" -> Icons.Filled.Star
    "person.crop.circle.badge.plus" -> Icons.Filled.PersonAdd
    "calendar.badge.clock", "calendar" -> Icons.Filled.Event
    "flag.fill" -> Icons.Filled.Flag
    "sparkles" -> Icons.Filled.AutoAwesome
    "hourglass" -> Icons.Filled.HourglassBottom
    "diamond.fill" -> Icons.Filled.Diamond
    else -> Icons.Filled.Notifications
}

private fun handleRoute(route: String?, vm: AppViewModel, onClose: () -> Unit) {
    if (route == null) return
    when {
        route == "gifts" -> { vm.selectTab(com.trendx.app.store.TabItem.Gifts); onClose() }
        route == "pulse" || route == "challenge" -> {
            vm.selectTab(com.trendx.app.store.TabItem.Home); onClose()
        }
        route.startsWith("poll:") -> { vm.selectTab(com.trendx.app.store.TabItem.Polls); onClose() }
    }
}

private fun relativeTime(iso: String): String {
    val dt = runCatching { OffsetDateTime.parse(iso) }.getOrNull() ?: return ""
    val now = OffsetDateTime.now()
    val seconds = ChronoUnit.SECONDS.between(dt, now).coerceAtLeast(0)
    return when {
        seconds < 60 -> "الآن"
        seconds < 3600 -> "قبل ${seconds / 60} د"
        seconds < 86_400 -> "قبل ${seconds / 3600} س"
        seconds < 604_800 -> "قبل ${seconds / 86_400} ي"
        seconds < 2_592_000 -> "قبل ${seconds / 604_800} أسبوع"
        else -> "قبل ${seconds / 2_592_000} شهر"
    }
}
