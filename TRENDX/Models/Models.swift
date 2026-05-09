//
//  Models.swift
//  TRENDX
//

import Foundation
import SwiftUI

// MARK: - User Model

struct TrendXUser: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var avatarInitial: String
    var points: Int
    var coins: Double
    var followedTopics: [UUID]
    var completedPolls: [UUID]
    var isPremium: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "مستخدم",
        email: String = "",
        avatarInitial: String = "م",
        points: Int = 100,
        coins: Double = 16.67,
        followedTopics: [UUID] = [],
        completedPolls: [UUID] = [],
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarInitial = avatarInitial
        self.points = points
        self.coins = coins
        self.followedTopics = followedTopics
        self.completedPolls = completedPolls
        self.isPremium = isPremium
    }
}

// MARK: - Topic Model

struct Topic: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var followersCount: Int
    var postsCount: Int
    var isFollowing: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String = "blue",
        followersCount: Int = 0,
        postsCount: Int = 0,
        isFollowing: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.followersCount = followersCount
        self.postsCount = postsCount
        self.isFollowing = isFollowing
    }
    
    /// A coherent, distinct color per topic — derived from the same palette
    /// the poll covers use so the entire app feels visually unified.
    /// Explicitly avoids the app's primary blue so topics read as their *own*
    /// identity and don't blend into UI chrome.
    var topicColor: Color {
        PollCoverStyle.from(topicName: name).tint
    }

    var topicGradient: [Color] {
        PollCoverStyle.from(topicName: name).gradient
    }
}

// MARK: - Poll Option

struct PollOption: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var votesCount: Int
    var percentage: Double
    
    init(id: UUID = UUID(), text: String, votesCount: Int = 0, percentage: Double = 0) {
        self.id = id
        self.text = text
        self.votesCount = votesCount
        self.percentage = percentage
    }
}

// MARK: - Poll Cover Style

enum PollCoverStyle: String, Codable, CaseIterable {
    case tech, economy, sports, social, media, health, food, travel, generic

    /// Single glyph used as a subtle watermark in the editorial cover —
    /// never as a loud floating clip-art element.
    var glyph: String {
        switch self {
        case .tech:    return "cpu"
        case .economy: return "chart.line.uptrend.xyaxis"
        case .sports:  return "soccerball"
        case .social:  return "person.2.wave.2.fill"
        case .media:   return "newspaper.fill"
        case .health:  return "heart.text.square.fill"
        case .food:    return "fork.knife"
        case .travel:  return "airplane"
        case .generic: return "sparkle"
        }
    }

    /// Deep → light gradient used only on the editorial cover hero.
    /// Carefully saturated so topics feel distinct without screaming.
    var gradient: [Color] {
        switch self {
        case .tech:
            return [Color(red: 0.28, green: 0.22, blue: 0.68), Color(red: 0.54, green: 0.36, blue: 0.92)]
        case .economy:
            return [Color(red: 0.08, green: 0.44, blue: 0.36), Color(red: 0.22, green: 0.68, blue: 0.52)]
        case .sports:
            return [Color(red: 0.92, green: 0.38, blue: 0.16), Color(red: 0.98, green: 0.62, blue: 0.24)]
        case .social:
            return [Color(red: 0.08, green: 0.48, blue: 0.56), Color(red: 0.30, green: 0.74, blue: 0.78)]
        case .media:
            return [Color(red: 0.56, green: 0.22, blue: 0.60), Color(red: 0.88, green: 0.40, blue: 0.72)]
        case .health:
            return [Color(red: 0.86, green: 0.28, blue: 0.38), Color(red: 0.96, green: 0.50, blue: 0.48)]
        case .food:
            return [Color(red: 0.88, green: 0.36, blue: 0.20), Color(red: 0.98, green: 0.70, blue: 0.32)]
        case .travel:
            return [Color(red: 0.12, green: 0.46, blue: 0.78), Color(red: 0.38, green: 0.74, blue: 0.94)]
        case .generic:
            return [Color(red: 0.28, green: 0.30, blue: 0.44), Color(red: 0.52, green: 0.58, blue: 0.72)]
        }
    }

    /// Editorial label shown on the hero cover and as a chip.
    var label: String {
        switch self {
        case .tech:    return "تقنية"
        case .economy: return "اقتصاد"
        case .sports:  return "رياضة"
        case .social:  return "مجتمع"
        case .media:   return "إعلام"
        case .health:  return "صحة"
        case .food:    return "طعام"
        case .travel:  return "سفر"
        case .generic: return "عام"
        }
    }

