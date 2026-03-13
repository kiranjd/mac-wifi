import Foundation
import Observation

@MainActor
@Observable
final class PopoverRouteController {
    enum Route: Equatable {
        case main
        case settings
    }

    static let shared = PopoverRouteController()

    var route: Route = .main

    func showMain() {
        route = .main
    }

    func showSettings() {
        route = .settings
    }
}
