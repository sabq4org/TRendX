//
//  Models.swift
//  TRENDX
//

import Foundation
import SwiftUI

// MARK: - User Model

enum UserGender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    case unspecified = "unspecified"

    var displayName: String {
        switch self {
        case .male:        return "ذكر"
        case .female:      return "أنثى"
        case .other:       return "أخرى"
        case .unspecified: return "لا أحب التحديد"
        }
    }
}

enum UserRole: String, Codable {
    case respondent
    case publisher
    case admin
}

enum UserTier: String, Codable {
    case free
    case premium
    case enterprise
}

/// One of the three account classes on TRENDX. Drives visual identity
/// (avatar shape, badge color, profile banner style) and the
/// verification flow.
enum AccountType: String, Codable, CaseIterable {
    case individual
    case organization
    case government

    var displayName: String {
        switch self {
        case .individual:   return "فرد"
        case .organization: return "منظّمة"
        case .government:   return "جهة حكومية"
        }
    }
}

struct TrendXUser: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var handle: String?
    var bio: String?
    var avatarInitial: String
    var avatarUrl: String?
    var bannerUrl: String?
    var accountType: AccountType
    var isVerified: Bool
    var points: Int
    var coins: Double
    var followedTopics: [UUID]
    var completedPolls: [UUID]
    var isPremium: Bool

    var role: UserRole
    var tier: UserTier
    var gender: UserGender
    var birthYear: Int?
    var city: String?
    var region: String?
    var country: String

    // Social graph counters and the viewer-follows flag, mirrored from
    // user_follows server-side. `viewerFollows` is only meaningful when
    // the user was decoded from a public lookup like GET /users/:id —
    // it stays false for the local current user.
    var followersCount: Int
    var followingCount: Int
    var viewerFollows: Bool

    init(
        id: UUID = UUID(),
        name: String = "مستخدم",
        email: String = "",
        handle: String? = nil,
        bio: String? = nil,
        avatarInitial: String = "م",
        avatarUrl: String? = nil,
        bannerUrl: String? = nil,
        accountType: AccountType = .individual,
        isVerified: Bool = false,
        points: Int = 100,
        coins: Double = 16.67,
        followedTopics: [UUID] = [],
        completedPolls: [UUID] = [],
        isPremium: Bool = false,
        role: UserRole = .respondent,
        tier: UserTier = .free,
        gender: UserGender = .unspecified,
        birthYear: Int? = nil,
        city: String? = nil,
        region: String? = nil,
        country: String = "SA",
        followersCount: Int = 0,
        followingCount: Int = 0,
        viewerFollows: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.handle = handle
        self.bio = bio
        self.avatarInitial = avatarInitial
        self.avatarUrl = avatarUrl
        self.bannerUrl = bannerUrl
        self.accountType = accountType
        self.isVerified = isVerified
        self.points = points
        self.coins = coins
        self.followedTopics = followedTopics
        self.completedPolls = completedPolls
        self.isPremium = isPremium
        self.role = role
        self.tier = tier
        self.gender = gender
        self.birthYear = birthYear
        self.city = city
        self.region = region
        self.country = country
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.viewerFollows = viewerFollows
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
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case rating = "rating"
    case linearScale = "linear_scale"

    /// Tolerant decoder so the iOS app keeps working through backend
    /// vocabulary changes (e.g. legacy Arabic raw values cached in
    /// UserDefaults from earlier builds).
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "single_choice", "اختيار واحد", "singleChoice":
            self = .singleChoice
        case "multiple_choice", "متعدد الاختيار", "multipleChoice":
            self = .multipleChoice
        case "rating", "تقييم":
            self = .rating
        case "linear_scale", "مقياس خطي", "linearScale":
            self = .linearScale
        default:
            self = .singleChoice
        }
    }

    var displayName: String {
        switch self {
        case .singleChoice:   return "اختيار واحد"
        case .multipleChoice: return "متعدد الاختيار"
        case .rating:         return "تقييم"
        case .linearScale:    return "مقياس خطي"
        }
    }
}

