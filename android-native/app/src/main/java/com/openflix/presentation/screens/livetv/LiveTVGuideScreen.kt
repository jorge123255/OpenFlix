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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text as M3Text
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

// OpenFlix theme - dark with cyan accents
private object Theme {
    // Base colors - matches OpenFlix dark theme
    val Background = Color(0xFF0D0D0D)  // Near black
    val Surface = Color(0xFF1A1A1A)     // Dark gray
    val SurfaceElevated = Color(0xFF242424)  // Slightly lighter
    val SurfaceHighlight = Color(0xFF2E2E2E)  // Highlighted/selected
    val Glass = Color(0xFF1F1F1F)
    val GlassBorder = Color(0xFF333333)

    // Accent colors - OpenFlix cyan/teal
    val Accent = Color(0xFF00D4FF)       // OpenFlix cyan
    val AccentGlow = Color(0xFF4DE8FF)   // Brighter cyan for glow
    val AccentSelected = Color(0xFF0A3D4D)  // Selected item background
    val AccentRed = Color(0xFFFF3B5C)
    val AccentBlue = Color(0xFF3B82F6)
    val AccentGold = Color(0xFFFFB800)

    // Program cell colors - dark with subtle borders
    val ProgramCell = Color(0xFF1A1A1A)
    val ProgramCellAlt = Color(0xFF1F1F1F)
    val ProgramCellSelected = Color(0xFF2A3A3F)
    val ProgramCellBorder = Color(0xFF2A2A2A)

    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0B0)
    val TextMuted = Color(0xFF666666)

    // Category colors - vibrant for contrast
    val Sports = Color(0xFF10B981)
    val SportsGlow = Color(0xFF34D399)
    val Movie = Color(0xFFEF4444)
    val MovieGlow = Color(0xFFF87171)
    val News = Color(0xFF3B82F6)
    val NewsGlow = Color(0xFF60A5FA)
    val Kids = Color(0xFFF59E0B)
    val KidsGlow = Color(0xFFFBBF24)
    val Entertainment = Color(0xFF00D4FF)
    val EntertainmentGlow = Color(0xFF4DE8FF)

    // Quality badge colors
    val BadgeUHD = Color(0xFF00D4FF)
    val BadgeHDR = Color(0xFF10B981)
    val BadgeDolby = Color(0xFF3B82F6)
    val BadgeCC = Color(0xFF6B7280)
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

// Time range options for guide
private enum class TimeRange(val label: String, val hours: Int) {
    HOURS_3("3 Hours", 3),
    HOURS_24("24 Hours", 24),
    DAYS_7("7 Days", 24 * 7),
    DAYS_14("14 Days", 24 * 14)
}

