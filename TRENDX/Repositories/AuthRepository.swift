//
//  AuthRepository.swift
//  TRENDX
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String?
    var userId: UUID
    var email: String
}

final class AuthRepository {
    private let client: TrendXAPIClient
    private let defaults: UserDefaults
    private let sessionKey = "trendx_auth_session_v1"

    init(client: TrendXAPIClient, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
    }

    var isRemoteEnabled: Bool {
        client.config.isConfigured
    }

    func restoreSession() -> AuthSession? {
        guard let data = defaults.data(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        if !client.config.isConfigured {
            let session = localSession(email: email)
            save(session)
            return session
        }

        let response: AuthResponse = try await client.post(
            "/auth/signin",
            body: AuthCredentials(email: email, password: password)
        )
        let session = response.session
        save(session)
        return session
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        gender: UserGender = .unspecified,
        birthYear: Int? = nil,
        city: String? = nil,
        region: String? = nil
    ) async throws -> AuthSession {
        if !client.config.isConfigured {
            let session = localSession(email: email)
            save(session)
            return session
        }

        let payload = SignUpPayload(
            name: name,
            email: email,
            password: password,
            gender: gender.rawValue,
            birthYear: birthYear,
            city: city,
            region: region,
            deviceType: "ios",
            osVersion: Self.systemVersionString
        )
        let response: AuthResponse = try await client.post(
            "/auth/signup",
            body: payload
        )

        let session = response.session
        save(session)
        return session
    }

    func signOut() {
        defaults.removeObject(forKey: sessionKey)
    }

    func fetchProfile(session: AuthSession) async throws -> TrendXUser {
        let profile: UserDTO = try await client.get("/profile", accessToken: session.accessToken)
        return profile.domain
    }

    func upsertProfile(name: String, email: String, session: AuthSession) async throws {
        let payload = ProfilePayload(
            id: session.userId,
            name: name,
            email: email,
            avatarInitial: String(name.prefix(1)),
            points: 100,
            coins: 16.67,
            isPremium: false
        )
        let _: UserDTO = try await client.post("/profile", accessToken: session.accessToken, body: payload)
    }

    /// Update arbitrary profile fields. Only non-nil keys are sent to the
    /// backend, so callers can selectively patch (name + city) without
    /// nuking the rest. Returns the freshly-decoded domain user.
    func updateProfile(
        name: String? = nil,
        email: String? = nil,
        handle: String? = nil,
        bio: String? = nil,
        avatarInitial: String? = nil,
        avatarUrl: String? = nil,
        bannerUrl: String? = nil,
        accountType: AccountType? = nil,
        gender: String? = nil,
        birthYear: Int? = nil,
        city: String? = nil,
        region: String? = nil,
        country: String? = nil,
        session: AuthSession
    ) async throws -> TrendXUser {
        let payload = ProfileUpdatePayload(
            name: name,
            email: email,
            handle: handle,
            bio: bio,
            avatarInitial: avatarInitial,
            avatarUrl: avatarUrl,
            bannerUrl: bannerUrl,
            accountType: accountType?.rawValue,
            gender: gender,
            birthYear: birthYear,
            city: city,
            region: region,
            country: country
        )
        let dto: UserDTO = try await client.post("/profile", accessToken: session.accessToken, body: payload)
        return dto.domain
    }

    /// Cheap server-side availability check for an `@handle` candidate.
    /// Returns nil when the handle is OK, or a localized error message
    /// when it's invalid / reserved / taken.
    func checkHandleAvailability(_ candidate: String, session: AuthSession) async throws -> String? {
        struct Response: Decodable {
            let ok: Bool
            let reason: String?
            let message: String?
        }
        let escaped = candidate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? candidate
        let result: Response = try await client.get(
            "/handles/check?handle=\(escaped)",
            accessToken: session.accessToken
        )
        return result.ok ? nil : (result.message ?? "هذا المعرّف غير متاح.")
    }

    private func save(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: sessionKey)
        }
    }

    private func localSession(email: String) -> AuthSession {
        AuthSession(
            accessToken: "local-beta-token",
            refreshToken: nil,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            email: email
        )
    }

    private static var systemVersionString: String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        #endif
    }
}

private struct ProfileUpdatePayload: Encodable {
    let name: String?
    let email: String?
    let handle: String?
    let bio: String?
    let avatarInitial: String?
    let avatarUrl: String?
    let bannerUrl: String?
    let accountType: String?
    let gender: String?
    let birthYear: Int?
    let city: String?
    let region: String?
    let country: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let name { try container.encode(name, forKey: .name) }
        if let email { try container.encode(email, forKey: .email) }
        if let handle { try container.encode(handle, forKey: .handle) }
        if let bio { try container.encode(bio, forKey: .bio) }
        if let avatarInitial { try container.encode(avatarInitial, forKey: .avatarInitial) }
        if let avatarUrl { try container.encode(avatarUrl, forKey: .avatarUrl) }
        if let bannerUrl { try container.encode(bannerUrl, forKey: .bannerUrl) }
        if let accountType { try container.encode(accountType, forKey: .accountType) }
        if let gender { try container.encode(gender, forKey: .gender) }
        if let birthYear { try container.encode(birthYear, forKey: .birthYear) }
        if let city { try container.encode(city, forKey: .city) }
        if let region { try container.encode(region, forKey: .region) }
        if let country { try container.encode(country, forKey: .country) }
    }

    enum CodingKeys: String, CodingKey {
        case name, email, handle, bio,
             avatarInitial, avatarUrl, bannerUrl,
             accountType, gender, birthYear, city, region, country
    }
}

private struct AuthCredentials: Encodable {
    let email: String
    let password: String
}

private struct SignUpPayload: Encodable {
    let name: String
    let email: String
    let password: String
    let gender: String
    let birthYear: Int?
    let city: String?
    let region: String?
    let deviceType: String
    let osVersion: String?
}

private struct AuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let user: AuthUser

    var session: AuthSession {
        AuthSession(
            accessToken: accessToken ?? "",
            refreshToken: refreshToken,
            userId: user.id,
            email: user.email ?? ""
        )
    }
}

private struct AuthUser: Decodable {
    let id: UUID
    let email: String?
}

private struct ProfilePayload: Codable {
    let id: UUID
    let name: String
    let email: String
    let avatarInitial: String
    let points: Int
    let coins: Double
    let isPremium: Bool
}
