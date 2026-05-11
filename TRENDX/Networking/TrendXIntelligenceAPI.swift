//
//  TrendXIntelligenceAPI.swift
//  TRENDX
//
//  Strongly-typed Swift client for the Layer-3 backend endpoints
//  (deep analytics, persona detection, sector benchmarking, sentiment
//  timelines). The shapes mirror the snake_case JSON returned by Hono;
//  `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` (already
//  configured on `TrendXAPIClient`) takes care of the conversion.
//
//  These endpoints are read-only and idempotent — safe to call from
//  any view, keep the requests behind a publisher-mode flag in the UI
//  if you only want to expose them on certain accounts.
//

import Foundation

// MARK: - Personas

struct TrendXModalAnswer: Decodable {
    let questionId: UUID
    let questionTitle: String
    let optionText: String
}

struct TrendXPersona: Decodable, Identifiable {
    var id: Int { clusterIndex }
    let clusterIndex: Int
    let size: Int
    let sharePct: Double
    let dominantGender: String?
    let dominantAgeGroup: String?
    let dominantCity: String?
    let name: String
    let description: String
    let traits: [String]
    let representativeQuote: String
    let modalAnswers: [TrendXModalAnswer]
}

struct TrendXSurveyPersonas: Decodable {
    let surveyId: UUID
    let k: Int
    let sampleSize: Int
    let cached: Bool
    let generatedAt: String
    let promptVersion: String
    let model: String
    let personas: [TrendXPersona]
}

// MARK: - Sentiment timeline

struct TrendXSentimentDay: Decodable {
    let date: String
    let sentiment: Double
    let sample: Int
    let polls: Int
    let surveys: Int
}

struct TrendXSentimentTimeline: Decodable {
    let topicId: UUID
    let topicName: String
    let days: Int
    let series: [TrendXSentimentDay]
    let currentScore: Double
    let direction: String      // "rising" | "falling" | "stable"
    let delta30d: Double
    let computedAt: String

    enum CodingKeys: String, CodingKey {
        case days, series, direction
        case topicId       = "topic_id"
        case topicName     = "topic_name"
        case currentScore  = "current_score"
        case delta30d      = "delta_30d"
        case computedAt    = "computed_at"
    }
}

// MARK: - Sector benchmark

struct TrendXBenchmarkRow: Decodable, Identifiable {
    var id: UUID { topicId }
    let topicId: UUID
    let topicName: String
    let topicSlug: String
    let pollsCount: Int
    let surveysCount: Int
    let totalVotes: Int
    let totalResponses: Int
    let avgCompletionRate: Int
    let followersCount: Int
    let sentimentScore: Double?
    let sentimentDirection: String?
}

struct TrendXBenchmarkLeaders: Decodable {
    let byEngagement: UUID?
    let byCompletion: UUID?
    let bySentiment: UUID?
    let byFollowers: UUID?
}

struct TrendXSectorBenchmark: Decodable {
    let topicIds: [UUID]
    let rows: [TrendXBenchmarkRow]
    let leaders: TrendXBenchmarkLeaders
    let computedAt: String
}

// MARK: - Heatmap

struct TrendXHeatmapCell: Decodable {
    let x: String
    let y: String
    let count: Int
    let rowPct: Double
}

struct TrendXHeatmap: Decodable {
    let surveyId: UUID?
    let pollId: UUID?
    let questionId: UUID?
    let xDim: String
    let yDim: String
    let xKeys: [String]
    let yKeys: [String]
    let cells: [TrendXHeatmapCell]
    let total: Int
    let computedAt: String
}

// MARK: - Cross-question

struct TrendXCrossQuestionCell: Decodable {
    let q1OptionId: UUID
    let q2OptionId: UUID
    let count: Int
    let conditionalPct: Double
}

struct TrendXCrossQuestion: Decodable {
    struct Question: Decodable {
        struct Option: Decodable { let id: UUID; let text: String }
        let id: UUID
        let title: String
        let options: [Option]
    }
    let surveyId: UUID
    let q1: Question
    let q2: Question
    let matrix: [[TrendXCrossQuestionCell]]
    let chiSquared: Double
    let degreesOfFreedom: Int
    let significance: String
    let sampleSize: Int
    let computedAt: String
}

