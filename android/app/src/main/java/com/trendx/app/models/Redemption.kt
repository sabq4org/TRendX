package com.trendx.app.models

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlin.random.Random

// Mirrors `Redemption` from TRENDX/Models/Models.swift.
@Serializable
data class Redemption(
    val id: String,
    val giftId: String,
    val giftName: String,
    val brandName: String,
    val pointsSpent: Int,
    val valueInRiyal: Double,
    val redeemedAt: Instant,
    val code: String
) {
    companion object {
        fun makeCode(): String {
            val alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
            val suffix = (1..6).map { alphabet[Random.nextInt(alphabet.length)] }.joinToString("")
            return "TX-$suffix"
        }

        fun newId(): String {
            val random = (1..32).map {
                "0123456789abcdef"[Random.nextInt(16)]
            }.joinToString("")
            return random.chunked(8).joinToString("-").let {
                "$it-${random.takeLast(12)}"
            }.take(36)
        }

        /// Build a fresh Redemption locally — used when we redeem a gift
        /// while the backend `/rewards/redeem` endpoint is not yet wired
        /// from Android. Same shape as the iOS local fallback.
        fun fromGift(gift: Gift): Redemption = Redemption(
            id = newId(),
            giftId = gift.id,
            giftName = gift.name,
            brandName = gift.brandName,
            pointsSpent = gift.pointsRequired,
            valueInRiyal = gift.valueInRiyal,
            redeemedAt = Clock.System.now(),
            code = makeCode()
        )
    }
}
