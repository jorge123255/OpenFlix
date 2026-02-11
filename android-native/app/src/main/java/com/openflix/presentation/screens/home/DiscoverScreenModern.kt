package com.openflix.presentation.screens.home

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.foundation.lazy.list.TvLazyColumn
import androidx.tv.foundation.lazy.list.TvLazyRow
import androidx.tv.foundation.lazy.list.items
import androidx.tv.foundation.lazy.list.itemsIndexed
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * Modern Discover Screen - Premium streaming service inspired
 * Features: Parallax hero, glass effects, smooth animations, Top 10 row
 */
@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DiscoverScreenModern(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    onNavigateToLiveTVPlayer: ((String) -> Unit)? = null,
    onNavigateToGuide: (() -> Unit)? = null,
    onNavigateToMultiview: (() -> Unit)? = null,
    onNavigateToSports: (() -> Unit)? = null,
    onWatchlistToggle: ((String) -> Unit)? = null,
    viewModel: DiscoverViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // Hero auto-advance
    var heroIndex by remember { mutableIntStateOf(0) }
    val heroItems = uiState.hubs.flatMap { it.items }.take(5)
    
    LaunchedEffect(Unit) {
        viewModel.loadHomeContent()
    }
    
    // Auto-advance hero
    LaunchedEffect(heroItems) {
        while (heroItems.isNotEmpty()) {
            delay(10000)
            heroIndex = (heroIndex + 1) % heroItems.size
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        // Ambient background
        if (heroItems.isNotEmpty()) {
            AmbientBackground(item = heroItems.getOrNull(heroIndex))
        }
        
        TvLazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 48.dp)
        ) {
            // Hero Section
            if (heroItems.isNotEmpty()) {
                item {
                    ModernHeroBanner(
                        items = heroItems,
                        currentIndex = heroIndex,
                        onIndexChange = { heroIndex = it },
                        onPlay = { onPlayClick(it.id.toString()) },
                        onDetails = { onMediaClick(it.id.toString()) },
                        onWatchlist = onWatchlistToggle?.let { toggle -> 
                            { item: MediaItem -> toggle(item.id.toString()) }
                        }
                    )
                }
            }
            
            // Quick Access Row (Live TV, Multiview, Guide, Sports)
            item {
                QuickAccessRow(
                    onLiveTVClick = { 
                        uiState.channels.firstOrNull()?.let { onNavigateToLiveTVPlayer?.invoke(it.id) }
                    },
                    onMultiviewClick = onNavigateToMultiview,
                    onGuideClick = onNavigateToGuide,
                    onSportsClick = onNavigateToSports
                )
            }
            
            // Continue Watching
            if (uiState.continueWatching.isNotEmpty()) {
                item {
                    ModernContentRow(
                        title = "Continue Watching",
                        subtitle = "Pick up where you left off",
                        icon = Icons.Default.PlayCircle,
                        accentColor = Color(0xFF2196F3),
                        items = uiState.continueWatching,
                        style = ContentRowStyle.ContinueWatching,
                        onItemClick = { onPlayClick(it.id.toString()) }
                    )
                }
            }
            
            // Top 10
            if (uiState.hubs.isNotEmpty()) {
                val topItems = uiState.hubs.flatMap { it.items }
                    .sortedByDescending { it.audienceRating ?: 0.0 }
                    .take(10)
                
                if (topItems.size >= 5) {
                    item {
                        ModernTop10Row(
                            items = topItems,
                            onItemClick = { onMediaClick(it.id.toString()) }
                        )
                    }
                }
            }
            
            // Hub rows
            items(uiState.hubs) { hub ->
                ModernContentRow(
                    title = hub.title,
                    subtitle = null,
                    icon = getHubIcon(hub.title),
                    accentColor = getHubColor(hub.title),
                    items = hub.items,
                    style = ContentRowStyle.Poster,
                    onItemClick = { onMediaClick(it.id.toString()) }
                )
            }
            
            // Live Now (if channels available)
            if (uiState.channels.isNotEmpty()) {
                item {
                    LiveNowRow(
                        channels = uiState.channels.filter { it.nowPlaying != null }.take(10),
                        onChannelClick = { channel ->
                            onNavigateToLiveTVPlayer?.invoke(channel.id)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Ambient Background

@Composable
private fun AmbientBackground(item: MediaItem?) {
    Box(modifier = Modifier.fillMaxSize()) {
        item?.let {
            AsyncImage(
                model = it.art ?: it.thumb,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .blur(80.dp)
                    .graphicsLayer { alpha = 0.3f }
                    .scale(1.2f),
                contentScale = ContentScale.Crop
            )
        }
    }
}

// MARK: - Modern Hero Banner

@Composable
private fun ModernHeroBanner(
    items: List<MediaItem>,
    currentIndex: Int,
    onIndexChange: (Int) -> Unit,
    onPlay: (MediaItem) -> Unit,
    onDetails: (MediaItem) -> Unit,
    onWatchlist: ((MediaItem) -> Unit)? = null
) {
    val pagerState = rememberPagerState(
        initialPage = currentIndex,
        pageCount = { items.size }
    )
    
    LaunchedEffect(currentIndex) {
        pagerState.animateScrollToPage(currentIndex)
    }
    
    LaunchedEffect(pagerState.currentPage) {
        onIndexChange(pagerState.currentPage)
    }
    
    Box(modifier = Modifier.height(600.dp)) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            items.getOrNull(page)?.let { item ->
                ModernHeroItem(
                    item = item,
                    onPlay = { onPlay(item) },
                    onDetails = { onDetails(item) },
                    onWatchlist = onWatchlist?.let { { it(item) } }
                )
            }
        }
        
        // Page indicators
        if (items.size > 1) {
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 24.dp)
                    .background(
                        Color.Black.copy(alpha = 0.4f),
                        RoundedCornerShape(20.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items.forEachIndexed { index, _ ->
                    Box(
                        modifier = Modifier
                            .size(
                                width = if (index == currentIndex) 24.dp else 8.dp,
                                height = 8.dp
                            )
                            .clip(RoundedCornerShape(4.dp))
                            .background(
                                if (index == currentIndex) Color.White
                                else Color.White.copy(alpha = 0.4f)
                            )
                            .animateContentSize()
                    )
                }
            }
        }
    }
}

// MARK: - Modern Hero Item

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernHeroItem(
    item: MediaItem,
    onPlay: () -> Unit,
    onDetails: () -> Unit,
    onWatchlist: (() -> Unit)? = null
) {
    var playFocused by remember { mutableStateOf(false) }
    var infoFocused by remember { mutableStateOf(false) }
    var watchlistFocused by remember { mutableStateOf(false) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        // Background image
        AsyncImage(
            model = item.art ?: item.thumb,
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )
        
        // Gradient overlays
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.7f),
                            Color.Black
                        )
                    )
                )
        )
        
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            Color.Black.copy(alpha = 0.8f),
                            Color.Black.copy(alpha = 0.4f),
                            Color.Transparent
                        )
                    )
                )
        )
        
        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 48.dp)
                .padding(bottom = 80.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            // Title
            Text(
                text = item.title,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Tagline
            item.tagline?.let {
                Text(
                    text = it,
                    fontSize = 20.sp,
                    color = Color.White.copy(alpha = 0.85f),
                    maxLines = 2
                )
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Metadata
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Rating
                item.audienceRating?.let { rating ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = Color.Yellow,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = String.format("%.1f", rating),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
                
                // Year
                item.year?.let {
                    Text(
                        text = it.toString(),
                        fontSize = 16.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
                
                // Content rating
                item.contentRating?.let {
                    Text(
                        text = it,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        modifier = Modifier
                            .background(
                                Color.White.copy(alpha = 0.2f),
                                RoundedCornerShape(4.dp)
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
                
                // Duration
                item.duration?.let { ms ->
                    val hours = ms / 3600000
                    val minutes = (ms % 3600000) / 60000
                    val text = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
                    Text(
                        text = text,
                        fontSize = 16.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
                
                // Genres
                if (item.genres.isNotEmpty()) {
                    Text(
                        text = item.genres.take(2).joinToString(" · "),
                        fontSize = 16.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Play button
                Surface(
                    onClick = onPlay,
                    modifier = Modifier
                        .onFocusChanged { playFocused = it.isFocused }
                        .graphicsLayer {
                            scaleX = if (playFocused) 1.1f else 1f
                            scaleY = if (playFocused) 1.1f else 1f
                        },
                    shape = RoundedCornerShape(28.dp),
                    colors = SurfaceDefaults.colors(
                        containerColor = Color.White
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 32.dp, vertical = 14.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = Color.Black,
                            modifier = Modifier.size(24.dp)
                        )
                        Text(
                            text = if (item.viewOffset != null) "Resume" else "Play",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.Black
                        )
                    }
                }
                
                // More Info button
                Surface(
                    onClick = onDetails,
                    modifier = Modifier
                        .onFocusChanged { infoFocused = it.isFocused }
                        .graphicsLayer {
                            scaleX = if (infoFocused) 1.1f else 1f
                            scaleY = if (infoFocused) 1.1f else 1f
                        },
                    shape = CircleShape,
                    colors = SurfaceDefaults.colors(
                        containerColor = Color.White.copy(alpha = 0.2f)
                    ),
                    border = BorderStroke(
                        width = if (infoFocused) 2.dp else 1.dp,
                        color = if (infoFocused) Color.White else Color.White.copy(alpha = 0.5f)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier
                            .padding(14.dp)
                            .size(24.dp)
                    )
                }
                
                // Watchlist button
                onWatchlist?.let { watchlistAction ->
                    Surface(
                        onClick = watchlistAction,
                        modifier = Modifier
                            .onFocusChanged { watchlistFocused = it.isFocused }
                            .graphicsLayer {
                                scaleX = if (watchlistFocused) 1.1f else 1f
                                scaleY = if (watchlistFocused) 1.1f else 1f
                            },
                        shape = CircleShape,
                        colors = SurfaceDefaults.colors(
                            containerColor = Color.White.copy(alpha = 0.2f)
                        ),
                        border = BorderStroke(
                            width = if (watchlistFocused) 2.dp else 1.dp,
                            color = if (watchlistFocused) Color(0xFF00D4AA) else Color.White.copy(alpha = 0.5f)
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.BookmarkAdd,
                            contentDescription = "Add to Watchlist",
                            tint = if (watchlistFocused) Color(0xFF00D4AA) else Color.White,
                            modifier = Modifier
                                .padding(14.dp)
                                .size(24.dp)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Content Row Styles

enum class ContentRowStyle {
    Poster,
    Wide,
    ContinueWatching
}

// MARK: - Modern Content Row

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernContentRow(
    title: String,
    subtitle: String?,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    accentColor: Color,
    items: List<MediaItem>,
    style: ContentRowStyle,
    onItemClick: (MediaItem) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 32.dp)
    ) {
        // Header
        Row(
            modifier = Modifier
                .padding(horizontal = 48.dp)
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = accentColor,
                modifier = Modifier.size(24.dp)
            )
            
            Column {
                Text(
                    text = title,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                
                subtitle?.let {
                    Text(
                        text = it,
                        fontSize = 14.sp,
                        color = Color.White.copy(alpha = 0.6f)
                    )
                }
            }
        }
        
        // Items
        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(items) { item ->
                when (style) {
                    ContentRowStyle.Poster -> ModernPosterCard(item = item, onClick = { onItemClick(item) })
                    ContentRowStyle.Wide -> ModernWideCard(item = item, onClick = { onItemClick(item) })
                    ContentRowStyle.ContinueWatching -> ModernContinueCard(item = item, onClick = { onItemClick(item) })
                }
            }
        }
    }
}

// MARK: - Modern Poster Card

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernPosterCard(
    item: MediaItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.08f else 1f,
        animationSpec = spring(dampingRatio = 0.7f)
    )
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(160.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(12.dp),
        border = if (isFocused) BorderStroke(3.dp, OpenFlixColors.Primary) else null
    ) {
        Column {
            Box {
                AsyncImage(
                    model = item.thumb,
                    contentDescription = null,
                    modifier = Modifier
                        .aspectRatio(2f / 3f)
                        .fillMaxWidth(),
                    contentScale = ContentScale.Crop
                )
                
                // Info overlay on focus
                AnimatedVisibility(
                    visible = isFocused,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
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
                            ),
                        contentAlignment = Alignment.BottomStart
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            item.audienceRating?.let { rating ->
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Star,
                                        contentDescription = null,
                                        tint = Color.Yellow,
                                        modifier = Modifier.size(14.dp)
                                    )
                                    Text(
                                        text = String.format("%.1f", rating),
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Title
            Text(
                text = item.title,
                fontSize = 14.sp,
                fontWeight = if (isFocused) FontWeight.SemiBold else FontWeight.Normal,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(12.dp)
            )
        }
    }
}

// MARK: - Modern Wide Card

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernWideCard(
    item: MediaItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f)
    )
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(320.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(12.dp),
        border = if (isFocused) BorderStroke(3.dp, OpenFlixColors.Primary) else null
    ) {
        Box {
            AsyncImage(
                model = item.art ?: item.thumb,
                contentDescription = null,
                modifier = Modifier
                    .aspectRatio(16f / 9f)
                    .fillMaxWidth(),
                contentScale = ContentScale.Crop
            )
            
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
            
            // Info
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(16.dp)
            ) {
                Text(
                    text = item.title,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    item.year?.let {
                        Text(
                            text = it.toString(),
                            fontSize = 14.sp,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                    }
                    
                    item.contentRating?.let {
                        Text(
                            text = it,
                            fontSize = 12.sp,
                            color = Color.White,
                            modifier = Modifier
                                .background(
                                    Color.White.copy(alpha = 0.2f),
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Modern Continue Card

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernContinueCard(
    item: MediaItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f)
    )
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(12.dp),
        border = if (isFocused) BorderStroke(3.dp, OpenFlixColors.Primary) else null
    ) {
        Column {
            Box {
                AsyncImage(
                    model = item.art ?: item.thumb,
                    contentDescription = null,
                    modifier = Modifier
                        .aspectRatio(16f / 9f)
                        .fillMaxWidth(),
                    contentScale = ContentScale.Crop
                )
                
                // Dark overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f))
                )
                
                // Play icon on focus
                AnimatedVisibility(
                    visible = isFocused,
                    enter = scaleIn() + fadeIn(),
                    exit = scaleOut() + fadeOut(),
                    modifier = Modifier.align(Alignment.Center)
                ) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .background(
                                Color.White.copy(alpha = 0.9f),
                                CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = Color.Black,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
                
                // Progress bar
                val progress = item.viewOffset?.let { offset ->
                    item.duration?.let { duration ->
                        if (duration > 0) offset.toFloat() / duration.toFloat() else 0f
                    }
                } ?: 0f
                
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .height(4.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.White.copy(alpha = 0.3f))
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(progress)
                            .background(OpenFlixColors.Primary)
                    )
                }
            }
            
            // Info
            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = item.title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                val remainingMs = item.duration?.let { duration ->
                    item.viewOffset?.let { offset ->
                        duration - offset
                    }
                }
                
                remainingMs?.let { ms ->
                    val minutes = ms / 60000
                    Text(
                        text = "${minutes}m left",
                        fontSize = 12.sp,
                        color = Color.White.copy(alpha = 0.6f)
                    )
                }
            }
        }
    }
}

// MARK: - Modern Top 10 Row

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernTop10Row(
    items: List<MediaItem>,
    onItemClick: (MediaItem) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 32.dp)
    ) {
        // Header
        Row(
            modifier = Modifier
                .padding(horizontal = 48.dp)
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "TOP",
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                color = Color.Red
            )
            Text(
                text = "10",
                fontSize = 28.sp,
                fontWeight = FontWeight.Black,
                color = Color.Red
            )
            Text(
                text = "in Your Library",
                fontSize = 18.sp,
                color = Color.White.copy(alpha = 0.8f)
            )
        }
        
        // Items
        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            itemsIndexed(items.take(10)) { index, item ->
                ModernTop10Card(
                    item = item,
                    rank = index + 1,
                    onClick = { onItemClick(item) }
                )
            }
        }
    }
}

// MARK: - Modern Top 10 Card

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ModernTop10Card(
    item: MediaItem,
    rank: Int,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.08f else 1f,
        animationSpec = spring(dampingRatio = 0.7f)
    )
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(0.dp),
        colors = SurfaceDefaults.colors(containerColor = Color.Transparent)
    ) {
        Row(
            verticalAlignment = Alignment.Bottom
        ) {
            // Rank number
            Text(
                text = "$rank",
                fontSize = 120.sp,
                fontWeight = FontWeight.Black,
                color = Color.White.copy(alpha = 0.2f),
                modifier = Modifier.offset(x = 20.dp)
            )
            
            // Poster
            AsyncImage(
                model = item.thumb,
                contentDescription = null,
                modifier = Modifier
                    .width(120.dp)
                    .aspectRatio(2f / 3f)
                    .clip(RoundedCornerShape(8.dp))
                    .border(
                        width = if (isFocused) 3.dp else 0.dp,
                        color = if (isFocused) OpenFlixColors.Primary else Color.Transparent,
                        shape = RoundedCornerShape(8.dp)
                    ),
                contentScale = ContentScale.Crop
            )
        }
    }
}

// MARK: - Quick Access Row

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun QuickAccessRow(
    onLiveTVClick: (() -> Unit)?,
    onMultiviewClick: (() -> Unit)?,
    onGuideClick: (() -> Unit)?,
    onSportsClick: (() -> Unit)?
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 48.dp, vertical = 24.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Live TV
        QuickAccessCard(
            icon = Icons.Default.LiveTv,
            title = "Live TV",
            subtitle = "Watch now",
            color = Color(0xFFE53935),
            onClick = onLiveTVClick
        )
        
        // Multiview
        QuickAccessCard(
            icon = Icons.Default.GridView,
            title = "Multiview",
            subtitle = "Watch 2-4 channels",
            color = Color(0xFF00D4AA),
            onClick = onMultiviewClick
        )
        
        // Guide
        QuickAccessCard(
            icon = Icons.Default.CalendarMonth,
            title = "TV Guide",
            subtitle = "What's on",
            color = Color(0xFF2196F3),
            onClick = onGuideClick
        )
        
        // Sports
        QuickAccessCard(
            icon = Icons.Default.SportsFootball,
            title = "Sports",
            subtitle = "Live scores",
            color = Color(0xFFFF9800),
            onClick = onSportsClick
        )
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun QuickAccessCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    color: Color,
    onClick: (() -> Unit)?
) {
    var focused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (focused) 1.05f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f)
    )
    
    Surface(
        onClick = { onClick?.invoke() },
        modifier = Modifier
            .weight(1f)
            .height(100.dp)
            .graphicsLayer { 
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(16.dp),
        colors = SurfaceDefaults.colors(
            containerColor = if (focused) color.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f),
            focusedContainerColor = color.copy(alpha = 0.3f)
        ),
        border = if (focused) BorderStroke(2.dp, color) else BorderStroke(1.dp, Color.White.copy(alpha = 0.1f))
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(color.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(28.dp)
                )
            }
            
            Column {
                Text(
                    text = title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.6f)
                )
            }
        }
    }
}

// MARK: - Live Now Row

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun LiveNowRow(
    channels: List<Channel>,
    onChannelClick: (Channel) -> Unit
) {
    if (channels.isEmpty()) return
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 32.dp)
    ) {
        // Header
        Row(
            modifier = Modifier
                .padding(horizontal = 48.dp)
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Live indicator
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(Color.Red)
            )
            
            Text(
                text = "Live Now",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
        
        // Channels
        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(channels) { channel ->
                LiveChannelCard(
                    channel = channel,
                    onClick = { onChannelClick(channel) }
                )
            }
        }
    }
}