    /// Editorial pull-quote for the cover hero.
    var heroPhrase: String {
        switch self {
        case .tech:    return "نبض التقنية"
        case .economy: return "حركة الاقتصاد"
        case .sports:  return "روح الرياضة"
        case .social:  return "صوت المجتمع"
        case .media:   return "مشهد إعلامي"
        case .health:  return "صحة وعافية"
        case .food:    return "مذاق اليوم"
        case .travel:  return "وجهات ملهمة"
        case .generic: return "اتجاه صاعد"
        }
    }

    /// The single defining topic color — used for stripes, avatar rings,
    /// selected option tint, badges, shadows. Picked so no two topics
    /// read as "the same blue" and none clash with the app's primary.
    var tint: Color {
        switch self {
        case .tech:    return Color(red: 0.42, green: 0.32, blue: 0.88)   // indigo-violet
        case .economy: return Color(red: 0.10, green: 0.60, blue: 0.46)   // emerald
        case .sports:  return Color(red: 0.92, green: 0.48, blue: 0.18)   // amber-orange
        case .social:  return Color(red: 0.10, green: 0.58, blue: 0.66)   // teal
        case .media:   return Color(red: 0.74, green: 0.30, blue: 0.66)   // magenta-plum
        case .health:  return Color(red: 0.90, green: 0.34, blue: 0.44)   // rose
        case .food:    return Color(red: 0.92, green: 0.46, blue: 0.22)   // coral
        case .travel:  return Color(red: 0.18, green: 0.58, blue: 0.88)   // sky
        case .generic: return Color(red: 0.40, green: 0.44, blue: 0.58)   // slate
        }
    }

    /// Very light wash (~8%) for subtle pill fills & result bars.
    var wash: Color { tint.opacity(0.10) }

    /// Soft border tint for outlines (~24%).
    var hairline: Color { tint.opacity(0.22) }

    static func from(topicName: String?) -> PollCoverStyle {
        guard let name = topicName?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return .generic
        }
        switch name {
        case "تقنية":     return .tech
        case "اقتصاد":    return .economy
        case "رياضة":     return .sports
        case "اجتماعية":  return .social
        case "إعلام":     return .media
        case "صحة":       return .health
        case "طعام":      return .food
        case "سفر":       return .travel
        default:          return .generic
        }
    }
}

// MARK: - Poll Model

enum PollType: String, Codable, CaseIterable {
    case singleChoice = "اختيار واحد"
    case multipleChoice = "متعدد الاختيار"
    case rating = "تقييم"
    case linearScale = "مقياس خطي"
}

enum PollStatus: String, Codable {
    case active = "نشط"
    case completed = "مكتمل"
    case draft = "مسودة"
}

