package com.openflix.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object OpenFlixColors {
    // Primary accent — Purple
    val Primary = Color(0xFF6138F5)
    val PrimaryDark = Color(0xFF4A2BC7)
    val PrimaryLight = Color(0xFF7B5CF7)

    // Secondary accent
    val Secondary = Color(0xFFFF6B35)

    // Background colors — Dark navy
    val Background = Color(0xFF151028)
    val Surface = Color(0xFF1E1832)
    val SurfaceVariant = Color(0xFF2E2E32)
    val SurfaceElevated = Color(0xFF2C2C3E)
    val Card = Color(0xFF222234)

    // Text colors
    val TextPrimary = Color.White
    val TextSecondary = Color(0xB3FFFFFF)   // White 70%
    val TextTertiary = Color(0x80FFFFFF)    // White 50%
    val TextMuted = Color(0x4DFFFFFF)       // White 30%
    val OnPrimary = Color.White

    // State colors
    val Success = Color(0xFF00E676)
    val Warning = Color(0xFFFFAB00)
    val Error = Color(0xFFFF5252)
    val Info = Color(0xFF6138F5)
    val LiveIndicator = Color(0xFFD0021B)

    // Progress
    val ProgressBackground = Color(0x4DFFFFFF)
    val ProgressFill = Color(0xFFD0021B)

    // Divider/Border
    val Divider = Color(0x26FFFFFF)
    val TabBar = Color(0xFF1E1832)
}

private val DarkColorScheme = darkColorScheme(
    primary = OpenFlixColors.Primary,
    secondary = OpenFlixColors.Secondary,
    background = OpenFlixColors.Background,
    surface = OpenFlixColors.Surface,
    error = OpenFlixColors.Error,
    onPrimary = Color.White,
    onSecondary = Color.Black,
    onBackground = OpenFlixColors.TextPrimary,
    onSurface = OpenFlixColors.TextPrimary,
    onError = Color.White
)

@Composable
fun OpenFlixTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
