package com.openflix.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * OpenFlix color palette - Xfinity-inspired purple/navy theme
 * Matches the iOS app design language exactly.
 */
object OpenFlixColors {
    // Primary brand colors - Purple accent (matches iOS Xfinity theme)
    val Primary = Color(0xFF6138F5)         // Xfinity purple accent
    val PrimaryDark = Color(0xFF5B3DC4)
    val PrimaryLight = Color(0xFF8B5FF8)
    val PrimaryMuted = Color(0xFF4B2DB4)    // For subtle accents

    // Secondary accent (orange for live/sports)
    val Secondary = Color(0xFFFF6B35)       // Orange for live indicators
    val SecondaryDark = Color(0xFFE55A25)
    val Accent = Color(0xFF7B4FE8)          // Purple variant for actions

    // Background colors - Deep navy blue (matches iOS #110C21)
    val Background = Color(0xFF110C21)      // Deep navy
    val BackgroundElevated = Color(0xFF160F2A)
    val Surface = Color(0xFF1A142E)         // Tab bar / cards (matches iOS)
    val SurfaceVariant = Color(0xFF1F1F2E)  // Hover/secondary surfaces
    val SurfaceHighlight = Color(0xFF2A2440) // Highlighted surfaces
    val Card = Color(0xFF1F1F2E)            // Card backgrounds (matches iOS cardBackground)
    val CardHover = Color(0xFF2A2450)       // Card hover state

    // Sidebar specific (TV - slightly darker navy)
    val SidebarBackground = Color(0xFF0D0918)
    val SidebarHover = Color(0xFF1A142E)
    val SidebarSelected = Color(0xFF241E3A)

    // Text colors (matches iOS opacity-based text)
    val OnBackground = Color(0xFFFFFFFF)    // Primary text
    val OnSurface = Color(0xFFFFFFFF)
    val OnPrimary = Color(0xFFFFFFFF)       // White text on purple
    val TextPrimary = Color(0xFFFFFFFF)     // White
    val TextSecondary = Color(0xB2FFFFFF)   // White 70% opacity (iOS textSecondary)
    val TextTertiary = Color(0x80FFFFFF)    // White 50% opacity (iOS textTertiary)
    val TextMuted = Color(0x4DFFFFFF)       // White 30% opacity

    // State colors
    val Success = Color(0xFF00E676)         // Green
    val Warning = Color(0xFFFF6B35)         // Orange (matches iOS warning)
    val Error = Color(0xFFFF5252)           // Red
    val Info = Color(0xFF6138F5)            // Purple (brand)
    val Live = Color(0xFFFF0000)            // Red for LIVE badge (matches iOS)

    // Focus colors (for TV navigation)
    val FocusBorder = Color(0xFF6138F5)     // Purple border on focus
    val FocusBackground = Color(0x336138F5) // Subtle purple overlay
    val FocusGlow = Color(0x406138F5)       // Purple glow effect

    // Live TV specific
    val LiveIndicator = Color(0xFFFF0000)   // Red LIVE dot (matches iOS)
    val LiveBadge = Color(0xFFFF0000)       // LIVE badge background
    val Recording = Color(0xFFFF3D3D)
    val Upcoming = Color(0xFF6138F5)        // Purple for upcoming
    val Sports = Color(0xFFFF6B35)          // Orange for sports

    // Overlay colors
    val Overlay = Color(0x80000000)         // 50% black
    val OverlayDark = Color(0xE6000000)     // 90% black
    val OverlayLight = Color(0x40000000)    // 25% black
    val OverlayGradientStart = Color(0x00000000)
    val OverlayGradientEnd = Color(0x99000000) // 60% black (iOS cardGradient)

    // Progress colors (matches iOS - white progress on translucent track)
    val ProgressBackground = Color(0x4DFFFFFF)  // White 30% (iOS progressBackground)
    val ProgressFill = Color(0xFFFFFFFF)    // White progress bar (iOS)
    val ProgressFillAlt = Color(0xFF6138F5) // Purple alternative

    // Divider/Border (matches iOS white 15% opacity)
    val Divider = Color(0x26FFFFFF)
    val Border = Color(0x26FFFFFF)          // White 15% (iOS border)
    val BorderSubtle = Color(0x1AFFFFFF)    // White 10%

    // Gradients (as color pairs)
    val HeroGradientStart = Color(0x00000000)
    val HeroGradientEnd = Color(0xF0110C21)  // Fade to navy background

    // Channel/Category colors
    val NewsColor = Color(0xFF3B82F5)       // Blue
    val SportsColor = Color(0xFF0FBA83)     // Green (matches iOS EPG sports)
    val EntertainmentColor = Color(0xFF66D980) // Green
    val KidsColor = Color(0xFFF59E0A)       // Amber (matches iOS EPG kids)
    val MoviesColor = Color(0xFFF04646)     // Red (matches iOS EPG movie)
}
