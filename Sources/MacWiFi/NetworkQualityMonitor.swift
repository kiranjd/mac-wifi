import Foundation
import Darwin
import SwiftUI

/// Monitors network quality using Apple's built-in networkQuality tool
/// Provides accurate speed and responsiveness measurements
@MainActor
@Observable
final class NetworkQualityMonitor {
    // Results
    var downloadMbps: Double = 0
    var uploadMbps: Double = 0
    var responsiveness: Int = 0  // RPM (Round-trips Per Minute)
    var baseRTTMs: Double = 0
    var loadedLatencyP50Ms: Double = 0
    var loadedLatencyP95Ms: Double = 0
    var loadedJitterMs: Double = 0
    var latencyInflation: Double = 0

    // Test confidence and stability
    var runCount: Int = 0
    var successfulRuns: Int = 0
    var trafficAffectedRuns: Int = 0
    var throughputVariation: Double = 0
    var responsivenessVariation: Double = 0
    var confidenceScore: Double = 0
    var testPhaseText: String = "Idle"
    var testNote: String?

    var isRunning = false
    var error: String?
    var lastTestTime: Date?  // When last test completed

    // Gateway vs Internet ping (for Local vs ISP diagnosis)
    var gatewayLatencyMs: Double?   // Ping to router
    var internetLatencyMs: Double?  // Ping to 1.1.1.1
    var gatewayPacketLossPercent: Double?
    var internetPacketLossPercent: Double?
    var gatewayJitterMs: Double?
    var internetJitterMs: Double?
    var gatewayIP: String?
    var dnsLookupMs: Double?
    var jitterHistoryMs: [Double] = []
    var packetLossHistoryPercent: [Double] = []
    var reliabilityHistory: [ReliabilitySample] = []

    // Real-time tracking during test
    var liveDownloadMbps: Double = 0
    var liveUploadMbps: Double = 0
    var graphScaleMbps: Double = 25
    var speedHistory: [(dl: Double, ul: Double)] = []  // For graph
    private let maxHistoryPoints = 36

    // Freshness and ambient usage heuristics
    let staleResultMaxAge: TimeInterval = 30 * 60
    var ambientDownloadMbps: Double = 0
    var ambientUploadMbps: Double = 0
    var sustainedDownloadMbps: Double = 0
    var sustainedUploadMbps: Double = 0
    var observedHDStreamingTraffic = false
    var observed4KStreamingTraffic = false
    private var ambientSamples: [AmbientTrafficSample] = []
    private let maxAmbientSamples = 90
    private let ambientWindowSeconds: TimeInterval = 90

    // Diagnosis: Is the issue WiFi or ISP?
    enum ConnectionIssue {
        case none
        case wifiProblem      // High gateway latency = local WiFi/router issue
        case ispProblem       // Low gateway, high internet = ISP issue
        case bothProblems     // Both are bad
    }

    var connectionIssue: ConnectionIssue {
        guard let gateway = gatewayLatencyMs, let internet = internetLatencyMs else {
            return .none
        }
        let gatewayLoss = gatewayPacketLossPercent ?? 0
        let internetLoss = internetPacketLossPercent ?? 0

        let gatewayBad = gateway > 50 || gatewayLoss > 2
        let internetBad = internet > 100
            || responsiveness < 500
            || internetLoss > 2
            || latencyInflation > 6

        if gatewayBad && internetBad { return .bothProblems }
        if gatewayBad { return .wifiProblem }
        if internetBad { return .ispProblem }
        return .none
    }

    // Derived scores for UI
    var speedScore: Double {
        // Based on download speed
        switch downloadMbps {
        case 100...: return 100
        case 50..<100: return 80 + (downloadMbps - 50) / 50 * 20
        case 25..<50: return 60 + (downloadMbps - 25) / 25 * 20
        case 10..<25: return 40 + (downloadMbps - 10) / 15 * 20
        case 5..<10: return 20 + (downloadMbps - 5) / 5 * 20
        default: return max(0, downloadMbps / 5 * 20)
        }
    }

    var reliabilityScore: Double {
        // Reliability combines responsiveness, loaded latency, packet loss,
        // and run-to-run stability. Throughput alone does not imply reliability.
        let rpmScore = rpmReliabilityScore
        let loadedLatencyScore = loadedLatencyReliabilityScore
        let inflationScore = inflationReliabilityScore
        let packetLossScore = packetLossReliabilityScore
        let consistencyScore = consistencyReliabilityScore

        return (
            rpmScore * 0.35
            + loadedLatencyScore * 0.25
            + inflationScore * 0.15
            + packetLossScore * 0.15
            + consistencyScore * 0.10
        )
    }

