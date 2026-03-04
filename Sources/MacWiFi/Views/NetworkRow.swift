import SwiftUI

struct NetworkRow: View {
    let network: Network
    let isConnected: Bool
    var isConnecting: Bool = false
    var connectionStatus: String? = nil
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // WiFi icon
                wifiIcon

                // Network name + status
                VStack(alignment: .leading, spacing: 0) {
                    Text(network.ssid)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)

                    if isConnecting, let status = connectionStatus {
                        Text(status)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(AppPalette.accent)
                    }
                }

                Spacer(minLength: 4)

                // Compact info
                HStack(spacing: 4) {
                    Text(String(format: "%4d dBm", network.rssi))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 58, alignment: .trailing)

                    // Band (only 5/6)
                    if network.band != .twoFour {
                        Text(network.band.rawValue)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 9, alignment: .center)
                    }

                    // Lock
                    if network.security.requiresPassword {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 10, alignment: .center)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovering = hover
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .help("\(network.signalQuality) signal (\(network.rssi) dBm)")
    }

    @ViewBuilder
    private var wifiIcon: some View {
        ZStack {
            if isConnecting {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.6)
            } else if #available(macOS 13.0, *) {
                Image(systemName: "wifi", variableValue: signalVariableValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
            } else {
                Image(systemName: "wifi")
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
            }
        }
        .frame(width: 20, height: 20)
        .background(
            Circle()
                .fill(isConnected ? AppPalette.accent : Color.clear)
        )
    }

    private var signalVariableValue: Double {
        switch network.signalBars {
        case 4: return 1.0
        case 3: return 0.75
        case 2: return 0.55
        case 1: return 0.35
        default: return 0.15
        }
    }

    private var iconColor: Color {
        if isConnected {
            return .white
        }
        switch network.signalBars {
        case 4: return .primary
        case 3: return .primary.opacity(0.85)
        case 2: return .secondary
        case 1: return AppPalette.accentSoft
        default: return AppPalette.criticalSoft
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isPressed {
            Color.primary.opacity(0.12)
        } else if isConnecting {
            AppPalette.accentBackground
        } else if isHovering {
            Color.primary.opacity(0.06)
        } else {
            Color.clear
        }
    }
}
