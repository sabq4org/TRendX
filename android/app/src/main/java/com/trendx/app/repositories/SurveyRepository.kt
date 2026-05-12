package com.trendx.app.repositories

import com.trendx.app.models.Survey
import com.trendx.app.networking.PollCreateOptionRequest
import com.trendx.app.networking.PollCreateRequest
import com.trendx.app.networking.SurveyCreateMetaRequest
import com.trendx.app.networking.SurveyCreateOptionRequest
import com.trendx.app.networking.SurveyCreateQuestionRequest
import com.trendx.app.networking.SurveyCreateRequest
import com.trendx.app.networking.SurveyRespondRequest
import com.trendx.app.networking.SurveyResponseAnswerRequest
import com.trendx.app.networking.TrendXAPIClient
import com.trendx.app.networking.createPollRemote
import com.trendx.app.networking.createSurveyRemote
import com.trendx.app.networking.getSurvey
import com.trendx.app.networking.listSurveys
import com.trendx.app.networking.respondToSurvey
import com.trendx.app.networking.toDomain

class SurveyRepository(private val client: TrendXAPIClient) {
    val isRemoteEnabled: Boolean get() = client.config.isConfigured

    suspend fun fetchSurveys(accessToken: String?): List<Survey>? = runCatching {
        client.listSurveys(accessToken).map { it.toDomain() }
    }.getOrNull()

    suspend fun fetchSurvey(id: String, accessToken: String?): Survey? = runCatching {
        client.getSurvey(id, accessToken).toDomain()
    }.getOrNull()

    suspend fun createSurvey(
        accessToken: String,
        title: String,
        description: String,
        coverStyle: String,
        rewardPoints: Int,
        durationDays: Int,
        questions: List<SurveyDraftInput>
    ): Survey? = runCatching {
        val request = SurveyCreateRequest(
            survey = SurveyCreateMetaRequest(
                title = title, description = description.takeIf { it.isNotBlank() },
                coverStyle = coverStyle, rewardPoints = rewardPoints, durationDays = durationDays
            ),
            questions = questions.map { q ->
                SurveyCreateQuestionRequest(
                    title = q.title,
                    options = q.options.map { SurveyCreateOptionRequest(it) },
                    rewardPoints = q.rewardPoints
                )
            }
        )
        client.createSurveyRemote(request, accessToken).survey.toDomain()
    }.getOrNull()

    suspend fun respondToSurvey(
        accessToken: String,
        surveyId: String,
        answers: List<Pair<String, String>>,
        completionSeconds: Int
    ): Boolean = runCatching {
        val request = SurveyRespondRequest(
            answers = answers.map { (qId, oId) ->
                SurveyResponseAnswerRequest(questionId = qId, optionId = oId)
            },
            completionSeconds = completionSeconds
        )
        client.respondToSurvey(surveyId, request, accessToken)
        true
    }.getOrDefault(false)

    suspend fun createPoll(
        accessToken: String,
        title: String,
        description: String?,
        topicId: String?,
        type: String,
        durationDays: Int,
        options: List<String>
    ): Boolean = runCatching {
        val req = PollCreateRequest(
            title = title,
            description = description?.takeIf { it.isNotBlank() },
            topicId = topicId, type = type, durationDays = durationDays,
            options = options.map { PollCreateOptionRequest(it) }
        )
        client.createPollRemote(req, accessToken)
        true
    }.getOrDefault(false)
}

data class SurveyDraftInput(
    val title: String,
    val options: List<String>,
    val rewardPoints: Int
)
