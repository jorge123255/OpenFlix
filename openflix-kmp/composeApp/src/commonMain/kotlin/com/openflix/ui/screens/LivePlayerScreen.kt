package com.openflix.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import com.openflix.ui.player.VideoSurface
import com.openflix.ui.util.platformUsesNativePlayer
import com.openflix.ui.viewmodel.LiveTVViewModel
import com.openflix.ui.viewmodel.PlayerViewModel
import kotlinx.coroutines.delay
import org.koin.compose.viewmodel.koinViewModel
import kotlin.math.absoluteValue

// ===== DESIGN TOKENS =====
private val Accent = Color(0xFF6C5CE7)
private val LiveRed = Color(0xFFFF3B5C)
private val SurfaceDark = Color(0xFF0D0B14)
private val GlassWhite = Color.White.copy(alpha = 0.08f)
private val GlassBorder = Color.White.copy(alpha = 0.12f)
private val TextDim = Color.White.copy(alpha = 0.45f)
private val TextMuted = Color.White.copy(alpha = 0.6f)

@Composable
fun LivePlayerScreen(
    channelId: String = "",
    channelName: String = "",
    channelNumber: String = "",
    channelLogo: String = "",
    streamUrl: String = "",
    archiveEnabled: Boolean = false,
    onBack: () -> Unit = {},
    viewModel: PlayerViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val isPlaying by viewModel.player.isPlaying.collectAsState()
    val isBuffering by viewModel.player.isBuffering.collectAsState()
    val videoResolution by viewModel.player.videoResolution.collectAsState()
    val liveTVViewModel: LiveTVViewModel = koinViewModel()
    val liveTVState by liveTVViewModel.uiState.collectAsState()

    var showMiniGuide by remember { mutableStateOf(false) }

    // Channel switching state
    val channels = liveTVState.channels
    val currentChannelIndex = remember(uiState.channelId, channels) {
        channels.indexOfFirst { it.id == uiState.channelId }.coerceAtLeast(0)
    }

    // Channel banner animation (shown briefly on switch)
    var showChannelBanner by remember { mutableStateOf(false) }
    LaunchedEffect(uiState.channelId) {
        if (uiState.channelId.isNotEmpty() && !uiState.isLoading) {
            showChannelBanner = true
            delay(3000)
            showChannelBanner = false
        }
    }

    // Double-tap skip feedback
    var skipLeftFeedback by remember { mutableStateOf(false) }
    var skipRightFeedback by remember { mutableStateOf(false) }

    // Load initial channel
    LaunchedEffect(channelId) {
        if (channelId.isNotEmpty()) {
            viewModel.loadChannel(channelId, channelName, channelNumber, channelLogo, streamUrl, archiveEnabled)
        }
    }

    // On iOS, live TV uses NativeLiveTVPlayer (full-screen modal).
    // Show black while it's active, navigate back when dismissed.
    if (platformUsesNativePlayer) {
        LaunchedEffect(Unit) {
            while (true) {
                delay(500)
                if (checkLiveTVPlayerDismissed()) {
                    onBack()
                    break
                }
            }
        }
        Box(modifier = Modifier.fillMaxSize().background(Color.Black))
        return
    }

    // Get program info from guide
    val currentProgram = liveTVViewModel.currentProgram(uiState.channelId)
    val nextProgram = liveTVViewModel.nextProgram(uiState.channelId)

    // Channel switch helper
    fun switchToChannel(channel: Channel) {
        ChannelStore.lastChannel = channel
        viewModel.switchChannel(
            channelId = channel.id,
            channelName = channel.name,
            channelNumber = channel.displayNumber,
            channelLogo = channel.logo ?: "",
            streamUrl = channel.streamUrl ?: "",
            archiveEnabled = channel.archiveEnabled
        )
    }

    fun channelUp() {
        if (channels.isEmpty()) return
        val next = (currentChannelIndex + 1) % channels.size
        switchToChannel(channels[next])
    }

    fun channelDown() {
        if (channels.isEmpty()) return
        val prev = if (currentChannelIndex <= 0) channels.size - 1 else currentChannelIndex - 1
        switchToChannel(channels[prev])
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // ===== VIDEO SURFACE =====
        if (!uiState.isLoading) {
            VideoSurface(player = viewModel.player, modifier = Modifier.fillMaxSize())
        }

        // ===== GESTURE LAYER =====
        if (!uiState.isLoading && uiState.error == null && !showMiniGuide) {
            var dragTotal by remember { mutableStateOf(0f) }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onTap = { offset ->
                                val width = size.width
                                val tapX = offset.x
                                // Single tap: toggle overlay
                                viewModel.toggleOverlay()
                            },
                            onDoubleTap = { offset ->
                                val width = size.width
                                val tapX = offset.x
                                if (tapX < width / 3f) {
                                    // Double-tap left: skip back 10s
                                    viewModel.skipBack()
                                    skipLeftFeedback = true
                                } else if (tapX > width * 2f / 3f) {
                                    // Double-tap right: skip forward 10s
                                    viewModel.skipForward()
                                    skipRightFeedback = true
                                }
                            }
                        )
                    }
                    .pointerInput(channels.size) {
                        detectHorizontalDragGestures(
                            onDragStart = { dragTotal = 0f },
                            onDragEnd = {
                                if (dragTotal.absoluteValue > 100f) {
                                    if (dragTotal > 0) channelDown() else channelUp()
                                }
                                dragTotal = 0f
                            },
                            onHorizontalDrag = { _, dragAmount ->
                                dragTotal += dragAmount
                            }
                        )
                    }
            )
        }

        // ===== DOUBLE-TAP SKIP FEEDBACK =====
        SkipFeedback(
            visible = skipLeftFeedback,
            text = "-10s",
            alignment = Alignment.CenterStart,
            onDone = { skipLeftFeedback = false }
        )
        SkipFeedback(
            visible = skipRightFeedback,
            text = "+10s",
            alignment = Alignment.CenterEnd,
            onDone = { skipRightFeedback = false }
        )

        // ===== LOADING STATE =====
        if (uiState.isLoading) {
            LoadingState(
                channelName = uiState.channelName,
                channelNumber = uiState.channelNumber,
                channelLogo = uiState.channelLogo.ifEmpty { channelLogo },
                onClose = onBack
            )
        }

        // ===== ERROR STATE =====
        uiState.error?.let { error ->
            ErrorState(
                error = error,
                onClose = onBack,
                onRetry = {
                    viewModel.loadChannel(
                        uiState.channelId.ifEmpty { channelId },
                        uiState.channelName,
                        uiState.channelNumber,
                        uiState.channelLogo,
                        streamUrl,
                        uiState.archiveEnabled
                    )
                }
            )
        }

        // ===== MID-STREAM BUFFERING / CHANNEL SWITCHING =====
        if (!uiState.isLoading && (isBuffering || uiState.isSwitchingChannel) && uiState.error == null) {
            Box(modifier = Modifier.align(Alignment.Center)) {
                CircularProgressIndicator(
                    color = Color.White.copy(alpha = 0.8f),
                    modifier = Modifier.size(40.dp),
                    strokeWidth = 2.5.dp
                )
            }
        }

        // ===== CHANNEL SWITCH BANNER =====
        AnimatedVisibility(
            visible = showChannelBanner && !uiState.isLoading && uiState.error == null && !uiState.showOverlay,
            enter = fadeIn(tween(200)) + slideInVertically(tween(300)) { -it },
            exit = fadeOut(tween(500)),
            modifier = Modifier
                .align(Alignment.TopCenter)
                .statusBarsPadding()
                .padding(top = 16.dp)
        ) {
            ChannelBanner(
                channelName = uiState.channelName,
                channelNumber = uiState.channelNumber,
                channelLogo = uiState.channelLogo.ifEmpty { channelLogo },
                resolution = videoResolution,
                programTitle = currentProgram?.title
            )
        }

        // ===== CONTROLS OVERLAY =====
        AnimatedVisibility(
            visible = uiState.showOverlay && !uiState.isLoading && uiState.error == null,
            enter = fadeIn(tween(200)),
            exit = fadeOut(tween(400))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            0f to Color.Black.copy(alpha = 0.75f),
                            0.2f to Color.Black.copy(alpha = 0.15f),
                            0.5f to Color.Transparent,
                            0.8f to Color.Black.copy(alpha = 0.15f),
                            1f to Color.Black.copy(alpha = 0.75f)
                        )
                    )
            ) {
                // ====== TOP BAR ======
                TopBar(
                    channelName = uiState.channelName,
                    channelNumber = uiState.channelNumber,
                    channelLogo = uiState.channelLogo.ifEmpty { channelLogo },
                    resolution = videoResolution,
                    currentProgram = currentProgram,
                    nextProgram = nextProgram,
                    onClose = onBack,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .fillMaxWidth()
                        .statusBarsPadding()
                )

                // ====== CENTER TRANSPORT ======
                CenterControls(
                    isPlaying = isPlaying,
                    onPlayPause = { viewModel.togglePlayPause() },
                    onSkipBack = { viewModel.skipBack() },
                    onSkipForward = { viewModel.skipForward() },
                    modifier = Modifier.align(Alignment.Center)
                )

                // ====== BOTTOM BAR ======
                BottomBar(
                    archiveEnabled = uiState.archiveEnabled,
                    onChannelDown = ::channelDown,
                    onChannelUp = ::channelUp,
                    onGuide = { showMiniGuide = true },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .navigationBarsPadding()
                )
            }
        }

        // ===== MINI GUIDE =====
        AnimatedVisibility(
            visible = showMiniGuide,
            enter = slideInVertically(tween(350, easing = FastOutSlowInEasing)) { it } + fadeIn(tween(250)),
            exit = slideOutVertically(tween(300)) { it } + fadeOut(tween(200)),
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            MiniGuidePanel(
                currentChannelId = uiState.channelId.ifEmpty { channelId },
                liveTVViewModel = liveTVViewModel,
                onChannelSelect = { channel ->
                    showMiniGuide = false
                    switchToChannel(channel)
                },
                onDismiss = { showMiniGuide = false }
            )
        }
    }
}

