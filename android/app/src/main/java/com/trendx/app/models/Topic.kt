package com.trendx.app.models

import com.trendx.app.theme.PollCoverStyle
import kotlinx.serialization.Serializable

@Serializable
data class Topic(
    val id: String,
    val name: String,
    val icon: String,
    val color: String = "blue",
    val followersCount: Int = 0,
    val postsCount: Int = 0,
    val isFollowing: Boolean = false
) {
    val coverStyle: PollCoverStyle get() = PollCoverStyle.fromTopic(name)

    companion object {
        // Mirrors Topic.samples from iOS — the offline / first-run feed
        // never renders blank because of these.
        val samples: List<Topic> = listOf(
            Topic(id = sampleId(1), name = "اجتماعية", icon = "people",
                color = "blue", followersCount = 45, postsCount = 16, isFollowing = true),
            Topic(id = sampleId(2), name = "إعلام", icon = "newspaper",
                color = "purple", followersCount = 84, postsCount = 10),
            Topic(id = sampleId(3), name = "اقتصاد", icon = "trendingup",
                color = "green", followersCount = 120, postsCount = 25),
            Topic(id = sampleId(4), name = "رياضة", icon = "sports",
                color = "orange", followersCount = 200, postsCount = 42),
            Topic(id = sampleId(5), name = "تقنية", icon = "memory",
                color = "blue", followersCount = 156, postsCount = 33),
            Topic(id = sampleId(6), name = "صحة", icon = "favorite",
                color = "red", followersCount = 89, postsCount = 18)
        )

        private fun sampleId(n: Int) = "00000000-0000-0000-0000-${"%012d".format(n)}"
    }
}
