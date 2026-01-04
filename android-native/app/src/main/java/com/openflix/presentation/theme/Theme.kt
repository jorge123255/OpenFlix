package com.openflix.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.darkColorScheme

/**
 * OpenFlix dark color scheme for TV
 * Modern streaming app aesthetic with refined dark palette
 */
private val OpenFlixDarkColorScheme = darkColorScheme(
    primary = OpenFlixColors.Primary,
    onPrimary = OpenFlixColors.OnPrimary,
    primaryContainer = OpenFlixColors.PrimaryDark,
    onPrimaryContainer = OpenFlixColors.OnSurface,
    secondary = OpenFlixColors.Secondary,
    onSecondary = OpenFlixColors.OnSurface,
    secondaryContainer = OpenFlixColors.SecondaryDark,
    onSecondaryContainer = OpenFlixColors.OnSurface,
    background = OpenFlixColors.Background,
    onBackground = OpenFlixColors.OnBackground,
    surface = OpenFlixColors.Surface,
    onSurface = OpenFlixColors.OnSurface,
    surfaceVariant = OpenFlixColors.SurfaceVariant,
    onSurfaceVariant = OpenFlixColors.TextSecondary,
    error = OpenFlixColors.Error,
    onError = OpenFlixColors.OnSurface,
    errorContainer = OpenFlixColors.Error,
    onErrorContainer = OpenFlixColors.OnSurface,
    border = OpenFlixColors.Border,
    borderVariant = OpenFlixColors.FocusBorder
)

/**
 * Extended colors not covered by Material theme
 */
data class ExtendedColors(
    val success: androidx.compose.ui.graphics.Color = OpenFlixColors.Success,
    val warning: androidx.compose.ui.graphics.Color = OpenFlixColors.Warning,
    val info: androidx.compose.ui.graphics.Color = OpenFlixColors.Info,
    val live: androidx.compose.ui.graphics.Color = OpenFlixColors.Live,
    val liveIndicator: androidx.compose.ui.graphics.Color = OpenFlixColors.LiveIndicator,
    val liveBadge: androidx.compose.ui.graphics.Color = OpenFlixColors.LiveBadge,
    val recording: androidx.compose.ui.graphics.Color = OpenFlixColors.Recording,
    val upcoming: androidx.compose.ui.graphics.Color = OpenFlixColors.Upcoming,
    val sports: androidx.compose.ui.graphics.Color = OpenFlixColors.Sports,
    val overlay: androidx.compose.ui.graphics.Color = OpenFlixColors.Overlay,
    val overlayDark: androidx.compose.ui.graphics.Color = OpenFlixColors.OverlayDark,
    val overlayLight: androidx.compose.ui.graphics.Color = OpenFlixColors.OverlayLight,
    val progressBackground: androidx.compose.ui.graphics.Color = OpenFlixColors.ProgressBackground,
    val progressFill: androidx.compose.ui.graphics.Color = OpenFlixColors.ProgressFill,
    val focusBorder: androidx.compose.ui.graphics.Color = OpenFlixColors.FocusBorder,
    val focusBackground: androidx.compose.ui.graphics.Color = OpenFlixColors.FocusBackground,
    val focusGlow: androidx.compose.ui.graphics.Color = OpenFlixColors.FocusGlow,
    val card: androidx.compose.ui.graphics.Color = OpenFlixColors.Card,
    val cardHover: androidx.compose.ui.graphics.Color = OpenFlixColors.CardHover,
    val textPrimary: androidx.compose.ui.graphics.Color = OpenFlixColors.TextPrimary,
    val textSecondary: androidx.compose.ui.graphics.Color = OpenFlixColors.TextSecondary,
    val textTertiary: androidx.compose.ui.graphics.Color = OpenFlixColors.TextTertiary,
    val textMuted: androidx.compose.ui.graphics.Color = OpenFlixColors.TextMuted,
    val sidebarBackground: androidx.compose.ui.graphics.Color = OpenFlixColors.SidebarBackground,
    val sidebarHover: androidx.compose.ui.graphics.Color = OpenFlixColors.SidebarHover,
    val sidebarSelected: androidx.compose.ui.graphics.Color = OpenFlixColors.SidebarSelected,
    val accent: androidx.compose.ui.graphics.Color = OpenFlixColors.Accent
)

val LocalExtendedColors = staticCompositionLocalOf { ExtendedColors() }

/**
 * Access extended colors through this object
 */
object OpenFlixThemeColors {
    val extended: ExtendedColors
        @Composable
        get() = LocalExtendedColors.current
}

/**
 * Main theme composable for OpenFlix TV app
 */
@Composable
fun OpenFlixTheme(
    content: @Composable () -> Unit
) {
    val extendedColors = ExtendedColors()

    CompositionLocalProvider(
        LocalExtendedColors provides extendedColors
    ) {
        MaterialTheme(
            colorScheme = OpenFlixDarkColorScheme,
            typography = OpenFlixTypography,
            content = content
        )
    }
}