@Composable
fun LiveTVGuideScreen(
    onBack: () -> Unit,
    onChannelSelected: (String) -> Unit,
    liveTVPlayer: LiveTVPlayer,
    onFullscreenChanged: (Boolean) -> Unit = {},
    onNavigateToMultiview: () -> Unit = {},
    onNavigateToChannelSurfing: () -> Unit = {},
    onNavigateToCatchup: () -> Unit = {},
    viewModel: LiveTVGuideViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()

    var selectedChannel by remember { mutableStateOf<ChannelWithPrograms?>(null) }
    var selectedProgram by remember { mutableStateOf<Program?>(null) }
    var selectedCategory by remember { mutableStateOf(Category.ALL) }
    var selectedTimeRange by remember { mutableStateOf(TimeRange.HOURS_3) }
    var selectedProvider by remember { mutableStateOf<String?>(null) }  // null = All providers

    // Program options dialog state (for recording)
    var showProgramOptionsDialog by remember { mutableStateOf(false) }
    var programToRecord by remember { mutableStateOf<Program?>(null) }
    var channelToRecord by remember { mutableStateOf<Channel?>(null) }

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
    val totalHours = selectedTimeRange.hours

    val now = remember { System.currentTimeMillis() / 1000 }
    val startTime = remember(selectedTimeRange) { (now / 1800) * 1800 }
    val endTime = startTime + (totalHours * 3600)

    val timeSlots = remember(startTime) {
        (0 until totalHours * 2).map { startTime + (it * slotMinutes * 60) }
    }

    val nowOffset = remember(now, startTime) {
        ((now - startTime) / 60f) * pixelsPerMinute.value
    }

    val channelWidth = 200.dp  // Channels DVR style - compact

    // Get unique providers from channels (use sourceName or source as fallback)
    val availableProviders = remember(uiState.guide) {
        val providers = uiState.guide
            .mapNotNull { it.channel.sourceName?.takeIf { s -> s.isNotBlank() } ?: it.channel.source?.takeIf { s -> s.isNotBlank() } }
            .distinct()
            .sorted()
        timber.log.Timber.d("Available providers: $providers (from ${uiState.guide.size} channels)")
        // Debug: log first few channel sourceNames
        uiState.guide.take(5).forEach { cwp ->
            timber.log.Timber.d("Channel ${cwp.channel.name}: sourceName=${cwp.channel.sourceName}, source=${cwp.channel.source}")
        }
        providers
    }

    // Filter channels by category AND provider
    val filteredGuide = remember(uiState.guide, selectedCategory, selectedProvider) {
        val categoryFiltered = when (selectedCategory) {
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

        // Apply provider filter if selected (check sourceName or source)
        if (selectedProvider != null) {
            categoryFiltered.filter {
                val channelProvider = it.channel.sourceName?.takeIf { s -> s.isNotBlank() } ?: it.channel.source
                channelProvider == selectedProvider
            }
        } else {
            categoryFiltered
        }
    }

    // Reload guide when time range changes
    LaunchedEffect(selectedTimeRange) { viewModel.loadGuide(startTime, endTime) }

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
                        // S key - Channel Surfing mode
                        Key.S -> {
                            onNavigateToChannelSurfing()
                            true
                        }
                        // C key - Catch Up TV
                        Key.C -> {
                            onNavigateToCatchup()
                            true
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
                // Top section: Info panel (full width)
                TopInfoSection(
                    channel = selectedChannel?.channel,
                    program = selectedProgram,
                    liveTVPlayer = liveTVPlayer,
                    isPlaying = isPlaying,
                    isMuted = isMuted,
                    onMuteToggle = { liveTVPlayer.toggleMute() }
                )

                // Favorites quick access bar
                val favoriteChannels = remember(uiState.guide) {
                    uiState.guide.filter { it.channel.favorite }
                }
                if (favoriteChannels.isNotEmpty()) {
                    FavoritesQuickBar(
                        favoriteChannels = favoriteChannels,
                        currentChannelId = currentChannelId,
                        onChannelClick = { cwp ->
                            selectedChannel = cwp
                            selectedProgram = cwp.programs.find { it.isAiring }
                            currentChannelId = cwp.channel.id
                            viewModel.trackChannelWatch(cwp.channel)
                            cwp.channel.streamUrl?.let { liveTVPlayer.play(it) }
                            isFullscreen = true
                        },
                        onLongClick = { cwp ->
                            // Could show context menu to remove from favorites
                        }
                    )
                }

                // Recent channels quick access bar
                val recentChannelIds by viewModel.recentChannelIds.collectAsState()
                val recentChannels = remember(uiState.guide, recentChannelIds) {
                    recentChannelIds.mapNotNull { id ->
                        uiState.guide.find { it.channel.id == id }
                    }.filter { !it.channel.favorite } // Exclude favorites (they have their own bar)
                }
                if (recentChannels.isNotEmpty()) {
                    RecentChannelsBar(
                        recentChannels = recentChannels,
                        currentChannelId = currentChannelId,
                        onChannelClick = { cwp ->
                            selectedChannel = cwp
                            selectedProgram = cwp.programs.find { it.isAiring }
                            currentChannelId = cwp.channel.id
                            viewModel.trackChannelWatch(cwp.channel)
                            cwp.channel.streamUrl?.let { liveTVPlayer.play(it) }
                            isFullscreen = true
                        }
                    )
                }

                // Filter bar with category, time range, and provider filters
                GuideFilterBar(
                    selectedCategory = selectedCategory,
                    onCategorySelect = { selectedCategory = it },
                    selectedTimeRange = selectedTimeRange,
                    onTimeRangeSelect = { selectedTimeRange = it },
                    selectedProvider = selectedProvider,
                    onProviderSelect = { selectedProvider = it },
                    availableProviders = availableProviders,
                    categoryFocusRequester = categoryTabsFocusRequester,
                    onDownPressed = { guideFocusRequester.requestFocus() },
                    onRefresh = { viewModel.loadGuide(startTime, endTime) },
                    isLoading = uiState.isLoading
                )

                // Guide content area
                Column(Modifier.weight(1f)) {
                    // Time header
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
                                        onSelect = { handleChannelSelect(cwp) },
                                        onProgramLongPress = { p ->
                                            // Show recording options dialog
                                            programToRecord = p
                                            channelToRecord = cwp.channel
                                            showProgramOptionsDialog = true
                                        }
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
                    } // End when
                } // End Column (guide content)
            } // End Column (main)
        } // End AnimatedVisibility (guide UI)

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
                    onStartOver = { /* TODO */ },
                    onCatchup = onNavigateToCatchup
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

        // Program Options Dialog (for recording)
        if (showProgramOptionsDialog && programToRecord != null) {
            ProgramOptionsDialog(
                program = programToRecord!!,
                channel = channelToRecord,
                isScheduling = uiState.isSchedulingRecording,
                onDismiss = {
                    showProgramOptionsDialog = false
                    programToRecord = null
                    channelToRecord = null
                },
                onWatch = {
                    // Watch the program (go to fullscreen)
                    showProgramOptionsDialog = false
                    val cwp = selectedChannel
                    if (cwp != null) {
                        handleChannelSelect(cwp)
                    }
                },
                onRecord = {
                    // Schedule single recording
                    channelToRecord?.id?.let { channelId ->
                        programToRecord?.let { program ->
                            viewModel.scheduleRecording(channelId, program, recordSeries = false)
                        }
                    }
                    showProgramOptionsDialog = false
                    programToRecord = null
                    channelToRecord = null
                },
                onRecordSeries = {
                    // Schedule series recording
                    channelToRecord?.id?.let { channelId ->
                        programToRecord?.let { program ->
                            viewModel.scheduleRecording(channelId, program, recordSeries = true)
                        }
                    }
                    showProgramOptionsDialog = false
                    programToRecord = null
                    channelToRecord = null
                }
            )
        }

        // Recording success/error messages
        uiState.recordingSuccess?.let { message ->
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 32.dp)
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(Theme.Sports.copy(alpha = 0.9f))
                        .padding(horizontal = 24.dp, vertical = 12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = message,
                            color = Color.White,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }

        uiState.recordingError?.let { error ->
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 32.dp)
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(Theme.AccentRed.copy(alpha = 0.9f))
                        .padding(horizontal = 24.dp, vertical = 12.dp)
                        .clickable { viewModel.clearRecordingError() }
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Error,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = error,
                            color = Color.White,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
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

