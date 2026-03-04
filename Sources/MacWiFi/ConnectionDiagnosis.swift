import SwiftUI

/// Plain English diagnosis engine
/// Translates technical metrics into user-friendly messages
struct ConnectionDiagnosis {

    // MARK: - Health Grade

    enum HealthGrade: Comparable {
        case excellent
        case good
        case fair
        case poor
        case bad

        var color: Color {
            switch self {
            case .excellent, .good: return AppPalette.accent
            case .fair: return AppPalette.accentMedium
            case .poor: return AppPalette.accentSoft
            case .bad: return AppPalette.critical
            }
        }

        var label: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .bad: return "Bad"
            }
        }
    }

    // MARK: - WiFi Signal Quality (from CoreWLAN)

    struct SignalQuality {
        let rssi: Int       // Signal strength (e.g., -58)
        let noise: Int      // Noise floor (e.g., -90)

        var snr: Int { rssi - noise }  // Signal-to-Noise Ratio

        var grade: HealthGrade {
            switch rssi {
            case (-50)...: return .excellent
            case (-60)..<(-50): return .good
            case (-70)..<(-60): return .fair
            case (-80)..<(-70): return .poor
            default: return .bad
            }
        }

        var label: String {
            switch grade {
            case .excellent: return "Strong"
            case .good: return "Good"
            case .fair: return "Okay"
            case .poor: return "Very Weak"
            case .bad: return "Barely Connected"
            }
        }
    }

    // MARK: - Internet Quality (from speed test)

    struct InternetQuality {
        let downloadMbps: Double
        let uploadMbps: Double
        let rpm: Int
        let loadedLatencyP95Ms: Double
        let latencyInflation: Double
        let packetLossPercent: Double
        let confidenceScore: Double
        let gatewayLatencyMs: Double?
        let internetLatencyMs: Double?
        let observedSustainedDownloadMbps: Double
        let observedSustainedUploadMbps: Double
        let observedHDStreamingTraffic: Bool
        let observed4KStreamingTraffic: Bool

        var grade: HealthGrade {
            // RPM weighted more heavily than raw speed
            let rpmGrade = rpmHealthGrade
            let speedGrade = speedHealthGrade
            let reliabilityGrade = reliabilityHealthGrade

            // Take the worse of speed, responsiveness, and loaded reliability.
            return min(rpmGrade, speedGrade, reliabilityGrade)
        }

        private var rpmHealthGrade: HealthGrade {
            switch rpm {
            case 1000...: return .excellent
            case 500..<1000: return .good
            case 200..<500: return .fair
            case 100..<200: return .poor
            default: return .bad
            }
        }

        private var speedHealthGrade: HealthGrade {
            switch downloadMbps {
            case 100...: return .excellent
            case 50..<100: return .good
            case 25..<50: return .good
            case 10..<25: return .fair
            case 5..<10: return .poor
            default: return .bad
            }
        }

        private var reliabilityHealthGrade: HealthGrade {
            if packetLossPercent >= 3 || loadedLatencyP95Ms >= 450 || latencyInflation >= 10 {
                return .bad
            }
            if packetLossPercent >= 1.5 || loadedLatencyP95Ms >= 300 || latencyInflation >= 7 {
                return .poor
            }
            if packetLossPercent >= 0.7 || loadedLatencyP95Ms >= 200 || latencyInflation >= 5 {
                return .fair
            }
            return .good
        }

        var label: String {
            switch grade {
            case .excellent: return "Fast"
            case .good: return "Good"
            case .fair: return "Slow"
            case .poor: return "Very Slow"
            case .bad: return "Barely Working"
            }
        }

        var hasBufferbloat: Bool {
            // Fast throughput but unstable loaded latency indicates bufferbloat.
            downloadMbps >= 25 && (rpm < 500 || latencyInflation >= 4 || loadedLatencyP95Ms >= 220)
        }
    }

    // MARK: - Overall Diagnosis

    let signal: SignalQuality?
    let internet: InternetQuality?
    let connectionIssue: NetworkQualityMonitor.ConnectionIssue

    /// Overall health grade combining signal, internet, and connection issues
    var overallGrade: HealthGrade {
        guard let internet = internet else {
            return signal?.grade ?? .fair  // No test run yet, use signal only
        }

        // Start with internet grade (most important for user experience)
        var grade = internet.grade

        // Factor in signal quality if available
        if let signal = signal {
            grade = min(grade, signal.grade)
        }

        // Connection issues should cap the grade
        switch connectionIssue {
        case .bothProblems:
            grade = min(grade, .poor)
        case .wifiProblem, .ispProblem:
            grade = min(grade, .fair)
        case .none:
            break
        }

        return grade
    }

    // MARK: - Plain English Messages

    /// One-line status message (Level 1)
    var statusMessage: String {
        guard internet != nil else {
            if let signal = signal {
                return signal.grade >= .good ? "Connected" : "Weak signal"
            }
            return "Tap to test connection"
        }

        switch overallGrade {
        case .excellent:
            return "Great for everything"
        case .good:
            return "Good for most activities"
        case .fair:
            return limitedActivitiesMessage ?? "Some activities may be limited"
        case .poor:
            return limitedActivitiesMessage ?? "Several activities won't work well"
        case .bad:
            return "Connection is struggling"
        }
    }

    /// Message about which activities are limited
    private var limitedActivitiesMessage: String? {
        guard internet != nil else { return nil }

        let issues = limitedActivities
        if issues.isEmpty { return nil }

        if issues.contains(.videoCalls) && issues.contains(.gaming) {
            return "Video calls and gaming may lag"
        } else if issues.contains(.videoCalls) {
            return "Video calls may stutter"
        } else if issues.contains(.gaming) {
            return "Gaming will be laggy"
        } else if issues.contains(.fourKStreaming) {
            return "4K streaming may buffer"
        }
        return nil
    }

    /// Explanation of why (Level 2) - only shown when there are actual issues
    var explanationMessage: String? {
        // Only show explanation when there's actually a problem
        guard overallGrade < .good || !limitedActivities.isEmpty else { return nil }

        // Explain based on the specific issue
        switch connectionIssue {
        case .wifiProblem:
            return "The weak spot is between your Mac and router. Wi-Fi signal or interference is causing drops."
        case .ispProblem:
            return "Your local Wi-Fi looks okay. The slowdown is likely on your provider or upstream route."
        case .bothProblems:
            return "Both your Wi-Fi link and internet route are unstable right now."
        case .none:
            break
        }

        // Fallback explanations based on metrics
        if let internet = internet {
            if internet.packetLossPercent >= 1.5 {
                return "Some data is being dropped, so apps may pause or retry."
            }
            if internet.hasBufferbloat {
                return "The connection slows down when the network is busy."
            } else if internet.loadedLatencyP95Ms >= 250 {
                return "Response time spikes when the network is busy."
            } else if internet.rpm < 200 {
                return "Response time is slow right now."
            } else if internet.downloadMbps < 10 {
                return "Download speed is lower than usual right now."
            }
        }

        if let signal = signal, signal.grade < .fair {
            return "Wi-Fi signal is weak. Moving closer to the router should help."
        }

        return nil
    }

    // MARK: - User-Facing Verdict

    var headlineVerdict: String {
        guard internet != nil else {
            if let signal {
                return signal.grade >= .good
                    ? "Connected. Running internet check..."
                    : "Weak Wi-Fi signal. Running internet check..."
            }
            return "Checking connection..."
        }

        let topRisky = prioritizedActivities.first { limitedActivities.contains($0) }
        let topGood = prioritizedGoodActivities.first { workingActivities.contains($0) }

        if let topGood, let topRisky {
            return "\(goodPhrase(for: topGood)) · \(riskyPhrase(for: topRisky))"
        }
        if let topRisky {
            return riskyPhrase(for: topRisky)
        }
        if let topGood {
            return "\(goodPhrase(for: topGood)) · Stable overall"
        }
        return "Connection quality is mixed"
    }

    var headlineSubtext: String {
        "\(wifiSummaryLine) · \(internetSummaryLine)"
    }

    var wifiSummaryLine: String {
        guard let signal else { return "Wi-Fi: Unknown" }
        return "Wi-Fi: \(signal.label)"
    }

    var internetSummaryLine: String {
        guard let internet else { return "Internet: Not tested yet" }

        if internet.packetLossPercent >= 1.5 || internet.loadedLatencyP95Ms >= 260 || internet.latencyInflation >= 5 {
            return "Internet: Unstable"
        }
        if internet.downloadMbps < 12 || internet.uploadMbps < 4 {
            return "Internet: Slow"
        }
        return "Internet: Stable"
    }

    // MARK: - Capability Analysis

    enum Activity: CaseIterable {
        case gaming
        case videoCalls
        case fourKStreaming
        case hdStreaming
        case browsing
        case downloads

        var name: String {
            switch self {
            case .gaming: return "Gaming"
            case .videoCalls: return "Video calls"
            case .fourKStreaming: return "4K streaming"
            case .hdStreaming: return "HD streaming"
            case .browsing: return "Browsing"
            case .downloads: return "File transfers"
            }
        }

        var icon: String {
            switch self {
            case .gaming: return "gamecontroller.fill"
            case .videoCalls: return "video.fill"
            case .fourKStreaming: return "tv.fill"
            case .hdStreaming: return "play.rectangle.fill"
            case .browsing: return "globe"
            case .downloads: return "arrow.down.circle.fill"
            }
        }

        // Real-world requirements:
        // download/upload for throughput, rpm for responsiveness, and app-specific loss tolerance.
        var requirements: (downloadMbps: Double, uploadMbps: Double, rpm: Int, maxPacketLossPercent: Double?) {
            switch self {
            case .gaming: return (15, 5, 900, 0.8)
            case .videoCalls: return (6, 3, 550, 1.2)
            case .fourKStreaming: return (30, 2, 120, 2.0)
            case .hdStreaming: return (8, 1.5, 120, 2.5)
            case .browsing: return (4, 1, 120, 3.0)
            case .downloads: return (20, 1, 60, nil)
            }
        }
    }

    struct ActivityStatus {
        let activity: Activity
        let works: Bool
        let reason: String?  // "too laggy", "too slow", etc.
    }

    /// Activities that won't work well
    var limitedActivities: [Activity] {
        activityStatuses.filter { !$0.works }.map { $0.activity }
    }

    /// Activities that will work
    var workingActivities: [Activity] {
        activityStatuses.filter { $0.works }.map { $0.activity }
    }

    var taskImpactStatuses: [ActivityStatus] {
        let order: [Activity] = [.browsing, .hdStreaming, .fourKStreaming, .videoCalls, .gaming, .downloads]
        let map = Dictionary(uniqueKeysWithValues: activityStatuses.map { ($0.activity, $0) })
        return order.compactMap { map[$0] }
    }

    /// All activity statuses with reasons
    var activityStatuses: [ActivityStatus] {
        guard let internet = internet else {
            return Activity.allCases.map { ActivityStatus(activity: $0, works: true, reason: nil) }
        }

        return Activity.allCases.map { activity in
            let requirements = activity.requirements
            let effectiveDownloadMbps = effectiveDownloadMbps(for: activity, internet: internet)
            let effectiveUploadMbps = effectiveUploadMbps(for: activity, internet: internet)
            let requiredRPM = effectiveRPMRequirement(for: activity, defaultValue: requirements.rpm)
            let maxPacketLossPercent = requirements.maxPacketLossPercent
            let maxLoadedLatencyMs = maxLoadedLatencyMs(for: activity)
            let maxLatencyInflation = maxLatencyInflation(for: activity)

            let downloadOk = effectiveDownloadMbps >= requirements.downloadMbps
            let uploadOk = effectiveUploadMbps >= requirements.uploadMbps
            let responsivenessOk = internet.rpm >= requiredRPM
            let packetLossOk = maxPacketLossPercent.map { internet.packetLossPercent <= $0 } ?? true
            let loadedLatencyOk = maxLoadedLatencyMs.map { internet.loadedLatencyP95Ms <= $0 } ?? true
            let inflationOk = maxLatencyInflation.map { internet.latencyInflation <= $0 } ?? true

            if downloadOk && uploadOk && responsivenessOk && packetLossOk && loadedLatencyOk && inflationOk {
                return ActivityStatus(activity: activity, works: true, reason: nil)
            }

            if observedTrafficOverridesFailure(for: activity, internet: internet) {
                return ActivityStatus(activity: activity, works: true, reason: nil)
            }

            let reason: String
            if !packetLossOk {
                reason = "packet loss"
            } else if !loadedLatencyOk || !inflationOk || !responsivenessOk {
                reason = "lag spikes"
            } else if !uploadOk {
                reason = "upload is limited"
            } else if !downloadOk {
                reason = "download is limited"
            } else {
                reason = "inconsistent connection"
            }

            return ActivityStatus(activity: activity, works: false, reason: reason)
        }
    }

    private func effectiveDownloadMbps(for activity: Activity, internet: InternetQuality) -> Double {
        switch activity {
        case .fourKStreaming, .hdStreaming:
            return max(internet.downloadMbps, internet.observedSustainedDownloadMbps)
        default:
            return internet.downloadMbps
        }
    }

    private func effectiveUploadMbps(for activity: Activity, internet: InternetQuality) -> Double {
        switch activity {
        case .videoCalls, .fourKStreaming, .hdStreaming:
            return max(internet.uploadMbps, internet.observedSustainedUploadMbps)
        default:
            return internet.uploadMbps
        }
    }

    private func effectiveRPMRequirement(for activity: Activity, defaultValue: Int) -> Int {
        switch activity {
        case .fourKStreaming, .hdStreaming:
            // Streaming throughput matters more than strict interaction latency.
            return 120
        default:
            return defaultValue
        }
    }

    private func maxLoadedLatencyMs(for activity: Activity) -> Double? {
        switch activity {
        case .gaming:
            return 220
        case .videoCalls:
            return 260
        case .browsing:
            return 420
        case .fourKStreaming, .hdStreaming:
            return 550
        case .downloads:
            return nil
        }
    }

    private func maxLatencyInflation(for activity: Activity) -> Double? {
        switch activity {
        case .gaming:
            return 5.5
        case .videoCalls:
            return 6.5
        case .browsing:
            return 9
        case .fourKStreaming, .hdStreaming:
            return 11
        case .downloads:
            return nil
        }
    }

    private func observedTrafficOverridesFailure(for activity: Activity, internet: InternetQuality) -> Bool {
        guard internet.packetLossPercent < 3 else { return false }
        guard internet.loadedLatencyP95Ms < 500 else { return false }
        guard internet.latencyInflation < 12 else { return false }

        switch activity {
        case .fourKStreaming:
            return internet.observed4KStreamingTraffic
        case .hdStreaming:
            return internet.observedHDStreamingTraffic || internet.observed4KStreamingTraffic
        default:
            return false
        }
    }

    func impactReasonLine(for status: ActivityStatus) -> String? {
        guard !status.works else { return nil }
        guard internet != nil else { return nil }

        switch status.activity {
        case .videoCalls:
            return "Calls may freeze for a moment or audio may sound robotic."
        case .gaming:
            return "Game controls may feel delayed during spikes."
        case .fourKStreaming:
            return "4K video may drop quality or buffer during peaks."
        case .hdStreaming:
            return "Video may buffer when others use the network."
        case .downloads:
            return "Large downloads may take longer than expected."
        case .browsing:
            return "Web pages may load slowly or hang briefly."
        }
    }

    private var prioritizedActivities: [Activity] {
        [.videoCalls, .gaming, .fourKStreaming, .hdStreaming, .downloads, .browsing]
    }

    private var prioritizedGoodActivities: [Activity] {
        [.browsing, .hdStreaming, .fourKStreaming, .downloads, .videoCalls, .gaming]
    }

    private func goodPhrase(for activity: Activity) -> String {
        switch activity {
        case .videoCalls: return "Good for calls"
        case .gaming: return "Good for gaming"
        case .fourKStreaming, .hdStreaming: return "Good for streaming"
        case .downloads: return "Good for file transfers"
        case .browsing: return "Good for browsing"
        }
    }

    private func riskyPhrase(for activity: Activity) -> String {
        switch activity {
        case .videoCalls: return "Risky for calls"
        case .gaming: return "Risky for gaming"
        case .fourKStreaming, .hdStreaming: return "Risky for streaming"
        case .downloads: return "Slow for file transfers"
        case .browsing: return "Browsing may stutter"
        }
    }

    // MARK: - Summary Text

    /// Compact summary for Level 1 (e.g., "4 of 6 activities work")
    var capabilitySummary: String {
        let working = workingActivities.count
        let total = Activity.allCases.count

        if working == total {
            return "All activities supported"
        } else if working == 0 {
            return "Most activities limited"
        } else {
            let limited = total - working
            return "\(limited) activit\(limited == 1 ? "y" : "ies") limited"
        }
    }
}
