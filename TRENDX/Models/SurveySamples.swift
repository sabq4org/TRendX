//
//  SurveySamples.swift
//  TRENDX
//
//  5 استبيانات في محور التقنية والذكاء الاصطناعي
//  (الاستبيانان 1 و 2 و 3 في Models.swift — هنا 4 و 5)
//

import Foundation

extension Survey {
    static let techSamples: [Survey] = Survey.samples + [

        // استبيان 4 — الخصوصية الرقمية
        Survey(
            title: "الخصوصية الرقمية في عصر الذكاء الاصطناعي",
            description: "كيف يرى المجتمع السعودي قضايا الخصوصية وجمع البيانات من قِبل أنظمة AI",
            coverStyle: .tech,
            questions: [
                SurveyQuestion(title: "هل تقرأ سياسة الخصوصية قبل استخدام أي تطبيق AI؟",
                     options: [
                        PollOption(text: "دائماً",            votesCount: 75,  percentage: 15),
                        PollOption(text: "أحياناً",           votesCount: 175, percentage: 35),
                        PollOption(text: "نادراً",            votesCount: 175, percentage: 35),
                        PollOption(text: "لا أقرأها أبداً",  votesCount: 75,  percentage: 15)
                     ], displayOrder: 0, rewardPoints: 25),
                SurveyQuestion(title: "ما مدى قلقك من استخدام بياناتك لتدريب نماذج AI؟",
                     options: [
                        PollOption(text: "قلق جداً",      votesCount: 200, percentage: 40),
                        PollOption(text: "قلق نسبياً",    votesCount: 175, percentage: 35),
                        PollOption(text: "لست قلقاً",     votesCount: 125, percentage: 25)
                     ], displayOrder: 1, rewardPoints: 25),
                SurveyQuestion(title: "هل تقبل تقديم بياناتك مقابل خدمة AI أفضل؟",
                     options: [
                        PollOption(text: "نعم بدون تردد",      votesCount: 100, percentage: 20),
                        PollOption(text: "نعم بشروط واضحة",    votesCount: 225, percentage: 45),
                        PollOption(text: "لا، خصوصيتي أولاً", votesCount: 175, percentage: 35)
                     ], displayOrder: 2, rewardPoints: 25),
                SurveyQuestion(title: "من تثق به أكثر لحماية بياناتك الرقمية؟",
                     options: [
                        PollOption(text: "الحكومة والجهات التنظيمية", votesCount: 240, percentage: 48),
                        PollOption(text: "الشركات التقنية الكبرى",     votesCount: 100, percentage: 20),
                        PollOption(text: "المنظمات المستقلة",          votesCount: 100, percentage: 20),
                        PollOption(text: "لا أثق بأيٍّ منهم",         votesCount: 60,  percentage: 12)
                     ], displayOrder: 3, rewardPoints: 25)
            ],
            topicName: "تقنية", totalResponses: 500, completionRate: 76,
            avgCompletionSeconds: 200, rewardPoints: 120
        ),

        // استبيان 5 — مستقبل العمل مع AI
        Survey(
            title: "مستقبل العمل في ظل انتشار الذكاء الاصطناعي",
            description: "تصورات سوق العمل السعودي تجاه أتمتة الوظائف وظهور مهن جديدة",
            coverStyle: .economy,
            questions: [
                SurveyQuestion(title: "هل تعتقد أن وظيفتك ستتأثر بـ AI خلال 5 سنوات؟",
                     options: [
                        PollOption(text: "ستتأثر كثيراً",       votesCount: 175, percentage: 35),
                        PollOption(text: "ستتأثر جزئياً",       votesCount: 225, percentage: 45),
                        PollOption(text: "لن تتأثر",            votesCount: 100, percentage: 20)
                     ], displayOrder: 0, rewardPoints: 30),
                SurveyQuestion(title: "ما المهارات التي ترى أنها الأهم في عصر AI؟",
                     options: [
                        PollOption(text: "التفكير النقدي والإبداع",    votesCount: 215, percentage: 43),
                        PollOption(text: "مهارات التقنية والبرمجة",    votesCount: 150, percentage: 30),
                        PollOption(text: "المهارات الإنسانية والتواصل", votesCount: 135, percentage: 27)
                     ], displayOrder: 1, rewardPoints: 30),
                SurveyQuestion(title: "كيف تستعد شخصياً لتأثير AI على مسيرتك المهنية؟",
                     options: [
                        PollOption(text: "أتعلم مهارات AI بنشاط",    votesCount: 190, percentage: 38),
                        PollOption(text: "أراقب وأنتظر التطورات",    votesCount: 175, percentage: 35),
                        PollOption(text: "لم أفكر بالأمر بعد",       votesCount: 135, percentage: 27)
                     ], displayOrder: 2, rewardPoints: 30),
                SurveyQuestion(title: "هل رؤية 2030 مُهيِّئة لسوق العمل السعودي لعصر AI؟",
                     options: [
                        PollOption(text: "نعم، على المسار الصحيح",  votesCount: 250, percentage: 50),
                        PollOption(text: "تحتاج تسريع أكبر",        votesCount: 175, percentage: 35),
                        PollOption(text: "لا تزال هناك فجوات كبيرة", votesCount: 75,  percentage: 15)
                     ], displayOrder: 3, rewardPoints: 30),
                SurveyQuestion(title: "ما القطاع الذي سيشهد أعلى خسائر وظيفية بسبب AI؟",
                     options: [
                        PollOption(text: "الخدمات والدعم الإداري", votesCount: 200, percentage: 40),
                        PollOption(text: "المحاسبة والمالية",      votesCount: 125, percentage: 25),
                        PollOption(text: "الإعلام والمحتوى",       votesCount: 100, percentage: 20),
                        PollOption(text: "التعليم",                votesCount: 75,  percentage: 15)
                     ], displayOrder: 4, rewardPoints: 30)
            ],
            topicName: "تقنية", totalResponses: 480, completionRate: 72,
            avgCompletionSeconds: 240, rewardPoints: 150
        )
    ]
}