/**
 * Premium info panel - Channels DVR style with large artwork and detailed badges
 */
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
            .background(Theme.Background)
    ) {
        Row(
            Modifier
                .fillMaxSize()
                .padding(start = 20.dp, end = 24.dp, top = 16.dp, bottom = 16.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Program Artwork - larger poster style
            Box(
                Modifier
                    .width(200.dp)
                    .height(150.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Theme.Surface),
                Alignment.Center
            ) {
                val imageUrl = program?.art ?: program?.thumb ?: channel?.logoUrl
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = program?.title,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Icon(
                        Icons.Default.Tv,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = Theme.TextMuted
                    )
                }
            }

            Spacer(Modifier.width(20.dp))

            // Program Info Column
            Column(
                Modifier.weight(1f),
                verticalArrangement = Arrangement.Top
            ) {
                // Title and time
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = program?.title ?: channel?.name ?: "Select a program",
                        color = Theme.TextPrimary,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    // Show time if available
                    program?.let { p ->
                        val fmt = SimpleDateFormat("h:mma", Locale.getDefault())
                        Text(
                            text = fmt.format(Date(p.startTime * 1000)),
                            color = Theme.TextSecondary,
                            fontSize = 14.sp,
                            modifier = Modifier.padding(start = 12.dp)
                        )
                    }
                }

                // Subtitle/Episode info
                val subtitle = program?.episodeInfo ?: program?.subtitle
                if (subtitle != null) {
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        color = Theme.TextSecondary,
                        fontSize = 14.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(Modifier.height(10.dp))

                // Badges row - more comprehensive like Channels DVR
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    program?.let { p ->
                        if (p.isNew || p.isPremiere) {
                            QualityBadge(if (p.isPremiere) "Premiere" else "New", Theme.Sports)
                        }
                    }
                    channel?.let { ch ->
                        if (ch.hd) {
                            QualityBadge("HD", Theme.AccentBlue)
                        }
                    }
                    // Additional badges
                    QualityBadge("CC", Theme.TextMuted)
                }

                Spacer(Modifier.height(12.dp))

                // Description
                program?.description?.let { desc ->
                    Text(
                        text = desc,
                        color = Theme.TextSecondary,
                        fontSize = 13.sp,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        lineHeight = 18.sp
                    )
                }
            }
        }
    }
}

/**
 * Quality badge component (UHD, HDR, Dolby Atmos style)
 */
@Composable
private fun QualityBadge(text: String, color: Color) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(4.dp))
            .background(color.copy(alpha = 0.9f))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text = text,
            color = Color.White,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

/**
 * OpenFlix style vertical category sidebar
 */
@Composable
private fun CategorySidebar(
    selected: Category,
    onSelect: (Category) -> Unit,
    focusRequester: FocusRequester,
    onRightPressed: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(150.dp)
            .fillMaxHeight()
            .background(Theme.Surface)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            itemsIndexed(Category.values().toList(), key = { _, cat -> cat.name }) { index, cat ->
                val isSelected = selected == cat
                var isFocused by remember { mutableStateOf(false) }

                val bgColor by animateColorAsState(
                    when {
                        isFocused -> Theme.SurfaceHighlight
                        isSelected -> Theme.Surface
                        else -> Color.Transparent
                    },
                    tween(150), "sidebarBg"
                )

                Surface(
                    onClick = { onSelect(cat) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(if (index == 0) Modifier.focusRequester(focusRequester) else Modifier)
                        .onFocusChanged { isFocused = it.isFocused }
                        .onKeyEvent { e ->
                            if (e.type == KeyEventType.KeyDown && e.key == Key.DirectionRight) {
                                onRightPressed()
                                true
                            } else false
                        },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(0.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = bgColor,
                        focusedContainerColor = Theme.SurfaceHighlight
                    ),
                    border = ClickableSurfaceDefaults.border(
                        focusedBorder = Border(
                            border = BorderStroke(2.dp, Theme.Accent),
                            shape = RoundedCornerShape(8.dp)
                        )
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Icon
                        cat.icon?.let { icon ->
                            Icon(
                                icon,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp),
                                tint = when {
                                    isSelected -> Theme.Accent
                                    isFocused -> cat.color
                                    else -> Theme.TextMuted
                                }
                            )
                            Spacer(Modifier.width(10.dp))
                        }

                        // Label
                        Text(
                            text = cat.label,
                            color = when {
                                isSelected -> Theme.Accent
                                isFocused -> Theme.TextPrimary
                                else -> Theme.TextSecondary
                            },
                            fontSize = 13.sp,
                            fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
                        )
                    }
                }
            }
        }
    }
}