enum PollStatus: String, Codable {
    case active   = "active"
    case completed = "ended"
    case draft    = "draft"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "active", "نشط":               self = .active
        case "ended", "completed", "مكتمل": self = .completed
        case "draft", "مسودة":              self = .draft
        default:                             self = .active
        }
    }

    var displayName: String {
        switch self {
        case .active:    return "نشط"
        case .completed: return "مكتمل"
        case .draft:     return "مسودة"
        }
    }
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
    var viewsCount: Int
    var savesCount: Int
    /// Account type of the publishing entity — drives the "استطلاع رسمي"
    /// marker and green border for government-published polls.
    var authorAccountType: AccountType
    var authorHandle: String?
    /// The publisher's UUID — used to navigate to their profile even
    /// when they haven't set a `@handle` yet.
    var publisherId: UUID?
    /// Audience gate for voting: "public" / "verified" / "verified_citizen".
    var voterAudience: String
    /// Whether the current viewer has reposted this poll. Driven by
    /// the repost endpoint and managed optimistically client-side.
    var viewerReposted: Bool = false
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
        viewsCount: Int = 0,
        savesCount: Int = 0,
        authorAccountType: AccountType = .individual,
        authorHandle: String? = nil,
        publisherId: UUID? = nil,
        voterAudience: String = "public",
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
        self.viewsCount = viewsCount
        self.savesCount = savesCount
        self.authorAccountType = authorAccountType
        self.authorHandle = authorHandle
        self.publisherId = publisherId
        self.voterAudience = voterAudience
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
    /// Number of redemptions in the last 7 days. Used for "شائع هذا الأسبوع".
    var weeklyRedemptions: Int = 0
    /// Most recent redemption timestamp; drives the "آخر استبدال قبل X" chip.
    var lastRedeemedAt: Date? = nil

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
        isAvailable: Bool = true,
        weeklyRedemptions: Int = 0,
        lastRedeemedAt: Date? = nil
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
        self.weeklyRedemptions = weeklyRedemptions
        self.lastRedeemedAt = lastRedeemedAt
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
        Gift(name: "قسيمة قهوة",            brandName: "Starbucks",          category: "مقاهي",     pointsRequired: 120, valueInRiyal: 20.0),
        Gift(name: "حلويات مختارة",      brandName: "AANI & DANI",        category: "حلويات",    pointsRequired: 180, valueInRiyal: 30.0),
        Gift(name: "قسيمة تسوّق",            brandName: "Amazon",             category: "تسوق",      pointsRequired: 300, valueInRiyal: 50.0),
        Gift(name: "خدمة عناية بالسيارة",  brandName: "3M AutoCare",        category: "سيارات",    pointsRequired: 360, valueInRiyal: 60.0),
        Gift(name: "قسيمة مجوهرات",       brandName: "AbdulGhani Heritage",category: "Jewellery", pointsRequired: 480, valueInRiyal: 80.0),
        Gift(name: "قطعة مميّزة",           brandName: "AbdulGhani",         category: "Jewellery", pointsRequired: 600, valueInRiyal: 100.0),
        Gift(name: "فطور الصباح",           brandName: "Dose Café",          category: "مقاهي",     pointsRequired: 150, valueInRiyal: 25.0),
        Gift(name: "سلة حلا",                brandName: "Bateel",             category: "حلويات",    pointsRequired: 420, valueInRiyal: 70.0)
    ]
}

// MARK: - Survey Model