    var reliabilityScoreOutOfTen: Double {
        clamp(reliabilityScore / 10, min: 0, max: 10)
    }

    enum ReliabilityTrend {
        case improving
        case worsening
        case stable
        case insufficientData
    }

    struct ReliabilitySample {
        let timestamp: Date
        let scoreOutOfTen: Double
    }

    struct ReliabilityFactor {
        let title: String
        let score: Double
        let detail: String
    }

    var reliabilityLabel: String {
        switch reliabilityScoreOutOfTen {
        case 8.0...:
            return "Reliable"
        case 6.0..<8.0:
            return "Okay"
        default:
            return "Unstable"
        }
    }

    var reliabilityConfidenceText: String {
        if successfulRuns >= 2 && confidenceScore >= 75 {
            return "High confidence"
        }
        if successfulRuns <= 1 || confidenceScore < 60 {
            return "Low confidence (few samples)"
        }
        return "Medium confidence"
    }

    var reliabilityTrendText: String {
        switch reliabilityTrend(window: 5 * 60) {
        case .improving:
            return "↑ improving (last 5 min)"
        case .worsening:
            return "↓ worsening (last 5 min)"
        case .stable:
            return "→ stable (last 5 min)"
        case .insufficientData:
            return "→ stable (building trend)"
        }
    }

    var reliabilityFactors: [ReliabilityFactor] {
        let worstLoss = max(gatewayPacketLossPercent ?? 0, internetPacketLossPercent ?? 0)
        return [
            ReliabilityFactor(
                title: "Latency responsiveness",
                score: rpmReliabilityScore,
                detail: "\(responsiveness) RPM"
            ),
            ReliabilityFactor(
                title: "Loaded latency spikes",
                score: loadedLatencyReliabilityScore,
                detail: loadedLatencyP95Ms > 0 ? String(format: "P95 %.0f ms", loadedLatencyP95Ms) : "Not enough data"
            ),
            ReliabilityFactor(
                title: "Jitter stability",
                score: inflationReliabilityScore,
                detail: loadedJitterMs > 0
                    ? String(format: "%.0f ms jitter", loadedJitterMs)
                    : "Not enough data"
            ),
            ReliabilityFactor(
                title: "Packet loss",
                score: packetLossReliabilityScore,
                detail: String(format: "%.1f%% loss", worstLoss)
            ),
            ReliabilityFactor(
                title: "Run consistency",
                score: consistencyReliabilityScore,
                detail: String(format: "variation %.0f%%", ((throughputVariation + responsivenessVariation) / 2) * 100)
            )
        ]
    }

    var hasFreshTestResults: Bool {
        guard successfulRuns > 0, let lastTestTime else { return false }
        return Date().timeIntervalSince(lastTestTime) <= staleResultMaxAge
    }

    var confidenceLabel: String {
        switch confidenceScore {
        case 80...: return "High"
        case 60..<80: return "Medium"
        default: return "Low"
        }
    }

    private var rpmReliabilityScore: Double {
        switch responsiveness {
        case 1000...: return 100
        case 500..<1000: return 70 + Double(responsiveness - 500) / 500 * 30
        case 200..<500: return 40 + Double(responsiveness - 200) / 300 * 30
        default: return max(0, Double(responsiveness) / 200 * 40)
        }
    }

    private var loadedLatencyReliabilityScore: Double {
        guard loadedLatencyP95Ms > 0 else { return 50 }
        switch loadedLatencyP95Ms {
        case ..<90: return 100
        case 90..<150: return 85
        case 150..<250: return 65
        case 250..<400: return 45
        default: return 20
        }
    }

    private var inflationReliabilityScore: Double {
        guard latencyInflation > 0 else { return 50 }
        switch latencyInflation {
        case ..<2.5: return 100
        case 2.5..<4: return 80
        case 4..<6: return 60
        case 6..<10: return 40
        default: return 20
        }
    }

    private var packetLossReliabilityScore: Double {
        let worstLoss = max(gatewayPacketLossPercent ?? 0, internetPacketLossPercent ?? 0)
        switch worstLoss {
        case ..<0.5: return 100
        case 0.5..<1: return 90
        case 1..<2: return 75
        case 2..<5: return 50
        default: return 20
        }
    }

    private var consistencyReliabilityScore: Double {
        // Variation is coefficient of variation (0 = perfectly stable)
        let combinedVariation = (throughputVariation + responsivenessVariation) / 2
        return clamp(100 - combinedVariation * 220, min: 20, max: 100)
    }

