import SwiftUI

// MARK: - Xfinity Design System (shared)

struct XfinityColors {
    static let background = Color(red: 0.06, green: 0.06, blue: 0.12)
    static let backgroundPrimary = background
    static let backgroundTertiary = Color(red: 0.12, green: 0.12, blue: 0.18)

    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.18)
    static let border = Color.white.opacity(0.15)

    static let accentPrimary = Color(red: 0.40, green: 0.30, blue: 0.90)
    static let progress = Color.white
    static let progressBackground = Color.white.opacity(0.3)
    static let progressBar = Color.white

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let textInverse = Color.black

    static let warning = Color.orange
    static let live = Color.red
    static let shimmer = Color.white.opacity(0.08)

    static let cardGradient = LinearGradient(
        colors: [Color.black.opacity(0.0), Color.black.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct XfinitySpacing {
    static let p2: CGFloat = 8
    static let p3: CGFloat = 12
    static let p4: CGFloat = 16
    static let p6: CGFloat = 24
    static let p8: CGFloat = 32

    static let galleryOuterPadding: CGFloat = 16
    static let galleryItemSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
}

struct XfinityDimensions {
    static let posterWidth: CGFloat = 120
    static let posterHeight: CGFloat = 180
    static let landscapeWidth: CGFloat = 220
    static let landscapeHeight: CGFloat = 124
    static let channelTileWidth: CGFloat = 120
    static let channelTileHeight: CGFloat = 70

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16

    static let progressBarHeight: CGFloat = 4
}

struct XfinityTypography {
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 24, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)
    static let callout = Font.system(size: 15, weight: .regular)
    static let calloutBold = Font.system(size: 15, weight: .semibold)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionBold = Font.system(size: 12, weight: .semibold)
    static let footnote = Font.system(size: 13, weight: .regular)
}

struct XfinityOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(XfinityColors.textPrimary)
            .padding(.horizontal, XfinitySpacing.p4)
            .padding(.vertical, XfinitySpacing.p2)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: XfinityDimensions.cornerRadiusMedium)
                    .stroke(XfinityColors.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct XfinityPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(XfinityColors.textInverse)
            .padding(.horizontal, XfinitySpacing.p4)
            .padding(.vertical, XfinitySpacing.p2)
            .background(XfinityColors.accentPrimary)
            .cornerRadius(XfinityDimensions.cornerRadiusMedium)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
