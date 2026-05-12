package com.trendx.app.theme

// Mirrors TRENDX/Stores/TrendXAI.swift — the Arabic-first greetings, brief
// copy, and section subtitles that give the iOS app its TRENDX-AI voice.
// Keep these in lockstep with the Swift source so screenshots from iOS and
// Android tell the same story.
object TrendXAI {

    data class Greeting(val eyebrow: String, val title: String, val whisper: String)

    fun greeting(name: String): Greeting {
        val firstName = name.trim().split(' ').firstOrNull()?.takeIf { it.isNotEmpty() } ?: "صديقي"
        return Greeting(
            eyebrow = "مرحباً بعودتك",
            title = "أهلاً $firstName",
            whisper = "TRENDX يتابع لك آخر النبض ويحضّر اقتراحات اليوم. ابدأ من حيث توقّفت."
        )
    }

    val trendingSubtitle: String = "أكثر استطلاعات اليوم تفاعلاً — خوارزمية الاتجاه تحدّثها كل ساعة."
    val communitySubtitle: String = "آراء حقيقية من مجتمعك — صوّت ورأيك يبني الموجة القادمة."
    val topicsSubtitle: String = "نختار لك المجالات الأقرب لاهتماماتك من سلوكك على TRENDX."
    val aiSearchPlaceholder: String = "ابحث عن موضوع، أو اطلب من TRENDX AI…"

    fun encouragement(): String =
        "شكراً لمشاركتك — رأيك صار جزءاً من النبض. لاحقاً ستظهر هنا قراءة AI خاصة بهذا الاستطلاع."

    data class AIBrief(val icon: String, val headline: String, val tag: String, val body: String)

    /// Lightweight client-side brief used by AIBriefCard. The iOS app
    /// derives its brief from active polls + topics + user; on Android we
    /// keep it simple for now and rotate among three editorial briefs by
    /// day-of-month. Plumb the real generator in a follow-up pass.
    fun dailyBrief(activePollCount: Int, topicsCount: Int): AIBrief {
        val day = (System.currentTimeMillis() / 86_400_000L).toInt()
        return when (day % 3) {
            0 -> AIBrief(
                icon = "Insights",
                headline = "النبض اليومي يميل نحو الاقتصاد والابتكار",
                tag = "خلاصة AI",
                body = "$activePollCount استطلاعاً نشطاً اليوم في $topicsCount مجالاً. أعلى مشاركة في موضوعات الاقتصاد والتقنية — رأيك الآن يصنع فرقاً."
            )
            1 -> AIBrief(
                icon = "Trend",
                headline = "السعوديون يتفاعلون أكثر مع المواضيع المجتمعية مساءً",
                tag = "ملاحظة AI",
                body = "أعلى ساعات تصويت بين 9-11 مساءً، وتركّز التفاعل في موضوعات الأسرة والترفيه والإعلام. شارك الآن لتنضم للنبض."
            )
            else -> AIBrief(
                icon = "Spark",
                headline = "اتجاه صاعد: نقاش حيوي حول التقنية والذكاء الاصطناعي",
                tag = "اتجاه AI",
                body = "آراء المستطلَعين تتجه إلى التفاؤل الحذر تجاه AI — متابعو هذا المجال يضيفون أكثر من ٤٠٪ من النبض."
            )
        }
    }
}
