package com.openflix.ui.screens

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
import androidx.compose.material3.*
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
import coil3.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.Recording
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.viewmodel.ForYouHeroItem
import com.openflix.ui.viewmodel.HomeViewModel
import org.koin.compose.viewmodel.koinViewModel
import kotlinx.coroutines.delay

/**
 * ForYou Screen - Matches iOS ForYouView line-by-line.
 * Section order: Hero → Continue Watching → Movies → TV Shows → On Now → Recordings → Recent Channels → Sports
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    onMediaClick: (String) -> Unit = {},
    viewModel: HomeViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadHome()
    }

    when {
        uiState.isLoading -> LoadingScreen("Loading...")
        uiState.error != null -> ErrorScreen(uiState.error!!, onRetry = viewModel::refresh)
        else -> {
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
                        channel.group?.lowercase()?.contains("sport") == true
                }.filter { it.nowPlaying != null }.take(10)
            }

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(OpenFlixColors.Background),
                contentPadding = PaddingValues(bottom = 100.dp)
            ) {
                // 1. Hero Banner Carousel
                if (uiState.heroItems.isNotEmpty()) {
                    item(key = "hero") {
                        HeroBannerCarousel(
                            items = uiState.heroItems,
                            onItemClick = { hero ->
                                hero.mediaId?.let { onMediaClick(it) }
                            }
                        )
                    }
                }

                // 2. Continue Watching
                if (uiState.continueWatching.isNotEmpty()) {
                    item(key = "continue_watching") {
                        ForYouGallerySection(title = "Continue Watching") {
                            ContinueWatchingRow(
                                items = uiState.continueWatching,
                                onItemClick = { onMediaClick(it.key) }
                            )
                        }
                    }
                }

                // 3. Movies (120x180 poster cards)
                if (uiState.movies.isNotEmpty()) {
                    item(key = "movies") {
                        ForYouGallerySection(title = "Movies", showViewAll = true) {
                            MediaPosterRow(
                                items = uiState.movies,
                                onItemClick = { onMediaClick(it.key) }
                            )
                        }
                    }
                }

                // 4. TV Shows (120x180 poster cards)
                if (uiState.tvShows.isNotEmpty()) {
                    item(key = "tv_shows") {
                        ForYouGallerySection(title = "TV Shows", showViewAll = true) {
                            MediaPosterRow(
                                items = uiState.tvShows,
                                onItemClick = { onMediaClick(it.key) }
                            )
                        }
                    }
                }

                // 5. On Now - Live TV (LIVE badge)
                if (onNowChannels.isNotEmpty()) {
                    item(key = "on_now") {
                        ForYouGallerySection(
                            title = "On Now",
                            badge = "LIVE",
                            badgeColor = OpenFlixColors.LiveIndicator
                        ) {
                            OnNowRow(channels = onNowChannels, onChannelClick = { })
                        }
                    }
                }

                // 6. New in Your Library (recordings)
                if (uiState.recentRecordings.isNotEmpty()) {
                    item(key = "recordings") {
                        ForYouGallerySection(title = "New in Your Library") {
                            RecordingsRow(recordings = uiState.recentRecordings)
                        }
                    }
                }

                // 7. Recent Channels (circular logos)
                if (recentChannels.isNotEmpty()) {
                    item(key = "recent_channels") {
                        ForYouGallerySection(title = "Recent Channels") {
                            RecentChannelsRow(channels = recentChannels, onChannelClick = { })
                        }
                    }
                }

                // 8. Sports (conditional, LIVE badge)
                if (sportsChannels.isNotEmpty()) {
                    item(key = "sports") {
                        ForYouGallerySection(
                            title = "Sports",
                            badge = "LIVE",
                            badgeColor = OpenFlixColors.LiveIndicator
                        ) {
                            OnNowRow(channels = sportsChannels, onChannelClick = { })
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hero Banner Carousel (380dp, auto-advance 5s)

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HeroBannerCarousel(
    items: List<ForYouHeroItem>,
    onItemClick: (ForYouHeroItem) -> Unit
) {
    var selectedIndex by remember { mutableIntStateOf(0) }
    val pagerState = rememberPagerState(pageCount = { items.size })

    LaunchedEffect(pagerState.currentPage) {
        selectedIndex = pagerState.currentPage
    }

    // Auto-advance every 5 seconds
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
                HeroBannerCard(item = item, onClick = { onItemClick(item) })
            }
        }

        // Page indicators (purple active, white@30% inactive)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.Center
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items.forEachIndexed { index, _ ->
                    Box(
                        modifier = Modifier
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
}

// MARK: - Hero Banner Card (blurred bg + centered sharp poster + bottom text)

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
        // Blurred full-bleed background
        AsyncImage(
            model = item.artPath ?: item.posterPath,
            contentDescription = null,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { scaleX = 1.1f; scaleY = 1.1f }
                .blur(20.dp),
            contentScale = ContentScale.Crop
        )

        // Sharp centered poster (2:3 aspect, 280dp height)
        AsyncImage(
            model = item.artPath ?: item.posterPath,
            contentDescription = item.title,
            modifier = Modifier
                .height(280.dp)
                .aspectRatio(2f / 3f)
                .align(Alignment.Center)
                .offset(y = (-30).dp)
                .clip(RoundedCornerShape(12.dp)),
            contentScale = ContentScale.Crop
        )

        // Bottom gradient for text
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

        // Content at bottom-left
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp)
        ) {
            // Badge (LIVE/MOVIE)
            item.badge?.let { badge ->
                Text(
                    text = badge,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    modifier = Modifier
                        .background(OpenFlixColors.Primary, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                )
                Spacer(modifier = Modifier.height(6.dp))
            }

            // Title (24sp Bold)
            Text(
                text = item.title,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 28.sp
            )

            // Subtitle
            item.subtitle?.let { sub ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = sub,
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.8f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

// MARK: - Gallery Section Container

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
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                badge?.let {
                    Text(
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
            if (showViewAll) {
                Text(
                    text = "View All",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.Gray
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
private fun ContinueWatchingTile(item: MediaItem, onClick: () -> Unit) {
    val progress = item.progressPercent.toFloat().coerceIn(0f, 1f)

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

            // Progress bar at bottom (3dp, purple fill on white@30% track)
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(3.dp)
            ) {
                Box(modifier = Modifier.fillMaxSize().background(Color.White.copy(alpha = 0.3f)))
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(progress)
                        .background(OpenFlixColors.Primary)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Title (13sp semibold)
        Text(
            text = item.title,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Subtitle (episode info or year)
        val subtitle = when {
            item.parentIndex != null && item.index != null -> "S${item.parentIndex} E${item.index}"
            item.year != null -> item.year.toString()
            else -> null
        }
        subtitle?.let {
            Text(
                text = it,
                fontSize = 12.sp,
                color = Color.Gray,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Media Poster Row (120x180, 2:3 aspect)

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
private fun MediaPosterTile(item: MediaItem, onClick: () -> Unit) {
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
        AsyncImage(
            model = displayThumb,
            contentDescription = displayTitle,
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(2f / 3f)
                .clip(RoundedCornerShape(12.dp))
                .background(OpenFlixColors.Card),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = displayTitle,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

// MARK: - On Now Row (160x90, LIVE badge overlay)

@Composable
private fun OnNowRow(channels: List<Channel>, onChannelClick: (Channel) -> Unit) {
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
private fun OnNowTile(channel: Channel, onClick: () -> Unit) {
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
            // Program artwork or channel logo fallback
            val programArt = channel.nowPlaying?.icon ?: channel.nowPlaying?.art
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

            // LIVE badge overlay (black@70% bg, red dot + "LIVE")
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
                Text(
                    text = "LIVE",
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Channel name (13sp semibold)
        Text(
            text = channel.name,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Current program (12sp gray)
        channel.nowPlaying?.let { program ->
            Text(
                text = program.title,
                fontSize = 12.sp,
                color = Color.Gray,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Recent Channels Row (70dp circles)

@Composable
private fun RecentChannelsRow(channels: List<Channel>, onChannelClick: (Channel) -> Unit) {
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
private fun RecentChannelTile(channel: Channel, onClick: () -> Unit) {
    Column(
        modifier = Modifier.clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Circle logo (70dp, white 0.1 fill, 50dp logo)
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
            } ?: Text(
                text = channel.name.take(3),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Channel number (12sp medium, gray)
        Text(
            text = channel.displayNumber,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = OpenFlixColors.TextTertiary
        )
    }
}

// MARK: - Recordings Row (160x90)

@Composable
private fun RecordingsRow(recordings: List<Recording>) {
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
private fun RecordingTile(recording: Recording) {
    Column(modifier = Modifier.width(160.dp)) {
        AsyncImage(
            model = recording.thumb ?: recording.art,
            contentDescription = recording.title,
            modifier = Modifier
                .fillMaxWidth()
                .height(90.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Card),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = if (recording.subtitle != null) "${recording.title} - ${recording.subtitle}" else recording.title,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        recording.channelName?.let { name ->
            Text(
                text = name,
                fontSize = 12.sp,
                color = OpenFlixColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Shared Components

@Composable
internal fun LoadingScreen(message: String) {
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
            CircularProgressIndicator(
                color = OpenFlixColors.Primary,
                modifier = Modifier.size(32.dp)
            )
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.TextSecondary
            )
        }
    }
}

@Composable
internal fun ErrorScreen(message: String, onRetry: () -> Unit) {
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
            Text(text = message, style = MaterialTheme.typography.bodyLarge, color = OpenFlixColors.Error)
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(OpenFlixColors.Primary)
                    .clickable(onClick = onRetry)
            ) {
                Text(
                    text = "Retry",
                    fontWeight = FontWeight.SemiBold,
                    color = OpenFlixColors.OnPrimary,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                )
            }
        }
    }
}