// MARK: - Client extension

extension TrendXAPIClient {
    /// Persona profiles for a completed survey. Heavy first call (k-medoids
    /// + GPT-4o); subsequent calls within 6h are served from cache.
    func surveyPersonas(
        surveyId: UUID,
        accessToken: String,
        forceRefresh: Bool = false
    ) async throws -> TrendXSurveyPersonas {
        let suffix = forceRefresh ? "?refresh=1" : ""
        return try await get("/surveys/\(surveyId.uuidString)/personas\(suffix)",
                             accessToken: accessToken)
    }

    /// Daily sentiment for a topic over the last `days` days (7..90).
    func topicSentimentTimeline(
        topicId: UUID,
        days: Int = 30,
        accessToken: String
    ) async throws -> TrendXSentimentTimeline {
        try await get("/analytics/topic/\(topicId.uuidString)/sentiment-timeline?days=\(days)",
                      accessToken: accessToken)
    }

    /// Side-by-side benchmark of 2..6 sectors.
    func sectorBenchmark(
        topicIds: [UUID],
        accessToken: String
    ) async throws -> TrendXSectorBenchmark {
        let csv = topicIds.map(\.uuidString).joined(separator: ",")
        return try await get("/analytics/sectors/benchmark?topic_ids=\(csv)",
                             accessToken: accessToken)
    }

    /// Two-dimensional heatmap of vote demographics for a poll.
    func pollHeatmap(
        pollId: UUID,
        x: String,
        y: String,
        optionId: UUID? = nil,
        accessToken: String
    ) async throws -> TrendXHeatmap {
        var path = "/analytics/poll/\(pollId.uuidString)/heatmap?x=\(x)&y=\(y)"
        if let optionId { path += "&option_id=\(optionId.uuidString)" }
        return try await get(path, accessToken: accessToken)
    }

    /// Two-dimensional heatmap of survey response demographics, optionally
    /// filtered by a chosen question/option.
    func surveyHeatmap(
        surveyId: UUID,
        x: String,
        y: String,
        questionId: UUID? = nil,
        optionId: UUID? = nil,
        accessToken: String
    ) async throws -> TrendXHeatmap {
        var path = "/analytics/survey/\(surveyId.uuidString)/heatmap?x=\(x)&y=\(y)"
        if let questionId { path += "&question_id=\(questionId.uuidString)" }
        if let optionId   { path += "&option_id=\(optionId.uuidString)" }
        return try await get(path, accessToken: accessToken)
    }

    /// Joint distribution between two questions of one survey (with χ²
    /// significance bucket).
    func surveyCrossQuestion(
        surveyId: UUID,
        q1: UUID,
        q2: UUID,
        accessToken: String
    ) async throws -> TrendXCrossQuestion {
        try await get("/analytics/survey/\(surveyId.uuidString)/cross-question?q1=\(q1.uuidString)&q2=\(q2.uuidString)",
                      accessToken: accessToken)
    }
}

// MARK: - Daily Pulse (نبض اليوم)

struct TrendXPulseOption: Decodable, Identifiable {
    var id: Int { index }
    let index: Int
    let text: String
    let votes: Int
    let percentage: Double
}

struct TrendXDailyPulse: Decodable {
    let id: UUID
    let pulseDate: String
    let question: String
    let description: String?
    let options: [TrendXPulseOption]
    let totalResponses: Int
    let status: String
    let closesAt: String
    let rewardPoints: Int
    let topicId: UUID?
    let aiSummary: String?
    let userResponded: Bool?
    let userChoice: Int?
}

struct TrendXUserStreak: Decodable {
    let currentStreak: Int
    let longestStreak: Int
    let totalPulses: Int
    let freezesLeft: Int
    let lastPulseDate: String?
    let status: String?
    let isPersonalBest: Bool?
    let delta: String?
}

