package com.openflix.presentation.screens.home

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.Recording
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * ForYou Screen - Matches iOS ForYouView line-by-line.
 * Section order: Hero → Continue Watching → Movies → TV Shows → On Now → Recordings → Recent Channels → Sports
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ForYouScreen(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onNavigateToLiveTVPlayer: ((String) -> Unit)? = null,
    viewModel: DiscoverViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadHomeContent()
    }

    val heroItems = uiState.heroItems
    val continueWatching = uiState.continueWatching
    val movies = uiState.movies
    val tvShows = uiState.tvShows
    val onNowChannels = remember(uiState.channels) {
        uiState.channels.filter { it.nowPlaying != null }.take(10)
    }
    val recentChannels = remember(uiState.channels) {
        uiState.channels.take(8)
    }
    val sportsChannels = remember(uiState.channels) {
        uiState.channels.filter { channel ->
            val name = channel.name.lowercase()
            name.contains("espn") || name.contains("sport") ||
                name.contains("fox sports") || name.contains("nfl") ||
                name.contains("nba") || name.contains("mlb") ||
                name.contains("nhl") || name.contains("golf") ||
                channel.category?.lowercase()?.contains("sport") == true
        }.filter { it.nowPlaying != null }.take(10)
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentPadding = PaddingValues(bottom = 100.dp)
    ) {
        // 1. Hero Banner Carousel
        if (heroItems.isNotEmpty()) {
            item(key = "hero") {
                HeroBannerCarousel(
                    items = heroItems,
                    onItemClick = { hero ->
                        if (hero.mediaId != null) onMediaClick(hero.mediaId)
                        else if (hero.channelId != null) onNavigateToLiveTVPlayer?.invoke(hero.channelId)
                    }
                )
            }
        }

        // 2. Continue Watching
        if (continueWatching.isNotEmpty()) {
            item(key = "continue_watching") {
                ForYouGallerySection(title = "Continue Watching") {
                    ContinueWatchingRow(
                        items = continueWatching,
                        onItemClick = { onPlayClick(it.id) }
                    )
                }
            }
        }

        // 3. Movies (120x180 poster cards, matching iOS)
        if (movies.isNotEmpty()) {
            item(key = "movies") {
                ForYouGallerySection(title = "Movies", showViewAll = true) {
                    MediaPosterRow(
                        items = movies,
                        onItemClick = { onMediaClick(it.id) }
                    )
                }
            }
        }

        // 4. TV Shows (120x180 poster cards, matching iOS)
        if (tvShows.isNotEmpty()) {
            item(key = "tv_shows") {
                ForYouGallerySection(title = "TV Shows", showViewAll = true) {
                    MediaPosterRow(
                        items = tvShows,
                        onItemClick = { onMediaClick(it.id) }
                    )
                }
            }
        }

        // 5. On Now - Live TV (LIVE badge in header, matching iOS)
        if (onNowChannels.isNotEmpty()) {
            item(key = "on_now") {
                ForYouGallerySection(
                    title = "On Now",
                    badge = "LIVE",
                    badgeColor = OpenFlixColors.LiveIndicator
                ) {
                    OnNowRow(
                        channels = onNowChannels,
                        onChannelClick = { channel ->
                            onNavigateToLiveTVPlayer?.invoke(channel.id)
                        }
                    )
                }
            }
        }

        // 6. New in Your Library (recordings, matching iOS)
        if (uiState.recentRecordings.isNotEmpty()) {
            item(key = "recordings") {
                ForYouGallerySection(title = "New in Your Library") {
                    RecordingsRow(recordings = uiState.recentRecordings)
                }
            }
        }

        // 7. Recent Channels (circular logos, matching iOS)
        if (recentChannels.isNotEmpty()) {
            item(key = "recent_channels") {
                ForYouGallerySection(title = "Recent Channels") {
                    RecentChannelsRow(
                        channels = recentChannels,
                        onChannelClick = { channel ->
                            onNavigateToLiveTVPlayer?.invoke(channel.id)
                        }
                    )
                }
            }
        }

        // 8. Sports (conditional, LIVE badge, matching iOS)
        if (sportsChannels.isNotEmpty()) {
            item(key = "sports") {
                ForYouGallerySection(
                    title = "Sports",
                    badge = "LIVE",
                    badgeColor = OpenFlixColors.LiveIndicator
                ) {
                    OnNowRow(
                        channels = sportsChannels,
                        onChannelClick = { channel ->
                            onNavigateToLiveTVPlayer?.invoke(channel.id)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Hero Banner Carousel (matches iOS HeroBannerCarousel: 380dp, auto-advance 5s)

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HeroBannerCarousel(
    items: List<ForYouHeroItem>,
    onItemClick: (ForYouHeroItem) -> Unit
) {
    var selectedIndex by remember { mutableIntStateOf(0) }

    val pagerState = rememberPagerState(pageCount = { items.size })

    // Sync selectedIndex with pager
    LaunchedEffect(pagerState.currentPage) {
        selectedIndex = pagerState.currentPage
    }

    // Auto-advance every 5 seconds (matching iOS)
    LaunchedEffect(items.size) {
        while (items.isNotEmpty()) {
            delay(5000)
            val next = (pagerState.currentPage + 1) % items.size
            pagerState.animateScrollToPage(next)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxWidth()
                .height(380.dp),
            contentPadding = PaddingValues(horizontal = 16.dp),
            pageSpacing = 12.dp
        ) { page ->
            items.getOrNull(page)?.let { item ->
                HeroBannerCard(
                    item = item,
                    onClick = { onItemClick(item) }
                )
            }
        }

        // Page indicators (matching iOS: 8dp circles, purple active, white 0.3 inactive)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            items.forEachIndexed { index, _ ->
                Box(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(
                            if (index == selectedIndex) OpenFlixColors.Primary
                            else Color.White.copy(alpha = 0.3f)
                        )
                        .animateContentSize()
                )
            }
        }
    }
}

// MARK: - Hero Banner Card (iOS style: blurred bg + centered poster + gradient + badge)

@Composable
private fun HeroBannerCard(
    item: ForYouHeroItem,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
    ) {
        // Blurred poster as full-bleed background (blur 20dp, scale 1.1x)
        AsyncImage(
            model = item.artPath,
            contentDescription = null,
            modifier = Modifier
                .fillMaxSize()
                .blur(20.dp)
                .graphicsLayer { scaleX = 1.1f; scaleY = 1.1f },
            contentScale = ContentScale.Crop
        )

        // Sharp poster centered (280dp height, 2:3 aspect, 12dp radius)
        AsyncImage(
            model = item.posterPath,
            contentDescription = item.title,
            modifier = Modifier
                .align(Alignment.Center)
                .offset(y = (-30).dp)
                .height(280.dp)
                .aspectRatio(2f / 3f)
                .clip(RoundedCornerShape(12.dp)),
            contentScale = ContentScale.Crop
        )

        // Gradient overlay (clear → clear → black 0.85)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.85f)
                        )
                    )
                )
        )

        // Content at bottom (badge + title + subtitle)
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp)
        ) {
            // Badge (11sp bold, white on colored bg, 4dp radius)
            item.badge?.let { badge ->
                val badgeColor = if (badge == "LIVE") OpenFlixColors.LiveIndicator else OpenFlixColors.Primary
                androidx.compose.material3.Text(
                    text = badge,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    modifier = Modifier
                        .background(badgeColor, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                )
                Spacer(modifier = Modifier.height(6.dp))
            }

            // Title (24sp bold, max 2 lines)
            androidx.compose.material3.Text(
                text = item.title,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Subtitle (14sp, white 0.8)
            item.subtitle?.let { sub ->
                androidx.compose.material3.Text(
                    text = sub,
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }
        }
    }
}

// MARK: - Gallery Section Container (matches iOS ForYouGallerySection)

@Composable
private fun ForYouGallerySection(
    title: String,
    badge: String? = null,
    badgeColor: Color = Color.Red,
    showViewAll: Boolean = false,
    content: @Composable () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp)
    ) {
        // Header: title (18sp bold) + optional badge + optional "View All"
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 0.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                androidx.compose.material3.Text(
                    text = title,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                // Badge (10sp bold, colored bg, 4dp radius)
                badge?.let {
                    androidx.compose.material3.Text(
                        text = it,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        modifier = Modifier
                            .background(badgeColor, RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 3.dp)
                    )
                }
            }

            // "View All" (14sp medium, gray)
            if (showViewAll) {
                androidx.compose.material3.Text(
                    text = "View All",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        content()
    }
}

// MARK: - Continue Watching Row (160x90, purple progress bar 3dp)

@Composable
private fun ContinueWatchingRow(
    items: List<MediaItem>,
    onItemClick: (MediaItem) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(items, key = { it.id }) { item ->
            ContinueWatchingTile(item = item, onClick = { onItemClick(item) })
        }
    }
}

