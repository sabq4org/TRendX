//
//  SurveyRepository.swift
//  TRENDX
//
//  Talks to the Railway backend's /surveys/* endpoints. Mirrors
//  PollRepository's offline-first contract: when the API is not
//  configured we fall back to whatever the caller passed in (or to
//  the cached samples) so the UI keeps working without a network.
//

import Foundation

final class SurveyRepository {
    private let client: TrendXAPIClient
    private let defaults: UserDefaults

    init(client: TrendXAPIClient, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
    }

    // MARK: - Reads

    /// Lists active surveys. Falls back to cached/sample surveys if
    /// the API is unreachable so PollsScreen never goes blank.
    func loadSurveys(session: AuthSession?) async throws -> [Survey] {
        guard client.config.isConfigured else { return cachedSurveys() }

        do {
            let response: [SurveyDTO] = try await client.get(
                "/surveys",
                accessToken: session?.accessToken
            )
            let surveys = response.map(\.domain)
            cache(surveys)
            return surveys
        } catch {
            return cachedSurveys()
        }
    }

    func loadSurvey(id: UUID, session: AuthSession?) async throws -> Survey {
        guard client.config.isConfigured else {
            throw TrendXAPIError.notConfigured
        }
        let dto: SurveyDTO = try await client.get(
            "/surveys/\(id.uuidString)",
            accessToken: session?.accessToken
        )
        return dto.domain
    }

    // MARK: - Writes

    func submitResponse(
        surveyId: UUID,
        answers: [SurveyAnswerInput],
        completionSeconds: Int?,
        session: AuthSession?
    ) async throws -> SurveyResponseAck {
        guard client.config.isConfigured else {
            // No backend wired — pretend success so the UI flow stays usable
            return SurveyResponseAck(ok: true, responseId: UUID(), isComplete: true)
        }
        let body = SurveyRespondRequest(
            answers: answers,
            completionSeconds: completionSeconds
        )
        return try await client.post(
            "/surveys/\(surveyId.uuidString)/respond",
            accessToken: session?.accessToken,
            body: body
        )
    }

    func createSurvey(
        _ survey: Survey,
        session: AuthSession?
    ) async throws -> Survey {
        guard client.config.isConfigured else { return survey }

        let request = CreateSurveyRequest(domain: survey)
        let response: CreateSurveyResponse = try await client.post(
            "/surveys/create",
            accessToken: session?.accessToken,
            body: request
        )
        return response.survey.domain
    }

    // MARK: - Cache

    private func cachedSurveys() -> [Survey] {
        if let data = defaults.data(forKey: "trendx_surveys_v1"),
           let surveys = try? JSONDecoder().decode([Survey].self, from: data),
           !surveys.isEmpty {
            return surveys
        }
        return Survey.techSamples
    }

    private func cache(_ surveys: [Survey]) {
        if let data = try? JSONEncoder().encode(surveys) {
            defaults.set(data, forKey: "trendx_surveys_v1")
        }
    }
}

// MARK: - Submit DTOs

struct SurveyAnswerInput: Encodable {
    let questionId: UUID
    let optionId: UUID
    let seconds: Int?
}

private struct SurveyRespondRequest: Encodable {
    let answers: [SurveyAnswerInput]
    let completionSeconds: Int?
}

struct SurveyResponseAck: Decodable {
    let ok: Bool
    let responseId: UUID
    let isComplete: Bool
}

// MARK: - Read / Create DTOs

private struct SurveyDTO: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let imageUrl: String?
    let coverStyle: String?
    let publisherId: UUID?
    let topicId: UUID?
    let topicName: String?
    let status: String?
    let rewardPoints: Int?
    let durationDays: Int?
    let totalResponses: Int?
    let totalCompletes: Int?
    let avgCompletionSeconds: Int?
    let completionRate: Int?
    let questions: [SurveyQuestionDTO]?
    let createdAt: Date?
    let expiresAt: Date?

    var domain: Survey {
        Survey(
            id: id,
            title: title,
            description: description ?? "",
            authorName: "TrendX Research",
            authorAvatar: "T",
            authorIsVerified: true,
            coverStyle: PollCoverStyle.from(rawValue: coverStyle) ?? .generic,
            questions: (questions ?? []).map(\.domainPoll),
            topicName: topicName,
            totalResponses: totalResponses ?? 0,
            completionRate: Double(completionRate ?? 0),
            avgCompletionSeconds: avgCompletionSeconds ?? 180,
            status: PollStatus(rawValue: status ?? "active") ?? .active,
            createdAt: createdAt ?? Date(),
            expiresAt: expiresAt ?? Date().addingTimeInterval(14 * 24 * 60 * 60),
            rewardPoints: rewardPoints ?? 120
        )
    }
}

