//
//  TrendXAPIConfig.swift
//  TRENDX
//

import Foundation

struct TrendXAPIConfig: Equatable {
    let baseURL: URL?

    var isConfigured: Bool {
        baseURL != nil
    }

    /// Default backend (Railway production). Override at runtime by adding
    /// `TRENDX_API_BASE_URL` to Info.plist or exporting it as a process env
    /// var (useful for staging or local dev against the railway-api repo).
    private static let defaultBaseURL = "https://trendx-production.up.railway.app"

    static var current: TrendXAPIConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment
        let rawURL = (info["TRENDX_API_BASE_URL"] as? String)
            ?? env["TRENDX_API_BASE_URL"]
            ?? defaultBaseURL

        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        // Fall back to the default if the override was supplied but blank.
        let candidate = trimmed.isEmpty ? defaultBaseURL : trimmed

        return TrendXAPIConfig(baseURL: URL(string: candidate))
    }
}
