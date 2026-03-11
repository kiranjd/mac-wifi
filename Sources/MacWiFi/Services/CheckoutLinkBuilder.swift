import Foundation

enum CheckoutLinkBuilder {
    static func purchaseURL(source: String = "macwifi_app") -> URL {
        guard var components = URLComponents(url: LemonSqueezyConfiguration.checkoutURL, resolvingAgainstBaseURL: false) else {
            return LemonSqueezyConfiguration.checkoutURL
        }

        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "utm_source", value: source))
        items.append(URLQueryItem(name: "utm_medium", value: "app"))
        items.append(URLQueryItem(name: "utm_campaign", value: "in_app_buy"))
        items.append(URLQueryItem(name: "checkout[custom][install_id]", value: AppAnalytics.shared.installId))
        items.append(URLQueryItem(name: "checkout[custom][device_name]", value: Host.current().localizedName ?? "Mac"))
        components.queryItems = items

        return components.url ?? LemonSqueezyConfiguration.checkoutURL
    }
}
