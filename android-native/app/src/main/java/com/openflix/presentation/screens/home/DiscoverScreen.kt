package com.openflix.presentation.screens.home

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import com.openflix.data.local.LastWatchedService
import com.openflix.domain.model.Channel
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.player.LiveTVPlayer
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay
import timber.log.Timber
import java.util.*
import kotlin.random.Random

/**
 * Netflix/Apple TV+ Style Home Screen
 * Full-screen immersive hero with content rows
 */
@Composable
fun DiscoverScreen(
    onMediaClick: (String) -> Unit,
    onPlayClick: (String) -> Unit,
    liveTVPlayer: LiveTVPlayer? = null,
    lastWatchedService: LastWatchedService? = null,
    onNavigateToLiveTVPlayer: ((String) -> Unit)? = null,
    onNavigateToGuide: (() -> Unit)? = null,
    onNavigateToSidebar: (() -> Unit)? = null,
    viewModel: DiscoverViewModel = hiltViewModel()
) {
    // VOD state from ViewModel
    val vodState by viewModel.uiState.collectAsState()

    // Channel state for Live Now section
    var channels by remember { mutableStateOf<List<Channel>>(emptyList()) }

    // Hero state
    var heroIndex by remember { mutableIntStateOf(0) }

    // Load content
    LaunchedEffect(Unit) {
        viewModel.loadChannels { loadedChannels ->
            channels = loadedChannels
        }
        viewModel.loadHomeContent()
    }

    // All media items
    val allItems = vodState.hubs.flatMap { it.items }

    // Hero items (items with art/banner for full-screen display)
    val heroItems = remember(allItems) {
        allItems.filter { it.art != null || it.banner != null }.take(10)
    }

    // Auto-rotate hero every 10 seconds
    LaunchedEffect(heroItems.size) {
        if (heroItems.isNotEmpty()) {
            while (true) {
                delay(10000)
                heroIndex = (heroIndex + 1) % heroItems.size
            }
        }
    }

    val currentHeroItem = heroItems.getOrNull(heroIndex)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0A0A0A))
    ) {
        // === FULL-SCREEN BACKGROUND ART ===
        currentHeroItem?.let { item ->
            // Background image with blur and fade
            AsyncImage(
                model = item.art ?: item.banner ?: item.thumb,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer { alpha = 0.6f }
                    .blur(8.dp),
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
                                Color(0xFF0A0A0A).copy(alpha = 0.3f),
                                Color(0xFF0A0A0A).copy(alpha = 0.7f),
                                Color(0xFF0A0A0A)
                            ),
                            startY = 0f,
                            endY = 1200f
                        )
                    )
            )

            // Left gradient for text readability
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                Color(0xFF0A0A0A).copy(alpha = 0.8f),
                                Color.Transparent,
                                Color.Transparent
                            ),
                            startX = 0f,
                            endX = 800f
                        )
                    )
            )
        }

        // === MAIN CONTENT ===
        TvLazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 48.dp)
        ) {
            // === HERO SECTION ===
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(380.dp)
                        .focusGroup()
                ) {
                    // OpenFlix logo at top right
                    Text(
                        text = "OPENFLIX",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.Primary,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(top = 24.dp, end = 48.dp)
                    )

                    // Hero content (left side)
                    currentHeroItem?.let { item ->
                        AnimatedContent(
                            targetState = item,
                            transitionSpec = {
                                fadeIn(animationSpec = tween(800)) togetherWith
                                        fadeOut(animationSpec = tween(800))
                            },
                            label = "hero_content",
                            modifier = Modifier
                                .align(Alignment.BottomStart)
                                .padding(start = 48.dp, bottom = 16.dp)
                                .width(550.dp)
                        ) { heroItem ->
                            Column {
                                // Title
                                Text(
                                    text = heroItem.title,
                                    style = MaterialTheme.typography.displaySmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis
                                )

                                Spacer(modifier = Modifier.height(12.dp))

                                // Metadata row
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // Year
                                    heroItem.year?.let { year ->
                                        Text(
                                            text = year.toString(),
                                            style = MaterialTheme.typography.bodyLarge,
                                            color = Color.White.copy(alpha = 0.9f)
                                        )
                                    }

                                    // Rating
                                    heroItem.rating?.let { rating ->
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Filled.Star,
                                                contentDescription = null,
                                                tint = Color(0xFFFFD700),
                                                modifier = Modifier.size(18.dp)
                                            )
                                            Text(
                                                text = String.format("%.1f", rating),
                                                style = MaterialTheme.typography.bodyLarge,
                                                fontWeight = FontWeight.SemiBold,
                                                color = Color.White.copy(alpha = 0.9f)
                                            )
                                        }
                                    }

                                    // Content rating
                                    heroItem.contentRating?.let { rating ->
                                        Box(
                                            modifier = Modifier
                                                .border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(4.dp))
                                                .padding(horizontal = 8.dp, vertical = 2.dp)
                                        ) {
                                            Text(
                                                text = rating,
                                                style = MaterialTheme.typography.labelMedium,
                                                color = Color.White.copy(alpha = 0.9f)
                                            )
                                        }
                                    }

                                    // Type badge
                                    val typeText = when (heroItem.type) {
                                        MediaType.MOVIE -> "Movie"
                                        MediaType.SHOW -> "Series"
                                        MediaType.EPISODE -> "Episode"
                                        else -> null
                                    }
                                    typeText?.let {
                                        Text(
                                            text = it,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                // Summary
                                heroItem.summary?.let { summary ->
                                    Text(
                                        text = summary,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White.copy(alpha = 0.8f),
                                        maxLines = 2,
                                        overflow = TextOverflow.Ellipsis,
                                        lineHeight = 18.sp
                                    )
                                }

                                Spacer(modifier = Modifier.height(16.dp))

                                // Action buttons
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                                ) {
                                    // Play button
                                    Surface(
                                        onClick = { onPlayClick(heroItem.id) },
                                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(6.dp)),
                                        colors = ClickableSurfaceDefaults.colors(
                                            containerColor = Color.White,
                                            focusedContainerColor = Color.White.copy(alpha = 0.9f)
                                        ),
                                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
                                        glow = ClickableSurfaceDefaults.glow(
                                            focusedGlow = Glow(
                                                elevationColor = Color.White.copy(alpha = 0.3f),
                                                elevation = 16.dp
                                            )
                                        )
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Filled.PlayArrow,
                                                contentDescription = null,
                                                tint = Color.Black,
                                                modifier = Modifier.size(20.dp)
                                            )
                                            Text(
                                                text = "Play",
                                                style = MaterialTheme.typography.bodyLarge,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.Black
                                            )
                                        }
                                    }

                                    // More Info button
                                    Surface(
                                        onClick = { onMediaClick(heroItem.id) },
                                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(6.dp)),
                                        colors = ClickableSurfaceDefaults.colors(
                                            containerColor = Color.White.copy(alpha = 0.2f),
                                            focusedContainerColor = Color.White.copy(alpha = 0.3f)
                                        ),
                                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Filled.Info,
                                                contentDescription = null,
                                                tint = Color.White,
                                                modifier = Modifier.size(20.dp)
                                            )
                                            Text(
                                                text = "More Info",
                                                style = MaterialTheme.typography.bodyLarge,
                                                fontWeight = FontWeight.SemiBold,
                                                color = Color.White
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Page indicators (bottom center)
                    if (heroItems.size > 1) {
                        Row(
                            modifier = Modifier
                                .align(Alignment.BottomCenter)
                                .padding(bottom = 16.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            heroItems.forEachIndexed { index, _ ->
                                Box(
                                    modifier = Modifier
                                        .size(
                                            width = if (index == heroIndex) 24.dp else 8.dp,
                                            height = 4.dp
                                        )
                                        .clip(RoundedCornerShape(2.dp))
                                        .background(
                                            if (index == heroIndex) Color.White
                                            else Color.White.copy(alpha = 0.4f)
                                        )
                                )
                            }
                        }
                    }
                }
            }

            // === CONTINUE WATCHING ===
            val continueWatching = allItems.filter { (it.viewOffset ?: 0) > 0 }.take(10)
            if (continueWatching.isNotEmpty()) {
                item {
                    ContentRow(
                        title = "Continue Watching",
                        icon = Icons.Filled.PlayCircle,
                        items = continueWatching,
                        onItemClick = onMediaClick,
                        showProgress = true
                    )
                }
            }

            // === LIVE NOW ===
            if (channels.isNotEmpty()) {
                item {
                    LiveNowRow(
                        channels = channels.take(15),
                        onChannelClick = { channel ->
                            onNavigateToLiveTVPlayer?.invoke(channel.id)
                        }
                    )
                }
            }

            // === TOP 10 TODAY ===
            val top10Items = allItems
                .filter { it.type == MediaType.MOVIE || it.type == MediaType.SHOW }
                .sortedByDescending { it.rating ?: 0.0 }
                .take(10)
            if (top10Items.isNotEmpty()) {
                item {
                    Top10Row(
                        items = top10Items,
                        onItemClick = onMediaClick
                    )
                }
            }

            // === JUST ADDED ===
            val justAdded = allItems.sortedByDescending { it.addedAt ?: 0 }.take(12)
            if (justAdded.isNotEmpty()) {
                item {
                    ContentRow(
                        title = "Just Added",
                        icon = Icons.Filled.NewReleases,
                        iconColor = Color(0xFF00E676),
                        items = justAdded,
                        onItemClick = onMediaClick,
                        showNewBadge = true
                    )
                }
            }

            // === KIDS & FAMILY ===
            val kidsRatings = setOf("G", "PG", "TV-G", "TV-Y", "TV-Y7", "TV-PG")
            val kidsItems = allItems.filter { item ->
                val rating = item.contentRating?.uppercase() ?: return@filter false
                rating in kidsRatings
            }.distinctBy { it.id }.take(15)
            if (kidsItems.isNotEmpty()) {
                item {
                    ContentRow(
                        title = "Kids & Family",
                        icon = Icons.Filled.FamilyRestroom,
                        iconColor = Color(0xFF4CAF50),
                        items = kidsItems,
                        onItemClick = onMediaClick
                    )
                }
            }

            // === STREAMING SERVICE ROWS (Netflix, Disney+, HBO Max, etc.) ===
            vodState.streamingServiceHubs.forEach { hub ->
                if (hub.items.isNotEmpty()) {
                    item {
                        StreamingServiceRow(
                            serviceName = hub.title,
                            items = hub.items.take(15),
                            onItemClick = onMediaClick
                        )
                    }
                }
            }

            // === FEELING LUCKY ===
            if (allItems.isNotEmpty()) {
                item {
                    FeelingLuckyRow(
                        items = allItems,
                        onItemClick = onMediaClick,
                        onPlayClick = onPlayClick
                    )
                }
            }

            // === LIBRARY SECTIONS ===
            vodState.hubs.forEach { hub ->
                if (hub.items.isNotEmpty()) {
                    item {
                        ContentRow(
                            title = hub.title,
                            items = hub.items.take(15),
                            onItemClick = onMediaClick
                        )
                    }
                }
            }
        }
    }
}

