package com.openflix.presentation.components

import android.app.Activity
import android.view.WindowManager
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/**
 * Gesture overlay for video player - handles swipe gestures for volume and brightness
 * Left side: Brightness control
 * Right side: Volume control
 */
@Composable
fun GestureOverlay(
    modifier: Modifier = Modifier,
    currentVolume: Int,
    onVolumeChange: (Int) -> Unit,
    enabled: Boolean = true
) {
    val context = LocalContext.current
    val activity = context as? Activity

    // Gesture state
    var showVolumeIndicator by remember { mutableStateOf(false) }
    var showBrightnessIndicator by remember { mutableStateOf(false) }
    var currentBrightness by remember { mutableFloatStateOf(0.5f) }
    var displayVolume by remember { mutableIntStateOf(currentVolume) }

    // Initialize brightness from window
    LaunchedEffect(Unit) {
        activity?.window?.attributes?.let { attrs ->
            currentBrightness = if (attrs.screenBrightness < 0) 0.5f else attrs.screenBrightness
        }
    }

    // Hide indicators after delay
    LaunchedEffect(showVolumeIndicator) {
        if (showVolumeIndicator) {
            delay(1500)
            showVolumeIndicator = false
        }
    }

    LaunchedEffect(showBrightnessIndicator) {
        if (showBrightnessIndicator) {
            delay(1500)
            showBrightnessIndicator = false
        }
    }

    // Update display volume when prop changes
    LaunchedEffect(currentVolume) {
        displayVolume = currentVolume
    }

    Box(modifier = modifier.fillMaxSize()) {
        if (enabled) {
            // Left side - Brightness control
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(0.5f)
                    .align(Alignment.CenterStart)
                    .pointerInput(Unit) {
                        detectVerticalDragGestures(
                            onDragStart = { showBrightnessIndicator = true },
                            onDragEnd = { /* Keep showing for delay */ },
                            onVerticalDrag = { _, dragAmount ->
                                // Swipe up = brighter, swipe down = dimmer
                                val delta = -dragAmount / size.height * 0.5f
                                currentBrightness = (currentBrightness + delta).coerceIn(0.01f, 1f)

                                // Apply brightness to window
                                activity?.window?.let { window ->
                                    val attrs = window.attributes
                                    attrs.screenBrightness = currentBrightness
                                    window.attributes = attrs
                                }
                                showBrightnessIndicator = true
                            }
                        )
                    }
            )

            // Right side - Volume control
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(0.5f)
                    .align(Alignment.CenterEnd)
                    .pointerInput(Unit) {
                        detectVerticalDragGestures(
                            onDragStart = { showVolumeIndicator = true },
                            onDragEnd = { /* Keep showing for delay */ },
                            onVerticalDrag = { _, dragAmount ->
                                // Swipe up = louder, swipe down = quieter
                                val delta = -dragAmount / size.height * 100
                                displayVolume = (displayVolume + delta.toInt()).coerceIn(0, 100)
                                onVolumeChange(displayVolume)
                                showVolumeIndicator = true
                            }
                        )
                    }
            )
        }

        // Volume indicator
        AnimatedVisibility(
            visible = showVolumeIndicator,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            GestureIndicator(
                icon = when {
                    displayVolume == 0 -> Icons.Default.VolumeOff
                    displayVolume < 50 -> Icons.Default.VolumeDown
                    else -> Icons.Default.VolumeUp
                },
                label = "Volume",
                value = displayVolume / 100f,
                displayValue = "$displayVolume%"
            )
        }

        // Brightness indicator
        AnimatedVisibility(
            visible = showBrightnessIndicator,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            GestureIndicator(
                icon = when {
                    currentBrightness < 0.3f -> Icons.Default.BrightnessLow
                    currentBrightness < 0.7f -> Icons.Default.BrightnessMedium
                    else -> Icons.Default.BrightnessHigh
                },
                label = "Brightness",
                value = currentBrightness,
                displayValue = "${(currentBrightness * 100).toInt()}%"
            )
        }
    }
}

@Composable
private fun GestureIndicator(
    icon: ImageVector,
    label: String,
    value: Float,
    displayValue: String
) {
    Box(
        modifier = Modifier
            .background(Color.Black.copy(alpha = 0.85f), RoundedCornerShape(16.dp))
            .padding(24.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = Color.White,
                modifier = Modifier.size(48.dp)
            )

            Text(
                text = displayValue,
                color = Color.White,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )

            LinearProgressIndicator(
                progress = value,
                modifier = Modifier
                    .width(120.dp)
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp)),
                color = Color.White,
                trackColor = Color.White.copy(alpha = 0.3f)
            )

            Text(
                text = label,
                color = Color.Gray,
                fontSize = 12.sp
            )
        }
    }
}
