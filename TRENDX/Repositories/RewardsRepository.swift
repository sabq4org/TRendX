//
//  RewardsRepository.swift
//  TRENDX
//

import Foundation

final class RewardsRepository {
    private let client: TrendXAPIClient
    private let defaults: UserDefaults

    init(client: TrendXAPIClient, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
    }

    func loadGifts(session: AuthSession?) async -> [Gift] {
        guard client.config.isConfigured else {
            return Gift.samples
        }

        do {
            let gifts: [GiftDTO] = try await client.get("/gifts", accessToken: session?.accessToken)
            return gifts.map(\.domain)
        } catch {
            return Gift.samples
        }
    }

    func loadRedemptions(session: AuthSession?) async -> [Redemption] {
        guard client.config.isConfigured else {
            return cachedRedemptions()
        }

        do {
            let redemptions: [RedemptionDTO] = try await client.get("/redemptions", accessToken: session?.accessToken)
            return redemptions.map(\.domain)
        } catch {
            return cachedRedemptions()
        }
    }

    func redeem(_ gift: Gift, session: AuthSession?) async throws -> RedemptionMutation {
        guard client.config.isConfigured else {
            throw TrendXAPIError.notConfigured
        }

        return try await client.post(
            "/gifts/redeem",
            accessToken: session?.accessToken,
            body: RedeemGiftRequest(giftId: gift.id)
        )
    }

    private func cachedRedemptions() -> [Redemption] {
        guard let data = defaults.data(forKey: "trendx_redemptions_v1"),
              let redemptions = try? JSONDecoder().decode([Redemption].self, from: data) else {
            return []
        }
        return redemptions
    }
}

struct RedemptionMutation: Decodable {
    let redemption: RedemptionDTO
    let user: UserDTO
}

private struct RedeemGiftRequest: Encodable {
    let giftId: UUID
}

struct GiftDTO: Codable {
    let id: UUID
    let name: String
    let brandName: String
    let brandLogo: String?
    let category: String
    let pointsRequired: Int
    let valueInRiyal: Double
    let imageUrl: String?
    let isRedeemAtStore: Bool?
    let isAvailable: Bool?

    var domain: Gift {
        Gift(
            id: id,
            name: name,
            brandName: brandName,
            brandLogo: brandLogo ?? "",
            category: category,
            pointsRequired: pointsRequired,
            valueInRiyal: valueInRiyal,
            imageURL: imageUrl,
            isRedeemAtStore: isRedeemAtStore ?? true,
            isAvailable: isAvailable ?? true
        )
    }
}

struct RedemptionDTO: Codable {
    let id: UUID
    let giftId: UUID
    let giftName: String
    let brandName: String
    let pointsSpent: Int
    let valueInRiyal: Double
    let redeemedAt: Date?
    let code: String

    var domain: Redemption {
        Redemption(
            id: id,
            giftId: giftId,
            giftName: giftName,
            brandName: brandName,
            pointsSpent: pointsSpent,
            valueInRiyal: valueInRiyal,
            redeemedAt: redeemedAt ?? Date(),
            code: code
        )
    }
}
