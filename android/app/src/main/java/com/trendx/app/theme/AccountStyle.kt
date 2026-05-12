package com.trendx.app.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.trendx.app.models.AccountType

// Mirrors AccountIdentity.swift extensions — visual identity for account
// types (individual / organization / government). Used everywhere an
// account name + avatar appears (cards, timeline, profile, comments).

val AccountType.tint: Color
    get() = when (this) {
        AccountType.individual   -> TrendXColors.Primary
        AccountType.organization -> TrendXColors.OrgGold
        AccountType.government   -> TrendXColors.SaudiGreen
    }

val AccountType.lightTint: Color
    get() = when (this) {
        AccountType.individual   -> TrendXColors.PrimaryLight
        AccountType.organization -> TrendXColors.OrgGoldLight
        AccountType.government   -> TrendXColors.SaudiGreenLight
    }

val AccountType.wash: Color
    get() = when (this) {
        AccountType.individual   -> TrendXColors.Primary.copy(alpha = 0.10f)
        AccountType.organization -> TrendXColors.OrgGoldWash
        AccountType.government   -> TrendXColors.SaudiGreenWash
    }

val AccountType.gradient: Brush
    get() = when (this) {
        AccountType.individual   -> TrendXGradients.Primary
        AccountType.organization -> TrendXGradients.OrgGold
        AccountType.government   -> TrendXGradients.SaudiGreen
    }

val AccountType.profileLabel: String
    get() = when (this) {
        AccountType.individual   -> "حساب فرد"
        AccountType.organization -> "حساب منظّمة"
        AccountType.government   -> "جهة رسمية"
    }

/// Avatar corner shape — circle for individuals, squircle for orgs/gov.
val AccountType.avatarCornerRadius: Int
    get() = when (this) {
        AccountType.individual   -> 999
        AccountType.organization -> 10
        AccountType.government   -> 8
    }