/// A single question inside a Survey. Distinct from `Poll` because survey
/// questions live only inside their parent and don't carry the standalone
/// poll metadata (author, shares, votes-total etc.). Backend DTO returned
/// by `/surveys/:id` includes `display_order`, `is_required`, and
/// `reward_points` per question — none of which exist on `Poll`.
struct SurveyQuestion: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String?
    var type: PollType
    var options: [PollOption]
    var displayOrder: Int
    var rewardPoints: Int
    var isRequired: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        type: PollType = .singleChoice,
        options: [PollOption] = [],
        displayOrder: Int = 0,
        rewardPoints: Int = 25,
        isRequired: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.options = options
        self.displayOrder = displayOrder
        self.rewardPoints = rewardPoints
        self.isRequired = isRequired
    }

    var totalVotes: Int { options.reduce(0) { $0 + $1.votesCount } }
}

struct Survey: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var authorName: String
    var authorAvatar: String
    var authorIsVerified: Bool
    var coverStyle: PollCoverStyle
    var questions: [SurveyQuestion]
    var topicName: String?
    var totalResponses: Int
    var completionRate: Double      // % من أكمل كل الأسئلة
    var avgCompletionSeconds: Int   // متوسط وقت الإكمال
    var status: PollStatus
    var createdAt: Date
    var expiresAt: Date
    var rewardPoints: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        authorName: String = "TrendX Research",
        authorAvatar: String = "T",
        authorIsVerified: Bool = true,
        coverStyle: PollCoverStyle = .generic,
        questions: [SurveyQuestion] = [],
        topicName: String? = nil,
        totalResponses: Int = 0,
        completionRate: Double = 0,
        avgCompletionSeconds: Int = 180,
        status: PollStatus = .active,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(14 * 24 * 60 * 60),
        rewardPoints: Int = 150
    ) {
        self.id = id; self.title = title; self.description = description
        self.authorName = authorName; self.authorAvatar = authorAvatar
        self.authorIsVerified = authorIsVerified; self.coverStyle = coverStyle
        self.questions = questions; self.topicName = topicName
        self.totalResponses = totalResponses; self.completionRate = completionRate
        self.avgCompletionSeconds = avgCompletionSeconds; self.status = status
        self.createdAt = createdAt; self.expiresAt = expiresAt
        self.rewardPoints = rewardPoints
    }

    var questionCount: Int { questions.count }
    var isExpired: Bool { Date() > expiresAt }
    var remainingDays: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0)
    }
}

