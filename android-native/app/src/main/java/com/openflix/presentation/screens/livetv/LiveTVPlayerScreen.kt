package com.openflix.presentation.screens.livetv

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.Canvas
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import androidx.compose.ui.viewinterop.AndroidView
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import com.openflix.domain.model.ProgramBadge
import com.openflix.player.LiveTVPlayer
import com.openflix.presentation.components.livetv.LiveTVPlayerControls
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.*

/**
 * Live TV Player screen with channel overlay and navigation.
 * Features:
 * - Full-screen video playback
 * - Channel info overlay (auto-hides after 5 seconds)
 * - Channel up/down navigation
 * - Number key input for direct channel selection
 * - Mini channel guide
 */
@Composable
fun LiveTVPlayerScreen(
    channelId: String,
    onBack: () -> Unit,
    onMultiview: () -> Unit = {},
    onEPGGuide: () -> Unit = {},
    onCatchup: () -> Unit = {},
    viewModel: LiveTVPlayerViewModel = hiltViewModel(),
    liveTVPlayer: LiveTVPlayer
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }

    // Overlay visibility state
    var showOverlay by remember { mutableStateOf(true) }
    var showMiniGuide by remember { mutableStateOf(false) }
    var showMiniEPG by remember { mutableStateOf(false) }
    var channelNumberInput by remember { mutableStateOf("") }

    // Auto-hide overlay timer
    LaunchedEffect(showOverlay) {
        if (showOverlay) {
            delay(5000)
            showOverlay = false
        }
    }

    // Clear channel number input after timeout
    LaunchedEffect(channelNumberInput) {
        if (channelNumberInput.isNotEmpty()) {
            delay(2000)
            val number = channelNumberInput.toIntOrNull()
            if (number != null) {
                viewModel.switchToChannelByNumber(number)
            }
            channelNumberInput = ""
        }
    }

    // Load channels when screen appears
    LaunchedEffect(channelId) {
        viewModel.loadChannelsAndPlay(channelId)
    }

    // Request focus for key events
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focusRequester)
            .focusable()
            .onKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown) {
                    // Check if any overlay/panel is open that needs D-pad navigation
                    val hasInteractiveOverlay = showOverlay || showMiniGuide || showMiniEPG ||
                        uiState.showChannelSearch || uiState.showSleepTimerPicker

                    when (event.key) {
                        // ========== D-PAD NAVIGATION ==========
                        // When overlay is visible: let D-pad navigate the UI
                        // When no overlay: D-pad changes channels/seeks
                        Key.DirectionUp -> {
                            if (hasInteractiveOverlay) {
                                // Let the UI handle focus navigation
                                false
                            } else {
                                viewModel.channelUp()
                                showOverlay = true
                                true
                            }
                        }
                        Key.DirectionDown -> {
                            if (hasInteractiveOverlay) {
                                // Let the UI handle focus navigation
                                false
                            } else {
                                viewModel.channelDown()
                                showOverlay = true
                                true
                            }
                        }
                        Key.DirectionLeft -> {
                            if (hasInteractiveOverlay) {
                                // Let the UI handle focus navigation
                                false
                            } else {
                                viewModel.seekBack(10)
                                showOverlay = true
                                true
                            }
                        }
                        Key.DirectionRight -> {
                            if (hasInteractiveOverlay) {
                                // Let the UI handle focus navigation
                                false
                            } else {
                                viewModel.seekForward(10)
                                showOverlay = true
                                true
                            }
                        }

                        // Hardware channel buttons (full remotes) - always work
                        Key.ChannelUp, Key.PageUp -> {
                            viewModel.channelUp()
                            showOverlay = true
                            true
                        }
                        Key.ChannelDown, Key.PageDown -> {
                            viewModel.channelDown()
                            showOverlay = true
                            true
                        }

                        // ========== SELECT/OK BUTTON ==========
                        // When no overlay: show overlay
                        // When overlay visible: let UI handle the selection
                        Key.Enter, Key.DirectionCenter -> {
                            if (!hasInteractiveOverlay) {
                                showOverlay = true
                                true
                            } else {
                                // Let the UI handle button clicks
                                false
                            }
                        }

                        // ========== PLAYBACK CONTROLS ==========
                        // Play/Pause - media buttons on full remotes
                        Key.MediaPlay -> {
                            if (uiState.isPaused) viewModel.togglePause()
                            showOverlay = true
                            true
                        }
                        Key.MediaPause -> {
                            if (!uiState.isPaused) viewModel.togglePause()
                            showOverlay = true
                            true
                        }
                        Key.MediaPlayPause, Key.Spacebar -> {
                            viewModel.togglePause()
                            showOverlay = true
                            true
                        }
                        Key.MediaStop -> {
                            viewModel.goLive() // Stop time-shift, go back to live
                            showOverlay = true
                            true
                        }

                        // Rewind/Fast Forward - media buttons (always work)
                        Key.MediaRewind -> {
                            viewModel.seekBack(10)
                            showOverlay = true
                            true
                        }
                        Key.MediaFastForward -> {
                            viewModel.seekForward(10)
                            showOverlay = true
                            true
                        }
                        // Skip buttons (some remotes have these)
                        Key.MediaSkipBackward -> {
                            viewModel.seekBack(30)
                            showOverlay = true
                            true
                        }
                        Key.MediaSkipForward -> {
                            viewModel.seekForward(30)
                            showOverlay = true
                            true
                        }

                        // ========== GUIDE/INFO BUTTONS (TV Remote) ==========
                        // Guide button - full EPG
                        Key.Guide -> {
                            onEPGGuide()
                            true
                        }
                        // Info button - show Mini EPG overlay
                        Key.Info -> {
                            showOverlay = true
                            showMiniEPG = true
                            viewModel.fetchUpcomingPrograms()
                            true
                        }
                        // Menu button - show mini channel guide
                        Key.Menu -> {
                            showMiniGuide = !showMiniGuide
                            showOverlay = true
                            true
                        }

                        // ========== COLOR BUTTONS (TV Remote with color keys) ==========
                        // RED button - Toggle favorites filter
                        Key(android.view.KeyEvent.KEYCODE_PROG_RED.toLong()) -> {
                            viewModel.toggleFavoritesFilter()
                            showOverlay = true
                            true
                        }
                        // GREEN button - Cycle audio tracks
                        Key(android.view.KeyEvent.KEYCODE_PROG_GREEN.toLong()) -> {
                            viewModel.cycleAudioTrack()
                            true
                        }
                        // YELLOW button - Cycle subtitle tracks
                        Key(android.view.KeyEvent.KEYCODE_PROG_YELLOW.toLong()) -> {
                            viewModel.cycleSubtitleTrack()
                            true
                        }
                        // BLUE button - Cycle aspect ratio
                        Key(android.view.KeyEvent.KEYCODE_PROG_BLUE.toLong()) -> {
                            viewModel.cycleAspectRatio()
                            showOverlay = true
                            true
                        }

                        // ========== SPECIAL FUNCTION BUTTONS (TV Remote) ==========
                        // Captions/CC button - cycle subtitles
                        Key(android.view.KeyEvent.KEYCODE_CAPTIONS.toLong()) -> {
                            viewModel.cycleSubtitleTrack()
                            true
                        }
                        // DVR button - show sleep timer
                        Key(android.view.KeyEvent.KEYCODE_DVR.toLong()) -> {
                            viewModel.toggleSleepTimerPicker()
                            true
                        }
                        // Bookmark button - toggle favorite
                        Key(android.view.KeyEvent.KEYCODE_BOOKMARK.toLong()), Key.Bookmark -> {
                            uiState.currentChannel?.let {
                                viewModel.toggleFavorite(it.id)
                            }
                            showOverlay = true
                            true
                        }
                        // Search button (Shield mic button) - channel search
                        Key(android.view.KeyEvent.KEYCODE_SEARCH.toLong()) -> {
                            viewModel.toggleChannelSearch()
                            true
                        }
                        // Settings button - show sleep timer picker
                        Key(android.view.KeyEvent.KEYCODE_SETTINGS.toLong()) -> {
                            viewModel.toggleSleepTimerPicker()
                            true
                        }
                        // Last channel / TV button
                        Key(android.view.KeyEvent.KEYCODE_LAST_CHANNEL.toLong()),
                        Key(android.view.KeyEvent.KEYCODE_TV.toLong()) -> {
                            viewModel.previousChannel()
                            showOverlay = true
                            true
                        }
                        // EPG button (alias for Guide)
                        Key(android.view.KeyEvent.KEYCODE_TV_DATA_SERVICE.toLong()) -> {
                            onEPGGuide()
                            true
                        }
                        // RECORD button
                        Key(android.view.KeyEvent.KEYCODE_MEDIA_RECORD.toLong()) -> {
                            // Record current program
                            true
                        }
                        // AUDIO button (separate from GREEN)
                        Key(android.view.KeyEvent.KEYCODE_MEDIA_AUDIO_TRACK.toLong()) -> {
                            viewModel.cycleAudioTrack()
                            true
                        }

                        // ========== PLAYBACK SPECIAL ==========
                        Key.MediaTopMenu -> {
                            viewModel.goLive()
                            showOverlay = true
                            true
                        }
                        Key.MediaPrevious -> {
                            if (uiState.isStartOverAvailable) {
                                viewModel.startOver()
                                showOverlay = true
                            }
                            true
                        }

                        // ========== KEYBOARD SHORTCUTS ==========
                        // S = Start Over
                        Key.S -> {
                            if (uiState.isStartOverAvailable) {
                                viewModel.startOver()
                                showOverlay = true
                            }
                            true
                        }
                        // M = Mute
                        Key.M -> {
                            viewModel.toggleMute()
                            showOverlay = true
                            true
                        }

                        // ========== MUTE ==========
                        Key.VolumeMute -> {
                            viewModel.toggleMute()
                            showOverlay = true
                            true
                        }
                        // Let system handle volume up/down
                        Key.VolumeUp, Key.VolumeDown -> false

                        // ========== BACK/EXIT ==========
                        Key.Escape, Key.Back -> {
                            when {
                                uiState.showChannelSearch -> viewModel.closeChannelSearch()
                                uiState.showSleepTimerPicker -> viewModel.toggleSleepTimerPicker()
                                showMiniGuide -> showMiniGuide = false
                                showMiniEPG -> showMiniEPG = false
                                showOverlay -> showOverlay = false
                                else -> onBack()
                            }
                            true
                        }

                        // ========== NUMBER KEYS (for remotes with number pad) ==========
                        Key.Zero, Key.NumPad0 -> { channelNumberInput += "0"; showOverlay = true; true }
                        Key.One, Key.NumPad1 -> { channelNumberInput += "1"; showOverlay = true; true }
                        Key.Two, Key.NumPad2 -> { channelNumberInput += "2"; showOverlay = true; true }
                        Key.Three, Key.NumPad3 -> { channelNumberInput += "3"; showOverlay = true; true }
                        Key.Four, Key.NumPad4 -> { channelNumberInput += "4"; showOverlay = true; true }
                        Key.Five, Key.NumPad5 -> { channelNumberInput += "5"; showOverlay = true; true }
                        Key.Six, Key.NumPad6 -> { channelNumberInput += "6"; showOverlay = true; true }
                        Key.Seven, Key.NumPad7 -> { channelNumberInput += "7"; showOverlay = true; true }
                        Key.Eight, Key.NumPad8 -> { channelNumberInput += "8"; showOverlay = true; true }
                        Key.Nine, Key.NumPad9 -> { channelNumberInput += "9"; showOverlay = true; true }

                        else -> false
                    }
                } else false
            }
    ) {
        // Video Surface - ExoPlayer PlayerView
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

        // Gesture controls overlay (swipe for volume/brightness)
        com.openflix.presentation.components.GestureOverlay(
            modifier = Modifier.fillMaxSize(),
            currentVolume = uiState.volume,
            onVolumeChange = { viewModel.setVolume(it) },
            enabled = !showOverlay && !showMiniGuide // Only active when controls hidden
        )

        // Loading indicator
        if (uiState.isLoading || uiState.isBuffering) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                LoadingSpinner(
                    color = OpenFlixColors.Primary,
                    modifier = Modifier.size(48.dp)
                )
            }
        }

        // Error display
        uiState.error?.let { error ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.8f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Playback Error",
                        style = MaterialTheme.typography.headlineMedium,
                        color = OpenFlixColors.Error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
        }

        // Channel number input display
        AnimatedVisibility(
            visible = channelNumberInput.isNotEmpty(),
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(40.dp)
        ) {
            Box(
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.85f),
                        RoundedCornerShape(8.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 16.dp)
            ) {
                Text(
                    text = channelNumberInput,
                    style = MaterialTheme.typography.displayLarge,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
        }

        // Channel info overlay with beautiful controls
        AnimatedVisibility(
            visible = showOverlay && uiState.currentChannel != null,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it }
        ) {
            uiState.currentChannel?.let { channel ->
                LiveTVPlayerControls(
                    channel = channel,
                    allChannels = uiState.channels,
                    isFavorite = uiState.favoriteChannelIds.contains(channel.id),
                    isMuted = uiState.isMuted,
                    // Time-shift state
                    isLive = uiState.isLive,
                    isPaused = uiState.isPaused,
                    timeShiftOffset = uiState.timeShiftOffsetDisplay,
                    isStartOverAvailable = uiState.isStartOverAvailable,
                    onShowEPG = onEPGGuide,
                    onShowMultiview = onMultiview,
                    onShowMiniGuide = { showMiniGuide = true },
                    onToggleFavorite = { viewModel.toggleFavorite(channel.id) },
                    onToggleMute = { viewModel.toggleMute() },
                    onShowAudioTracks = { /* TODO: Audio tracks sheet */ },
                    onShowSubtitles = { /* TODO: Subtitle tracks sheet */ },
                    onQuickRecord = { viewModel.scheduleQuickRecording() },
                    isRecording = uiState.isRecording,
                    instantSwitchReady = uiState.instantSwitchReady,
                    preBufferedChannelIds = uiState.preBufferedChannelIds,
                    onChannelSelected = { selectedChannel ->
                        viewModel.switchToChannel(selectedChannel)
                        showOverlay = true
                    },
                    // Time-shift callbacks
                    onTogglePause = { viewModel.togglePause() },
                    onSeekBack = { viewModel.seekBack(10) },
                    onSeekForward = { viewModel.seekForward(10) },
                    onGoLive = { viewModel.goLive() },
                    onStartOver = { viewModel.startOver() },
                    onCatchup = onCatchup
                )
            }
        }

        // Mini channel guide
        AnimatedVisibility(
            visible = showMiniGuide,
            enter = fadeIn() + slideInHorizontally { -it },
            exit = fadeOut() + slideOutHorizontally { -it },
            modifier = Modifier.align(Alignment.CenterStart)
        ) {
            MiniChannelGuide(
                channels = viewModel.getFilteredChannels(),
                currentChannel = uiState.currentChannel,
                favoriteChannelIds = uiState.favoriteChannelIds,
                showFavoritesOnly = uiState.showFavoritesOnly,
                onChannelSelected = { channel ->
                    viewModel.switchToChannel(channel)
                    showMiniGuide = false
                    showOverlay = true
                },
                onToggleFavorite = { channelId ->
                    viewModel.toggleFavorite(channelId)
                },
                onToggleFavoritesFilter = {
                    viewModel.toggleFavoritesFilter()
                }
            )
        }

        // Mini EPG Overlay (Tivimate-style horizontal program timeline)
        AnimatedVisibility(
            visible = showMiniEPG && uiState.currentChannel != null,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            uiState.currentChannel?.let { channel ->
                MiniEPGOverlay(
                    channel = channel,
                    programs = uiState.upcomingPrograms,
                    onProgramSelected = { program ->
                        // Could implement catch-up/start-over here
                        if (uiState.isStartOverAvailable && program.isAiring) {
                            viewModel.startOver()
                        }
                    },
                    onDismiss = { showMiniEPG = false }
                )
            }
        }

        // Audio/Subtitle track switch feedback (Tivimate-style)
        TrackSwitchIndicator(
            audioMessage = uiState.audioTrackMessage,
            subtitleMessage = uiState.subtitleTrackMessage,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 80.dp)
        )

        // Recording feedback indicator
        RecordingIndicator(
            successMessage = uiState.recordingSuccess,
            errorMessage = uiState.recordingError,
            isScheduling = uiState.isSchedulingRecording,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 140.dp)
        )

        // Sleep timer indicator (shows remaining time when active)
        uiState.sleepTimerMinutesRemaining?.let { minutes ->
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp)
                    .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(8.dp))
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(text = "💤", fontSize = 14.sp)
                    Text(
                        text = viewModel.getSleepTimerDisplay(),
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                }
            }
        }

        // Sleep timer picker dialog
        AnimatedVisibility(
            visible = uiState.showSleepTimerPicker,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            SleepTimerPicker(
                options = viewModel.sleepTimerOptions,
                currentTimer = uiState.sleepTimerMinutesRemaining,
                onSelect = { minutes -> viewModel.setSleepTimer(minutes) },
                onCancel = { viewModel.cancelSleepTimer() },
                onDismiss = { viewModel.toggleSleepTimerPicker() }
            )
        }

        // Channel search overlay (Tivimate-style)
        AnimatedVisibility(
            visible = uiState.showChannelSearch,
            enter = fadeIn() + slideInHorizontally { -it },
            exit = fadeOut() + slideOutHorizontally { -it },
            modifier = Modifier.align(Alignment.CenterStart)
        ) {
            ChannelSearchOverlay(
                query = uiState.channelSearchQuery,
                channels = uiState.filteredChannels,
                currentChannel = uiState.currentChannel,
                onQueryChange = { viewModel.updateSearchQuery(it) },
                onChannelSelected = { viewModel.selectSearchResult(it) },
                onDismiss = { viewModel.closeChannelSearch() }
            )
        }
    }
}