// ==========================================
// CONTENT ROW COMPONENTS
// ==========================================

@Composable
private fun ContentRow(
    title: String,
    items: List<MediaItem>,
    onItemClick: (String) -> Unit,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    iconColor: Color = OpenFlixColors.Primary,
    showProgress: Boolean = false,
    showNewBadge: Boolean = false
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp)
            .focusGroup()
    ) {
        // Section header
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            icon?.let {
                Icon(
                    imageVector = it,
                    contentDescription = null,
                    tint = iconColor,
                    modifier = Modifier.size(24.dp)
                )
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(items) { item ->
                MediaCard(
                    item = item,
                    onClick = { onItemClick(item.id) },
                    showProgress = showProgress,
                    showNewBadge = showNewBadge
                )
            }
        }
    }
}

// ==========================================
// STREAMING SERVICE ROW
// ==========================================

@Composable
private fun StreamingServiceRow(
    serviceName: String,
    items: List<MediaItem>,
    onItemClick: (String) -> Unit
) {
    // Service-specific branding colors
    val (serviceColor, serviceLogo) = remember(serviceName) {
        when {
            serviceName.contains("Netflix", ignoreCase = true) -> Color(0xFFE50914) to "N"
            serviceName.contains("Disney", ignoreCase = true) -> Color(0xFF113CCF) to "D+"
            serviceName.contains("HBO", ignoreCase = true) || serviceName.contains("Max", ignoreCase = true) -> Color(0xFF5822B4) to "MAX"
            serviceName.contains("Prime", ignoreCase = true) || serviceName.contains("Amazon", ignoreCase = true) -> Color(0xFF00A8E1) to "P"
            serviceName.contains("Apple", ignoreCase = true) -> Color(0xFF000000) to "tv+"
            serviceName.contains("Hulu", ignoreCase = true) -> Color(0xFF1CE783) to "H"
            serviceName.contains("Paramount", ignoreCase = true) -> Color(0xFF0064FF) to "P+"
            serviceName.contains("Peacock", ignoreCase = true) -> Color(0xFF000000) to "NBC"
            else -> OpenFlixColors.Primary to serviceName.take(2).uppercase()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp)
            .focusGroup()
    ) {
        // Section header with service branding
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Service badge/logo
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .background(serviceColor, RoundedCornerShape(6.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = serviceLogo,
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    fontSize = if (serviceLogo.length > 2) 8.sp else 12.sp
                )
            }

            Text(
                text = serviceName,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(items) { item ->
                StreamingServiceCard(
                    item = item,
                    serviceColor = serviceColor,
                    onClick = { onItemClick(item.id) }
                )
            }
        }
    }
}

