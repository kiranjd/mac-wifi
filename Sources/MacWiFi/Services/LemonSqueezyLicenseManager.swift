import AppKit
import Foundation
import Security

private let defaultLicenseKeychainService = "live.macwifi.license"
private let legacyDebugLicenseKeychainService = "live.macwifi.license.debug"

@MainActor
final class LemonSqueezyLicenseManager: ObservableObject {
    static let shared = LemonSqueezyLicenseManager()

    private enum PersistenceBackend {
        case developerFile(URL)
        case keychain
    }

    struct LicenseState: Codable, Equatable {
        let licenseKey: String
        let instanceId: String
        let status: String
        let expiresAt: Date?
        let storeId: Int
        let productId: Int
        let lastValidatedAt: Date?

        var isLicensed: Bool {
            guard status == "active" else { return false }
            guard let expiresAt else { return true }
            return expiresAt > Date()
        }

        var maskedKey: String {
            let trimmed = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 8 else { return trimmed }
            return "\(trimmed.prefix(4))…\(trimmed.suffix(4))"
        }
    }

    enum LicenseError: LocalizedError {
        case invalidKey
        case activationLimitReached
        case licenseKeyNotFound
        case instanceIdNotFound
        case productMismatch
        case serverUnreachable
        case networkRestricted
        case expired
        case disabled
        case unexpectedResponse
        case other(String)

        var errorDescription: String? {
            switch self {
            case .invalidKey:
                return "That license key doesn’t look valid."
            case .activationLimitReached:
                return "This license has already reached its activation limit."
            case .licenseKeyNotFound:
                return "The license server could not find that key."
            case .instanceIdNotFound:
                return "This Mac is no longer registered for that license."
            case .productMismatch:
                return "This license is not for MacWiFi."
            case .serverUnreachable:
                return "Unable to reach Lemon Squeezy right now."
            case .networkRestricted:
                return "This network appears to be blocking the license server."
            case .expired:
                return "This license has expired."
            case .disabled:
                return "This license has been disabled."
            case .unexpectedResponse:
                return "The license server returned an unexpected response."
            case .other(let message):
                return message
            }
        }
    }

    @Published private(set) var state: LicenseState?
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private let keychainService: String
    private let keychainAccount: String
    private let session: URLSession
    private let persistenceBackend: PersistenceBackend
    private let fileManager: FileManager

    private static let validationTTL: TimeInterval = 24 * 60 * 60
    private static let hyphenLikeCharacters = ["‐", "‑", "‒", "–", "—", "−", "﹘", "﹣", "－"]

    init(
        session: URLSession = .shared,
        keychainService: String = defaultLicenseKeychainService,
        keychainAccount: String = "license",
        fileManager: FileManager = .default,
        diagnostics: AppDiagnostics = .shared
    ) {
        self.session = session
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
        self.fileManager = fileManager
        self.persistenceBackend = diagnostics.isDeveloperMachine
            ? .developerFile(diagnostics.developerLicenseStateURL)
            : .keychain
        self.state = loadPersistedState()
    }

    var isLicensed: Bool {
        state?.isLicensed ?? false
    }

    func openCheckout(source: String = "settings") {
        AppAnalytics.shared.trackEvent("checkout_initiated", parameters: ["surface": source])
        NSWorkspace.shared.open(CheckoutLinkBuilder.purchaseURL(source: source))
    }

