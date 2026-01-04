package com.openflix.presentation.screens.media

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.Button
import androidx.tv.material3.ButtonDefaults
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
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
                    relatedItems = uiState.relatedItems,
                    onBack = onBack,
                    onPlay = { onPlayMedia(uiState.mediaItem!!.id) },
                    onRelatedClick = { item -> onPlayMedia(item.id) }
                )
            }
        }
    }
}

@Composable
private fun MediaDetailContent(
    mediaItem: MediaItem,
    relatedItems: List<MediaItem>,
    onBack: () -> Unit,
    onPlay: () -> Unit,
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

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
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

                    Spacer(modifier = Modifier.height(24.dp))

                    // Action buttons
                    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        Button(onClick = onPlay) {
                            Text(
                                text = when {
                                    mediaItem.viewOffset != null && mediaItem.viewOffset > 0 -> "Resume"
                                    mediaItem.type == MediaType.SHOW -> "Play S1E1"
                                    else -> "Play"
                                }
                            )
                        }

                        Button(
                            onClick = { /* Add to watchlist */ },
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.SurfaceVariant
                            )
                        ) {
                            Text("Add to Watchlist")
                        }

                        if (mediaItem.type == MediaType.SHOW) {
                            Button(
                                onClick = { /* Shuffle play */ },
                                colors = ButtonDefaults.colors(
                                    containerColor = OpenFlixColors.SurfaceVariant
                                )
                            ) {
                                Text("Shuffle")
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

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
