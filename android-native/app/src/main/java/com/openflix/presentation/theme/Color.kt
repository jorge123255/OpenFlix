package com.openflix.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * OpenFlix color palette - Modern streaming app aesthetic
 * Inspired by premium streaming services like Fubo, Apple TV+, Disney+
 */
object OpenFlixColors {
    // Primary brand colors - Cyan/Teal accent (modern, not Netflix-red)
    val Primary = Color(0xFF00D4FF)         // Bright cyan accent
    val PrimaryDark = Color(0xFF00A8CC)
    val PrimaryLight = Color(0xFF5CE1FF)
    val PrimaryMuted = Color(0xFF0891B2)    // For subtle accents

    // Secondary accent (orange for live/sports)
    val Secondary = Color(0xFFFF6B35)       // Orange for live indicators
    val SecondaryDark = Color(0xFFE55A25)
    val Accent = Color(0xFFFF3D71)          // Pink/red for important actions

    // Background colors - Deep dark grays
    val Background = Color(0xFF0D0D0D)      // Near black
    val BackgroundElevated = Color(0xFF141414)
    val Surface = Color(0xFF1A1A1A)         // Cards/panels
    val SurfaceVariant = Color(0xFF242424)  // Hover/secondary surfaces
    val SurfaceHighlight = Color(0xFF2D2D2D) // Highlighted surfaces
    val Card = Color(0xFF1E1E1E)            // Card backgrounds
    val CardHover = Color(0xFF282828)       // Card hover state

    // Sidebar specific
    val SidebarBackground = Color(0xFF0A0A0A)
    val SidebarHover = Color(0xFF1A1A1A)
    val SidebarSelected = Color(0xFF242424)

    // Text colors
    val OnBackground = Color(0xFFFFFFFF)    // Primary text
    val OnSurface = Color(0xFFFFFFFF)
    val OnPrimary = Color(0xFF000000)       // Dark text on cyan
    val TextPrimary = Color(0xFFF5F5F5)     // Bright white
    val TextSecondary = Color(0xFFAAAAAA)   // Muted gray
    val TextTertiary = Color(0xFF666666)    // Subtle gray
    val TextMuted = Color(0xFF4D4D4D)       // Very subtle

    // State colors
    val Success = Color(0xFF00E676)         // Green
    val Warning = Color(0xFFFFAB00)         // Amber
    val Error = Color(0xFFFF5252)           // Red
    val Info = Color(0xFF40C4FF)            // Light blue
    val Live = Color(0xFFFF3D3D)            // Red for LIVE badge

    // Focus colors (for TV navigation)
    val FocusBorder = Color(0xFFFFFFFF)     // White border on focus
    val FocusBackground = Color(0x20FFFFFF) // Subtle white overlay
    val FocusGlow = Color(0x40FFFFFF)       // Glow effect

    // Live TV specific
    val LiveIndicator = Color(0xFFFF3D3D)   // Red LIVE dot
    val LiveBadge = Color(0xFFFF3D3D)       // LIVE badge background
    val Recording = Color(0xFFFF3D3D)
    val Upcoming = Color(0xFF40C4FF)
    val Sports = Color(0xFFFF6B35)          // Orange for sports

    // Overlay colors
    val Overlay = Color(0x80000000)         // 50% black
    val OverlayDark = Color(0xE6000000)     // 90% black
    val OverlayLight = Color(0x40000000)    // 25% black
    val OverlayGradientStart = Color(0x00000000)
    val OverlayGradientEnd = Color(0xCC000000)

    // Progress colors
    val ProgressBackground = Color(0xFF3D3D3D)
    val ProgressFill = Color(0xFFFF3D3D)    // Red progress bar
    val ProgressFillAlt = Color(0xFF00D4FF) // Cyan alternative

    // Divider/Border
    val Divider = Color(0xFF2D2D2D)
    val Border = Color(0xFF333333)
    val BorderSubtle = Color(0xFF222222)

    // Gradients (as color pairs)
    val HeroGradientStart = Color(0x00000000)
    val HeroGradientEnd = Color(0xF0000000)

    // Channel/Category colors
    val NewsColor = Color(0xFF2196F3)       // Blue
    val SportsColor = Color(0xFFFF6B35)     // Orange
    val EntertainmentColor = Color(0xFFE91E63) // Pink
    val KidsColor = Color(0xFF4CAF50)       // Green
    val MoviesColor = Color(0xFF9C27B0)     // Purple
}