/**
 * Horizontal category filter row - compact chips style
 */
@Composable
private fun CategoryFilterRow(
    selected: Category,
    onSelect: (Category) -> Unit,
    focusRequester: FocusRequester,
    onDownPressed: () -> Unit
) {
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .background(Theme.Surface),
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        itemsIndexed(Category.values().toList(), key = { _, cat -> cat.name }) { index, cat ->
            val isSelected = selected == cat
            var isFocused by remember { mutableStateOf(false) }

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
                    containerColor = if (isSelected) Theme.Accent.copy(alpha = 0.2f) else Theme.SurfaceElevated,
                    focusedContainerColor = Theme.SurfaceHighlight
                ),
                border = ClickableSurfaceDefaults.border(
                    border = if (isSelected) Border(
                        border = BorderStroke(1.5.dp, Theme.Accent),
                        shape = RoundedCornerShape(20.dp)
                    ) else Border.None,
                    focusedBorder = Border(
                        border = BorderStroke(2.dp, Theme.Accent),
                        shape = RoundedCornerShape(20.dp)
                    )
                ),
                scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    cat.icon?.let { icon ->
                        Icon(
                            icon,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = if (isSelected) Theme.Accent else Theme.TextSecondary
                        )
                        Spacer(Modifier.width(6.dp))
                    }
                    Text(
                        text = cat.label,
                        color = if (isSelected) Theme.Accent else Theme.TextPrimary,
                        fontSize = 13.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                    )
                }
            }
        }
    }
}

/**
 * Complete filter bar with categories, time range, and provider selector
 */
