import SwiftUI

enum LicenseGateSurface {
    case popover
    case settings
}

struct LicenseGateView: View {
    @ObservedObject var licenseManager: LemonSqueezyLicenseManager
    let surface: LicenseGateSurface
    var showsBackground: Bool = true

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
        .background {
            if showsBackground {
                backgroundLayer
            }
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
                    Button(action: activateLicense) {
                        HStack(spacing: 7) {
                            if licenseManager.isWorking {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.8)
                            }
                            Text(licenseManager.isWorking ? "Activating…" : "Activate")
                        }
                        .frame(minWidth: 104)
                    }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(isActivateDisabled)

                    Button("Buy") {
                        licenseManager.openCheckout(source: isPopover ? "license_popover" : "license_settings")
                    }
                    .disabled(licenseManager.isWorking)
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
        VStack(alignment: .leading, spacing: 14) {
            heroCard
            activationCard
            supportCard
        }
        .padding(isPopover ? 16 : 24)
        .frame(width: isPopover ? 420 : 620, height: isPopover ? 300 : 360, alignment: .topLeading)
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
        HStack(spacing: 14) {
            licensedHeroIcon

            VStack(alignment: .leading, spacing: 4) {
                Text("License active")
                    .font(.system(size: isPopover ? 21 : 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("This Mac is activated.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppPalette.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.75), lineWidth: 1)
        )
    }

    private var licensedHeroIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                   let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                } else {
                    Image(systemName: "wifi")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .foregroundStyle(AppPalette.accentStrong)
                        .background(AppPalette.accentFaint)
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppPalette.borderSoft.opacity(0.45), lineWidth: 1)
            )

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(nsColor: .systemGreen))
                .background(Color(nsColor: .windowBackgroundColor), in: Circle())
                .offset(x: 4, y: 4)
        }
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
        Group {
            if let state = licenseManager.state, state.isLicensed {
                licensedStateSection(state)
            } else {
                lockedStateSection
            }
        }
    }

    @ViewBuilder
    private func licensedStateSection(_ state: LemonSqueezyLicenseManager.LicenseState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            statusRow(title: "Status", value: "Active on this Mac")
            statusRow(title: "License Key", value: state.maskedKey)

            if licenseManager.isWorking {
                ProgressView("Contacting the license server…")
                    .controlSize(.small)
            }

            if let errorMessage = licenseManager.errorMessage, !errorMessage.isEmpty {
                errorBanner(errorMessage)
            }

            HStack {
                Spacer()
                Button("Deactivate This Mac", role: .destructive) {
                    showDeactivateConfirmation = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppPalette.borderSoft.opacity(0.55), lineWidth: 1)
        )
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
        HStack {
            Spacer()

            Link(destination: URL(string: "https://macwifi.live/help/activate-license")!) {
                HStack(spacing: 6) {
                    Text("Need help with activation?")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
            }
        }
        .foregroundStyle(AppPalette.accentStrong)
    }

    private var isActivateDisabled: Bool {
        licenseManager.isWorking || licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
}
