//
//  TrendXAPIClient.swift
//  TRENDX
//

import Foundation

enum TrendXAPIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "TRENDX API is not configured for this build."
        case .invalidResponse:
            return "The API returned an invalid response."
        case let .server(status, message):
            return "TRENDX API request failed (\(status)): \(message)"
        }
    }
}

final class TrendXAPIClient {
    let config: TrendXAPIConfig

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(config: TrendXAPIConfig = .current, session: URLSession = .shared) {
        self.config = config
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.trendxFractional.date(from: value)
                ?? ISO8601DateFormatter.trendxInternet.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<T: Decodable>(_ path: String, accessToken: String? = nil) async throws -> T {
        try await request(path, method: "GET", accessToken: accessToken, bodyData: nil)
    }

    func post<T: Decodable, Body: Encodable>(
        _ path: String,
        accessToken: String? = nil,
        body: Body
    ) async throws -> T {
        let data = try encoder.encode(body)
        return try await request(path, method: "POST", accessToken: accessToken, bodyData: data)
    }

    private func request<T: Decodable>(
        _ path: String,
        method: String,
        accessToken: String?,
        bodyData: Data?
    ) async throws -> T {
        guard let baseURL = config.baseURL, config.isConfigured else {
            throw TrendXAPIError.notConfigured
        }

        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw TrendXAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TrendXAPIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TrendXAPIError.server(status: http.statusCode, message: message)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try decoder.decode(T.self, from: data)
    }
}

struct EmptyResponse: Decodable {}

private extension ISO8601DateFormatter {
    static let trendxInternet: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let trendxFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