@Composable
private fun GuideFilterBar(
    selectedCategory: Category,
    onCategorySelect: (Category) -> Unit,
    selectedTimeRange: TimeRange,
    onTimeRangeSelect: (TimeRange) -> Unit,
    selectedProvider: String?,
    onProviderSelect: (String?) -> Unit,
    availableProviders: List<String>,
    categoryFocusRequester: FocusRequester,
    onDownPressed: () -> Unit,
    onRefresh: () -> Unit = {},
    isLoading: Boolean = false
) {
    var showTimeRangeDropdown by remember { mutableStateOf(false) }
    var showProviderDropdown by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(Theme.Surface)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Category chips (scrollable)
        LazyRow(
            modifier = Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            itemsIndexed(Category.values().toList(), key = { _, cat -> cat.name }) { index, cat ->
                val isSelected = selectedCategory == cat
                var isFocused by remember { mutableStateOf(false) }

                Surface(
                    onClick = { onCategorySelect(cat) },
                    modifier = Modifier
                        .then(if (index == 0) Modifier.focusRequester(categoryFocusRequester) else Modifier)
                        .onFocusChanged { isFocused = it.isFocused }
                        .onKeyEvent { e ->
                            if (e.type == KeyEventType.KeyDown && e.key == Key.DirectionDown) {
                                onDownPressed()
                                true
                            } else false
                        },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(20.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (isSelected) Theme.Accent.copy(alpha = 0.2f) else Theme.SurfaceElevated,
                        focusedContainerColor = Theme.SurfaceHighlight
                    ),
                    border = ClickableSurfaceDefaults.border(
                        border = if (isSelected) Border(
                            border = BorderStroke(1.5.dp, Theme.Accent),
                            shape = RoundedCornerShape(20.dp)
                        ) else Border.None,
                        focusedBorder = Border(
                            border = BorderStroke(2.dp, Theme.Accent),
                            shape = RoundedCornerShape(20.dp)
                        )
                    ),
                    scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        cat.icon?.let { icon ->
                            Icon(
                                icon,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = if (isSelected) Theme.Accent else Theme.TextSecondary
                            )
                            Spacer(Modifier.width(4.dp))
                        }
                        Text(
                            text = cat.label,
                            color = if (isSelected) Theme.Accent else Theme.TextPrimary,
                            fontSize = 12.sp,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                        )
                    }
                }
            }
        }

        // Divider
        Box(
            Modifier
                .width(1.dp)
                .height(24.dp)
                .background(Theme.TextMuted.copy(alpha = 0.3f))
        )

        // Time Range dropdown button
        Box {
            Surface(
                onClick = { showTimeRangeDropdown = !showTimeRangeDropdown },
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = Theme.SurfaceElevated,
                    focusedContainerColor = Theme.SurfaceHighlight
                ),
                border = ClickableSurfaceDefaults.border(
                    focusedBorder = Border(
                        border = BorderStroke(2.dp, Theme.Accent),
                        shape = RoundedCornerShape(8.dp)
                    )
                )
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Theme.TextSecondary
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        text = selectedTimeRange.label,
                        color = Theme.TextPrimary,
                        fontSize = 12.sp
                    )
                    Spacer(Modifier.width(4.dp))
                    Icon(
                        Icons.Default.ArrowDropDown,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Theme.TextSecondary
                    )
                }
            }

            DropdownMenu(
                expanded = showTimeRangeDropdown,
                onDismissRequest = { showTimeRangeDropdown = false }
            ) {
                TimeRange.values().forEach { range ->
                    DropdownMenuItem(
                        text = { Text(range.label) },
                        onClick = {
                            onTimeRangeSelect(range)
                            showTimeRangeDropdown = false
                        },
                        leadingIcon = if (range == selectedTimeRange) {
                            { Icon(Icons.Default.Check, null, tint = Theme.Accent) }
                        } else null
                    )
                }
            }
        }

        // Provider dropdown button
        Box {
                Surface(
                    onClick = { showProviderDropdown = !showProviderDropdown },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (selectedProvider != null) Theme.Accent.copy(alpha = 0.2f) else Theme.SurfaceElevated,
                        focusedContainerColor = Theme.SurfaceHighlight
                    ),
                    border = ClickableSurfaceDefaults.border(
                        border = if (selectedProvider != null) Border(
                            border = BorderStroke(1.5.dp, Theme.Accent),
                            shape = RoundedCornerShape(8.dp)
                        ) else Border.None,
                        focusedBorder = Border(
                            border = BorderStroke(2.dp, Theme.Accent),
                            shape = RoundedCornerShape(8.dp)
                        )
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = if (selectedProvider != null) Theme.Accent else Theme.TextSecondary
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            text = selectedProvider ?: "All Sources",
                            color = if (selectedProvider != null) Theme.Accent else Theme.TextPrimary,
                            fontSize = 12.sp,
                            maxLines = 1
                        )
                        Spacer(Modifier.width(4.dp))
                        Icon(
                            Icons.Default.ArrowDropDown,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = if (selectedProvider != null) Theme.Accent else Theme.TextSecondary
                        )
                    }
                }

                DropdownMenu(
                    expanded = showProviderDropdown,
                    onDismissRequest = { showProviderDropdown = false }
                ) {
                    // "All Sources" option
                    DropdownMenuItem(
                        text = { Text("All Sources") },
                        onClick = {
                            onProviderSelect(null)
                            showProviderDropdown = false
                        },
                        leadingIcon = if (selectedProvider == null) {
                            { Icon(Icons.Default.Check, null, tint = Theme.Accent) }
                        } else null
                    )

                    // Individual providers
                    availableProviders.forEach { provider ->
                        DropdownMenuItem(
                            text = { Text(provider) },
                            onClick = {
                                onProviderSelect(provider)
                                showProviderDropdown = false
                            },
                            leadingIcon = if (provider == selectedProvider) {
                                { Icon(Icons.Default.Check, null, tint = Theme.Accent) }
                            } else null
                        )
                    }
                }
            }

            // Refresh button
            Surface(
                onClick = { if (!isLoading) onRefresh() },
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = if (isLoading) Theme.Accent.copy(alpha = 0.2f) else Theme.SurfaceElevated,
                    focusedContainerColor = Theme.SurfaceHighlight
                ),
                border = ClickableSurfaceDefaults.border(
                    focusedBorder = Border(
                        border = BorderStroke(1.5.dp, Theme.Accent),
                        shape = RoundedCornerShape(8.dp)
                    )
                ),
                scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
            ) {
                Box(
                    modifier = Modifier.padding(8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Refresh,
                        contentDescription = "Refresh Guide",
                        modifier = Modifier.size(20.dp),
                        tint = if (isLoading) Theme.Accent else Theme.TextSecondary
                    )
                }
            }
    }
}

/**
 * OpenFlix style time header
 */