    private var testTask: Task<Void, Never>?
    private var ambientTrafficTask: Task<Void, Never>?
    private var isExecutingSpeedRun = false
    private var currentRunIndex = 0
    private var currentRunStartTime: Date?
    private var testStartTime: Date?
    private let minRuns = 1
    private let maxRuns = 2
    private let estimatedRunDurationSeconds: TimeInterval = 9
    private let lowCrossTrafficThresholdMbps = 1.5
    private let crossTrafficMaxWaitSeconds = 2.5
    private let maxDiagnosticHistoryPoints = 8
    private let maxReliabilityHistoryPoints = 24

    private var estimatedTotalTestDurationSeconds: TimeInterval {
        // Includes active runs, wait window between runs, and a small fixed setup allowance.
        Double(maxRuns) * estimatedRunDurationSeconds
            + Double(max(0, maxRuns - 1)) * crossTrafficMaxWaitSeconds
            + 2.0
    }

    var runProgress: Double {
        guard runCount > 0 else { return 0 }
        if !isRunning {
            return successfulRuns > 0 ? 1 : 0
        }

        let elapsedProgress: Double
        if let start = testStartTime {
            elapsedProgress = clamp(
                Date().timeIntervalSince(start) / estimatedTotalTestDurationSeconds,
                min: 0,
                max: 0.97
            )
        } else {
            elapsedProgress = 0
        }

        // Keep progress from ever moving backwards and still reflect hard run completions.
        let completedRunsProgress = clamp(
            Double(successfulRuns) / Double(maxRuns),
            min: 0,
            max: 0.97
        )

        return max(elapsedProgress, completedRunsProgress)
    }

    var isPreliminaryResult: Bool {
        successfulRuns > 0 && (isRunning || successfulRuns < runCount)
    }

    init() {
        startAmbientTrafficMonitoring()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        error = nil
        testNote = nil
        runCount = maxRuns
        successfulRuns = 0
        trafficAffectedRuns = 0
        currentRunIndex = 0
        currentRunStartTime = nil
        testStartTime = Date()
        throughputVariation = 0
        responsivenessVariation = 0
        confidenceScore = 0
        testPhaseText = "Checking baseline latency..."
        downloadMbps = 0
        uploadMbps = 0
        responsiveness = 0
        baseRTTMs = 0
        loadedLatencyP50Ms = 0
        loadedLatencyP95Ms = 0
        loadedJitterMs = 0
        latencyInflation = 0
        gatewayLatencyMs = nil
        internetLatencyMs = nil
        gatewayPacketLossPercent = nil
        internetPacketLossPercent = nil
        gatewayJitterMs = nil
        internetJitterMs = nil
        gatewayIP = nil
        dnsLookupMs = nil
        speedHistory = []
        liveDownloadMbps = 0
        liveUploadMbps = 0
        graphScaleMbps = 25

        testTask = Task {
            // Start throughput/reliability test immediately for fast UI feedback.
            async let pingTask: Void = runPingDiagnostics()
            await runSpeedTest()
            _ = await pingTask
        }
    }

    /// Quick ping test to distinguish WiFi issues from ISP issues
    func runPingDiagnostics() async {
        testPhaseText = "Checking local Wi-Fi vs internet..."

        async let dnsLookup: Double? = measureDNSLookupMs(host: "one.one.one.one")

        // Get gateway IP
        gatewayIP = getGatewayIP()

        // Ping gateway (router)
        if let gateway = gatewayIP {
            let stats = await ping(host: gateway, count: 8, timeoutMs: 1000)
            gatewayLatencyMs = stats?.avg
            gatewayPacketLossPercent = stats?.packetLossPercent
            gatewayJitterMs = stats?.stddev
        }

        // Ping internet (Cloudflare DNS)
        let internetStats = await ping(host: "1.1.1.1", count: 8, timeoutMs: 1000)
        internetLatencyMs = internetStats?.avg
        internetPacketLossPercent = internetStats?.packetLossPercent
        internetJitterMs = internetStats?.stddev
        dnsLookupMs = await dnsLookup

        testPhaseText = "Measuring reliability under load..."
    }

    func stop() {
        isRunning = false
        testTask?.cancel()
        testTask = nil
        testStartTime = nil
    }

    // MARK: - Speed Test using networkQuality

