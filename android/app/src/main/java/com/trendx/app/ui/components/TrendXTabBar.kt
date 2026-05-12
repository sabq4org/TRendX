package com.trendx.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import com.trendx.app.store.TabItem
import com.trendx.app.theme.TrendXColors

// Floating tab bar — mirrors TrendXTabBar in iOS. Sits above the content
// at the bottom of the authed shell, semi-translucent, with a pill mark
// behind the active item.
@Composable
fun TrendXTabBar(
    selectedTab: TabItem,
    onSelectTab: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 12.dp)
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(28.dp), clip = false)
            .clip(RoundedCornerShape(28.dp))
            .background(TrendXColors.Surface.copy(alpha = 0.96f))
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(28.dp))
            .padding(horizontal = 6.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TabItem.entries.forEach { tab ->
            TabBarItem(
                tab = tab,
                isSelected = tab == selectedTab,
                onClick = { onSelectTab(tab) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun TabBarItem(
    tab: TabItem,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val tint by animateColorAsState(
        targetValue = if (isSelected) TrendXColors.Primary else TrendXColors.TertiaryInk,
        label = "tabTint"
    )
    val pillColor by animateColorAsState(
        targetValue = if (isSelected) TrendXColors.Primary.copy(alpha = 0.10f)
        else TrendXColors.Surface.copy(alpha = 0f),
        label = "tabPill"
    )

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .height(54.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(pillColor)
            .clickable(onClick = onClick)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(imageVector = tab.icon, contentDescription = tab.label, tint = tint,
                modifier = Modifier.size(22.dp))
            Text(text = tab.label, color = tint,
                style = androidx.compose.material3.MaterialTheme.typography.labelSmall)
        }
        if (isSelected) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 4.dp)
                    .size(width = 14.dp, height = 3.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.Primary)
            )
        }
    }
}
