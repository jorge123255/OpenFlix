package com.openflix.presentation.screens.tvshows

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

// Modern accent color matching tvOS
private val AccentTeal = Color(0xFF00D4AA)
private val AccentTealDark = Color(0xFF00A080)

/**
 * Modern TV Shows Screen - Channels DVR 7.0 inspired
 * Glass morphism, spring animations, theater mode hero
 */
@Composable
fun TVShowsScreenModern(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onBrowseAll: () -> Unit,
    viewModel: TVShowsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    var selectedGenre by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadTVShows()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Ambient background blur from featured content
        if (uiState.featuredItems.isNotEmpty()) {
            AsyncImage(
                model = uiState.featuredItems.first().backdropUrl(),
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .blur(100.dp)
                    .graphicsLayer { alpha = 0.3f },
                contentScale = ContentScale.Crop
            )
        }

        when {
            uiState.isLoading -> {
                ModernTVLoadingScreen()
            }
            uiState.error != null -> {
                ModernTVErrorScreen(
                    message = uiState.error!!,
                    onRetry = viewModel::loadTVShows
                )
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Transparent),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    // Theater Mode Hero
                    item {
                        if (uiState.featuredItems.isNotEmpty()) {
                            TVTheaterModeHeroModern(
                                items = uiState.featuredItems,
                                trailers = uiState.trailers,
                                onPlayClick = { item -> onMediaClick(item.id) }, // Go to detail for episode selection
                                onInfoClick = { item -> onMediaClick(item.id) },
                                onTrailerClick = { trailer ->
                                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(trailer.youtubeWatchUrl))
                                    context.startActivity(intent)
                                }
                            )
                        }
                    }

                    // Genre Filter Bar
                    item {
                        TVGenreFilterBarModern(
                            genres = uiState.genreHubs.map { it.genre },
                            selectedGenre = selectedGenre,
                            onGenreSelected = { genre ->
                                selectedGenre = if (selectedGenre == genre) null else genre
                            },
                            onBrowseAll = onBrowseAll
                        )
                    }

                    // Continue Watching with glass cards
                    if (uiState.continueWatching.isNotEmpty()) {
                        item {
                            ModernTVContentRow(
                                title = "Continue Watching",
                                subtitle = "Pick up where you left off",
                                icon = Icons.Default.PlayCircle,
                                accentColor = Color(0xFF4A90D9),
                                items = uiState.continueWatching,
                                cardStyle = TVCardStyle.ContinueWatching,
                                onItemClick = onMediaClick,
                                onPlayClick = onPlayClick
                            )
                        }
                    }

                    // Up Next (new episodes)
                    uiState.hubs.find { it.title.contains("Next", ignoreCase = true) || it.title.contains("New Episode", ignoreCase = true) }?.let { upNextHub ->
                        item {
                            ModernTVContentRow(
                                title = "Up Next",
                                subtitle = "New episodes waiting",
                                icon = Icons.Default.Upcoming,
                                accentColor = Color(0xFF9B59B6),
                                items = upNextHub.items,
                                cardStyle = TVCardStyle.Episode,
                                onItemClick = onMediaClick,
                                onPlayClick = onPlayClick
                            )
                        }
                    }

                    // Recently Added
                    uiState.hubs.find { it.title.contains("Recent", ignoreCase = true) }?.let { recentHub ->
                        item {
                            ModernTVContentRow(
                                title = "Recently Added",
                                subtitle = "Fresh arrivals",
                                icon = Icons.Default.NewReleases,
                                accentColor = AccentTeal,
                                items = recentHub.items,
                                cardStyle = TVCardStyle.Poster,
                                onItemClick = onMediaClick,
                                onPlayClick = onPlayClick
                            )
                        }
                    }

                    // Genre Hubs with colored accents (filtered if genre selected)
                    val displayedGenres = if (selectedGenre != null) {
                        uiState.genreHubs.filter { it.genre == selectedGenre }
                    } else {
                        uiState.genreHubs
                    }
                    
                    itemsIndexed(displayedGenres) { index, genreHub ->
                        ModernTVContentRow(
                            title = genreHub.genre,
                            subtitle = "${genreHub.items.size} shows",
                            icon = tvGenreIcon(genreHub.genre),
                            accentColor = tvGenreColor(genreHub.genre),
                            items = genreHub.items,
                            cardStyle = TVCardStyle.Poster,
                            onItemClick = onMediaClick,
                            onPlayClick = onPlayClick
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Theater Mode Hero

@Composable
private fun TVTheaterModeHeroModern(
    items: List<MediaItem>,
    trailers: Map<String, TrailerInfo>,
    onPlayClick: (MediaItem) -> Unit,
    onInfoClick: (MediaItem) -> Unit,
    onTrailerClick: (TrailerInfo) -> Unit
) {
    var currentIndex by remember { mutableStateOf(0) }
    var isAutoPlaying by remember { mutableStateOf(true) }
    
    val currentItem = items.getOrNull(currentIndex) ?: return
    val currentTrailer = trailers[currentItem.id]

    // Auto-advance timer
    LaunchedEffect(currentIndex, isAutoPlaying) {
        if (isAutoPlaying && items.size > 1) {
            delay(8000)
            currentIndex = (currentIndex + 1) % items.size
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(480.dp)
    ) {
        // Background with parallax effect
        AsyncImage(
            model = currentItem.backdropUrl(),
            contentDescription = null,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { 
                    scaleX = 1.1f
                    scaleY = 1.1f
                },
            contentScale = ContentScale.Crop
        )

        // Cinematic vignette
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.radialGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.4f)),
                        radius = 1000f
                    )
                )
        )

        // Left gradient
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .width(600.dp)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            Color.Black.copy(alpha = 0.95f),
                            Color.Black.copy(alpha = 0.7f),
                            Color.Transparent
                        )
                    )
                )
        )

        // Bottom gradient
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f), Color.Black)
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(start = 48.dp, bottom = 48.dp)
                .widthIn(max = 600.dp)
        ) {
            // TV SERIES badge
            Surface(
                shape = RoundedCornerShape(20.dp),
                colors = SurfaceDefaults.colors(
                    containerColor = AccentTeal.copy(alpha = 0.2f)
                ),
                border = BorderStroke(1.dp, AccentTeal.copy(alpha = 0.5f))
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Tv,
                        contentDescription = null,
                        tint = AccentTeal,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "TV SERIES",
                        color = AccentTeal,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Title with glow effect
            Text(
                text = currentItem.title,
                color = Color.White,
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.graphicsLayer {
                    shadowElevation = 8f
                }
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Metadata row
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                currentItem.year?.let { year ->
                    Text(
                        text = year.toString(),
                        color = Color.White.copy(alpha = 0.9f),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                }

                currentItem.childCount?.let { seasons ->
                    TVMetadataPillModern(
                        icon = Icons.Default.Tv,
                        text = "$seasons Season${if (seasons > 1) "s" else ""}"
                    )
                }

                currentItem.contentRating?.let { rating ->
                    TVMetadataPillModern(text = rating)
                }

                currentItem.audienceRating?.let { score ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = Color(0xFFFFD700),
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = String.format("%.1f", score),
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Summary
            currentItem.summary?.let { summary ->
                Text(
                    text = summary,
                    color = Color.White.copy(alpha = 0.85f),
                    fontSize = 16.sp,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    lineHeight = 24.sp
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Action buttons
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                // Watch Now button
                var playFocused by remember { mutableStateOf(false) }
                val playScale by animateFloatAsState(
                    targetValue = if (playFocused) 1.08f else 1f,
                    animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
                )
                
                Button(
                    onClick = { onPlayClick(currentItem) },
                    modifier = Modifier
                        .scale(playScale)
                        .onFocusChanged { 
                            playFocused = it.isFocused
                            if (it.isFocused) isAutoPlaying = false
                        },
                    colors = ButtonDefaults.colors(
                        containerColor = Color.White,
                        contentColor = Color.Black
                    ),
                    shape = RoundedCornerShape(28.dp),
                    contentPadding = PaddingValues(horizontal = 32.dp, vertical = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Watch Now",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Episodes button
                var episodesFocused by remember { mutableStateOf(false) }
                val episodesScale by animateFloatAsState(
                    targetValue = if (episodesFocused) 1.06f else 1f,
                    animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
                )

                OutlinedButton(
                    onClick = { onInfoClick(currentItem) },
                    modifier = Modifier
                        .scale(episodesScale)
                        .onFocusChanged { 
                            episodesFocused = it.isFocused
                            if (it.isFocused) isAutoPlaying = false
                        },
                    colors = ButtonDefaults.colors(
                        containerColor = Color.White.copy(alpha = 0.15f),
                        contentColor = Color.White
                    ),
                    border = BorderStroke(
                        width = if (episodesFocused) 2.dp else 1.dp,
                        color = if (episodesFocused) Color.White else Color.White.copy(alpha = 0.5f)
                    ),
                    shape = RoundedCornerShape(28.dp),
                    contentPadding = PaddingValues(horizontal = 24.dp, vertical = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.List,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Episodes",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                // Trailer button if available
                currentTrailer?.let { trailer ->
                    var trailerFocused by remember { mutableStateOf(false) }
                    val trailerScale by animateFloatAsState(
                        targetValue = if (trailerFocused) 1.06f else 1f,
                        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
                    )

                    OutlinedButton(
                        onClick = { onTrailerClick(trailer) },
                        modifier = Modifier
                            .scale(trailerScale)
                            .onFocusChanged { 
                                trailerFocused = it.isFocused
                                if (it.isFocused) isAutoPlaying = false
                            },
                        colors = ButtonDefaults.colors(
                            containerColor = Color.White.copy(alpha = 0.15f),
                            contentColor = Color.White
                        ),
                        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.3f)),
                        shape = RoundedCornerShape(28.dp),
                        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayCircle,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Trailer",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Page indicators
            if (items.size > 1) {
                Spacer(modifier = Modifier.height(24.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items.forEachIndexed { index, _ ->
                        val width by animateDpAsState(
                            targetValue = if (index == currentIndex) 28.dp else 10.dp,
                            animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
                        )
                        Box(
                            modifier = Modifier
                                .height(6.dp)
                                .width(width)
                                .clip(RoundedCornerShape(3.dp))
                                .background(
                                    if (index == currentIndex) AccentTeal 
                                    else Color.White.copy(alpha = 0.4f)
                                )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Genre Filter Bar

@Composable
private fun TVGenreFilterBarModern(
    genres: List<String>,
    selectedGenre: String?,
    onGenreSelected: (String) -> Unit,
    onBrowseAll: () -> Unit
) {
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 24.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 48.dp)
    ) {
        // Browse All button
        item {
            var focused by remember { mutableStateOf(false) }
            val scale by animateFloatAsState(
                targetValue = if (focused) 1.05f else 1f,
                animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
            )

            Surface(
                onClick = onBrowseAll,
                modifier = Modifier
                    .scale(scale)
                    .onFocusChanged { focused = it.isFocused },
                shape = RoundedCornerShape(24.dp),
                colors = SurfaceDefaults.colors(
                    containerColor = AccentTeal.copy(alpha = 0.15f)
                ),
                border = BorderStroke(1.dp, AccentTeal.copy(alpha = 0.5f))
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.GridView,
                        contentDescription = null,
                        tint = AccentTeal,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = "Browse All",
                        color = AccentTeal,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }

        // Divider
        item {
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(32.dp)
                    .background(Color.White.copy(alpha = 0.2f))
            )
        }

        // Genre pills
        items(genres.take(12)) { genre ->
            TVGenrePillModern(
                genre = genre,
                isSelected = genre == selectedGenre,
                onSelect = { onGenreSelected(genre) }
            )
        }
    }
}

@Composable
private fun TVGenrePillModern(
    genre: String,
    isSelected: Boolean = false,
    onSelect: () -> Unit = {}
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )
    val color = tvGenreColor(genre)

    Surface(
        onClick = onSelect,
        modifier = Modifier
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = RoundedCornerShape(20.dp),
        colors = SurfaceDefaults.colors(
            containerColor = when {
                isSelected -> color.copy(alpha = 0.5f)
                focused -> color.copy(alpha = 0.3f)
                else -> Color.White.copy(alpha = 0.1f)
            }
        ),
        border = when {
            isSelected -> BorderStroke(2.dp, color)
            focused -> BorderStroke(2.dp, Color.White)
            else -> null
        }
    ) {
        Text(
            text = genre,
            color = if (focused || isSelected) Color.White else Color.White.copy(alpha = 0.9f),
            fontSize = 14.sp,
            fontWeight = if (focused || isSelected) FontWeight.Bold else FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp)
        )
    }
}

// MARK: - Modern Content Row

enum class TVCardStyle { Poster, ContinueWatching, Episode }

@Composable
private fun ModernTVContentRow(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    accentColor: Color,
    items: List<MediaItem>,
    cardStyle: TVCardStyle,
    onItemClick: (String) -> Unit,
    onPlayClick: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
    ) {
        // Header with icon
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon with glow
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(accentColor.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = accentColor,
                    modifier = Modifier.size(22.dp)
                )
            }

            Column {
                Text(
                    text = title,
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = subtitle,
                    color = Color.White.copy(alpha = 0.6f),
                    fontSize = 13.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Content row
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            contentPadding = PaddingValues(horizontal = 48.dp)
        ) {
            items(items.take(15)) { item ->
                when (cardStyle) {
                    TVCardStyle.Poster -> ModernTVPosterCard(
                        item = item,
                        onItemClick = { onItemClick(item.id) }
                    )
                    TVCardStyle.ContinueWatching -> ModernTVContinueCard(
                        item = item,
                        onItemClick = { onItemClick(item.id) },
                        onPlayClick = { onPlayClick(item.id) }
                    )
                    TVCardStyle.Episode -> ModernTVEpisodeCard(
                        item = item,
                        onItemClick = { onItemClick(item.id) },
                        onPlayClick = { onPlayClick(item.id) }
                    )
                }
            }
        }
    }
}

// MARK: - Modern TV Poster Card

@Composable
private fun ModernTVPosterCard(
    item: MediaItem,
    onItemClick: () -> Unit
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.08f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )

    Surface(
        onClick = onItemClick,
        modifier = Modifier
            .width(160.dp)
            .height(240.dp)
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = RoundedCornerShape(12.dp),
        border = if (focused) BorderStroke(4.dp, AccentTeal) else null,
        tonalElevation = if (focused) 16.dp else 0.dp
    ) {
        Box {
            // Poster image
            AsyncImage(
                model = item.posterUrl(),
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )

            // Bottom gradient with info
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
                    .align(Alignment.BottomCenter)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.9f))
                        )
                    )
            )

            // Title and metadata
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp)
            ) {
                Text(
                    text = item.title,
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                item.childCount?.let { seasons ->
                    Text(
                        text = "$seasons Season${if (seasons > 1) "s" else ""}",
                        color = Color.White.copy(alpha = 0.7f),
                        fontSize = 12.sp
                    )
                }
            }

            // Focus glow
            if (focused) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(AccentTeal.copy(alpha = 0.1f))
                )
            }
        }
    }
}

// MARK: - Modern TV Continue Card

@Composable
private fun ModernTVContinueCard(
    item: MediaItem,
    onItemClick: () -> Unit,
    onPlayClick: () -> Unit
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )

    val progress = item.viewOffset?.let { offset ->
        item.duration?.let { duration ->
            if (duration > 0) offset.toFloat() / duration.toFloat() else 0f
        }
    } ?: 0f

    Surface(
        onClick = onPlayClick,
        modifier = Modifier
            .width(360.dp)
            .height(220.dp)
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = RoundedCornerShape(16.dp),
        border = if (focused) BorderStroke(4.dp, AccentTeal) else null
    ) {
        Box {
            // Background
            AsyncImage(
                model = item.backdropUrl() ?: item.posterUrl(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )

            // Glass overlay at bottom
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(90.dp)
                    .align(Alignment.BottomCenter)
                    .background(Color.Black.copy(alpha = 0.75f))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(14.dp)
                ) {
                    // Show title
                    Text(
                        text = item.grandparentTitle ?: item.parentTitle ?: "",
                        color = Color.White.copy(alpha = 0.7f),
                        fontSize = 12.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    // Episode title
                    Text(
                        text = item.title,
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Episode info and time remaining
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Episode badge
                        item.parentIndex?.let { season ->
                            item.index?.let { episode ->
                                Text(
                                    text = "S$season E$episode",
                                    color = AccentTeal,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                        
                        item.duration?.let { duration ->
                            item.viewOffset?.let { offset ->
                                val remaining = (duration - offset) / 60000
                                Text(
                                    text = "• ${remaining}min left",
                                    color = Color.White.copy(alpha = 0.6f),
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    // Progress bar
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(Color.White.copy(alpha = 0.3f))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(progress)
                                .fillMaxHeight()
                                .background(AccentTeal)
                        )
                    }
                }
            }

            // Play icon overlay
            Icon(
                imageVector = Icons.Default.PlayCircleFilled,
                contentDescription = "Play",
                tint = Color.White.copy(alpha = if (focused) 1f else 0.8f),
                modifier = Modifier
                    .size(56.dp)
                    .align(Alignment.Center)
            )
        }
    }
}

// MARK: - Modern TV Episode Card

@Composable
private fun ModernTVEpisodeCard(
    item: MediaItem,
    onItemClick: () -> Unit,
    onPlayClick: () -> Unit
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.04f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )

    Surface(
        onClick = onPlayClick,
        modifier = Modifier
            .width(320.dp)
            .height(180.dp)
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = RoundedCornerShape(14.dp),
        border = if (focused) BorderStroke(3.dp, AccentTeal) else null
    ) {
        Row {
            // Thumbnail
            Box(
                modifier = Modifier
                    .width(160.dp)
                    .fillMaxHeight()
            ) {
                AsyncImage(
                    model = item.posterUrl() ?: item.backdropUrl(),
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }

            // Info panel
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.8f))
                    .padding(14.dp)
            ) {
                // Show name
                Text(
                    text = item.grandparentTitle ?: "",
                    color = Color.White.copy(alpha = 0.6f),
                    fontSize = 12.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                // Episode title
                Text(
                    text = item.title,
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.weight(1f))

                // Season/Episode badge
                item.parentIndex?.let { season ->
                    item.index?.let { episode ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            colors = SurfaceDefaults.colors(
                                containerColor = Color.White.copy(alpha = 0.15f)
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Text(
                                    text = "S$season",
                                    color = AccentTeal,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Text(
                                    text = "E$episode",
                                    color = Color.White.copy(alpha = 0.8f),
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Duration
                item.duration?.let { duration ->
                    Text(
                        text = formatDuration(duration),
                        color = Color.White.copy(alpha = 0.5f),
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

// MARK: - Helper Views

@Composable
private fun TVMetadataPillModern(
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    text: String
) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        colors = SurfaceDefaults.colors(
            containerColor = Color.White.copy(alpha = 0.15f)
        )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            icon?.let {
                Icon(
                    imageVector = it,
                    contentDescription = null,
                    tint = Color.White.copy(alpha = 0.8f),
                    modifier = Modifier.size(14.dp)
                )
            }
            Text(
                text = text,
                color = Color.White.copy(alpha = 0.9f),
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
private fun ModernTVLoadingScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentAlignment = Alignment.Center
    ) {
        val infiniteTransition = rememberInfiniteTransition()
        val rotation by infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(1000, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            )
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier.size(48.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(AccentTeal.copy(alpha = 0.2f))
                )
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .graphicsLayer { rotationZ = rotation }
                        .drawWithContent {
                            drawContent()
                            drawArc(
                                color = AccentTeal,
                                startAngle = 0f,
                                sweepAngle = 90f,
                                useCenter = false,
                                style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx())
                            )
                        }
                )
            }

            Text(
                text = "Loading TV Shows...",
                color = Color.White.copy(alpha = 0.7f),
                fontSize = 16.sp
            )
        }
    }
}

@Composable
private fun ModernTVErrorScreen(
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
            Icon(
                imageVector = Icons.Default.ErrorOutline,
                contentDescription = null,
                tint = Color.Red.copy(alpha = 0.8f),
                modifier = Modifier.size(64.dp)
            )

            Text(
                text = message,
                color = Color.White.copy(alpha = 0.8f),
                fontSize = 16.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp)
            )

            var focused by remember { mutableStateOf(false) }
            val scale by animateFloatAsState(
                targetValue = if (focused) 1.05f else 1f,
                animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
            )

            Button(
                onClick = onRetry,
                modifier = Modifier
                    .scale(scale)
                    .onFocusChanged { focused = it.isFocused },
                colors = ButtonDefaults.colors(
                    containerColor = AccentTeal
                ),
                shape = RoundedCornerShape(24.dp)
            ) {
                Text(
                    text = "Try Again",
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

// MARK: - Helper Functions

private fun formatDuration(milliseconds: Long): String {
    val minutes = milliseconds / 60000
    val hours = minutes / 60
    val remainingMinutes = minutes % 60
    return if (hours > 0) "${hours}h ${remainingMinutes}m" else "${minutes}m"
}

private fun tvGenreIcon(genre: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (genre.lowercase()) {
        "drama" -> Icons.Default.TheaterComedy
        "comedy" -> Icons.Default.EmojiEmotions
        "action", "adventure" -> Icons.Default.LocalFireDepartment
        "sci-fi", "science fiction" -> Icons.Default.Rocket
        "horror", "thriller" -> Icons.Default.Visibility
        "documentary" -> Icons.Default.Description
        "animation", "anime" -> Icons.Default.Palette
        "crime" -> Icons.Default.Shield
        "mystery" -> Icons.Default.Search
        "romance" -> Icons.Default.Favorite
        "fantasy" -> Icons.Default.AutoAwesome
        "family" -> Icons.Default.FamilyRestroom
        else -> Icons.Default.Tv
    }
}

private fun tvGenreColor(genre: String): Color {
    return when (genre.lowercase()) {
        "drama" -> Color(0xFF9B59B6)
        "comedy" -> Color(0xFFFFD93D)
        "action", "adventure" -> Color(0xFFFF6B35)
        "sci-fi", "science fiction" -> Color(0xFF00CED1)
        "horror", "thriller" -> Color(0xFFE74C3C)
        "documentary" -> Color(0xFF95A5A6)
        "animation", "anime" -> Color(0xFFFF85A2)
        "crime" -> Color(0xFF5C6BC0)
        "mystery" -> Color(0xFF26A69A)
        "romance" -> Color(0xFFFF69B4)
        "fantasy" -> Color(0xFFAB47BC)
        "family" -> Color(0xFF66BB6A)
        else -> AccentTeal
    }
}
