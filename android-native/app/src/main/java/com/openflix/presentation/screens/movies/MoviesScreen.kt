package com.openflix.presentation.screens.movies

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.GenreHub
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.TrailerInfo
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.presentation.components.ContentType
import com.openflix.presentation.components.HeroCarousel
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

/**
 * Movies screen - shows only movie content with hero carousel and genre hubs
 */
@Composable
fun MoviesScreen(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onBrowseAll: () -> Unit,
    viewModel: MoviesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.loadMovies()
    }

    when {
        uiState.isLoading -> {
            LoadingScreen()
        }
        uiState.error != null -> {
            ErrorScreen(
                message = uiState.error!!,
                onRetry = viewModel::loadMovies
            )
        }
        else -> {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(OpenFlixColors.Background),
                contentPadding = PaddingValues(bottom = 48.dp)
            ) {
                // Hero Carousel Section
                item {
                    if (uiState.featuredItems.isNotEmpty()) {
                        HeroCarousel(
                            items = uiState.featuredItems,
                            trailers = uiState.trailers,
                            onPlayClick = { item -> onPlayClick(item.id) },
                            onInfoClick = { item -> onMediaClick(item.id) },
                            onTrailerClick = { _, trailer ->
                                // Open YouTube trailer
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(trailer.youtubeWatchUrl))
                                context.startActivity(intent)
                            },
                            contentType = ContentType.MOVIES
                        )
                    } else if (uiState.featuredItem != null) {
                        // Fallback to single hero if no featured items
                        MovieHeroSection(
                            mediaItem = uiState.featuredItem!!,
                            onPlay = { onPlayClick(uiState.featuredItem!!.id) },
                            onDetails = { onMediaClick(uiState.featuredItem!!.id) }
                        )
                    }
                }

                // Browse All Section
                item {
                    BrowseAllSection(
                        title = "Browse All",
                        subtitle = "Movies",
                        onClick = onBrowseAll
                    )
                }

                // Continue Watching Movies
                if (uiState.continueWatching.isNotEmpty()) {
                    item {
                        ContinueWatchingSection(
                            items = uiState.continueWatching,
                            onItemClick = onMediaClick,
                            onPlayClick = onPlayClick
                        )
                    }
                }

                // Genre Hub Sections
                items(uiState.genreHubs) { genreHub ->
                    GenreHubSection(
                        genreHub = genreHub,
                        onItemClick = { mediaItem -> onMediaClick(mediaItem.id) }
                    )
                }

                // Original Movie Hubs (for content not covered by genre hubs)
                items(uiState.hubs) { hub ->
                    // Skip if hub title matches any genre hub
                    if (uiState.genreHubs.none { it.genre.equals(hub.title, ignoreCase = true) }) {
                        MovieHubSection(
                            hub = hub,
                            onItemClick = { mediaItem -> onMediaClick(mediaItem.id) },
                            onPlayClick = { mediaItem -> onPlayClick(mediaItem.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun GenreHubSection(
    genreHub: GenreHub,
    onItemClick: (MediaItem) -> Unit
) {
    Column(modifier = Modifier.padding(top = 40.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 56.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = genreHub.genre,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextPrimary
            )
            Text(
                text = "${genreHub.items.size} movies",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        LazyRow(
            contentPadding = PaddingValues(horizontal = 56.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            items(genreHub.items) { item ->
                MediaCard(
                    mediaItem = item,
                    onClick = { onItemClick(item) },
                    width = 180.dp,
                    aspectRatio = 1.5f
                )
            }
        }
    }
}

@Composable
private fun MovieHeroSection(
    mediaItem: MediaItem,
    onPlay: () -> Unit,
    onDetails: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(480.dp)
    ) {
        // Background
        val imageUrl = mediaItem.backdropUrl ?: mediaItem.posterUrl
        if (imageUrl != null) {
            AsyncImage(
                model = imageUrl,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(start = 56.dp, end = 56.dp, bottom = 48.dp, top = 80.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            // Movies badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Movie,
                    contentDescription = null,
                    tint = OpenFlixColors.Primary,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = "MOVIES",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = OpenFlixColors.Primary,
                    letterSpacing = 2.sp
                )
            }

            Text(
                text = mediaItem.title,
                style = MaterialTheme.typography.displayMedium.copy(fontSize = 48.sp),
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

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
                PlayButton(
                    text = if (mediaItem.viewOffset != null && mediaItem.viewOffset > 0) "Resume" else "Play",
                    onClick = onPlay
                )
                SecondaryButton(text = "More Info", onClick = onDetails)
            }
        }
    }
}

@Composable
private fun ContinueWatchingSection(
    items: List<MediaItem>,
    onItemClick: (String) -> Unit,
    onPlayClick: (String) -> Unit
) {
    Column(modifier = Modifier.padding(top = 32.dp)) {
        Row(
            modifier = Modifier.padding(horizontal = 56.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.PlayArrow,
                contentDescription = null,
                tint = OpenFlixColors.Primary,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = "Continue Watching",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        LazyRow(
            contentPadding = PaddingValues(horizontal = 56.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            items(items) { item ->
                MediaCard(
                    mediaItem = item,
                    onClick = { onItemClick(item.id) },
                    width = 200.dp,
                    aspectRatio = 1.5f,
                    showProgress = true
                )
            }
        }
    }
}

@Composable
private fun MovieHubSection(
    hub: Hub,
    onItemClick: (MediaItem) -> Unit,
    onPlayClick: (MediaItem) -> Unit
) {
    Column(modifier = Modifier.padding(top = 40.dp)) {
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
            if (hub.size > 0) {
                Text(
                    text = "${hub.size} movies",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        LazyRow(
            contentPadding = PaddingValues(horizontal = 56.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            items(hub.items) { item ->
                MediaCard(
                    mediaItem = item,
                    onClick = { onItemClick(item) },
                    width = 180.dp,
                    aspectRatio = 1.5f
                )
            }
        }
    }
}

@Composable
private fun PlayButton(text: String, onClick: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
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
private fun SecondaryButton(text: String, onClick: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
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
                text = "Loading movies...",
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.TextSecondary
            )
        }
    }
}

@Composable
private fun ErrorScreen(message: String, onRetry: () -> Unit) {
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
            Surface(
                onClick = onRetry,
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.SurfaceVariant,
                    focusedContainerColor = OpenFlixColors.SurfaceHighlight
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

@Composable
private fun BrowseAllSection(
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 56.dp, vertical = 24.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Primary.copy(alpha = 0.15f),
            focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.3f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(16.dp)
            )
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .background(OpenFlixColors.Primary, RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Movie,
                        contentDescription = null,
                        tint = OpenFlixColors.Background,
                        modifier = Modifier.size(32.dp)
                    )
                }
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.TextPrimary
                    )
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                contentDescription = "Browse all",
                tint = OpenFlixColors.TextPrimary,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
