import SwiftUI
import AppKit
import Combine

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

struct PopoverRootView: View {
    @Bindable var manager: WiFiManager
    @ObservedObject var licenseManager: LemonSqueezyLicenseManager
    @State private var activationFeedback = LicenseActivationFeedbackController.shared

    var body: some View {
        Group {
            if licenseManager.isLicensed, activationFeedback.pendingSuccessToken != nil {
                LicenseActivationSuccessView(manager: manager)
            } else if licenseManager.isLicensed {
                MenuContent(manager: manager)
            } else {
                LicenseGateView(licenseManager: licenseManager, surface: .popover)
            }
        }
        .background(VisualEffectBackground())
    }
}

struct LicenseActivationSuccessView: View {
    @Bindable var manager: WiFiManager
    @State private var activationFeedback = LicenseActivationFeedbackController.shared
    @State private var animateBadge = false
    @State private var revealContent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(nsColor: .systemGreen).opacity(0.24),
                                    Color(nsColor: .systemGreen).opacity(0.08),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)
                        .scaleEffect(animateBadge ? 1.0 : 0.82)

                    Circle()
                        .stroke(Color(nsColor: .systemGreen).opacity(0.24), lineWidth: 1)
                        .frame(width: 108, height: 108)
                        .scaleEffect(animateBadge ? 1.02 : 0.9)
                        .opacity(animateBadge ? 1 : 0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(nsColor: .systemGreen))
                        .scaleEffect(animateBadge ? 1 : 0.55)
                        .opacity(animateBadge ? 1 : 0)
                }
                .padding(.top, 12)
                .animation(.spring(response: 0.5, dampingFraction: 0.72), value: animateBadge)

                VStack(spacing: 7) {
                    Text("License Activated")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("MacWiFi is unlocked on this Mac. Run a check now and see how your connection is doing.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppPalette.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 8)
                .animation(.easeOut(duration: 0.28).delay(0.12), value: revealContent)

                Button(action: startWifiTest) {
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 12, weight: .semibold))
                        Text("How's my WiFi")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.accentStrong, AppPalette.accentMedium],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 10)
                .animation(.easeOut(duration: 0.28).delay(0.18), value: revealContent)

                Button("Later") {
                    activationFeedback.clear()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
                .opacity(revealContent ? 1 : 0)
                .animation(.easeOut(duration: 0.24).delay(0.22), value: revealContent)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(width: 360)
        .background(.regularMaterial)
        .onAppear {
            animateBadge = false
            revealContent = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                animateBadge = true
            }
            withAnimation(.easeOut(duration: 0.28).delay(0.08)) {
                revealContent = true
            }
        }
    }

    private func startWifiTest() {
        activationFeedback.clear()
        manager.refreshStatus()
        manager.qualityMonitor.start()
        if manager.isPoweredOn {
            manager.scan()
        }
    }
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
    private enum PopoverPresentationReason: String {
        case user
        case completedResults = "completed_results"
        case licenseRequired = "license_required"
        case activationSuccess = "activation_success"
    }

    private enum PopoverDismissalReason: String {
        case explicitCollapse = "explicit_collapse"
        case outsideInteraction = "outside_interaction"
        case replaced = "replaced"
        case statusMenu = "status_menu"
    }

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var observationTask: Task<Void, Never>?
    private var licenseObservation: AnyCancellable?
    private let licenseManager = LemonSqueezyLicenseManager.shared
    private let settingsWindowCoordinator = SettingsWindowCoordinator()
    private var hasUserOpenedPopover = false
    private var popoverCollapsedAfterUserInteraction = false
    private var lastAutoPresentedResultsAt: Date?
    private var didAutoPresentLicenseGate = false
    private var suppressAutoPresentUntilNextExplicitOpen = false
    private var pendingDismissalReason: PopoverDismissalReason?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let diagnostics = AppDiagnostics.shared
        AppLogger.shared.info(
            "MacWiFi launched",
            category: .app,
            metadata: [
                "developer_machine": diagnostics.isDeveloperMachine.description,
                "developer_marker": diagnostics.developerMarkerPath ?? "none",
                "log_file": diagnostics.appLogURL.path,
            ]
        )
        setupStatusItem()
        setupPopover()
        observeLicenseState()
        startObservingQuality()
        WiFiManager.shared.refreshStatus()
        AppAnalytics.shared.trackInstallIfNeeded()
        Task {
            await licenseManager.validate(forceRemote: false)
            await MainActor.run {
                if !licenseManager.isLicensed {
                    presentLicenseGateIfNeeded(force: true)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        observationTask?.cancel()
        licenseObservation?.cancel()
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
                        self.handleCompletedQualityRun()
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

        let iconName: String
        let accessibilityDescription: String

        if !licenseManager.isLicensed {
            iconName = "lock.fill"
            accessibilityDescription = "License required"
            button.toolTip = "Activate your MacWiFi license"
        } else if !manager.isPoweredOn {
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
        if !licenseManager.isLicensed {
            button.toolTip = "Activate your MacWiFi license"
        } else if let ssid = manager.currentNetwork?.ssid, manager.isPoweredOn {
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
            rootView: PopoverRootView(
                manager: WiFiManager.shared,
                licenseManager: licenseManager
            )
        )

        popover.contentViewController = hostingController
        popover.delegate = self
    }

    @objc private func togglePopover() {
        if shouldShowStatusMenu(for: NSApp.currentEvent) {
            showStatusMenu()
            return
        }

        hasUserOpenedPopover = true
        if popover.isShown {
            pendingDismissalReason = .explicitCollapse
            AppLogger.shared.debug("Closing popover from status item", category: .ui)
            popover.performClose(nil)
        } else {
            popoverCollapsedAfterUserInteraction = false
            suppressAutoPresentUntilNextExplicitOpen = false
            showPopover(reason: .user)
        }
    }

    private func showPopover(reason: PopoverPresentationReason) {
        guard let button = statusItem.button else { return }
        guard button.window != nil else { return }
        guard button.bounds.width > 0, button.bounds.height > 0 else { return }

        if licenseManager.isLicensed {
            WiFiManager.shared.refreshStatus()
        }
        if popover.isShown {
            pendingDismissalReason = .replaced
            popover.performClose(nil)
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        AppLogger.shared.info(
            "Showing popover",
            category: .ui,
            metadata: ["reason": reason.rawValue]
        )
        if !licenseManager.isLicensed {
            didAutoPresentLicenseGate = true
            return
        }

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
        if popover.isShown {
            pendingDismissalReason = .statusMenu
            popover.performClose(nil)
        }

        let menu = NSMenu()
        let settingsTitle = licenseManager.isLicensed ? "License & Settings…" : "Activate License…"
        menu.addItem(withTitle: settingsTitle, action: #selector(openSettingsWindow), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacWiFi", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func popoverDidClose(_ notification: Notification) {
        let dismissalReason = pendingDismissalReason ?? .outsideInteraction
        pendingDismissalReason = nil

        switch dismissalReason {
        case .explicitCollapse:
            if hasUserOpenedPopover {
                popoverCollapsedAfterUserInteraction = true
            }
            suppressAutoPresentUntilNextExplicitOpen = false
        case .replaced:
            popoverCollapsedAfterUserInteraction = false
        case .outsideInteraction, .statusMenu:
            popoverCollapsedAfterUserInteraction = false
            suppressAutoPresentUntilNextExplicitOpen = true
        }

        AppLogger.shared.debug(
            "Popover closed",
            category: .ui,
            metadata: [
                "dismissal_reason": dismissalReason.rawValue,
                "has_user_opened": hasUserOpenedPopover.description,
                "collapsed_after_user_interaction": popoverCollapsedAfterUserInteraction.description,
                "auto_present_suppressed": suppressAutoPresentUntilNextExplicitOpen.description,
            ]
        )
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
                    AppLogger.shared.info("Activation URL handled successfully", category: .license)
                    showPopover(reason: .activationSuccess)
                }
            } catch let error as LemonSqueezyLicenseManager.LicenseError {
                await MainActor.run {
                    AppLogger.shared.warning(
                        "Activation URL failed",
                        category: .license,
                        metadata: ["error": error.localizedDescription]
                    )
                    presentLicenseGateIfNeeded(force: true)
                    showActivationAlert(title: "Activation Failed", message: error.errorDescription ?? "MacWiFi could not activate this license.")
                }
            } catch {
                await MainActor.run {
                    AppLogger.shared.warning(
                        "Activation URL failed",
                        category: .license,
                        metadata: ["error": error.localizedDescription]
                    )
                    presentLicenseGateIfNeeded(force: true)
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

    private func handleCompletedQualityRun() {
        updateMenuBarIcon()
        maybeAutoPresentCompletedResults()
    }

    private func maybeAutoPresentCompletedResults() {
        guard licenseManager.isLicensed else { return }
        let monitor = WiFiManager.shared.qualityMonitor

        guard let completedAt = monitor.lastTestTime else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "missing_completion_time"])
            return
        }

        guard monitor.hasFreshTestResults else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "results_not_fresh"])
            return
        }

        guard hasUserOpenedPopover else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "user_never_opened_popover"])
            return
        }

        guard !suppressAutoPresentUntilNextExplicitOpen else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "auto_present_suppressed_after_dismiss"])
            return
        }

        guard popoverCollapsedAfterUserInteraction else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "popover_not_collapsed_after_user_interaction"])
            return
        }

        guard !popover.isShown else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "popover_already_visible"])
            return
        }

        guard lastAutoPresentedResultsAt != completedAt else {
            AppLogger.shared.debug("Skipping auto-present for completed results", category: .ui, metadata: ["reason": "result_already_presented"])
            return
        }

        lastAutoPresentedResultsAt = completedAt
        popoverCollapsedAfterUserInteraction = false
        showPopover(reason: .completedResults)
    }

    private func observeLicenseState() {
        licenseObservation = licenseManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateMenuBarIcon()
                self.handleLicenseStateChange()
            }
    }

    private func handleLicenseStateChange() {
        if licenseManager.isLicensed {
            return
        }

        WiFiManager.shared.qualityMonitor.stop()
        lastAutoPresentedResultsAt = nil
        presentLicenseGateIfNeeded(force: true)
    }

    private func presentLicenseGateIfNeeded(force: Bool) {
        guard !licenseManager.isLicensed else { return }
        guard force || !didAutoPresentLicenseGate else { return }

        didAutoPresentLicenseGate = true
        popoverCollapsedAfterUserInteraction = false
        showPopover(reason: .licenseRequired)
    }
}
