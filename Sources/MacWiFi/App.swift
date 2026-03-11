import SwiftUI
import AppKit

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.state = .active
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

@main
struct MacWiFiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let licenseManager = LemonSqueezyLicenseManager.shared

    var body: some Scene {
        Settings {
            SettingsView(licenseManager: licenseManager)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var observationTask: Task<Void, Never>?
    private let licenseManager = LemonSqueezyLicenseManager.shared
    private let settingsWindowCoordinator = SettingsWindowCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startObservingQuality()
        WiFiManager.shared.refreshStatus()
        AppAnalytics.shared.trackInstallIfNeeded()
        Task {
            await licenseManager.validate(forceRemote: false)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func startObservingQuality() {
        // Observe quality monitor changes to update icon
        observationTask = Task {
            let monitor = WiFiManager.shared.qualityMonitor
            let manager = WiFiManager.shared
            var lastScore: Double = -1
            var lastRunningState = monitor.isRunning
            var lastPowerState = manager.isPoweredOn
            var lastSSID = manager.currentNetwork?.ssid
            var lastConnectionState = manager.connectionState

            while !Task.isCancelled {
                // Calculate current score
                let score = min(monitor.speedScore, monitor.reliabilityScore)
                let isRunning = monitor.isRunning
                let isPoweredOn = manager.isPoweredOn
                let connectedSSID = manager.currentNetwork?.ssid
                let connectionState = manager.connectionState
                let wasRunning = lastRunningState

                // Update icon whenever power, connectivity, run-state, or quality changes.
                if score != lastScore
                    || isRunning != wasRunning
                    || isPoweredOn != lastPowerState
                    || connectedSSID != lastSSID
                    || connectionState != lastConnectionState {
                    lastScore = score
                    lastRunningState = isRunning
                    lastPowerState = isPoweredOn
                    lastSSID = connectedSSID
                    lastConnectionState = connectionState
                    await MainActor.run {
                        updateMenuBarIcon()
                    }
                }

                // Test completion updates icon/state only; never auto-open UI.
                if wasRunning && !isRunning && monitor.successfulRuns > 0 {
                    await MainActor.run {
                        self.updateMenuBarIcon()
                    }
                }

                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem.button else { return }

        let manager = WiFiManager.shared
        let monitor = manager.qualityMonitor

        // Base icon
        let iconName: String
        let accessibilityDescription: String
        if !manager.isPoweredOn {
            iconName = "wifi.slash"
            accessibilityDescription = "Wi-Fi off"
        } else if manager.currentNetwork == nil {
            iconName = "wifi.exclamationmark"
            accessibilityDescription = "Wi-Fi on, not connected"
        } else if monitor.isRunning {
            iconName = "wifi"
            accessibilityDescription = "Wi-Fi connected, testing"
        } else if monitor.downloadMbps > 0 {
            // Use filled icon with quality indicator
            let score = min(monitor.speedScore, monitor.reliabilityScore)
            if score >= 70 {
                iconName = "wifi"  // Good - normal icon
                accessibilityDescription = "Wi-Fi connected"
            } else if score >= 40 {
                iconName = "wifi.exclamationmark"  // Warning
                accessibilityDescription = "Wi-Fi connected, warning"
            } else if score > 0 {
                iconName = "wifi.exclamationmark"  // Poor
                accessibilityDescription = "Wi-Fi connected, poor quality"
            } else {
                iconName = "wifi"
                accessibilityDescription = "Wi-Fi connected"
            }
        } else {
            iconName = "wifi"
            accessibilityDescription = "Wi-Fi connected"
        }

        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: accessibilityDescription)
        if let ssid = manager.currentNetwork?.ssid, manager.isPoweredOn {
            button.toolTip = "\(ssid)"
        } else {
            button.toolTip = accessibilityDescription
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient

        // Use hosting controller directly - it will size to fit SwiftUI content
        let hostingController = NSHostingController(
            rootView: MenuContent(manager: WiFiManager.shared)
                .background(VisualEffectBackground())
        )

        popover.contentViewController = hostingController
        popover.delegate = self
    }

    @objc private func togglePopover() {
        if shouldShowStatusMenu(for: NSApp.currentEvent) {
            showStatusMenu()
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        guard button.window != nil else { return }
        guard button.bounds.width > 0, button.bounds.height > 0 else { return }

        WiFiManager.shared.refreshStatus()
        if popover.isShown {
            popover.performClose(nil)
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Start scanning when popover opens, only if Wi-Fi is powered on.
        if WiFiManager.shared.isPoweredOn {
            WiFiManager.shared.scan()
        }
    }

    private func shouldShowStatusMenu(for event: NSEvent?) -> Bool {
        guard let event else { return false }
        return event.type == .rightMouseUp || event.modifierFlags.contains(.control)
    }

    private func showStatusMenu() {
        popover.performClose(nil)

        let menu = NSMenu()
        menu.addItem(withTitle: "License & Settings…", action: #selector(openSettingsWindow), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacWiFi", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            settingsWindowCoordinator.show(licenseManager: licenseManager)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        guard url.scheme?.lowercased() == "macwifi" else { return }
        guard url.host?.lowercased() == "activate" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let key = components?.queryItems?.first(where: { $0.name == "key" })?.value,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        Task {
            do {
                try await licenseManager.activate(licenseKey: key)
                await MainActor.run {
                    openSettingsWindow()
                    showActivationAlert(title: "License Activated", message: "MacWiFi is now licensed on this Mac.")
                }
            } catch let error as LemonSqueezyLicenseManager.LicenseError {
                await MainActor.run {
                    openSettingsWindow()
                    showActivationAlert(title: "Activation Failed", message: error.errorDescription ?? "MacWiFi could not activate this license.")
                }
            } catch {
                await MainActor.run {
                    openSettingsWindow()
                    showActivationAlert(title: "Activation Failed", message: "MacWiFi could not activate this license.")
                }
            }
        }
    }

    private func showActivationAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
