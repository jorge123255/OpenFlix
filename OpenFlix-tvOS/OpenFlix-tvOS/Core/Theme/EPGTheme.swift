import SwiftUI

// MARK: - EPG Theme (Tivimate-inspired)
// Professional TV guide styling with dark theme and cyan accents

enum EPGTheme {
    // MARK: - Core Colors

    /// Near-black background (#0D0D0D)
    static let background = Color(red: 0.05, green: 0.05, blue: 0.05)

    /// Surface color for cards and panels (#1A1A1A)
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.10)

    /// Elevated surface for focused items (#242424)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.14)

    /// Card background (#1E1E1E)
    static let card = Color(red: 0.12, green: 0.12, blue: 0.12)

    // MARK: - Accent Colors

    /// Primary cyan accent (#00D4FF)
    static let accent = Color(red: 0, green: 0.83, blue: 1)

    /// Lighter cyan for glow effects
    static let accentGlow = Color(red: 0.3, green: 0.91, blue: 1)

    /// Dark cyan for backgrounds
    static let accentDark = Color(red: 0, green: 0.66, blue: 0.8)

    /// Pink/Red for live indicators (#FF4081)
    static let live = Color(red: 1, green: 0.25, blue: 0.51)

    /// Now line indicator color
    static let nowLine = Color.red

    // MARK: - Text Colors

    /// Primary text - bright white
    static let textPrimary = Color.white

    /// Secondary text - light gray (69% white)
    static let textSecondary = Color(white: 0.69)

    /// Muted text - dim gray (40% white)
    static let textMuted = Color(white: 0.4)

    // MARK: - Category Colors

    static let sports = Color(red: 0.06, green: 0.73, blue: 0.51)      // #0FBA83
    static let movie = Color(red: 0.94, green: 0.27, blue: 0.27)       // #F04646
    static let news = Color(red: 0.23, green: 0.51, blue: 0.96)        // #3B82F5
    static let kids = Color(red: 0.96, green: 0.62, blue: 0.04)        // #F59E0A
    static let documentary = Color(red: 0.55, green: 0.36, blue: 0.96) // #8C5CF5
    static let music = Color(red: 0.96, green: 0.36, blue: 0.72)       // #F55CB8
    static let entertainment = Color(red: 0.40, green: 0.85, blue: 0.50) // #66D980

    // MARK: - Program Cell Colors

    /// Normal program cell background
    static let programCell = Color(white: 0.10)

    /// Selected/focused program cell background
    static let programCellSelected = Color(red: 0.16, green: 0.23, blue: 0.25)

    /// Currently airing program background
    static let programCellLive = Color(red: 0.12, green: 0.15, blue: 0.18)

    // MARK: - State Colors

    static let success = Color(red: 0, green: 0.90, blue: 0.46)        // #00E676
    static let warning = Color(red: 1, green: 0.67, blue: 0)           // #FFAB00
    static let error = Color(red: 1, green: 0.32, blue: 0.32)          // #FF5252
    static let recording = Color(red: 1, green: 0.24, blue: 0.24)      // Red dot

    // MARK: - Badge Colors

    static let newBadge = Color.green
    static let liveBadge = live
    static let hdBadge = Color.blue
    static let fourKBadge = Color.yellow
    static let recBadge = recording

    // MARK: - Gradients

    static let playerGradient = LinearGradient(
        colors: [.clear, .black.opacity(0.9)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let topGradient = LinearGradient(
        colors: [.black.opacity(0.8), .clear],
        startPoint: .top,
        endPoint: .bottom
    )

    static let channelColumnGradient = LinearGradient(
        colors: [surface, surface.opacity(0.95)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Dimensions (tvOS optimized for 10-foot UI)

    enum Dimensions {
        /// Width of channel column in EPG
        static let channelColumnWidth: CGFloat = 280

        /// Width per 30-minute time slot
        static let timeSlotWidth: CGFloat = 300

        /// Height of each channel row
        static let rowHeight: CGFloat = 80

        /// Height of time header
        static let headerHeight: CGFloat = 60

        /// Height of category filter tabs
        static let categoryTabHeight: CGFloat = 50

        /// Channel logo size
        static let logoSize: CGFloat = 56

        /// Corner radius for cells
        static let cornerRadius: CGFloat = 8

        /// Focus scale effect
        static let focusScale: CGFloat = 1.05

        /// Focus border width
        static let focusBorderWidth: CGFloat = 4
    }

    // MARK: - Helper Functions

    /// Returns the appropriate category color for a program
    static func categoryColor(for category: String?) -> Color {
        guard let cat = category?.lowercased() else { return accent }

        if cat.contains("sport") { return sports }
        if cat.contains("movie") || cat.contains("film") { return movie }
        if cat.contains("news") { return news }
        if cat.contains("kid") || cat.contains("child") || cat.contains("cartoon") { return kids }
        if cat.contains("doc") { return documentary }
        if cat.contains("music") { return music }
        if cat.contains("entertain") || cat.contains("comedy") { return entertainment }

        return accent
    }

    /// Returns resolution badge color
    static func resolutionColor(height: Int?) -> Color {
        guard let h = height else { return textSecondary }
        if h >= 2160 { return fourKBadge }
        if h >= 1080 { return accent }
        return textSecondary
    }
}

// MARK: - Focus Style Modifiers

struct EPGFocusStyle: ViewModifier {
    let isFocused: Bool
    var borderColor: Color = EPGTheme.accent

    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? EPGTheme.Dimensions.focusScale : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: EPGTheme.Dimensions.cornerRadius)
                    .stroke(isFocused ? borderColor : .clear, lineWidth: EPGTheme.Dimensions.focusBorderWidth)
            )
            .shadow(color: isFocused ? borderColor.opacity(0.5) : .clear, radius: 10)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    func epgFocusStyle(isFocused: Bool, borderColor: Color = EPGTheme.accent) -> some View {
        modifier(EPGFocusStyle(isFocused: isFocused, borderColor: borderColor))
    }
}

// MARK: - Badge View

struct EPGBadge: View {
    let text: String
    let color: Color
    var textColor: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(4)
    }
}

// MARK: - Resolution Badge

struct ResolutionBadge: View {
    let height: Int?

    private var label: String {
        guard let h = height else { return "" }
        switch h {
        case 2160...: return "4K"
        case 1080...: return "1080p"
        case 720...: return "720p"
        case 480...: return "480p"
        default: return "\(h)p"
        }
    }

    private var icon: String? {
        guard let h = height else { return nil }
        return h >= 2160 ? "sparkles.tv" : (h >= 1080 ? "tv" : nil)
    }

    var body: some View {
        if !label.isEmpty {
            HStack(spacing: 4) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                }
                Text(label)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(EPGTheme.resolutionColor(height: height))
        }
    }
}

// MARK: - Live Indicator

struct LiveIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(EPGTheme.live)
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)

            Text("LIVE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(EPGTheme.live)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Progress Bar

struct EPGProgressBar: View {
    let progress: Double
    var height: CGFloat = 4
    var backgroundColor: Color = Color.white.opacity(0.2)
    var foregroundColor: Color = EPGTheme.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        EPGBadge(text: "NEW", color: EPGTheme.newBadge)
        EPGBadge(text: "LIVE", color: EPGTheme.liveBadge)
        EPGBadge(text: "HD", color: EPGTheme.hdBadge)

        ResolutionBadge(height: 2160)
        ResolutionBadge(height: 1080)
        ResolutionBadge(height: 720)

        LiveIndicator()

        EPGProgressBar(progress: 0.65)
            .frame(width: 200)
    }
    .padding()
    .background(EPGTheme.background)
}