struct TrendXPulseResponse: Decodable {
    let pulse: TrendXDailyPulse
    let reward: Int
    let streak: TrendXUserStreak
    let predictionScore: Int?
}

struct TrendXPulseHistoryItem: Decodable, Identifiable {
    var id: String { pulseDate }
    let pulseDate: String
    let question: String
    let totalResponses: Int
    let leadingOptionText: String?
    let leadingPct: Double
}

struct TrendXPulseHistory: Decodable {
    let items: [TrendXPulseHistoryItem]
}

struct TrendXPulseYesterday: Decodable {
    let pulse: TrendXDailyPulse?
}

private struct PulseRespondBody: Encodable {
    let optionIndex: Int
    let predictedPct: Int?
}

extension TrendXAPIClient {
    func pulseToday(accessToken: String) async throws -> TrendXDailyPulse {
        try await get("/pulse/today", accessToken: accessToken)
    }
    func pulseRespond(optionIndex: Int, predictedPct: Int?, accessToken: String) async throws -> TrendXPulseResponse {
        try await post("/pulse/today/respond",
                       accessToken: accessToken,
                       body: PulseRespondBody(optionIndex: optionIndex, predictedPct: predictedPct))
    }
    func pulseYesterday(accessToken: String) async throws -> TrendXPulseYesterday {
        try await get("/pulse/yesterday", accessToken: accessToken)
    }
    func pulseHistory(days: Int = 14, accessToken: String) async throws -> TrendXPulseHistory {
        try await get("/pulse/history?days=\(days)", accessToken: accessToken)
    }
    func myStreak(accessToken: String) async throws -> TrendXUserStreak {
        try await get("/me/streak", accessToken: accessToken)
    }
}

// MARK: - Opinion DNA

struct TrendXDNAAxis: Decodable, Identifiable {
    var id: String { key }
    let key: String
    let labelHigh: String
    let labelLow: String
    let score: Int
}

struct TrendXDNAArchetype: Decodable {
    let title: String
    let blurb: String
}

struct TrendXOpinionDNA: Decodable {
    let computedAt: String
    let sampleSize: Int
    let axes: [TrendXDNAAxis]
    let archetype: TrendXDNAArchetype
    let shareCaption: String
}

extension TrendXAPIClient {
    func myOpinionDNA(accessToken: String) async throws -> TrendXOpinionDNA {
        try await get("/me/dna", accessToken: accessToken)
    }
    func refreshOpinionDNA(accessToken: String) async throws -> TrendXOpinionDNA {
        try await post("/me/dna/refresh", accessToken: accessToken, body: EmptyBody())
    }
}

// MARK: - TRENDX Index (public)

// NOTE on coding keys:
// Swift's `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`
// turns `change_24h` into `change24H` (capitalising the first letter
// of *every* segment, even "24h" — see `String.capitalized`). That
// breaks decoding because the property below is `change24h` with a
// lowercase `h`. We pin the keys explicitly to dodge the rule.
struct TrendXIndexMetric: Decodable, Identifiable {
    var id: String { slug }
    let slug: String
    let name: String
    let value: Int
    let change24h: Int
    let direction: String   // "up" | "down" | "flat"
    let sampleSize: Int
    let blurb: String

    enum CodingKeys: String, CodingKey {
        case slug, name, value, direction, blurb
        case change24h = "change_24h"
        case sampleSize = "sample_size"
    }
}

struct TrendXIndex: Decodable {
    let computedAt: String
    let composite: Int
    let compositeChange24h: Int
    let totalResponses: Int
    let metrics: [TrendXIndexMetric]

    enum CodingKeys: String, CodingKey {
        case composite, metrics
        case computedAt           = "computed_at"
        case compositeChange24h   = "composite_change_24h"
        case totalResponses       = "total_responses"
    }
}

extension TrendXAPIClient {
    /// Public — no auth needed.
    func trendxIndex() async throws -> TrendXIndex {
        try await get("/public/index")
    }
}

// MARK: - Predictive Accuracy

struct TrendXUserAccuracy: Decodable {
    let predictions: Int
    let scored: Int
    let averageAccuracy: Int
    let bestAccuracy: Int
    let rankPercentile: Int
}