@Composable
private fun ChannelInfoOverlay(
    channel: Channel,
    nextChannels: List<Channel>
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.7f),
                        Color.Black.copy(alpha = 0.9f)
                    )
                )
            )
            .padding(32.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom
        ) {
            // Channel logo
            AsyncImage(
                model = channel.logoUrl,
                contentDescription = channel.name,
                modifier = Modifier
                    .size(80.dp)
                    .background(
                        OpenFlixColors.SurfaceVariant,
                        RoundedCornerShape(8.dp)
                    ),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.width(24.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                // Channel number and name
                Row(verticalAlignment = Alignment.CenterVertically) {
                    channel.number?.let { number ->
                        Text(
                            text = number,
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold,
                            color = OpenFlixColors.Primary
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )

                    if (channel.hd) {
                        Spacer(modifier = Modifier.width(12.dp))
                        Box(
                            modifier = Modifier
                                .background(
                                    OpenFlixColors.Info,
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = "HD",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Now playing
                channel.nowPlaying?.let { program ->
                    ProgramInfoRow(program = program, label = "NOW")
                }

                // Up next
                channel.upNext?.let { program ->
                    Spacer(modifier = Modifier.height(4.dp))
                    ProgramInfoRow(program = program, label = "NEXT")
                }
            }

            // Next channels preview
            if (nextChannels.isNotEmpty()) {
                Spacer(modifier = Modifier.width(32.dp))
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "Up Next",
                        style = MaterialTheme.typography.labelMedium,
                        color = OpenFlixColors.TextTertiary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    nextChannels.take(3).forEach { nextChannel ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(vertical = 2.dp)
                        ) {
                            Text(
                                text = nextChannel.number ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.Primary,
                                modifier = Modifier.width(40.dp)
                            )
                            Text(
                                text = nextChannel.name,
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.TextSecondary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.widthIn(max = 150.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ProgramInfoRow(
    program: Program,
    label: String
) {
    val timeFormat = remember { SimpleDateFormat("h:mm a", Locale.getDefault()) }

    Row(verticalAlignment = Alignment.CenterVertically) {
        // Label
        Box(
            modifier = Modifier
                .background(
                    if (label == "NOW") OpenFlixColors.LiveIndicator else OpenFlixColors.SurfaceVariant,
                    RoundedCornerShape(4.dp)
                )
                .padding(horizontal = 8.dp, vertical = 2.dp)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Time
        val startTime = Date(program.startTime * 1000)
        val endTime = Date(program.endTime * 1000)
        Text(
            text = "${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}",
            style = MaterialTheme.typography.bodySmall,
            color = OpenFlixColors.TextSecondary
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Title
        Text(
            text = program.displayTitle,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )

        // Badges
        program.badges.take(2).forEach { badge ->
            Spacer(modifier = Modifier.width(8.dp))
            ProgramBadgeChip(badge = badge)
        }

        // Progress bar for current program
        if (label == "NOW" && program.isAiring) {
            Spacer(modifier = Modifier.width(16.dp))
            Box(
                modifier = Modifier
                    .width(100.dp)
                    .height(4.dp)
                    .background(
                        OpenFlixColors.ProgressBackground,
                        RoundedCornerShape(2.dp)
                    )
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(program.progress)
                        .fillMaxHeight()
                        .background(
                            OpenFlixColors.Primary,
                            RoundedCornerShape(2.dp)
                        )
                )
            }
        }
    }
}

@Composable
private fun ProgramBadgeChip(badge: ProgramBadge) {
    val (text, color) = when (badge) {
        ProgramBadge.NEW -> "NEW" to OpenFlixColors.Success
        ProgramBadge.LIVE -> "LIVE" to OpenFlixColors.LiveIndicator
        ProgramBadge.PREMIERE -> "PREMIERE" to OpenFlixColors.Warning
        ProgramBadge.FINALE -> "FINALE" to OpenFlixColors.Warning
        ProgramBadge.SPORTS -> "SPORTS" to OpenFlixColors.Sports
        ProgramBadge.MOVIE -> "MOVIE" to OpenFlixColors.Info
        ProgramBadge.RECORDING -> "REC" to OpenFlixColors.Error
        ProgramBadge.CATCHUP -> "CATCHUP" to Color(0xFF8B5CF6)  // Purple for catch-up
    }

    Box(
        modifier = Modifier
            .background(color, RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            fontSize = 10.sp
        )
    }
}

@Composable
private fun MiniChannelGuide(
    channels: List<Channel>,
    currentChannel: Channel?,
    favoriteChannelIds: Set<String>,
    showFavoritesOnly: Boolean,
    onChannelSelected: (Channel) -> Unit,
    onToggleFavorite: (String) -> Unit,
    onToggleFavoritesFilter: () -> Unit
) {
    Box(
        modifier = Modifier
            .width(420.dp)
            .fillMaxHeight()
            .padding(vertical = 32.dp)
            .background(
                Brush.horizontalGradient(
                    colors = listOf(
                        Color(0xFF1F2937),
                        Color(0xFF111827)
                    )
                ),
                RoundedCornerShape(topEnd = 16.dp, bottomEnd = 16.dp)
            )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Header with favorites filter toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Channel Guide",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = if (showFavoritesOnly) "${channels.size} favorites" else "${channels.size} channels",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }

                // Favorites filter toggle button
                Surface(
                    onClick = onToggleFavoritesFilter,
                    modifier = Modifier.size(44.dp),
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (showFavoritesOnly) Color(0xFFF59E0B).copy(alpha = 0.2f) else OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = if (showFavoritesOnly) Color(0xFFF59E0B).copy(alpha = 0.3f) else OpenFlixColors.FocusBackground
                    )
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Text(
                            text = if (showFavoritesOnly) "★" else "☆",
                            fontSize = 20.sp,
                            color = if (showFavoritesOnly) Color(0xFFF59E0B) else OpenFlixColors.TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            if (channels.isEmpty()) {
                // Empty state
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "☆",
                            fontSize = 48.sp,
                            color = OpenFlixColors.TextTertiary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = if (showFavoritesOnly) "No favorite channels" else "No channels available",
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary
                        )
                        if (showFavoritesOnly) {
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Press F to show all channels",
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(
                        items = channels,
                        key = { it.id }
                    ) { channel ->
                        MiniGuideChannelItem(
                            channel = channel,
                            isSelected = channel.id == currentChannel?.id,
                            isFavorite = channel.id in favoriteChannelIds,
                            onClick = { onChannelSelected(channel) },
                            onToggleFavorite = { onToggleFavorite(channel.id) }
                        )
                    }
                }
            }

            // Footer hint
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "F: Filter • S: Add/Remove Favorite",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }
    }
}

@Composable
private fun MiniGuideChannelItem(
    channel: Channel,
    isSelected: Boolean,
    isFavorite: Boolean,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .focusable()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                isSelected -> OpenFlixColors.Primary.copy(alpha = 0.3f)
                isFocused -> OpenFlixColors.FocusBackground
                else -> Color.Transparent
            },
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        border = if (isSelected) {
            ClickableSurfaceDefaults.border(
                border = Border(
                    border = androidx.compose.foundation.BorderStroke(2.dp, OpenFlixColors.Primary),
                    shape = RoundedCornerShape(8.dp)
                )
            )
        } else {
            ClickableSurfaceDefaults.border()
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel number
            Text(
                text = channel.number ?: "-",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (isSelected) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                modifier = Modifier.width(48.dp)
            )

            // Channel logo
            AsyncImage(
                model = channel.logoUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(40.dp)
                    .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(4.dp)),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )

                    // Favorite star (inline)
                    if (isFavorite) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "★",
                            fontSize = 14.sp,
                            color = Color(0xFFF59E0B)
                        )
                    }
                }

                channel.nowPlaying?.let { program ->
                    Text(
                        text = program.title,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // HD badge
            if (channel.hd) {
                Box(
                    modifier = Modifier
                        .background(OpenFlixColors.Info, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "HD",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

/**
 * Channel search overlay with text input and filtered results
 */
@Composable
private fun ChannelSearchOverlay(
    query: String,
    channels: List<Channel>,
    currentChannel: Channel?,
    onQueryChange: (String) -> Unit,
    onChannelSelected: (Channel) -> Unit,
    onDismiss: () -> Unit
) {
    val searchFocusRequester = remember { FocusRequester() }

    // Request focus on the search field when opened
    LaunchedEffect(Unit) {
        searchFocusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .width(450.dp)
            .fillMaxHeight()
            .padding(vertical = 32.dp)
            .background(
                Brush.horizontalGradient(
                    colors = listOf(
                        Color(0xFF1F2937),
                        Color(0xFF111827)
                    )
                ),
                RoundedCornerShape(topEnd = 16.dp, bottomEnd = 16.dp)
            )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = 16.dp)
            ) {
                Text(text = "🔍", fontSize = 24.sp)
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Search Channels",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            // Search input
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(12.dp))
                    .padding(4.dp)
            ) {
                androidx.compose.foundation.text.BasicTextField(
                    value = query,
                    onValueChange = onQueryChange,
                    modifier = Modifier
                        .fillMaxWidth()
                        .focusRequester(searchFocusRequester)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    textStyle = MaterialTheme.typography.bodyLarge.copy(
                        color = Color.White
                    ),
                    singleLine = true,
                    decorationBox = { innerTextField ->
                        if (query.isEmpty()) {
                            Text(
                                text = "Type to search...",
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                        innerTextField()
                    }
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Results count
            Text(
                text = "${channels.size} channel${if (channels.size != 1) "s" else ""} found",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextSecondary,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            // Channel list
            if (channels.isEmpty() && query.isNotBlank()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = "😔", fontSize = 48.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "No channels found",
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(
                        items = channels.take(50), // Limit for performance
                        key = { it.id }
                    ) { channel ->
                        SearchChannelItem(
                            channel = channel,
                            isSelected = channel.id == currentChannel?.id,
                            onClick = { onChannelSelected(channel) }
                        )
                    }
                }
            }

            // Hint
            Text(
                text = "Press Q to close • Enter to select",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary,
                modifier = Modifier.padding(top = 12.dp)
            )
        }
    }
}

@Composable
private fun SearchChannelItem(
    channel: Channel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                isSelected -> OpenFlixColors.Primary.copy(alpha = 0.3f)
                else -> Color.Transparent
            },
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        border = if (isSelected) {
            ClickableSurfaceDefaults.border(
                border = Border(
                    border = BorderStroke(2.dp, OpenFlixColors.Primary),
                    shape = RoundedCornerShape(8.dp)
                ),
                focusedBorder = Border(
                    border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                    shape = RoundedCornerShape(8.dp)
                )
            )
        } else {
            ClickableSurfaceDefaults.border(
                focusedBorder = Border(
                    border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                    shape = RoundedCornerShape(8.dp)
                )
            )
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel number
            Text(
                text = channel.number ?: "-",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (isSelected) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                modifier = Modifier.width(48.dp)
            )

            // Channel logo
            AsyncImage(
                model = channel.logoUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(36.dp)
                    .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(4.dp)),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = channel.name,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                channel.nowPlaying?.let { program ->
                    Text(
                        text = program.title,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // HD badge
            if (channel.hd) {
                Box(
                    modifier = Modifier
                        .background(OpenFlixColors.Info, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "HD",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

/**
 * Sleep timer picker dialog
 */
@Composable
private fun SleepTimerPicker(
    options: List<Int>,
    currentTimer: Int?,
    onSelect: (Int) -> Unit,
    onCancel: () -> Unit,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .background(
                Color(0xFF1F2937).copy(alpha = 0.95f),
                RoundedCornerShape(16.dp)
            )
            .padding(24.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Title
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(bottom = 20.dp)
            ) {
                Text(text = "💤", fontSize = 28.sp)
                Text(
                    text = "Sleep Timer",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            // Current timer status
            if (currentTimer != null) {
                Text(
                    text = "Timer active: ${currentTimer}m remaining",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.Primary,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
            }

            // Timer options in a row
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                options.forEach { minutes ->
                    val displayText = if (minutes >= 60) {
                        "${minutes / 60}h${if (minutes % 60 > 0) " ${minutes % 60}m" else ""}"
                    } else {
                        "${minutes}m"
                    }

                    Surface(
                        onClick = { onSelect(minutes) },
                        modifier = Modifier.width(72.dp),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = if (currentTimer == minutes) {
                                OpenFlixColors.Primary.copy(alpha = 0.3f)
                            } else {
                                OpenFlixColors.SurfaceVariant
                            },
                            focusedContainerColor = OpenFlixColors.FocusBackground
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                                shape = RoundedCornerShape(12.dp)
                            ),
                            border = if (currentTimer == minutes) {
                                Border(
                                    border = BorderStroke(2.dp, OpenFlixColors.Primary),
                                    shape = RoundedCornerShape(12.dp)
                                )
                            } else {
                                Border.None
                            }
                        ),
                        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
                    ) {
                        Box(
                            modifier = Modifier
                                .padding(vertical = 12.dp)
                                .fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = displayText,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium,
                                color = Color.White
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Cancel / Close buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                if (currentTimer != null) {
                    Surface(
                        onClick = onCancel,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.Error.copy(alpha = 0.2f),
                            focusedContainerColor = OpenFlixColors.Error.copy(alpha = 0.4f)
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, OpenFlixColors.Error),
                                shape = RoundedCornerShape(8.dp)
                            )
                        )
                    ) {
                        Text(
                            text = "Cancel Timer",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.Error,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
                        )
                    }
                }

                Surface(
                    onClick = onDismiss,
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.FocusBackground
                    ),
                    border = ClickableSurfaceDefaults.border(
                        focusedBorder = Border(
                            border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                            shape = RoundedCornerShape(8.dp)
                        )
                    )
                ) {
                    Text(
                        text = "Close",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
                    )
                }
            }

            // Hint
            Text(
                text = "Press Z to toggle • Back to close",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary,
                modifier = Modifier.padding(top = 16.dp)
            )
        }
    }
}

/**
 * Track switch indicator - shows audio/subtitle track change feedback
 */
@Composable
private fun TrackSwitchIndicator(
    audioMessage: String?,
    subtitleMessage: String?,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Audio track indicator
        AnimatedVisibility(
            visible = audioMessage != null,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Box(
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.85f),
                        RoundedCornerShape(12.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Audio icon
                    Text(
                        text = "🔊",
                        fontSize = 20.sp
                    )
                    Text(
                        text = audioMessage ?: "",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }

        // Subtitle track indicator
        AnimatedVisibility(
            visible = subtitleMessage != null,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Box(
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.85f),
                        RoundedCornerShape(12.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Subtitle icon
                    Text(
                        text = "💬",
                        fontSize = 20.sp
                    )
                    Text(
                        text = subtitleMessage ?: "",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }
    }
}

/**
 * Mini EPG Overlay - Shows horizontal timeline of upcoming programs (Tivimate-style)
 */
@Composable
private fun MiniEPGOverlay(
    channel: Channel,
    programs: List<Program>,
    onProgramSelected: (Program) -> Unit,
    onDismiss: () -> Unit
) {
    val timeFormat = remember { SimpleDateFormat("h:mm a", Locale.getDefault()) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.85f),
                        Color.Black.copy(alpha = 0.95f)
                    )
                )
            )
            .padding(24.dp)
    ) {
        Column {
            // Channel header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = 16.dp)
            ) {
                // Channel logo
                AsyncImage(
                    model = channel.logoUrl,
                    contentDescription = channel.name,
                    modifier = Modifier
                        .size(48.dp)
                        .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(8.dp)),
                    contentScale = ContentScale.Fit
                )

                Spacer(modifier = Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        channel.number?.let { number ->
                            Text(
                                text = number,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = OpenFlixColors.Primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                        }
                        Text(
                            text = channel.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White
                        )
                        if (channel.hd) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .background(OpenFlixColors.Info, RoundedCornerShape(4.dp))
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "HD",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                        }
                    }
                    Text(
                        text = "Press E to hide • ←/→ to browse programs",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }

            // Program timeline
            if (programs.isEmpty()) {
                // No programs available
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No program information available",
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            } else {
                // Horizontal scrolling program list
                androidx.compose.foundation.lazy.LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(horizontal = 4.dp)
                ) {
                    items(
                        items = programs.take(8), // Show up to 8 programs
                        key = { it.id ?: it.startTime.toString() }
                    ) { program ->
                        MiniEPGProgramItem(
                            program = program,
                            timeFormat = timeFormat,
                            onClick = { onProgramSelected(program) }
                        )
                    }
                }
            }
        }
    }
}

/**
 * Individual program item in the Mini EPG
 */
@Composable
private fun MiniEPGProgramItem(
    program: Program,
    timeFormat: SimpleDateFormat,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val isCurrentlyAiring = program.isAiring

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                isCurrentlyAiring -> OpenFlixColors.Primary.copy(alpha = 0.2f)
                else -> OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
            },
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(12.dp)
            ),
            border = if (isCurrentlyAiring) {
                Border(
                    border = BorderStroke(2.dp, OpenFlixColors.Primary),
                    shape = RoundedCornerShape(12.dp)
                )
            } else {
                Border.None
            }
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            // Time slot
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                // NOW badge for current program
                if (isCurrentlyAiring) {
                    Box(
                        modifier = Modifier
                            .background(OpenFlixColors.LiveIndicator, RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "NOW",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                }

                Text(
                    text = "${timeFormat.format(Date(program.startTime * 1000))} - ${timeFormat.format(Date(program.endTime * 1000))}",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isCurrentlyAiring) Color.White else OpenFlixColors.TextSecondary
                )

                Spacer(modifier = Modifier.weight(1f))

                // Duration
                val durationMins = ((program.endTime - program.startTime) / 60).toInt()
                Text(
                    text = "${durationMins}m",
                    style = MaterialTheme.typography.labelSmall,
                    color = OpenFlixColors.TextTertiary
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Program title
            Text(
                text = program.displayTitle,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Medium,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            // Episode info or description
            program.episodeInfo?.let { epInfo ->
                Text(
                    text = epInfo,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.Primary,
                    maxLines = 1
                )
            }

            // Program description (if room)
            program.description?.let { desc ->
                if (desc.isNotBlank()) {
                    Text(
                        text = desc,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            // Badges
            if (program.badges.isNotEmpty()) {
                Spacer(modifier = Modifier.height(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    program.badges.take(3).forEach { badge ->
                        ProgramBadgeChip(badge = badge)
                    }
                }
            }

            // Progress bar for current program
            if (isCurrentlyAiring) {
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(OpenFlixColors.ProgressBackground, RoundedCornerShape(2.dp))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(program.progress)
                            .fillMaxHeight()
                            .background(OpenFlixColors.Primary, RoundedCornerShape(2.dp))
                    )
                }
            }
        }
    }
}

/**
 * Simple animated loading spinner that doesn't use problematic animation APIs
 */
@Composable
private fun LoadingSpinner(
    color: Color,
    modifier: Modifier = Modifier
) {
    var rotation by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(Unit) {
        while (true) {
            rotation = (rotation + 10f) % 360f
            delay(16) // ~60fps
        }
    }

    Canvas(modifier = modifier) {
        val strokeWidth = size.minDimension * 0.1f
        val radius = (size.minDimension - strokeWidth) / 2

        drawArc(
            color = color.copy(alpha = 0.3f),
            startAngle = 0f,
            sweepAngle = 360f,
            useCenter = false,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
            size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
            topLeft = androidx.compose.ui.geometry.Offset(
                (size.width - radius * 2) / 2,
                (size.height - radius * 2) / 2
            )
        )

        drawArc(
            color = color,
            startAngle = rotation,
            sweepAngle = 90f,
            useCenter = false,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
            size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
            topLeft = androidx.compose.ui.geometry.Offset(
                (size.width - radius * 2) / 2,
                (size.height - radius * 2) / 2
            )
        )
    }
}

/**
 * Recording feedback indicator - shows success/error messages for DVR recording
 */
@Composable
private fun RecordingIndicator(
    successMessage: String?,
    errorMessage: String?,
    isScheduling: Boolean,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Scheduling indicator
        AnimatedVisibility(
            visible = isScheduling,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Box(
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.85f),
                        RoundedCornerShape(12.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    LoadingSpinner(
                        color = OpenFlixColors.LiveIndicator,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "Scheduling recording...",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }

        // Success indicator
        AnimatedVisibility(
            visible = successMessage != null && !isScheduling,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Box(
                modifier = Modifier
                    .background(
                        OpenFlixColors.Success.copy(alpha = 0.9f),
                        RoundedCornerShape(12.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Record icon
                    Text(
                        text = "⏺",
                        fontSize = 20.sp,
                        color = Color.White
                    )
                    Text(
                        text = successMessage ?: "",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }

        // Error indicator
        AnimatedVisibility(
            visible = errorMessage != null && !isScheduling,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Box(
                modifier = Modifier
                    .background(
                        OpenFlixColors.Error.copy(alpha = 0.9f),
                        RoundedCornerShape(12.dp)
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Error icon
                    Text(
                        text = "⚠️",
                        fontSize = 20.sp
                    )
                    Text(
                        text = errorMessage ?: "",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }
    }
}

