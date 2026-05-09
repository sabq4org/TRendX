//
//  AuthRepository.swift
//  TRENDX
//

import Foundation

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

    func signUp(name: String, email: String, password: String) async throws -> AuthSession {
        if !client.config.isConfigured {
            let session = localSession(email: email)
            save(session)
            return session
        }

        let response: AuthResponse = try await client.post(
            "/auth/signup",
            body: SignUpPayload(name: name, email: email, password: password)
        )

        let session = response.session
        save(session)
        try? await upsertProfile(name: name, email: email, session: session)
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
}

private struct AuthCredentials: Encodable {
    let email: String
    let password: String
}

private struct SignUpPayload: Encodable {
    let name: String
    let email: String
    let password: String
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