// MARK: - Live Channel Card

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun LiveChannelCard(
    channel: Channel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                val scale = if (isFocused) 1.05f else 1f
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(12.dp),
        colors = SurfaceDefaults.colors(
            containerColor = if (isFocused) OpenFlixColors.Primary.copy(alpha = 0.2f)
                            else OpenFlixColors.Card
        ),
        border = if (isFocused) BorderStroke(2.dp, OpenFlixColors.Primary) else null
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Logo
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.White.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    channel.logo?.let {
                        AsyncImage(
                            model = it,
                            contentDescription = null,
                            modifier = Modifier.size(40.dp),
                            contentScale = ContentScale.Fit
                        )
                    } ?: Text(
                        text = channel.number?.toString() ?: "?",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = channel.name,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    channel.nowPlaying?.let { program ->
                        Text(
                            text = program.title,
                            fontSize = 12.sp,
                            color = Color.White.copy(alpha = 0.7f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                
                // LIVE badge
                Text(
                    text = "LIVE",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Black,
                    color = Color.White,
                    modifier = Modifier
                        .background(Color.Red, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
        }
    }
}

// MARK: - Helpers

private fun getHubIcon(title: String): androidx.compose.ui.graphics.vector.ImageVector {
    val lower = title.lowercase()
    return when {
        lower.contains("action") -> Icons.Default.LocalFireDepartment
        lower.contains("comedy") -> Icons.Default.EmojiEmotions
        lower.contains("drama") -> Icons.Default.TheaterComedy
        lower.contains("horror") -> Icons.Default.Nightlight
        lower.contains("sci") -> Icons.Default.RocketLaunch
        lower.contains("recently") -> Icons.Default.NewReleases
        lower.contains("popular") -> Icons.Default.TrendingUp
        lower.contains("recommend") -> Icons.Default.AutoAwesome
        else -> Icons.Default.Movie
    }
}

private fun getHubColor(title: String): Color {
    val lower = title.lowercase()
    return when {
        lower.contains("action") -> Color.Red
        lower.contains("comedy") -> Color.Yellow
        lower.contains("drama") -> Color(0xFF9C27B0)
        lower.contains("horror") -> Color.Gray
        lower.contains("sci") -> Color.Cyan
        lower.contains("recently") -> OpenFlixColors.Primary
        lower.contains("popular") -> Color(0xFFFF6B35)
        lower.contains("recommend") -> Color(0xFF9C27B0)
        else -> OpenFlixColors.Primary
    }
}

private fun Modifier.scale(scale: Float): Modifier = graphicsLayer {
    scaleX = scale
    scaleY = scale
}
