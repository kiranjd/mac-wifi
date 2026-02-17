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

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var observationTask: Task<Void, Never>?
    private var isPinnedSummaryPopover = false
    private var allowPinnedPopoverClose = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startObservingQuality()

        // Start reliability test as soon as the app launches if already connected.
        if shouldAutoStartTest() {
            WiFiManager.shared.qualityMonitor.start()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func startObservingQuality() {
        // Observe quality monitor changes to update icon
        observationTask = Task {
            let monitor = WiFiManager.shared.qualityMonitor
            var lastScore: Double = -1
            var lastRunningState = monitor.isRunning

            while !Task.isCancelled {
                // Calculate current score
                let score = min(monitor.speedScore, monitor.reliabilityScore)
                let isRunning = monitor.isRunning

                // Update icon if score changed or test state changed
                if score != lastScore || isRunning {
                    lastScore = score
                    await MainActor.run {
                        updateMenuBarIcon()
                    }
                }

                // Always bring popover to focus when a test completes.
                if lastRunningState && !isRunning && monitor.successfulRuns > 0 {
                    await MainActor.run {
                        if !self.popover.isShown {
                            self.showCompletionPopover()
                        } else {
                            self.pinCurrentPopoverForSummary()
                            self.bringAppAndPopoverToFront()
                        }
                    }
                }
                lastRunningState = isRunning

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
        if !manager.isPoweredOn {
            iconName = "wifi.slash"
        } else if manager.currentNetwork == nil {
            iconName = "wifi"
        } else if monitor.isRunning {
            iconName = "wifi"
        } else if monitor.downloadMbps > 0 {
            // Use filled icon with quality indicator
            let score = min(monitor.speedScore, monitor.reliabilityScore)
            if score >= 70 {
                iconName = "wifi"  // Good - normal icon
            } else if score >= 40 {
                iconName = "wifi.exclamationmark"  // Warning
            } else if score > 0 {
                iconName = "wifi.exclamationmark"  // Poor
            } else {
                iconName = "wifi"
            }
        } else {
            iconName = "wifi"
        }

        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "WiFi")
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
        if popover.isShown {
            allowPinnedPopoverClose = true
            popover.performClose(nil)
            allowPinnedPopoverClose = false
            isPinnedSummaryPopover = false
            popover.behavior = .transient
        } else {
            showPopover(triggerAutoStart: true)
        }
    }

    private func showPopover(triggerAutoStart: Bool) {
        guard let button = statusItem.button else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Start scanning when popover opens.
        WiFiManager.shared.scan()
        if triggerAutoStart && WiFiManager.shared.currentNetwork != nil {
            WiFiManager.shared.qualityMonitor.start()
        }
    }

    private func showCompletionPopover() {
        pinCurrentPopoverForSummary()
        bringAppAndPopoverToFront()
        showPopover(triggerAutoStart: false)
    }

    private func pinCurrentPopoverForSummary() {
        isPinnedSummaryPopover = true
        popover.behavior = .applicationDefined
    }

    private func bringAppAndPopoverToFront() {
        NSApp.activate(ignoringOtherApps: true)
        if let buttonWindow = statusItem.button?.window {
            buttonWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func shouldAutoStartTest(maxAgeSeconds: TimeInterval = 120) -> Bool {
        let manager = WiFiManager.shared
        let monitor = manager.qualityMonitor

        guard manager.currentNetwork != nil else { return false }
        guard !monitor.isRunning else { return false }

        guard let lastTestTime = monitor.lastTestTime else {
            return true
        }
        return Date().timeIntervalSince(lastTestTime) > maxAgeSeconds
    }

    func popoverDidClose(_ notification: Notification) {
        if !allowPinnedPopoverClose {
            isPinnedSummaryPopover = false
            popover.behavior = .transient
        }
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        if isPinnedSummaryPopover && !allowPinnedPopoverClose {
            return false
        }
        return true
    }
}
