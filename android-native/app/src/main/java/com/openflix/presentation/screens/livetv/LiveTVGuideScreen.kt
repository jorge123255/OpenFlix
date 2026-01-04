package com.openflix.presentation.screens.livetv

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import androidx.compose.ui.viewinterop.AndroidView
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.player.LiveTVPlayer
import com.openflix.player.StreamInfo
import com.openflix.presentation.components.livetv.LiveTVPlayerControls
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.*

// Premium dark theme with glassmorphism colors
private object Theme {
    val Background = Color(0xFF050508)
    val Surface = Color(0xFF0D0D12)
    val SurfaceElevated = Color(0xFF16161D)
    val SurfaceHighlight = Color(0xFF22222D)
    val Glass = Color(0xFF1A1A24)
    val GlassBorder = Color(0xFF2A2A38)

    val Accent = Color(0xFF00D4AA)
    val AccentGlow = Color(0xFF00FFD4)
    val AccentRed = Color(0xFFFF3B5C)
    val AccentBlue = Color(0xFF3B82F6)
    val AccentGold = Color(0xFFFFB800)

    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0C0)
    val TextMuted = Color(0xFF606078)

    // Category colors - vibrant gradients
    val Sports = Color(0xFF10B981)
    val SportsGlow = Color(0xFF34D399)
    val Movie = Color(0xFFEF4444)
    val MovieGlow = Color(0xFFF87171)
    val News = Color(0xFF3B82F6)
    val NewsGlow = Color(0xFF60A5FA)
    val Kids = Color(0xFFF59E0B)
    val KidsGlow = Color(0xFFFBBF24)
    val Entertainment = Color(0xFF8B5CF6)
    val EntertainmentGlow = Color(0xFFA78BFA)
}

// Category filter options - FuboTV style
private enum class Category(val label: String, val icon: ImageVector?, val color: Color) {
    ALL("All", Icons.Default.Check, Theme.Accent),
    FAVORITES("Favorites", Icons.Default.Star, Theme.AccentGold),
    RECOMMENDED("Recommended", null, Theme.Entertainment),
    TRENDING("Trending", Icons.Default.TrendingUp, Theme.AccentRed),
    LIVE_SPORTS("Live Sports", Icons.Default.SportsSoccer, Theme.Sports),
    MOVIES("Movies", Icons.Default.Movie, Theme.Movie),
    NEWS("News", Icons.Default.Newspaper, Theme.News),
    KIDS("Kids", Icons.Default.ChildCare, Theme.Kids),
    JUST_ADDED("Just Added", Icons.Default.NewReleases, Theme.AccentBlue)
}

