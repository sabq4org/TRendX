//
//  PollRepository.swift
//  TRENDX
//

import Foundation

struct PollBootstrap {
    var topics: [Topic]
    var polls: [Poll]
}

final class PollRepository {
    private let client: TrendXAPIClient
    private let defaults: UserDefaults

    init(client: TrendXAPIClient, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
    }

    func loadBootstrap(session: AuthSession?) async throws -> PollBootstrap {
        guard client.config.isConfigured else {
            return PollBootstrap(topics: cachedTopics(), polls: cachedPolls())
        }

        do {
            let response: BootstrapResponse = try await client.get(
                "/bootstrap",
                accessToken: session?.accessToken
            )

            let bootstrap = PollBootstrap(
                topics: response.topics.map(\.domain),
                polls: response.polls.map(\.domain)
            )
            cache(bootstrap.topics, key: "trendx_topics_v1")
            cache(bootstrap.polls, key: "trendx_polls_v1")
            return bootstrap
        } catch {
            return PollBootstrap(topics: cachedTopics(), polls: cachedPolls())
        }
    }

    func createPoll(_ poll: Poll, session: AuthSession?) async throws -> Poll {
        guard client.config.isConfigured else {
            return poll
        }

        let request = CreatePollRequest(poll: poll, userId: session?.userId)
        let response: PollMutationResponse = try await client.post(
            "/polls/create",
            accessToken: session?.accessToken,
            body: request
        )
        return response.poll.domain
    }

    func vote(pollId: UUID, optionId: UUID, session: AuthSession?) async throws -> VoteMutation {
        guard client.config.isConfigured else {
            throw TrendXAPIError.notConfigured
        }

        return try await client.post(
            "/polls/vote",
            accessToken: session?.accessToken,
            body: VoteRequest(pollId: pollId, optionId: optionId)
        )
    }

    private func cachedTopics() -> [Topic] {
        if let data = defaults.data(forKey: "trendx_topics_v1"),
           let topics = try? JSONDecoder().decode([Topic].self, from: data) {
            return topics
        }
        return Topic.samples
    }

    private func cachedPolls() -> [Poll] {
        if let data = defaults.data(forKey: "trendx_polls_v1"),
           let polls = try? JSONDecoder().decode([Poll].self, from: data),
           !polls.isEmpty {
            return polls
        }
        return Poll.samples
    }

    private func cache<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}

struct VoteMutation: Decodable {
    let poll: PollDTO
    let user: UserDTO
    let insight: String?
}

private struct BootstrapResponse: Decodable {
    let topics: [TopicDTO]
    let polls: [PollDTO]
}

private struct CreatePollRequest: Encodable {
    let poll: PollDTO
    let options: [PollOptionDTO]
    let userId: UUID?

    init(poll: Poll, userId: UUID?) {
        self.poll = PollDTO(domain: poll)
        self.options = poll.options.map(PollOptionDTO.init(domain:))
        self.userId = userId
    }
}

private struct PollMutationResponse: Decodable {
    let poll: PollDTO
}

private struct VoteRequest: Encodable {
    let pollId: UUID
    let optionId: UUID
}

struct UserDTO: Codable {
    let id: UUID
    let name: String
    let email: String?
    let avatarInitial: String?
    let points: Int
    let coins: Double
    let followedTopics: [UUID]?
    let completedPolls: [UUID]?
    let isPremium: Bool?

    var domain: TrendXUser {
        TrendXUser(
            id: id,
            name: name,
            email: email ?? "",
            avatarInitial: avatarInitial ?? String(name.prefix(1)),
            points: points,
            coins: coins,
            followedTopics: followedTopics ?? [],
            completedPolls: completedPolls ?? [],
            isPremium: isPremium ?? false
        )
    }
}

struct TopicDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String?
    let followersCount: Int?
    let postsCount: Int?

    var domain: Topic {
        Topic(
            id: id,
            name: name,
            icon: icon,
            color: color ?? "blue",
            followersCount: followersCount ?? 0,
            postsCount: postsCount ?? 0
        )
    }
}

struct PollDTO: Codable {
    let id: UUID
    let title: String
    let description: String?
    let imageUrl: String?
    let coverStyle: PollCoverStyle?
    let authorName: String?
    let authorAvatar: String?
    let authorIsVerified: Bool?
    let options: [PollOptionDTO]?
    let topicId: UUID?
    let topicName: String?
    let type: PollType
    let status: PollStatus
    let totalVotes: Int?
    let rewardPoints: Int?
    let durationDays: Int?
    let createdAt: Date?
    let expiresAt: Date?
    let userVotedOptionId: UUID?
    let isBookmarked: Bool?
    let sharesCount: Int?
    let repostsCount: Int?
    let aiInsight: String?

    init(domain: Poll) {
        self.id = domain.id
        self.title = domain.title
        self.description = domain.description
        self.imageUrl = domain.imageURL
        self.coverStyle = domain.coverStyle
        self.authorName = domain.authorName
        self.authorAvatar = domain.authorAvatar
        self.authorIsVerified = domain.authorIsVerified
        self.options = domain.options.map(PollOptionDTO.init(domain:))
        self.topicId = domain.topicId
        self.topicName = domain.topicName
        self.type = domain.type
        self.status = domain.status
        self.totalVotes = domain.totalVotes
        self.rewardPoints = domain.rewardPoints
        self.durationDays = domain.durationDays
        self.createdAt = domain.createdAt
        self.expiresAt = domain.expiresAt
        self.userVotedOptionId = domain.userVotedOptionId
        self.isBookmarked = domain.isBookmarked
        self.sharesCount = domain.sharesCount
        self.repostsCount = domain.repostsCount
        self.aiInsight = domain.aiInsight
    }

    var domain: Poll {
        Poll(
            id: id,
            title: title,
            description: description,
            imageURL: imageUrl,
            coverStyle: coverStyle,
            authorName: authorName ?? "TrendX User",
            authorAvatar: authorAvatar ?? "T",
            authorIsVerified: authorIsVerified ?? false,
            options: options?.map(\.domain) ?? [],
            topicId: topicId,
            topicName: topicName,
            type: type,
            status: status,
            totalVotes: totalVotes ?? 0,
            rewardPoints: rewardPoints ?? 50,
            durationDays: durationDays ?? 7,
            createdAt: createdAt ?? Date(),
            expiresAt: expiresAt ?? Date().addingTimeInterval(7 * 24 * 60 * 60),
            userVotedOptionId: userVotedOptionId,
            isBookmarked: isBookmarked ?? false,
            sharesCount: sharesCount ?? 0,
            repostsCount: repostsCount ?? 0,
            aiInsight: aiInsight
        )
    }
}

struct PollOptionDTO: Codable {
    let id: UUID
    let text: String
    let votesCount: Int?
    let percentage: Double?

    init(domain: PollOption) {
        self.id = domain.id
        self.text = domain.text
        self.votesCount = domain.votesCount
        self.percentage = domain.percentage
    }

    var domain: PollOption {
        PollOption(id: id, text: text, votesCount: votesCount ?? 0, percentage: percentage ?? 0)
    }
}