    private func runSpeedTest() async {
        // Start live monitoring
        let monitorTask = Task {
            await monitorLiveSpeed()
        }

        var metricsRuns: [SingleRunMetrics] = []
        var failures = 0
        var trafficRuns = 0
        runCount = maxRuns

        for runIndex in 0..<maxRuns {
            if Task.isCancelled { break }

            // First run should start quickly. Later runs can wait for lower cross traffic.
            if runIndex == 0 {
                let initialTraffic = await sampleBackgroundTrafficMbps(durationMs: 350)
                if initialTraffic > lowCrossTrafficThresholdMbps {
                    trafficRuns += 1
                }
            } else {
                testPhaseText = "Preparing run \(runIndex + 1) of \(runCount)..."
                let hadQuietWindow = await waitForLowCrossTraffic(
                    maxWaitSeconds: crossTrafficMaxWaitSeconds,
                    thresholdMbps: lowCrossTrafficThresholdMbps
                )
                if !hadQuietWindow {
                    trafficRuns += 1
                }
            }

            do {
                testPhaseText = "Run \(runIndex + 1) of \(runCount): stressing link..."
                currentRunIndex = runIndex
                currentRunStartTime = Date()
                isExecutingSpeedRun = true
                let result = try await runSingleSpeedTest()
                isExecutingSpeedRun = false
                currentRunStartTime = nil
                let metrics = metricsFrom(result)
                metricsRuns.append(metrics)
                applyAggregatedResults(
                    metricsRuns,
                    trafficRuns: trafficRuns,
                    failures: failures,
                    expectedRuns: runCount
                )

                if runIndex + 1 >= minRuns, shouldStopEarly(runs: metricsRuns, trafficRuns: trafficRuns) {
                    runCount = runIndex + 1
                    testPhaseText = "Stable result reached early."
                    break
                } else if runIndex + 1 < runCount {
                    testPhaseText = "Initial result ready. Refining reliability..."
                }
            } catch {
                isExecutingSpeedRun = false
                currentRunStartTime = nil
                failures += 1
            }
        }

        monitorTask.cancel()

        if !metricsRuns.isEmpty {
            applyAggregatedResults(
                metricsRuns,
                trafficRuns: trafficRuns,
                failures: failures,
                expectedRuns: max(runCount, metricsRuns.count)
            )
            appendDiagnosticHistorySnapshot()
            appendReliabilitySample()
            error = nil
            testPhaseText = "Reliability test complete."
        } else {
            error = "Speed test failed: unable to collect results"
            testPhaseText = "Unable to complete reliability test."
        }

        liveDownloadMbps = 0
        liveUploadMbps = 0
        isRunning = false
        isExecutingSpeedRun = false
        currentRunStartTime = nil
        testStartTime = nil
        lastTestTime = Date()
    }

    private func appendDiagnosticHistorySnapshot() {
        let jitterSample = max(
            loadedJitterMs,
            gatewayJitterMs ?? 0,
            internetJitterMs ?? 0
        )
        let packetLossSample = max(
            gatewayPacketLossPercent ?? 0,
            internetPacketLossPercent ?? 0
        )

        jitterHistoryMs.append(max(0, jitterSample))
        packetLossHistoryPercent.append(max(0, packetLossSample))

        if jitterHistoryMs.count > maxDiagnosticHistoryPoints {
            jitterHistoryMs.removeFirst(jitterHistoryMs.count - maxDiagnosticHistoryPoints)
        }
        if packetLossHistoryPercent.count > maxDiagnosticHistoryPoints {
            packetLossHistoryPercent.removeFirst(packetLossHistoryPercent.count - maxDiagnosticHistoryPoints)
        }
    }

    private func appendReliabilitySample() {
        reliabilityHistory.append(
            ReliabilitySample(
                timestamp: Date(),
                scoreOutOfTen: reliabilityScoreOutOfTen
            )
        )

        if reliabilityHistory.count > maxReliabilityHistoryPoints {
            reliabilityHistory.removeFirst(reliabilityHistory.count - maxReliabilityHistoryPoints)
        }
    }

    private func reliabilityTrend(window: TimeInterval) -> ReliabilityTrend {
        let cutoff = Date().addingTimeInterval(-window)
        let recent = reliabilityHistory.filter { $0.timestamp >= cutoff }

        guard recent.count >= 2, let first = recent.first, let last = recent.last else {
            return .insufficientData
        }

        let delta = last.scoreOutOfTen - first.scoreOutOfTen
        if abs(delta) < 0.35 {
            return .stable
        }
        return delta > 0 ? .improving : .worsening
    }

