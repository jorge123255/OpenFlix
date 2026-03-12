package com.openflix.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/**
 * Full-screen splash video that plays on every cold launch.
 * Tap anywhere to skip (with fade). Video natural end crossfades smoothly.
 */
@Composable
fun SplashVideoScreen(
    onFinished: () -> Unit
) {
    var skipping by remember { mutableStateOf(false) }
    var done by remember { mutableStateOf(false) }
    var showSkipHint by remember { mutableStateOf(false) }

    // Show "Tap to skip" after 3 seconds
    LaunchedEffect(Unit) {
        delay(3000)
        if (!skipping && !done) showSkipHint = true
    }

    // Hide skip hint when skipping
    LaunchedEffect(skipping) {
        if (skipping) showSkipHint = false
    }

    val alpha by animateFloatAsState(
        targetValue = if (skipping || done) 0f else 1f,
        animationSpec = tween(600, easing = EaseOutCubic),
        label = "splashFade",
        finishedListener = {
            if (!done) {
                done = true
                onFinished()
            }
        }
    )

    val skipHintAlpha by animateFloatAsState(
        targetValue = if (showSkipHint && !skipping) 1f else 0f,
        animationSpec = tween(800),
        label = "skipHint"
    )

    if (!done) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            // Video layer
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .alpha(alpha)
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() }
                    ) {
                        if (!skipping && !done) skipping = true
                    }
            ) {
                SplashVideoPlayer(
                    onVideoEnd = {
                        if (!skipping && !done) {
                            // Natural end — smooth fade out
                            skipping = true
                        }
                    },
                    onFadeOutAudio = {
                        // Called ~1.5s before end so platform can fade volume
                    }
                )
            }

            // "Tap to skip" hint
            if (skipHintAlpha > 0f) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .alpha(skipHintAlpha),
                    contentAlignment = Alignment.BottomCenter
                ) {
                    Text(
                        text = "Tap to skip",
                        color = Color.White.copy(alpha = 0.5f),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Light,
                        modifier = Modifier.padding(bottom = 48.dp)
                    )
                }
            }
        }
    }
}

private val EaseOutCubic = CubicBezierEasing(0.215f, 0.61f, 0.355f, 1.0f)

/**
 * Platform-specific video player for the splash video.
 * Plays the bundled splash_video.mp4 full-screen with sound.
 * Should fade audio volume in the last ~1.5 seconds.
 */
@Composable
expect fun SplashVideoPlayer(
    onVideoEnd: () -> Unit,
    onFadeOutAudio: () -> Unit = {}
)