@Composable
private fun StreamingServiceCard(
    item: MediaItem,
    serviceColor: Color,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(180.dp)
            .height(270.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color(0xFF1A1A1A),
            focusedContainerColor = Color(0xFF2A2A2A)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, serviceColor),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = serviceColor.copy(alpha = 0.4f),
                elevation = 20.dp
            )
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Poster
            AsyncImage(
                model = item.thumb,
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
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
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            )

            // Title and year
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp)
            ) {
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                item.year?.let { year ->
                    Text(
                        text = year.toString(),
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

@Composable
private fun MediaCard(
    item: MediaItem,
    onClick: () -> Unit,
    showProgress: Boolean = false,
    showNewBadge: Boolean = false
) {
    var isFocused by remember { mutableStateOf(false) }

    val progress = if (showProgress && (item.viewOffset ?: 0) > 0 && (item.duration ?: 0) > 0) {
        (item.viewOffset!!.toFloat() / item.duration!!).coerceIn(0f, 1f)
    } else 0f

    val isNew = showNewBadge && item.addedAt?.let {
        val daysSince = (System.currentTimeMillis() - it * 1000L) / (1000 * 60 * 60 * 24)
        daysSince <= 14
    } ?: false

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(180.dp)
            .height(270.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color(0xFF1A1A1A),
            focusedContainerColor = Color(0xFF2A2A2A)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, Color.White),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = Color.White.copy(alpha = 0.3f),
                elevation = 20.dp
            )
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Poster
            AsyncImage(
                model = item.thumb,
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
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
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            )

            // NEW badge
            if (isNew) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(8.dp)
                        .background(Color(0xFF00E676), RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "NEW",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }

            // Progress bar
            if (showProgress && progress > 0f) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .padding(8.dp)
                ) {
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
                                .background(OpenFlixColors.Primary, RoundedCornerShape(2.dp))
                        )
                    }
                }
            }

            // Title and year
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp)
            ) {
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                item.year?.let { year ->
                    Text(
                        text = year.toString(),
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

// ==========================================
// LIVE NOW ROW
// ==========================================

@Composable
private fun LiveNowRow(
    channels: List<Channel>,
    onChannelClick: (Channel) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp)
            .focusGroup()
    ) {
        // Section header
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Pulsing live dot
            val infiniteTransition = rememberInfiniteTransition(label = "live_pulse")
            val alpha by infiniteTransition.animateFloat(
                initialValue = 1f,
                targetValue = 0.3f,
                animationSpec = infiniteRepeatable(
                    animation = tween(1000),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "pulse"
            )

            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(Color.Red.copy(alpha = alpha), CircleShape)
            )

            Text(
                text = "Live Now",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

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
            .height(160.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color(0xFF1A1A1A),
            focusedContainerColor = Color(0xFF2A2A2A)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, Color.Red),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = Color.Red.copy(alpha = 0.4f),
                elevation = 16.dp
            )
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Channel thumbnail or program image
            AsyncImage(
                model = channel.nowPlaying?.thumb ?: channel.nowPlaying?.art ?: channel.logoUrl,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )

            // Gradient
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.9f)
                            )
                        )
                    )
            )

            // LIVE badge
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(12.dp)
                    .background(Color.Red, RoundedCornerShape(4.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "LIVE",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            // Channel logo
            channel.logoUrl?.let { logoUrl ->
                AsyncImage(
                    model = logoUrl,
                    contentDescription = null,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(12.dp)
                        .height(24.dp)
                        .widthIn(max = 60.dp),
                    contentScale = ContentScale.Fit
                )
            }

            // Program info
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp)
            ) {
                Text(
                    text = channel.nowPlaying?.title ?: channel.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                channel.nowPlaying?.let { program ->
                    // Time remaining
                    val remaining = ((program.endTime - System.currentTimeMillis() / 1000) / 60).toInt()
                    if (remaining > 0) {
                        Text(
                            text = "${remaining}m left",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                    }

                    // Progress bar
                    program.progress?.let { progress ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(3.dp)
                                .clip(RoundedCornerShape(1.5.dp))
                                .background(Color.White.copy(alpha = 0.3f))
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(progress)
                                    .fillMaxHeight()
                                    .background(Color.Red, RoundedCornerShape(1.5.dp))
                            )
                        }
                    }
                }
            }
        }
    }
}

