import Foundation
import Observation

@MainActor
@Observable
final class LicenseActivationFeedbackController {
    static let shared = LicenseActivationFeedbackController()

    private(set) var pendingSuccessToken: UUID?

    func presentSuccess() {
        pendingSuccessToken = UUID()
    }

    func clear() {
        pendingSuccessToken = nil
    }
}