extension Survey {
    static let samples: [Survey] = [
        Survey(
            title: "الذكاء الاصطناعي في حياتنا اليومية",
            description: "دراسة شاملة حول تأثير تقنيات AI على سلوكيات وأولويات المجتمع السعودي",
            coverStyle: .tech,
            questions: [
                SurveyQuestion(title: "كم ساعة يومياً تستخدم أدوات الذكاء الاصطناعي؟",
                     options: [
                        PollOption(text: "أقل من ساعة", votesCount: 180, percentage: 36),
                        PollOption(text: "1-3 ساعات", votesCount: 225, percentage: 45),
                        PollOption(text: "أكثر من 3 ساعات", votesCount: 95, percentage: 19)
                     ], displayOrder: 0, rewardPoints: 30),
                SurveyQuestion(title: "ما مدى تأثير AI على إنتاجيتك المهنية؟",
                     options: [
                        PollOption(text: "زاد إنتاجيتي كثيراً", votesCount: 220, percentage: 44),
                        PollOption(text: "تحسن طفيف", votesCount: 175, percentage: 35),
                        PollOption(text: "لم يتغيّر شيء", votesCount: 65, percentage: 13),
                        PollOption(text: "أثّر سلباً", votesCount: 40, percentage: 8)
                     ], displayOrder: 1, rewardPoints: 30),
                SurveyQuestion(title: "هل تقلق من تأثير AI على سوق العمل؟",
                     options: [
                        PollOption(text: "نعم، قلق شديد", votesCount: 130, percentage: 26),
                        PollOption(text: "قلق متوسط", votesCount: 185, percentage: 37),
                        PollOption(text: "لست قلقاً", votesCount: 145, percentage: 29),
                        PollOption(text: "متفائل جداً", votesCount: 40, percentage: 8)
                     ], displayOrder: 2, rewardPoints: 30),
                SurveyQuestion(title: "أي مجال ترى فيه AI التحول الأكبر؟",
                     options: [
                        PollOption(text: "الصحة والطب",      votesCount: 165, percentage: 33),
                        PollOption(text: "التعليم والتدريب", votesCount: 150, percentage: 30),
                        PollOption(text: "الأعمال والاقتصاد",  votesCount: 110, percentage: 22),
                        PollOption(text: "الإعلام والمحتوى",   votesCount: 75,  percentage: 15)
                     ], displayOrder: 3, rewardPoints: 30),
                SurveyQuestion(title: "ما مدى استعدادك للدفع مقابل استخدام AI؟",
                     options: [
                        PollOption(text: "مستعد إذا كانت القيمة عادلة", votesCount: 195, percentage: 39),
                        PollOption(text: "فقط باشتراك مدفوع مسبقاً",           votesCount: 120, percentage: 24),
                        PollOption(text: "أفضل النماذج المجانية فقط",           votesCount: 110, percentage: 22),
                        PollOption(text: "لست مستعداً للدفع",                         votesCount: 75,  percentage: 15)
                     ], displayOrder: 4, rewardPoints: 30)
            ],
            topicName: "تقنية",
            totalResponses: 500,
            completionRate: 78,
            avgCompletionSeconds: 210,
            rewardPoints: 150
        ),

        // استبيان 2
        Survey(
            title: "ثقة المجتمع بتقنيات AI في اتخاذ القرار",
            description: "هل يثق الجمهور بقرارات تتخذها أنظمة الذكاء الاصطناعي؟",
            coverStyle: .tech,
            questions: [
                SurveyQuestion(title: "هل تثق بقرار طبي AI بدون مراجعة بشرية؟",
                     options: [
                        PollOption(text: "نعم، أثق به",      votesCount: 180, percentage: 36),
                        PollOption(text: "بحذر، أحتاج مراجعة", votesCount: 245, percentage: 49),
                        PollOption(text: "لا، لا أثق",     votesCount: 75,  percentage: 15)
                     ], displayOrder: 0, rewardPoints: 30),
                SurveyQuestion(title: "هل تثق بحكم قضائي AI في قضية بسيطة؟",
                     options: [
                        PollOption(text: "نعم",          votesCount: 140, percentage: 28),
                        PollOption(text: "بشروط محددة", votesCount: 210, percentage: 42),
                        PollOption(text: "لا إطلاقاً",   votesCount: 150, percentage: 30)
                     ], displayOrder: 1, rewardPoints: 30),
                SurveyQuestion(title: "من يتحمل مسؤولية قرار AI الخاطئ؟",
                     options: [
                        PollOption(text: "الشركة المطوّرة", votesCount: 225, percentage: 45),
                        PollOption(text: "المستخدم",        votesCount: 100, percentage: 20),
                        PollOption(text: "كلاهما معاً",    votesCount: 175, percentage: 35)
                     ], displayOrder: 2, rewardPoints: 30),
                SurveyQuestion(title: "هل يجب تنظيم AI حكومياً في السعودية؟",
                     options: [
                        PollOption(text: "نعم، تنظيم صارم",  votesCount: 310, percentage: 62),
                        PollOption(text: "تنظيم خفيف فقط", votesCount: 140, percentage: 28),
                        PollOption(text: "لا حاجة لتنظيم",   votesCount: 50,  percentage: 10)
                     ], displayOrder: 3, rewardPoints: 30)
            ],
            topicName: "تقنية", totalResponses: 500, completionRate: 74,
            avgCompletionSeconds: 195, rewardPoints: 130
        ),

        // استبيان 3
        Survey(
            title: "ذكاء اصطناعي في التعليم: تحوّل أم تهديد؟",
            description: "تقييم مدى جاهزية المنظومة التعليمية لاستيعاب تقنيات الذكاء الاصطناعي",
            coverStyle: .tech,
            questions: [
                SurveyQuestion(title: "هل تستخدم AI في دراستك أو عملك؟",
                     options: [
                        PollOption(text: "نعم، يومياً",     votesCount: 280, percentage: 56),
                        PollOption(text: "أحياناً",         votesCount: 140, percentage: 28),
                        PollOption(text: "لا، لم أجرّبه", votesCount: 80,  percentage: 16)
                     ], displayOrder: 0, rewardPoints: 25),
                SurveyQuestion(title: "هل AI يساعد في الفهم أو يضعف التفكير؟",
                     options: [
                        PollOption(text: "يساعد كثيراً",    votesCount: 220, percentage: 44),
                        PollOption(text: "يساعد لكن بحذر", votesCount: 185, percentage: 37),
                        PollOption(text: "يضعف التفكير",   votesCount: 95,  percentage: 19)
                     ], displayOrder: 1, rewardPoints: 25),
                SurveyQuestion(title: "ما أكثر استخدامات AI في التعليم؟",
                     options: [
                        PollOption(text: "تلخيص المعلومات",  votesCount: 215, percentage: 43),
                        PollOption(text: "كتابة التقارير",     votesCount: 160, percentage: 32),
                        PollOption(text: "حل المسائل",       votesCount: 125, percentage: 25)
                     ], displayOrder: 2, rewardPoints: 25),
                SurveyQuestion(title: "هل يجب تعليم AI كمادة مستقلة؟",
                     options: [
                        PollOption(text: "نعم، ضروري", votesCount: 300, percentage: 60),
                        PollOption(text: "يكفي ضمن مواد أخرى", votesCount: 150, percentage: 30),
                        PollOption(text: "ليست ضرورة", votesCount: 50, percentage: 10)
                     ], displayOrder: 3, rewardPoints: 25)
            ],
            topicName: "تقنية", totalResponses: 420, completionRate: 81,
            avgCompletionSeconds: 185, rewardPoints: 120
        )
    ]
}