@Composable
private fun TimeHeader(
    slots: List<Long>,
    channelWidth: Dp,
    pxPerMin: Dp,
    slotMins: Int,
    now: Long,
    onShiftTime: (Int) -> Unit
) {
    val dayFmt = SimpleDateFormat("EEE, MMM d", Locale.getDefault())
    val isToday = remember(slots.firstOrNull()) {
        val cal = Calendar.getInstance()
        val today = cal.get(Calendar.DAY_OF_YEAR)
        cal.timeInMillis = (slots.firstOrNull() ?: 0) * 1000
        cal.get(Calendar.DAY_OF_YEAR) == today
    }

    Row(
        Modifier
            .fillMaxWidth()
            .height(40.dp)
            .background(Theme.SurfaceElevated)
    ) {
        // Date/channel header
        Box(
            Modifier
                .width(channelWidth)
                .fillMaxHeight()
                .background(Theme.Surface),
            contentAlignment = Alignment.CenterStart
        ) {
            Row(
                Modifier.padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isToday) "Today" else dayFmt.format(Date((slots.firstOrNull() ?: 0) * 1000)),
                    color = Theme.TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        // Time slots
        Row(
            Modifier
                .weight(1f)
                .horizontalScroll(rememberScrollState())
        ) {
            val fmt = SimpleDateFormat("h:mm a", Locale.getDefault())
            slots.forEach { ts ->
                val w = pxPerMin * slotMins

                Box(
                    Modifier
                        .width(w)
                        .fillMaxHeight()
                        .drawBehind {
                            // Vertical divider line
                            drawLine(
                                Theme.ProgramCellBorder.copy(0.3f),
                                Offset(0f, 0f),
                                Offset(0f, size.height),
                                1f
                            )
                        },
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = fmt.format(Date(ts * 1000)),
                        color = Theme.TextSecondary,
                        fontSize = 12.sp,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
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
    onSelect: () -> Unit,
    onProgramLongPress: (Program) -> Unit = {}
) {
    val programs = remember(data.programs, startTime, endTime) {
        data.programs.filter { it.endTime > startTime && it.startTime < endTime }
    }

    Row(
        Modifier
            .fillMaxWidth()
            .height(56.dp)  // Channels DVR style - compact rows
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
                        onClick = onSelect,
                        onLongPress = { onProgramLongPress(p) }
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

/**
 * Clean channel cell - Channels DVR style with network logo and number
 */
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

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(width)
            .height(56.dp)  // More compact like Channels DVR
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
            border = Border(
                border = BorderStroke(0.5.dp, Theme.GlassBorder),
                shape = RoundedCornerShape(0.dp)
            ),
            focusedBorder = Border(border = BorderStroke(2.dp, Theme.Accent), shape = RoundedCornerShape(4.dp))
        )
    ) {
        Row(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Network logo - clean white/light background like Channels DVR
            Box(
                Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.White),
                Alignment.Center
            ) {
                AsyncImage(
                    model = ch.logoUrl,
                    contentDescription = ch.name,
                    modifier = Modifier
                        .size(36.dp)
                        .padding(2.dp),
                    contentScale = ContentScale.Fit
                )
            }

            Spacer(Modifier.width(8.dp))

            // Channel number - prominent like Channels DVR
            ch.number?.let { num ->
                Text(
                    text = num,
                    color = Theme.TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.width(32.dp)
                )
            }

            // Channel name
            Text(
                text = ch.name,
                color = Theme.TextPrimary,
                fontSize = 13.sp,
                fontWeight = FontWeight.Normal,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

/**
 * Clean program cell - Channels DVR style
 */
@Composable
private fun ProgramCell(
    p: Program,
    width: Dp,
    isLive: Boolean,
    isFirstRow: Boolean = false,
    onUpPressed: () -> Unit = {},
    onFocus: () -> Unit,
    onClick: () -> Unit,
    onLongPress: () -> Unit = {}
) {
    var focused by remember { mutableStateOf(false) }

    val bg by animateColorAsState(
        when {
            focused -> Theme.SurfaceHighlight
            else -> Theme.Surface
        },
        tween(150), "progBg"
    )

    // Track long-press state for D-pad center button
    var pressStartTime by remember { mutableStateOf(0L) }
    val longPressThreshold = 500L

    Surface(
        onClick = onClick,
        onLongClick = onLongPress,
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .padding(horizontal = 0.5.dp, vertical = 0.5.dp)
            .onFocusChanged {
                focused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .onKeyEvent { e ->
                when {
                    e.key == Key.DirectionCenter || e.key == Key.Enter -> {
                        when (e.type) {
                            KeyEventType.KeyDown -> {
                                if (pressStartTime == 0L) {
                                    pressStartTime = System.currentTimeMillis()
                                } else if (System.currentTimeMillis() - pressStartTime > longPressThreshold) {
                                    onLongPress()
                                    pressStartTime = 0L
                                    true
                                } else false
                                false
                            }
                            KeyEventType.KeyUp -> {
                                pressStartTime = 0L
                                false
                            }
                            else -> false
                        }
                    }
                    else -> false
                }
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
            border = Border(
                border = BorderStroke(0.5.dp, Theme.GlassBorder),
                shape = RoundedCornerShape(0.dp)
            ),
            focusedBorder = Border(
                border = BorderStroke(2.dp, Theme.Accent),
                shape = RoundedCornerShape(4.dp)
            )
        )
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 10.dp, vertical = 6.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Title - clean and simple
            Text(
                text = p.title,
                color = Theme.TextPrimary,
                fontSize = 13.sp,
                fontWeight = FontWeight.Normal,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 16.sp
            )

            // Bottom row: time only (clean like Channels DVR)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                val fmt = SimpleDateFormat("h:mm", Locale.getDefault())
                Text(
                    text = fmt.format(Date(p.startTime * 1000)),
                    color = Theme.TextMuted,
                    fontSize = 11.sp
                )

                // Progress indicator for live - subtle underline
                if (isLive && p.progress > 0) {
                    Spacer(Modifier.width(8.dp))
                    Box(
                        Modifier
                            .weight(1f)
                            .height(2.dp)
                            .clip(RoundedCornerShape(1.dp))
                            .background(Theme.GlassBorder)
                    ) {
                        Box(
                            Modifier
                                .fillMaxHeight()
                                .fillMaxWidth(p.progress)
                                .background(Theme.Accent)
                        )
                    }
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

/**
 * Program Options Dialog - shown when user long-presses or selects a program
 * with the option to Record or Record Series
 */
@Composable
fun ProgramOptionsDialog(
    program: Program,
    channel: Channel?,
    isScheduling: Boolean,
    onDismiss: () -> Unit,
    onWatch: () -> Unit,
    onRecord: () -> Unit,
    onRecordSeries: () -> Unit
) {
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .clickable { onDismiss() },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.5f)
                .clip(RoundedCornerShape(16.dp))
                .background(Theme.Surface)
                .border(1.dp, Theme.GlassBorder, RoundedCornerShape(16.dp))
                .clickable { /* Prevent click through */ }
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
            ) {
                // Header with program info
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Program thumbnail
                    program.thumb?.let { thumbUrl ->
                        AsyncImage(
                            model = thumbUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(100.dp, 56.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Theme.SurfaceElevated),
                            contentScale = ContentScale.Crop
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                    }

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = program.title,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )

                        program.episodeInfo?.let { info ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = info,
                                style = MaterialTheme.typography.bodyMedium,
                                color = Theme.TextSecondary
                            )
                        }

                        // Time info
                        val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${timeFormat.format(Date(program.startTime * 1000))} - ${timeFormat.format(Date(program.endTime * 1000))}",
                            style = MaterialTheme.typography.bodySmall,
                            color = Theme.TextMuted
                        )

                        channel?.let { ch ->
                            Text(
                                text = ch.name,
                                style = MaterialTheme.typography.bodySmall,
                                color = Theme.Accent
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Action buttons
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Watch Now button
                    Surface(
                        onClick = onWatch,
                        modifier = Modifier
                            .fillMaxWidth()
                            .focusRequester(focusRequester),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Theme.Accent,
                            focusedContainerColor = Theme.AccentGlow
                        ),
                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.PlayArrow,
                                contentDescription = null,
                                tint = Color.Black,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Watch Now",
                                color = Color.Black,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                    }

                    // Record button
                    Surface(
                        onClick = onRecord,
                        modifier = Modifier.fillMaxWidth(),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Theme.SurfaceElevated,
                            focusedContainerColor = Theme.AccentRed.copy(alpha = 0.3f)
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, Theme.AccentRed),
                                shape = RoundedCornerShape(12.dp)
                            )
                        ),
                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.FiberManualRecord,
                                contentDescription = null,
                                tint = Theme.AccentRed,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (isScheduling) "Scheduling..." else "Record",
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 16.sp
                            )
                        }
                    }

                    // Record Series button (only for TV shows with series ID)
                    if (program.seriesId != null) {
                        Surface(
                            onClick = onRecordSeries,
                            modifier = Modifier.fillMaxWidth(),
                            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                            colors = ClickableSurfaceDefaults.colors(
                                containerColor = Theme.SurfaceElevated,
                                focusedContainerColor = Theme.AccentRed.copy(alpha = 0.3f)
                            ),
                            border = ClickableSurfaceDefaults.border(
                                focusedBorder = Border(
                                    border = BorderStroke(2.dp, Theme.AccentRed),
                                    shape = RoundedCornerShape(12.dp)
                                )
                            ),
                            scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.PlaylistAdd,
                                    contentDescription = null,
                                    tint = Theme.AccentRed,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = if (isScheduling) "Scheduling..." else "Record Series",
                                    color = Color.White,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 16.sp
                                )
                            }
                        }
                    }

                    // Cancel button
                    Surface(
                        onClick = onDismiss,
                        modifier = Modifier.fillMaxWidth(),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Color.Transparent,
                            focusedContainerColor = Theme.SurfaceHighlight
                        ),
                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                    ) {
                        Text(
                            text = "Cancel",
                            color = Theme.TextSecondary,
                            fontSize = 14.sp,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            textAlign = TextAlign.Center
                        )
                    }
                }

                // Hint
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Press BACK to close",
                    style = MaterialTheme.typography.bodySmall,
                    color = Theme.TextMuted,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        }
    }
}

