package com.trendx.app.models

import com.trendx.app.theme.PollCoverStyle
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlin.time.Duration.Companion.days

// Mirrors TRENDX/Models/Models.swift Survey + SurveyQuestion 1-for-1.
// Survey questions are distinct from Poll because they live only inside
// their parent and don't carry standalone metadata (author / shares / etc.).

@Serializable
data class SurveyQuestion(
    val id: String,
    val title: String,
    val description: String? = null,
    val type: PollType = PollType.SingleChoice,
    val options: List<PollOption> = emptyList(),
    val displayOrder: Int = 0,
    val rewardPoints: Int = 25,
    val isRequired: Boolean = true
) {
    val totalVotes: Int get() = options.sumOf { it.votesCount }
}

@Serializable
data class Survey(
    val id: String,
    val title: String,
    val description: String = "",
    val imageUrl: String? = null,
    val authorName: String = "TrendX Research",
    val authorAvatar: String = "T",
    val authorAvatarUrl: String? = null,
    val authorIsVerified: Boolean = true,
    val authorAccountType: AccountType = AccountType.individual,
    val authorHandle: String? = null,
    val publisherId: String? = null,
    val coverStyle: PollCoverStyle = PollCoverStyle.Generic,
    val questions: List<SurveyQuestion> = emptyList(),
    val topicName: String? = null,
    val totalResponses: Int = 0,
    val completionRate: Double = 0.0,
    val avgCompletionSeconds: Int = 180,
    val status: PollStatus = PollStatus.Active,
    val createdAt: Instant = Clock.System.now(),
    val expiresAt: Instant = Clock.System.now().plus(14.days),
    val rewardPoints: Int = 150
) {
    val questionCount: Int get() = questions.size
    val isExpired: Boolean get() = Clock.System.now() > expiresAt
    val remainingDays: Int get() {
        val seconds = (expiresAt - Clock.System.now()).inWholeSeconds
        return if (seconds <= 0) 0 else (seconds / 86_400).toInt()
    }

    companion object {
        // Sample tech-survey content matching iOS Survey.samples 1-for-1.
        val techSamples: List<Survey> = listOf(
            Survey(
                id = "survey-tech-1",
                title = "الذكاء الاصطناعي في حياتنا اليومية",
                description = "دراسة شاملة حول تأثير تقنيات AI على سلوكيات وأولويات المجتمع السعودي",
                coverStyle = PollCoverStyle.Tech,
                questions = listOf(
                    SurveyQuestion(
                        id = "q1-1",
                        title = "كم ساعة يومياً تستخدم أدوات الذكاء الاصطناعي؟",
                        options = listOf(
                            PollOption(id = "q1-1-a", text = "أقل من ساعة", votesCount = 180, percentage = 36.0),
                            PollOption(id = "q1-1-b", text = "1-3 ساعات", votesCount = 225, percentage = 45.0),
                            PollOption(id = "q1-1-c", text = "أكثر من 3 ساعات", votesCount = 95, percentage = 19.0)
                        ),
                        displayOrder = 0, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q1-2",
                        title = "ما مدى تأثير AI على إنتاجيتك المهنية؟",
                        options = listOf(
                            PollOption(id = "q1-2-a", text = "زاد إنتاجيتي كثيراً", votesCount = 220, percentage = 44.0),
                            PollOption(id = "q1-2-b", text = "تحسن طفيف", votesCount = 175, percentage = 35.0),
                            PollOption(id = "q1-2-c", text = "لم يتغيّر شيء", votesCount = 65, percentage = 13.0),
                            PollOption(id = "q1-2-d", text = "أثّر سلباً", votesCount = 40, percentage = 8.0)
                        ),
                        displayOrder = 1, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q1-3",
                        title = "هل تقلق من تأثير AI على سوق العمل؟",
                        options = listOf(
                            PollOption(id = "q1-3-a", text = "نعم، قلق شديد", votesCount = 130, percentage = 26.0),
                            PollOption(id = "q1-3-b", text = "قلق متوسط", votesCount = 185, percentage = 37.0),
                            PollOption(id = "q1-3-c", text = "لست قلقاً", votesCount = 145, percentage = 29.0),
                            PollOption(id = "q1-3-d", text = "متفائل جداً", votesCount = 40, percentage = 8.0)
                        ),
                        displayOrder = 2, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q1-4",
                        title = "أي مجال ترى فيه AI التحول الأكبر؟",
                        options = listOf(
                            PollOption(id = "q1-4-a", text = "الصحة والطب", votesCount = 165, percentage = 33.0),
                            PollOption(id = "q1-4-b", text = "التعليم والتدريب", votesCount = 150, percentage = 30.0),
                            PollOption(id = "q1-4-c", text = "الأعمال والاقتصاد", votesCount = 110, percentage = 22.0),
                            PollOption(id = "q1-4-d", text = "الإعلام والمحتوى", votesCount = 75, percentage = 15.0)
                        ),
                        displayOrder = 3, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q1-5",
                        title = "ما مدى استعدادك للدفع مقابل استخدام AI؟",
                        options = listOf(
                            PollOption(id = "q1-5-a", text = "مستعد إذا كانت القيمة عادلة", votesCount = 195, percentage = 39.0),
                            PollOption(id = "q1-5-b", text = "فقط باشتراك مدفوع مسبقاً", votesCount = 120, percentage = 24.0),
                            PollOption(id = "q1-5-c", text = "أفضل النماذج المجانية فقط", votesCount = 110, percentage = 22.0),
                            PollOption(id = "q1-5-d", text = "لست مستعداً للدفع", votesCount = 75, percentage = 15.0)
                        ),
                        displayOrder = 4, rewardPoints = 30
                    )
                ),
                topicName = "تقنية", totalResponses = 500, completionRate = 78.0,
                avgCompletionSeconds = 210, rewardPoints = 150
            ),
            Survey(
                id = "survey-tech-2",
                title = "ثقة المجتمع بتقنيات AI في اتخاذ القرار",
                description = "هل يثق الجمهور بقرارات تتخذها أنظمة الذكاء الاصطناعي؟",
                coverStyle = PollCoverStyle.Tech,
                questions = listOf(
                    SurveyQuestion(
                        id = "q2-1",
                        title = "هل تثق بقرار طبي AI بدون مراجعة بشرية؟",
                        options = listOf(
                            PollOption(id = "q2-1-a", text = "نعم، أثق به", votesCount = 180, percentage = 36.0),
                            PollOption(id = "q2-1-b", text = "بحذر، أحتاج مراجعة", votesCount = 245, percentage = 49.0),
                            PollOption(id = "q2-1-c", text = "لا، لا أثق", votesCount = 75, percentage = 15.0)
                        ),
                        displayOrder = 0, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q2-2",
                        title = "هل تثق بحكم قضائي AI في قضية بسيطة؟",
                        options = listOf(
                            PollOption(id = "q2-2-a", text = "نعم", votesCount = 140, percentage = 28.0),
                            PollOption(id = "q2-2-b", text = "بشروط محددة", votesCount = 210, percentage = 42.0),
                            PollOption(id = "q2-2-c", text = "لا إطلاقاً", votesCount = 150, percentage = 30.0)
                        ),
                        displayOrder = 1, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q2-3",
                        title = "من يتحمل مسؤولية قرار AI الخاطئ؟",
                        options = listOf(
                            PollOption(id = "q2-3-a", text = "الشركة المطوّرة", votesCount = 225, percentage = 45.0),
                            PollOption(id = "q2-3-b", text = "المستخدم", votesCount = 100, percentage = 20.0),
                            PollOption(id = "q2-3-c", text = "كلاهما معاً", votesCount = 175, percentage = 35.0)
                        ),
                        displayOrder = 2, rewardPoints = 30
                    ),
                    SurveyQuestion(
                        id = "q2-4",
                        title = "هل يجب تنظيم AI حكومياً في السعودية؟",
                        options = listOf(
                            PollOption(id = "q2-4-a", text = "نعم، تنظيم صارم", votesCount = 310, percentage = 62.0),
                            PollOption(id = "q2-4-b", text = "تنظيم خفيف فقط", votesCount = 140, percentage = 28.0),
                            PollOption(id = "q2-4-c", text = "لا حاجة لتنظيم", votesCount = 50, percentage = 10.0)
                        ),
                        displayOrder = 3, rewardPoints = 30
                    )
                ),
                topicName = "تقنية", totalResponses = 500, completionRate = 74.0,
                avgCompletionSeconds = 195, rewardPoints = 130
            ),
            Survey(
                id = "survey-tech-3",
                title = "ذكاء اصطناعي في التعليم: تحوّل أم تهديد؟",
                description = "تقييم مدى جاهزية المنظومة التعليمية لاستيعاب تقنيات الذكاء الاصطناعي",
                coverStyle = PollCoverStyle.Tech,
                questions = listOf(
                    SurveyQuestion(
                        id = "q3-1",
                        title = "هل تستخدم AI في دراستك أو عملك؟",
                        options = listOf(
                            PollOption(id = "q3-1-a", text = "نعم، يومياً", votesCount = 280, percentage = 56.0),
                            PollOption(id = "q3-1-b", text = "أحياناً", votesCount = 140, percentage = 28.0),
                            PollOption(id = "q3-1-c", text = "لا، لم أجرّبه", votesCount = 80, percentage = 16.0)
                        ),
                        displayOrder = 0, rewardPoints = 25
                    ),
                    SurveyQuestion(
                        id = "q3-2",
                        title = "هل AI يساعد في الفهم أو يضعف التفكير؟",
                        options = listOf(
                            PollOption(id = "q3-2-a", text = "يساعد كثيراً", votesCount = 220, percentage = 44.0),
                            PollOption(id = "q3-2-b", text = "يساعد لكن بحذر", votesCount = 185, percentage = 37.0),
                            PollOption(id = "q3-2-c", text = "يضعف التفكير", votesCount = 95, percentage = 19.0)
                        ),
                        displayOrder = 1, rewardPoints = 25
                    ),
                    SurveyQuestion(
                        id = "q3-3",
                        title = "ما أكثر استخدامات AI في التعليم؟",
                        options = listOf(
                            PollOption(id = "q3-3-a", text = "تلخيص المعلومات", votesCount = 215, percentage = 43.0),
                            PollOption(id = "q3-3-b", text = "كتابة التقارير", votesCount = 160, percentage = 32.0),
                            PollOption(id = "q3-3-c", text = "حل المسائل", votesCount = 125, percentage = 25.0)
                        ),
                        displayOrder = 2, rewardPoints = 25
                    ),
                    SurveyQuestion(
                        id = "q3-4",
                        title = "هل يجب تعليم AI كمادة مستقلة؟",
                        options = listOf(
                            PollOption(id = "q3-4-a", text = "نعم، ضروري", votesCount = 300, percentage = 60.0),
                            PollOption(id = "q3-4-b", text = "يكفي ضمن مواد أخرى", votesCount = 150, percentage = 30.0),
                            PollOption(id = "q3-4-c", text = "ليست ضرورة", votesCount = 50, percentage = 10.0)
                        ),
                        displayOrder = 3, rewardPoints = 25
                    )
                ),
                topicName = "تقنية", totalResponses = 420, completionRate = 81.0,
                avgCompletionSeconds = 185, rewardPoints = 120
            )
        )
    }
}

data class SurveyAnswerInput(
    val questionId: String,
    val optionId: String,
    val seconds: Int? = null
)
