import Foundation

enum AppInstallIdentity {
    private static let defaultsKey = "macwifi.install_id"

    static var installID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: defaultsKey),
           !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return existing
        }

        let created = UUID().uuidString
        defaults.set(created, forKey: defaultsKey)
        return created
    }
}