struct Poll: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String?
    var imageURL: String?
    /// Visual theme for the generated cover when no imageURL is provided
    var coverStyle: PollCoverStyle?
    var authorName: String
    var authorAvatar: String
    var authorIsVerified: Bool
    var options: [PollOption]
    var topicId: UUID?
    var topicName: String?
    var type: PollType
    var status: PollStatus
    var totalVotes: Int
    var rewardPoints: Int
    var durationDays: Int
    var createdAt: Date
    var expiresAt: Date
    var userVotedOptionId: UUID?
    var isBookmarked: Bool
    var sharesCount: Int
    var repostsCount: Int
    /// Optional AI-generated insight shown as an elegant chip inside the card
    var aiInsight: String?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        imageURL: String? = nil,
        coverStyle: PollCoverStyle? = nil,
        authorName: String = "مستخدم",
        authorAvatar: String = "م",
        authorIsVerified: Bool = false,
        options: [PollOption] = [],
        topicId: UUID? = nil,
        topicName: String? = nil,
        type: PollType = .singleChoice,
        status: PollStatus = .active,
        totalVotes: Int = 0,
        rewardPoints: Int = 50,
        durationDays: Int = 7,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        userVotedOptionId: UUID? = nil,
        isBookmarked: Bool = false,
        sharesCount: Int = 0,
        repostsCount: Int = 0,
        aiInsight: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.coverStyle = coverStyle
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.authorIsVerified = authorIsVerified
        self.options = options
        self.topicId = topicId
        self.topicName = topicName
        self.type = type
        self.status = status
        self.totalVotes = totalVotes
        self.rewardPoints = rewardPoints
        self.durationDays = durationDays
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.userVotedOptionId = userVotedOptionId
        self.isBookmarked = isBookmarked
        self.sharesCount = sharesCount
        self.repostsCount = repostsCount
        self.aiInsight = aiInsight
    }
    
    var hasUserVoted: Bool {
        userVotedOptionId != nil
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var remainingDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresAt)
        return max(0, components.day ?? 0)
    }

    var remainingHours: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: Date(), to: expiresAt)
        return max(0, components.hour ?? 0)
    }

    /// Human readable deadline, e.g. "يبقى 3 أيام" / "ينتهي خلال 5 ساعات" / "انتهى"
    var deadlineLabel: String {
        if isExpired { return "انتهى" }
        if remainingDays >= 1 { return "يبقى \(remainingDays) يوم" }
        if remainingHours >= 1 { return "ينتهي خلال \(remainingHours) ساعة" }
        return "ينتهي قريباً"
    }

    /// Returns true when the poll ends within 24 hours (still active)
    var isEndingSoon: Bool {
        !isExpired && remainingDays == 0
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Always-available topic style — used for per-card visual identity
    /// (stripe, avatar ring, selected option tint, shadow) even when no
    /// cover image is rendered.
    var topicStyle: PollCoverStyle {
        coverStyle ?? PollCoverStyle.from(topicName: topicName)
    }

    /// Whether to show the large editorial cover. Existing generated styles
    /// act as polished visual covers when no remote image is attached.
    var shouldShowCover: Bool {
        imageURL != nil || coverStyle != nil
    }
}

// MARK: - Gift Model

struct Gift: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var brandName: String
    var brandLogo: String
    var category: String
    var pointsRequired: Int
    var valueInRiyal: Double
    var imageURL: String?
    var isRedeemAtStore: Bool
    var isAvailable: Bool

    // MARK: - UI helpers

    /// Single brand-flavored tint used on the gift card visuals.
    var categoryTint: Color {
        switch category {
        case "حلويات":    return Color(red: 0.92, green: 0.44, blue: 0.60)
        case "مقاهي":     return Color(red: 0.56, green: 0.36, blue: 0.24)
        case "سيارات":    return Color(red: 0.28, green: 0.40, blue: 0.58)
        case "Jewellery": return Color(red: 0.78, green: 0.58, blue: 0.22)
        case "تسوق":      return Color(red: 0.18, green: 0.62, blue: 0.58)
        default:          return TrendXTheme.primary
        }
    }

    /// Secondary tint (lighter) for gradient companions.
    var categoryTintLight: Color {
        switch category {
        case "حلويات":    return Color(red: 0.98, green: 0.62, blue: 0.74)
        case "مقاهي":     return Color(red: 0.78, green: 0.58, blue: 0.42)
        case "سيارات":    return Color(red: 0.46, green: 0.58, blue: 0.76)
        case "Jewellery": return Color(red: 0.96, green: 0.78, blue: 0.40)
        case "تسوق":      return Color(red: 0.36, green: 0.80, blue: 0.72)
        default:          return TrendXTheme.primaryLight
        }
    }

    var categoryIcon: String {
        switch category {
        case "حلويات":    return "birthday.cake.fill"
        case "مقاهي":     return "cup.and.saucer.fill"
        case "سيارات":    return "car.fill"
        case "Jewellery": return "diamond.fill"
        case "تسوق":      return "bag.fill"
        default:          return "gift.fill"
        }
    }

    /// First 1–2 characters of the brand name used as a monogram.
    var brandMonogram: String {
        let trimmed = brandName.trimmingCharacters(in: .whitespaces)
        let first = trimmed.prefix(1).uppercased()
        let words = trimmed.split(separator: " ")
        if words.count >= 2, let second = words[1].first {
            return first + String(second).uppercased()
        }
        if trimmed.count >= 2 {
            return trimmed.prefix(2).uppercased()
        }
        return first
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        brandName: String,
        brandLogo: String = "",
        category: String,
        pointsRequired: Int,
        valueInRiyal: Double,
        imageURL: String? = nil,
        isRedeemAtStore: Bool = true,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.brandLogo = brandLogo
        self.category = category
        self.pointsRequired = pointsRequired
        self.valueInRiyal = valueInRiyal
        self.imageURL = imageURL
        self.isRedeemAtStore = isRedeemAtStore
        self.isAvailable = isAvailable
    }
}

