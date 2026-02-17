import SwiftUI

struct PasswordPrompt: View {
    let network: Network?
    @Binding var password: String
    let onConnect: () -> Void
    let onCancel: () -> Void

    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.secondary)

                if let network = network {
                    Text(network.ssid)
                        .font(.system(size: 14, weight: .semibold))

                    Text("Enter the password for this network")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // Password field
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                SecureField("", text: $password)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .focused($isPasswordFocused)
                    .onSubmit {
                        if !password.isEmpty {
                            onConnect()
                        }
                    }
            }

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button("Connect") {
                    onConnect()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(width: 300)
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
        onConnect: {},
        onCancel: {}
    )
}
