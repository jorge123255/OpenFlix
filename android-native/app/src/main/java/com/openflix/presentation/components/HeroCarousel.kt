package com.openflix.presentation.components

import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Tv
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.TrailerInfo
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * Auto-rotating hero carousel for featured content.
 * Displays multiple featured items with automatic advancement.
 */
@Composable
fun HeroCarousel(
    items: List<MediaItem>,
    trailers: Map<String, TrailerInfo> = emptyMap(),
    onPlayClick: (MediaItem) -> Unit,
    onInfoClick: (MediaItem) -> Unit,
    onTrailerClick: ((MediaItem, TrailerInfo) -> Unit)? = null,
    modifier: Modifier = Modifier,
    autoAdvanceInterval: Long = 10_000L,
    contentType: ContentType = ContentType.MOVIES
) {
    if (items.isEmpty()) return

    var currentIndex by remember { mutableIntStateOf(0) }
    var isPaused by remember { mutableStateOf(false) }

    // Auto-advance timer
    LaunchedEffect(currentIndex, isPaused) {
        if (!isPaused && items.size > 1) {
            delay(autoAdvanceInterval)
            currentIndex = (currentIndex + 1) % items.size
        }
    }

    val currentItem = items[currentIndex]

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(480.dp)
    ) {
        // Animated background
        AnimatedContent(
            targetState = currentItem,
            transitionSpec = {
                fadeIn(animationSpec = tween(500)) togetherWith
                    fadeOut(animationSpec = tween(500))
            },
            label = "hero_background"
        ) { item ->
            // Use trailer for this specific item, not the outer scope currentTrailer
            val itemTrailer = trailers[item.id]
            val imageUrl = itemTrailer?.thumbnailUrl
                ?: item.backdropUrl
                ?: item.posterUrl

            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
        }

        // Gradients
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            OpenFlixColors.Background.copy(alpha = 0.95f),
                            OpenFlixColors.Background.copy(alpha = 0.6f),
                            Color.Transparent
                        )
                    )
                )
        )

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            OpenFlixColors.Background.copy(alpha = 0.8f),
                            OpenFlixColors.Background
                        ),
                        startY = 200f
                    )
                )
        )

        // Content
        AnimatedContent(
            targetState = currentItem,
            transitionSpec = {
                (fadeIn(animationSpec = tween(400)) + slideInHorizontally { it / 4 }) togetherWith
                    (fadeOut(animationSpec = tween(300)) + slideOutHorizontally { -it / 4 })
            },
            label = "hero_content"
        ) { item ->
            HeroContent(
                mediaItem = item,
                trailer = trailers[item.id],
                contentType = contentType,
                onPlayClick = { onPlayClick(item) },
                onInfoClick = { onInfoClick(item) },
                onTrailerClick = onTrailerClick?.let { { trailer -> it(item, trailer) } },
                onFocusChanged = { isFocused -> isPaused = isFocused }
            )
        }

        // Page indicator
        if (items.size > 1) {
            PageIndicator(
                pageCount = items.size,
                currentPage = currentIndex,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp)
            )
        }
    }
}