    private func runSingleSpeedTest() async throws -> NetworkQualityResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/networkQuality")
        process.arguments = ["-c"]  // JSON output, parallel upload+download mode

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            DispatchQueue.global().async {
                let output = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: SpeedTestError.processError)
                }
            }
        }

        guard let result = try? JSONDecoder().decode(NetworkQualityResult.self, from: data) else {
            throw SpeedTestError.parseError
        }
        return result
    }

    private func metricsFrom(_ result: NetworkQualityResult) -> SingleRunMetrics {
        let loaded = result.loadedLatencySamples
        let base = result.base_rtt ?? 0
        let p50 = percentile(loaded, p: 0.50) ?? 0
        let p95 = percentile(loaded, p: 0.95) ?? 0
        let jitter = max(0, p95 - p50)
        let inflation = (base > 0 && p95 > 0) ? (p95 / base) : 0

        return SingleRunMetrics(
            downloadMbps: result.dl_throughput / 1_000_000,
            uploadMbps: result.ul_throughput / 1_000_000,
            responsiveness: result.responsiveness,
            baseRTTMs: base,
            loadedP50Ms: p50,
            loadedP95Ms: p95,
            loadedJitterMs: jitter,
            latencyInflation: inflation
        )
    }

    private func applyAggregatedResults(
        _ runs: [SingleRunMetrics],
        trafficRuns: Int,
        failures: Int,
        expectedRuns: Int
    ) {
        successfulRuns = runs.count
        trafficAffectedRuns = trafficRuns

        downloadMbps = median(runs.map(\.downloadMbps)) ?? 0
        uploadMbps = median(runs.map(\.uploadMbps)) ?? 0
        responsiveness = Int((median(runs.map(\.responsiveness)) ?? 0).rounded())
        baseRTTMs = median(runs.map(\.baseRTTMs)) ?? 0
        loadedLatencyP50Ms = median(runs.map(\.loadedP50Ms)) ?? 0
        loadedLatencyP95Ms = median(runs.map(\.loadedP95Ms)) ?? 0
        loadedJitterMs = median(runs.map(\.loadedJitterMs)) ?? 0
        latencyInflation = median(runs.map(\.latencyInflation)) ?? 0

        throughputVariation = average(
            coefficientOfVariation(runs.map(\.downloadMbps)),
            coefficientOfVariation(runs.map(\.uploadMbps))
        )
        responsivenessVariation = coefficientOfVariation(runs.map(\.responsiveness))

        confidenceScore = calculateConfidenceScore(
            runs: runs,
            plannedRuns: expectedRuns,
            trafficRuns: trafficRuns
        )

        if failures > 0 || trafficRuns > 0 || runs.count < expectedRuns {
            var notes: [String] = []
            if failures > 0 {
                notes.append("Partial sample (\(runs.count)/\(expectedRuns) runs)")
            }
            if trafficRuns > 0 {
                notes.append("Background traffic detected during \(trafficRuns) run(s)")
            }
            if runs.count < expectedRuns {
                notes.append("Refining reliability estimate")
            }
            testNote = notes.joined(separator: " · ")
        } else {
            testNote = nil
        }
    }

    private func shouldStopEarly(runs: [SingleRunMetrics], trafficRuns: Int) -> Bool {
        guard runs.count >= minRuns else { return false }
        guard trafficRuns == 0 else { return false }

        let worstLoss = max(gatewayPacketLossPercent ?? 0, internetPacketLossPercent ?? 0)
        if worstLoss >= 1.0 { return false }

        // One-run fast exit only when the first run is clearly strong and stable.
        if runs.count == 1, let first = runs.first {
            return first.downloadMbps >= 55
                && first.uploadMbps >= 15
                && first.responsiveness >= 700
                && first.loadedP95Ms < 160
                && first.latencyInflation < 3
        }

        let dlVariation = coefficientOfVariation(runs.map(\.downloadMbps))
        let ulVariation = coefficientOfVariation(runs.map(\.uploadMbps))
        let rpmVariation = coefficientOfVariation(runs.map(\.responsiveness))
        let p95Latency = median(runs.map(\.loadedP95Ms)) ?? 0
        let inflation = median(runs.map(\.latencyInflation)) ?? 0

        return dlVariation < 0.12
            && ulVariation < 0.15
            && rpmVariation < 0.15
            && p95Latency < 220
            && inflation < 4.5
    }

    private func calculateConfidenceScore(
        runs: [SingleRunMetrics],
        plannedRuns: Int,
        trafficRuns: Int
    ) -> Double {
        guard plannedRuns > 0 else { return 0 }

        let successRate = Double(runs.count) / Double(plannedRuns)
        let successScore = successRate * 100

        let variation = average(
            coefficientOfVariation(runs.map(\.downloadMbps)),
            coefficientOfVariation(runs.map(\.uploadMbps)),
            coefficientOfVariation(runs.map(\.responsiveness))
        )
        let variationScore = clamp(100 - variation * 220, min: 5, max: 100)

        let trafficFraction = Double(trafficRuns) / Double(plannedRuns)
        let trafficScore = clamp(100 - (trafficFraction * 45), min: 40, max: 100)

        let worstLoss = max(gatewayPacketLossPercent ?? 0, internetPacketLossPercent ?? 0)
        let lossScore: Double
        switch worstLoss {
        case ..<0.5: lossScore = 100
        case 0.5..<1: lossScore = 90
        case 1..<2: lossScore = 75
        case 2..<5: lossScore = 55
        default: lossScore = 30
        }

        let baseScore = successScore * 0.35
            + variationScore * 0.30
            + trafficScore * 0.20
            + lossScore * 0.15

        if runs.count == 1 {
            return baseScore * 0.86
        }
        return baseScore
    }

    private func waitForLowCrossTraffic(maxWaitSeconds: Double, thresholdMbps: Double) async -> Bool {
        let deadline = Date().addingTimeInterval(maxWaitSeconds)
        while Date() < deadline, !Task.isCancelled {
            let trafficMbps = await sampleBackgroundTrafficMbps(durationMs: 900)
            if trafficMbps <= thresholdMbps {
                return true
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return false
    }

    private func sampleBackgroundTrafficMbps(durationMs: Int) async -> Double {
        let startBytes = getNetworkBytes()
        let startTime = Date()
        try? await Task.sleep(for: .milliseconds(durationMs))
        let endBytes = getNetworkBytes()
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return 0 }

        let rxBytes = endBytes.rx >= startBytes.rx ? Double(endBytes.rx - startBytes.rx) : 0
        let txBytes = endBytes.tx >= startBytes.tx ? Double(endBytes.tx - startBytes.tx) : 0
        let totalBits = (rxBytes + txBytes) * 8
        return totalBits / (elapsed * 1_000_000)
    }

    // MARK: - Ambient Traffic Monitoring

    private func startAmbientTrafficMonitoring() {
        guard ambientTrafficTask == nil else { return }

        ambientTrafficTask = Task(priority: .utility) {
            var lastBytes = self.getNetworkBytes()
            var lastTime = Date()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                let currentBytes = self.getNetworkBytes()
                let currentTime = Date()
                let elapsed = currentTime.timeIntervalSince(lastTime)

                guard elapsed > 0 else {
                    lastBytes = currentBytes
                    lastTime = currentTime
                    continue
                }

                let dlBytes = currentBytes.rx >= lastBytes.rx ? Double(currentBytes.rx - lastBytes.rx) : 0
                let ulBytes = currentBytes.tx >= lastBytes.tx ? Double(currentBytes.tx - lastBytes.tx) : 0
                let dlMbps = (dlBytes * 8) / (elapsed * 1_000_000)
                let ulMbps = (ulBytes * 8) / (elapsed * 1_000_000)

                self.ingestAmbientTrafficSample(downloadMbps: dlMbps, uploadMbps: ulMbps, at: currentTime)

                lastBytes = currentBytes
                lastTime = currentTime
            }
        }
    }

    private func ingestAmbientTrafficSample(downloadMbps: Double, uploadMbps: Double, at time: Date) {
        let clampedDl = max(0, downloadMbps)
        let clampedUl = max(0, uploadMbps)
        let alpha = 0.35

        ambientDownloadMbps = ambientDownloadMbps + alpha * (clampedDl - ambientDownloadMbps)
        ambientUploadMbps = ambientUploadMbps + alpha * (clampedUl - ambientUploadMbps)

        ambientSamples.append(
            AmbientTrafficSample(
                timestamp: time,
                downloadMbps: clampedDl,
                uploadMbps: clampedUl
            )
        )

        let cutoff = time.addingTimeInterval(-ambientWindowSeconds)
        ambientSamples.removeAll { $0.timestamp < cutoff }
        if ambientSamples.count > maxAmbientSamples {
            ambientSamples.removeFirst(ambientSamples.count - maxAmbientSamples)
        }

        sustainedDownloadMbps = percentile(ambientSamples.map(\.downloadMbps), p: 0.65) ?? 0
        sustainedUploadMbps = percentile(ambientSamples.map(\.uploadMbps), p: 0.65) ?? 0

        let loss = max(gatewayPacketLossPercent ?? 0, internetPacketLossPercent ?? 0)
        let hasAcceptableLoss = loss < 3
        let fourKLikeSeconds = ambientSamples.filter { $0.downloadMbps >= 18 }.count
        let hdLikeSeconds = ambientSamples.filter { $0.downloadMbps >= 6 }.count

        observed4KStreamingTraffic = hasAcceptableLoss && fourKLikeSeconds >= 10
        observedHDStreamingTraffic = hasAcceptableLoss && (hdLikeSeconds >= 10 || observed4KStreamingTraffic)
    }

    // MARK: - Live Speed Monitoring

    private func monitorLiveSpeed() async {
        var lastBytes = getNetworkBytes()
        var lastTime = Date()

        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))

            // Freeze live values between runs to avoid confusing drops to zero.
            guard isExecutingSpeedRun else {
                lastBytes = getNetworkBytes()
                lastTime = Date()
                continue
            }

            let currentBytes = getNetworkBytes()
            let currentTime = Date()
            let elapsed = currentTime.timeIntervalSince(lastTime)

            if elapsed > 0 {
                // Safe subtraction to avoid overflow (counters can wrap or reset)
                let dlBytes: Double
                let ulBytes: Double

                if currentBytes.rx >= lastBytes.rx {
                    dlBytes = Double(currentBytes.rx - lastBytes.rx)
                } else {
                    dlBytes = 0  // Counter wrapped or reset
                }

                if currentBytes.tx >= lastBytes.tx {
                    ulBytes = Double(currentBytes.tx - lastBytes.tx)
                } else {
                    ulBytes = 0  // Counter wrapped or reset
                }

                // Convert to Mbps (bytes to megabits)
                let rawDlMbps = (dlBytes * 8) / (elapsed * 1_000_000)
                let rawUlMbps = (ulBytes * 8) / (elapsed * 1_000_000)

                await MainActor.run {
                    // Exponential smoothing to reduce jagged jumps in the live graph.
                    let alpha = 0.28
                    let nextDl = self.liveDownloadMbps + alpha * (rawDlMbps - self.liveDownloadMbps)
                    let nextUl = self.liveUploadMbps + alpha * (rawUlMbps - self.liveUploadMbps)

                    self.liveDownloadMbps = max(0, nextDl)
                    self.liveUploadMbps = max(0, nextUl)

                    // Keep Y-axis scale stable; expand quickly, shrink slowly.
                    let instantMax = max(self.liveDownloadMbps, self.liveUploadMbps, 10)
                    if instantMax > self.graphScaleMbps {
                        self.graphScaleMbps = instantMax
                    } else {
                        self.graphScaleMbps = max(10, self.graphScaleMbps * 0.97 + instantMax * 0.03)
                    }

                    // Add to history
                    self.speedHistory.append((dl: self.liveDownloadMbps, ul: self.liveUploadMbps))
                    if self.speedHistory.count > self.maxHistoryPoints {
                        self.speedHistory.removeFirst()
                    }
                }
            }

            lastBytes = currentBytes
            lastTime = currentTime
        }
    }

    /// Get current network interface bytes (rx, tx)
    private nonisolated func getNetworkBytes() -> (rx: UInt64, tx: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            // Only count WiFi interface (en0 on most Macs)
            if name == "en0" {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalRx += UInt64(networkData.pointee.ifi_ibytes)
                    totalTx += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        return (totalRx, totalTx)
    }

    // MARK: - Gateway & Ping Diagnostics

    /// Get the default gateway IP address
    private nonisolated func getGatewayIP() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        process.arguments = ["-rn"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }

            // Parse netstat output to find default gateway
            // Look for line starting with "default" and extract the gateway IP
            for line in output.components(separatedBy: "\n") {
                let components = line.split(separator: " ", omittingEmptySubsequences: true)
                if components.first == "default", components.count >= 2 {
                    let gateway = String(components[1])
                    // Validate it looks like an IP
                    if gateway.contains(".") && !gateway.contains("%") {
                        return gateway
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    /// Ping a host and return latency in milliseconds
    private func ping(host: String, count: Int, timeoutMs: Int) async -> PingStats? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/sbin/ping")
                process.arguments = ["-c", "\(count)", "-W", "\(timeoutMs)", host]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let output = String(data: data, encoding: .utf8) else {
                        continuation.resume(returning: nil)
                        return
                    }

                    continuation.resume(returning: parsePingStats(from: output))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private nonisolated func measureDNSLookupMs(host: String) async -> Double? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var resultInfo: UnsafeMutablePointer<addrinfo>?
                let start = DispatchTime.now().uptimeNanoseconds
                let status = getaddrinfo(host, nil, nil, &resultInfo)
                let end = DispatchTime.now().uptimeNanoseconds
                if let resultInfo {
                    freeaddrinfo(resultInfo)
                }

                guard status == 0 else {
                    continuation.resume(returning: nil)
                    return
                }

                let elapsedMs = Double(end - start) / 1_000_000
                continuation.resume(returning: max(0, elapsedMs))
            }
        }
    }
}

