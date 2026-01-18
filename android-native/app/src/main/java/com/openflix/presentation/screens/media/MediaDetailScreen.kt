package com.openflix.presentation.screens.media

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.Button
import androidx.tv.material3.ButtonDefaults
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.openflix.domain.model.CastMember
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun MediaDetailScreen(
    mediaId: String,
    onBack: () -> Unit,
    onPlayMedia: (String) -> Unit,
    onNavigateToSeason: (String, Int) -> Unit,
    viewModel: MediaDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(mediaId) {
        viewModel.loadMediaDetail(mediaId)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading...", color = OpenFlixColors.TextSecondary)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(uiState.error!!, color = OpenFlixColors.Error)
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadMediaDetail(mediaId) }) {
                            Text("Retry")
                        }
                    }
                }
            }
            uiState.mediaItem != null -> {
                MediaDetailContent(
                    mediaItem = uiState.mediaItem!!,
                    seasons = uiState.seasons,
                    relatedItems = uiState.relatedItems,
                    onBack = onBack,
                    onPlay = { onPlayMedia(uiState.mediaItem!!.id) },
                    onSeasonClick = { season -> onNavigateToSeason(season.id, season.index) },
                    onRelatedClick = { item -> onPlayMedia(item.id) }
                )
            }
        }
    }
}

