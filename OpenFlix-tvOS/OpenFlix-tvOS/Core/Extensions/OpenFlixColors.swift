import SwiftUI

/// OpenFlix color palette - Apple TV inspired with unique teal accent
/// Premium, modern design differentiated from Apple TV's white/gray
enum OpenFlixColors {
    // MARK: - Primary Brand Colors (Teal accent - differentiates from Apple TV)
    static let accent = Color(hex: "00D4AA")           // Primary teal accent
    static let accentDark = Color(hex: "00A888")       // Darker teal for pressed states
    static let accentLight = Color(hex: "33DFBB")      // Lighter teal for highlights
    static let accentGlow = Color(hex: "00D4AA").opacity(0.3) // Glow effect

    // Legacy names for compatibility
    static let primary = accent
    static let primaryDark = accentDark
    static let primaryLight = accentLight

    // MARK: - Secondary Colors
    static let secondary = Color(hex: "FF6B35")        // Orange for live/sports
    static let live = Color(hex: "FF3D3D")             // Live indicator red

    // MARK: - Background Colors (Deep dark grays)
    static let background = Color.black                 // True black for OLED
    static let backgroundElevated = Color(hex: "141414")
    static let surface = Color(hex: "1C1C1E")          // Card background (12pt rounded)
    static let surfaceElevated = Color(hex: "2C2C2E")  // Elevated card
    static let surfaceVariant = Color(hex: "242424")
    static let card = Color(hex: "1E1E1E")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // MARK: - State Colors
    static let success = Color(hex: "00E676")
    static let warning = Color(hex: "FFAB00")
    static let error = Color(hex: "FF5252")

    // MARK: - Focus Colors (tvOS)
    static let focusBorder = Color.white
    static let focusBackground = Color.white.opacity(0.1)

    // MARK: - Button Colors
    static let buttonPrimary = Color.white             // White pill button background
    static let buttonPrimaryText = Color.black         // Black text on white button
    static let buttonSecondary = Color.white.opacity(0.2) // Circular button background
    static let buttonSecondaryText = Color.white

    // MARK: - Overlays
    static let overlay = Color.black.opacity(0.5)
    static let overlayDark = Color.black.opacity(0.9)
    static let overlayLight = Color.black.opacity(0.3)

    // MARK: - Progress Bar
    static let progressBackground = Color.white.opacity(0.3)
    static let progressFill = Color(hex: "FF3D3D")     // Red progress

    // MARK: - Content Rating Badge Colors
    static let ratingBadgeBackground = Color.white.opacity(0.2)
    static let ratingBadgeBorder = Color.white.opacity(0.3)

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [background, accentDark.opacity(0.2), background],
        startPoint: .top,
        endPoint: .bottom
    )

    // Hero gradient - left-aligned content style
    static let heroGradient = LinearGradient(
        colors: [.black.opacity(0.8), .black.opacity(0.4), .clear],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Bottom gradient for hero
    static let heroBottomGradient = LinearGradient(
        colors: [.clear, .black.opacity(0.3), .black.opacity(0.8), .black],
        startPoint: .top,
        endPoint: .bottom
    )

    // Side gradient for detail views
    static let sideGradient = LinearGradient(
        colors: [.black.opacity(0.9), .black.opacity(0.6), .clear],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Corner Radius Constants
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16

    // MARK: - Animation Durations
    static let animationFast: Double = 0.15
    static let animationNormal: Double = 0.25
    static let animationSlow: Double = 0.35
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