// MARK: - JSON Models for networkQuality output

private struct NetworkQualityResult: Codable {
    let dl_throughput: Double  // bits per second
    let ul_throughput: Double  // bits per second
    let responsiveness: Double  // RPM (Round-trips Per Minute)

    // Optional fields
    let dl_flows: Int?
    let ul_flows: Int?
    let interface_name: String?
    let base_rtt: Double?
    let lud_foreign_h2_req_resp: [Double]?
    let lud_foreign_dl_h2_req_resp: [Double]?
    let lud_foreign_ul_h2_req_resp: [Double]?

    var loadedLatencySamples: [Double] {
        if let combined = lud_foreign_h2_req_resp, !combined.isEmpty {
            return combined
        }
        var merged: [Double] = []
        if let dl = lud_foreign_dl_h2_req_resp { merged.append(contentsOf: dl) }
        if let ul = lud_foreign_ul_h2_req_resp { merged.append(contentsOf: ul) }
        return merged
    }
}

private struct SingleRunMetrics {
    let downloadMbps: Double
    let uploadMbps: Double
    let responsiveness: Double
    let baseRTTMs: Double
    let loadedP50Ms: Double
    let loadedP95Ms: Double
    let loadedJitterMs: Double
    let latencyInflation: Double
}

private struct PingStats {
    let avg: Double
    let stddev: Double
    let packetLossPercent: Double
}

