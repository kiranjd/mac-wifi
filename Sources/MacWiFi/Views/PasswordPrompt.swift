import SwiftUI

struct PasswordPrompt: View {
    let network: Network?
    @Binding var password: String
    let errorMessage: String?
    let isConnecting: Bool
    let onConnect: () -> Void
    let onCancel: () -> Void

    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "wifi")
                .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppPalette.accent)

                if let network = network {
                    Text(network.ssid)
                        .font(.system(size: 15, weight: .semibold))

                    Text("Enter the password to join this network.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppPalette.textMuted)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 11))
                    .foregroundStyle(AppPalette.textMuted)

                SecureField("Network password", text: $password)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppPalette.borderSoft.opacity(0.8), lineWidth: 1)
                    )
                    .focused($isPasswordFocused)
                    .disabled(isConnecting)
                    .onSubmit {
                        if !password.isEmpty && !isConnecting {
                            onConnect()
                        }
                    }
            }

            if let errorMessage, !errorMessage.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppPalette.critical)
                        .padding(.top, 1)

                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(AppPalette.criticalSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(AppPalette.critical.opacity(0.45), lineWidth: 1)
                )
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
                .disabled(isConnecting)

                Button(action: onConnect) {
                    HStack(spacing: 6) {
                        if isConnecting {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        }
                        Text(isConnecting ? "Connecting…" : "Connect")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty || isConnecting)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(width: 320)
        .background(.regularMaterial)
        .onAppear {
            isPasswordFocused = true
        }
    }
}

#Preview {
    PasswordPrompt(
        network: Network(
            id: "1",
            ssid: "Test Network",
            rssi: -50,
            channel: 36,
            security: .wpa2,
            isKnown: false
        ),
        password: .constant(""),
        errorMessage: nil,
        isConnecting: false,
        onConnect: {},
        onCancel: {}
    )
}