/**
 * Favorites Quick Access Bar - Shows favorite channels for quick switching
 */
@Composable
private fun FavoritesQuickBar(
    favoriteChannels: List<ChannelWithPrograms>,
    currentChannelId: String?,
    onChannelClick: (ChannelWithPrograms) -> Unit,
    onLongClick: (ChannelWithPrograms) -> Unit = {},
    modifier: Modifier = Modifier
) {
    if (favoriteChannels.isEmpty()) return

    Column(modifier = modifier.fillMaxWidth()) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                tint = Theme.AccentGold,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "FAVORITES",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = Theme.AccentGold,
                letterSpacing = 1.sp
            )
            Spacer(modifier = Modifier.width(8.dp))
            Box(
                modifier = Modifier
                    .background(Theme.AccentGold.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "${favoriteChannels.size}",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Theme.AccentGold
                )
            }
        }

        // Channel strip
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp)
        ) {
            items(favoriteChannels, key = { it.channel.id }) { cwp ->
                FavoriteChannelCard(
                    channelWithPrograms = cwp,
                    isSelected = cwp.channel.id == currentChannelId,
                    onClick = { onChannelClick(cwp) },
                    onLongClick = { onLongClick(cwp) }
                )
            }
        }

        // Divider
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
                .height(1.dp)
                .background(Theme.GlassBorder)
        )
    }
}

