package com.trendx.app.models

import kotlinx.datetime.Instant

// Mirrors `TrendXLedgerEntry` from the iOS app — the rows you see on the
// "النقاط" detail screen: amount earned/spent, the action that produced
// it, and the running balance after the change.
data class LedgerEntry(
    val id: String,
    val amount: Int,
    val type: String,
    val refType: String?,
    val refId: String?,
    val description: String?,
    val balanceAfter: Int,
    val createdAt: Instant?
) {
    val isCredit: Boolean get() = amount > 0
    val isDebit: Boolean get() = amount < 0

    /// Friendly Arabic label for the action that produced this entry.
    val typeDisplay: String get() = when (type) {
        "vote_reward" -> "مكافأة تصويت"
        "daily_bonus" -> "مكافأة يومية"
        "redemption" -> "استبدال هدية"
        "challenge_reward" -> "مكافأة تحدّي"
        "signup_bonus" -> "مكافأة تسجيل"
        "manual" -> "تسوية يدوية"
        else -> type
    }
}