@Composable
private fun HeroContent(
    mediaItem: MediaItem,
    trailer: TrailerInfo?,
    contentType: ContentType,
    onPlayClick: () -> Unit,
    onInfoClick: () -> Unit,
    onTrailerClick: ((TrailerInfo) -> Unit)?,
    onFocusChanged: (Boolean) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(start = 56.dp, end = 56.dp, bottom = 64.dp, top = 80.dp),
        verticalArrangement = Arrangement.Bottom
    ) {
        // Content type badge
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(bottom = 12.dp)
        ) {
            Icon(
                imageVector = contentType.icon,
                contentDescription = null,
                tint = OpenFlixColors.Primary,
                modifier = Modifier.size(20.dp)
            )
            Text(
                text = contentType.label,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.Primary,
                letterSpacing = 2.sp
            )
        }

        // Title
        val displayTitle = when (mediaItem.type) {
            MediaType.EPISODE -> mediaItem.grandparentTitle ?: mediaItem.title
            else -> mediaItem.title
        }

        Text(
            text = displayTitle,
            style = MaterialTheme.typography.displayMedium.copy(fontSize = 48.sp),
            fontWeight = FontWeight.Bold,
            color = OpenFlixColors.TextPrimary,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )

        // Episode info if applicable
        if (mediaItem.type == MediaType.EPISODE) {
            Text(
                text = "S${mediaItem.parentIndex} E${mediaItem.index} - ${mediaItem.title}",
                style = MaterialTheme.typography.titleLarge,
                color = OpenFlixColors.TextSecondary,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        // Metadata
        Row(
            modifier = Modifier.padding(top = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            mediaItem.year?.let {
                Text(
                    text = it.toString(),
                    style = MaterialTheme.typography.titleMedium,
                    color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                )
            }
            mediaItem.contentRating?.let {
                Box(
                    modifier = Modifier
                        .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.labelMedium,
                        color = OpenFlixColors.TextPrimary
                    )
                }
            }
            when (mediaItem.type) {
                MediaType.MOVIE -> {
                    mediaItem.duration?.let {
                        val hours = it / 3600000
                        val minutes = (it % 3600000) / 60000
                        Text(
                            text = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m",
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                        )
                    }
                }
                MediaType.SHOW -> {
                    mediaItem.childCount?.let { seasons ->
                        Text(
                            text = "$seasons Season${if (seasons > 1) "s" else ""}",
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                        )
                    }
                }
                else -> {}
            }
            // Genre tags (first 2)
            if (mediaItem.genres.isNotEmpty()) {
                mediaItem.genres.take(2).forEach { genre ->
                    Text(
                        text = genre,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
        }

        // Summary
        mediaItem.summary?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .padding(top = 16.dp)
                    .widthIn(max = 600.dp)
            )
        }

        // Buttons
        Row(
            modifier = Modifier.padding(top = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            val playText = when {
                mediaItem.viewOffset != null && mediaItem.viewOffset > 0 -> "Resume"
                mediaItem.type == MediaType.SHOW -> "Watch Now"
                else -> "Play"
            }

            HeroPlayButton(
                text = playText,
                onClick = onPlayClick,
                onFocusChanged = onFocusChanged
            )

            HeroSecondaryButton(
                text = "More Info",
                onClick = onInfoClick,
                onFocusChanged = onFocusChanged
            )

            // Trailer button if available
            if (trailer != null && onTrailerClick != null) {
                HeroSecondaryButton(
                    text = "Trailer",
                    onClick = { onTrailerClick(trailer) },
                    onFocusChanged = onFocusChanged
                )
            }
        }
    }
}

@Composable
private fun HeroPlayButton(
    text: String,
    onClick: () -> Unit,
    onFocusChanged: (Boolean) -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { onFocusChanged(it.isFocused) },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.TextPrimary,
            focusedContainerColor = OpenFlixColors.TextPrimary
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(3.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(8.dp)
            )
        )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.PlayArrow,
                contentDescription = null,
                tint = OpenFlixColors.Background,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = text,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.Background
            )
        }
    }
}

@Composable
private fun HeroSecondaryButton(
    text: String,
    onClick: () -> Unit,
    onFocusChanged: (Boolean) -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { onFocusChanged(it.isFocused) },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f),
            focusedContainerColor = OpenFlixColors.SurfaceHighlight
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(8.dp)
            )
        )
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextPrimary,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
        )
    }
}

enum class ContentType(val label: String, val icon: ImageVector) {
    MOVIES("MOVIES", Icons.Filled.Movie),
    TV_SHOWS("TV SHOWS", Icons.Filled.Tv),
    ALL("FEATURED", Icons.Filled.VideoLibrary)
}
