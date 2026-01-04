package com.openflix.presentation.screens.home

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

/**
 * Modern Home/Discover screen with Fubo-style layout
 */
@Composable
fun DiscoverScreen(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    viewModel: DiscoverViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadHomeContent()
    }

    when {
        uiState.isLoading -> {
            LoadingScreen()
        }
        uiState.error != null -> {
            ErrorScreen(
                message = uiState.error!!,
                onRetry = viewModel::loadHomeContent
            )
        }
        else -> {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(OpenFlixColors.Background),
                contentPadding = PaddingValues(bottom = 48.dp)
            ) {
                // Hero Section
                uiState.featuredItem?.let { featured ->
                    item {
                        ModernHeroSection(
                            mediaItem = featured,
                            onPlay = { onPlayClick(featured.id) },
                            onDetails = { onMediaClick(featured.id) }
                        )
                    }
                }

                // Content Rows
                items(uiState.hubs) { hub ->
                    ModernHubSection(
                        hub = hub,
                        onItemClick = { mediaItem -> onMediaClick(mediaItem.id) },
                        onPlayClick = { mediaItem -> onPlayClick(mediaItem.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun ModernHeroSection(
    mediaItem: MediaItem,
    onPlay: () -> Unit,
    onDetails: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(520.dp)  // Taller hero for more impact
    ) {
        // Background - either image or gradient placeholder
        val imageUrl = mediaItem.backdropUrl ?: mediaItem.posterUrl
        if (imageUrl != null) {
            AsyncImage(
                model = imageUrl,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // Premium gradient placeholder background
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                OpenFlixColors.Primary.copy(alpha = 0.2f),
                                OpenFlixColors.PrimaryDark.copy(alpha = 0.1f),
                                OpenFlixColors.Background
                            ),
                            start = androidx.compose.ui.geometry.Offset(0f, 0f),
                            end = androidx.compose.ui.geometry.Offset(1500f, 1500f)
                        )
                    )
            )
        }

        // Multi-layer gradient overlays for depth
        // Left fade for text readability
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            OpenFlixColors.Background.copy(alpha = 0.95f),
                            OpenFlixColors.Background.copy(alpha = 0.7f),
                            OpenFlixColors.Background.copy(alpha = 0.3f),
                            Color.Transparent
                        ),
                        startX = 0f,
                        endX = 900f
                    )
                )
        )

        // Bottom gradient for seamless transition
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Transparent,
                            OpenFlixColors.Background.copy(alpha = 0.6f),
                            OpenFlixColors.Background
                        ),
                        startY = 100f
                    )
                )
        )

        // Vignette effect at top for polish
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            OpenFlixColors.Background.copy(alpha = 0.4f),
                            Color.Transparent
                        )
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(start = 56.dp, end = 56.dp, bottom = 56.dp, top = 100.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            // Title with text shadow effect
            Text(
                text = mediaItem.title,
                style = MaterialTheme.typography.displayMedium.copy(
                    fontSize = 52.sp,
                    letterSpacing = (-0.5).sp
                ),
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Metadata row with refined styling
            Row(
                modifier = Modifier.padding(top = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                mediaItem.year?.let { year ->
                    Text(
                        text = year.toString(),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                    )
                }

                // Separator dot
                if (mediaItem.year != null && (mediaItem.contentRating != null || mediaItem.duration != null)) {
                    Box(
                        modifier = Modifier
                            .size(4.dp)
                            .background(
                                color = OpenFlixColors.TextSecondary,
                                shape = CircleShape
                            )
                    )
                }

                mediaItem.contentRating?.let { rating ->
                    Box(
                        modifier = Modifier
                            .background(
                                color = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f),
                                shape = RoundedCornerShape(4.dp)
                            )
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = rating,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                        )
                    }
                }

                mediaItem.duration?.let { duration ->
                    val hours = duration / 3600000
                    val minutes = (duration % 3600000) / 60000
                    val durationText = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
                    Text(
                        text = durationText,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                    )
                }

                // Quality badge
                Box(
                    modifier = Modifier
                        .background(
                            color = OpenFlixColors.Primary.copy(alpha = 0.15f),
                            shape = RoundedCornerShape(4.dp)
                        )
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "HD",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.Primary
                    )
                }
            }

            // Summary with better line height
            mediaItem.summary?.let { summary ->
                Text(
                    text = summary,
                    style = MaterialTheme.typography.bodyLarge.copy(
                        lineHeight = 28.sp
                    ),
                    color = OpenFlixColors.TextSecondary,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .padding(top = 20.dp)
                        .widthIn(max = 650.dp)
                )
            }

            // Action buttons with enhanced styling
            Row(
                modifier = Modifier.padding(top = 28.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Play button
                HeroPlayButton(
                    text = if (mediaItem.viewOffset != null && mediaItem.viewOffset > 0) "Resume" else "Play",
                    onClick = onPlay
                )

                // More Info button
                HeroSecondaryButton(
                    text = "More Info",
                    onClick = onDetails
                )
            }
        }
    }
}

@Composable
private fun HeroPlayButton(
    text: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        label = "playButtonScale"
    )

    Surface(
        onClick = onClick,
        modifier = Modifier
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused },
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
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        label = "secondaryButtonScale"
    )

    val backgroundColor by animateColorAsState(
        targetValue = if (isFocused) OpenFlixColors.SurfaceHighlight else OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f),
        label = "secondaryButtonBg"
    )

    Surface(
        onClick = onClick,
        modifier = Modifier
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = backgroundColor,
            focusedContainerColor = OpenFlixColors.SurfaceHighlight
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
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
                imageVector = Icons.Filled.Info,
                contentDescription = null,
                tint = OpenFlixColors.TextPrimary,
                modifier = Modifier.size(20.dp)
            )
            Text(
                text = text,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Medium,
                color = OpenFlixColors.TextPrimary
            )
        }
    }
}

@Composable
private fun ModernHubSection(
    hub: Hub,
    onItemClick: (MediaItem) -> Unit,
    onPlayClick: (MediaItem) -> Unit
) {
    Column(
        modifier = Modifier.padding(top = 40.dp)
    ) {
        // Section Title with refined styling
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 56.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = hub.title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextPrimary
            )

            // Item count badge
            if (hub.size > 0) {
                Text(
                    text = "${hub.size} titles",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Horizontal scroll of items with better spacing
        LazyRow(
            contentPadding = PaddingValues(horizontal = 56.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            items(hub.items) { item ->
                MediaCard(
                    mediaItem = item,
                    onClick = { onItemClick(item) },
                    width = 200.dp,  // Slightly larger cards
                    aspectRatio = 1.5f
                )
            }
        }
    }
}

@Composable
private fun LoadingScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Simple loading indicator
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(OpenFlixColors.Primary.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(OpenFlixColors.Primary)
                )
            }

            Text(
                text = "Loading...",
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.TextSecondary
            )
        }
    }
}

@Composable
private fun ErrorScreen(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.Error
            )

            var isFocused by remember { mutableStateOf(false) }

            Surface(
                onClick = onRetry,
                modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.SurfaceVariant,
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
                    text = "Retry",
                    style = MaterialTheme.typography.titleMedium,
                    color = OpenFlixColors.TextPrimary,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                )
            }
        }
    }
}
