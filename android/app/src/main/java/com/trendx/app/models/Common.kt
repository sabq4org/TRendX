package com.trendx.app.models

import kotlinx.serialization.Serializable

// Mirrors enums from TRENDX/Models/Models.swift. We model IDs as plain
// String everywhere — the backend already exchanges them as JSON strings,
// and skipping a UUID serializer keeps boilerplate down. Validate at
// the boundary if a screen needs strict guarantees.

@Serializable
enum class UserGender {
    male, female, other, unspecified;

    val displayName: String get() = when (this) {
        male -> "ذكر"
        female -> "أنثى"
        other -> "أخرى"
        unspecified -> "لا أحب التحديد"
    }
}

@Serializable
enum class UserRole { respondent, publisher, admin }

@Serializable
enum class UserTier { free, premium, enterprise }

@Serializable
enum class AccountType {
    individual, organization, government;

    val displayName: String get() = when (this) {
        individual -> "فرد"
        organization -> "منظّمة"
        government -> "جهة حكومية"
    }
}

@Serializable
enum class PollType(val raw: String) {
    SingleChoice("single_choice"),
    MultipleChoice("multiple_choice"),
    Rating("rating"),
    LinearScale("linear_scale");

    val displayName: String get() = when (this) {
        SingleChoice -> "اختيار واحد"
        MultipleChoice -> "متعدد الاختيار"
        Rating -> "تقييم"
        LinearScale -> "مقياس خطي"
    }

    companion object {
        fun fromRaw(value: String?): PollType = when (value) {
            "single_choice", "اختيار واحد", "singleChoice" -> SingleChoice
            "multiple_choice", "متعدد الاختيار", "multipleChoice" -> MultipleChoice
            "rating", "تقييم" -> Rating
            "linear_scale", "مقياس خطي", "linearScale" -> LinearScale
            else -> SingleChoice
        }
    }
}

@Serializable
enum class PollStatus(val raw: String) {
    Active("active"), Completed("ended"), Draft("draft");

    val displayName: String get() = when (this) {
        Active -> "نشط"
        Completed -> "مكتمل"
        Draft -> "مسودة"
    }

    companion object {
        fun fromRaw(value: String?): PollStatus = when (value) {
            "active", "نشط" -> Active
            "ended", "completed", "مكتمل" -> Completed
            "draft", "مسودة" -> Draft
            else -> Active
        }
    }
}
