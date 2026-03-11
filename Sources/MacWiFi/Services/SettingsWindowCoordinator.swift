import AppKit
import SwiftUI

@MainActor
final class SettingsWindowCoordinator {
    private var window: NSWindow?

    func show(licenseManager: LemonSqueezyLicenseManager) {
        if let window {
            window.contentViewController = NSHostingController(rootView: SettingsView(licenseManager: licenseManager))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: SettingsView(licenseManager: licenseManager))
        let window = NSWindow(contentViewController: controller)
        window.title = "MacWiFi Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 620, height: 520))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