    func activate(licenseKey: String) async throws {
        let normalized = Self.normalizeLicenseKey(licenseKey)
        guard !normalized.isEmpty else {
            throw LicenseError.invalidKey
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        let instanceName = Host.current().localizedName ?? "Mac"
        let nextState = try await sendLicenseRequest(
            path: "activate",
            payload: [
                "license_key": normalized,
                "instance_name": instanceName,
            ],
            allowFallback: true
        ) { data, response in
            try Self.decodeActivationResponse(licenseKey: normalized, data: data, response: response)
        }

        saveState(nextState)
        state = nextState
        LicenseActivationFeedbackController.shared.presentSuccess()
        AppLogger.shared.info("License activated", category: .license)
    }

    func validate(forceRemote: Bool = false) async {
        guard let current = state else { return }
        guard forceRemote || !Self.shouldSkipValidation(lastValidatedAt: current.lastValidatedAt) else { return }

        errorMessage = nil

        do {
            let validated = try await sendLicenseRequest(
                path: "validate",
                payload: [
                    "license_key": current.licenseKey,
                    "instance_id": current.instanceId,
                ],
                allowFallback: true
            ) { data, response in
                try Self.decodeValidationResponse(current: current, data: data, response: response)
            }

            saveState(validated)
            state = validated
            AppLogger.shared.debug("License validated", category: .license, metadata: ["force_remote": forceRemote.description])
        } catch let error as LicenseError {
            AppLogger.shared.warning(
                "License validation failed",
                category: .license,
                metadata: ["error": error.localizedDescription]
            )
            if Self.isTerminal(error) {
                clearState()
            }
            errorMessage = error.localizedDescription
        } catch {
            AppLogger.shared.warning(
                "License validation failed",
                category: .license,
                metadata: ["error": error.localizedDescription]
            )
            errorMessage = error.localizedDescription
        }
    }

    func deactivate() async throws {
        guard let current = state else { return }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            _ = try await sendLicenseRequest(
                path: "deactivate",
                payload: [
                    "license_key": current.licenseKey,
                    "instance_id": current.instanceId,
                ],
                allowFallback: true
            ) { data, response in
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw Self.mapError(from: Self.decodeErrorMessage(from: data), statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                return ()
            }
        } catch let error as LicenseError {
            AppLogger.shared.warning(
                "License deactivation failed",
                category: .license,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        } catch {
            AppLogger.shared.warning(
                "License deactivation failed",
                category: .license,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }

        clearState()
        AppLogger.shared.info("License deactivated", category: .license)
    }

    private func sendLicenseRequest<T>(
        path: String,
        payload: [String: String],
        allowFallback: Bool,
        decode: (Data, URLResponse) throws -> T
    ) async throws -> T {
        do {
            let direct = try await performRequest(path: path, payload: payload, baseURL: LemonSqueezyConfiguration.apiBaseURL)
            return try decode(direct.0, direct.1)
        } catch let error as LicenseError where allowFallback && LemonSqueezyConfiguration.isRelayFallbackEnabled && Self.shouldFallback(for: error) {
            AppLogger.shared.info("Falling back to relay license endpoint", category: .license, metadata: ["path": path])
            let fallback = try await performRequest(path: path, payload: payload, baseURL: LemonSqueezyConfiguration.relayBaseURL)
            return try decode(fallback.0, fallback.1)
        } catch {
            throw error
        }
    }

    private func performRequest(path: String, payload: [String: String], baseURL: URL) async throws -> (Data, URLResponse) {
        let endpoint = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncodedData(payload)

        do {
            return try await session.data(for: request)
        } catch {
            throw LicenseError.serverUnreachable
        }
    }

    private func loadPersistedState() -> LicenseState? {
        switch persistenceBackend {
        case .developerFile(let url):
            return loadPersistedState(fileURL: url)
        case .keychain:
            return loadPersistedState(service: keychainService)
        }
    }

    private func loadPersistedState(fileURL: URL) -> LicenseState? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(LicenseState.self, from: data)
        } catch {
            AppLogger.shared.warning(
                "Failed to decode developer license state",
                category: .license,
                metadata: [
                    "path": fileURL.path,
                    "error": error.localizedDescription,
                ]
            )
            return nil
        }
    }

    private func loadPersistedState(service: String) -> LicenseState? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: keychainAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let decoded = try? JSONDecoder().decode(LicenseState.self, from: data) else {
            if status != errSecItemNotFound {
                AppLogger.shared.warning(
                    "Failed to load license state from keychain",
                    category: .license,
                    metadata: [
                        "service": service,
                        "status": Self.describeKeychainStatus(status),
                    ]
                )
            }
            return nil
        }

        return decoded
    }

    @discardableResult
    private func saveState(_ nextState: LicenseState) -> Bool {
        switch persistenceBackend {
        case .developerFile(let url):
            return saveState(nextState, fileURL: url)
        case .keychain:
            return saveState(nextState, service: keychainService)
        }
    }

