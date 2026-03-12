package com.openflix.presentation.screens.media

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.Button
import androidx.tv.material3.ButtonDefaults
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.openflix.domain.model.CastMember
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.PlaybackMode
import com.openflix.domain.model.PlaybackOption
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors
import com.openflix.util.DeviceType
import com.openflix.util.LocalDeviceType

@Composable
fun MediaDetailScreen(
    mediaId: String,
    onBack: () -> Unit,
    onPlayMedia: (String, Long?) -> Unit,
    onNavigateToSeason: (String, Int) -> Unit,
    viewModel: MediaDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val deviceType = LocalDeviceType.current

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
                if (deviceType.isTabletOrPhone) {
                    TabletMediaDetailContent(
                        mediaItem = uiState.mediaItem!!,
                        seasons = uiState.seasons,
                        relatedItems = uiState.relatedItems,
                        playbackOptions = uiState.playbackOptions,
                        selectedOption = uiState.selectedOption,
                        showVersionPicker = uiState.showVersionPicker,
                        onBack = onBack,
                        onPlay = {
                            onPlayMedia(uiState.mediaItem!!.id, uiState.selectedOption?.fileId)
                        },
                        onSeasonClick = { season -> onNavigateToSeason(season.id, season.index) },
                        onRelatedClick = { item -> onPlayMedia(item.id, null) },
                        onSelectOption = { viewModel.selectPlaybackOption(it) },
                        onToggleVersionPicker = { viewModel.toggleVersionPicker() }
                    )
                } else {
                    TVMediaDetailContent(
                        mediaItem = uiState.mediaItem!!,
                        seasons = uiState.seasons,
                        relatedItems = uiState.relatedItems,
                        playbackOptions = uiState.playbackOptions,
                        selectedOption = uiState.selectedOption,
                        showVersionPicker = uiState.showVersionPicker,
                        onBack = onBack,
                        onPlay = {
                            onPlayMedia(uiState.mediaItem!!.id, uiState.selectedOption?.fileId)
                        },
                        onSeasonClick = { season -> onNavigateToSeason(season.id, season.index) },
                        onRelatedClick = { item -> onPlayMedia(item.id, null) },
                        onSelectOption = { viewModel.selectPlaybackOption(it) },
                        onToggleVersionPicker = { viewModel.toggleVersionPicker() }
                    )
                }
            }
        }
    }
}

// === TV Layout (focus-based, uses tv.material3) ===