// ===== CHANNEL BANNER (shows briefly on channel switch) =====

@Composable
private fun ChannelBanner(
    channelName: String,
    channelNumber: String,
    channelLogo: String,
    resolution: String,
    programTitle: String?
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Color.Black.copy(alpha = 0.8f))
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        if (channelLogo.isNotEmpty()) {
            AsyncImage(
                model = channelLogo,
                contentDescription = null,
                modifier = Modifier.size(28.dp).clip(RoundedCornerShape(4.dp)),
                contentScale = ContentScale.Fit
            )
        }
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                if (channelNumber.isNotEmpty()) {
                    Text(channelNumber, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Accent)
                }
                Text(channelName, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                if (resolution.isNotEmpty()) {
                    ResolutionBadge(resolution)
                }
            }
            if (programTitle != null) {
                Text(programTitle, fontSize = 12.sp, color = TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

// ===== TOP BAR =====

@Composable
private fun TopBar(
    channelName: String,
    channelNumber: String,
    channelLogo: String,
    resolution: String,
    currentProgram: Program?,
    nextProgram: Program?,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(horizontal = 20.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Row 1: Close | Channel info | Resolution
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Close
            GlassCircle(size = 42.dp, onClick = onClose) {
                Icon(Icons.Default.Close, "Close", tint = Color.White, modifier = Modifier.size(20.dp))
            }

            // Channel info center
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (channelLogo.isNotEmpty()) {
                    AsyncImage(
                        model = channelLogo,
                        contentDescription = null,
                        modifier = Modifier.size(30.dp).clip(RoundedCornerShape(6.dp)),
                        contentScale = ContentScale.Fit
                    )
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = channelName,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            maxLines = 1
                        )
                        if (resolution.isNotEmpty()) {
                            ResolutionBadge(resolution)
                        }
                    }
                    if (channelNumber.isNotEmpty()) {
                        Text("CH $channelNumber", fontSize = 11.sp, color = TextDim, fontWeight = FontWeight.Medium)
                    }
                }
            }

            // Balance spacer
            Spacer(modifier = Modifier.size(42.dp))
        }

        // Row 2: Program info (now playing + next)
        if (currentProgram != null) {
            ProgramInfoBar(currentProgram = currentProgram, nextProgram = nextProgram)
        }
    }
}

