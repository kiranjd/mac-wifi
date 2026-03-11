import Foundation

struct AppDiagnostics {
    static let shared = AppDiagnostics()

    let checkedDeveloperMarkerURLs: [URL]
    let developerMarkerURL: URL?
    let isDeveloperMachine: Bool
    let logsDirectoryURL: URL
    let appLogURL: URL
    let analyticsLogURL: URL
    let isAnalyticsFileLoggingEnabled: Bool

    private let settings: [String: String]

    private init(
        fileManager: FileManager = .default,
        bundle: Bundle = .main
    ) {
        let logsDirectoryURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("MacWiFi", isDirectory: true)
        let applicationSupportURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("MacWiFi", isDirectory: true)

        let candidateURLs = [
            bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("dev.txt", isDirectory: false),
            applicationSupportURL.appendingPathComponent("dev.txt", isDirectory: false),
        ]

        let markerURL = candidateURLs.first(where: { fileManager.fileExists(atPath: $0.path) })
        let rawSettings = markerURL.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        let parsedSettings = Self.parseSettings(rawSettings)

        self.checkedDeveloperMarkerURLs = candidateURLs
        self.developerMarkerURL = markerURL
        self.isDeveloperMachine = markerURL != nil
        self.logsDirectoryURL = logsDirectoryURL
        self.appLogURL = logsDirectoryURL.appendingPathComponent("app.log", isDirectory: false)
        self.analyticsLogURL = logsDirectoryURL.appendingPathComponent("analytics.log", isDirectory: false)
        self.settings = parsedSettings
        self.isAnalyticsFileLoggingEnabled = markerURL != nil
            && Self.boolSetting(
                from: parsedSettings,
                keys: [
                    "analytics",
                    "ga4",
                    "ga4_logs",
                    "analytics_logs",
                    "analytics_file_logging",
                ],
                defaultValue: true
            )
    }

    var developerMarkerPath: String? {
        developerMarkerURL?.path
    }

    var checkedDeveloperMarkerPaths: [String] {
        checkedDeveloperMarkerURLs.map(\.path)
    }

    private static func parseSettings(_ rawSettings: String) -> [String: String] {
        var parsed: [String: String] = [:]

        for rawLine in rawSettings.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), let separator = trimmed.firstIndex(of: "=") else {
                continue
            }

            let key = String(trimmed[..<separator])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let value = String(trimmed[trimmed.index(after: separator)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            guard !key.isEmpty else { continue }
            parsed[key] = value
        }

        return parsed
    }

    private static func boolSetting(
        from settings: [String: String],
        keys: [String],
        defaultValue: Bool
    ) -> Bool {
        for key in keys {
            guard let value = settings[key] else { continue }
            switch value {
            case "1", "true", "yes", "on":
                return true
            case "0", "false", "no", "off":
                return false
            default:
                continue
            }
        }

        return defaultValue
    }
}
