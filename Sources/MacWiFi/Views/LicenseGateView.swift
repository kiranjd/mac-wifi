import SwiftUI

enum LicenseGateSurface {
    case popover
    case settings
}

struct LicenseGateView: View {
    @ObservedObject var licenseManager: LemonSqueezyLicenseManager
    let surface: LicenseGateSurface

    @State private var licenseKey = ""
    @State private var showDeactivateConfirmation = false
    @FocusState private var isLicenseFieldFocused: Bool

    private var isPopover: Bool {
        surface == .popover
    }

    var body: some View {
        Group {
            if licenseManager.isLicensed {
                licensedLayout
            } else {
                lockedLayout
            }
        }
        .background(backgroundLayer)
        .confirmationDialog(
            "Deactivate this Mac?",
            isPresented: $showDeactivateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deactivate This Mac", role: .destructive) {
                deactivateLicense()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("MacWiFi will lock again on this Mac until you activate it with a valid license key.")
        }
        .task {
            await licenseManager.validate(forceRemote: false)
        }
        .onAppear {
            guard !licenseManager.isLicensed else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isLicenseFieldFocused = true
            }
        }
    }

    private var lockedLayout: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                appIcon

                VStack(alignment: .leading, spacing: 6) {
                    Text("MacWiFi")
                        .font(.system(size: isPopover ? 28 : 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("MacWiFi helps you figure out whether the problem is your Wi-Fi or your internet connection. It checks packet loss, jitter, latency, and path quality from the menu bar.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .focused($isLicenseFieldFocused)
                    .onSubmit(activateLicense)

                HStack(spacing: 10) {
                    Button("Activate", action: activateLicense)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(isActivateDisabled)

                    Button("Buy") {
                        licenseManager.openCheckout(source: isPopover ? "license_popover" : "license_settings")
                    }
                }

                if licenseManager.isWorking {
                    ProgressView("Activating MacWiFi…")
                        .controlSize(.small)
                }

                if let errorMessage = licenseManager.errorMessage, !errorMessage.isEmpty {
                    errorBanner(errorMessage)
                }
            }
        }
        .padding(isPopover ? 24 : 28)
        .frame(width: isPopover ? 420 : 620, height: isPopover ? 260 : 280, alignment: .topLeading)
    }

    private var licensedLayout: some View {
        ScrollView(showsIndicators: !isPopover) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                activationCard
                supportCard

                if !isPopover {
                    aboutCard
                }
            }
            .padding(isPopover ? 18 : 24)
        }
        .frame(width: isPopover ? 420 : 620, height: isPopover ? 540 : 520)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppPalette.surfaceBase,
                    AppPalette.surfaceSoft.opacity(0.96),
                    AppPalette.surfaceRaised.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppPalette.accentBackground)
                .frame(width: 240, height: 240)
                .blur(radius: 44)
                .offset(x: 160, y: -180)

            Circle()
                .fill(AppPalette.criticalBackground.opacity(0.9))
                .frame(width: 180, height: 180)
                .blur(radius: 32)
                .offset(x: -150, y: -140)
        }
        .ignoresSafeArea()
    }

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 16) {
            appIcon

            VStack(alignment: .leading, spacing: 10) {
                Text("MacWiFi is activated on this Mac.")
                    .font(.system(size: isPopover ? 24 : 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(heroDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)

                HStack(spacing: 8) {
                    LicenseBenefitPill(title: "One-time purchase")
                    LicenseBenefitPill(title: "Per-Mac activation")
                    LicenseBenefitPill(title: "Direct email key")
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.75), lineWidth: 1)
        )
    }

    private var appIcon: some View {
        Group {
            if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
            } else {
                Image(systemName: "wifi")
                    .resizable()
                    .scaledToFit()
                    .padding(16)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.accentStrong, AppPalette.accentMedium],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }

    private var activationCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                if let state = licenseManager.state, state.isLicensed {
                    licensedStateSection(state)
                } else {
                    lockedStateSection
                }
            }
            .padding(2)
        } label: {
            Label(
                licenseManager.isLicensed ? "License Status" : "Activate License",
                systemImage: licenseManager.isLicensed ? "checkmark.shield" : "key.horizontal"
            )
            .font(.system(size: 13, weight: .semibold))
        }
        .groupBoxStyle(.automatic)
    }

    @ViewBuilder
    private func licensedStateSection(_ state: LemonSqueezyLicenseManager.LicenseState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            statusRow(title: "Status", value: "Active on this Mac")
            statusRow(title: "License Key", value: state.maskedKey)
            statusRow(title: "Last Validation", value: formattedValidationDate(state.lastValidatedAt))

            if let expiresAt = state.expiresAt {
                statusRow(title: "Expires", value: formattedDate(expiresAt))
            }

            if licenseManager.isWorking {
                ProgressView("Contacting the license server…")
                    .controlSize(.small)
            }

            if let errorMessage = licenseManager.errorMessage, !errorMessage.isEmpty {
                errorBanner(errorMessage)
            }

            HStack(spacing: 10) {
                Button("Validate Now") {
                    Task { await licenseManager.validate(forceRemote: true) }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Deactivate This Mac", role: .destructive) {
                    showDeactivateConfirmation = true
                }
            }
        }
    }

    private var lockedStateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paste the license key from your purchase email. Until activation succeeds, MacWiFi stays locked on this Mac.")
                .font(.system(size: 13))
                .foregroundStyle(AppPalette.textMuted)

            TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .focused($isLicenseFieldFocused)
                .onSubmit(activateLicense)

            if licenseManager.isWorking {
                ProgressView("Activating MacWiFi…")
                    .controlSize(.small)
            }

            if let errorMessage = licenseManager.errorMessage, !errorMessage.isEmpty {
                errorBanner(errorMessage)
            }

            HStack(spacing: 10) {
                Button("Activate", action: activateLicense)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isActivateDisabled)

                Button("Buy") {
                    licenseManager.openCheckout(source: isPopover ? "license_popover" : "license_settings")
                }

                Spacer()
            }

            Text("Already bought MacWiFi? The purchase email also includes a one-click activation link that can open the app automatically.")
                .font(.system(size: 12))
                .foregroundStyle(AppPalette.textMuted)
        }
    }

    private var supportCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Need a key, a receipt, or help with activation?")
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)

                HStack(spacing: 10) {
                    Link("Activation Guide", destination: URL(string: "https://macwifi.live/help/activate-license")!)
                    Link("Email Support", destination: URL(string: "mailto:support@macwifi.live")!)
                }
            }
            .padding(2)
        } label: {
            Label("Support", systemImage: "questionmark.circle")
                .font(.system(size: 13, weight: .semibold))
        }
    }

    private var aboutCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                statusRow(title: "Version", value: appVersion)
                Text("MacWiFi is a native menu bar utility for diagnosing whether the problem is your Wi-Fi, your router, or the path beyond it.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)
            }
            .padding(2)
        } label: {
            Label("About", systemImage: "info.circle")
                .font(.system(size: 13, weight: .semibold))
        }
    }

    private var isActivateDisabled: Bool {
        licenseManager.isWorking || licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var heroDescription: String {
        "Your license is active, validated locally on this Mac, and ready for background checks, network scans, and diagnostics."
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

    private func deactivateLicense() {
        Task {
            do {
                try await licenseManager.deactivate()
            } catch {
                licenseManager.errorMessage = error.localizedDescription
            }
        }
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(AppPalette.textMuted)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.system(size: 13))
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedValidationDate(_ date: Date?) -> String {
        guard let date else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct LicenseBenefitPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppPalette.accentFaint, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AppPalette.borderSoft.opacity(0.45), lineWidth: 1)
            )
    }
}