// ===== PROGRAM INFO BAR =====

@Composable
private fun ProgramInfoBar(currentProgram: Program, nextProgram: Program?) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Color.Black.copy(alpha = 0.4f))
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        // Now playing
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Live dot
            val pulseAnim = rememberInfiniteTransition()
            val pulse by pulseAnim.animateFloat(
                initialValue = 0.5f, targetValue = 1f,
                animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse)
            )
            Box(
                modifier = Modifier.size(6.dp).clip(CircleShape)
                    .background(LiveRed.copy(alpha = pulse))
            )
            Text("NOW", fontSize = 10.sp, fontWeight = FontWeight.Black, color = LiveRed, letterSpacing = 1.sp)

            Text(
                text = currentProgram.title,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )

            // Time remaining
            val remaining = currentProgram.remainingMinutes
            if (remaining > 0) {
                Text(
                    "${remaining}m left",
                    fontSize = 11.sp,
                    color = TextMuted
                )
            }
        }

        // Program progress bar
        val progress = currentProgram.progress.toFloat()
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(3.dp)
                .clip(RoundedCornerShape(1.5.dp))
                .background(Color.White.copy(alpha = 0.15f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(progress)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(1.5.dp))
                    .background(LiveRed)
            )
        }

        // Up next
        if (nextProgram != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("NEXT", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = TextDim, letterSpacing = 1.sp)
                Text(
                    text = nextProgram.title,
                    fontSize = 12.sp,
                    color = TextDim,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = formatEpochTime(nextProgram.startTimeMs),
                    fontSize = 11.sp,
                    color = TextDim
                )
            }
        }
    }
}

