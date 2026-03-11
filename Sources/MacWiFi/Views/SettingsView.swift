import SwiftUI

struct SettingsView: View {
    @ObservedObject var licenseManager: LemonSqueezyLicenseManager
    @State private var licenseKey = ""

    var body: some View {
        Form {
            Section("License") {
                if let state = licenseManager.state, state.isLicensed {
                    LabeledContent("Status", value: "Active on this Mac")
                    LabeledContent("Key", value: state.maskedKey)

                    HStack {
                        Button("Validate Now") {
                            Task { await licenseManager.validate(forceRemote: true) }
                        }

                        Button("Deactivate This Mac", role: .destructive) {
                            Task {
                                do {
                                    try await licenseManager.deactivate()
                                } catch {
                                    licenseManager.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                } else {
                    Text("MacWiFi uses a one-time Lemon Squeezy license. Paste your key here, or buy a new one.")
                        .foregroundStyle(.secondary)

                    TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                        .onSubmit(activateLicense)

                    HStack {
                        Button("Activate", action: activateLicense)
                            .disabled(isActivateDisabled)

                        Button("Buy for $9.99") {
                            licenseManager.openCheckout(source: "settings")
                        }
                    }
                }

                if let errorMessage = licenseManager.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Activation Links") {
                Text("Purchase emails can open MacWiFi directly with `macwifi://activate?key=...`.")
                    .foregroundStyle(.secondary)
            }

            Section("Support") {
                Link("Activation Guide", destination: URL(string: "https://macwifi.live/help/activate-license")!)
                Link("Email support@macwifi.live", destination: URL(string: "mailto:support@macwifi.live")!)
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                Text("MacWiFi is a small native utility for checking whether the problem is your Wi-Fi or the path beyond it.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 600, height: 480)
        .task {
            await licenseManager.validate(forceRemote: false)
        }
    }

    private var isActivateDisabled: Bool {
        licenseManager.isWorking || licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func activateLicense() {
        let value = licenseKey
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            do {
                try await licenseManager.activate(licenseKey: value)
                licenseKey = ""
            } catch {
                licenseManager.errorMessage = error.localizedDescription
            }
        }
    }
}
