import Foundation
import CoreWLAN
import CoreLocation

/// Helper class for location delegate (not MainActor)
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var manager: WiFiManager?

    func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {
        let status = locationManager.authorizationStatus
        let authorized = (status == .authorizedAlways || status == .authorized)
        Task { @MainActor in
            manager?.locationAuthorized = authorized
            if authorized {
                manager?.refreshStatus()
            }
        }
    }
}

/// Helper class for WiFi event delegate (not MainActor)
private class WiFiEventDelegate: NSObject, CWEventDelegate {
    weak var manager: WiFiManager?

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            manager?.refreshStatus()
            // Reset speed test when network changes
            manager?.qualityMonitor.stop()
            if manager?.currentNetwork != nil {
                manager?.qualityMonitor.start()
            }
        }
    }

    func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            manager?.refreshStatus()
        }
    }

    func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            manager?.refreshStatus()
        }
    }
}

/// Manages all WiFi operations via CoreWLAN
@MainActor
@Observable
final class WiFiManager {
    static let shared = WiFiManager()

    struct PersonalHotspot: Identifiable, Hashable {
        let ssid: String
        let isAvailableNow: Bool
        let matchedNetwork: Network?

        var id: String {
            ssid.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    // State
    var networks: [Network] = []
    var personalHotspots: [PersonalHotspot] = []
    var currentNetwork: Network?
    var transmitRateMbps: Double?
    var isScanning = false
    var isPoweredOn = true
    var error: String?
    var lastScanTime: Date?
    var locationAuthorized = false

    // Connection state
    var connectionState: ConnectionState = .idle
    var connectingToSSID: String?

    // Quality monitoring
    let qualityMonitor = NetworkQualityMonitor()

    // Location manager for SSID access
    private let locationManager = CLLocationManager()
    private let locationDelegate = LocationDelegate()
    private let wifiEventDelegate = WiFiEventDelegate()
    private let scanCacheTTL: TimeInterval = 5 * 60

    enum ConnectionState: Equatable {
        case idle
        case findingNetwork
        case associating
        case authenticating
        case gettingIP
        case connected
        case failed(String)

        var displayText: String {
            switch self {
            case .idle: return ""
            case .findingNetwork: return "Finding network..."
            case .associating: return "Connecting..."
            case .authenticating: return "Authenticating..."
            case .gettingIP: return "Getting IP address..."
            case .connected: return "Connected"
            case .failed(let reason): return reason
            }
        }

        var isConnecting: Bool {
            switch self {
            case .findingNetwork, .associating, .authenticating, .gettingIP:
                return true
            default:
                return false
            }
        }
    }

    // CoreWLAN
    private let client = CWWiFiClient.shared()
    private var interface: CWInterface? { client.interface() }

    private init() {
        locationDelegate.manager = self
        locationManager.delegate = locationDelegate
        wifiEventDelegate.manager = self

        // Start listening for WiFi events
        do {
            try client.startMonitoringEvent(with: .ssidDidChange)
            try client.startMonitoringEvent(with: .linkDidChange)
            try client.startMonitoringEvent(with: .powerDidChange)
            client.delegate = wifiEventDelegate
        } catch {
            print("Failed to start WiFi monitoring: \(error)")
        }

        requestLocationAccess()
        refreshStatus()
    }

    func requestLocationAccess() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorized:
            locationAuthorized = true
            refreshStatus()
        default:
            locationAuthorized = false
        }
    }

    // MARK: - Status

    func refreshStatus() {
        guard let iface = interface else {
            error = "No WiFi interface found"
            return
        }

        isPoweredOn = iface.powerOn()

        if isPoweredOn, let ssid = iface.ssid() {
            let txRate = iface.transmitRate()
            transmitRateMbps = txRate > 0 ? txRate : nil
            currentNetwork = Network(
                id: iface.bssid() ?? "current",
                ssid: ssid,
                rssi: iface.rssiValue(),
                channel: iface.wlanChannel()?.channelNumber ?? 0,
                security: .wpa2,
                isKnown: true
            )
        } else {
            transmitRateMbps = nil
            currentNetwork = nil
        }
    }

    // MARK: - Scanning