// MARK: - Redemption Model

struct Redemption: Codable, Identifiable, Equatable {
    let id: UUID
    var giftId: UUID
    var giftName: String
    var brandName: String
    var pointsSpent: Int
    var valueInRiyal: Double
    var redeemedAt: Date
    var code: String

    init(
        id: UUID = UUID(),
        giftId: UUID,
        giftName: String,
        brandName: String,
        pointsSpent: Int,
        valueInRiyal: Double,
        redeemedAt: Date = Date(),
        code: String = Redemption.makeCode()
    ) {
        self.id = id
        self.giftId = giftId
        self.giftName = giftName
        self.brandName = brandName
        self.pointsSpent = pointsSpent
        self.valueInRiyal = valueInRiyal
        self.redeemedAt = redeemedAt
        self.code = code
    }

    private static func makeCode() -> String {
        "TX-" + String(UUID().uuidString.prefix(6)).uppercased()
    }
}

// MARK: - Sample Data

extension Topic {
    static let samples: [Topic] = [
        Topic(name: "اجتماعية", icon: "person.3.fill", color: "blue", followersCount: 45, postsCount: 16, isFollowing: true),
        Topic(name: "إعلام", icon: "newspaper.fill", color: "purple", followersCount: 84, postsCount: 10, isFollowing: false),
        Topic(name: "اقتصاد", icon: "chart.line.uptrend.xyaxis", color: "green", followersCount: 120, postsCount: 25),
        Topic(name: "رياضة", icon: "sportscourt.fill", color: "orange", followersCount: 200, postsCount: 42),
        Topic(name: "تقنية", icon: "cpu.fill", color: "blue", followersCount: 156, postsCount: 33),
        Topic(name: "صحة", icon: "heart.fill", color: "red", followersCount: 89, postsCount: 18)
    ]
}

