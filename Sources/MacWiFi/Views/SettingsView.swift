import SwiftUI

struct SettingsView: View {
    @ObservedObject var licenseManager: LemonSqueezyLicenseManager

    var body: some View {
        LicenseGateView(licenseManager: licenseManager, surface: .settings)
    }
}
