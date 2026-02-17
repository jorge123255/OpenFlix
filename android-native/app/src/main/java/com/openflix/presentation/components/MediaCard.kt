package com.openflix.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.domain.model.watchProgress
import com.openflix.presentation.theme.OpenFlixColors

/**
 * Modern TV-optimized media card with refined focus handling
 */
@Composable
fun MediaCard(
    mediaItem: MediaItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    width: Dp = 180.dp,
    aspectRatio: Float = 1.5f,  // 2:3 for posters
    showTitle: Boolean = true,
    showProgress: Boolean = true,
    showBadge: Boolean = true
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.08f else 1f,
        animationSpec = tween(200),
        label = "cardScale"
    )

    // Elevation animation for depth
    val elevation by animateFloatAsState(
        targetValue = if (isFocused) 24f else 4f,
        animationSpec = tween(200),
        label = "cardElevation"
    )

    val cardHeight = width * aspectRatio

    Column(
        modifier = modifier
            .width(width)
            .scale(scale)
    ) {
        // Card with poster
        Surface(
            onClick = onClick,
            modifier = Modifier
                .fillMaxWidth()
                .height(cardHeight)
                .shadow(
                    elevation = elevation.dp,
                    shape = RoundedCornerShape(16.dp),
                    ambientColor = if (isFocused) OpenFlixColors.Primary.copy(alpha = 0.3f) else Color.Black,
                    spotColor = if (isFocused) OpenFlixColors.Primary.copy(alpha = 0.2f) else Color.Black
                )
                .onFocusChanged { isFocused = it.isFocused },
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = OpenFlixColors.Card,
                focusedContainerColor = OpenFlixColors.Card
            ),
            border = ClickableSurfaceDefaults.border(
                focusedBorder = Border(
                    border = BorderStroke(2.5.dp, OpenFlixColors.FocusBorder),
                    shape = RoundedCornerShape(16.dp)
                )
            ),
            scale = ClickableSurfaceDefaults.scale(focusedScale = 1f),
            glow = ClickableSurfaceDefaults.glow(
                focusedGlow = Glow(
                    elevation = 20.dp,
                    elevationColor = OpenFlixColors.Primary.copy(alpha = 0.25f)
                )
            )
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                // Poster Image or placeholder
                if (mediaItem.posterUrl != null) {
                    AsyncImage(
                        model = mediaItem.posterUrl,
                        contentDescription = mediaItem.title,
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(RoundedCornerShape(16.dp)),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    // Premium gradient placeholder with title initial
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(RoundedCornerShape(16.dp))
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(
                                        OpenFlixColors.SurfaceHighlight,
                                        OpenFlixColors.SurfaceVariant,
                                        OpenFlixColors.Card
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = mediaItem.title.take(1).uppercase(),
                            style = MaterialTheme.typography.displayMedium,
                            fontWeight = FontWeight.Bold,
                            color = OpenFlixColors.TextTertiary
                        )
                    }
                }

                // Bottom gradient for badges/progress
                if (showProgress && mediaItem.watchProgress > 0f) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        Color.Transparent,
                                        OpenFlixColors.OverlayDark
                                    )
                                )
                            )
                    )
                }

                // NEW badge
                if (showBadge && (mediaItem.viewCount == null || mediaItem.viewCount == 0)) {
                    val addedRecently = mediaItem.addedAt?.let {
                        (System.currentTimeMillis() / 1000 - it) < (7 * 24 * 60 * 60) // 7 days
                    } ?: false

                    if (addedRecently) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopStart)
                                .padding(8.dp)
                                .background(
                                    color = OpenFlixColors.Primary,
                                    shape = RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = "NEW",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = OpenFlixColors.OnPrimary
                            )
                        }
                    }
                }

                // Watch progress bar
                if (showProgress && mediaItem.watchProgress > 0f && mediaItem.watchProgress < 0.95f) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .padding(horizontal = 8.dp, vertical = 10.dp)
                    ) {
                        // Background track
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(4.dp)
                                .background(
                                    color = OpenFlixColors.ProgressBackground,
                                    shape = RoundedCornerShape(2.dp)
                                )
                        )
                        // Progress fill
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(mediaItem.watchProgress)
                                .height(4.dp)
                                .background(
                                    color = OpenFlixColors.ProgressFill,
                                    shape = RoundedCornerShape(2.dp)
                                )
                        )
                    }
                }

                // Watched indicator
                if (mediaItem.watchProgress >= 0.95f) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(8.dp)
                            .size(24.dp)
                            .background(
                                color = OpenFlixColors.Success,
                                shape = RoundedCornerShape(4.dp)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "✓",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
            }
        }

        // Title below card
        if (showTitle) {
            Spacer(modifier = Modifier.height(10.dp))

            val textColor by animateColorAsState(
                targetValue = if (isFocused) OpenFlixColors.TextPrimary else OpenFlixColors.TextSecondary,
                label = "titleColor"
            )

            Text(
                text = mediaItem.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isFocused) FontWeight.Medium else FontWeight.Normal,
                color = textColor,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Year / Episode info
            val subtitle = when {
                mediaItem.year != null -> mediaItem.year.toString()
                mediaItem.parentIndex != null && mediaItem.index != null ->
                    "S${mediaItem.parentIndex} E${mediaItem.index}"
                else -> null
            }
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary,
                    maxLines = 1
                )
            }
        }
    }
}

