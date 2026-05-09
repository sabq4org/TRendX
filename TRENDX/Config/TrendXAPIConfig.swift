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

    static var current: TrendXAPIConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment
        let rawURL = (info["TRENDX_API_BASE_URL"] as? String)
            ?? env["TRENDX_API_BASE_URL"]
            ?? ""

        return TrendXAPIConfig(
            baseURL: URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines))
        )
    }
}