extension Poll {
    static let samples: [Poll] = [
        Poll(
            title: "ما رأيك في عالم التقنية والتقنيين؟",
            coverStyle: .tech,
            authorName: "TrendX Official",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "مهم جداً للمستقبل", votesCount: 35, percentage: 70),
                PollOption(text: "مهم بشكل متوسط", votesCount: 10, percentage: 20),
                PollOption(text: "ليس مهماً", votesCount: 5, percentage: 10)
            ],
            topicName: "تقنية",
            totalVotes: 50,
            rewardPoints: 50,
            aiInsight: "تحليل ذكي: الأغلبية (70%) ترى أن التقنية ركيزة للمستقبل — اتجاه متسارع منذ بداية العام."
        ),
        Poll(
            title: "ما هي القفزة التي تعكس التحول الحقيقي في جاذبية المملكة للاستثمار بنظرك؟",
            coverStyle: .economy,
            authorName: "TrendX Official",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "الريادة عالمياً في جودة البنية التحتية", votesCount: 6, percentage: 54.55),
                PollOption(text: "نمو صافي التدفقات 90% في الربع الأخير 2025", votesCount: 4, percentage: 36.36),
                PollOption(text: "تراجع خروج رؤوس الأموال للخارج بنسبة 84%", votesCount: 2, percentage: 18.18),
                PollOption(text: "القفز 38 مركزاً في الأداء الاقتصادي العالمي", votesCount: 5, percentage: 45.45)
            ],
            topicName: "اقتصاد",
            totalVotes: 11,
            rewardPoints: 50,
            durationDays: 7,
            aiInsight: "تتصدّر البنية التحتية رأي المستطلَعين كمؤشر الثقة الأبرز قبل مؤشرات التدفقات المالية."
        ),
        Poll(
            title: "أين تقضي إجازة العيد غالباً؟",
            coverStyle: .social,
            authorName: "Mahmoud Hafez",
            authorAvatar: "م",
            authorIsVerified: false,
            options: [
                PollOption(text: "في جزيرة القطن (السرير)", votesCount: 2, percentage: 16.67),
                PollOption(text: "التنزه مع الأصدقاء", votesCount: 2, percentage: 16.67),
                PollOption(text: "زيارات عائلية", votesCount: 8, percentage: 66.67),
                PollOption(text: "السينما أهم شيء", votesCount: 0, percentage: 0),
                PollOption(text: "أمام التلفزيون مع الكعك", votesCount: 3, percentage: 25)
            ],
            topicName: "اجتماعية",
            totalVotes: 12,
            rewardPoints: 30,
            aiInsight: "لا تزال الزيارات العائلية الخيار الأول بفارق واضح — عادة ثابتة عبر أجيال المستخدمين."
        ),
        Poll(
            title: "آراء الجماهير حول مباراة برشلونة وأتلتيكو مدريد في إياب دوري أبطال أوروبا",
            coverStyle: .sports,
            authorName: "TrendX Sports",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "فوز برشلونة", votesCount: 25, percentage: 50),
                PollOption(text: "فوز أتلتيكو", votesCount: 15, percentage: 30),
                PollOption(text: "تعادل", votesCount: 10, percentage: 20)
            ],
            topicName: "رياضة",
            totalVotes: 50,
            rewardPoints: 50
        ),
        Poll(
            title: "وعي الجمهور بقضايا الأمن الغذائي والزراعة المستدامة من خلال المحتوى الرقمي.",
            coverStyle: .social,
            authorName: "TrendX Research",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "واعي جداً", votesCount: 20, percentage: 40),
                PollOption(text: "واعي بشكل متوسط", votesCount: 20, percentage: 40),
                PollOption(text: "غير واعي", votesCount: 10, percentage: 20)
            ],
            topicName: "اجتماعية",
            totalVotes: 50,
            rewardPoints: 50,
            aiInsight: "80% من المصوّتين لديهم وعي متوسط فأعلى بقضايا الأمن الغذائي — فرصة لمحتوى تعميقي."
        ),
        Poll(
            title: "تأثير المحتوى الرياضي الرقمي (ملخصات، تحليلات، مقاطع قصيرة) على متابعة البطولات.",
            coverStyle: .sports,
            authorName: "TrendX Sports",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "تأثير كبير", votesCount: 30, percentage: 60),
                PollOption(text: "تأثير متوسط", votesCount: 15, percentage: 30),
                PollOption(text: "لا يوجد تأثير", votesCount: 5, percentage: 10)
            ],
            topicName: "رياضة",
            totalVotes: 50,
            rewardPoints: 50
        ),
        Poll(
            title: "قبول الجمهور لاستخدام الذكاء الاصطناعي في الترجمة والكتابة وإنشاء الصور والفيديو.",
            coverStyle: .tech,
            authorName: "TrendX Tech",
            authorAvatar: "T",
            authorIsVerified: true,
            options: [
                PollOption(text: "أقبله تماماً", votesCount: 25, percentage: 50),
                PollOption(text: "أقبله بحذر", votesCount: 20, percentage: 40),
                PollOption(text: "لا أقبله", votesCount: 5, percentage: 10)
            ],
            topicName: "تقنية",
            totalVotes: 50,
            rewardPoints: 50,
            aiInsight: "90% يتقبّلون الذكاء الاصطناعي — لكن الحذر لا يزال حاضراً لدى ثلث العيّنة."
        )
    ]
}

extension Gift {
    static let samples: [Gift] = [
        Gift(name: "قسيمة قهوة",       brandName: "Starbucks",        category: "مقاهي",     pointsRequired: 120, valueInRiyal: 20.0),
        Gift(name: "حلويات مختارة",   brandName: "AANI & DANI",      category: "حلويات",    pointsRequired: 180, valueInRiyal: 30.0),
        Gift(name: "قسيمة تسوّق",       brandName: "Amazon",           category: "تسوق",      pointsRequired: 300, valueInRiyal: 50.0),
        Gift(name: "خدمة عناية بالسيارة", brandName: "3M AutoCare",   category: "سيارات",    pointsRequired: 360, valueInRiyal: 60.0),
        Gift(name: "قسيمة مجوهرات",  brandName: "AbdulGhani Heritage", category: "Jewellery", pointsRequired: 480, valueInRiyal: 80.0),
        Gift(name: "قطعة مميّزة",      brandName: "AbdulGhani",       category: "Jewellery", pointsRequired: 600, valueInRiyal: 100.0),
        Gift(name: "فطور الصباح",      brandName: "Dose Café",        category: "مقاهي",     pointsRequired: 150, valueInRiyal: 25.0),
        Gift(name: "سلة حلا",           brandName: "Bateel",           category: "حلويات",    pointsRequired: 420, valueInRiyal: 70.0)
    ]
}
