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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            if manager.isPoweredOn {
                // Current network info bar (if connected)
                if let current = manager.currentNetwork {
                    connectionInfoBar(current)
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
        .sheet(isPresented: $showPasswordPrompt) {
            PasswordPrompt(
                network: selectedNetwork,
                password: $password,
                onConnect: connectWithPassword,
                onCancel: { showPasswordPrompt = false; password = "" }
            )
        }
        .onAppear {
            if manager.isPoweredOn {
                if manager.networks.isEmpty {
                    manager.scan()
                }
                // Start immediately when opening if connected.
                if manager.currentNetwork != nil && !manager.qualityMonitor.isRunning {
                    manager.qualityMonitor.start()
                }
            }
        }
        .onChange(of: manager.currentNetwork?.ssid) { _, newValue in
            // Start quality test when we connect to a network
            if newValue != nil && !manager.qualityMonitor.isRunning {
                manager.qualityMonitor.start()
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
        }
        let otherNetworks = manager.networks.filter {
            !$0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
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
                .font(.system(size: 13, weight: .semibold))

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
                        .fill(Color.blue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "wifi")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(wifiBadgeHover ? 1.06 : 1.0)
                .shadow(
                    color: Color.blue.opacity(wifiBadgeHover ? 0.45 : 0.18),
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
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(network.band.displayName) · \(network.security.rawValue)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { manager.disconnect() }) {
                    Text("Disconnect")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Graph with overlaid speed numbers
            if showContent {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        // Graph
                        liveSpeedGraph
                            .frame(height: 84)
                            .padding(.horizontal, -8)
                            .opacity(isRunning ? 1 : 0.5)

                        // Throughput + reliability labels
                        HStack(spacing: 12) {
                            speedValueCompact(
                                value: dlSpeed,
                                arrow: "arrow.down",
                                color: .blue,
                                helpText: "Download speed"
                            )
                            speedValueCompact(
                                value: ulSpeed,
                                arrow: "arrow.up",
                                color: .green,
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
                        .shadow(color: colorScheme == .dark ? .black : .white, radius: 1, x: 0, y: 1)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.8), radius: 4, x: 0, y: 1)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 6)
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
                            .padding(.vertical, 12)
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
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func runningGraphStatusFooter(monitor: NetworkQualityMonitor) -> some View {
        let status = runningPhaseStatusMessage(monitor)

        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .opacity(0.18)
                .padding(.horizontal, 10)
                .padding(.bottom, 5)

            ZStack(alignment: .leading) {
                Text(status.message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .id(status.id)
                .transition(
                    .asymmetric(
                        insertion: .offset(y: 4).combined(with: .opacity),
                        removal: .offset(y: -4).combined(with: .opacity)
                    )
                )
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 7)

            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.blue.opacity(0.09))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.blue.opacity(0.50))
                            .frame(width: max(3, geo.size.width * monitor.runProgress), height: 3)
                    }
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.blue.opacity(0.015)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.28), value: status.id)
    }

    private func runningPhaseStatusMessage(_ monitor: NetworkQualityMonitor) -> (id: String, message: String) {
        let phase = monitor.testPhaseText.lowercased()

        if monitor.successfulRuns == 0 {
            return (
                id: "collecting",
                message: "Collecting baseline samples…"
            )
        }

        if phase.contains("local wi-fi vs internet") {
            return (id: "path-check", message: "Checking Wi-Fi vs internet path…")
        }
        if phase.contains("baseline latency") {
            return (id: "baseline", message: "Checking baseline latency…")
        }
        if phase.contains("preparing run") {
            return (id: "preparing", message: "Preparing next test pass…")
        }
        if phase.contains("stressing link") {
            return (id: "load", message: "Testing stability under load…")
        }
        if phase.contains("stable result reached early") {
            return (id: "early-stable", message: "Looks stable, running confirmation…")
        }
        if phase.contains("initial result ready") {
            return (id: "refining", message: "Initial result ready, refining…")
        }

        if monitor.runProgress >= 0.92 {
            return (
                id: "finalizing",
                message: "Finalizing summary…"
            )
        }

        return (
            id: "running",
            message: "Running connection check…"
        )
    }

    // Details section - simple and clear
    @ViewBuilder
    private var detailsExpandedSection: some View {
        let diagnosis = currentDiagnosis
        let monitor = manager.qualityMonitor
        let showReliability = !monitor.isRunning && monitor.hasFreshTestResults

        VStack(alignment: .leading, spacing: 10) {
            diagnosisSummaryCard(diagnosis: diagnosis, monitor: monitor, showReliability: showReliability)
            whatYouCanDoNowCard(diagnosis: diagnosis)

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
        let title: String
        let positive: String
        let issue: String
        let issueIcon: String
        let issueColor: Color
    }

    private struct QuickActionStatus {
        let title: String
        let isGood: Bool
        let detail: String
    }

    @ViewBuilder
    private func diagnosisSummaryCard(diagnosis: ConnectionDiagnosis, monitor: NetworkQualityMonitor, showReliability: Bool) -> some View {
        let summary = diagnosisSummary(diagnosis)

        VStack(alignment: .leading, spacing: 6) {
            Text("Diagnosis")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)

            Text(summary.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            diagnosisDetailRow(
                icon: "checkmark.circle.fill",
                text: summary.positive,
                color: .green
            )

            diagnosisDetailRow(
                icon: summary.issueIcon,
                text: summary.issue,
                color: summary.issueColor
            )

            if showReliability {
                diagnosisDetailRow(
                    icon: "waveform.path.ecg",
                    text: formatReliabilityLabel(monitor),
                    color: .secondary
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func diagnosisDetailRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private func diagnosisSummary(_ diagnosis: ConnectionDiagnosis) -> DiagnosisSummary {
        guard let internet = diagnosis.internet else {
            return DiagnosisSummary(
                title: "Checking connection…",
                positive: "Wi-Fi connected",
                issue: "Collecting enough samples for a reliable result",
                issueIcon: "hourglass",
                issueColor: .secondary
            )
        }

        switch diagnosis.connectionIssue {
        case .ispProblem:
            let issue = internet.packetLossPercent >= 1
                ? "High latency + packet loss"
                : "High latency on the internet path"
            return DiagnosisSummary(
                title: "ISP unstable",
                positive: "Wi-Fi link strong",
                issue: issue,
                issueIcon: "exclamationmark.circle.fill",
                issueColor: .orange
            )
        case .wifiProblem:
            return DiagnosisSummary(
                title: "Wi-Fi unstable",
                positive: "Internet path is likely okay",
                issue: "Weak signal or local interference",
                issueIcon: "exclamationmark.circle.fill",
                issueColor: .orange
            )
        case .bothProblems:
            return DiagnosisSummary(
                title: "Both unstable",
                positive: "Light tasks may still work",
                issue: "Wi-Fi interference + ISP latency",
                issueIcon: "xmark.octagon.fill",
                issueColor: .red
            )
        case .none:
            if !diagnosis.limitedActivities.isEmpty {
                return DiagnosisSummary(
                    title: "Connection mixed",
                    positive: "Wi-Fi link strong",
                    issue: "Latency spikes under load",
                    issueIcon: "exclamationmark.circle.fill",
                    issueColor: .orange
                )
            }
            return DiagnosisSummary(
                title: "Connection stable",
                positive: "Wi-Fi link strong",
                issue: "No major issues detected",
                issueIcon: "checkmark.circle.fill",
                issueColor: .green
            )
        }
    }

    @ViewBuilder
    private func whatYouCanDoNowCard(diagnosis: ConnectionDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What you can do right now")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)

            quickActionRow(
                status: quickActionStatus(
                    title: "Real-time calls and gaming",
                    activities: [.videoCalls, .gaming],
                    diagnosis: diagnosis,
                    warningDetail: "May stutter / lag spikes"
                )
            )
            quickActionRow(
                status: quickActionStatus(
                    title: "Streaming (HD/4K)",
                    activities: [.hdStreaming, .fourKStreaming],
                    diagnosis: diagnosis,
                    warningDetail: "May buffer at times"
                )
            )
            quickActionRow(
                status: quickActionStatus(
                    title: "Transfers, uploads, backups",
                    activities: [.downloads],
                    diagnosis: diagnosis,
                    warningDetail: "May slow during congestion"
                )
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func quickActionStatus(
        title: String,
        activities: [ConnectionDiagnosis.Activity],
        diagnosis: ConnectionDiagnosis,
        warningDetail: String
    ) -> QuickActionStatus {
        let statusMap = Dictionary(uniqueKeysWithValues: diagnosis.taskImpactStatuses.map { ($0.activity, $0.works) })
        let isGood = activities.allSatisfy { statusMap[$0] ?? true }
        return QuickActionStatus(
            title: title,
            isGood: isGood,
            detail: isGood ? "Should be fine" : warningDetail
        )
    }

    @ViewBuilder
    private func quickActionRow(status: QuickActionStatus) -> some View {
        HStack(alignment: .center, spacing: 7) {
            Image(systemName: status.isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(status.isGood ? .green : .orange)
                .frame(width: 14, alignment: .center)

            Text(status.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Spacer(minLength: 0)

            Text(status.detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(width: 122, alignment: .trailing)
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
            return ("❌", .red)
        }
        if diagnosis.connectionIssue == .none && diagnosis.limitedActivities.isEmpty {
            return ("✅", .green)
        }
        return ("⚠️", .orange)
    }

    @ViewBuilder
    private func speedValueCompact(value: Double, arrow: String, color: Color, helpText: String) -> some View {
        let speedNumber = formatSpeedNumber(value)

        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                Text(speedNumber)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .id(speedNumber)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 3).combined(with: .opacity),
                            removal: .offset(y: -3).combined(with: .opacity)
                        )
                    )
            }
            .frame(width: 44, height: 20, alignment: .trailing)
            .clipped()
            .animation(.easeInOut(duration: 0.18), value: speedNumber)

            Text("M")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)

            Image(systemName: arrow)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
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
                .font(.system(size: 11))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(takeaway.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = takeaway.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
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
                title: "Running connection check",
                subtitle: "Collecting enough samples for a reliable verdict.",
                icon: "⏳",
                tint: .secondary
            )
        }

        let title: String
        let subtitle: String
        switch diagnosis.connectionIssue {
        case .ispProblem:
            title = "Diagnosis: ISP unstable"
            subtitle = "Local Wi-Fi looks strong"
        case .wifiProblem:
            title = "Diagnosis: Wi-Fi unstable"
            subtitle = "Internet path looks stable"
        case .bothProblems:
            title = "Diagnosis: Both unstable"
            subtitle = "Wi-Fi interference + ISP latency"
        case .none:
            if internet.packetLossPercent >= 1.0 || internet.loadedLatencyP95Ms >= 260 || internet.latencyInflation >= 5 {
                title = "Diagnosis: ISP unstable"
                subtitle = "Local Wi-Fi looks strong"
            } else if !diagnosis.limitedActivities.isEmpty {
                title = "Diagnosis: Mixed performance"
                subtitle = "Latency spikes under load"
            } else {
                title = "Diagnosis: Stable"
                subtitle = "Wi-Fi and internet both look healthy"
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
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            return .green
        case .fair:
            return .orange
        case .poor, .bad:
            return .red
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
        if label == "Stable" { return .green }
        if label == "Slow" { return .orange }
        if label == "Not tested yet" { return .secondary }
        return .orange
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
            return Color(nsColor: .systemYellow)
        case .bad:
            return Color(nsColor: .systemRed)
        }
    }

    private func chipBackgroundColor(for state: TaskChipState) -> Color {
        switch state {
        case .good:
            return Color.green.opacity(0.12)
        case .warning:
            return Color(nsColor: .systemYellow).opacity(0.18)
        case .bad:
            return Color(nsColor: .systemRed).opacity(0.16)
        }
    }

    private func chipBorderColor(for state: TaskChipState) -> Color {
        switch state {
        case .good:
            return Color.green.opacity(0.36)
        case .warning:
            return Color(nsColor: .systemYellow).opacity(0.58)
        case .bad:
            return Color(nsColor: .systemRed).opacity(0.58)
        }
    }

    @ViewBuilder
    private func connectionBreakdownSection(diagnosis: ConnectionDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let monitor = manager.qualityMonitor

            diagnosticsSectionCard(title: "Internet quality", icon: "globe") {
                metricRow("Latency", latencyLabel(monitor), icon: "timer", tone: callDelayTone(monitor))
                metricRow("Jitter", jitterLabel(monitor), icon: "waveform.path.ecg", tone: jitterTone(monitor))
                metricRow("Packet loss", packetLossLabel(monitor), icon: "exclamationmark.triangle.fill", tone: packetLossTone(monitor))
                metricRow(
                    "Down / Up",
                    "\(formatSpeedMbps(monitor.downloadMbps)) / \(formatSpeedMbps(monitor.uploadMbps))",
                    icon: "arrow.down.and.up.circle.fill",
                    tone: throughputTone(max(monitor.downloadMbps, monitor.uploadMbps))
                )
            }

            diagnosticsSectionCard(title: "Connection path", icon: "point.3.connected.trianglepath.dotted") {
                metricRow("Router ping", formatOptionalMs(monitor.gatewayLatencyMs), icon: "dot.radiowaves.left.and.right", tone: pingTone(monitor.gatewayLatencyMs))
                metricRow("Internet ping", formatOptionalMs(monitor.internetLatencyMs), icon: "network.badge.shield.half.filled", tone: pingTone(monitor.internetLatencyMs))
                metricRow("DNS time", formatOptionalMs(monitor.dnsLookupMs), icon: "magnifyingglass", tone: dnsTone(monitor.dnsLookupMs))
            }

            diagnosticsSectionCard(title: "Wi-Fi link", icon: "wifi") {
                metricRow(
                    "Signal",
                    manager.currentNetwork.map { "\(diagnosis.wifiSummaryLine.replacingOccurrences(of: "Wi-Fi: ", with: "")) (\($0.rssi) dBm)" } ?? diagnosis.wifiSummaryLine,
                    icon: "wifi",
                    tone: signalTone(diagnosis)
                )
                metricRow("RSSI", manager.currentNetwork.map { "\($0.rssi) dBm" } ?? "--", icon: "antenna.radiowaves.left.and.right", tone: signalTone(diagnosis))
                metricRow("SNR", manager.currentNetwork.map { "\($0.snr) dB" } ?? "--", icon: "gauge.with.dots.needle.67percent", tone: signalTone(diagnosis))
                metricRow("Band", manager.currentNetwork?.band.displayName ?? "--", icon: "dot.scope")
                if let current = manager.currentNetwork {
                    metricRow("Channel", "\(current.channel) (\(current.channelWidth) MHz)", icon: "point.3.connected.trianglepath.dotted")
                }
                metricRow("PHY rate", manager.transmitRateMbps.map { String(format: "%.0f Mbps", $0) } ?? "--", icon: "bolt.horizontal.circle.fill")
            }

            diagnosticsSectionCard(title: "Recent history", icon: "clock.arrow.2.circlepath") {
                metricRow("Jitter history", jitterHistoryLabel(monitor), icon: "waveform.path.ecg", tone: .muted)
                metricRow("Packet loss history", packetLossHistoryLabel(monitor), icon: "chart.line.downtrend.xyaxis", tone: .muted)
            }
        }
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
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 7))
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
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(metricToneColor(tone))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 1)
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
            return .green
        case .warning:
            return .orange
        case .bad:
            return .red
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
        // Fixed size graph - no layout animation
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            Canvas { context, size in
                let history = smoothedHistory(manager.qualityMonitor.speedHistory)
                guard history.count >= 2 else { return }

                let maxSpeed = max(manager.qualityMonitor.graphScaleMbps, 10)

                let width = size.width
                let height = size.height
                let stepX = width / CGFloat(max(history.count - 1, 1))

                // Download points - use full height with small padding
                let dlPoints = history.enumerated().map { (i, point) -> CGPoint in
                    CGPoint(
                        x: CGFloat(i) * stepX,
                        y: height * 0.1 + (height * 0.85) * (1 - CGFloat(point.dl / maxSpeed))
                    )
                }

                // Upload points
                let ulPoints = history.enumerated().map { (i, point) -> CGPoint in
                    CGPoint(
                        x: CGFloat(i) * stepX,
                        y: height * 0.1 + (height * 0.85) * (1 - CGFloat(point.ul / maxSpeed))
                    )
                }

                let dlLine = smoothPath(through: dlPoints)
                let ulLine = smoothPath(through: ulPoints)

                // Fill under download curve using a single closed path to avoid seam artifacts.
                var closedFill = dlLine
                closedFill.addLine(to: CGPoint(x: dlPoints.last!.x, y: height))
                closedFill.addLine(to: CGPoint(x: dlPoints[0].x, y: height))
                closedFill.closeSubpath()

                context.fill(closedFill, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .blue.opacity(0.30), location: 0),
                        .init(color: .blue.opacity(0.12), location: 0.5),
                        .init(color: .blue.opacity(0.0), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: height)
                ))

                // Draw download line
                context.stroke(dlLine, with: .color(.blue), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                // Draw upload line
                context.stroke(ulLine, with: .color(.green), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
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
        }
        let otherNetworks = manager.networks.filter {
            !$0.isKnown
                && $0.ssid != manager.currentNetwork?.ssid
                && !personalHotspotSSIDs.contains($0.ssid.lowercased())
        }

        VStack(alignment: .leading, spacing: 0) {
            if !manager.personalHotspots.isEmpty {
                sectionHeaderWithTime("Personal Hotspot", showScanInfo: false)
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
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOtherNetworks.toggle()
                }
                if showOtherNetworks && manager.networks.isEmpty {
                    manager.scan()
                }
            }) {
                HStack {
                    Text("Other Networks")
                        .font(.system(size: 13))
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

            Image(systemName: showOtherNetworks ? "chevron.down" : "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)
        }
        .padding(.trailing, 10)
    }

    // MARK: - Section Header

    private func sectionHeaderWithTime(_ title: String, showScanInfo: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
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
            HStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(hotspot.ssid)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Text(hotspot.isAvailableNow ? "Available now" : "Saved hotspot")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                if isConnecting {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                } else if hotspot.isAvailableNow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Nearby")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status View

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
            Text(error)
                .font(.system(size: 10))
                .foregroundStyle(.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
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
            showPasswordPrompt = true
        } else {
            connectToNetwork(network, password: nil)
        }
    }

    private func connectWithPassword() {
        guard let network = selectedNetwork else { return }
        connectToNetwork(network, password: password)
        showPasswordPrompt = false
    }

    private func connectToNetwork(_ network: Network, password: String?) {
        // Immediate UI feedback
        manager.connectingToSSID = network.ssid
        manager.connectionState = .findingNetwork
        manager.error = nil

        Task {
            do {
                try await manager.connect(to: network, password: password)
            } catch {
                manager.error = error.localizedDescription
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
