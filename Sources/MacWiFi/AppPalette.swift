import SwiftUI
import AppKit

enum AppPalette {
    // Semantic palette tuned to native macOS menu aesthetics.
    static let surfaceBase = Color(nsColor: .windowBackgroundColor)
    static let surfaceRaised = Color(nsColor: .controlBackgroundColor)
    static let surfaceSoft = Color(nsColor: .underPageBackgroundColor)
    static let borderSoft = Color(nsColor: .separatorColor)
    static let textMuted = Color(nsColor: .secondaryLabelColor)

    static let accent = Color(nsColor: .controlAccentColor)
    static let accentStrong = Color(nsColor: .controlAccentColor)
    static let accentMedium = Color(nsColor: .systemIndigo)
    static let accentSoft = Color(nsColor: .systemBlue).opacity(0.75)
    static let accentFaint = Color(nsColor: .selectedContentBackgroundColor).opacity(0.14)
    static let accentBackground = Color(nsColor: .selectedContentBackgroundColor).opacity(0.28)

    static let graphDownload = Color(nsColor: .systemGreen)
    static let graphUpload = Color(nsColor: .systemBlue)

    static let critical = Color(nsColor: .systemIndigo)
    static let criticalSoft = Color(nsColor: .systemIndigo).opacity(0.82)
    static let criticalBackground = Color(nsColor: .selectedContentBackgroundColor).opacity(0.22)
}
