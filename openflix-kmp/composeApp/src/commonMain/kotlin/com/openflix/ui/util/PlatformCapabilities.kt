package com.openflix.ui.util

/**
 * Whether the platform's video player can natively play MKV containers.
 * Android (ExoPlayer/mpv) can, iOS (AVPlayer) cannot.
 */
expect val platformSupportsMKV: Boolean

/**
 * Whether the platform uses a native full-screen player (presented modally).
 * iOS: true (AVPlayerViewController presented natively, bypasses Compose rendering).
 * Android: false (uses Compose VideoPlayerScreen with ExoPlayer/mpv).
 */
expect val platformUsesNativePlayer: Boolean