@Composable
fun LiveTVGuideScreen(
    onBack: () -> Unit,
    onChannelSelected: (String) -> Unit,
    liveTVPlayer: LiveTVPlayer,
    onFullscreenChanged: (Boolean) -> Unit = {},
    onNavigateToMultiview: () -> Unit = {},
    viewModel: LiveTVGuideViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()

    var selectedChannel by remember { mutableStateOf<ChannelWithPrograms?>(null) }
    var selectedProgram by remember { mutableStateOf<Program?>(null) }
    var selectedCategory by remember { mutableStateOf(Category.ALL) }

    // Use the shared LiveTVPlayer (ExoPlayer) - same player for preview and fullscreen
    val isPlaying by liveTVPlayer.isPlaying.collectAsState()
    val isBuffering by liveTVPlayer.isBuffering.collectAsState()
    val isMuted by liveTVPlayer.isMuted.collectAsState()
    val isPaused by liveTVPlayer.isPaused.collectAsState()
    val currentUrl by liveTVPlayer.currentUrl.collectAsState()
    var currentChannelId by remember { mutableStateOf<String?>(null) }

    // Fullscreen mode state - same player, just expanded
    var isFullscreen by remember { mutableStateOf(false) }
    var showFullscreenControls by remember { mutableStateOf(true) }
    var showProgramInfo by remember { mutableStateOf(false) }

    // Initialize player when screen appears
    LaunchedEffect(Unit) {
        liveTVPlayer.initialize()
    }

    // Debounce channel selection for preview (wait 1.5s before playing, unless fullscreen)
    LaunchedEffect(selectedChannel?.channel?.id, isFullscreen) {
        val channelId = selectedChannel?.channel?.id
        val streamUrl = selectedChannel?.channel?.streamUrl

        if (channelId != null && streamUrl != null && channelId != currentChannelId) {
            // In fullscreen, play immediately. In guide preview, wait 1.5s
            if (!isFullscreen) delay(1500)
            if (selectedChannel?.channel?.id == channelId) {
                currentChannelId = channelId
                liveTVPlayer.play(streamUrl)
            }
        }
    }

    // Auto-hide fullscreen controls
    LaunchedEffect(showFullscreenControls, isFullscreen) {
        if (isFullscreen && showFullscreenControls) {
            delay(5000)
            showFullscreenControls = false
        }
    }

    // Mute/unmute when entering/exiting fullscreen + notify parent
    LaunchedEffect(isFullscreen) {
        liveTVPlayer.setMuted(!isFullscreen)
        onFullscreenChanged(isFullscreen)
    }

    // Focus management for D-pad navigation
    val categoryTabsFocusRequester = remember { FocusRequester() }
    val guideFocusRequester = remember { FocusRequester() }

    val pixelsPerMinute = 5.dp  // Slightly larger cells
    val slotMinutes = 30
    val totalHours = 3

    val now = remember { System.currentTimeMillis() / 1000 }
    val startTime = remember { (now / 1800) * 1800 }
    val endTime = startTime + (totalHours * 3600)

    val timeSlots = remember(startTime) {
        (0 until totalHours * 2).map { startTime + (it * slotMinutes * 60) }
    }

    val nowOffset = remember(now, startTime) {
        ((now - startTime) / 60f) * pixelsPerMinute.value
    }

    val channelWidth = 220.dp

    // Filter channels by category
    val filteredGuide = remember(uiState.guide, selectedCategory) {
        when (selectedCategory) {
            Category.ALL -> uiState.guide
            Category.FAVORITES -> uiState.guide.filter { it.channel.favorite }
            Category.RECOMMENDED -> uiState.guide.filter { cwp ->
                // Show channels with current airing content that has good metadata
                cwp.programs.any { it.isAiring && (it.thumb != null || it.art != null) }
            }
            Category.TRENDING -> uiState.guide.filter { cwp ->
                // Show channels with live or new content
                cwp.programs.any { it.isAiring && (it.isLive || it.isNew || it.isPremiere) }
            }
            Category.LIVE_SPORTS -> uiState.guide.filter { cwp ->
                cwp.programs.any { it.isSports && it.isAiring } ||
                cwp.channel.category?.contains("sports", true) == true
            }
            Category.MOVIES -> uiState.guide.filter { cwp ->
                cwp.programs.any { it.isMovie } || cwp.channel.category?.contains("movie", true) == true
            }
            Category.NEWS -> uiState.guide.filter { cwp ->
                cwp.channel.category?.contains("news", true) == true ||
                cwp.channel.name.contains("news", true) ||
                cwp.channel.name.contains("cnn", true) ||
                cwp.channel.name.contains("msnbc", true) ||
                cwp.channel.name.contains("fox news", true)
            }
            Category.KIDS -> uiState.guide.filter { cwp ->
                cwp.programs.any { it.isKids } ||
                cwp.channel.category?.contains("kids", true) == true ||
                cwp.channel.name.contains("disney", true) ||
                cwp.channel.name.contains("nick", true) ||
                cwp.channel.name.contains("cartoon", true)
            }
            Category.JUST_ADDED -> uiState.guide.filter { cwp ->
                cwp.programs.any { it.isNew || it.isPremiere }
            }
        }
    }

    LaunchedEffect(Unit) { viewModel.loadGuide(startTime, endTime) }

    LaunchedEffect(filteredGuide) {
        if (selectedChannel == null && filteredGuide.isNotEmpty()) {
            selectedChannel = filteredGuide.first()
            selectedProgram = selectedChannel?.programs?.find { it.isAiring }
        }
    }

    // Handle channel selection - expand to fullscreen using SAME ExoPlayer instance (like Tivimate)
    val handleChannelSelect: (ChannelWithPrograms) -> Unit = { cwp ->
        selectedChannel = cwp
        selectedProgram = cwp.programs.find { it.isAiring }

        // If this channel is already playing, just go fullscreen (instant, no reload!)
        if (currentChannelId == cwp.channel.id && isPlaying) {
            isFullscreen = true
            showFullscreenControls = true
        } else {
            // Start playing this channel and go fullscreen
            currentChannelId = cwp.channel.id
            cwp.channel.streamUrl?.let { url ->
                liveTVPlayer.play(url)
            }
            isFullscreen = true
            showFullscreenControls = true
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Theme.Background)
            .onKeyEvent { e ->
                if (e.type == KeyEventType.KeyDown) {
                    when (e.key) {
                        Key.Back, Key.Escape -> {
                            if (isFullscreen && showFullscreenControls) {
                                // First, hide controls
                                showFullscreenControls = false
                                true
                            } else if (isFullscreen) {
                                // Controls hidden, exit fullscreen
                                isFullscreen = false
                                true
                            } else {
                                onBack()
                                true
                            }
                        }
                        // In fullscreen: D-pad for channel surfing (only when controls are hidden)
                        Key.DirectionUp -> {
                            if (isFullscreen && !showFullscreenControls) {
                                // Controls hidden - switch channel
                                val currentIndex = filteredGuide.indexOfFirst { it.channel.id == selectedChannel?.channel?.id }
                                if (currentIndex > 0) {
                                    val newChannel = filteredGuide[currentIndex - 1]
                                    selectedChannel = newChannel
                                    selectedProgram = newChannel.programs.find { it.isAiring }
                                    currentChannelId = newChannel.channel.id
                                    newChannel.channel.streamUrl?.let { liveTVPlayer.play(it) }
                                    showFullscreenControls = true
                                }
                                true
                            } else false // Let Compose handle focus navigation when controls visible
                        }
                        Key.DirectionDown -> {
                            if (isFullscreen && !showFullscreenControls) {
                                // Controls hidden - switch channel
                                val currentIndex = filteredGuide.indexOfFirst { it.channel.id == selectedChannel?.channel?.id }
                                if (currentIndex >= 0 && currentIndex < filteredGuide.size - 1) {
                                    val newChannel = filteredGuide[currentIndex + 1]
                                    selectedChannel = newChannel
                                    selectedProgram = newChannel.programs.find { it.isAiring }
                                    currentChannelId = newChannel.channel.id
                                    newChannel.channel.streamUrl?.let { liveTVPlayer.play(it) }
                                    showFullscreenControls = true
                                }
                                true
                            } else false // Let Compose handle focus navigation when controls visible
                        }
                        Key.DirectionCenter, Key.Enter -> {
                            if (isFullscreen && !showFullscreenControls) {
                                // Show controls when hidden
                                showFullscreenControls = true
                                true
                            } else if (!isFullscreen) {
                                // Not in fullscreen - let the guide handle it
                                false
                            } else {
                                // Controls are showing - let buttons handle Enter
                                false
                            }
                        }
                        // Mute toggle
                        Key.VolumeMute -> {
                            if (isFullscreen) {
                                liveTVPlayer.toggleMute()
                                showFullscreenControls = true
                                true
                            } else false
                        }
                        // Menu button - show guide overlay while playing
                        Key.Menu -> {
                            if (isFullscreen) {
                                isFullscreen = false
                                true
                            } else false
                        }
                        else -> false
                    }
                } else false
            }
    ) {
        // SINGLE video surface - used for both preview and fullscreen (like Tivimate)
        // ExoPlayer PlayerView that can switch surfaces seamlessly
        if (isFullscreen) {
            // Fullscreen video surface using ExoPlayer's PlayerView
            AndroidView(
                factory = { ctx ->
                    androidx.media3.ui.PlayerView(ctx).apply {
                        useController = false  // We use our own controls
                        liveTVPlayer.getPlayer()?.let { player = it }
                    }
                },
                update = { playerView ->
                    liveTVPlayer.getPlayer()?.let { playerView.player = it }
                },
                modifier = Modifier.fillMaxSize()
            )
        }

        // Guide UI - visible when not fullscreen
        AnimatedVisibility(
            visible = !isFullscreen,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Column(Modifier.fillMaxSize()) {
                // Top section: Video preview + Info panel
                TopInfoSection(
                    channel = selectedChannel?.channel,
                    program = selectedProgram,
                    liveTVPlayer = liveTVPlayer,
                    isPlaying = isPlaying,
                    isMuted = isMuted,
                    onMuteToggle = { liveTVPlayer.toggleMute() }
                )

                // Category filter tabs
                CategoryTabs(
                    selected = selectedCategory,
                    onSelect = { selectedCategory = it },
                    focusRequester = categoryTabsFocusRequester,
                    onDownPressed = { guideFocusRequester.requestFocus() }
                )

                // Time header with scrubbing
                TimeHeader(
                    slots = timeSlots,
                    channelWidth = channelWidth,
                    pxPerMin = pixelsPerMinute,
                    slotMins = slotMinutes,
                    now = now,
                    onShiftTime = { mins -> viewModel.shiftTime(mins) }
                )

                // Grid
                when {
                    uiState.isLoading -> LoadingView()
                    uiState.error != null -> ErrorView(uiState.error!!) { viewModel.loadGuide(startTime, endTime) }
                    filteredGuide.isEmpty() -> EmptyView(selectedCategory != Category.ALL)
                    else -> {
                        val displayed = remember(filteredGuide, uiState.displayedCount) {
                            filteredGuide.take(uiState.displayedCount)
                        }

                        Box(Modifier.weight(1f)) {
                            LazyColumn(
                                state = listState,
                                modifier = Modifier
                                    .fillMaxSize()
                                    .focusRequester(guideFocusRequester)
                                    .focusProperties {
                                        up = categoryTabsFocusRequester
                                    }
                            ) {
                                itemsIndexed(displayed, key = { _, cwp -> cwp.channel.id }) { index, cwp ->
                                    GuideRow(
                                        data = cwp,
                                        startTime = startTime,
                                        endTime = endTime,
                                        pxPerMin = pixelsPerMinute,
                                        channelWidth = channelWidth,
                                        now = now,
                                        isSelected = selectedChannel?.channel?.id == cwp.channel.id,
                                        isFirstRow = index == 0,
                                        onUpPressed = { categoryTabsFocusRequester.requestFocus() },
                                        onChannelFocus = {
                                            selectedChannel = cwp
                                            selectedProgram = cwp.programs.find { it.isAiring }
                                        },
                                        onProgramFocus = { p -> selectedChannel = cwp; selectedProgram = p },
                                        onSelect = { handleChannelSelect(cwp) }
                                    )
                                }

                                if (uiState.displayedCount < filteredGuide.size) {
                                    item {
                                        LaunchedEffect(Unit) { viewModel.loadMoreChannels() }
                                        Box(Modifier.fillMaxWidth().height(60.dp), Alignment.Center) {
                                            PulsingDots()
                                        }
                                    }
                                }
                            }

                            // Now line with glow effect
                            if (nowOffset > 0 && nowOffset < (totalHours * 60 * pixelsPerMinute.value)) {
                                Box(
                                    Modifier
                                        .offset(x = channelWidth + nowOffset.dp)
                                        .width(3.dp)
                                        .fillMaxHeight()
                                        .background(
                                            Brush.verticalGradient(
                                                listOf(
                                                    Theme.AccentRed,
                                                    Theme.AccentRed.copy(0.8f),
                                                    Theme.AccentRed.copy(0.4f),
                                                    Theme.AccentRed.copy(0.1f)
                                                )
                                            )
                                        )
                                )
                                // Glow
                                Box(
                                    Modifier
                                        .offset(x = channelWidth + nowOffset.dp - 4.dp)
                                        .width(10.dp)
                                        .fillMaxHeight()
                                        .background(
                                            Brush.horizontalGradient(
                                                listOf(
                                                    Color.Transparent,
                                                    Theme.AccentRed.copy(0.15f),
                                                    Color.Transparent
                                                )
                                            )
                                        )
                                )
                            }
                        }
                    }
                }
            }
        }

        // Fullscreen controls overlay (video is rendered separately above)
        // Fullscreen player controls overlay
        AnimatedVisibility(
            visible = isFullscreen && showFullscreenControls && selectedChannel != null,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it }
        ) {
            selectedChannel?.channel?.let { channel ->
                LiveTVPlayerControls(
                    channel = channel,
                    allChannels = filteredGuide.map { it.channel },
                    isFavorite = false, // TODO: favorites from ViewModel
                    isMuted = isMuted,
                    isLive = true,
                    isPaused = liveTVPlayer.isPaused.collectAsState().value,
                    timeShiftOffset = "",
                    isStartOverAvailable = false,
                    onShowEPG = { /* Already in guide */ },
                    onShowMultiview = onNavigateToMultiview,
                    onShowMiniGuide = { isFullscreen = false }, // Back to guide
                    onShowInfo = { showProgramInfo = true },
                    onToggleFavorite = { /* TODO */ },
                    onToggleMute = { liveTVPlayer.toggleMute() },
                    onShowAudioTracks = { /* TODO */ },
                    onShowSubtitles = { /* TODO */ },
                    onQuickRecord = { /* TODO */ },
                    onChannelSelected = { selectedCh ->
                        // Find the channel in guide and switch to it
                        val cwp = filteredGuide.find { it.channel.id == selectedCh.id }
                        if (cwp != null) {
                            selectedChannel = cwp
                            selectedProgram = cwp.programs.find { it.isAiring }
                            currentChannelId = cwp.channel.id
                            cwp.channel.streamUrl?.let { liveTVPlayer.play(it) }
                        }
                    },
                    onTogglePause = { liveTVPlayer.togglePlayPause() },
                    onSeekBack = { liveTVPlayer.seekBack10() },
                    onSeekForward = { liveTVPlayer.seekForward10() },
                    onGoLive = { liveTVPlayer.goLive() },
                    onStartOver = { /* TODO */ }
                )
            }
        }

        // Tap anywhere to toggle controls when fullscreen
        if (isFullscreen && !showFullscreenControls) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable { showFullscreenControls = true }
            )
        }

        // Loading indicator for fullscreen
        if (isFullscreen && !isPlaying) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                PulsingDots()
            }
        }

        // Program Info Dialog
        if (showProgramInfo && selectedProgram != null) {
            val streamInfo by liveTVPlayer.streamInfo.collectAsState()
            ProgramInfoDialog(
                program = selectedProgram!!,
                channel = selectedChannel?.channel,
                streamInfo = streamInfo,
                onDismiss = { showProgramInfo = false }
            )
        }
    }
}

