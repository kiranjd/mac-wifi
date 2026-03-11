import Foundation
import OSLog

enum AppLogCategory: String {
    case app
    case analytics
    case license
    case quality
    case ui
    case wifi
}

enum AppLogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

final class AppLogger {
    static let shared = AppLogger()

    private let diagnostics = AppDiagnostics.shared
    private let subsystem = Bundle.main.bundleIdentifier ?? "live.macwifi.app"
    private let appSink: FileLogSink?
    private let analyticsSink: FileLogSink?

    private init(fileManager: FileManager = .default) {
        if diagnostics.isDeveloperMachine {
            appSink = FileLogSink(directoryURL: diagnostics.logsDirectoryURL, fileURL: diagnostics.appLogURL, fileManager: fileManager)
            if diagnostics.isAnalyticsFileLoggingEnabled {
                analyticsSink = FileLogSink(
                    directoryURL: diagnostics.logsDirectoryURL,
                    fileURL: diagnostics.analyticsLogURL,
                    fileManager: fileManager
                )
            } else {
                analyticsSink = nil
            }
        } else {
            appSink = nil
            analyticsSink = nil
        }
    }

    func debug(
        _ message: String,
        category: AppLogCategory = .app,
        metadata: [String: String] = [:]
    ) {
        guard diagnostics.isDeveloperMachine else { return }
        log(.debug, message, category: category, metadata: metadata)
    }

    func info(
        _ message: String,
        category: AppLogCategory = .app,
        metadata: [String: String] = [:]
    ) {
        log(.info, message, category: category, metadata: metadata)
    }

    func warning(
        _ message: String,
        category: AppLogCategory = .app,
        metadata: [String: String] = [:]
    ) {
        log(.warning, message, category: category, metadata: metadata)
    }

    func error(
        _ message: String,
        category: AppLogCategory = .app,
        metadata: [String: String] = [:]
    ) {
        log(.error, message, category: category, metadata: metadata)
    }

    func analytics(
        _ message: String,
        metadata: [String: String] = [:]
    ) {
        guard diagnostics.isDeveloperMachine, diagnostics.isAnalyticsFileLoggingEnabled else { return }
        log(.info, message, category: .analytics, metadata: metadata)
    }

    private func log(
        _ level: AppLogLevel,
        _ message: String,
        category: AppLogCategory,
        metadata: [String: String]
    ) {
        let renderedMessage = Self.renderMessage(message, metadata: metadata)
        writeToUnifiedLog(level: level, message: renderedMessage, category: category)

        guard diagnostics.isDeveloperMachine else { return }

        let line = Self.renderFileLine(level: level, category: category, message: renderedMessage)
        appSink?.append(line)
        if category == .analytics, diagnostics.isAnalyticsFileLoggingEnabled {
            analyticsSink?.append(line)
        }
    }

    private func writeToUnifiedLog(
        level: AppLogLevel,
        message: String,
        category: AppLogCategory
    ) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }

    private static func renderMessage(
        _ message: String,
        metadata: [String: String]
    ) -> String {
        guard !metadata.isEmpty else { return message }
        let renderedMetadata = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        return "\(message) | \(renderedMetadata)"
    }

    private static func renderFileLine(
        level: AppLogLevel,
        category: AppLogCategory,
        message: String
    ) -> String {
        "\(ISO8601DateFormatter.logTimestamp.string(from: Date())) [\(level.rawValue)] [\(category.rawValue)] \(message)\n"
    }
}

private final class FileLogSink {
    private let directoryURL: URL
    private let fileURL: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "live.macwifi.file-log-sink", qos: .utility)

    init(directoryURL: URL, fileURL: URL, fileManager: FileManager) {
        self.directoryURL = directoryURL
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func append(_ line: String) {
        queue.async {
            guard let data = line.data(using: .utf8) else { return }

            do {
                try self.fileManager.createDirectory(
                    at: self.directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                if !self.fileManager.fileExists(atPath: self.fileURL.path) {
                    self.fileManager.createFile(atPath: self.fileURL.path, contents: nil)
                }

                let handle = try FileHandle(forWritingTo: self.fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                let fallback = Logger(subsystem: Bundle.main.bundleIdentifier ?? "live.macwifi.app", category: "logging")
                fallback.error("Failed to append log file \(self.fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

private extension ISO8601DateFormatter {
    static let logTimestamp: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