    @discardableResult
    private func saveState(_ nextState: LicenseState, fileURL: URL) -> Bool {
        do {
            let data = try JSONEncoder().encode(nextState)
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: [.atomic])
            return true
        } catch {
            AppLogger.shared.warning(
                "Failed to write developer license state",
                category: .license,
                metadata: [
                    "path": fileURL.path,
                    "error": error.localizedDescription,
                ]
            )
            return false
        }
    }

    @discardableResult
    private func saveState(_ nextState: LicenseState, service: String) -> Bool {
        guard let data = try? JSONEncoder().encode(nextState) else {
            AppLogger.shared.warning(
                "Failed to encode license state for keychain",
                category: .license,
                metadata: ["service": service]
            )
            return false
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: keychainAccount,
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var createQuery = query
            createQuery[kSecValueData] = data
            createQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
            if createStatus != errSecSuccess {
                AppLogger.shared.warning(
                    "Failed to create license state in keychain",
                    category: .license,
                    metadata: [
                        "service": service,
                        "status": Self.describeKeychainStatus(createStatus),
                    ]
                )
                return false
            }
            return true
        }

        if updateStatus != errSecSuccess {
            AppLogger.shared.warning(
                "Failed to update license state in keychain",
                category: .license,
                metadata: [
                    "service": service,
                    "status": Self.describeKeychainStatus(updateStatus),
                ]
            )
            return false
        }

        return true
    }

    private func clearState() {
        switch persistenceBackend {
        case .developerFile(let url):
            deletePersistedState(fileURL: url)
        case .keychain:
            deletePersistedState(service: keychainService)
        }
        deletePersistedState(service: legacyDebugLicenseKeychainService)
        state = nil
    }

    private func deletePersistedState(fileURL: URL) {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            AppLogger.shared.warning(
                "Failed to delete developer license state",
                category: .license,
                metadata: [
                    "path": fileURL.path,
                    "error": error.localizedDescription,
                ]
            )
        }
    }

    private func deletePersistedState(service: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: keychainAccount,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.shared.warning(
                "Failed to delete license state from keychain",
                category: .license,
                metadata: [
                    "service": service,
                    "status": Self.describeKeychainStatus(status),
                ]
            )
        }
    }

    private static func describeKeychainStatus(_ status: OSStatus) -> String {
        if let message = SecCopyErrorMessageString(status, nil) as String? {
            return "\(status): \(message)"
        }
        return "\(status)"
    }

    private static func decodeActivationResponse(
        licenseKey: String,
        data: Data,
        response: URLResponse
    ) throws -> LicenseState {
        guard let http = response as? HTTPURLResponse else {
            throw LicenseError.unexpectedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw mapError(from: decodeErrorMessage(from: data), statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ActivateResponse.self, from: data)
        guard decoded.activated,
              let licenseKeyInfo = decoded.licenseKey,
              let instance = decoded.instance else {
            throw mapError(from: decoded.error, statusCode: http.statusCode)
        }

        guard matchesConfiguredScope(storeId: decoded.meta?.storeId, productId: decoded.meta?.productId) else {
            throw LicenseError.productMismatch
        }

        switch licenseKeyInfo.status {
        case "expired":
            throw LicenseError.expired
        case "disabled":
            throw LicenseError.disabled
        default:
            break
        }

        return LicenseState(
            licenseKey: licenseKey,
            instanceId: instance.id,
            status: licenseKeyInfo.status,
            expiresAt: parseExpiresAt(licenseKeyInfo.expiresAt),
            storeId: decoded.meta?.storeId ?? 0,
            productId: decoded.meta?.productId ?? 0,
            lastValidatedAt: Date()
        )
    }

    private static func decodeValidationResponse(
        current: LicenseState,
        data: Data,
        response: URLResponse
    ) throws -> LicenseState {
        guard let http = response as? HTTPURLResponse else {
            throw LicenseError.unexpectedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw mapError(from: decodeErrorMessage(from: data), statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ValidateResponse.self, from: data)
        guard decoded.valid, let licenseKeyInfo = decoded.licenseKey else {
            throw mapError(from: decoded.error, statusCode: http.statusCode)
        }

        guard matchesConfiguredScope(storeId: decoded.meta?.storeId, productId: decoded.meta?.productId) else {
            throw LicenseError.productMismatch
        }

        switch licenseKeyInfo.status {
        case "expired":
            throw LicenseError.expired
        case "disabled":
            throw LicenseError.disabled
        default:
            break
        }

        return LicenseState(
            licenseKey: current.licenseKey,
            instanceId: current.instanceId,
            status: licenseKeyInfo.status,
            expiresAt: parseExpiresAt(licenseKeyInfo.expiresAt),
            storeId: decoded.meta?.storeId ?? current.storeId,
            productId: decoded.meta?.productId ?? current.productId,
            lastValidatedAt: Date()
        )
    }

    private static func shouldSkipValidation(lastValidatedAt: Date?, now: Date = Date()) -> Bool {
        guard let lastValidatedAt else { return false }
        return now.timeIntervalSince(lastValidatedAt) < validationTTL
    }

    private static func shouldFallback(for error: LicenseError) -> Bool {
        switch error {
        case .serverUnreachable, .networkRestricted:
            return true
        case .other(let message):
            let lowercased = message.lowercased()
            return lowercased.contains("blocked") || lowercased.contains("forbidden") || lowercased.contains("unreachable")
        default:
            return false
        }
    }

    private static func isTerminal(_ error: LicenseError) -> Bool {
        switch error {
        case .invalidKey, .productMismatch, .expired, .disabled:
            return true
        default:
            return false
        }
    }

    private static func matchesConfiguredScope(storeId: Int?, productId: Int?) -> Bool {
        guard storeId == LemonSqueezyConfiguration.storeId else { return false }
        guard productId == LemonSqueezyConfiguration.productId else { return false }
        return true
    }

    private static func parseExpiresAt(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: raw) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: raw)
    }

    private static func normalizeLicenseKey(_ raw: String) -> String {
        var normalized = raw
        for character in hyphenLikeCharacters {
            normalized = normalized.replacingOccurrences(of: character, with: "-")
        }

        normalized = normalized.replacingOccurrences(of: "\u{00A0}", with: " ")
        let scalars = normalized.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
        return String(String.UnicodeScalarView(scalars)).uppercased()
    }

    private static func formEncodedData(_ values: [String: String]) -> Data? {
        var components = URLComponents()
        components.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private static func decodeErrorMessage(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(GenericErrorResponse.self, from: data) {
            return decoded.error
        }
        return nil
    }

    private static func mapError(from message: String?, statusCode: Int) -> LicenseError {
        let lowercased = message?.lowercased() ?? ""

        if lowercased.contains("activation limit") {
            return .activationLimitReached
        }
        if lowercased.contains("license key not found") || lowercased.contains("license_key not found") {
            return .licenseKeyNotFound
        }
        if lowercased.contains("instance id not found") || lowercased.contains("instance_id not found") {
            return .instanceIdNotFound
        }
        if lowercased.contains("expired") {
            return .expired
        }
        if lowercased.contains("disabled") {
            return .disabled
        }
        if lowercased.contains("invalid") {
            return .invalidKey
        }
        if lowercased.contains("blocked") || lowercased.contains("forbidden") || statusCode == 403 || statusCode == 451 {
            return .networkRestricted
        }
        if lowercased.contains("product") || lowercased.contains("store") {
            return .productMismatch
        }
        if lowercased.isEmpty {
            return statusCode == 0 ? .serverUnreachable : .unexpectedResponse
        }

        return .other(message ?? "Unexpected license error")
    }
}

private struct LicenseKeyInfo: Codable {
    let status: String
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case expiresAt = "expires_at"
    }
}

private struct LicenseMeta: Codable {
    let storeId: Int
    let productId: Int

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case productId = "product_id"
    }
}

private struct LicenseInstance: Codable {
    let id: String
}

private struct ActivateResponse: Codable {
    let activated: Bool
    let error: String?
    let licenseKey: LicenseKeyInfo?
    let meta: LicenseMeta?
    let instance: LicenseInstance?

    enum CodingKeys: String, CodingKey {
        case activated
        case error
        case licenseKey = "license_key"
        case meta
        case instance
    }
}

private struct ValidateResponse: Codable {
    let valid: Bool
    let error: String?
    let licenseKey: LicenseKeyInfo?
    let meta: LicenseMeta?

    enum CodingKeys: String, CodingKey {
        case valid
        case error
        case licenseKey = "license_key"
        case meta
    }
}

private struct GenericErrorResponse: Codable {
    let error: String?
}