@Composable
private fun ProgramInfoDialog(
    program: Program,
    channel: Channel?,
    streamInfo: StreamInfo?,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .clickable { onDismiss() },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.7f)
                .padding(24.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(Theme.Surface)
                .clickable { /* Prevent click through */ }
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
            ) {
                // Header with channel info
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    channel?.logoUrl?.let { logoUrl ->
                        AsyncImage(
                            model = logoUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(48.dp)
                                .clip(RoundedCornerShape(8.dp))
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Column {
                        Text(
                            text = channel?.name ?: "",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.White
                        )
                        channel?.number?.let {
                            Text(
                                text = "Channel $it",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.7f)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Program title
                Text(
                    text = program.title,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Time info
                val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                val dateFormat = SimpleDateFormat("EEE, MMM d", Locale.getDefault())
                Text(
                    text = "${dateFormat.format(Date(program.startTime * 1000))} • ${timeFormat.format(Date(program.startTime * 1000))} - ${timeFormat.format(Date(program.endTime * 1000))}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Theme.AccentBlue
                )

                // Duration
                val durationMinutes = ((program.endTime - program.startTime) / 60).toInt()
                Text(
                    text = "${durationMinutes} min",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f)
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Description
                val description = program.description
                if (!description.isNullOrBlank()) {
                    Text(
                        text = description,
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color.White.copy(alpha = 0.9f),
                        maxLines = 4,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Stream Info Section
                if (streamInfo != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Theme.SurfaceElevated)
                            .padding(16.dp)
                    ) {
                        Column {
                            Text(
                                text = "STREAM INFO",
                                style = MaterialTheme.typography.labelMedium,
                                color = Theme.Accent,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                // Video Info Column
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "VIDEO",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White.copy(alpha = 0.5f)
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))

                                    // Resolution badge
                                    streamInfo.resolutionLabel?.let { label ->
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Box(
                                                modifier = Modifier
                                                    .clip(RoundedCornerShape(4.dp))
                                                    .background(
                                                        when (label) {
                                                            "4K" -> Theme.AccentGold
                                                            "1080p" -> Theme.AccentBlue
                                                            else -> Theme.TextMuted
                                                        }
                                                    )
                                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                                            ) {
                                                Text(
                                                    text = label,
                                                    style = MaterialTheme.typography.labelSmall,
                                                    fontWeight = FontWeight.Bold,
                                                    color = Color.White
                                                )
                                            }
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(
                                                text = streamInfo.resolution ?: "",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = Color.White.copy(alpha = 0.7f)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))
                                    streamInfo.videoCodec?.let {
                                        Text(
                                            text = "Codec: ${it.uppercase()}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                    streamInfo.videoFrameRate?.let {
                                        Text(
                                            text = "Frame Rate: ${String.format("%.2f", it)} fps",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                    streamInfo.videoBitrateLabel?.let {
                                        Text(
                                            text = "Bitrate: $it",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                }

                                // Audio Info Column
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "AUDIO",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White.copy(alpha = 0.5f)
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))

                                    streamInfo.audioChannelsLabel?.let { label ->
                                        Box(
                                            modifier = Modifier
                                                .clip(RoundedCornerShape(4.dp))
                                                .background(Theme.Entertainment)
                                                .padding(horizontal = 6.dp, vertical = 2.dp)
                                        ) {
                                            Text(
                                                text = label,
                                                style = MaterialTheme.typography.labelSmall,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))
                                    streamInfo.audioCodec?.let {
                                        Text(
                                            text = "Codec: ${it.uppercase()}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                    streamInfo.audioSampleRate?.let {
                                        Text(
                                            text = "Sample Rate: ${it / 1000} kHz",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                    streamInfo.audioBitrateLabel?.let {
                                        Text(
                                            text = "Bitrate: $it",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Close hint
                Text(
                    text = "Press any key to close",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.5f),
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        }
    }
}

@Composable
private fun FullscreenControls(
    channel: Channel?,
    program: Program?,
    isPlaying: Boolean,
    isMuted: Boolean,
    showControls: Boolean,
    onToggleControls: () -> Unit,
    onMuteToggle: () -> Unit,
    onBack: () -> Unit
) {
    // This is just the controls overlay - video is rendered separately using ExoPlayer PlayerView
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable { onToggleControls() }
    ) {
        // Loading indicator
        if (!isPlaying) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                PulsingDots()
            }
        }

        // Controls overlay
        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(
                                Color.Black.copy(alpha = 0.7f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            ) {
                // Top bar - channel info
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Back button
                    Surface(
                        onClick = onBack,
                        modifier = Modifier.size(48.dp),
                        shape = ClickableSurfaceDefaults.shape(CircleShape),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Color.White.copy(alpha = 0.2f),
                            focusedContainerColor = Color.White.copy(alpha = 0.4f)
                        )
                    ) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                            Icon(
                                Icons.Default.ArrowBack,
                                contentDescription = "Back to Guide",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    // Channel logo
                    channel?.logoUrl?.let { logoUrl ->
                        AsyncImage(
                            model = logoUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(56.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.1f)),
                            contentScale = ContentScale.Fit
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                    }

                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            channel?.number?.let { num ->
                                Text(
                                    text = num,
                                    color = Color.White.copy(alpha = 0.7f),
                                    fontSize = 18.sp
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                            }
                            Text(
                                text = channel?.name ?: "",
                                color = Color.White,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        program?.let { prog ->
                            Text(
                                text = prog.title,
                                color = Color.White.copy(alpha = 0.8f),
                                fontSize = 16.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }

                    // LIVE badge
                    Box(
                        modifier = Modifier
                            .background(Theme.AccentRed, RoundedCornerShape(4.dp))
                            .padding(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = "LIVE",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // Bottom bar - controls
                Row(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Mute button
                    Surface(
                        onClick = onMuteToggle,
                        modifier = Modifier.size(48.dp),
                        shape = ClickableSurfaceDefaults.shape(CircleShape),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Color.White.copy(alpha = 0.2f),
                            focusedContainerColor = Color.White.copy(alpha = 0.4f)
                        )
                    ) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                            Icon(
                                if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
                                contentDescription = if (isMuted) "Unmute" else "Mute",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(24.dp))

                    // Control hints
                    Text(
                        text = "▲▼ Channels  •  ◀ Guide",
                        color = Color.White.copy(alpha = 0.5f),
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun TopInfoSection(
    channel: Channel?,
    program: Program?,
    liveTVPlayer: LiveTVPlayer,
    isPlaying: Boolean,
    isMuted: Boolean,
    onMuteToggle: () -> Unit
) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(180.dp)
    ) {
        // Background art with blur effect
        program?.art?.let { artUrl ->
            AsyncImage(
                model = artUrl,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer { alpha = 0.3f },
                contentScale = ContentScale.Crop
            )
        }

        // Glassmorphism overlay
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Theme.Glass.copy(0.95f),
                            Theme.Glass.copy(0.85f),
                            Theme.Background
                        )
                    )
                )
        )

        Row(
            Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Video Preview Panel
            Box(
                Modifier
                    .size(260.dp, 146.dp)  // 16:9 aspect ratio
                    .clip(RoundedCornerShape(12.dp))
                    .background(Theme.SurfaceElevated)
                    .border(2.dp, if (isPlaying) Theme.Accent else Theme.GlassBorder, RoundedCornerShape(12.dp)),
                Alignment.Center
            ) {
                if (isPlaying) {
                    // Live video preview using ExoPlayer PlayerView
                    AndroidView(
                        factory = { ctx ->
                            androidx.media3.ui.PlayerView(ctx).apply {
                                useController = false
                                liveTVPlayer.getPlayer()?.let { player = it }
                            }
                        },
                        update = { playerView ->
                            liveTVPlayer.getPlayer()?.let { playerView.player = it }
                        },
                        modifier = Modifier.fillMaxSize()
                    )

                    // Gradient overlay at bottom
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(40.dp)
                            .align(Alignment.BottomCenter)
                            .background(
                                Brush.verticalGradient(
                                    listOf(Color.Transparent, Color.Black.copy(0.7f))
                                )
                            )
                    )

                    // Mute button
                    Box(
                        Modifier
                            .align(Alignment.BottomEnd)
                            .padding(8.dp)
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(Color.Black.copy(0.6f))
                            .clickable { onMuteToggle() },
                        Alignment.Center
                    ) {
                        Icon(
                            if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
                            contentDescription = if (isMuted) "Unmute" else "Mute",
                            modifier = Modifier.size(18.dp),
                            tint = Color.White
                        )
                    }

                    // LIVE badge
                    Box(
                        Modifier
                            .align(Alignment.TopStart)
                            .padding(8.dp)
                    ) {
                        AnimatedLiveBadge()
                    }
                } else {
                    // Static image fallback
                    val imageUrl = program?.thumb ?: program?.art ?: channel?.logoUrl
                    if (imageUrl != null) {
                        AsyncImage(
                            model = imageUrl,
                            contentDescription = null,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Icon(Icons.Default.Tv, null, Modifier.size(48.dp), Theme.TextMuted)
                    }

                    // Loading indicator
                    if (channel != null) {
                        Box(
                            Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(0.4f)),
                            Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                PulsingDots()
                                Spacer(Modifier.height(8.dp))
                                Text("Loading preview...", color = Theme.TextMuted, fontSize = 11.sp)
                            }
                        }
                    }

                    // LIVE overlay for static image
                    if (program?.isAiring == true) {
                        Box(
                            Modifier
                                .align(Alignment.TopStart)
                                .padding(8.dp)
                        ) {
                            AnimatedLiveBadge()
                        }
                    }
                }
            }

            Spacer(Modifier.width(20.dp))

            // Channel & Program info
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    // Channel logo
                    channel?.logoUrl?.let {
                        Box(
                            Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Theme.SurfaceElevated),
                            Alignment.Center
                        ) {
                            AsyncImage(it, null, Modifier.size(28.dp))
                        }
                        Spacer(Modifier.width(12.dp))
                    }

                    channel?.number?.let {
                        Text(it, color = Theme.Accent, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.width(10.dp))
                    }

                    Text(
                        channel?.name ?: "Select a channel",
                        color = Theme.TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, false)
                    )

                    channel?.let { ch ->
                        Spacer(Modifier.width(12.dp))
                        if (ch.hd) {
                            GlowBadge("HD", Theme.AccentBlue)
                            Spacer(Modifier.width(8.dp))
                        }
                    }
                }

                program?.let { p ->
                    Spacer(Modifier.height(12.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CategoryChip(p)
                        Spacer(Modifier.width(10.dp))
                        Text(
                            p.title,
                            color = Theme.TextPrimary,
                            fontSize = 26.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f, false)
                        )
                    }

                    // Episode info
                    (p.episodeInfo ?: p.subtitle)?.let { info ->
                        Spacer(Modifier.height(4.dp))
                        Text(info, color = Theme.TextSecondary, fontSize = 14.sp, maxLines = 1)
                    }

                    // Time + Progress
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        val fmt = SimpleDateFormat("h:mm a", Locale.getDefault())
                        Text(
                            "${fmt.format(Date(p.startTime * 1000))} - ${fmt.format(Date(p.endTime * 1000))}",
                            color = Theme.TextSecondary,
                            fontSize = 13.sp
                        )

                        if (p.isAiring) {
                            Spacer(Modifier.width(16.dp))
                            Box(
                                Modifier
                                    .width(80.dp)
                                    .height(4.dp)
                                    .clip(RoundedCornerShape(2.dp))
                                    .background(Theme.SurfaceHighlight)
                            ) {
                                Box(
                                    Modifier
                                        .fillMaxHeight()
                                        .fillMaxWidth(p.progress)
                                        .background(
                                            Brush.horizontalGradient(
                                                listOf(Theme.AccentRed, Theme.AccentGold)
                                            )
                                        )
                                )
                            }
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "${(p.progress * 100).toInt()}%",
                                color = Theme.AccentGold,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            // Description
            program?.description?.let { desc ->
                Spacer(Modifier.width(24.dp))
                Box(
                    Modifier
                        .weight(0.6f)
                        .fillMaxHeight()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Theme.Glass.copy(0.5f))
                        .border(1.dp, Theme.GlassBorder.copy(0.3f), RoundedCornerShape(12.dp))
                        .padding(12.dp)
                ) {
                    Text(
                        desc,
                        color = Theme.TextSecondary,
                        fontSize = 13.sp,
                        maxLines = 5,
                        overflow = TextOverflow.Ellipsis,
                        lineHeight = 18.sp
                    )
                }
            }

        }
    }
}

@Composable
private fun CategoryTabs(
    selected: Category,
    onSelect: (Category) -> Unit,
    focusRequester: FocusRequester,
    onDownPressed: () -> Unit
) {
    // FuboTV-style scrollable filter tabs
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .background(Theme.Surface),
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        itemsIndexed(Category.values().toList(), key = { _, cat -> cat.name }) { index, cat ->
            val isSelected = selected == cat
            var isFocused by remember { mutableStateOf(false) }

            val bgColor by animateColorAsState(
                when {
                    isSelected -> Theme.SurfaceHighlight
                    isFocused -> Theme.SurfaceElevated
                    else -> Theme.Surface
                },
                tween(150), "tabBg"
            )

            Surface(
                onClick = { onSelect(cat) },
                modifier = Modifier
                    .then(if (index == 0) Modifier.focusRequester(focusRequester) else Modifier)
                    .onFocusChanged { isFocused = it.isFocused }
                    .onKeyEvent { e ->
                        if (e.type == KeyEventType.KeyDown && e.key == Key.DirectionDown) {
                            onDownPressed()
                            true
                        } else false
                    },
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(20.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = bgColor,
                    focusedContainerColor = Theme.SurfaceHighlight
                ),
                border = ClickableSurfaceDefaults.border(
                    border = if (isSelected) Border(border = BorderStroke(1.dp, Theme.TextMuted.copy(0.3f)), shape = RoundedCornerShape(20.dp)) else Border.None,
                    focusedBorder = Border(border = BorderStroke(2.dp, Theme.Accent), shape = RoundedCornerShape(20.dp))
                ),
                scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
            ) {
                Row(
                    Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Checkmark for selected "All" tab (FuboTV style)
                    if (cat == Category.ALL && isSelected) {
                        Icon(
                            Icons.Default.Check,
                            null,
                            Modifier.size(16.dp),
                            Theme.Accent
                        )
                        Spacer(Modifier.width(6.dp))
                    } else if (cat.icon != null) {
                        Icon(
                            cat.icon,
                            null,
                            Modifier.size(16.dp),
                            if (isSelected || isFocused) cat.color else Theme.TextMuted
                        )
                        Spacer(Modifier.width(6.dp))
                    }
                    Text(
                        cat.label,
                        color = if (isSelected) Theme.TextPrimary else Theme.TextSecondary,
                        fontSize = 14.sp,
                        fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
                    )
                }
            }
        }
    }
}

@Composable
private fun TimeHeader(
    slots: List<Long>,
    channelWidth: Dp,
    pxPerMin: Dp,
    slotMins: Int,
    now: Long,
    onShiftTime: (Int) -> Unit
) {
    val dayFmt = SimpleDateFormat("EEEE", Locale.getDefault())
    val isToday = remember(slots.firstOrNull()) {
        val cal = Calendar.getInstance()
        val today = cal.get(Calendar.DAY_OF_YEAR)
        cal.timeInMillis = (slots.firstOrNull() ?: 0) * 1000
        cal.get(Calendar.DAY_OF_YEAR) == today
    }

    Row(
        Modifier
            .fillMaxWidth()
            .height(44.dp)
            .background(Theme.SurfaceElevated)
    ) {
        // FuboTV-style "Today >" button
        Surface(
            onClick = { onShiftTime(-30) },
            modifier = Modifier.width(channelWidth).fillMaxHeight(),
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(0.dp)),
            colors = ClickableSurfaceDefaults.colors(Theme.Surface, focusedContainerColor = Theme.SurfaceHighlight)
        ) {
            Row(
                Modifier.fillMaxSize().padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Day indicator with arrow
                Text(
                    if (isToday) "Today" else dayFmt.format(Date((slots.firstOrNull() ?: 0) * 1000)),
                    color = Theme.TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                Spacer(Modifier.width(8.dp))
                Icon(
                    Icons.Default.ChevronRight,
                    null,
                    Modifier.size(18.dp),
                    Theme.TextMuted
                )
            }
        }

        Row(
            Modifier
                .weight(1f)
                .horizontalScroll(rememberScrollState())
        ) {
            val fmt = SimpleDateFormat("h:mma", Locale.getDefault())
            var isFirstSlot = true
            slots.forEach { ts ->
                val w = pxPerMin * slotMins
                val isCurrent = now in ts until (ts + slotMins * 60)

                Box(
                    Modifier
                        .width(w)
                        .fillMaxHeight()
                        .drawBehind {
                            drawLine(Theme.GlassBorder.copy(0.5f), Offset(0f, 0f), Offset(0f, size.height), 1f)
                        }
                        .background(Color.Transparent),
                    Alignment.CenterStart
                ) {
                    Column(Modifier.padding(start = 12.dp)) {
                        // FuboTV style: "Now Playing" for current, time for others
                        if (isCurrent && isFirstSlot) {
                            Text(
                                "Now Playing",
                                color = Theme.TextPrimary,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Medium
                            )
                        } else {
                            Text(
                                fmt.format(Date(ts * 1000)).lowercase(),
                                color = Theme.TextSecondary,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Normal
                            )
                        }
                    }
                }
                isFirstSlot = false
            }
        }
    }
}

@Composable
private fun GuideRow(
    data: ChannelWithPrograms,
    startTime: Long,
    endTime: Long,
    pxPerMin: Dp,
    channelWidth: Dp,
    now: Long,
    isSelected: Boolean,
    isFirstRow: Boolean = false,
    onUpPressed: () -> Unit = {},
    onChannelFocus: () -> Unit,
    onProgramFocus: (Program) -> Unit,
    onSelect: () -> Unit
) {
    val programs = remember(data.programs, startTime, endTime) {
        data.programs.filter { it.endTime > startTime && it.startTime < endTime }
    }

    Row(
        Modifier
            .fillMaxWidth()
            .height(88.dp)  // FuboTV-style row height
            .background(if (isSelected) Theme.Surface.copy(0.6f) else Color.Transparent)
    ) {
        // Find current airing program for thumbnail
        val currentProgram = remember(programs, now) {
            programs.find { now in it.startTime..it.endTime }
        }
        ChannelCell(
            ch = data.channel,
            currentProgram = currentProgram,
            width = channelWidth,
            isSelected = isSelected,
            isFirstRow = isFirstRow,
            onUpPressed = onUpPressed,
            onFocus = onChannelFocus,
            onClick = onSelect
        )

        Row(
            Modifier
                .weight(1f)
                .fillMaxHeight()
                .horizontalScroll(rememberScrollState())
        ) {
            if (programs.isEmpty()) {
                Box(
                    Modifier
                        .width(pxPerMin * ((endTime - startTime) / 60).toInt())
                        .fillMaxHeight()
                        .padding(3.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(
                            Brush.horizontalGradient(
                                listOf(Theme.Surface.copy(0.4f), Theme.Surface.copy(0.2f))
                            )
                        ),
                    Alignment.CenterStart
                ) {
                    Text(
                        "No program information",
                        color = Theme.TextMuted,
                        fontSize = 13.sp,
                        modifier = Modifier.padding(start = 20.dp)
                    )
                }
            } else {
                programs.forEach { p ->
                    val start = maxOf(p.startTime, startTime)
                    val end = minOf(p.endTime, endTime)
                    val w = pxPerMin * ((end - start) / 60f).toInt()
                    ProgramCell(
                        p = p,
                        width = w,
                        isLive = now in p.startTime..p.endTime,
                        isFirstRow = isFirstRow,
                        onUpPressed = onUpPressed,
                        onFocus = { onProgramFocus(p) },
                        onClick = onSelect
                    )
                }
            }
        }
    }

    // Subtle separator
    Box(
        Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Theme.GlassBorder.copy(0.3f))
    )
}

@Composable
private fun ChannelCell(
    ch: Channel,
    currentProgram: Program?,
    width: Dp,
    isSelected: Boolean,
    isFirstRow: Boolean = false,
    onUpPressed: () -> Unit = {},
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var focused by remember { mutableStateOf(false) }
    val bg by animateColorAsState(
        when {
            focused -> Theme.SurfaceHighlight
            isSelected -> Theme.SurfaceElevated
            else -> Theme.Surface
        },
        tween(150), "chBg"
    )

    // Create a focus requester for redirecting UP navigation
    val tabsFocusRequester = remember { FocusRequester() }

    // Try to capture the category tabs focus requester on first composition
    LaunchedEffect(isFirstRow) {
        if (isFirstRow) {
            // Will be set via callback
        }
    }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(width)
            .height(88.dp)  // FuboTV-style height
            .onFocusChanged {
                focused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .then(
                if (isFirstRow) {
                    Modifier.onPreviewKeyEvent { e ->
                        if (e.type == KeyEventType.KeyDown && e.key == Key.DirectionUp) {
                            onUpPressed()
                            true
                        } else false
                    }
                } else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(0.dp)),
        colors = ClickableSurfaceDefaults.colors(bg, focusedContainerColor = Theme.SurfaceHighlight),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(border = BorderStroke(2.dp, Theme.Accent), shape = RoundedCornerShape(0.dp))
        )
    ) {
        Row(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Favorite star (FuboTV style - left side)
            if (ch.favorite) {
                Icon(Icons.Default.Star, null, Modifier.size(14.dp), Theme.AccentGold)
                Spacer(Modifier.width(6.dp))
            }

            // Channel logo
            Box(
                Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Theme.Background),
                Alignment.Center
            ) {
                AsyncImage(ch.logoUrl, null, Modifier.size(36.dp), contentScale = ContentScale.Fit)
            }

            Spacer(Modifier.width(10.dp))

            // FuboTV style: Program thumbnail next to channel logo
            val thumbUrl = currentProgram?.thumb ?: currentProgram?.art ?: ch.nowPlaying?.thumb
            if (thumbUrl != null) {
                Box(
                    Modifier
                        .size(80.dp, 56.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(Theme.SurfaceElevated)
                ) {
                    AsyncImage(
                        thumbUrl,
                        null,
                        Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                    // LIVE badge overlay
                    if (currentProgram?.isLive == true || currentProgram?.isAiring == true) {
                        Box(
                            Modifier
                                .align(Alignment.BottomStart)
                                .padding(4.dp)
                        ) {
                            Box(
                                Modifier
                                    .clip(RoundedCornerShape(3.dp))
                                    .background(Theme.AccentRed)
                                    .padding(horizontal = 5.dp, vertical = 2.dp)
                            ) {
                                Text("LIVE", color = Color.White, fontSize = 8.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
                Spacer(Modifier.width(10.dp))
            }

            // Channel info column
            Column(Modifier.weight(1f)) {
                Text(
                    ch.name,
                    color = Theme.TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun ProgramCell(
    p: Program,
    width: Dp,
    isLive: Boolean,
    isFirstRow: Boolean = false,
    onUpPressed: () -> Unit = {},
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var focused by remember { mutableStateOf(false) }

    val catColor = when {
        p.isSports -> Theme.Sports
        p.isMovie -> Theme.Movie
        p.isKids -> Theme.Kids
        else -> Theme.Entertainment
    }

    val catGlow = when {
        p.isSports -> Theme.SportsGlow
        p.isMovie -> Theme.MovieGlow
        p.isKids -> Theme.KidsGlow
        else -> Theme.EntertainmentGlow
    }

    val bg by animateColorAsState(
        when {
            focused -> catColor.copy(0.4f)
            isLive -> catColor.copy(0.2f)
            else -> Theme.Surface
        },
        tween(150), "progBg"
    )

    val scale by animateFloatAsState(
        targetValue = if (focused) 1.03f else 1f,
        animationSpec = spring(dampingRatio = 0.7f),
        label = "scale"
    )

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .padding(3.dp)
            .scale(scale)
            .onFocusChanged {
                focused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .then(
                if (isFirstRow) {
                    Modifier.onPreviewKeyEvent { e ->
                        if (e.type == KeyEventType.KeyDown && e.key == Key.DirectionUp) {
                            onUpPressed()
                            true
                        } else false
                    }
                } else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(14.dp)),
        colors = ClickableSurfaceDefaults.colors(bg, focusedContainerColor = catColor.copy(0.4f)),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(border = BorderStroke(2.dp, catGlow), shape = RoundedCornerShape(14.dp))
        ),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(catColor.copy(0.3f), 8.dp)
        )
    ) {
        Box(Modifier.fillMaxSize()) {
            // Category accent bar
            Box(
                Modifier
                    .width(4.dp)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(topStart = 14.dp, bottomStart = 14.dp))
                    .background(
                        Brush.verticalGradient(listOf(catGlow, catColor))
                    )
            )

            Column(
                Modifier
                    .fillMaxSize()
                    .padding(start = 14.dp, end = 12.dp, top = 12.dp, bottom = 12.dp)
            ) {
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (isLive) {
                        AnimatedLiveBadge(small = true)
                        Spacer(Modifier.width(8.dp))
                    }

                    // Category icon
                    CategoryIconSmall(p)
                    Spacer(Modifier.width(6.dp))

                    Text(
                        p.title,
                        color = Theme.TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    // Recording indicator
                    if (p.hasRecording) {
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.Default.FiberManualRecord, null, Modifier.size(12.dp), Theme.AccentRed)
                    }
                }

                // Episode info with "New" badge (FuboTV style)
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    (p.episodeInfo ?: p.subtitle)?.let { info ->
                        Text(
                            info,
                            color = Theme.TextSecondary,
                            fontSize = 11.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f, false)
                        )
                    }

                    // FuboTV-style "New" badge
                    if (p.isNew || p.isPremiere) {
                        if (p.episodeInfo != null || p.subtitle != null) {
                            Spacer(Modifier.width(8.dp))
                        }
                        Box(
                            Modifier
                                .clip(RoundedCornerShape(3.dp))
                                .background(Theme.SurfaceHighlight)
                                .border(1.dp, Theme.TextMuted.copy(0.3f), RoundedCornerShape(3.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                "New",
                                color = Theme.TextSecondary,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                Spacer(Modifier.weight(1f))

                // Time display (smaller, more subtle)
                val fmt = SimpleDateFormat("h:mma", Locale.getDefault())
                Text(
                    fmt.format(Date(p.startTime * 1000)).lowercase(),
                    color = Theme.TextMuted,
                    fontSize = 10.sp
                )

                if (isLive) {
                    Spacer(Modifier.height(4.dp))
                    @Suppress("DEPRECATION")
                    LinearProgressIndicator(
                        progress = p.progress,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(3.dp)
                            .clip(RoundedCornerShape(1.5.dp)),
                        color = catGlow,
                        trackColor = Theme.TextMuted.copy(0.2f)
                    )
                }
            }
        }
    }
}

// Animated Components

@Composable
private fun AnimatedLiveBadge(small: Boolean = false) {
    val infiniteTransition = rememberInfiniteTransition(label = "live")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.4f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse"
    )

    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Row(
        Modifier
            .scale(scale)
            .clip(RoundedCornerShape(4.dp))
            .background(Theme.AccentRed.copy(alpha))
            .padding(horizontal = if (small) 6.dp else 8.dp, vertical = if (small) 2.dp else 3.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier
                .size(if (small) 5.dp else 6.dp)
                .clip(CircleShape)
                .background(Color.White)
        )
        Spacer(Modifier.width(4.dp))
        Text(
            "LIVE",
            color = Color.White,
            fontSize = if (small) 9.sp else 10.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun PulsingDot(color: Color = Theme.AccentRed) {
    val infiniteTransition = rememberInfiniteTransition(label = "dot")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(600),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    Box(
        Modifier
            .size(8.dp)
            .clip(CircleShape)
            .background(color.copy(alpha))
    )
}

@Composable
private fun PulsingDots() {
    val infiniteTransition = rememberInfiniteTransition(label = "dots")
    Row {
        repeat(3) { i ->
            val delay = i * 200
            val alpha by infiniteTransition.animateFloat(
                initialValue = 0.3f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = keyframes {
                        durationMillis = 1000
                        0.3f at delay
                        1f at delay + 250
                        0.3f at delay + 500
                    }
                ),
                label = "dot$i"
            )
            Box(
                Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(Theme.Accent.copy(alpha))
            )
            if (i < 2) Spacer(Modifier.width(8.dp))
        }
    }
}

@Composable
private fun GlowBadge(text: String, color: Color, small: Boolean = false) {
    Box(
        Modifier
            .clip(RoundedCornerShape(if (small) 3.dp else 4.dp))
            .background(color.copy(0.2f))
            .border(1.dp, color.copy(0.4f), RoundedCornerShape(if (small) 3.dp else 4.dp))
            .padding(horizontal = if (small) 5.dp else 8.dp, vertical = if (small) 1.dp else 3.dp)
    ) {
        Text(
            text,
            color = color,
            fontSize = if (small) 9.sp else 10.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun CategoryChip(program: Program) {
    val (icon, color, label) = when {
        program.isSports -> Triple(Icons.Default.SportsSoccer, Theme.Sports, "Sports")
        program.isMovie -> Triple(Icons.Default.Movie, Theme.Movie, "Movie")
        program.isKids -> Triple(Icons.Default.ChildCare, Theme.Kids, "Kids")
        else -> Triple(Icons.Default.Tv, Theme.Entertainment, "TV")
    }

    Row(
        Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(color.copy(0.15f))
            .border(1.dp, color.copy(0.3f), RoundedCornerShape(8.dp))
            .padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, Modifier.size(14.dp), color)
        Spacer(Modifier.width(5.dp))
        Text(label, color = color, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun CategoryIconSmall(program: Program) {
    val (icon, color) = when {
        program.isSports -> Icons.Default.SportsSoccer to Theme.Sports
        program.isMovie -> Icons.Default.Movie to Theme.Movie
        program.isKids -> Icons.Default.ChildCare to Theme.Kids
        else -> Icons.Default.Tv to Theme.Entertainment
    }

    Box(
        Modifier
            .size(20.dp)
            .clip(RoundedCornerShape(5.dp))
            .background(color.copy(0.2f)),
        Alignment.Center
    ) {
        Icon(icon, null, Modifier.size(13.dp), color)
    }
}

// State Views

@Composable
private fun LoadingView() {
    Box(Modifier.fillMaxSize(), Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            PulsingDots()
            Spacer(Modifier.height(20.dp))
            Text("Loading guide...", color = Theme.TextSecondary, fontSize = 15.sp)
        }
    }
}

@Composable
private fun ErrorView(err: String, retry: () -> Unit) {
    Box(Modifier.fillMaxSize(), Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.ErrorOutline, null, Modifier.size(64.dp), Theme.AccentRed)
            Spacer(Modifier.height(16.dp))
            Text(err, color = Theme.TextPrimary, fontSize = 15.sp)
            Spacer(Modifier.height(24.dp))
            Surface(
                onClick = retry,
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                colors = ClickableSurfaceDefaults.colors(Theme.Accent, focusedContainerColor = Theme.AccentGlow),
                glow = ClickableSurfaceDefaults.glow(focusedGlow = Glow(Theme.Accent.copy(0.4f), 8.dp))
            ) {
                Text(
                    "Retry",
                    Modifier.padding(horizontal = 36.dp, vertical = 14.dp),
                    Color.Black,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

@Composable
private fun EmptyView(isFiltered: Boolean) {
    Box(Modifier.fillMaxSize(), Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                if (isFiltered) Icons.Default.FilterListOff else Icons.Default.LiveTv,
                null,
                Modifier.size(72.dp),
                Theme.TextMuted
            )
            Spacer(Modifier.height(16.dp))
            Text(
                if (isFiltered) "No channels match this filter" else "No channels available",
                color = Theme.TextSecondary,
                fontSize = 16.sp
            )
        }
    }
}
