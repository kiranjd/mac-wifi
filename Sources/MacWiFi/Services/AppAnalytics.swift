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
            guard !self.defaults.bool(forKey: Keys.installPingSent) else {
                AppLogger.shared.debug("Skipping install analytics ping", category: .analytics, metadata: ["reason": "already_sent"])
                return
            }
            guard self.hasMeasurementConfiguration else {
                AppLogger.shared.debug("Skipping install analytics ping", category: .analytics, metadata: ["reason": "missing_configuration"])
                return
            }

            let installId = AppInstallIdentity.installID
            let payload = self.payload(
                installId: installId,
                eventName: "app_install_anonymous",
                parameters: self.baseParameters()
            )
            AppLogger.shared.analytics(
                "Prepared analytics event",
                metadata: [
                    "event": "app_install_anonymous",
                    "payload": self.renderPayload(payload),
                ]
            )

            Task.detached(priority: .utility) {
                guard let request = self.makeRequest(payload: payload) else { return }
                do {
                    let (_, response) = try await self.session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        AppLogger.shared.warning(
                            "Analytics event failed",
                            category: .analytics,
                            metadata: [
                                "event": "app_install_anonymous",
                                "status": String(statusCode),
                            ]
                        )
                        return
                    }
                    AppLogger.shared.analytics(
                        "Analytics event delivered",
                        metadata: [
                            "event": "app_install_anonymous",
                            "status": String(httpResponse.statusCode),
                        ]
                    )
                    self.defaults.set(true, forKey: Keys.installPingSent)
                } catch {
                    AppLogger.shared.warning(
                        "Analytics event failed",
                        category: .analytics,
                        metadata: [
                            "event": "app_install_anonymous",
                            "error": error.localizedDescription,
                        ]
                    )
                    return
                }
            }
        }
    }

    func trackEvent(_ name: String, parameters: [String: Any] = [:]) {
        queue.async {
            guard self.hasMeasurementConfiguration else {
                AppLogger.shared.debug("Skipping analytics event", category: .analytics, metadata: ["event": name, "reason": "missing_configuration"])
                return
            }

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
            AppLogger.shared.analytics(
                "Prepared analytics event",
                metadata: [
                    "event": name,
                    "payload": self.renderPayload(payload),
                ]
            )

            Task.detached(priority: .utility) {
                guard let request = self.makeRequest(payload: payload) else { return }
                do {
                    let (_, response) = try await self.session.data(for: request)
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    if (200...299).contains(statusCode) {
                        AppLogger.shared.analytics(
                            "Analytics event delivered",
                            metadata: [
                                "event": name,
                                "status": String(statusCode),
                            ]
                        )
                    } else {
                        AppLogger.shared.warning(
                            "Analytics event failed",
                            category: .analytics,
                            metadata: [
                                "event": name,
                                "status": String(statusCode),
                            ]
                        )
                    }
                } catch {
                    AppLogger.shared.warning(
                        "Analytics event failed",
                        category: .analytics,
                        metadata: [
                            "event": name,
                            "error": error.localizedDescription,
                        ]
                    )
                }
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

    private var hasMeasurementConfiguration: Bool {
        !AnalyticsConfiguration.ga4MeasurementId.isEmpty
            && !AnalyticsConfiguration.ga4MeasurementAPISecret.isEmpty
    }

    private func renderPayload(_ payload: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "unserializable"
        }
        return json
    }
}