    func scan(force: Bool = false) {
        guard let iface = interface else {
            error = "No WiFi interface"
            return
        }

        guard isPoweredOn else {
            error = "WiFi is off"
            return
        }

        if !force,
           let lastScanTime,
           Date().timeIntervalSince(lastScanTime) < scanCacheTTL,
           (!networks.isEmpty || !personalHotspots.isEmpty) {
            error = nil
            return
        }

        guard !isScanning else { return }

        isScanning = true
        error = nil
        let interfaceName = iface.interfaceName ?? "en0"
        let knownFromCoreWLAN = getKnownNetworkSSIDsFromCoreWLAN()
        let preferredKnown = getPreferredNetworkSSIDs(interfaceName: interfaceName)
        let knownSSIDs = knownFromCoreWLAN.union(preferredKnown)
        let preferredHotspots = preferredKnown.filter { self.isLikelyPersonalHotspotSSID($0) }

        // Move heavy CoreWLAN work to background thread
        Task.detached(priority: .userInitiated) {
            do {
                // Scan for networks - includeHidden to catch personal hotspots
                let activeScanResults = try iface.scanForNetworks(withSSID: nil, includeHidden: true)
                let cachedScanResults = iface.cachedScanResults() ?? []
                let likelyPersonalHotspots = preferredHotspots.isEmpty
                    ? knownSSIDs.filter { self.isLikelyPersonalHotspotSSID($0) }
                    : preferredHotspots

                var cwNetworks = activeScanResults
                cwNetworks.formUnion(cachedScanResults)

                // Targeted probes for known hotspot names (e.g. "<Name>'s iPhone").
                for hotspotSSID in likelyPersonalHotspots
                where !cwNetworks.contains(where: { ($0.ssid ?? "") == hotspotSSID }) {
                    if let hotspotData = hotspotSSID.data(using: .utf8),
                       let targetedResults = try? iface.scanForNetworks(withSSID: hotspotData, includeHidden: true) {
                        cwNetworks.formUnion(targetedResults)
                    }
                }

                var scannedNetworks = cwNetworks.map { cw in
                    Network(from: cw, isKnown: knownSSIDs.contains(cw.ssid ?? ""))
                }

                // Sort by signal strength (strongest first)
                scannedNetworks.sort { $0.rssi > $1.rssi }

                // Deduplicate by SSID (keep strongest signal)
                // For hidden networks: keep a small set and avoid showing very weak entries.
                var seen = Set<String>()
                var hiddenCount = 0
                let maxHiddenNetworks = 6
                let minHiddenRSSI = -85

                scannedNetworks = scannedNetworks.filter { network in
                    if network.ssid == "Hidden Network" || network.ssid.isEmpty {
                        guard hiddenCount < maxHiddenNetworks && network.rssi >= minHiddenRSSI else {
                            return false
                        }
                        hiddenCount += 1
                        return true
                    }
                    let key = network.ssid.lowercased()
                    guard !seen.contains(key) else { return false }
                    seen.insert(key)
                    return true
                }

                let finalNetworks = scannedNetworks
                let finalHotspots = self.buildPersonalHotspotEntries(
                    scannedNetworks: finalNetworks
                )

                await MainActor.run {
                    let hiddenOnly = !finalNetworks.isEmpty && finalNetworks.allSatisfy { $0.ssid == "Hidden Network" }
                    self.networks = finalNetworks
                    self.personalHotspots = finalHotspots
                    self.isScanning = false
                    if hiddenOnly && !self.locationAuthorized {
                        self.error = "Location Services required"
                    } else {
                        self.error = nil
                    }
                    self.lastScanTime = Date()
                }
            } catch let err as NSError {
                await MainActor.run {
                    if err.domain == "com.apple.coreWLAN.error" {
                        if err.code == -3931 {
                            self.error = "Location Services required"
                        } else {
                            self.error = "WiFi error: \(err.localizedDescription)"
                        }
                    } else {
                        self.error = "Scan failed: \(err.localizedDescription)"
                    }
                    self.personalHotspots = []
                    self.isScanning = false
                }
            }
        }
    }

    private func getKnownNetworkSSIDsFromCoreWLAN() -> Set<String> {
        guard let configs = interface?.configuration()?.networkProfiles else {
            return []
        }
        return Set(configs.compactMap { ($0 as? CWNetworkProfile)?.ssid })
    }

    private nonisolated func getPreferredNetworkSSIDs(interfaceName: String) -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-listpreferredwirelessnetworks", interfaceName]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return [] }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }

            var names = Set<String>()
            for rawLine in output.components(separatedBy: .newlines) {
                let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if trimmed.lowercased().hasPrefix("preferred networks on") { continue }
                names.insert(trimmed)
            }
            return names
        } catch {
            return []
        }
    }

    private nonisolated func isLikelyPersonalHotspotSSID(_ ssid: String) -> Bool {
        let name = ssid.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return name.contains("iphone")
            || name.contains("ipad")
            || name.contains("hotspot")
            || name.contains("pixel")
            || name.contains("galaxy")
    }

    private nonisolated func buildPersonalHotspotEntries(
        scannedNetworks: [Network]
    ) -> [PersonalHotspot] {
        var byKey: [String: PersonalHotspot] = [:]

        for network in scannedNetworks where isLikelyPersonalHotspotSSID(network.ssid) {
            let trimmedSSID = network.ssid.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmedSSID.lowercased()
            byKey[key] = PersonalHotspot(
                ssid: trimmedSSID,
                isAvailableNow: true,
                matchedNetwork: network
            )
        }

        return byKey.values.sorted { lhs, rhs in
            let lhsRSSI = lhs.matchedNetwork?.rssi ?? Int.min
            let rhsRSSI = rhs.matchedNetwork?.rssi ?? Int.min
            if lhsRSSI != rhsRSSI {
                return lhsRSSI > rhsRSSI
            }
            return lhs.ssid.localizedCaseInsensitiveCompare(rhs.ssid) == .orderedAscending
        }
    }

    // MARK: - Connect

    func connect(to network: Network, password: String? = nil) async throws {
        guard let iface = interface else {
            connectionState = .failed("No WiFi interface")
            throw WiFiError.noInterface
        }

        connectingToSSID = network.ssid
        error = nil

        // Step 1: Find network
        connectionState = .findingNetwork
        let cwNetworks: Set<CWNetwork>
        do {
            cwNetworks = try iface.scanForNetworks(withSSID: network.ssid.data(using: .utf8))
        } catch {
            connectionState = .failed("Network not found")
            connectingToSSID = nil
            throw WiFiError.networkNotFound
        }

        guard let cwNetwork = cwNetworks.first else {
            connectionState = .failed("Network not found")
            connectingToSSID = nil
            throw WiFiError.networkNotFound
        }

        // Step 2: Associate
        connectionState = .associating

        // Step 3: Authenticate (happens during associate if password required)
        if password != nil {
            connectionState = .authenticating
        }

        do {
            try iface.associate(to: cwNetwork, password: password)
        } catch let err as NSError {
            let reason: String
            if err.code == -3924 {
                reason = "Wrong password"
            } else if err.code == -3905 {
                reason = "Connection timed out"
            } else {
                reason = err.localizedDescription
            }
            connectionState = .failed(reason)
            connectingToSSID = nil
            throw WiFiError.connectionFailed(reason)
        }

        // Step 4: Getting IP
        connectionState = .gettingIP

        // Brief wait for DHCP
        try? await Task.sleep(for: .milliseconds(500))

        connectionState = .connected
        refreshStatus()

        // Reset after brief success display
        try? await Task.sleep(for: .seconds(1))
        connectionState = .idle
        connectingToSSID = nil
    }

    // MARK: - Disconnect

    func disconnect() {
        interface?.disassociate()
        currentNetwork = nil
        refreshStatus()
    }

    // MARK: - Power

    func setPower(_ on: Bool) {
        do {
            try interface?.setPower(on)
            isPoweredOn = on
            if !on {
                currentNetwork = nil
                networks = []
            }
        } catch {
            self.error = "Failed to toggle WiFi: \(error.localizedDescription)"
        }
    }

    func togglePower() {
        setPower(!isPoweredOn)
    }
}

// MARK: - Custom Network init

extension Network {
    init(id: String, ssid: String, rssi: Int, channel: Int, security: SecurityType, isKnown: Bool) {
        self.id = id
        self.ssid = ssid
        self.rssi = rssi
        self.noise = -90  // Default noise floor
        self.channel = channel
        self.channelWidth = 80
        self.security = security
        self.isKnown = isKnown
    }
}

// MARK: - Errors

enum WiFiError: LocalizedError {
    case noInterface
    case networkNotFound
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .noInterface: return "No WiFi interface found"
        case .networkNotFound: return "Network not found"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        }
    }
}