@Composable
private fun FavoriteChannelCard(
    channelWithPrograms: ChannelWithPrograms,
    isSelected: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    val channel = channelWithPrograms.channel
    val nowPlaying = channelWithPrograms.programs.find { it.isAiring }
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        onLongClick = onLongClick,
        modifier = Modifier
            .width(180.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) Theme.AccentSelected else Theme.Surface,
            focusedContainerColor = Theme.Accent.copy(alpha = 0.2f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, Theme.Accent),
                shape = RoundedCornerShape(12.dp)
            ),
            border = if (isSelected) Border(
                border = BorderStroke(2.dp, Theme.Accent.copy(alpha = 0.5f)),
                shape = RoundedCornerShape(12.dp)
            ) else Border.None
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = Theme.Accent.copy(alpha = 0.3f),
                elevation = 8.dp
            )
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel logo
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Theme.SurfaceElevated),
                contentAlignment = Alignment.Center
            ) {
                if (channel.logoUrl != null) {
                    AsyncImage(
                        model = channel.logoUrl,
                        contentDescription = channel.name,
                        modifier = Modifier.size(36.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.name.take(2).uppercase(),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = Theme.Accent
                    )
                }
            }

            Spacer(modifier = Modifier.width(10.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                // Channel number and name
                Row(verticalAlignment = Alignment.CenterVertically) {
                    channel.number?.let { number ->
                        Text(
                            text = number,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = if (isFocused || isSelected) Theme.Accent else Theme.TextPrimary
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                    }
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.bodySmall,
                        color = Theme.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                // Now playing
                nowPlaying?.let { program ->
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = program.title,
                        style = MaterialTheme.typography.bodySmall,
                        color = Theme.TextMuted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        fontSize = 11.sp
                    )

                    // Progress bar
                    Spacer(modifier = Modifier.height(4.dp))
                    LinearProgressIndicator(
                        progress = program.progress,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(2.dp)
                            .clip(RoundedCornerShape(1.dp)),
                        color = Theme.Accent,
                        trackColor = Theme.SurfaceHighlight
                    )
                }
            }

            // Live indicator if currently selected/playing
            if (isSelected) {
                Spacer(modifier = Modifier.width(6.dp))
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(Theme.AccentRed)
                )
            }
        }
    }
}

/**
 * Recent Channels Quick Access Bar - Shows recently watched channels
 */
@Composable
private fun RecentChannelsBar(
    recentChannels: List<ChannelWithPrograms>,
    currentChannelId: String?,
    onChannelClick: (ChannelWithPrograms) -> Unit,
    modifier: Modifier = Modifier
) {
    if (recentChannels.isEmpty()) return

    Column(modifier = modifier.fillMaxWidth()) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.History,
                contentDescription = null,
                tint = Theme.Accent,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "RECENT",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = Theme.Accent,
                letterSpacing = 1.sp
            )
            Spacer(modifier = Modifier.width(8.dp))
            Box(
                modifier = Modifier
                    .background(Theme.Accent.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "${recentChannels.size}",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Theme.Accent
                )
            }
        }

        // Channel strip
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp)
        ) {
            items(recentChannels, key = { it.channel.id }) { cwp ->
                RecentChannelCard(
                    channelWithPrograms = cwp,
                    isSelected = cwp.channel.id == currentChannelId,
                    onClick = { onChannelClick(cwp) }
                )
            }
        }

        // Divider
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
                .height(1.dp)
                .background(Theme.GlassBorder)
        )
    }
}

@Composable
private fun RecentChannelCard(
    channelWithPrograms: ChannelWithPrograms,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val channel = channelWithPrograms.channel
    val nowPlaying = channelWithPrograms.programs.find { it.isAiring }
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(160.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(10.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) Theme.AccentSelected else Theme.Surface,
            focusedContainerColor = Theme.Accent.copy(alpha = 0.15f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, Theme.Accent),
                shape = RoundedCornerShape(10.dp)
            ),
            border = if (isSelected) Border(
                border = BorderStroke(1.dp, Theme.Accent.copy(alpha = 0.4f)),
                shape = RoundedCornerShape(10.dp)
            ) else Border.None
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel logo (smaller for recent)
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Theme.SurfaceElevated),
                contentAlignment = Alignment.Center
            ) {
                if (channel.logoUrl != null) {
                    AsyncImage(
                        model = channel.logoUrl,
                        contentDescription = channel.name,
                        modifier = Modifier.size(28.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.name.take(2).uppercase(),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Theme.Accent
                    )
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                // Channel number and name
                Row(verticalAlignment = Alignment.CenterVertically) {
                    channel.number?.let { number ->
                        Text(
                            text = number,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (isFocused || isSelected) Theme.Accent else Theme.TextPrimary
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.bodySmall,
                        color = Theme.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        fontSize = 11.sp
                    )
                }

                // Now playing (compact)
                nowPlaying?.let { program ->
                    Text(
                        text = program.title,
                        style = MaterialTheme.typography.bodySmall,
                        color = Theme.TextMuted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        fontSize = 10.sp
                    )
                }
            }

            // Playing indicator
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(Theme.AccentRed)
                )
            }
        }
    }
}