// ==========================================
// TOP 10 ROW
// ==========================================

@Composable
private fun Top10Row(
    items: List<MediaItem>,
    onItemClick: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp)
            .focusGroup()
    ) {
        // Section header
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.EmojiEvents,
                contentDescription = null,
                tint = Color(0xFFFFD700),
                modifier = Modifier.size(28.dp)
            )
            Text(
                text = "Top 10 Today",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        TvLazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            itemsIndexed(items.take(10)) { index, item ->
                Top10Card(
                    rank = index + 1,
                    item = item,
                    onClick = { onItemClick(item.id) }
                )
            }
        }
    }
}

@Composable
private fun Top10Card(
    rank: Int,
    item: MediaItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier.height(200.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        // Large ranking number with stroke effect
        Box(
            modifier = Modifier
                .width(70.dp)
                .height(180.dp),
            contentAlignment = Alignment.CenterEnd
        ) {
            Text(
                text = rank.toString(),
                style = MaterialTheme.typography.displayLarge.copy(
                    fontSize = if (rank < 10) 140.sp else 100.sp,
                    fontWeight = FontWeight.Black
                ),
                color = Color(0xFF1A1A1A),
                modifier = Modifier.offset(x = 20.dp)
            )
        }

        // Poster card
        Surface(
            onClick = onClick,
            modifier = Modifier
                .width(130.dp)
                .height(195.dp)
                .offset(x = (-20).dp)
                .onFocusChanged { isFocused = it.isFocused },
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = Color(0xFF1A1A1A),
                focusedContainerColor = Color(0xFF2A2A2A)
            ),
            border = ClickableSurfaceDefaults.border(
                focusedBorder = Border(
                    border = BorderStroke(2.dp, Color(0xFFFFD700)),
                    shape = RoundedCornerShape(8.dp)
                )
            ),
            scale = ClickableSurfaceDefaults.scale(focusedScale = 1.08f),
            glow = ClickableSurfaceDefaults.glow(
                focusedGlow = Glow(
                    elevationColor = Color(0xFFFFD700).copy(alpha = 0.4f),
                    elevation = 20.dp
                )
            )
        ) {
            AsyncImage(
                model = item.thumb,
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        }
    }
}

