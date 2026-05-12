package com.trendx.app.store

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Home
import androidx.compose.ui.graphics.vector.ImageVector

// Mirrors TabItem on iOS — same order so analytics/copy stay aligned.
enum class TabItem(val label: String, val icon: ImageVector) {
    Home("الرئيسية", Icons.Filled.Home),
    Polls("الاستطلاعات", Icons.Filled.BarChart),
    Gifts("الهدايا", Icons.Filled.CardGiftcard),
    Account("حسابي", Icons.Filled.AccountCircle)
}