struct TrendXAccuracyLeaderItem: Decodable, Identifiable {
    var id: UUID { userId }
    let userId: UUID
    let name: String
    let avatarInitial: String
    let predictions: Int
    let averageAccuracy: Int
}

struct TrendXAccuracyLeaderboard: Decodable {
    let items: [TrendXAccuracyLeaderItem]
}

private struct PredictBody: Encodable {
    let predictedPct: Int
}

extension TrendXAPIClient {
    func predictPoll(pollId: UUID, predictedPct: Int, accessToken: String) async throws -> EmptyResponse {
        try await post("/polls/\(pollId.uuidString)/predict",
                       accessToken: accessToken,
                       body: PredictBody(predictedPct: predictedPct))
    }
    func myAccuracy(accessToken: String) async throws -> TrendXUserAccuracy {
        try await get("/me/accuracy", accessToken: accessToken)
    }
    func accuracyLeaderboard(limit: Int = 25, accessToken: String) async throws -> TrendXAccuracyLeaderboard {
        try await get("/accuracy/leaderboard?limit=\(limit)", accessToken: accessToken)
    }
}

// MARK: - Weekly Challenge

struct TrendXMyChallengePrediction: Decodable {
    let predictedPct: Int
    let distance: Int?
    let rank: Int?
}

struct TrendXWeeklyChallenge: Decodable {
    let id: UUID
    let weekStart: String
    let question: String
    let description: String?
    let metricLabel: String
    let closesAt: String
    let status: String
    let targetPct: Int?
    let rewardPoints: Int
    let totalPredictions: Int
    let myPrediction: TrendXMyChallengePrediction?
}

extension TrendXAPIClient {
    func thisWeekChallenge(accessToken: String) async throws -> TrendXWeeklyChallenge {
        try await get("/challenges/this-week", accessToken: accessToken)
    }
    func predictChallenge(id: UUID, predictedPct: Int, accessToken: String) async throws -> EmptyResponse {
        try await post("/challenges/\(id.uuidString)/predict",
                       accessToken: accessToken,
                       body: PredictBody(predictedPct: predictedPct))
    }
}

// MARK: - Comments (الحوار)

struct TrendXCommentUser: Decodable {
    let id: UUID
    let name: String
    let avatarInitial: String
}

struct TrendXComment: Decodable, Identifiable {
    let id: UUID
    let body: String
    let score: Int
    let upvotes: Int
    let downvotes: Int
    let createdAt: String
    let authorVoteOptionId: UUID?
    let user: TrendXCommentUser
}

struct TrendXCommentsList: Decodable {
    let items: [TrendXComment]
}

private struct CommentBody: Encodable { let body: String }
private struct CommentVoteBody: Encodable { let value: Int }

extension TrendXAPIClient {
    func pollComments(pollId: UUID, sort: String = "top", accessToken: String) async throws -> TrendXCommentsList {
        try await get("/polls/\(pollId.uuidString)/comments?sort=\(sort)", accessToken: accessToken)
    }
    func postComment(pollId: UUID, body: String, accessToken: String) async throws -> EmptyResponse {
        try await post("/polls/\(pollId.uuidString)/comments",
                       accessToken: accessToken,
                       body: CommentBody(body: body))
    }
    func voteComment(commentId: UUID, value: Int, accessToken: String) async throws -> EmptyResponse {
        try await post("/comments/\(commentId.uuidString)/vote",
                       accessToken: accessToken,
                       body: CommentVoteBody(value: value))
    }
}

// MARK: - Points ledger

struct TrendXLedgerEntry: Decodable, Identifiable {
    let id: UUID
    let amount: Int
    let type: String
    let description: String?
    let balanceAfter: Int?
    let createdAt: Date
}

extension TrendXAPIClient {
    func pointsLedger(accessToken: String) async throws -> [TrendXLedgerEntry] {
        try await get("/points/ledger", accessToken: accessToken)
    }
}

private struct EmptyBody: Encodable {}
