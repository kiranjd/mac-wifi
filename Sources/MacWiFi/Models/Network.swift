import Foundation
import CoreWLAN

/// Represents a WiFi network with all relevant info
struct Network: Identifiable, Hashable {
    let id: String  // BSSID
    let ssid: String
    let rssi: Int  // Signal strength in dBm
    let noise: Int  // Noise floor in dBm
    let channel: Int
    let channelWidth: Int  // MHz
    let security: SecurityType
    let isKnown: Bool

    var snr: Int { rssi - noise }  // Signal-to-noise ratio

    var band: Band {
        switch channel {
        case 1...14: return .twoFour
        case 36...64, 100...144, 149...177: return .five
        case 1...233 where channel > 177: return .six  // 6GHz starts at channel 1 but uses different range
        default:
            // Fallback: check if channel is in 5GHz range
            if channel >= 36 { return .five }
            return .twoFour
        }
    }

    var signalBars: Int {
        switch rssi {
        case -50...0: return 4
        case -60...(-51): return 3
        case -70...(-61): return 2
        case -80...(-71): return 1
        default: return 0
        }
    }

    var signalQuality: String {
        switch signalBars {
        case 4: return "Excellent"
        case 3: return "Good"
        case 2: return "Fair"
        case 1: return "Weak"
        default: return "Poor"
        }
    }

    /// Estimated speed tier based on band and signal
    var speedTier: SpeedTier {
        let baseSpeed: SpeedTier = band == .twoFour ? .slow : (band == .five ? .fast : .veryFast)

        // Adjust for signal strength
        switch (baseSpeed, signalBars) {
        case (.veryFast, 3...4): return .veryFast
        case (.veryFast, _): return .fast
        case (.fast, 3...4): return .fast
        case (.fast, 2): return .medium
        case (.fast, _): return .slow
        case (.medium, 3...4): return .medium
        case (.medium, _): return .slow
        case (.slow, _): return .slow
        }
    }

    /// Overall score for sorting (higher = better)
    var qualityScore: Int {
        var score = 0
        // Signal contributes most
        score += (rssi + 100) * 2  // -30 dBm = 140, -90 dBm = 20
        // Band bonus
        score += band == .five ? 30 : (band == .six ? 40 : 0)
        // Known network bonus
        score += isKnown ? 50 : 0
        // Security bonus
        score += security == .wpa3 ? 10 : (security == .wpa2 ? 5 : 0)
        return score
    }

    enum Band: String {
        case twoFour = "2.4"
        case five = "5"
        case six = "6"

        var displayName: String {
            switch self {
            case .twoFour: return "2.4 GHz"
            case .five: return "5 GHz"
            case .six: return "6 GHz"
            }
        }
    }

    enum SpeedTier: String {
        case slow = "Basic"
        case medium = "Good"
        case fast = "Fast"
        case veryFast = "Very Fast"

        var icon: String {
            switch self {
            case .slow: return "tortoise"
            case .medium: return "hare"
            case .fast: return "bolt"
            case .veryFast: return "bolt.horizontal"
            }
        }
    }

    enum SecurityType: String {
        case open = "Open"
        case wep = "WEP"
        case wpa = "WPA"
        case wpa2 = "WPA2"
        case wpa3 = "WPA3"
        case enterprise = "Enterprise"
        case unknown = "Unknown"

        var requiresPassword: Bool {
            self != .open
        }

        var color: String {
            switch self {
            case .open: return "red"
            case .wep, .wpa: return "yellow"
            case .wpa2, .wpa3: return "green"
            case .enterprise: return "blue"
            case .unknown: return "gray"
            }
        }
    }

    /// Create from CoreWLAN network
    init(from cwNetwork: CWNetwork, isKnown: Bool = false) {
        self.id = cwNetwork.bssid ?? UUID().uuidString
        self.ssid = cwNetwork.ssid ?? "Hidden Network"
        self.rssi = cwNetwork.rssiValue
        self.noise = cwNetwork.noiseMeasurement
        self.channel = cwNetwork.wlanChannel?.channelNumber ?? 0
        self.channelWidth = Self.getChannelWidth(cwNetwork.wlanChannel)
        self.isKnown = isKnown
        self.security = Self.detectSecurity(cwNetwork)
    }

    private static func getChannelWidth(_ channel: CWChannel?) -> Int {
        guard let ch = channel else { return 20 }
        switch ch.channelWidth {
        case .width20MHz: return 20
        case .width40MHz: return 40
        case .width80MHz: return 80
        case .width160MHz: return 160
        @unknown default: return 20
        }
    }

    private static func detectSecurity(_ network: CWNetwork) -> SecurityType {
        // Check security types in order of strength
        if network.supportsSecurity(.wpa3Personal) || network.supportsSecurity(.wpa3Transition) {
            return .wpa3
        }
        if network.supportsSecurity(.wpa3Enterprise) || network.supportsSecurity(.wpa2Enterprise) {
            return .enterprise
        }
        if network.supportsSecurity(.wpa2Personal) {
            return .wpa2
        }
        if network.supportsSecurity(.wpaPersonal) || network.supportsSecurity(.wpaPersonalMixed) {
            return .wpa
        }
        if network.supportsSecurity(.dynamicWEP) || network.supportsSecurity(.wpaEnterprise) {
            return .enterprise
        }
        if network.supportsSecurity(.WEP) {
            return .wep
        }
        if network.supportsSecurity(.none) {
            return .open
        }
        return .unknown
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Network, rhs: Network) -> Bool {
        lhs.id == rhs.id
    }
}
