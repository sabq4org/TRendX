package com.trendx.app.ui.screens

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Gift
import com.trendx.app.models.GiftCategory
import com.trendx.app.models.GiftSortMode
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.EmptyStateView
import com.trendx.app.ui.components.GiftCard
import com.trendx.app.ui.components.TrendXSearchBar
import com.trendx.app.ui.components.WalletHero

// Faithful Compose port of TRENDX/Screens/GiftsScreen.swift. Header,
// Wallet hero, AI picks horizontal carousel, search, category strip,
// "كتالوج الهدايا" header with sort menu, and a 2-column LazyVerticalGrid
// of GiftCards. Tapping a card opens the redemption confirmation.
@Composable
fun GiftsScreen(
    gifts: List<Gift>,
    points: Int,
    coins: Double,
    onOpenHistory: () -> Unit,
    onSelectGift: (Gift) -> Unit,
    modifier: Modifier = Modifier
) {
    var searchText by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf(GiftCategory.All) }
    var sortMode by remember { mutableStateOf(GiftSortMode.AI) }
    var showSortMenu by remember { mutableStateOf(false) }

    val minimumForRedeem = remember(gifts) {
        gifts.minOfOrNull { it.pointsRequired } ?: 120
    }

    val filteredGifts = remember(gifts, searchText, selectedCategory, sortMode, points) {
        var list = gifts
        if (searchText.isNotBlank()) {
            list = list.filter {
                it.name.contains(searchText, ignoreCase = true) ||
                    it.brandName.contains(searchText, ignoreCase = true)
            }
        }
        selectedCategory.rawValue?.let { raw ->
            list = list.filter { it.category == raw }
        }
        when (sortMode) {
            GiftSortMode.AI -> list.sortedByDescending { aiScore(it, points) }
            GiftSortMode.Affordable -> list.sortedWith(
                compareByDescending<Gift> { points >= it.pointsRequired }
                    .thenBy { it.pointsRequired }
            )
            GiftSortMode.Value -> list.sortedByDescending {
                it.valueInRiyal / it.pointsRequired.coerceAtLeast(1)
            }
        }
    }

    val aiPicks = remember(gifts, points) {
        gifts.map { gift ->
            val ratio = if (points > 0) gift.pointsRequired.toDouble() / points else 2.0
            val closeness = when {
                ratio <= 1.0 -> 1.0 - (1.0 - ratio) * 0.3
                ratio <= 1.5 -> 1.2 - (ratio - 1.0)
                else -> (1.0 / ratio).coerceAtLeast(0.1)
            }
            val valueRatio = gift.valueInRiyal / gift.pointsRequired.coerceAtLeast(1)
            gift to (closeness * 0.7 + valueRatio * 3.0)
        }.sortedByDescending { it.second }.take(6).map { it.first }
    }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        LazyColumn(
            modifier = Modifier.fillMaxSize().statusBarsPadding(),
            contentPadding = PaddingValues(top = 14.dp, bottom = 140.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            item("header") {
                GiftsHeader(onHistoryTap = onOpenHistory)
            }
            item("wallet") {
                WalletHero(points = points, coins = coins, minimumForRedeem = minimumForRedeem)
            }
            if (aiPicks.isNotEmpty()) {
                item("ai-picks") {
                    AIPicksStrip(gifts = aiPicks, userPoints = points,
                        onSelect = onSelectGift)
                }
            }
            item("search") {
                Box(modifier = Modifier.padding(horizontal = 20.dp)) {
                    TrendXSearchBar(
                        text = searchText,
                        onTextChange = { searchText = it },
                        placeholder = "ابحث عن علامة أو هدية…"
                    )
                }
            }
            item("categories") {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    contentPadding = PaddingValues(horizontal = 20.dp)
                ) {
                    items(GiftCategory.entries.toList()) { category ->
                        CategoryChip(
                            category = category,
                            isSelected = selectedCategory == category,
                            onClick = { selectedCategory = category }
                        )
                    }
                }
            }
            item("catalog-header") {
                Box(modifier = Modifier.padding(horizontal = 20.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(text = "كتالوج الهدايا", style = TrendXType.Subheadline,
                                color = TrendXColors.Ink)
                            Text(text = "${filteredGifts.size} هدية متاحة",
                                style = TextStyle(fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = TrendXColors.TertiaryInk))
                        }
                        SortMenu(
                            current = sortMode,
                            expanded = showSortMenu,
                            onExpandedChange = { showSortMenu = it },
                            onSelect = { sortMode = it; showSortMenu = false }
                        )
                    }
                }
            }
            if (filteredGifts.isEmpty()) {
                item("empty") {
                    Box(modifier = Modifier.padding(20.dp)) {
                        EmptyStateView(
                            icon = Icons.Filled.CardGiftcard,
                            title = "لا توجد هدايا مطابقة",
                            message = "جرّب فئة أخرى أو ابحث باسم علامة تجارية."
                        )
                    }
                }
            } else {
                item("grid") {
                    GiftsGrid(gifts = filteredGifts, points = points,
                        onSelect = onSelectGift)
                }
            }
        }
    }
}

@Composable
private fun GiftsHeader(onHistoryTap: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = "الهدايا", style = TrendXType.Headline, color = TrendXColors.Ink)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                    tint = TrendXColors.AiIndigo, modifier = Modifier.size(10.dp))
                Spacer(Modifier.width(5.dp))
                Text(text = "هدايا مختارة لك بواسطة TRENDX AI",
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium,
                        color = TrendXColors.TertiaryInk))
            }
        }
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(TrendXColors.Surface)
                .border(0.8.dp, TrendXColors.Outline, CircleShape)
                .clickable(onClick = onHistoryTap)
        ) {
            Icon(imageVector = Icons.Filled.History, contentDescription = "السجل",
                tint = TrendXColors.SecondaryInk, modifier = Modifier.size(15.dp))
        }
    }
}