/**
 * Wide card for featured/continue watching content
 */
@Composable
fun WideMediaCard(
    mediaItem: MediaItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    showLiveBadge: Boolean = false
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.08f else 1f,
        animationSpec = tween(150),
        label = "wideCardScale"
    )

    Surface(
        onClick = onClick,
        modifier = modifier
            .width(320.dp)
            .height(180.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Card,
            focusedContainerColor = OpenFlixColors.Card
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(3.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevation = 16.dp,
                elevationColor = OpenFlixColors.FocusGlow
            )
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Background image
            AsyncImage(
                model = mediaItem.backdropUrl ?: mediaItem.posterUrl,
                contentDescription = mediaItem.title,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(12.dp)),
                contentScale = ContentScale.Crop
            )

            // Gradient overlay
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                OpenFlixColors.OverlayDark
                            ),
                            startY = 80f
                        )
                    )
            )

            // LIVE badge
            if (showLiveBadge) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(12.dp)
                        .background(
                            color = OpenFlixColors.LiveBadge,
                            shape = RoundedCornerShape(4.dp)
                        )
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "LIVE",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            // Title overlay at bottom
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .padding(12.dp)
            ) {
                Text(
                    text = mediaItem.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = OpenFlixColors.TextPrimary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                // Progress bar
                if (mediaItem.watchProgress > 0f && mediaItem.watchProgress < 0.95f) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(3.dp)
                            .background(
                                color = OpenFlixColors.ProgressBackground,
                                shape = RoundedCornerShape(2.dp)
                            )
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(mediaItem.watchProgress)
                                .height(3.dp)
                                .background(
                                    color = OpenFlixColors.ProgressFill,
                                    shape = RoundedCornerShape(2.dp)
                                )
                        )
                    }
                }
            }
        }
    }
}

/**
 * Compact version of MediaCard
 */
@Composable
fun CompactMediaCard(
    mediaItem: MediaItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    MediaCard(
        mediaItem = mediaItem,
        onClick = onClick,
        modifier = modifier,
        width = 150.dp,
        showTitle = true,
        showProgress = true
    )
}

/**
 * Large media card for featured content
 */
@Composable
fun FeaturedMediaCard(
    mediaItem: MediaItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    WideMediaCard(
        mediaItem = mediaItem,
        onClick = onClick,
        modifier = modifier
    )
}

/**
 * Wide card for continue watching
 */
@Composable
fun ContinueWatchingCard(
    mediaItem: MediaItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    WideMediaCard(
        mediaItem = mediaItem,
        onClick = onClick,
        modifier = modifier
    )
}