@Composable
private fun MediaDetailContent(
    mediaItem: MediaItem,
    seasons: List<com.openflix.domain.model.Season>,
    relatedItems: List<MediaItem>,
    onBack: () -> Unit,
    onPlay: () -> Unit,
    onSeasonClick: (com.openflix.domain.model.Season) -> Unit,
    onRelatedClick: (MediaItem) -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Background Art
        AsyncImage(
            model = mediaItem.backdropUrl ?: mediaItem.posterUrl,
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        // Gradient overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            OpenFlixColors.OverlayDark,
                            OpenFlixColors.Overlay,
                            OpenFlixColors.OverlayLight
                        )
                    )
                )
        )

        // Content - scrollable
        val scrollState = rememberScrollState()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(48.dp)
        ) {
            // Back button
            Button(
                onClick = onBack,
                colors = ButtonDefaults.colors(
                    containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                )
            ) {
                Text("Back")
            }

            Spacer(modifier = Modifier.height(32.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                // Poster
                AsyncImage(
                    model = mediaItem.posterUrl,
                    contentDescription = mediaItem.title,
                    modifier = Modifier
                        .width(200.dp)
                        .aspectRatio(2f / 3f)
                        .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.medium),
                    contentScale = ContentScale.Crop
                )

                Spacer(modifier = Modifier.width(32.dp))

                // Details
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = mediaItem.title,
                        style = MaterialTheme.typography.displaySmall,
                        color = OpenFlixColors.OnSurface
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Metadata row
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        mediaItem.year?.let { year ->
                            Text(
                                text = year.toString(),
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextSecondary
                            )
                        }

                        mediaItem.contentRating?.let { rating ->
                            Box(
                                modifier = Modifier
                                    .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.extraSmall)
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(rating, style = MaterialTheme.typography.labelMedium)
                            }
                        }

                        mediaItem.duration?.let { duration ->
                            val hours = duration / 3600000
                            val minutes = (duration % 3600000) / 60000
                            Text(
                                text = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m",
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextSecondary
                            )
                        }

                        mediaItem.rating?.let { rating ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("⭐", style = MaterialTheme.typography.bodyLarge)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "%.1f".format(rating),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = OpenFlixColors.TextSecondary
                                )
                            }
                        }
                    }

                    if (mediaItem.genres.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = mediaItem.genres.take(3).joinToString(" • "),
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextTertiary
                        )
                    }

                    // Tagline
                    mediaItem.tagline?.let { tagline ->
                        if (tagline.isNotBlank()) {
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "\"$tagline\"",
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Light,
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Summary
                    mediaItem.summary?.let { summary ->
                        Text(
                            text = summary,
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary,
                            maxLines = 4,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    // Director, Writers, Studio
                    Spacer(modifier = Modifier.height(16.dp))

                    if (mediaItem.directors.isNotEmpty()) {
                        Row {
                            Text(
                                text = "Director: ",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = OpenFlixColors.TextSecondary
                            )
                            Text(
                                text = mediaItem.directors.take(2).joinToString(", "),
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }

                    if (mediaItem.writers.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Row {
                            Text(
                                text = "Writers: ",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = OpenFlixColors.TextSecondary
                            )
                            Text(
                                text = mediaItem.writers.take(3).joinToString(", "),
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }

                    mediaItem.studio?.let { studio ->
                        Spacer(modifier = Modifier.height(4.dp))
                        Row {
                            Text(
                                text = "Studio: ",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = OpenFlixColors.TextSecondary
                            )
                            Text(
                                text = studio,
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Action buttons
                    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        Button(
                            onClick = onPlay,
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.Primary,
                                contentColor = OpenFlixColors.OnPrimary
                            )
                        ) {
                            Text(
                                text = when {
                                    mediaItem.viewOffset != null && mediaItem.viewOffset > 0 -> "▶ Resume"
                                    mediaItem.type == MediaType.SHOW -> "▶ Play S1E1"
                                    else -> "▶ Play"
                                },
                                color = OpenFlixColors.OnPrimary
                            )
                        }

                        Button(
                            onClick = { /* Add to watchlist */ },
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.SurfaceVariant,
                                contentColor = OpenFlixColors.OnSurface
                            )
                        ) {
                            Text(
                                text = "+ Watchlist",
                                color = OpenFlixColors.OnSurface
                            )
                        }

                        if (mediaItem.type == MediaType.SHOW) {
                            Button(
                                onClick = { /* Shuffle play */ },
                                colors = ButtonDefaults.colors(
                                    containerColor = OpenFlixColors.SurfaceVariant,
                                    contentColor = OpenFlixColors.OnSurface
                                )
                            ) {
                                Text(
                                    text = "⟳ Shuffle",
                                    color = OpenFlixColors.OnSurface
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Seasons section for TV Shows
            if (mediaItem.type == MediaType.SHOW && seasons.isNotEmpty()) {
                Text(
                    text = "Seasons",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(100.dp)
                ) {
                    items(seasons) { season ->
                        SeasonCard(
                            season = season,
                            onClick = { onSeasonClick(season) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // Cast section
            if (mediaItem.cast.isNotEmpty()) {
                Text(
                    text = "Cast",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(mediaItem.cast.take(10)) { castMember ->
                        CastCard(castMember = castMember)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // Related content
            if (relatedItems.isNotEmpty()) {
                Text(
                    text = "Related",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(relatedItems) { item ->
                        MediaCard(
                            mediaItem = item,
                            onClick = { onRelatedClick(item) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CastCard(castMember: CastMember) {
    Column(
        modifier = Modifier.width(100.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Actor photo
        AsyncImage(
            model = castMember.thumb,
            contentDescription = castMember.name,
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(OpenFlixColors.SurfaceVariant),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Actor name
        Text(
            text = castMember.name,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Character name
        castMember.role?.let { role ->
            Text(
                text = role,
                style = MaterialTheme.typography.labelSmall,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun SeasonCard(
    season: com.openflix.domain.model.Season,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .width(150.dp)
            .height(90.dp),
        shape = ButtonDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ButtonDefaults.colors(
            containerColor = OpenFlixColors.Surface.copy(alpha = 0.9f),
            contentColor = OpenFlixColors.OnSurface,
            focusedContainerColor = OpenFlixColors.Primary,
            focusedContentColor = OpenFlixColors.OnPrimary
        )
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(8.dp)
        ) {
            Text(
                text = season.title.ifEmpty { "Season ${season.index}" },
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.OnSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            season.leafCount?.let { count ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "$count episodes",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
            }
        }
    }
}