@Composable
private fun AIPicksStrip(
    gifts: List<Gift>,
    userPoints: Int,
    onSelect: (Gift) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(30.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.AiIndigo.copy(alpha = 0.10f))
            ) {
                Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                    tint = TrendXColors.AiIndigo, modifier = Modifier.size(12.dp))
            }
            Spacer(Modifier.width(10.dp))
            Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Text(text = "مختارة لك", style = TrendXType.Subheadline, color = TrendXColors.Ink)
                Text(text = "TRENDX AI يختار الأقرب لرصيدك",
                    style = TextStyle(fontSize = 11.5.sp, fontWeight = FontWeight.Medium,
                        color = TrendXColors.TertiaryInk))
            }
        }
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(horizontal = 20.dp)
        ) {
            items(gifts, key = { it.id }) { gift ->
                AIPickCard(gift = gift, userPoints = userPoints,
                    onTap = { onSelect(gift) })
            }
        }
    }
}

@Composable
private fun AIPickCard(gift: Gift, userPoints: Int, onTap: () -> Unit) {
    val canAfford = userPoints >= gift.pointsRequired
    val tint = gift.categoryTint

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .width(136.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
            .clickable(onClick = onTap)
            .padding(vertical = 16.dp, horizontal = 10.dp)
    ) {
        Box(modifier = Modifier.size(74.dp), contentAlignment = Alignment.Center) {
            Box(modifier = Modifier
                .size(74.dp)
                .clip(RoundedCornerShape(18.dp))
                .background(androidx.compose.ui.graphics.Brush.linearGradient(listOf(
                    tint, Color(red = (tint.red + 0.2f).coerceAtMost(1f),
                        green = (tint.green + 0.2f).coerceAtMost(1f),
                        blue = (tint.blue + 0.2f).coerceAtMost(1f))
                ))))
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.18f))
            ) {
                Text(text = gift.brandMonogram, style = TextStyle(
                    fontWeight = FontWeight.Black, fontSize = 20.sp, color = Color.White))
            }
            if (canAfford) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .size(18.dp)
                        .clip(CircleShape)
                        .background(TrendXColors.Surface)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Verified,
                        contentDescription = null,
                        tint = TrendXColors.Success,
                        modifier = Modifier.size(14.dp)
                    )
                }
            }
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(text = gift.brandName, style = TextStyle(
                fontWeight = FontWeight.Bold, fontSize = 12.5.sp, color = TrendXColors.Ink),
                maxLines = 1)
            Text(text = gift.category, style = TextStyle(
                fontSize = 10.5.sp, fontWeight = FontWeight.Medium,
                color = TrendXColors.TertiaryInk), maxLines = 1)
        }
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Accent.copy(alpha = 0.12f))
                .padding(horizontal = 10.dp, vertical = 5.dp)
        ) {
            Icon(imageVector = Icons.Filled.Star,
                contentDescription = null, tint = TrendXColors.Accent,
                modifier = Modifier.size(11.dp))
            Spacer(Modifier.width(4.dp))
            Text(text = gift.pointsRequired.toString(), style = TextStyle(
                fontWeight = FontWeight.Black, fontSize = 12.sp,
                color = TrendXColors.AccentDeep))
        }
    }
}

@Composable
private fun CategoryChip(
    category: GiftCategory,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val bg = if (isSelected) category.tint else TrendXColors.Surface
    val fg = if (isSelected) Color.White else TrendXColors.SecondaryInk
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .border(0.8.dp,
                if (isSelected) Color.Transparent else TrendXColors.Outline, CircleShape)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp)
    ) {
        Icon(imageVector = category.icon, contentDescription = null, tint = fg,
            modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = category.label,
            style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = fg))
    }
}

@Composable
private fun SortMenu(
    current: GiftSortMode,
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    onSelect: (GiftSortMode) -> Unit
) {
    Box {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Surface)
                .border(0.8.dp, TrendXColors.Outline, CircleShape)
                .clickable { onExpandedChange(true) }
                .padding(horizontal = 12.dp, vertical = 8.dp)
        ) {
            Icon(imageVector = Icons.Filled.Tune, contentDescription = null,
                tint = TrendXColors.SecondaryInk, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(6.dp))
            Text(text = "ترتيب", style = TextStyle(fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold, color = TrendXColors.SecondaryInk))
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { onExpandedChange(false) }) {
            GiftSortMode.entries.forEach { mode ->
                DropdownMenuItem(
                    text = { Text(text = mode.label) },
                    onClick = { onSelect(mode) }
                )
            }
        }
    }
}

@Composable
private fun GiftsGrid(gifts: List<Gift>, points: Int, onSelect: (Gift) -> Unit) {
    // We're inside a LazyColumn already, so a nested LazyVerticalGrid would
    // throw "Vertically scrollable component was measured with infinite
    // height". Lay out the grid manually as 2-up rows instead.
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)
    ) {
        gifts.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                row.forEach { gift ->
                    GiftCard(
                        gift = gift,
                        userPoints = points,
                        onTap = { onSelect(gift) },
                        modifier = Modifier.weight(1f)
                    )
                }
                if (row.size == 1) {
                    // Pad the last odd row so the single card stays half-width.
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

private fun aiScore(gift: Gift, points: Int): Double {
    val ratio = if (points > 0) gift.pointsRequired.toDouble() / points else 2.0
    val closeness = if (ratio <= 1.0) 1.0 else (1.4 - ratio).coerceAtLeast(0.1)
    val valueRatio = gift.valueInRiyal / gift.pointsRequired.coerceAtLeast(1)
    return closeness * 0.7 + valueRatio * 3.0
}