// ===== CENTER CONTROLS =====

@Composable
private fun CenterControls(
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    onSkipBack: () -> Unit,
    onSkipForward: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(48.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Skip back
        GlassCircle(size = 64.dp, onClick = onSkipBack) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Default.Refresh, "Skip back", tint = Color.White, modifier = Modifier.size(24.dp))
                Text("10", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }
        }

        // Play / Pause hero button
        GlassCircle(size = 80.dp, bgAlpha = 0.25f, onClick = onPlayPause) {
            if (isPlaying) {
                // Pause bars
                Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    Box(Modifier.width(7.dp).height(32.dp).clip(RoundedCornerShape(2.dp)).background(Color.White))
                    Box(Modifier.width(7.dp).height(32.dp).clip(RoundedCornerShape(2.dp)).background(Color.White))
                }
            } else {
                Icon(Icons.Default.PlayArrow, "Play", tint = Color.White, modifier = Modifier.size(44.dp))
            }
        }

        // Skip forward
        GlassCircle(size = 64.dp, onClick = onSkipForward) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Default.Refresh, "Skip forward", tint = Color.White, modifier = Modifier.size(24.dp))
                Text("10", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }
        }
    }
}

// ===== BOTTOM BAR =====

@Composable
private fun BottomBar(
    archiveEnabled: Boolean,
    onChannelDown: () -> Unit,
    onChannelUp: () -> Unit,
    onGuide: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Live badge row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            LiveBadge()
            Text("Watching Live", fontSize = 12.sp, color = TextDim)
        }

        // Action bar: buttons in a glass tray
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(Color.White.copy(alpha = 0.06f))
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            ActionChip(icon = Icons.Default.KeyboardArrowDown, label = "CH-", onClick = onChannelDown)
            ActionChip(icon = Icons.Default.KeyboardArrowUp, label = "CH+", onClick = onChannelUp)
            ActionChip(icon = Icons.Default.Star, label = "Record", iconColor = LiveRed.copy(alpha = 0.8f), onClick = {})
            if (archiveEnabled) {
                ActionChip(icon = Icons.Default.Refresh, label = "Catch Up", onClick = {})
            }
            ActionChip(icon = Icons.AutoMirrored.Filled.List, label = "Guide", onClick = onGuide)
        }
    }
}

