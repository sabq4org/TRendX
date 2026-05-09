//
//  AIRepository.swift
//  TRENDX
//

import Foundation

struct AIComposeResult: Codable, Equatable {
    var question: String
    var options: [String]
    var clarityScore: Int
    var rationale: String
}

final class AIRepository {
    private let client: TrendXAPIClient

    init(client: TrendXAPIClient) {
        self.client = client
    }

    func composePoll(
        question: String,
        topicName: String?,
        type: PollType,
        session: AuthSession?
    ) async -> AIComposeResult {
        let fallback = AIComposeResult(
            question: question,
            options: TrendXAI.suggestedOptions(for: question, topicName: topicName, type: type),
            clarityScore: TrendXAI.clarityScore(
                question: question,
                options: TrendXAI.suggestedOptions(for: question, topicName: topicName, type: type)
            ),
            rationale: "اقتراح محلي احتياطي من TRENDX AI."
        )

        guard client.config.isConfigured else { return fallback }

        do {
            return try await client.post(
                "/ai/compose-poll",
                accessToken: session?.accessToken,
                body: AIComposeRequest(question: question, topicName: topicName, type: type.rawValue)
            )
        } catch {
            return fallback
        }
    }

    func pollInsight(for poll: Poll, session: AuthSession?) async -> String {
        let fallback = TrendXAI.postVoteInsight(for: poll)
        guard client.config.isConfigured else { return fallback }

        do {
            let result: AIInsightResponse = try await client.post(
                "/ai/poll-insight",
                accessToken: session?.accessToken,
                body: AIInsightRequest(poll: PollDTO(domain: poll))
            )
            return result.insight
        } catch {
            return fallback
        }
    }
}

private struct AIComposeRequest: Encodable {
    let question: String
    let topicName: String?
    let type: String
}

private struct AIInsightRequest: Encodable {
    let poll: PollDTO
}

private struct AIInsightResponse: Decodable {
    let insight: String
}
