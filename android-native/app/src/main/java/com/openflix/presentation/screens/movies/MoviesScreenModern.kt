package com.openflix.presentation.screens.movies

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
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
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
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
import com.openflix.presentation.components.ContentType
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

// Modern accent color matching tvOS
private val AccentTeal = Color(0xFF00D4AA)
private val AccentTealDark = Color(0xFF00A080)

/**
 * Modern Movies Screen - Channels DVR 7.0 inspired
 * Glass morphism, spring animations, theater mode hero
 */
@Composable
fun MoviesScreenModern(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onBrowseAll: () -> Unit,
    viewModel: MoviesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    var selectedGenre by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadMovies()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Ambient background blur from featured content
        if (uiState.featuredItems.isNotEmpty()) {
            AsyncImage(
                model = uiState.featuredItems.first().backdropUrl,
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
                ModernLoadingScreen()
            }
            uiState.error != null -> {
                ModernErrorScreen(
                    message = uiState.error!!,
                    onRetry = viewModel::loadMovies
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
                            TheaterModeHeroModern(
                                items = uiState.featuredItems,
                                trailers = uiState.trailers,
                                onPlayClick = { item -> onPlayClick(item.id) },
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
                        GenreFilterBarModern(
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
                            ModernContentRow(
                                title = "Continue Watching",
                                subtitle = "Pick up where you left off",
                                icon = Icons.Default.PlayCircle,
                                accentColor = Color(0xFF4A90D9),
                                items = uiState.continueWatching,
                                cardStyle = CardStyle.ContinueWatching,
                                onItemClick = onMediaClick,
                                onPlayClick = onPlayClick
                            )
                        }
                    }

                    // Recently Added
                    if (uiState.hubs.any { it.title.contains("Recent", ignoreCase = true) }) {
                        val recentHub = uiState.hubs.first { it.title.contains("Recent", ignoreCase = true) }
                        item {
                            ModernContentRow(
                                title = "Recently Added",
                                subtitle = "Fresh arrivals",
                                icon = Icons.Default.NewReleases,
                                accentColor = AccentTeal,
                                items = recentHub.items,
                                cardStyle = CardStyle.Poster,
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
                        ModernContentRow(
                            title = genreHub.genre,
                            subtitle = "${genreHub.items.size} movies",
                            icon = genreIcon(genreHub.genre),
                            accentColor = genreColor(genreHub.genre),
                            items = genreHub.items,
                            cardStyle = CardStyle.Poster,
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
private fun TheaterModeHeroModern(
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
            model = currentItem.backdropUrl,
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
            // MOVIES badge
            Surface(
                shape = RoundedCornerShape(20.dp),
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = AccentTeal.copy(alpha = 0.2f)
                ),
                border = Border(BorderStroke(1.dp, AccentTeal.copy(alpha = 0.5f)))
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Movie,
                        contentDescription = null,
                        tint = AccentTeal,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "MOVIE",
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

                currentItem.duration?.let { duration ->
                    MetadataPillModern(text = formatDuration(duration))
                }

                currentItem.contentRating?.let { rating ->
                    MetadataPillModern(text = rating)
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
                // Play button
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
                    shape = ButtonDefaults.shape(shape = RoundedCornerShape(28.dp)),
                    contentPadding = PaddingValues(horizontal = 32.dp, vertical = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Play",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                // More Info button
                var infoFocused by remember { mutableStateOf(false) }
                val infoScale by animateFloatAsState(
                    targetValue = if (infoFocused) 1.06f else 1f,
                    animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
                )

                OutlinedButton(
                    onClick = { onInfoClick(currentItem) },
                    modifier = Modifier
                        .scale(infoScale)
                        .onFocusChanged {
                            infoFocused = it.isFocused
                            if (it.isFocused) isAutoPlaying = false
                        },
                    colors = ButtonDefaults.colors(
                        containerColor = Color.White.copy(alpha = 0.15f),
                        contentColor = Color.White
                    ),
                    border = ButtonDefaults.border(
                        border = Border(BorderStroke(1.dp, Color.White.copy(alpha = 0.5f))),
                        focusedBorder = Border(BorderStroke(2.dp, Color.White))
                    ),
                    shape = ButtonDefaults.shape(shape = RoundedCornerShape(28.dp)),
                    contentPadding = PaddingValues(horizontal = 24.dp, vertical = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "More Info",
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
                        border = ButtonDefaults.border(
                            border = Border(BorderStroke(1.dp, Color.White.copy(alpha = 0.3f)))
                        ),
                        shape = ButtonDefaults.shape(shape = RoundedCornerShape(28.dp)),
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
private fun GenreFilterBarModern(
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
                shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(24.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = AccentTeal.copy(alpha = 0.15f)
                ),
                border = ClickableSurfaceDefaults.border(
                    border = Border(BorderStroke(1.dp, AccentTeal.copy(alpha = 0.5f)))
                )
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
            GenrePillModern(
                genre = genre,
                isSelected = genre == selectedGenre,
                onSelect = { onGenreSelected(genre) }
            )
        }
    }
}

@Composable
private fun GenrePillModern(
    genre: String,
    isSelected: Boolean = false,
    onSelect: () -> Unit = {}
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )
    val color = genreColor(genre)

    Surface(
        onClick = onSelect,
        modifier = Modifier
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(20.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                isSelected -> color.copy(alpha = 0.5f)
                focused -> color.copy(alpha = 0.3f)
                else -> Color.White.copy(alpha = 0.1f)
            }
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(BorderStroke(2.dp, Color.White))
        )
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

enum class CardStyle { Poster, ContinueWatching }

@Composable
private fun ModernContentRow(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    accentColor: Color,
    items: List<MediaItem>,
    cardStyle: CardStyle,
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
                    CardStyle.Poster -> ModernPosterCard(
                        item = item,
                        onItemClick = { onItemClick(item.id) }
                    )
                    CardStyle.ContinueWatching -> ModernContinueCard(
                        item = item,
                        onItemClick = { onItemClick(item.id) },
                        onPlayClick = { onPlayClick(item.id) }
                    )
                }
            }
        }
    }
}

// MARK: - Modern Poster Card

@Composable
private fun ModernPosterCard(
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
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(12.dp)),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(BorderStroke(4.dp, AccentTeal))
        )
    ) {
        Box {
            // Poster image
            AsyncImage(
                model = item.posterUrl,
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
                item.year?.let { year ->
                    Text(
                        text = year.toString(),
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

// MARK: - Modern Continue Card

@Composable
private fun ModernContinueCard(
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
            .width(320.dp)
            .height(200.dp)
            .scale(scale)
            .onFocusChanged { focused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(BorderStroke(4.dp, AccentTeal))
        )
    ) {
        Box {
            // Background
            AsyncImage(
                model = item.backdropUrl ?: item.posterUrl,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )

            // Glass overlay at bottom
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
                    .align(Alignment.BottomCenter)
                    .background(Color.Black.copy(alpha = 0.7f))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(12.dp)
                ) {
                    Text(
                        text = item.title,
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Time remaining
                    item.duration?.let { duration ->
                        item.viewOffset?.let { offset ->
                            val remaining = (duration - offset) / 60000
                            Text(
                                text = "${remaining}min left",
                                color = Color.White.copy(alpha = 0.7f),
                                fontSize = 12.sp
                            )
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

// MARK: - Helper Views

@Composable
private fun MetadataPillModern(text: String) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        colors = NonInteractiveSurfaceDefaults.colors(
            containerColor = Color.White.copy(alpha = 0.15f)
        )
    ) {
        Text(
            text = text,
            color = Color.White.copy(alpha = 0.9f),
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun ModernLoadingScreen() {
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
                // Background circle
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(AccentTeal.copy(alpha = 0.2f))
                )
                // Spinning arc
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
                text = "Loading Movies...",
                color = Color.White.copy(alpha = 0.7f),
                fontSize = 16.sp
            )
        }
    }
}

@Composable
private fun ModernErrorScreen(
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
                shape = ButtonDefaults.shape(shape = RoundedCornerShape(24.dp))
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

private fun genreIcon(genre: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (genre.lowercase()) {
        "action", "adventure" -> Icons.Default.LocalFireDepartment
        "comedy" -> Icons.Default.EmojiEmotions
        "drama" -> Icons.Default.TheaterComedy
        "horror", "thriller" -> Icons.Default.Visibility
        "sci-fi", "science fiction" -> Icons.Default.Rocket
        "romance" -> Icons.Default.Favorite
        "documentary" -> Icons.Default.Description
        "animation", "anime" -> Icons.Default.Palette
        "crime" -> Icons.Default.Shield
        "mystery" -> Icons.Default.Search
        "fantasy" -> Icons.Default.AutoAwesome
        "family" -> Icons.Default.FamilyRestroom
        else -> Icons.Default.Movie
    }
}

private fun genreColor(genre: String): Color {
    return when (genre.lowercase()) {
        "action", "adventure" -> Color(0xFFFF6B35)
        "comedy" -> Color(0xFFFFD93D)
        "drama" -> Color(0xFF9B59B6)
        "horror", "thriller" -> Color(0xFFE74C3C)
        "sci-fi", "science fiction" -> Color(0xFF00CED1)
        "romance" -> Color(0xFFFF69B4)
        "documentary" -> Color(0xFF95A5A6)
        "animation", "anime" -> Color(0xFFFF85A2)
        "crime" -> Color(0xFF5C6BC0)
        "mystery" -> Color(0xFF26A69A)
        "fantasy" -> Color(0xFFAB47BC)
        "family" -> Color(0xFF66BB6A)
        else -> AccentTeal
    }
}