@Composable
private fun TVMediaDetailContent(
    mediaItem: MediaItem,
    seasons: List<com.openflix.domain.model.Season>,
    relatedItems: List<MediaItem>,
    playbackOptions: List<PlaybackOption>,
    selectedOption: PlaybackOption?,
    showVersionPicker: Boolean,
    onBack: () -> Unit,
    onPlay: () -> Unit,
    onSeasonClick: (com.openflix.domain.model.Season) -> Unit,
    onRelatedClick: (MediaItem) -> Unit,
    onSelectOption: (PlaybackOption) -> Unit,
    onToggleVersionPicker: () -> Unit
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
                    MetadataRow(mediaItem)

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
                    CrewInfo(mediaItem)

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

            // Version Picker
            if (playbackOptions.size > 1) {
                Spacer(modifier = Modifier.height(24.dp))
                VersionPickerSection(
                    options = playbackOptions,
                    selectedOption = selectedOption,
                    expanded = showVersionPicker,
                    onToggle = onToggleVersionPicker,
                    onSelect = onSelectOption,
                    isTv = true
                )
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

// === Tablet Layout (touch-friendly, uses material3) ===

@Composable
private fun TabletMediaDetailContent(
    mediaItem: MediaItem,
    seasons: List<com.openflix.domain.model.Season>,
    relatedItems: List<MediaItem>,
    playbackOptions: List<PlaybackOption>,
    selectedOption: PlaybackOption?,
    showVersionPicker: Boolean,
    onBack: () -> Unit,
    onPlay: () -> Unit,
    onSeasonClick: (com.openflix.domain.model.Season) -> Unit,
    onRelatedClick: (MediaItem) -> Unit,
    onSelectOption: (PlaybackOption) -> Unit,
    onToggleVersionPicker: () -> Unit
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
                .padding(32.dp)
        ) {
            // Back button (touch-friendly)
            androidx.compose.material3.TextButton(
                onClick = onBack
            ) {
                androidx.compose.material3.Text(
                    text = "← Back",
                    color = OpenFlixColors.TextPrimary,
                    fontSize = 16.sp
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                // Poster
                AsyncImage(
                    model = mediaItem.posterUrl,
                    contentDescription = mediaItem.title,
                    modifier = Modifier
                        .width(180.dp)
                        .aspectRatio(2f / 3f)
                        .clip(RoundedCornerShape(12.dp))
                        .background(OpenFlixColors.SurfaceVariant),
                    contentScale = ContentScale.Crop
                )

                Spacer(modifier = Modifier.width(24.dp))

                // Details
                Column(modifier = Modifier.weight(1f)) {
                    androidx.compose.material3.Text(
                        text = mediaItem.title,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.OnSurface
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Metadata row
                    TabletMetadataRow(mediaItem)

                    if (mediaItem.genres.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        androidx.compose.material3.Text(
                            text = mediaItem.genres.take(3).joinToString(" • "),
                            fontSize = 14.sp,
                            color = OpenFlixColors.TextTertiary
                        )
                    }

                    // Tagline
                    mediaItem.tagline?.let { tagline ->
                        if (tagline.isNotBlank()) {
                            Spacer(modifier = Modifier.height(12.dp))
                            androidx.compose.material3.Text(
                                text = "\"$tagline\"",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Light,
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Summary
                    mediaItem.summary?.let { summary ->
                        androidx.compose.material3.Text(
                            text = summary,
                            fontSize = 15.sp,
                            color = OpenFlixColors.TextSecondary,
                            maxLines = 4,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    // Director, Writers, Studio
                    Spacer(modifier = Modifier.height(16.dp))
                    TabletCrewInfo(mediaItem)

                    Spacer(modifier = Modifier.height(24.dp))

                    // Action buttons (touch-friendly)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        androidx.compose.material3.Button(
                            onClick = onPlay,
                            colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                                containerColor = OpenFlixColors.Primary,
                                contentColor = OpenFlixColors.OnPrimary
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            androidx.compose.material3.Text(
                                text = when {
                                    mediaItem.viewOffset != null && mediaItem.viewOffset > 0 -> "▶ Resume"
                                    mediaItem.type == MediaType.SHOW -> "▶ Play S1E1"
                                    else -> "▶ Play"
                                }
                            )
                        }

                        androidx.compose.material3.OutlinedButton(
                            onClick = { /* Add to watchlist */ },
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            androidx.compose.material3.Text(
                                text = "+ Watchlist",
                                color = OpenFlixColors.OnSurface
                            )
                        }
                    }
                }
            }

            // Version Picker
            if (playbackOptions.size > 1) {
                Spacer(modifier = Modifier.height(24.dp))
                VersionPickerSection(
                    options = playbackOptions,
                    selectedOption = selectedOption,
                    expanded = showVersionPicker,
                    onToggle = onToggleVersionPicker,
                    onSelect = onSelectOption,
                    isTv = false
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Seasons section for TV Shows
            if (mediaItem.type == MediaType.SHOW && seasons.isNotEmpty()) {
                androidx.compose.material3.Text(
                    text = "Seasons",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(90.dp)
                ) {
                    items(seasons) { season ->
                        TabletSeasonCard(
                            season = season,
                            onClick = { onSeasonClick(season) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // Cast section
            if (mediaItem.cast.isNotEmpty()) {
                androidx.compose.material3.Text(
                    text = "Cast",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(mediaItem.cast.take(10)) { castMember ->
                        TabletCastCard(castMember = castMember)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // Related content
            if (relatedItems.isNotEmpty()) {
                androidx.compose.material3.Text(
                    text = "Related",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
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

// === Shared Version Picker ===

@Composable
private fun VersionPickerSection(
    options: List<PlaybackOption>,
    selectedOption: PlaybackOption?,
    expanded: Boolean,
    onToggle: () -> Unit,
    onSelect: (PlaybackOption) -> Unit,
    isTv: Boolean
) {
    Column {
        // Collapsed header row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Surface.copy(alpha = 0.6f))
                .then(
                    if (isTv) Modifier else Modifier.clickable(onClick = onToggle)
                )
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Mode badge for selected option
                selectedOption?.let { option ->
                    PlaybackModeBadge(option.playbackMode)
                    Spacer(modifier = Modifier.width(12.dp))
                }

                if (isTv) {
                    Text(
                        text = "Version: ${selectedOption?.displayName ?: "Default"}",
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.OnSurface
                    )
                } else {
                    androidx.compose.material3.Text(
                        text = "Version: ${selectedOption?.displayName ?: "Default"}",
                        fontSize = 15.sp,
                        color = OpenFlixColors.OnSurface
                    )
                }
            }

            if (isTv) {
                Button(
                    onClick = onToggle,
                    colors = ButtonDefaults.colors(
                        containerColor = Color.Transparent
                    )
                ) {
                    Text(
                        text = if (expanded) "▲" else "▼",
                        color = OpenFlixColors.TextSecondary
                    )
                }
            } else {
                androidx.compose.material3.Text(
                    text = if (expanded) "▲" else "▼",
                    fontSize = 16.sp,
                    color = OpenFlixColors.TextSecondary
                )
            }
        }

        // Expanded options
        AnimatedVisibility(
            visible = expanded,
            enter = expandVertically(),
            exit = shrinkVertically()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                options.forEach { option ->
                    VersionOptionRow(
                        option = option,
                        isSelected = option.fileId == selectedOption?.fileId,
                        onClick = { onSelect(option) },
                        isTv = isTv
                    )
                }
            }
        }
    }
}

@Composable
private fun VersionOptionRow(
    option: PlaybackOption,
    isSelected: Boolean,
    onClick: () -> Unit,
    isTv: Boolean
) {
    val bgColor = if (isSelected) {
        OpenFlixColors.Surface.copy(alpha = 0.8f)
    } else {
        OpenFlixColors.Surface.copy(alpha = 0.4f)
    }

    if (isTv) {
        Button(
            onClick = onClick,
            modifier = Modifier.fillMaxWidth(),
            shape = ButtonDefaults.shape(RoundedCornerShape(8.dp)),
            colors = ButtonDefaults.colors(
                containerColor = bgColor,
                focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.3f)
            )
        ) {
            VersionOptionContent(option, isSelected)
        }
    } else {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(bgColor)
                .clickable(onClick = onClick)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            VersionOptionContent(option, isSelected)
        }
    }
}

@Composable
private fun RowScope.VersionOptionContent(
    option: PlaybackOption,
    isSelected: Boolean
) {
    // Mode badge
    PlaybackModeBadge(option.playbackMode)

    Spacer(modifier = Modifier.width(12.dp))

    // Info
    Column(modifier = Modifier.weight(1f)) {
        androidx.compose.material3.Text(
            text = option.displayName,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.OnSurface
        )
        option.reason?.let { reason ->
            androidx.compose.material3.Text(
                text = reason,
                fontSize = 12.sp,
                color = OpenFlixColors.TextTertiary
            )
        }
    }

    // Selection indicator
    Box(
        modifier = Modifier
            .size(20.dp)
            .background(
                if (isSelected) OpenFlixColors.Primary else Color.Transparent,
                CircleShape
            )
            .then(
                if (!isSelected) Modifier.background(
                    OpenFlixColors.TextTertiary.copy(alpha = 0.3f),
                    CircleShape
                ) else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(OpenFlixColors.OnPrimary, CircleShape)
            )
        }
    }
}

@Composable
private fun PlaybackModeBadge(mode: PlaybackMode) {
    val (color, label) = when (mode) {
        PlaybackMode.DIRECT_PLAY -> Pair(Color(0xFF4CAF50), "Direct")
        PlaybackMode.DIRECT_STREAM -> Pair(Color(0xFF2196F3), "Stream")
        PlaybackMode.TRANSCODE -> Pair(Color(0xFFFFC107), "Transcode")
    }

    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        androidx.compose.material3.Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = color
        )
    }
}

// === Shared Metadata Components ===

@Composable
private fun MetadataRow(mediaItem: MediaItem) {
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
}

@Composable
private fun TabletMetadataRow(mediaItem: MediaItem) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        mediaItem.year?.let { year ->
            androidx.compose.material3.Text(
                text = year.toString(),
                fontSize = 15.sp,
                color = OpenFlixColors.TextSecondary
            )
        }

        mediaItem.contentRating?.let { rating ->
            Box(
                modifier = Modifier
                    .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(4.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                androidx.compose.material3.Text(
                    text = rating,
                    fontSize = 12.sp,
                    color = OpenFlixColors.TextPrimary
                )
            }
        }

        mediaItem.duration?.let { duration ->
            val hours = duration / 3600000
            val minutes = (duration % 3600000) / 60000
            androidx.compose.material3.Text(
                text = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m",
                fontSize = 15.sp,
                color = OpenFlixColors.TextSecondary
            )
        }

        mediaItem.rating?.let { rating ->
            androidx.compose.material3.Text(
                text = "⭐ ${"%.1f".format(rating)}",
                fontSize = 15.sp,
                color = OpenFlixColors.TextSecondary
            )
        }
    }
}

@Composable
private fun CrewInfo(mediaItem: MediaItem) {
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
}

@Composable
private fun TabletCrewInfo(mediaItem: MediaItem) {
    if (mediaItem.directors.isNotEmpty()) {
        Row {
            androidx.compose.material3.Text(
                text = "Director: ",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextSecondary
            )
            androidx.compose.material3.Text(
                text = mediaItem.directors.take(2).joinToString(", "),
                fontSize = 14.sp,
                color = OpenFlixColors.TextTertiary
            )
        }
    }

    if (mediaItem.writers.isNotEmpty()) {
        Spacer(modifier = Modifier.height(4.dp))
        Row {
            androidx.compose.material3.Text(
                text = "Writers: ",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextSecondary
            )
            androidx.compose.material3.Text(
                text = mediaItem.writers.take(3).joinToString(", "),
                fontSize = 14.sp,
                color = OpenFlixColors.TextTertiary
            )
        }
    }

    mediaItem.studio?.let { studio ->
        Spacer(modifier = Modifier.height(4.dp))
        Row {
            androidx.compose.material3.Text(
                text = "Studio: ",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.TextSecondary
            )
            androidx.compose.material3.Text(
                text = studio,
                fontSize = 14.sp,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

// === TV Card Components ===

@Composable
private fun CastCard(castMember: CastMember) {
    Column(
        modifier = Modifier.width(100.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
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

        Text(
            text = castMember.name,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

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

// === Tablet Card Components ===

@Composable
private fun TabletCastCard(castMember: CastMember) {
    Column(
        modifier = Modifier.width(100.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
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

        androidx.compose.material3.Text(
            text = castMember.name,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        castMember.role?.let { role ->
            androidx.compose.material3.Text(
                text = role,
                fontSize = 11.sp,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun TabletSeasonCard(
    season: com.openflix.domain.model.Season,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .width(140.dp)
            .height(80.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(OpenFlixColors.Surface.copy(alpha = 0.9f))
            .clickable(onClick = onClick)
            .padding(12.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            androidx.compose.material3.Text(
                text = season.title.ifEmpty { "Season ${season.index}" },
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = OpenFlixColors.OnSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            season.leafCount?.let { count ->
                Spacer(modifier = Modifier.height(4.dp))
                androidx.compose.material3.Text(
                    text = "$count episodes",
                    fontSize = 12.sp,
                    color = OpenFlixColors.TextSecondary
                )
            }
        }
    }
}