@Composable
private fun ContinueWatchingTile(
    item: MediaItem,
    onClick: () -> Unit
) {
    val progress = item.viewOffset?.let { offset ->
        item.duration?.let { duration ->
            if (duration > 0) offset.toFloat() / duration.toFloat() else 0f
        }
    } ?: 0f

    Column(
        modifier = Modifier
            .width(160.dp)
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(90.dp)
                .clip(RoundedCornerShape(8.dp))
        ) {
            AsyncImage(
                model = item.art ?: item.thumb,
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )

            // Progress bar at bottom (3dp, purple fill on white 0.3 track)
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(3.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.White.copy(alpha = 0.3f))
                )
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(progress.coerceIn(0f, 1f))
                        .background(OpenFlixColors.Primary)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Title (13sp semibold)
        androidx.compose.material3.Text(
            text = item.title,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Subtitle (12sp gray)
        val subtitle = when {
            item.type == MediaType.EPISODE -> item.tagline ?: item.summary?.take(40)
            else -> {
                val remainingMs = item.duration?.let { d -> item.viewOffset?.let { o -> d - o } }
                remainingMs?.let { "${it / 60000}m left" }
            }
        }
        subtitle?.let {
            androidx.compose.material3.Text(
                text = it,
                fontSize = 12.sp,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Media Poster Row (120x180 poster cards, 2:3 aspect, matching iOS MediaGalleryTile)

@Composable
private fun MediaPosterRow(
    items: List<MediaItem>,
    onItemClick: (MediaItem) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(items, key = { it.id }) { item ->
            MediaPosterTile(item = item, onClick = { onItemClick(item) })
        }
    }
}

@Composable
private fun MediaPosterTile(
    item: MediaItem,
    onClick: () -> Unit
) {
    val displayThumb = when (item.type) {
        MediaType.EPISODE -> item.grandparentThumb ?: item.thumb
        else -> item.thumb
    }
    val displayTitle = when (item.type) {
        MediaType.EPISODE -> item.grandparentTitle ?: item.title
        else -> item.title
    }

    Column(
        modifier = Modifier
            .width(120.dp)
            .clickable(onClick = onClick)
    ) {
        // Poster (120x180, 2:3 aspect, 8dp radius)
        AsyncImage(
            model = displayThumb,
            contentDescription = displayTitle,
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(2f / 3f)
                .clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Title (13sp medium, max 2 lines)
        androidx.compose.material3.Text(
            text = displayTitle,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

// MARK: - On Now Row (160x90, LIVE badge overlay, matching iOS OnNowGalleryRow)

@Composable
private fun OnNowRow(
    channels: List<Channel>,
    onChannelClick: (Channel) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(channels, key = { it.id }) { channel ->
            OnNowTile(channel = channel, onClick = { onChannelClick(channel) })
        }
    }
}

@Composable
private fun OnNowTile(
    channel: Channel,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(160.dp)
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(90.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(Color.White.copy(alpha = 0.08f))
        ) {
            // Program artwork or channel logo fallback (matching iOS)
            val programArt = channel.nowPlaying?.thumb ?: channel.nowPlaying?.art
            if (programArt != null) {
                AsyncImage(
                    model = programArt,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                channel.logo?.let { logo ->
                    AsyncImage(
                        model = logo,
                        contentDescription = null,
                        modifier = Modifier
                            .size(80.dp, 50.dp)
                            .align(Alignment.Center),
                        contentScale = ContentScale.Fit
                    )
                }
            }

            // LIVE badge overlay (red dot + "LIVE" 9sp, black 0.7 bg)
            Row(
                modifier = Modifier
                    .padding(8.dp)
                    .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 6.dp, vertical = 3.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(OpenFlixColors.LiveIndicator)
                )
                androidx.compose.material3.Text(
                    text = "LIVE",
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Channel name (13sp semibold)
        androidx.compose.material3.Text(
            text = channel.name,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Current program (12sp gray)
        channel.nowPlaying?.let { program ->
            androidx.compose.material3.Text(
                text = program.title,
                fontSize = 12.sp,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Recent Channels Row (70dp circles, matching iOS RecentChannelGalleryTile)

@Composable
private fun RecentChannelsRow(
    channels: List<Channel>,
    onChannelClick: (Channel) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(channels, key = { it.id }) { channel ->
            RecentChannelTile(channel = channel, onClick = { onChannelClick(channel) })
        }
    }
}

@Composable
private fun RecentChannelTile(
    channel: Channel,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier.clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Circle logo (70dp, white 0.1 fill, 50dp logo centered)
        Box(
            modifier = Modifier
                .size(70.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            channel.logo?.let { logo ->
                AsyncImage(
                    model = logo,
                    contentDescription = channel.name,
                    modifier = Modifier.size(50.dp),
                    contentScale = ContentScale.Fit
                )
            } ?: androidx.compose.material3.Text(
                text = channel.name.take(3),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Channel number (12sp medium, gray)
        androidx.compose.material3.Text(
            text = channel.number ?: "",
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextTertiary
        )
    }
}

// MARK: - Recordings Row (160x90, matching iOS RecordingGalleryTile / "New in Your Library")

@Composable
private fun RecordingsRow(
    recordings: List<Recording>
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(recordings, key = { it.id }) { recording ->
            RecordingTile(recording = recording)
        }
    }
}

@Composable
private fun RecordingTile(
    recording: Recording
) {
    Column(
        modifier = Modifier.width(160.dp)
    ) {
        // Thumbnail (160x90, 8dp radius)
        AsyncImage(
            model = recording.thumb ?: recording.art,
            contentDescription = recording.title,
            modifier = Modifier
                .fillMaxWidth()
                .height(90.dp)
                .clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Title (13sp semibold)
        androidx.compose.material3.Text(
            text = if (recording.subtitle != null) "${recording.title} - ${recording.subtitle}" else recording.title,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Channel name (12sp gray)
        recording.channelName?.let { name ->
            androidx.compose.material3.Text(
                text = name,
                fontSize = 12.sp,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
