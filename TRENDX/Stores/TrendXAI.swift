//
//  TrendXAI.swift
//  TRENDX
//
//  The brand voice of TRENDX — a small, deterministic on-device content
//  engine that supplies time-aware greetings, daily briefs, encouragements
//  and ambient inspirational copy so the product *feels* AI-powered.
//

import Foundation
import SwiftUI

enum TrendXAI {

    // MARK: - Identity

    static let appName     = "TRENDX AI"
    static let tagline     = "ذكاء يلتقي بصوتك"
    static let signature   = "مدعوم بـ TRENDX AI"

    // MARK: - Time-aware greeting

    struct Greeting {
        let eyebrow: String
        let title: String
        let whisper: String
    }

    static func greeting(for name: String) -> Greeting {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return Greeting(
                eyebrow: "صباح الخير",
                title: "أهلاً \(name)",
                whisper: "ابدأ يومك بصوتٍ يُسمَع — رأيك يصنع الاتجاه."
            )
        case 12..<17:
            return Greeting(
                eyebrow: "نهارك ملهم",
                title: "\(name)، يومك مليان فرص",
                whisper: "اختر استطلاعاً، ولِّد أثراً خلال دقيقة."
            )
        case 17..<21:
            return Greeting(
                eyebrow: "مساء النور",
                title: "لحظة تأمل يا \(name)",
                whisper: "اختم يومك برأيٍ يُضاف لذاكرة المجتمع."
            )
        default:
            return Greeting(
                eyebrow: "ليلة هادئة",
                title: "وقت الهدوء يا \(name)",
                whisper: "أفكارك الليلة قد تُلهم قرار الغد."
            )
        }
    }

    // MARK: - Daily AI Brief

    struct AIBrief {
        let headline: String
        let body: String
        let tag: String
        let icon: String
    }

    /// Rotates deterministically by the ordinal day of the year so the feed
    /// feels alive without any backend.
    static func dailyBrief() -> AIBrief {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return briefs[day % briefs.count]
    }

    static func dailyBrief(activePolls: [Poll], topics: [Topic], user: TrendXUser) -> AIBrief {
        let endingSoon = activePolls.filter(\.isEndingSoon).count
        let followedNames = topics.filter(\.isFollowing).map(\.name).prefix(2).joined(separator: " و")
        let topTopic = topics.max { $0.postsCount < $1.postsCount }?.name ?? "المجتمع"

        if endingSoon > 0 {
            return AIBrief(
                headline: "رادار اليوم",
                body: "\(endingSoon) استطلاع ينتهي قريباً. TRENDX AI يقترح أن تبدأ بالأسئلة السريعة قبل أن تغلق نافذة التأثير.",
                tag: "أولوية عاجلة",
                icon: "dot.radiowaves.left.and.right"
            )
        }

        if !followedNames.isEmpty {
            return AIBrief(
                headline: "مجلة اهتماماتك",
                body: "رتّبنا لك الصفحة حسب \(followedNames). كل تصويت جديد يساعدنا في جعل الرادار أقرب لذوقك.",
                tag: "مخصص لك",
                icon: "sparkles"
            )
        }

        return AIBrief(
            headline: "بوصلة TRENDX",
            body: "\(topTopic) يتصدر المشهد حالياً، ورصيدك \(user.points) نقطة يقرّبك من أول هدية قابلة للاستبدال.",
            tag: "تحليل محلي",
            icon: "chart.line.uptrend.xyaxis"
        )
    }

    private static let briefs: [AIBrief] = [
        AIBrief(
            headline: "نبض اليوم",
            body: "التقنية والذكاء الاصطناعي يتصدّران اهتمامات المجتمع هذا الأسبوع — فرصتك لتُسمع رأيك في أكثر المواضيع تأثيراً.",
            tag: "اتجاه صاعد",
            icon: "sparkles"
        ),
        AIBrief(
            headline: "رؤية ذكية",
            body: "70% من المصوّتين يرون أن البنية التحتية الرقمية ركيزة المستقبل — صوتك قد يعيد تشكيل المعادلة.",
            tag: "تحليل لحظي",
            icon: "brain.head.profile"
        ),
        AIBrief(
            headline: "لفتة ملهمة",
            body: "كل رأي تشاركه يُبنى عليه قرار. TRENDX AI يلخّص لك أبرز الاتجاهات ليكون اختيارك أعمق.",
            tag: "إلهام",
            icon: "wand.and.stars"
        ),
        AIBrief(
            headline: "اقتراح اليوم",
            body: "جرّب متابعة موضوعٍ جديد — التنوّع الفكري يُغني توصيات الذكاء الاصطناعي لك.",
            tag: "اقتراح",
            icon: "lightbulb.fill"
        ),
        AIBrief(
            headline: "توقيت ذهبي",
            body: "الاستطلاعات التي تنتهي خلال 24 ساعة أكثر تأثيراً. شاركها الآن لترفع قيمة صوتك.",
            tag: "فرصة",
            icon: "bolt.fill"
        ),
        AIBrief(
            headline: "قراءة سريعة",
            body: "الاقتصاد والمجتمع يتشاركان اهتماماً متقارباً اليوم — دليل على وعي جماعي متوازن.",
            tag: "ملاحظة",
            icon: "chart.bar.fill"
        )
    ]

    // MARK: - Post-vote encouragements

    static func encouragement() -> String {
        let phrases = [
            "شكراً لصوتك — رأيك أضاف لمسة للصورة الكاملة.",
            "صوتٌ واعٍ يصنع فارقاً. TRENDX AI يقدّر مشاركتك.",
            "كل رأي يُغني التحليل — استمر على هذا الإيقاع.",
            "تمّ دمج رأيك في اتجاهات الوقت الفعلي.",
            "صوتك انضمّ للتحليل الجماعي — أبدعت."
        ]
        return phrases.randomElement() ?? phrases[0]
    }

    static func postVoteInsight(for poll: Poll) -> String {
        guard let leader = poll.options.max(by: { $0.percentage < $1.percentage }) else {
            return encouragement()
        }

        let margin = poll.options
            .filter { $0.id != leader.id }
            .map(\.percentage)
            .max() ?? 0
        let gap = max(leader.percentage - margin, 0)
        let topic = poll.topicName ?? poll.topicStyle.label

        if gap >= 25 {
            return "\(topic): خيار «\(leader.text)» يتقدم بفارق \(Int(gap)) نقطة، ما يشير إلى اتجاه جماعي واضح حتى الآن."
        }

        if poll.isEndingSoon {
            return "النتيجة متقاربة وتنتهي قريباً. كل صوت جديد قد يغيّر قراءة \(topic) خلال الساعات القادمة."
        }

        return "المشهد لا يزال مفتوحاً في \(topic): «\(leader.text)» يتصدر حالياً بنسبة \(Int(leader.percentage))% مع قابلية عالية للتغيّر."
    }

    static func giftReason(gift: Gift, userPoints: Int) -> String {
        let remaining = max(gift.pointsRequired - userPoints, 0)
        let valuePerPoint = gift.valueInRiyal / max(Double(gift.pointsRequired), 1)

        if remaining == 0 {
            return "يمكنك استبدالها الآن، وقيمتها \(Int(gift.valueInRiyal)) ر.س مقابل \(gift.pointsRequired) نقطة تجعلها اختياراً جاهزاً وفورياً."
        }

        if remaining <= 80 {
            return "تفصلك \(remaining) نقطة فقط. TRENDX AI رشحها لأنها قريبة من رصيدك الحالي وقيمتها لكل نقطة \(String(format: "%.2f", valuePerPoint))."
        }

        return "اختيار طموح ضمن فئة \(gift.category). تحتاج \(remaining) نقطة، لكنها تمنح قيمة أعلى عند الاستمرار في التصويت."
    }

    static func clarityScore(question: String, options: [String]) -> Int {
        let cleanQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var score = 35

        if cleanQuestion.count >= 18 { score += 20 }
        if cleanQuestion.contains("؟") || cleanQuestion.contains("?") { score += 10 }
        if cleanOptions.count >= 2 { score += 20 }
        if Set(cleanOptions).count == cleanOptions.count { score += 10 }
        if cleanOptions.allSatisfy({ $0.count <= 42 }) { score += 5 }

        return min(score, 100)
    }

    static func suggestedOptions(for question: String, topicName: String?, type: PollType) -> [String] {
        let topic = topicName ?? "الموضوع"
        let lower = question.lowercased()

        if type == .rating || lower.contains("تقييم") {
            return ["ممتاز", "جيد", "يحتاج تحسين"]
        }

        if lower.contains("أفضل") || lower.contains("اختيار") {
            return ["الخيار الأكثر تأثيراً", "الخيار الأسهل تنفيذاً", "الخيار الأعلى قيمة"]
        }

        switch topic {
        case "تقنية":
            return ["يدعم الابتكار", "يحتاج تنظيم", "تأثيره محدود"]
        case "اقتصاد":
            return ["يزيد الثقة", "يحسّن الكفاءة", "أثره طويل المدى"]
        case "رياضة":
            return ["أوافق بقوة", "محايد", "لا أوافق"]
        default:
            return ["أوافق", "محايد", "لا أوافق"]
        }
    }

    static func suggestedQuestion(topicName: String?, type: PollType) -> String {
        let topic = topicName ?? "هذا الموضوع"
        switch type {
        case .singleChoice:
            return "ما الخيار الأكثر تأثيراً في \(topic) خلال الفترة القادمة؟"
        case .multipleChoice:
            return "ما العوامل التي ترى أنها تؤثر في \(topic)؟"
        case .rating:
            return "كيف تقيّم وضع \(topic) حالياً؟"
        case .linearScale:
            return "على مقياس من 1 إلى 10، ما مدى أهمية \(topic) بالنسبة لك؟"
        }
    }

    // MARK: - Section subtitles (ambient copy)

    static let trendingSubtitle   = "رصد لحظي بواسطة TRENDX AI"
    static let communitySubtitle  = "كل صوت يُضاف للتحليل الجماعي"
    static let topicsSubtitle     = "اختر ما يلامس اهتماماتك"

    // MARK: - AI Search placeholder

    static let aiSearchPlaceholder = "اسأل TRENDX AI أو ابحث عن موضوع…"
}
