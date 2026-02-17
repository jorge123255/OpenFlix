package com.openflix.presentation.screens.playlist

import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PlaylistPlay
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.foundation.lazy.grid.TvGridCells
import androidx.tv.foundation.lazy.grid.TvLazyVerticalGrid
import androidx.tv.foundation.lazy.grid.items
import androidx.tv.foundation.lazy.list.TvLazyColumn
import androidx.tv.foundation.lazy.list.items
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.Playlist
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun PlaylistsScreen(
    onBack: () -> Unit,
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    viewModel: PlaylistsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0A0A0A))
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Header
            PlaylistsHeader(
                selectedPlaylist = uiState.selectedPlaylist,
                playlistCount = uiState.playlists.size,
                onBack = {
                    if (uiState.selectedPlaylist != null) {
                        viewModel.clearSelection()
                    } else {
                        onBack()
                    }
                }
            )

            // Content
            when {
                uiState.isLoading -> {
                    LoadingState()
                }
                uiState.error != null && uiState.playlists.isEmpty() -> {
                    ErrorState(
                        message = uiState.error!!,
                        onRetry = { viewModel.loadPlaylists() }
                    )
                }
                uiState.playlists.isEmpty() -> {
                    EmptyState()
                }
                uiState.selectedPlaylist != null -> {
                    // Show playlist items
                    PlaylistItemsView(
                        items = uiState.playlistItems,
                        isLoading = uiState.isLoadingItems,
                        onItemClick = onMediaClick,
                        onPlayClick = onPlayClick
                    )
                }
                else -> {
                    // Show playlists grid
                    PlaylistsGrid(
                        playlists = uiState.playlists,
                        onPlaylistClick = { viewModel.selectPlaylist(it) }
                    )
                }
            }
        }
    }
}

@Composable
private fun PlaylistsHeader(
    selectedPlaylist: Playlist?,
    playlistCount: Int,
    onBack: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 48.dp, vertical = 24.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Back button
        Surface(
            onClick = onBack,
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = Color.White.copy(alpha = 0.1f),
                focusedContainerColor = Color.White.copy(alpha = 0.2f)
            ),
            scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
        ) {
            Box(
                modifier = Modifier.padding(12.dp),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        // Icon
        Icon(
            imageVector = Icons.Filled.PlaylistPlay,
            contentDescription = null,
            tint = OpenFlixColors.Primary,
            modifier = Modifier.size(32.dp)
        )

        // Title
        Text(
            text = selectedPlaylist?.title ?: "My Playlists",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f, fill = false)
        )

        // Count badge
        if (selectedPlaylist == null && playlistCount > 0) {
            Box(
                modifier = Modifier
                    .background(OpenFlixColors.Primary, RoundedCornerShape(16.dp))
                    .padding(horizontal = 12.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "$playlistCount playlists",
                    style = MaterialTheme.typography.labelMedium,
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold
                )
            }
        } else if (selectedPlaylist != null) {
            selectedPlaylist.leafCount?.let { count ->
                Box(
                    modifier = Modifier
                        .background(OpenFlixColors.Primary, RoundedCornerShape(16.dp))
                        .padding(horizontal = 12.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "$count items",
                        style = MaterialTheme.typography.labelMedium,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

@Composable
private fun LoadingState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(3) { index ->
                    val infiniteTransition = rememberInfiniteTransition(label = "loading")
                    val alpha by infiniteTransition.animateFloat(
                        initialValue = 0.3f,
                        targetValue = 1f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(600, delayMillis = index * 200),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "dot_$index"
                    )
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .background(
                                OpenFlixColors.Primary.copy(alpha = alpha),
                                RoundedCornerShape(6.dp)
                            )
                    )
                }
            }
            Text(
                text = "Loading playlists...",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun ErrorState(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.Red.copy(alpha = 0.8f)
            )
            Surface(
                onClick = onRetry,
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Primary,
                    focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.8f)
                )
            ) {
                Text(
                    text = "Retry",
                    style = MaterialTheme.typography.labelLarge,
                    color = Color.White,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                )
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.PlaylistPlay,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.3f),
                modifier = Modifier.size(80.dp)
            )
            Text(
                text = "No playlists yet",
                style = MaterialTheme.typography.headlineSmall,
                color = Color.White.copy(alpha = 0.7f)
            )
            Text(
                text = "Create playlists to organize your content",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.5f)
            )
        }
    }
}

