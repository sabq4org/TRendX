package com.trendx.app.models

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.Coffee
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.trendx.app.theme.TrendXColors

// Mirrors `enum GiftCategory` from TRENDX/Screens/GiftsScreen.swift.
enum class GiftCategory(
    val rawValue: String?,
    val label: String,
    val tint: Color,
    val icon: ImageVector
) {
    All(null,         "الكل",     TrendXColors.Primary,                      Icons.Filled.GridView),
    Sweets("حلويات",  "حلويات",   Color(red = 0.92f, green = 0.44f, blue = 0.60f), Icons.Filled.Cake),
    Cafes("مقاهي",    "مقاهي",    Color(red = 0.56f, green = 0.36f, blue = 0.24f), Icons.Filled.Coffee),
    Cars("سيارات",    "سيارات",   Color(red = 0.28f, green = 0.40f, blue = 0.58f), Icons.Filled.DirectionsCar),
    Jewellery("Jewellery", "Jewellery", Color(red = 0.78f, green = 0.58f, blue = 0.22f), Icons.Filled.Diamond),
    Shopping("تسوق",  "تسوق",     Color(red = 0.18f, green = 0.62f, blue = 0.58f), Icons.Filled.ShoppingBag);
}

enum class GiftSortMode(val label: String) {
    AI("ترتيب TRENDX AI"),
    Affordable("المتاح أولاً"),
    Value("الأعلى قيمة")
}