private struct SurveyQuestionDTO: Decodable {
    let id: UUID
    let surveyId: UUID?
    let title: String
    let description: String?
    let type: String?
    let displayOrder: Int?
    let rewardPoints: Int?
    let isRequired: Bool?
    let options: [SurveyOptionDTO]?

    /// Express each survey question as a Poll so the existing iOS
    /// model graph (Survey.questions: [Poll]) keeps working without
    /// a parallel hierarchy.
    var domainPoll: Poll {
        let opts = (options ?? []).map { o in
            PollOption(id: o.id, text: o.text, votesCount: o.votesCount ?? 0, percentage: 0)
        }
        return Poll(
            id: id,
            title: title,
            description: description,
            imageURL: nil,
            coverStyle: .generic,
            authorName: "TrendX",
            authorAvatar: "T",
            authorIsVerified: true,
            options: opts,
            topicId: nil,
            topicName: nil,
            type: PollType(rawValue: type ?? "single_choice") ?? .singleChoice,
            status: .active,
            totalVotes: opts.reduce(0) { $0 + $1.votesCount },
            rewardPoints: rewardPoints ?? 25,
            durationDays: 14,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(14 * 24 * 60 * 60),
            userVotedOptionId: nil,
            isBookmarked: false,
            sharesCount: 0,
            repostsCount: 0,
            aiInsight: nil
        )
    }
}

private struct SurveyOptionDTO: Decodable {
    let id: UUID
    let text: String
    let displayOrder: Int?
    let votesCount: Int?
}

// MARK: - Create Survey request

private struct CreateSurveyRequest: Encodable {
    let survey: SurveyEnvelope
    let questions: [QuestionEnvelope]

    init(domain: Survey) {
        self.survey = SurveyEnvelope(
            title: domain.title,
            description: domain.description.isEmpty ? nil : domain.description,
            coverStyle: domain.coverStyle.rawValue,
            topicId: nil,
            rewardPoints: domain.rewardPoints,
            durationDays: max(1, Calendar.current.dateComponents(
                [.day], from: domain.createdAt, to: domain.expiresAt
            ).day ?? 14)
        )
        self.questions = domain.questions.map { q in
            QuestionEnvelope(
                title: q.title,
                type: q.type.rawValue,
                rewardPoints: q.rewardPoints,
                options: q.options.map { OptionEnvelope(text: $0.text) }
            )
        }
    }

    struct SurveyEnvelope: Encodable {
        let title: String
        let description: String?
        let coverStyle: String?
        let topicId: UUID?
        let rewardPoints: Int
        let durationDays: Int
    }

    struct QuestionEnvelope: Encodable {
        let title: String
        let type: String
        let rewardPoints: Int
        let options: [OptionEnvelope]
    }

    struct OptionEnvelope: Encodable {
        let text: String
    }
}

private struct CreateSurveyResponse: Decodable {
    let survey: CreateSurveyEcho

    /// The /surveys/create endpoint echoes the same shape as /surveys/:id
    /// so we just re-decode through SurveyDTO.
    var domain: Survey { survey.domain }
}

private struct CreateSurveyEcho: Decodable {
    private let inner: SurveyDTO

    init(from decoder: Decoder) throws {
        self.inner = try SurveyDTO(from: decoder)
    }

    var domain: Survey { inner.domain }
}

// MARK: - PollCoverStyle helper

private extension PollCoverStyle {
    static func from(rawValue: String?) -> PollCoverStyle? {
        guard let raw = rawValue else { return nil }
        return PollCoverStyle(rawValue: raw)
    }
}