// ==========================================
// FEELING LUCKY ROW
// ==========================================

@Composable
private fun FeelingLuckyRow(
    items: List<MediaItem>,
    onItemClick: (String) -> Unit,
    onPlayClick: (String) -> Unit
) {
    var isSpinning by remember { mutableStateOf(false) }
    var selectedItem by remember { mutableStateOf<MediaItem?>(null) }
    var displayIndex by remember { mutableIntStateOf(0) }

    // Spinning animation
    LaunchedEffect(isSpinning) {
        if (isSpinning && items.isNotEmpty()) {
            var spinCount = 0
            val totalSpins = 25
            while (spinCount < totalSpins) {
                displayIndex = Random.nextInt(items.size)
                val delayMs = (50 + spinCount * 15).toLong().coerceAtMost(300)
                delay(delayMs)
                spinCount++
            }
            val finalIndex = Random.nextInt(items.size)
            displayIndex = finalIndex
            selectedItem = items[finalIndex]
            isSpinning = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp, bottom = 16.dp)
            .focusGroup()
    ) {
        // Section header
        Row(
            modifier = Modifier.padding(horizontal = 48.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Casino,
                contentDescription = null,
                tint = OpenFlixColors.Primary,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = "Feeling Lucky?",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(24.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Shuffle button
            Surface(
                onClick = { isSpinning = true },
                modifier = Modifier.size(120.dp),
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Primary,
                    focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.8f)
                ),
                scale = ClickableSurfaceDefaults.scale(focusedScale = 1.08f),
                glow = ClickableSurfaceDefaults.glow(
                    focusedGlow = Glow(
                        elevationColor = OpenFlixColors.Primary.copy(alpha = 0.6f),
                        elevation = 24.dp
                    )
                )
            ) {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    val infiniteTransition = rememberInfiniteTransition(label = "shuffle")
                    val rotation by infiniteTransition.animateFloat(
                        initialValue = 0f,
                        targetValue = if (isSpinning) 360f else 0f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(500, easing = LinearEasing),
                            repeatMode = RepeatMode.Restart
                        ),
                        label = "rotation"
                    )

                    Icon(
                        imageVector = Icons.Filled.Casino,
                        contentDescription = "Shuffle",
                        tint = Color.White,
                        modifier = Modifier
                            .size(48.dp)
                            .graphicsLayer { rotationZ = if (isSpinning) rotation else 0f }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = if (isSpinning) "Spinning..." else "Surprise Me!",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        textAlign = TextAlign.Center
                    )
                }
            }

            // Preview card
            if (items.isNotEmpty()) {
                val displayItem = if (isSpinning) items.getOrNull(displayIndex) else selectedItem

                AnimatedContent(
                    targetState = displayItem,
                    transitionSpec = {
                        fadeIn(animationSpec = tween(100)) togetherWith
                                fadeOut(animationSpec = tween(100))
                    },
                    label = "random_picker"
                ) { item ->
                    if (item != null) {
                        Surface(
                            onClick = { if (!isSpinning) onItemClick(item.id) },
                            modifier = Modifier
                                .width(220.dp)
                                .height(120.dp),
                            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                            colors = ClickableSurfaceDefaults.colors(
                                containerColor = Color(0xFF1A1A1A),
                                focusedContainerColor = Color(0xFF2A2A2A)
                            ),
                            border = ClickableSurfaceDefaults.border(
                                focusedBorder = Border(
                                    border = BorderStroke(2.dp, OpenFlixColors.Primary),
                                    shape = RoundedCornerShape(12.dp)
                                )
                            ),
                            scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
                        ) {
                            Box(modifier = Modifier.fillMaxSize()) {
                                AsyncImage(
                                    model = item.art ?: item.thumb,
                                    contentDescription = null,
                                    modifier = Modifier.fillMaxSize(),
                                    contentScale = ContentScale.Crop
                                )
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
                                Text(
                                    text = item.title,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier
                                        .align(Alignment.BottomStart)
                                        .padding(12.dp)
                                )
                            }
                        }
                    } else {
                        Box(
                            modifier = Modifier
                                .width(220.dp)
                                .height(120.dp)
                                .background(Color(0xFF1A1A1A), RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Press to shuffle!",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.5f)
                            )
                        }
                    }
                }
            }

            // Play button
            AnimatedVisibility(
                visible = selectedItem != null && !isSpinning,
                enter = fadeIn() + scaleIn(),
                exit = fadeOut() + scaleOut()
            ) {
                Surface(
                    onClick = { selectedItem?.let { onPlayClick(it.id) } },
                    modifier = Modifier.size(56.dp),
                    shape = ClickableSurfaceDefaults.shape(CircleShape),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = Color.White,
                        focusedContainerColor = Color.White.copy(alpha = 0.9f)
                    ),
                    scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
                ) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Filled.PlayArrow,
                            contentDescription = "Play",
                            tint = Color.Black,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
            }
        }
    }
}

// Helper extension for border
@Composable
private fun Modifier.border(width: androidx.compose.ui.unit.Dp, color: Color, shape: androidx.compose.ui.graphics.Shape) =
    this.then(
        Modifier.background(Color.Transparent, shape)
            .padding(width)
            .background(Color.Transparent, shape)
    )
