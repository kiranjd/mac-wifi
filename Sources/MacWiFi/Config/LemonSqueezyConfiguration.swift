import Foundation

enum LemonSqueezyConfiguration {
    static let storeId = 225921
    static let productId = 883028
    static let checkoutURL = URL(string: "https://kiranjd8.lemonsqueezy.com/checkout/buy/dc36a9dc-bba2-46af-9426-f1c41120c477")!

    static let apiBaseURL: URL = {
        let fallback = "https://api.lemonsqueezy.com/v1/licenses"
        let raw = ProcessInfo.processInfo.environment["MACWIFI_LICENSE_API_BASE_URL"] ?? fallback
        return URL(string: raw) ?? URL(string: fallback)!
    }()

    static let relayBaseURL: URL = {
        let fallback = "https://macwifi.live/api/license"
        let raw = ProcessInfo.processInfo.environment["MACWIFI_LICENSE_RELAY_BASE_URL"] ?? fallback
        return URL(string: raw) ?? URL(string: fallback)!
    }()

    static let isRelayFallbackEnabled: Bool = {
        let raw = ProcessInfo.processInfo.environment["MACWIFI_LICENSE_RELAY_FALLBACK_ENABLED"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch raw {
        case "0", "false", "no":
            return false
        default:
            return true
        }
    }()
}
