import Foundation

final class AppAnalytics {
    static let shared = AppAnalytics()

    private enum Keys {
        static let installId = "analytics.install_id"
        static let installPingSent = "analytics.install_ping_sent"
    }

    private let defaults = UserDefaults.standard
    private let session = URLSession.shared
    private let queue = DispatchQueue(label: "com.kiranjd.macwifi.analytics", qos: .utility)

    private init() {}

    var installId: String {
        AppInstallIdentity.installID
    }

    func trackInstallIfNeeded() {
        queue.async {
            guard !self.defaults.bool(forKey: Keys.installPingSent) else { return }
            guard !AnalyticsConfiguration.ga4MeasurementId.isEmpty,
                  !AnalyticsConfiguration.ga4MeasurementAPISecret.isEmpty else { return }

            let installId = AppInstallIdentity.installID
            let payload = self.payload(
                installId: installId,
                eventName: "app_install_anonymous",
                parameters: self.baseParameters()
            )

            Task.detached(priority: .utility) {
                guard let request = self.makeRequest(payload: payload) else { return }
                do {
                    let (_, response) = try await self.session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        return
                    }
                    self.defaults.set(true, forKey: Keys.installPingSent)
                } catch {
                    return
                }
            }
        }
    }

    func trackEvent(_ name: String, parameters: [String: Any] = [:]) {
        queue.async {
            guard !AnalyticsConfiguration.ga4MeasurementId.isEmpty,
                  !AnalyticsConfiguration.ga4MeasurementAPISecret.isEmpty else { return }

            let installId = AppInstallIdentity.installID
            var merged = self.baseParameters()
            for (key, value) in parameters {
                merged[key] = value
            }
            let payload = self.payload(
                installId: installId,
                eventName: name,
                parameters: merged
            )

            Task.detached(priority: .utility) {
                guard let request = self.makeRequest(payload: payload) else { return }
                _ = try? await self.session.data(for: request)
            }
        }
    }
    private func makeRequest(payload: [String: Any]) -> URLRequest? {
        guard var components = URLComponents(string: "https://www.google-analytics.com/mp/collect") else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "measurement_id", value: AnalyticsConfiguration.ga4MeasurementId),
            URLQueryItem(name: "api_secret", value: AnalyticsConfiguration.ga4MeasurementAPISecret),
        ]
        guard let url = components.url,
              let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func payload(installId: String, eventName: String, parameters: [String: Any]) -> [String: Any] {
        [
            "client_id": installId,
            "non_personalized_ads": true,
            "user_properties": [
                "install_id": ["value": installId],
                "platform": ["value": "macOS"],
            ],
            "events": [
                [
                    "name": eventName,
                    "params": parameters,
                ],
            ],
        ]
    }

    private func baseParameters() -> [String: Any] {
        var params: [String: Any] = [
            "platform": "macOS",
            "engagement_time_msec": 1,
            "site_domain": "macwifi.live",
        ]
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            params["app_version"] = version
        }
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            params["build_number"] = build
        }
        params["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        return params
    }
}
