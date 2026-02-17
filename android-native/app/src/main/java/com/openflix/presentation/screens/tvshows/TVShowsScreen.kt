package com.openflix.presentation.screens.tvshows

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
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Tv
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
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.domain.model.watchProgress
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.presentation.components.ContentType
import com.openflix.presentation.components.HeroCarousel
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

/**
 * TV Shows screen - shows only TV show content with hero carousel and genre hubs
 */
@Composable
fun TVShowsScreen(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onBrowseAll: () -> Unit,
    viewModel: TVShowsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.loadTVShows()
    }

    when {
        uiState.isLoading -> {
            LoadingScreen()
        }
        uiState.error != null -> {
            ErrorScreen(
                message = uiState.error!!,
                onRetry = viewModel::loadTVShows
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
                            contentType = ContentType.TV_SHOWS
                        )
                    } else if (uiState.featuredItem != null) {
                        // Fallback to single hero if no featured items
                        TVShowHeroSection(
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
                        subtitle = "TV Shows",
                        onClick = onBrowseAll
                    )
                }

                // Continue Watching Episodes
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

                // Original TV Show Hubs (for content not covered by genre hubs)
                items(uiState.hubs) { hub ->
                    // Skip if hub title matches any genre hub
                    if (uiState.genreHubs.none { it.genre.equals(hub.title, ignoreCase = true) }) {
                        TVShowHubSection(
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
                text = "${genreHub.items.size} shows",
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
private fun TVShowHeroSection(
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
            // TV Shows badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Tv,
                    contentDescription = null,
                    tint = OpenFlixColors.Primary,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = "TV SHOWS",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = OpenFlixColors.Primary,
                    letterSpacing = 2.sp
                )
            }

            // Title - show grandparent title for episodes
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
                // Show season/episode count for shows
                if (mediaItem.type == MediaType.SHOW) {
                    mediaItem.childCount?.let { seasons ->
                        Text(
                            text = "$seasons Season${if (seasons > 1) "s" else ""}",
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.TextPrimary.copy(alpha = 0.9f)
                        )
                    }
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
                val playText = when {
                    mediaItem.type == MediaType.EPISODE && mediaItem.viewOffset != null && mediaItem.viewOffset > 0 -> "Resume"
                    mediaItem.type == MediaType.EPISODE -> "Play"
                    else -> "Watch Now"
                }
                PlayButton(text = playText, onClick = onPlay)
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
                EpisodeCard(
                    episode = item,
                    onClick = { onPlayClick(item.id) }
                )
            }
        }
    }
}

@Composable
private fun EpisodeCard(
    episode: MediaItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Card,
            focusedContainerColor = OpenFlixColors.Card
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column {
            // Episode thumbnail
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(157.dp)
            ) {
                AsyncImage(
                    model = episode.thumb ?: episode.posterUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Progress bar
                if (episode.viewOffset != null && episode.duration != null && episode.duration > 0) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .fillMaxWidth()
                            .height(4.dp)
                            .background(Color.Black.copy(alpha = 0.5f))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxHeight()
                                .fillMaxWidth(episode.watchProgress)
                                .background(OpenFlixColors.Primary)
                        )
                    }
                }
            }

            // Episode info
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                // Show title
                Text(
                    text = episode.grandparentTitle ?: "",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = OpenFlixColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                // Episode number
                Text(
                    text = "S${episode.parentIndex} E${episode.index}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary,
                    modifier = Modifier.padding(top = 2.dp)
                )

                // Episode title
                Text(
                    text = episode.title,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}

@Composable
private fun TVShowHubSection(
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
                    text = "${hub.size} shows",
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
                text = "Loading TV shows...",
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
                        imageVector = Icons.Filled.Tv,
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
