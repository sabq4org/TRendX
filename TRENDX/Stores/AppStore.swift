//
//  AppStore.swift
//  TRENDX
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var currentUser: TrendXUser
    @Published var topics: [Topic]
    @Published var polls: [Poll]
    @Published var gifts: [Gift]
    @Published var redemptions: [Redemption]
    @Published var selectedTab: TabItem = .home
    @Published var showCreatePoll: Bool = false
    
    private let userKey = "trendx_user_v1"
    private let topicsKey = "trendx_topics_v1"
    private let pollsKey = "trendx_polls_v1"
    private let redemptionsKey = "trendx_redemptions_v1"
    
    init() {
        // Load user
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(TrendXUser.self, from: data) {
            self.currentUser = user
        } else {
            self.currentUser = TrendXUser(name: "علي", avatarInitial: "ع", points: 100, coins: 16.67)
        }
        
        // Load topics
        if let data = UserDefaults.standard.data(forKey: topicsKey),
           let topics = try? JSONDecoder().decode([Topic].self, from: data) {
            self.topics = topics
        } else {
            self.topics = Topic.samples
        }
        
        // Load polls — fallback to samples if empty or corrupt
        if let data = UserDefaults.standard.data(forKey: pollsKey),
           let polls = try? JSONDecoder().decode([Poll].self, from: data),
           !polls.isEmpty {
            self.polls = polls
        } else {
            self.polls = Poll.samples
            // persist samples so edits are saved
            if let encoded = try? JSONEncoder().encode(Poll.samples) {
                UserDefaults.standard.set(encoded, forKey: pollsKey)
            }
        }
        
        self.gifts = Gift.samples

        if let data = UserDefaults.standard.data(forKey: redemptionsKey),
           let redemptions = try? JSONDecoder().decode([Redemption].self, from: data) {
            self.redemptions = redemptions
        } else {
            self.redemptions = []
        }
    }
    
    // MARK: - User Actions
    
    func addPoints(_ amount: Int) {
        currentUser.points += amount
        currentUser.coins = Double(currentUser.points) / 6.0
        persistUser()
    }
    
    func deductPoints(_ amount: Int) -> Bool {
        guard currentUser.points >= amount else { return false }
        currentUser.points -= amount
        currentUser.coins = Double(currentUser.points) / 6.0
        persistUser()
        return true
    }
    
    // MARK: - Topic Actions
    
    func toggleFollowTopic(_ topicId: UUID) {
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            topics[index].isFollowing.toggle()
            if topics[index].isFollowing {
                topics[index].followersCount += 1
                currentUser.followedTopics.append(topicId)
            } else {
                topics[index].followersCount -= 1
                currentUser.followedTopics.removeAll { $0 == topicId }
            }
            persistTopics()
            persistUser()
        }
    }
    
    var followedTopics: [Topic] {
        topics.filter { $0.isFollowing }
    }
    
    // MARK: - Poll Actions
    
    func voteOnPoll(_ pollId: UUID, optionId: UUID) {
        guard let pollIndex = polls.firstIndex(where: { $0.id == pollId }),
              !polls[pollIndex].hasUserVoted else { return }
        
        polls[pollIndex].userVotedOptionId = optionId
        polls[pollIndex].totalVotes += 1
        
        if let optionIndex = polls[pollIndex].options.firstIndex(where: { $0.id == optionId }) {
            polls[pollIndex].options[optionIndex].votesCount += 1
        }
        
        // Recalculate percentages
        let total = polls[pollIndex].totalVotes
        for i in polls[pollIndex].options.indices {
            polls[pollIndex].options[i].percentage = Double(polls[pollIndex].options[i].votesCount) / Double(total) * 100
        }

        polls[pollIndex].aiInsight = TrendXAI.postVoteInsight(for: polls[pollIndex])
        
        addPoints(polls[pollIndex].rewardPoints)
        if !currentUser.completedPolls.contains(pollId) {
            currentUser.completedPolls.append(pollId)
        }
        persistPolls()
    }
    
    func toggleBookmark(_ pollId: UUID) {
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].isBookmarked.toggle()
            persistPolls()
        }
    }

    func sharePoll(_ pollId: UUID) {
        if let index = polls.firstIndex(where: { $0.id == pollId }) {
            polls[index].sharesCount += 1
            persistPolls()
        }
    }
    
    func createPoll(_ poll: Poll) {
        var newPoll = poll
        newPoll.authorName = currentUser.name
        newPoll.authorAvatar = currentUser.avatarInitial
        polls.insert(newPoll, at: 0)
        persistPolls()
    }
    
    var activePolls: [Poll] {
        polls.filter { $0.status == .active && !$0.isExpired }
    }
    
    var completedPolls: [Poll] {
        polls.filter { $0.status == .completed || $0.isExpired || $0.hasUserVoted }
    }
    
    var latestPolls: [Poll] {
        Array(activePolls.prefix(5))
    }

    var votedPolls: [Poll] {
        polls.filter { $0.hasUserVoted }
    }

    var endedPolls: [Poll] {
        polls.filter { $0.status == .completed || $0.isExpired }
    }

    var smartFeedPolls: [Poll] {
        activePolls.sorted { lhs, rhs in
            score(for: lhs) > score(for: rhs)
        }
    }

    func poll(withId id: UUID) -> Poll? {
        polls.first { $0.id == id }
    }

    func redeemGift(_ gift: Gift) -> Redemption? {
        guard gift.isAvailable, deductPoints(gift.pointsRequired) else { return nil }
        let redemption = Redemption(
            giftId: gift.id,
            giftName: gift.name,
            brandName: gift.brandName,
            pointsSpent: gift.pointsRequired,
            valueInRiyal: gift.valueInRiyal
        )
        redemptions.insert(redemption, at: 0)
        persistRedemptions()
        return redemption
    }

    func giftRecommendationReason(for gift: Gift) -> String {
        TrendXAI.giftReason(gift: gift, userPoints: currentUser.points)
    }

    private func score(for poll: Poll) -> Int {
        var value = 0
        if let topicId = poll.topicId, currentUser.followedTopics.contains(topicId) { value += 70 }
        if let topicName = poll.topicName, topics.first(where: { $0.name == topicName && $0.isFollowing }) != nil { value += 60 }
        if !poll.hasUserVoted { value += 45 }
        if poll.isEndingSoon { value += 30 }
        value += min(poll.totalVotes, 120) / 4
        value += poll.aiInsight == nil ? 0 : 12
        return value
    }
    
    // MARK: - Persistence
    
    private func persistUser() {
        if let data = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }
    
    private func persistTopics() {
        if let data = try? JSONEncoder().encode(topics) {
            UserDefaults.standard.set(data, forKey: topicsKey)
        }
    }
    
    private func persistPolls() {
        if let data = try? JSONEncoder().encode(polls) {
            UserDefaults.standard.set(data, forKey: pollsKey)
        }
    }

    private func persistRedemptions() {
        if let data = try? JSONEncoder().encode(redemptions) {
            UserDefaults.standard.set(data, forKey: redemptionsKey)
        }
    }
}

// MARK: - Tab Items

enum TabItem: String, CaseIterable {
    case home = "الرئيسية"
    case polls = "الاستطلاعات"
    case gifts = "الهدايا"
    case account = "حسابي"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .polls: return "doc.text.fill"
        case .gifts: return "gift.fill"
        case .account: return "person.fill"
        }
    }
    
    var selectedIcon: String {
        icon
    }
}
