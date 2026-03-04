import SwiftUI
import CoreWLAN
import AppKit

struct MenuContent: View {
    @Bindable var manager: WiFiManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showPasswordPrompt = false
    @State private var selectedNetwork: Network?
    @State private var password = ""
    @State private var showOtherNetworks = false
    @State private var wifiBadgeHover = false
    @State private var wifiBadgeFlarePosition: CGFloat = -36
    @State private var didCopyDiagnostics = false
    @State private var passwordPromptError: String?
    @State private var isSubmittingPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
                .padding(.horizontal, 12)
                .padding(.top, 13)
                .padding(.bottom, 9)

            if manager.isPoweredOn {
                if isLocationServicesError {
                    locationPermissionPrimaryView
                } else {
                    // Current network info bar (if connected)
                    if let current = manager.currentNetwork {
                        connectionInfoBar(current)
                    } else {
                        notConnectedInfoBar
                    }

                    Divider().opacity(0.4).padding(.horizontal, 8)

                    // Networks list
                    if shouldUseScrollableNetworksList {
                        ScrollView(showsIndicators: true) {
                            networksList
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                        }
                        .frame(height: networksListHeight)
                    } else {
                        networksList
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                }
            } else {
                // WiFi off state
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Wi-Fi is off")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }

            Divider().opacity(0.4).padding(.horizontal, 8)

            // Footer
            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 336)
        .background(.regularMaterial)
        .sheet(isPresented: $showPasswordPrompt) {
            PasswordPrompt(
                network: selectedNetwork,
                password: $password,
                errorMessage: passwordPromptError,
                isConnecting: isSubmittingPassword,
                onConnect: connectWithPassword,
                onCancel: resetPasswordPrompt
            )
        }
        .onAppear {
            if manager.isPoweredOn {
                if manager.networks.isEmpty {
                    manager.scan()
                }
            }
        }
        .onDisappear {
            // Keep tests running when popover closes so results can complete in background.
        }
    }

    // MARK: - Header

    private func relativeTimeString(since date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        let minutes = max(1, seconds / 60)
        return "\(minutes)m ago"
    }

    private var shouldUseScrollableNetworksList: Bool {
        visibleNetworkRowsCount > 10
    }

    private var networksListHeight: CGFloat {
        // Keep long lists constrained without forcing large empty space for short content.
        let estimatedRowHeight: CGFloat = 28
        let basePadding: CGFloat = 12
        let estimated = (CGFloat(max(visibleNetworkRowsCount, 1)) * estimatedRowHeight) + basePadding
        return min(estimated, 300)
    }

    private var visibleNetworkRowsCount: Int {
        let personalHotspotSSIDs = Set(manager.personalHotspots.map { $0.ssid.lowercased() })
        let knownNetworks = manager.networks.filter {
            $0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
                && !$0.isHiddenSSID
        }
        let otherNetworks = manager.networks.filter {
            !$0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
                && !$0.isHiddenSSID
        }

        var visibleRowsEstimate = manager.personalHotspots.count + knownNetworks.count
        if manager.currentNetwork != nil {
            visibleRowsEstimate += 1 // "Other Networks" row
            if showOtherNetworks {
                visibleRowsEstimate += otherNetworks.count
            }
        } else {
            visibleRowsEstimate += otherNetworks.count
        }
        return visibleRowsEstimate
    }

