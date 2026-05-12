package com.trendx.app.models

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Coffee
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.trendx.app.theme.TrendXColors
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable

@Serializable
data class Gift(
    val id: String,
    val name: String,
    val brandName: String,
    val brandLogo: String = "",
    val category: String,
    val pointsRequired: Int,
    val valueInRiyal: Double,
    val imageUrl: String? = null,
    val isRedeemAtStore: Boolean = true,
    val isAvailable: Boolean = true,
    val weeklyRedemptions: Int = 0,
    val lastRedeemedAt: Instant? = null
) {
    val categoryIcon: ImageVector get() = when (category) {
        "حلويات" -> Icons.Filled.Cake
        "مقاهي" -> Icons.Filled.Coffee
        "سيارات" -> Icons.Filled.DirectionsCar
        "Jewellery" -> Icons.Filled.Diamond
        "تسوق" -> Icons.Filled.ShoppingBag
        else -> Icons.Filled.CardGiftcard
    }

    val categoryTint: Color get() = when (category) {
        "حلويات" -> Color(red = 0.92f, green = 0.44f, blue = 0.60f)
        "مقاهي" -> Color(red = 0.56f, green = 0.36f, blue = 0.24f)
        "سيارات" -> Color(red = 0.28f, green = 0.40f, blue = 0.58f)
        "Jewellery" -> Color(red = 0.78f, green = 0.58f, blue = 0.22f)
        "تسوق" -> Color(red = 0.18f, green = 0.62f, blue = 0.58f)
        else -> TrendXColors.Primary
    }

    val brandMonogram: String get() {
        val trimmed = brandName.trim()
        val first = trimmed.take(1).uppercase()
        val words = trimmed.split(' ').filter { it.isNotEmpty() }
        return when {
            words.size >= 2 -> first + words[1].first().toString().uppercase()
            trimmed.length >= 2 -> trimmed.take(2).uppercase()
            else -> first
        }
    }

    companion object {
        // Mirrors Gift.samples from iOS — keeps GiftsScreen non-empty offline.
        val samples: List<Gift> = listOf(
            Gift(giftId(1), "قسيمة قهوة", "Starbucks", category = "مقاهي",
                pointsRequired = 120, valueInRiyal = 20.0),
            Gift(giftId(2), "حلويات مختارة", "AANI & DANI", category = "حلويات",
                pointsRequired = 180, valueInRiyal = 30.0),
            Gift(giftId(3), "قسيمة تسوّق", "Amazon", category = "تسوق",
                pointsRequired = 300, valueInRiyal = 50.0),
            Gift(giftId(4), "خدمة عناية بالسيارة", "3M AutoCare", category = "سيارات",
                pointsRequired = 360, valueInRiyal = 60.0),
            Gift(giftId(5), "قسيمة مجوهرات", "AbdulGhani Heritage", category = "Jewellery",
                pointsRequired = 480, valueInRiyal = 80.0),
            Gift(giftId(6), "قطعة مميّزة", "AbdulGhani", category = "Jewellery",
                pointsRequired = 600, valueInRiyal = 100.0),
            Gift(giftId(7), "فطور الصباح", "Dose Café", category = "مقاهي",
                pointsRequired = 150, valueInRiyal = 25.0),
            Gift(giftId(8), "سلة حلا", "Bateel", category = "حلويات",
                pointsRequired = 420, valueInRiyal = 70.0)
        )

        private fun giftId(n: Int) = "20000000-0000-0000-0000-${"%012d".format(n)}"
    }
}