// ===== LOADING STATE =====

@Composable
private fun LoadingState(channelName: String, channelNumber: String, channelLogo: String, onClose: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        GlassCircle(
            size = 38.dp,
            onClick = onClose,
            modifier = Modifier.statusBarsPadding().padding(16.dp).align(Alignment.TopStart)
        ) {
            Icon(Icons.Default.Close, "Close", tint = Color.White, modifier = Modifier.size(18.dp))
        }

        Column(
            modifier = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Channel logo
            if (channelLogo.isNotEmpty()) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color.White.copy(alpha = 0.06f)),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = channelLogo,
                        contentDescription = null,
                        modifier = Modifier.size(56.dp),
                        contentScale = ContentScale.Fit
                    )
                }
            }

            CircularProgressIndicator(
                color = Accent,
                modifier = Modifier.size(36.dp),
                strokeWidth = 2.5.dp
            )

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                if (channelNumber.isNotEmpty()) {
                    Text("CH $channelNumber", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Accent)
                }
                if (channelName.isNotEmpty()) {
                    Text(channelName, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                }
                Text("Tuning...", fontSize = 13.sp, color = TextDim)
            }
        }
    }
}

// ===== ERROR STATE =====

@Composable
private fun ErrorState(error: String, onClose: () -> Unit, onRetry: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.95f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(Icons.Default.Warning, null, tint = Color(0xFFFFD700), modifier = Modifier.size(48.dp))
            Text("Unable to Play", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Text(
                error,
                fontSize = 14.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 24.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = onClose,
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White),
                    shape = RoundedCornerShape(10.dp)
                ) { Text("Close") }
                Button(
                    onClick = onRetry,
                    colors = ButtonDefaults.buttonColors(containerColor = Accent),
                    shape = RoundedCornerShape(10.dp)
                ) { Text("Retry") }
            }
        }
    }
}

// ===== SKIP FEEDBACK (double-tap ripple) =====

@Composable
private fun BoxScope.SkipFeedback(visible: Boolean, text: String, alignment: Alignment, onDone: () -> Unit) {
    LaunchedEffect(visible) {
        if (visible) {
            delay(600)
            onDone()
        }
    }

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(tween(100)) + scaleIn(tween(200), initialScale = 0.7f),
        exit = fadeOut(tween(300)),
        modifier = Modifier.align(alignment).padding(horizontal = 48.dp)
    ) {
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(text, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
        }
    }
}

// ===== LIVE BADGE =====

@Composable
private fun LiveBadge() {
    val transition = rememberInfiniteTransition()
    val pulse by transition.animateFloat(
        initialValue = 0.4f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse)
    )

    Row(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(LiveRed.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Box(modifier = Modifier.size(7.dp).clip(CircleShape).background(LiveRed.copy(alpha = pulse)))
        Text("LIVE", fontSize = 12.sp, fontWeight = FontWeight.Black, color = LiveRed, letterSpacing = 1.sp)
    }
}

// ===== GLASS CIRCLE BUTTON =====

@Composable
private fun GlassCircle(
    size: Dp = 44.dp,
    bgAlpha: Float = 0.2f,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = bgAlpha))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
        content = content
    )
}

// ===== RESOLUTION BADGE =====