    private var header: some View {
        HStack {
            Text("Wi-Fi")
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            Spacer()

            if manager.isScanning {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.7)
                    .padding(.trailing, 6)
            }

            Toggle("", isOn: Binding(
                get: { manager.isPoweredOn },
                set: { manager.setPower($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
        }
    }

    // MARK: - Connected Network Card (Premium integrated design)

    private var notConnectedInfoBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppPalette.accentBackground.opacity(colorScheme == .dark ? 0.42 : 0.28))
                    .frame(width: 28, height: 28)
                Image(systemName: "wifi")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Not Connected")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Wi-Fi is on. Select a network below to connect.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppPalette.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppPalette.borderSoft.opacity(0.85), lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func connectionInfoBar(_ network: Network) -> some View {
        let monitor = manager.qualityMonitor
        let isRunning = monitor.isRunning
        let hasFreshResults = monitor.hasFreshTestResults
        let hasInRunResults = isRunning && monitor.successfulRuns > 0
        let showContent = isRunning || hasFreshResults
        let showDetails = hasFreshResults || hasInRunResults
        let dlSpeed = isRunning ? monitor.liveDownloadMbps : (hasFreshResults ? monitor.downloadMbps : 0)
        let ulSpeed = isRunning ? monitor.liveUploadMbps : (hasFreshResults ? monitor.uploadMbps : 0)

        VStack(alignment: .leading, spacing: 0) {
            // Header: Network name + disconnect
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppPalette.accent)
                        .frame(width: 28, height: 28)
                    Image(systemName: "wifi")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(wifiBadgeHover ? 1.06 : 1.0)
                .shadow(
                    color: AppPalette.accent.opacity(wifiBadgeHover ? 0.45 : 0.18),
                    radius: wifiBadgeHover ? 10 : 4,
                    x: 0,
                    y: 0
                )
                .overlay {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.52), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(8, geo.size.width * 0.38), height: geo.size.height * 1.9)
                            .rotationEffect(.degrees(24))
                            .offset(x: wifiBadgeFlarePosition)
                    }
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.75), value: wifiBadgeHover)
                .onHover { hovering in
                    wifiBadgeHover = hovering
                    if hovering {
                        // Quick shine sweep across the badge on hover.
                        wifiBadgeFlarePosition = -36
                        withAnimation(.easeOut(duration: 0.72)) {
                            wifiBadgeFlarePosition = 36
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.18)) {
                            wifiBadgeFlarePosition = -36
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(network.ssid)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("\(network.band.displayName) · \(network.security.rawValue)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.textMuted)
                }

                Spacer()

                Button(action: { manager.disconnect() }) {
                    Text("Disconnect")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 13)
            .padding(.bottom, 6)

            // Graph with overlaid speed numbers
            if showContent {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        // Graph
                        liveSpeedGraph
                            .frame(height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .opacity(isRunning ? 1 : 0.5)

                        // Throughput + reliability labels
                        HStack(spacing: 10) {
                            speedValueCompact(
                                value: dlSpeed,
                                arrow: "arrow.down",
                                color: AppPalette.graphDownload,
                                helpText: "Download speed"
                            )
                            speedValueCompact(
                                value: ulSpeed,
                                arrow: "arrow.up",
                                color: AppPalette.graphUpload,
                                helpText: "Upload speed"
                            )

                            Spacer(minLength: 4)

                            if !isRunning && hasFreshResults {
                                Button(action: { monitor.start() }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .shadow(
                            color: colorScheme == .dark ? .black.opacity(0.24) : .black.opacity(0.10),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                        .padding(.horizontal, 10)
                        .padding(.bottom, 9)
                    }

                    if isRunning {
                        runningGraphStatusFooter(monitor: monitor)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isRunning)

                // Details section - show preliminary reliability while still running
                if showDetails {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .opacity(0.3)
                            .padding(.horizontal, 12)

                        detailsExpandedSection
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                    }
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                }
            } else {
                // Test button - when no test yet
                Button(action: { monitor.start() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 12))
                        Text("Test Connection")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isRunning)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppPalette.accentBackground.opacity(colorScheme == .dark ? 0.12 : 0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppPalette.borderSoft.opacity(0.78), lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func runningGraphStatusFooter(monitor: NetworkQualityMonitor) -> some View {
        let status = runningNetworkLayerStatus(monitor)

        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .opacity(0.18)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            TimelineView(.periodic(from: .now, by: monitor.visualUpdateIntervalSeconds)) { _ in
                let clampedProgress = max(0, min(1, monitor.runProgress))
                let progressPercent = Int((clampedProgress * 100).rounded())

                Text("\(status.line) · \(progressPercent)%")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .id(status.id)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 3).combined(with: .opacity),
                            removal: .offset(y: -3).combined(with: .opacity)
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    AppPalette.accentBackground.opacity(colorScheme == .dark ? 0.10 : 0.05),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .background(.ultraThinMaterial)
        )
        .animation(.easeInOut(duration: 0.24), value: status.id)
    }

    private struct RunningPhaseStatus {
        let id: String
        let line: String
    }

    private func runningNetworkLayerStatus(_ monitor: NetworkQualityMonitor) -> RunningPhaseStatus {
        let phase = monitor.testPhaseText.lowercased()

        if monitor.runProgress >= 0.94 {
            return RunningPhaseStatus(
                id: "finalizing",
                line: "Wrapping up results"
            )
        }

        if phase.contains("local wi-fi vs internet")
            || phase.contains("baseline latency")
            || (monitor.successfulRuns == 0 && (monitor.gatewayLatencyMs == nil || monitor.internetLatencyMs == nil)) {
            return RunningPhaseStatus(
                id: "path-check",
                line: "Checking Wi-Fi and internet"
            )
        }

        if (phase.contains("stressing link") && monitor.successfulRuns == 0)
            || phase.contains("measuring internet speed") {
            return RunningPhaseStatus(
                id: "speed",
                line: "Measuring download and upload speed"
            )
        }

        if phase.contains("preparing run")
            || phase.contains("initial result ready")
            || phase.contains("stable result reached early")
            || phase.contains("stressing link") {
            return RunningPhaseStatus(
                id: "stability",
                line: "Checking connection stability"
            )
        }

        return RunningPhaseStatus(
            id: "stability-default",
            line: "Checking connection stability"
        )
    }

    // Details section - simple and clear
    @ViewBuilder
    private var detailsExpandedSection: some View {
        let diagnosis = currentDiagnosis

        VStack(alignment: .leading, spacing: 10) {
            diagnosisSummaryCard(diagnosis: diagnosis)
            Divider().opacity(0.24)
            whatYouCanDoNowCard(diagnosis: diagnosis)
            Divider().opacity(0.18)

            DisclosureGroup("Advanced info") {
                connectionBreakdownSection(diagnosis: diagnosis)
                    .padding(.top, 2)
                Text("Speed test uses data.")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    Button(action: copyDiagnosticsToClipboard) {
                        Label("Copy diagnostics", systemImage: "doc.on.doc")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    if didCopyDiagnostics {
                        Text("Copied")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 4)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }

    // Old collapsible version (kept for reference)
    @ViewBuilder
    private var detailsSection: some View {
        detailsExpandedSection
    }

    private struct DiagnosisSummary {
        enum Tone {
            case healthy
            case caution
            case unstable
            case checking
        }

        let title: String
        let detail: String
        let tone: Tone
    }

    private struct QuickActionStatus {
        enum Severity {
            case good
            case warning
            case poor
        }

        let title: String
        let icon: String
        let isGood: Bool
        let severity: Severity
        let goodDetail: String
        let warningDetail: String
        let whyDetail: String

        var detail: String {
            isGood ? goodDetail : warningDetail
        }

        var riskLabel: String {
            switch severity {
            case .good:
                return "Good"
            case .warning:
                return "Fair"
            case .poor:
                return "Poor"
            }
        }
    }

    private enum OutcomeRowKind: Hashable {
        case calls
        case streaming
        case browsing
    }

    @ViewBuilder
    private func diagnosisSummaryCard(diagnosis: ConnectionDiagnosis) -> some View {
        let summary = diagnosisSummary(diagnosis)
        let toneColor = diagnosisToneColor(summary.tone)

        VStack(alignment: .leading, spacing: 6) {
            Text(summary.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toneColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(summary.detail)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
    }

    private func diagnosisSummary(_ diagnosis: ConnectionDiagnosis) -> DiagnosisSummary {
        guard let internet = diagnosis.internet else {
            return DiagnosisSummary(
                title: "Checking internet health",
                detail: "Running a quick test for speed, delay, and stability.",
                tone: .checking
            )
        }

        let isUnstable = diagnosis.connectionIssue == .bothProblems
            || internet.packetLossPercent >= 1.8
            || internet.loadedLatencyP95Ms >= 320
            || internet.latencyInflation >= 7
        if isUnstable {
            let detail: String
            if internet.packetLossPercent >= 1.8 {
                detail = "Data loss is high, so apps may pause, retry, or drop audio/video."
            } else if internet.loadedLatencyP95Ms >= 320 || internet.latencyInflation >= 7 {
                detail = "Delay spikes are high right now, so calls and interactions may feel jumpy."
            } else {
                detail = "The connection is unstable, so expect buffering or brief dropouts."
            }
            return DiagnosisSummary(
                title: "Internet is unstable right now",
                detail: detail,
                tone: .unstable
            )
        }

        let isMixed = !diagnosis.limitedActivities.isEmpty
            || internet.packetLossPercent >= 0.8
            || internet.loadedLatencyP95Ms >= 220
            || internet.latencyInflation >= 4
            || internet.downloadMbps < 20
            || internet.uploadMbps < 6
        if isMixed {
            return DiagnosisSummary(
                title: "Internet is usable, but not consistent",
                detail: "Light browsing should work, but real-time tasks may stutter at times.",
                tone: .caution
            )
        }

        return DiagnosisSummary(
            title: "Internet looks stable right now",
            detail: "Speed and responsiveness are in a healthy range for everyday use.",
            tone: .healthy
        )
    }

    private func diagnosisToneColor(_ tone: DiagnosisSummary.Tone) -> Color {
        switch tone {
        case .healthy:
            return AppPalette.graphDownload.opacity(0.9)
        case .caution:
            return Color(nsColor: .systemYellow).opacity(0.74)
        case .unstable:
            return Color(nsColor: .systemOrange).opacity(0.74)
        case .checking:
            return .primary
        }
    }

    @ViewBuilder
    private func whatYouCanDoNowCard(diagnosis: ConnectionDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            quickActionRow(
                status: quickActionStatus(
                    kind: .calls,
                    title: "Calls",
                    icon: "video.fill",
                    activities: [.videoCalls],
                    diagnosis: diagnosis,
                    goodDetail: "Looks stable",
                    warningDetail: "May freeze / robotic audio"
                )
            )
            quickActionRow(
                status: quickActionStatus(
                    kind: .streaming,
                    title: "Streaming",
                    icon: "play.rectangle.fill",
                    activities: [.hdStreaming, .fourKStreaming],
                    diagnosis: diagnosis,
                    goodDetail: "Looks stable",
                    warningDetail: "May buffer under load"
                )
            )
            quickActionRow(
                status: quickActionStatus(
                    kind: .browsing,
                    title: "Browsing",
                    icon: "globe",
                    activities: [.browsing],
                    diagnosis: diagnosis,
                    goodDetail: "Should feel quick",
                    warningDetail: "Pages may load slowly"
                )
            )
        }
        .padding(.horizontal, 2)
    }

    private func quickActionStatus(
        kind: OutcomeRowKind,
        title: String,
        icon: String,
        activities: [ConnectionDiagnosis.Activity],
        diagnosis: ConnectionDiagnosis,
        goodDetail: String,
        warningDetail: String
    ) -> QuickActionStatus {
        let statusMap = Dictionary(uniqueKeysWithValues: diagnosis.taskImpactStatuses.map { ($0.activity, $0) })
        let selectedStatuses = activities.compactMap { statusMap[$0] }
        let isGood = selectedStatuses.allSatisfy { $0.works }
        let severity: QuickActionStatus.Severity
        if isGood {
            severity = .good
        } else if selectedStatuses.contains(where: { status in
            guard let reason = status.reason?.lowercased() else { return false }
            return reason.contains("packet loss") || reason.contains("lag spikes")
        }) {
            severity = .poor
        } else {
            severity = .warning
        }

        let whyDetail = quickActionWhy(
            kind: kind,
            diagnosis: diagnosis,
            statuses: selectedStatuses,
            monitor: manager.qualityMonitor
        )

        return QuickActionStatus(
            title: title,
            icon: icon,
            isGood: isGood,
            severity: severity,
            goodDetail: goodDetail,
            warningDetail: warningDetail,
            whyDetail: whyDetail
        )
    }

    @ViewBuilder
    private func quickActionRow(status: QuickActionStatus) -> some View {
        let stateColor = quickActionColor(for: status.severity)
        let borderColor = quickActionBorderColor(for: status.severity)

        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(stateColor)
                    .frame(width: 16, height: 16, alignment: .center)
                    .padding(.top, 1)

                Text(status.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 6)

                riskChip(status: status)
            }

            Text(status.detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(borderColor, lineWidth: 0.8)
        )
    }

    private func quickActionColor(for severity: QuickActionStatus.Severity) -> Color {
        switch severity {
        case .good:
            return AppPalette.graphDownload.opacity(0.9)
        case .warning:
            return Color(nsColor: .systemYellow).opacity(0.78)
        case .poor:
            return Color(nsColor: .systemOrange).opacity(0.78)
        }
    }

    private func quickActionBorderColor(for severity: QuickActionStatus.Severity) -> Color {
        switch severity {
        case .good:
            return AppPalette.graphDownload.opacity(0.22)
        case .warning:
            return Color(nsColor: .systemYellow).opacity(0.24)
        case .poor:
            return Color(nsColor: .systemOrange).opacity(0.26)
        }
    }

    @ViewBuilder
    private func riskChip(status: QuickActionStatus) -> some View {
        let chipColor = quickActionColor(for: status.severity)
        Text(status.riskLabel)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(chipColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(chipColor.opacity(0.13), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(chipColor.opacity(0.25), lineWidth: 0.8)
            )
    }

    private func quickActionWhy(
        kind: OutcomeRowKind,
        diagnosis: ConnectionDiagnosis,
        statuses: [ConnectionDiagnosis.ActivityStatus],
        monitor: NetworkQualityMonitor
    ) -> String {
        let loss = max(monitor.gatewayPacketLossPercent ?? 0, monitor.internetPacketLossPercent ?? 0)
        let jitter = max(monitor.internetJitterMs ?? 0, monitor.loadedJitterMs)
        let throughputVariationPercent = ((monitor.throughputVariation + monitor.responsivenessVariation) / 2) * 100
        let dnsMs = monitor.dnsLookupMs ?? 0

        switch kind {
        case .calls:
            if jitter >= 30 && loss >= 1.0 {
                return "High jitter + packet loss"
            }
            if jitter >= 30 {
                return "Jitter is elevated"
            }
            if loss >= 1.0 {
                return "Packet loss is elevated"
            }
            if statuses.contains(where: { $0.reason?.contains("lag spikes") == true }) {
                return "Latency spikes under load"
            }
            return "Intermittent real-time instability"
        case .streaming:
            if throughputVariationPercent >= 16 {
                return "Download fluctuating"
            }
            if (diagnosis.internet?.downloadMbps ?? 0) < 12 {
                return "Download throughput is low"
            }
            if loss >= 1.5 {
                return "Packet loss affects playback consistency"
            }
            return "Bandwidth varies with network load"
        case .browsing:
            if dnsMs >= 120 {
                return "DNS latency elevated"
            }
            if (diagnosis.internet?.loadedLatencyP95Ms ?? 0) >= 260 {
                return "Page response latency is elevated"
            }
            if loss >= 1.0 {
                return "Packet loss causes page retries"
            }
            return "Response time fluctuates across requests"
        }
    }

    // MARK: - Current Diagnosis

    private var currentDiagnosis: ConnectionDiagnosis {
        let monitor = manager.qualityMonitor
        let signal: ConnectionDiagnosis.SignalQuality?
        if let network = manager.currentNetwork {
            signal = ConnectionDiagnosis.SignalQuality(
                rssi: network.rssi,
                noise: network.noise
            )
        } else {
            signal = nil
        }

        let internet: ConnectionDiagnosis.InternetQuality?
        let canUseInternetMetrics = monitor.hasFreshTestResults || (monitor.isRunning && monitor.successfulRuns > 0)
        if canUseInternetMetrics {
            internet = ConnectionDiagnosis.InternetQuality(
                downloadMbps: monitor.downloadMbps,
                uploadMbps: monitor.uploadMbps,
                rpm: monitor.responsiveness,
                loadedLatencyP95Ms: monitor.loadedLatencyP95Ms,
                latencyInflation: monitor.latencyInflation,
                packetLossPercent: max(monitor.gatewayPacketLossPercent ?? 0, monitor.internetPacketLossPercent ?? 0),
                confidenceScore: monitor.confidenceScore,
                gatewayLatencyMs: monitor.gatewayLatencyMs,
                internetLatencyMs: monitor.internetLatencyMs,
                observedSustainedDownloadMbps: monitor.sustainedDownloadMbps,
                observedSustainedUploadMbps: monitor.sustainedUploadMbps,
                observedHDStreamingTraffic: monitor.observedHDStreamingTraffic,
                observed4KStreamingTraffic: monitor.observed4KStreamingTraffic
            )
        } else {
            internet = nil
        }

        return ConnectionDiagnosis(
            signal: signal,
            internet: internet,
            connectionIssue: monitor.connectionIssue
        )
    }

    private func formatSpeedNumber(_ mbps: Double) -> String {
        let value = max(0, mbps)
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        if value >= 10 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func formatSpeedMbps(_ mbps: Double) -> String {
        "\(formatSpeedNumber(mbps)) M"
    }

    private func formatReliabilityLabel(_ monitor: NetworkQualityMonitor) -> String {
        switch monitor.reliabilityLabel.lowercased() {
        case "reliable":
            return "Reliable"
        case "okay":
            return "Good enough"
        default:
            return "Unreliable"
        }
    }

    private func diagnosisSeverity(for diagnosis: ConnectionDiagnosis, internet: ConnectionDiagnosis.InternetQuality) -> (icon: String, color: Color) {
        if diagnosis.connectionIssue == .bothProblems || internet.packetLossPercent >= 2.5 {
            return ("❌", AppPalette.critical)
        }
        if diagnosis.connectionIssue == .none && diagnosis.limitedActivities.isEmpty {
            return ("✅", AppPalette.accent)
        }
        return ("⚠️", AppPalette.accentMedium)
    }

    @ViewBuilder
    private func speedValueCompact(value: Double, arrow: String, color: Color, helpText: String) -> some View {
        let speedNumber = formatSpeedNumber(value)

        HStack(spacing: 1) {
            HStack(spacing: 0) {
                ForEach(Array(speedNumber.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    let character = item.element

                    ZStack(alignment: .leading) {
                        Text(String(character))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .id("\(index)-\(character)")
                            .transition(
                                .asymmetric(
                                    insertion: .offset(y: 3).combined(with: .opacity),
                                    removal: .offset(y: -3).combined(with: .opacity)
                                )
                            )
                    }
                    .frame(width: 10, height: 21, alignment: .leading)
                    .clipped()
                }
            }
            .frame(height: 21, alignment: .leading)
            .clipped()
            .animation(.easeInOut(duration: 0.18), value: speedNumber)

            Text("M")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Image(systemName: arrow)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.58), lineWidth: 0.7)
        )
        .frame(minWidth: 78, alignment: .leading)
        .help(helpText)
    }

    @ViewBuilder
    private func taskImpactChip(_ status: ConnectionDiagnosis.ActivityStatus) -> some View {
        let state = chipState(for: status)
        HStack(spacing: 4) {
            Text(chipSymbol(for: state))
                .font(.system(size: 10))
            Text(status.activity.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(chipTextColor(for: state))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(chipBackgroundColor(for: state))
        .overlay(
            Capsule()
                .stroke(chipBorderColor(for: state), lineWidth: 0.8)
        )
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func statusTakeawayPill(diagnosis: ConnectionDiagnosis) -> some View {
        let takeaway = primaryTakeaway(diagnosis: diagnosis)
        HStack(alignment: .top, spacing: 7) {
            Text(takeaway.icon)
                .font(.system(size: 12, weight: .semibold))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(takeaway.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = takeaway.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(takeaway.tint.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(takeaway.tint.opacity(0.45), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func primaryTakeaway(diagnosis: ConnectionDiagnosis) -> (title: String, subtitle: String?, icon: String, tint: Color) {
        guard let internet = diagnosis.internet else {
            return (
                title: "Checking your connection",
                subtitle: "We need a few more seconds to finish the check.",
                icon: "⏳",
                tint: .secondary
            )
        }

        let title: String
        let subtitle: String
        switch diagnosis.connectionIssue {
        case .ispProblem:
            title = "Internet looks unstable"
            subtitle = "Your Wi-Fi signal looks good"
        case .wifiProblem:
            title = "Wi-Fi signal looks unstable"
            subtitle = "Your internet service looks okay"
        case .bothProblems:
            title = "Connection is unstable in two places"
            subtitle = "Your Wi-Fi and internet service both need attention"
        case .none:
            if internet.packetLossPercent >= 1.0 || internet.loadedLatencyP95Ms >= 260 || internet.latencyInflation >= 5 {
                title = "Internet looks unstable"
                subtitle = "Your Wi-Fi signal looks good"
            } else if !diagnosis.limitedActivities.isEmpty {
                title = "Connection is okay, but not consistent"
                subtitle = "Things can slow down when your network is busy"
            } else {
                title = "Connection looks healthy"
                subtitle = "Your Wi-Fi and internet both look good"
            }
        }

        let severity = diagnosisSeverity(for: diagnosis, internet: internet)
        return (title, subtitle, severity.icon, severity.color)
    }

    @ViewBuilder
    private func twoHopModelSection(diagnosis: ConnectionDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            hopStatusRow(
                title: "Mac \u{2192} Router (Wi-Fi)",
                label: wifiHopLabel(diagnosis),
                icon: wifiHopIcon(diagnosis),
                color: wifiHopColor(diagnosis)
            )
            hopStatusRow(
                title: "Router \u{2192} Internet (ISP)",
                label: internetHopLabel(diagnosis),
                icon: internetHopIcon(diagnosis),
                color: internetHopColor(diagnosis)
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.68), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func hopStatusRow(title: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title + ":")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(icon)
                .font(.system(size: 10))
            Spacer(minLength: 0)
        }
    }

    private func wifiHopLabel(_ diagnosis: ConnectionDiagnosis) -> String {
        guard let signal = diagnosis.signal else { return "Unknown" }
        return signal.label
    }

    private func wifiHopIcon(_ diagnosis: ConnectionDiagnosis) -> String {
        guard let signal = diagnosis.signal else { return "⚪" }
        switch signal.grade {
        case .excellent, .good:
            return "✅"
        case .fair:
            return "⚠️"
        case .poor, .bad:
            return "❌"
        }
    }

    private func wifiHopColor(_ diagnosis: ConnectionDiagnosis) -> Color {
        guard let signal = diagnosis.signal else { return .secondary }
        switch signal.grade {
        case .excellent, .good:
            return AppPalette.accent
        case .fair:
            return AppPalette.accentMedium
        case .poor, .bad:
            return AppPalette.critical
        }
    }

    private func internetHopLabel(_ diagnosis: ConnectionDiagnosis) -> String {
        guard let internet = diagnosis.internet else { return "Not tested yet" }
        if internet.packetLossPercent >= 1.5 || internet.loadedLatencyP95Ms >= 260 || internet.latencyInflation >= 5 {
            return "Unstable"
        }
        if internet.downloadMbps < 12 || internet.uploadMbps < 4 {
            return "Slow"
        }
        return "Stable"
    }

    private func internetHopIcon(_ diagnosis: ConnectionDiagnosis) -> String {
        let label = internetHopLabel(diagnosis)
        if label == "Stable" { return "✅" }
        if label == "Slow" { return "⚠️" }
        if label == "Not tested yet" { return "⚪" }
        return "⚠️"
    }

    private func internetHopColor(_ diagnosis: ConnectionDiagnosis) -> Color {
        let label = internetHopLabel(diagnosis)
        if label == "Stable" { return AppPalette.accent }
        if label == "Slow" { return AppPalette.accentMedium }
        if label == "Not tested yet" { return .secondary }
        return AppPalette.accentMedium
    }

    private enum TaskChipState {
        case good
        case warning
        case bad
    }

    private func chipState(for status: ConnectionDiagnosis.ActivityStatus) -> TaskChipState {
        guard !status.works else { return .good }
        let reason = status.reason?.lowercased() ?? ""
        if reason.contains("packet loss") || reason.contains("slow & laggy") {
            return .bad
        }
        return .warning
    }

    private func chipSymbol(for state: TaskChipState) -> String {
        switch state {
        case .good: return "✅"
        case .warning: return "⚠️"
        case .bad: return "❌"
        }
    }

    private func chipTextColor(for state: TaskChipState) -> Color {
        switch state {
        case .good:
            return .primary
        case .warning:
            return AppPalette.accent
        case .bad:
            return AppPalette.critical
        }
    }

    private func chipBackgroundColor(for state: TaskChipState) -> Color {
        switch state {
        case .good:
            return AppPalette.accentFaint
        case .warning:
            return AppPalette.accentBackground
        case .bad:
            return AppPalette.criticalBackground
        }
    }

    private func chipBorderColor(for state: TaskChipState) -> Color {
        switch state {
        case .good:
            return AppPalette.accentMedium
        case .warning:
            return AppPalette.accentSoft
        case .bad:
            return AppPalette.criticalSoft
        }
    }

    @ViewBuilder
    private func connectionBreakdownSection(diagnosis: ConnectionDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let monitor = manager.qualityMonitor
            let path = pathDiagnosis(monitor: monitor, diagnosis: diagnosis)

            diagnosticsSectionCard(title: "Likely issue source", icon: "scope") {
                metricRow("Path", path.label, icon: "arrow.triangle.branch", tone: path.tone)
            }

            diagnosticsSectionCard(title: "Wi-Fi side", icon: "wifi") {
                metricRow("RSSI / noise", wifiSignalAndNoiseLabel(), icon: "antenna.radiowaves.left.and.right", tone: signalTone(diagnosis))
                metricRow("Band", manager.currentNetwork?.band.displayName ?? "--", icon: "dot.scope")
                metricRow("Channel width", manager.currentNetwork.map { "\($0.channelWidth) MHz (ch \($0.channel))" } ?? "--", icon: "point.3.connected.trianglepath.dotted")
                metricRow("PHY rate", manager.transmitRateMbps.map { String(format: "%.0f Mbps", $0) } ?? "--", icon: "bolt.horizontal.circle.fill")
                metricRow("Router ping", formatOptionalMs(monitor.gatewayLatencyMs), icon: "dot.radiowaves.left.and.right", tone: pingTone(monitor.gatewayLatencyMs))
            }

            diagnosticsSectionCard(title: "Internet side", icon: "globe") {
                metricRow("DNS response", formatOptionalMs(monitor.dnsLookupMs), icon: "magnifyingglass", tone: dnsTone(monitor.dnsLookupMs))
                metricRow("ISP/public ping", formatOptionalMs(monitor.internetLatencyMs), icon: "network.badge.shield.half.filled", tone: pingTone(monitor.internetLatencyMs))
                metricRow(
                    "Packet loss to router",
                    formatOptionalPercent(monitor.gatewayPacketLossPercent),
                    icon: "point.3.connected.trianglepath.dotted",
                    tone: packetLossTone(monitor.gatewayPacketLossPercent)
                )
                metricRow(
                    "Packet loss to internet",
                    formatOptionalPercent(monitor.internetPacketLossPercent),
                    icon: "network",
                    tone: packetLossTone(monitor.internetPacketLossPercent)
                )
            }
        }
    }

    private func pathDiagnosis(
        monitor: NetworkQualityMonitor,
        diagnosis: ConnectionDiagnosis
    ) -> (label: String, tone: MetricTone) {
        switch monitor.connectionIssue {
        case .wifiProblem:
            if let signal = diagnosis.signal, signal.grade >= .poor {
                return ("Wi-Fi weak signal / local interference", .bad)
            }
            return ("Wi-Fi/local network issue", .warning)
        case .ispProblem:
            return ("ISP/public internet path unstable", .warning)
        case .bothProblems:
            return ("Both Wi-Fi and ISP path have issues", .bad)
        case .none:
            if monitor.gatewayLatencyMs == nil && monitor.internetLatencyMs == nil {
                return ("Not enough path data yet", .muted)
            }
            return ("No clear split; path looks stable", .good)
        }
    }

    private func wifiSignalAndNoiseLabel() -> String {
        guard let current = manager.currentNetwork else { return "--" }
        return "\(current.rssi) / \(current.noise) dBm"
    }

    @ViewBuilder
    private func diagnosticsSectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)

            VStack(alignment: .leading, spacing: 2) {
                content()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(AppPalette.borderSoft.opacity(0.62), lineWidth: 0.7)
            )
        }
    }

    @ViewBuilder
    private func metricRow(_ title: String, _ value: String, icon: String, tone: MetricTone = .neutral) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(metricToneColor(tone).opacity(0.9))
                .frame(width: 11)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            if let info = metricInfo(for: title) {
                MetricInfoPopoverButton(info: info)
            }

            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(metricToneColor(tone))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 1)
    }

    private struct MetricInfo: Hashable {
        let title: String
        let explanation: String
    }

    private struct MetricInfoPopoverButton: View {
        let info: MetricInfo
        @State private var isPresented = false

        var body: some View {
            Button(action: { isPresented.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPresented, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(info.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(info.explanation)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(width: 250, alignment: .leading)
            }
        }
    }

    private func metricInfo(for title: String) -> MetricInfo? {
        switch title {
        case "Latency":
            return MetricInfo(
                title: "Latency",
                explanation: "Latency is how long your connection takes to respond. Higher latency makes apps feel delayed, especially calls, gaming, and live interactions."
            )
        case "Jitter":
            return MetricInfo(
                title: "Jitter",
                explanation: "Jitter is how much your latency jumps around from moment to moment. Even with decent speed, high jitter causes choppy calls and unstable streaming."
            )
        case "Packet loss":
            return MetricInfo(
                title: "Packet loss",
                explanation: "Packet loss means some data never arrives and must be resent. That leads to glitches, buffering, and dropped moments during calls or games."
            )
        case "Down / Up":
            return MetricInfo(
                title: "Download and upload",
                explanation: "Download affects streaming and browsing, while upload affects video calls, backups, and sending files. Balanced speeds keep both directions feeling smooth."
            )
        case "Router ping":
            return MetricInfo(
                title: "Router ping",
                explanation: "Router ping measures delay on your local Wi-Fi link only. If this is high, the issue is usually inside your home network, not your ISP."
            )
        case "Path":
            return MetricInfo(
                title: "Likely issue source",
                explanation: "This compares local router metrics and internet path metrics to estimate where instability is coming from: your Wi-Fi side, ISP/public path, or both."
            )
        case "RSSI / noise":
            return MetricInfo(
                title: "RSSI and noise",
                explanation: "RSSI is signal strength and noise is background interference. Weak signal or high noise usually points to a local Wi-Fi issue."
            )
        case "Channel width":
            return MetricInfo(
                title: "Channel width",
                explanation: "Wider channels can increase throughput, but in crowded environments they can also increase interference and instability."
            )
        case "Internet ping":
            return MetricInfo(
                title: "Internet ping",
                explanation: "Internet ping measures delay after traffic leaves your router and reaches the wider internet. If this is high while router ping is low, your ISP path is likely the bottleneck."
            )
        case "ISP/public ping":
            return MetricInfo(
                title: "ISP/public ping",
                explanation: "This is the end-to-end ping to a public host. It acts as an ISP/public-path proxy after traffic leaves your local router."
            )
        case "DNS time":
            return MetricInfo(
                title: "DNS time",
                explanation: "DNS time is how long it takes to translate a site name into an address. Slow DNS makes pages feel slow to start, even when speed tests look good."
            )
        case "DNS response":
            return MetricInfo(
                title: "DNS response",
                explanation: "DNS response time is name lookup delay. Elevated DNS can make websites feel slow even when throughput is fine."
            )
        case "Packet loss to router":
            return MetricInfo(
                title: "Packet loss to router",
                explanation: "Loss to router reflects local Wi-Fi/link reliability. If this is elevated, the problem is likely inside your local network."
            )
        case "Packet loss to internet":
            return MetricInfo(
                title: "Packet loss to internet",
                explanation: "Loss to internet reflects issues after traffic leaves your local router. If this is elevated while router loss is low, ISP/public path is likely unstable."
            )
        case "Signal":
            return MetricInfo(
                title: "Signal",
                explanation: "Signal summarizes how healthy your current Wi-Fi radio link is. Better signal usually means fewer drops and more stable speed."
            )
        case "RSSI":
            return MetricInfo(
                title: "RSSI",
                explanation: "RSSI is raw Wi-Fi signal strength in dBm. Values closer to zero are stronger and usually produce better stability."
            )
        case "SNR":
            return MetricInfo(
                title: "SNR",
                explanation: "SNR compares your signal against background noise. Higher SNR means cleaner communication and fewer retransmissions."
            )
        case "Band":
            return MetricInfo(
                title: "Band",
                explanation: "Band shows which Wi-Fi frequency you’re using. 5 or 6 GHz is often faster, while 2.4 GHz reaches farther but can be more crowded."
            )
        case "Channel":
            return MetricInfo(
                title: "Channel",
                explanation: "Channel is the lane your Wi-Fi uses; width shows how wide that lane is. Crowded channels can reduce stability and increase interference."
            )
        case "PHY rate":
            return MetricInfo(
                title: "PHY rate",
                explanation: "PHY rate is the raw radio link rate between your Mac and router. Real app speed is usually lower because of overhead, congestion, and internet limits."
            )
        case "Jitter history":
            return MetricInfo(
                title: "Jitter history",
                explanation: "This trend shows whether jitter spikes are occasional or persistent. Frequent spikes are a common reason calls feel inconsistent."
            )
        case "Packet loss history":
            return MetricInfo(
                title: "Packet loss history",
                explanation: "This trend shows whether dropped packets happen repeatedly. Repeated loss is a strong signal of unstable connection quality."
            )
        default:
            return nil
        }
    }

    private enum MetricTone {
        case neutral
        case good
        case warning
        case bad
        case muted
    }

    private func metricToneColor(_ tone: MetricTone) -> Color {
        switch tone {
        case .neutral:
            return .primary
        case .good:
            return AppPalette.accent
        case .warning:
            return AppPalette.accentMedium
        case .bad:
            return AppPalette.critical
        case .muted:
            return .secondary
        }
    }

    private func throughputTone(_ mbps: Double) -> MetricTone {
        if mbps >= 50 { return .good }
        if mbps >= 15 { return .neutral }
        if mbps >= 5 { return .warning }
        return .bad
    }

    private func callDelayTone(_ monitor: NetworkQualityMonitor) -> MetricTone {
        let latency = monitor.internetLatencyMs ?? monitor.loadedLatencyP50Ms
        if latency <= 0 { return .muted }
        if latency < 90 { return .good }
        if latency < 170 { return .warning }
        return .bad
    }

    private func jitterTone(_ monitor: NetworkQualityMonitor) -> MetricTone {
        let jitter = monitor.internetJitterMs ?? monitor.loadedJitterMs
        if jitter <= 0 { return .muted }
        if jitter < 20 { return .good }
        if jitter < 50 { return .warning }
        return .bad
    }

    private func packetLossTone(_ monitor: NetworkQualityMonitor) -> MetricTone {
        let loss = max(monitor.gatewayPacketLossPercent ?? 0, monitor.internetPacketLossPercent ?? 0)
        if loss < 0.5 { return .good }
        if loss < 2.0 { return .warning }
        return .bad
    }

    private func packetLossTone(_ value: Double?) -> MetricTone {
        guard let value, value >= 0 else { return .muted }
        if value < 0.5 { return .good }
        if value < 2.0 { return .warning }
        return .bad
    }

    private func pingTone(_ value: Double?) -> MetricTone {
        guard let value, value > 0 else { return .muted }
        if value < 70 { return .good }
        if value < 140 { return .warning }
        return .bad
    }

    private func dnsTone(_ value: Double?) -> MetricTone {
        guard let value, value > 0 else { return .muted }
        if value < 30 { return .good }
        if value < 80 { return .warning }
        return .bad
    }

    private func signalTone(_ diagnosis: ConnectionDiagnosis) -> MetricTone {
        guard let signal = diagnosis.signal else { return .muted }
        switch signal.grade {
        case .excellent, .good:
            return .good
        case .fair:
            return .warning
        case .poor, .bad:
            return .bad
        }
    }

    private func latencyLabel(_ monitor: NetworkQualityMonitor) -> String {
        let latency = monitor.internetLatencyMs ?? monitor.loadedLatencyP50Ms

        if latency <= 0 {
            return "--"
        }
        return String(format: "%.0f ms", max(0, latency))
    }

    private func jitterLabel(_ monitor: NetworkQualityMonitor) -> String {
        let jitter = monitor.internetJitterMs ?? monitor.loadedJitterMs
        if jitter <= 0 {
            return "--"
        }
        return String(format: "%.0f ms", max(0, jitter))
    }

    private func packetLossLabel(_ monitor: NetworkQualityMonitor) -> String {
        let loss = max(monitor.gatewayPacketLossPercent ?? 0, monitor.internetPacketLossPercent ?? 0)
        return String(format: "%.1f%%", max(0, loss))
    }

    private func formatOptionalMs(_ value: Double?) -> String {
        guard let value, value > 0 else { return "--" }
        return String(format: "%.0f ms", value)
    }

    private func formatOptionalPercent(_ value: Double?) -> String {
        guard let value, value >= 0 else { return "--" }
        return String(format: "%.1f%%", value)
    }

    private func jitterHistoryLabel(_ monitor: NetworkQualityMonitor) -> String {
        let recent = monitor.jitterHistoryMs.suffix(5)
        guard !recent.isEmpty else { return "--" }
        return recent.map { String(format: "%.0f", $0) }.joined(separator: " · ") + " ms"
    }

    private func packetLossHistoryLabel(_ monitor: NetworkQualityMonitor) -> String {
        let recent = monitor.packetLossHistoryPercent.suffix(5)
        guard !recent.isEmpty else { return "--" }
        return recent.map { String(format: "%.1f", $0) }.joined(separator: " · ") + " %"
    }

    private func copyDiagnosticsToClipboard() {
        let monitor = manager.qualityMonitor
        let current = manager.currentNetwork
        var lines: [String] = []

        lines.append("MacWiFi Diagnostics")
        lines.append("SSID: \(current?.ssid ?? "Not connected")")
        lines.append("Band: \(current?.band.displayName ?? "--")")
        lines.append("Signal: \(current.map { "\($0.rssi) dBm" } ?? "--")")
        lines.append("Noise: \(current.map { "\($0.noise) dBm" } ?? "--")")
        lines.append("SNR: \(current.map { "\($0.snr) dB" } ?? "--")")
        lines.append("Channel: \(current.map { "\($0.channel) (\($0.channelWidth) MHz)" } ?? "--")")
        lines.append("PHY rate: \(manager.transmitRateMbps.map { String(format: "%.0f Mbps", $0) } ?? "--")")
        lines.append("MCS: Not exposed by CoreWLAN")
        lines.append("Download: \(formatSpeedMbps(monitor.downloadMbps))")
        lines.append("Upload: \(formatSpeedMbps(monitor.uploadMbps))")
        lines.append("Router ping: \(formatOptionalMs(monitor.gatewayLatencyMs))")
        lines.append("Internet ping: \(formatOptionalMs(monitor.internetLatencyMs))")
        lines.append("DNS time: \(formatOptionalMs(monitor.dnsLookupMs))")
        lines.append("Jitter: \(jitterLabel(monitor))")
        lines.append("Packet loss: \(packetLossLabel(monitor))")
        lines.append("Jitter history: \(jitterHistoryLabel(monitor))")
        lines.append("Packet loss history: \(packetLossHistoryLabel(monitor))")
        lines.append(formatReliabilityLabel(monitor))
        lines.append("Trend: \(monitor.reliabilityTrendText)")
        lines.append("Tested: \(monitor.lastTestTime.map { relativeTimeString(since: $0) } ?? "--")")

        let payload = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(payload, forType: .string)

        didCopyDiagnostics = true
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            didCopyDiagnostics = false
        }
    }

    // MARK: - Live Speed Graph

    private var liveSpeedGraph: some View {
        TimelineView(.animation(minimumInterval: manager.qualityMonitor.visualUpdateIntervalSeconds)) { _ in
            Canvas { context, size in
                let history = smoothedHistory(manager.qualityMonitor.speedHistory)
                guard history.count >= 2 else { return }

                let observedPeak = history.reduce(0.0) { partial, point in
                    max(partial, max(point.dl, point.ul))
                }
                let referenceScale = max(manager.qualityMonitor.graphScaleMbps, observedPeak)
                // Keep headroom so peaks don't clip against the top edge.
                let maxSpeed = max(referenceScale * 1.14, 10)
                let width = size.width
                let height = size.height
                let stepX = width / CGFloat(max(history.count - 1, 1))
                let plotTop = height * 0.14
                let plotBottom = height * 0.90
                let plotHeight = max(1, plotBottom - plotTop)

                // Subtle chart guides for scanability.
                for marker in [0.22, 0.42, 0.62, 0.82] {
                    let y = height * marker
                    var guide = Path()
                    guide.move(to: CGPoint(x: 0, y: y))
                    guide.addLine(to: CGPoint(x: width, y: y))
                    context.stroke(
                        guide,
                        with: .color(AppPalette.borderSoft.opacity(0.34)),
                        style: StrokeStyle(lineWidth: 0.7, lineCap: .round, dash: [3, 4])
                    )
                }

                let dlPoints = history.enumerated().map { (i, point) -> CGPoint in
                    let normalized = max(0, min(1, point.dl / maxSpeed))
                    return CGPoint(
                        x: CGFloat(i) * stepX,
                        y: plotTop + plotHeight * (1 - CGFloat(normalized))
                    )
                }

                let ulPoints = history.enumerated().map { (i, point) -> CGPoint in
                    let normalized = max(0, min(1, point.ul / maxSpeed))
                    return CGPoint(
                        x: CGFloat(i) * stepX,
                        y: plotTop + plotHeight * (1 - CGFloat(normalized))
                    )
                }

                let dlLine = smoothPath(through: dlPoints)
                let ulLine = smoothPath(through: ulPoints)

                var dlFill = dlLine
                dlFill.addLine(to: CGPoint(x: dlPoints.last!.x, y: height))
                dlFill.addLine(to: CGPoint(x: dlPoints[0].x, y: height))
                dlFill.closeSubpath()
                context.fill(dlFill, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: AppPalette.graphDownload.opacity(0.26), location: 0),
                        .init(color: AppPalette.graphDownload.opacity(0.12), location: 0.48),
                        .init(color: AppPalette.graphDownload.opacity(0.0), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: height)
                ))

                var ulFill = ulLine
                ulFill.addLine(to: CGPoint(x: ulPoints.last!.x, y: height))
                ulFill.addLine(to: CGPoint(x: ulPoints[0].x, y: height))
                ulFill.closeSubpath()
                context.fill(ulFill, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: AppPalette.graphUpload.opacity(0.11), location: 0),
                        .init(color: AppPalette.graphUpload.opacity(0.06), location: 0.52),
                        .init(color: AppPalette.graphUpload.opacity(0.0), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: height)
                ))

                // Glow + primary strokes.
                context.stroke(
                    dlLine,
                    with: .color(AppPalette.graphDownload.opacity(0.2)),
                    style: StrokeStyle(lineWidth: 3.8, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    ulLine,
                    with: .color(AppPalette.graphUpload.opacity(0.17)),
                    style: StrokeStyle(lineWidth: 3.1, lineCap: .round, lineJoin: .round)
                )

                context.stroke(
                    dlLine,
                    with: .color(AppPalette.graphDownload),
                    style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    ulLine,
                    with: .color(AppPalette.graphUpload),
                    style: StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round)
                )

                // Current-point markers.
                if let dlPoint = dlPoints.last {
                    let outer = CGRect(x: dlPoint.x - 4.8, y: dlPoint.y - 4.8, width: 9.6, height: 9.6)
                    let inner = CGRect(x: dlPoint.x - 2.6, y: dlPoint.y - 2.6, width: 5.2, height: 5.2)
                    context.fill(Path(ellipseIn: outer), with: .color(AppPalette.graphDownload.opacity(0.35)))
                    context.fill(Path(ellipseIn: inner), with: .color(AppPalette.graphDownload))
                }

                if let ulPoint = ulPoints.last {
                    let outer = CGRect(x: ulPoint.x - 4.2, y: ulPoint.y - 4.2, width: 8.4, height: 8.4)
                    let inner = CGRect(x: ulPoint.x - 2.2, y: ulPoint.y - 2.2, width: 4.4, height: 4.4)
                    context.fill(Path(ellipseIn: outer), with: .color(AppPalette.graphUpload.opacity(0.32)))
                    context.fill(Path(ellipseIn: inner), with: .color(AppPalette.graphUpload))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func smoothedHistory(_ samples: [(dl: Double, ul: Double)]) -> [(dl: Double, ul: Double)] {
        guard samples.count >= 3 else { return samples }

        var result: [(dl: Double, ul: Double)] = []
        result.reserveCapacity(samples.count)

        for i in samples.indices {
            let start = max(samples.startIndex, i - 1)
            let end = min(samples.endIndex - 1, i + 1)
            let window = samples[start...end]

            let weighted = window.enumerated().reduce((dl: 0.0, ul: 0.0, w: 0.0)) { partial, entry in
                let point = entry.element
                let idx = start + entry.offset
                let weight = (idx == i) ? 0.6 : 0.2
                return (
                    dl: partial.dl + point.dl * weight,
                    ul: partial.ul + point.ul * weight,
                    w: partial.w + weight
                )
            }

            result.append((dl: weighted.dl / weighted.w, ul: weighted.ul / weighted.w))
        }

        return result
    }

    /// Catmull-Rom to Bezier conversion with safe control-point distance.
    private func smoothPath(through points: [CGPoint]) -> Path {
        guard points.count >= 2 else { return Path() }

        var path = Path()
        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[0]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

            // 1/6 is the standard Catmull-Rom -> cubic Bezier factor.
            let factor: CGFloat = 1.0 / 6.0

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * factor,
                y: p1.y + (p2.y - p0.y) * factor
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * factor,
                y: p2.y - (p3.y - p1.y) * factor
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        return path
    }

    private var suggestedNetwork: Network? {
        guard let current = manager.currentNetwork else { return nil }
        return manager.networks.first { network in
            network.isKnown &&
            network.ssid != current.ssid &&
            network.qualityScore > current.qualityScore + 15
        }
    }

    // MARK: - Networks List

    @ViewBuilder
    private var networksList: some View {
        let personalHotspotSSIDs = Set(manager.personalHotspots.map { $0.ssid.lowercased() })
        let knownNetworks = manager.networks.filter {
            $0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
                && !$0.isHiddenSSID
        }
        let otherNetworks = manager.networks.filter {
            !$0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
                && !$0.isHiddenSSID
        }

        VStack(alignment: .leading, spacing: 0) {
            if !manager.personalHotspots.isEmpty {
                sectionHeaderWithTime("Personal Hotspots", showScanInfo: false)
                ForEach(manager.personalHotspots) { hotspot in
                    personalHotspotRow(hotspot)
                }
            }

            // Known networks section
            if !knownNetworks.isEmpty {
                sectionHeaderWithTime("Known Networks", showScanInfo: false)
                ForEach(knownNetworks) { network in
                    networkRow(network)
                }
            }

            // Other networks section
            if manager.currentNetwork != nil {
                // Connected: show collapsible row (Apple-style)
                otherNetworksRow(count: otherNetworks.count)

                if showOtherNetworks && !otherNetworks.isEmpty {
                    ForEach(otherNetworks) { network in
                        networkRow(network)
                    }
                }
            } else {
                // Not connected: show all networks expanded
                if !otherNetworks.isEmpty || manager.isScanning {
                    sectionHeaderWithTime("Other Networks", showScanInfo: true)
                    ForEach(otherNetworks) { network in
                        networkRow(network)
                    }
                }

                // Status messages only when not connected
                statusView
            }
        }
    }

    // MARK: - Other Networks Row (Apple-style collapsed)

    private func otherNetworksRow(count: Int) -> some View {
        HStack(spacing: 6) {
            Button(action: toggleOtherNetworks) {
                HStack {
                    Text("Other Networks")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.001))
            }
            .buttonStyle(.plain)

            if manager.isScanning {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.7)
                    .frame(width: 16)
            } else {
                Button(action: { manager.scan(force: true) }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Scan again")
                .frame(width: 16)
            }

            Button(action: toggleOtherNetworks) {
                Image(systemName: showOtherNetworks ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 10)
    }

    private func toggleOtherNetworks() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showOtherNetworks.toggle()
        }
        if showOtherNetworks && manager.networks.isEmpty {
            manager.scan()
        }
    }

    // MARK: - Section Header

    private func sectionHeaderWithTime(_ title: String, showScanInfo: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if showScanInfo {
                if manager.isScanning {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                } else {
                    Button(action: { manager.scan(force: true) }) {
                        HStack(spacing: 4) {
                            if let scanTime = manager.lastScanTime {
                                Text(scanTimeAgo(scanTime))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private func scanTimeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 5 {
            return "Just now"
        } else if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        }
    }

    // MARK: - Network Row

    @ViewBuilder
    private func networkRow(_ network: Network) -> some View {
        let isConnecting = manager.connectingToSSID == network.ssid && manager.connectionState.isConnecting
        NetworkRow(
            network: network,
            isConnected: false,
            isConnecting: isConnecting,
            connectionStatus: isConnecting ? manager.connectionState.displayText : nil,
            onTap: { handleNetworkTap(network) }
        )
    }

    @ViewBuilder
    private func personalHotspotRow(_ hotspot: WiFiManager.PersonalHotspot) -> some View {
        let isConnecting = manager.connectingToSSID == hotspot.ssid && manager.connectionState.isConnecting

        Button(action: {
            handlePersonalHotspotTap(hotspot)
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppPalette.accentBackground.opacity(colorScheme == .dark ? 0.30 : 0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppPalette.accent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(hotspot.ssid)
                        .font(.system(size: 13.5, weight: .semibold))
                        .lineLimit(1)

                    Text(hotspotSubtitle(hotspot))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                if isConnecting {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                } else if hotspot.isAvailableNow {
                    HStack(spacing: 6) {
                        if #available(macOS 13.0, *), let signal = hotspotSignalVariableValue(hotspot) {
                            Image(systemName: "wifi", variableValue: signal)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "wifi")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        if let band = hotspot.matchedNetwork?.band.displayName {
                            Text(band.replacingOccurrences(of: ".0", with: ""))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Nearby")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private func hotspotSubtitle(_ hotspot: WiFiManager.PersonalHotspot) -> String {
        if hotspot.isAvailableNow {
            if let matched = hotspot.matchedNetwork {
                return "Available now · \(matched.signalQuality) signal"
            }
            return "Available now"
        }
        return "Saved hotspot"
    }

    private func hotspotSignalVariableValue(_ hotspot: WiFiManager.PersonalHotspot) -> Double? {
        guard let bars = hotspot.matchedNetwork?.signalBars else { return nil }
        switch bars {
        case 4: return 1.0
        case 3: return 0.75
        case 2: return 0.55
        case 1: return 0.35
        default: return 0.15
        }
    }

    // MARK: - Status View

    @ViewBuilder
    private var locationPermissionPrimaryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppPalette.accent)

                Text("Location Access Needed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Text("MacWiFi needs Location Services to discover nearby Wi-Fi networks. Turn it on to scan, diagnose, and show accurate connection details.")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Privacy & Security…") {
                openLocationServicesSettings()
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundStyle(AppPalette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.84), lineWidth: 1)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusView: some View {
        if manager.isScanning && manager.networks.isEmpty {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Scanning...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        } else if manager.networks.isEmpty && manager.error == nil && !manager.isScanning {
            Text("No networks found")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(10)
        }

        if let error = manager.error {
            if isLocationServicesError {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location access is required to show nearby Wi-Fi networks.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)

                    Button("Open Privacy & Security…") {
                        openLocationServicesSettings()
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(AppPalette.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppPalette.borderSoft.opacity(0.8), lineWidth: 1)
                )
                .padding(.horizontal, 8)
            } else {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(AppPalette.critical)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppPalette.criticalBackground.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()

            Button("Wi-Fi Settings...") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func handleNetworkTap(_ network: Network) {
        if network.security.requiresPassword && !network.isKnown {
            selectedNetwork = network
            password = ""
            passwordPromptError = nil
            isSubmittingPassword = false
            showPasswordPrompt = true
        } else {
            connectToNetwork(network, password: nil)
        }
    }

    private func connectWithPassword() {
        guard let network = selectedNetwork else { return }
        passwordPromptError = nil
        isSubmittingPassword = true

        connectToNetwork(network, password: password) { result in
            isSubmittingPassword = false
            switch result {
            case .success:
                resetPasswordPrompt()
            case .failure:
                passwordPromptError = manager.error ?? "Unable to join this network. Check the password and try again."
            }
        }
    }

    private var isLocationServicesError: Bool {
        (manager.error ?? "").localizedCaseInsensitiveContains("location services")
    }

    private func openLocationServicesSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_LocationServices",
            "x-apple.systempreferences:com.apple.preference.security"
        ]

        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func resetPasswordPrompt() {
        showPasswordPrompt = false
        selectedNetwork = nil
        password = ""
        passwordPromptError = nil
        isSubmittingPassword = false
    }

    private func connectToNetwork(
        _ network: Network,
        password: String?,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        // Immediate UI feedback
        manager.connectingToSSID = network.ssid
        manager.connectionState = .findingNetwork
        manager.error = nil

        Task { @MainActor in
            do {
                try await manager.connect(to: network, password: password)
                completion?(.success(()))
            } catch {
                manager.error = error.localizedDescription
                completion?(.failure(error))
            }
        }
    }

    private func handlePersonalHotspotTap(_ hotspot: WiFiManager.PersonalHotspot) {
        if let matched = hotspot.matchedNetwork {
            connectToNetwork(matched, password: nil)
            return
        }

        let syntheticNetwork = Network(
            id: "hotspot-\(hotspot.ssid)",
            ssid: hotspot.ssid,
            rssi: -65,
            channel: 0,
            security: .wpa2,
            isKnown: true
        )
        connectToNetwork(syntheticNetwork, password: nil)
    }
}

// MARK: - FlowLayout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        totalHeight = currentY + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