private struct AmbientTrafficSample {
    let timestamp: Date
    let downloadMbps: Double
    let uploadMbps: Double
}

private func parsePingStats(from output: String) -> PingStats? {
    var packetLossPercent: Double?
    var avg: Double?
    var stddev: Double?

    for line in output.components(separatedBy: "\n") {
        if packetLossPercent == nil,
           let lossRange = line.range(of: "% packet loss") {
            let prefix = line[..<lossRange.lowerBound]
            if let valueString = prefix.split(separator: ",").last?.trimmingCharacters(in: .whitespaces),
               let value = Double(valueString) {
                packetLossPercent = value
            }
        }

        if avg == nil,
           let statsRange = line.range(of: "round-trip min/avg/max/stddev = ") {
            let stats = line[statsRange.upperBound...]
            let parts = stats.split(separator: "/")
            if parts.count >= 4 {
                avg = Double(parts[1])
                stddev = Double(parts[3].replacingOccurrences(of: " ms", with: ""))
            }
        }
    }

    guard let avg, let stddev, let packetLossPercent else { return nil }
    return PingStats(avg: avg, stddev: stddev, packetLossPercent: packetLossPercent)
}

private func median(_ values: [Double]) -> Double? {
    guard !values.isEmpty else { return nil }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
        return (sorted[mid - 1] + sorted[mid]) / 2
    }
    return sorted[mid]
}

private func percentile(_ values: [Double], p: Double) -> Double? {
    guard !values.isEmpty else { return nil }
    let sorted = values.sorted()
    let clamped = clamp(p, min: 0, max: 1)
    let idx = Int((Double(sorted.count - 1) * clamped).rounded())
    return sorted[idx]
}

private func coefficientOfVariation(_ values: [Double]) -> Double {
    guard values.count >= 2 else { return 0 }
    let mean = values.reduce(0, +) / Double(values.count)
    guard mean > 0 else { return 0 }
    let variance = values.reduce(0) { partial, value in
        let delta = value - mean
        return partial + delta * delta
    } / Double(values.count)
    return sqrt(variance) / mean
}

private func average(_ values: Double...) -> Double {
    guard !values.isEmpty else { return 0 }
    return values.reduce(0, +) / Double(values.count)
}

private func clamp(_ value: Double, min: Double, max: Double) -> Double {
    Swift.max(min, Swift.min(max, value))
}

private enum SpeedTestError: Error {
    case processError
    case parseError
}