@Composable
private fun ResolutionBadge(resolution: String) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(4.dp))
            .background(Color.White.copy(alpha = 0.15f))
            .padding(horizontal = 5.dp, vertical = 1.dp)
    ) {
        Text(resolution, fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.7f))
    }
}

// ===== ACTION CHIP =====

@Composable
private fun ActionChip(
    icon: ImageVector,
    label: String,
    iconColor: Color = Color.White,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Icon(icon, label, tint = iconColor, modifier = Modifier.size(22.dp))
        Text(label, fontSize = 10.sp, color = TextMuted, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center)
    }
}

// ===== MINI GUIDE PANEL (multi-channel) =====

@Composable
private fun MiniGuidePanel(
    currentChannelId: String,
    liveTVViewModel: LiveTVViewModel,
    onChannelSelect: (Channel) -> Unit,
    onDismiss: () -> Unit
) {
    val uiState by liveTVViewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        if (uiState.guide.isEmpty()) {
            liveTVViewModel.loadChannels()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .fillMaxHeight(0.55f)
            .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
            .background(SurfaceDark)
    ) {
        Column {
            // Drag handle
            Box(
                modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier.width(36.dp).height(4.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(Color.White.copy(alpha = 0.2f))
                )
            }

            // Header
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Guide", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)

                GlassCircle(size = 30.dp, onClick = onDismiss) {
                    Icon(Icons.Default.Close, "Close", tint = Color.White, modifier = Modifier.size(15.dp))
                }
            }

            HorizontalDivider(color = GlassBorder, thickness = 0.5.dp)

            // Channel list with programs
            val channels = uiState.channels
            if (channels.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        CircularProgressIndicator(color = Accent, modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
                        Text("Loading channels...", color = TextDim, fontSize = 13.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 4.dp)
                ) {
                    items(channels) { channel ->
                        val isCurrent = channel.id == currentChannelId
                        val program = liveTVViewModel.currentProgram(channel.id)

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .then(
                                    if (isCurrent) Modifier.background(Accent.copy(alpha = 0.1f))
                                    else Modifier
                                )
                                .clickable { onChannelSelect(channel) }
                                .padding(horizontal = 20.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Channel number
                            Text(
                                text = channel.displayNumber,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (isCurrent) Accent else TextMuted,
                                modifier = Modifier.width(40.dp)
                            )

                            // Logo
                            if (channel.logo != null) {
                                AsyncImage(
                                    model = channel.logo,
                                    contentDescription = null,
                                    modifier = Modifier.size(width = 36.dp, height = 24.dp).padding(end = 10.dp),
                                    contentScale = ContentScale.Fit
                                )
                            } else {
                                Spacer(modifier = Modifier.width(36.dp).padding(end = 10.dp))
                            }

                            // Channel name + program
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = channel.name,
                                    fontSize = 14.sp,
                                    fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isCurrent) Color.White else Color.White.copy(alpha = 0.85f),
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                if (program != null) {
                                    Text(
                                        text = program.title,
                                        fontSize = 12.sp,
                                        color = TextDim,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }

                            // Current indicator
                            if (isCurrent) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(Accent)
                                )
                            }
                        }

                        if (!isCurrent) {
                            HorizontalDivider(color = GlassBorder, thickness = 0.5.dp, modifier = Modifier.padding(horizontal = 20.dp))
                        }
                    }
                }
            }
        }
    }
}

// ===== UTILITIES =====

private fun formatEpochTime(epochMs: Long): String {
    val totalSeconds = epochMs / 1000
    val secondsInDay = totalSeconds % 86400
    val hours = ((secondsInDay / 3600) % 24).toInt()
    val minutes = ((secondsInDay % 3600) / 60).toInt()
    val displayHour = if (hours == 0) 12 else if (hours > 12) hours - 12 else hours
    val amPm = if (hours < 12) "AM" else "PM"
    return "$displayHour:${minutes.toString().padStart(2, '0')} $amPm"
}