struct SurveyAnalytics {
    // الملخص التنفيذي
    let totalResponses: Int
    let completionRate: Double
    let avgCompletionSeconds: Int
    let confidenceLevel: Double
    let marginOfError: Double

    // بصمة المشارك
    let malePercent: Double
    let femalePercent: Double
    let topAgeGroup: String
    let topAgePercent: Double
    let topCountry: String
    let topCountryPercent: Double
    let topCity: String
    let topDevice: String
    let deviceBreakdown: [(device: String, icon: String, percent: Double)]
    let peakHour: String

    // خريطة الإجماع — لكل سؤال: نسبة التوافق
    let questionConsensus: [(questionShort: String, leadPercent: Double, label: String)]

    // الروابط الخفية — Cross-question correlations
    let correlations: [(q1: String, choice1: String, q2: String, choice2: String, percent: Double)]

    // الشخصيات المكتشفة
    let personas: [RespondentPersona]

    // منحنى الرأي عبر الزمن
    let sentimentTimeline: [(day: Int, positivePercent: Double)]

    // الاكتشافات الرئيسية
    let keyFindings: [String]

    // التوصيات
    let recommendations: [String]

    static func mock(for survey: Survey) -> SurveyAnalytics {
        let n = max(survey.totalResponses, 50)
        return SurveyAnalytics(
            totalResponses: n,
            completionRate: survey.completionRate > 0 ? survey.completionRate : 78,
            avgCompletionSeconds: survey.avgCompletionSeconds,
            confidenceLevel: n > 300 ? 95 : n > 150 ? 90 : 85,
            marginOfError: n > 300 ? 2.8 : n > 150 ? 4.2 : 6.1,
            malePercent: 61,
            femalePercent: 39,
            topAgeGroup: "25–34",
            topAgePercent: 43,
            topCountry: "السعودية",
            topCountryPercent: 67,
            topCity: "الرياض",
            topDevice: "iOS — 87%",
            deviceBreakdown: [
                (device: "iPhone / iOS", icon: "iphone",          percent: 57),
                (device: "Android",      icon: "phone",            percent: 30),
                (device: "iPad",         icon: "ipad",             percent: 8),
                (device: "Web",          icon: "laptopcomputer",   percent: 5)
            ],
            peakHour: "9–11 مساءً",
            questionConsensus: survey.questions.enumerated().map { i, q in
                let lead = q.options.max(by: { $0.percentage < $1.percentage })?.percentage ?? 50
                let label = lead > 70 ? "توافق قوي" : lead > 55 ? "ميل واضح" : "انقسام حاد"
                let short = String(q.title.prefix(28)) + (q.title.count > 28 ? "…" : "")
                return (questionShort: short, leadPercent: lead, label: label)
            },
            correlations: [
                ("ساعات الاستخدام", "1-3 ساعات", "التأثير على العمل", "زاد إنتاجيتي", 71),
                ("القلق من سوق العمل", "لست قلقاً", "مجال التحول", "التعليم والتدريب", 68),
                ("ساعات الاستخدام", "+3 ساعات", "القلق", "متفائل جداً", 64),
            ],
            personas: [
                RespondentPersona(name: "المتبنّي المبكّر", emoji: "⚡️",
                    description: "شاب 25-34 من الرياض يستخدم AI +3 ساعات، متفائل جداً ولا يقلق من سوق العمل",
                    percent: 38,
                    traits: ["مستخدم مكثف", "متفائل", "رياضي"]),
                RespondentPersona(name: "المتشكك المدروس", emoji: "ᾝ0",
                    description: "محترف 35-44 يستخدم AI بحذر، يقلق من سوق العمل ويرى التحول في التعليم",
                    percent: 29,
                    traits: ["حذر", "متشكك", "مدروس"]),
                RespondentPersona(name: "المتحفظ العملي", emoji: "🛡️",
                    description: "مستخدم خفيف يقلق من أثر AI على وظيفته، إجاباته تدل على مقاومة للتغيير",
                    percent: 33,
                    traits: ["حذر", "محافظ", "عملي"])
            ],
            sentimentTimeline: [
                (1, 58), (2, 61), (3, 59), (4, 63),
                (5, 67), (6, 65), (7, 70), (8, 68),
                (9, 72), (10, 69), (11, 74), (12, 76),
                (13, 73), (14, 78)
            ],
            keyFindings: [
                "٧٩% من المشاركين يستخدمون AI يومياً لأكثر من ساعة — اندماج عميق في الروتين اليومي",
                "المستخدمون المكثفون (+3 ساعات) هم الأقل قلقاً من سوق العمل — علاقة عكسية واضحة",
                "الصحة والطب تصدر مجالات التحول المتوقع بنسبة ٣٣% — يعكس قلق اجتماعياً حقيقياً",
                "فجوة جيلية واضحة: فئة 18-24 أكثر تفاؤلاً بفارق ١٨ نقطة عن فئة +٤٥",
                "الرياض أكثر تفاؤلاً من جدة بفارق ١٢% — يعكس تبايناً جغرافياً في تبني التقنية"
            ],
            recommendations: [
                "استهدف الفئة 35+ بمحتوى تعليمي يخفف مخاوف سوق العمل",
                "استثمر في جدة والمنطقة الغربية — نسبة التبني أقل بمراحل عن الرياض",
                "تقطيع محتوى الصحة الرقمية لاستهداف المتشككين بحجج علمية"
            ]
        )
    }
}

struct RespondentPersona: Codable, Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let description: String
    let percent: Int
    let traits: [String]

    init(id: UUID = UUID(), name: String, emoji: String, description: String, percent: Int, traits: [String]) {
        self.id = id; self.name = name; self.emoji = emoji
        self.description = description; self.percent = percent; self.traits = traits
    }
}