@Composable
private fun PlaylistsGrid(
    playlists: List<Playlist>,
    onPlaylistClick: (Playlist) -> Unit
) {
    TvLazyVerticalGrid(
        columns = TvGridCells.Adaptive(minSize = 240.dp),
        contentPadding = PaddingValues(horizontal = 48.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        items(playlists, key = { it.id }) { playlist ->
            PlaylistCard(
                playlist = playlist,
                onClick = { onPlaylistClick(playlist) }
            )
        }
    }
}

@Composable
private fun PlaylistCard(
    playlist: Playlist,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(240.dp)
            .height(180.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color(0xFF1A1A1A),
            focusedContainerColor = Color(0xFF252525)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = OpenFlixColors.Primary.copy(alpha = 0.3f),
                elevation = 16.dp
            )
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Thumbnail
            val imageUrl = playlist.composite ?: playlist.thumb
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = playlist.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                // Placeholder
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    OpenFlixColors.Primary.copy(alpha = 0.3f),
                                    OpenFlixColors.PrimaryDark.copy(alpha = 0.5f)
                                )
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.MusicNote,
                        contentDescription = null,
                        tint = Color.White.copy(alpha = 0.5f),
                        modifier = Modifier.size(48.dp)
                    )
                }
            }

            // Gradient overlay
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            )

            // Playlist type badge
            playlist.playlistType?.let { type ->
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(8.dp)
                        .background(OpenFlixColors.Primary, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = type.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            // Bottom info
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp)
            ) {
                Text(
                    text = playlist.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                playlist.leafCount?.let { count ->
                    Text(
                        text = "$count items",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }

                // Play button (visible on focus)
                if (isFocused) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Surface(
                        onClick = onClick,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(6.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Color.White,
                            focusedContainerColor = Color.White.copy(alpha = 0.9f)
                        ),
                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.PlayArrow,
                                contentDescription = null,
                                tint = Color.Black,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "View",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PlaylistItemsView(
    items: List<MediaItem>,
    isLoading: Boolean,
    onItemClick: (String) -> Unit,
    onPlayClick: (String) -> Unit
) {
    if (isLoading) {
        LoadingState()
        return
    }

    if (items.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "This playlist is empty",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
        return
    }

    TvLazyColumn(
        contentPadding = PaddingValues(horizontal = 48.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        items(items, key = { it.id }) { item ->
            PlaylistItemRow(
                item = item,
                onClick = { onItemClick(item.id) },
                onPlayClick = { onPlayClick(item.id) }
            )
        }
    }
}

@Composable
private fun PlaylistItemRow(
    item: MediaItem,
    onClick: () -> Unit,
    onPlayClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(100.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color(0xFF1A1A1A),
            focusedContainerColor = Color(0xFF252525)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Thumbnail
            AsyncImage(
                model = item.thumb,
                contentDescription = item.title,
                modifier = Modifier
                    .height(76.dp)
                    .aspectRatio(16f / 9f)
                    .clip(RoundedCornerShape(6.dp)),
                contentScale = ContentScale.Crop
            )

            // Info
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val typeText = when (item.type) {
                        MediaType.MOVIE -> "Movie"
                        MediaType.SHOW -> "Series"
                        MediaType.EPISODE -> "Episode"
                        else -> null
                    }
                    typeText?.let {
                        Text(
                            text = it,
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.Primary
                        )
                    }

                    item.year?.let { year ->
                        Text(
                            text = year.toString(),
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }

                    item.rating?.let { rating ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(2.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Star,
                                contentDescription = null,
                                tint = Color(0xFFFFD700),
                                modifier = Modifier.size(12.dp)
                            )
                            Text(
                                text = String.format("%.1f", rating),
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.6f)
                            )
                        }
                    }
                }

                item.duration?.let { duration ->
                    val minutes = duration / 60000
                    Text(
                        text = if (minutes >= 60) "${minutes / 60}h ${minutes % 60}m" else "${minutes}m",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.5f)
                    )
                }
            }

            // Play button
            if (isFocused) {
                Surface(
                    onClick = onPlayClick,
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(6.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = OpenFlixColors.Primary,
                        focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.8f)
                    ),
                    scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
                ) {
                    Icon(
                        imageVector = Icons.Filled.PlayArrow,
                        contentDescription = "Play",
                        tint = Color.White,
                        modifier = Modifier
                            .padding(12.dp)
                            .size(24.dp)
                    )
                }
            }
        }
    }
}
