package com.openflix.presentation.screens.livetv

import android.util.Log
import android.view.SurfaceView
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.player.MultiviewPlayer
import kotlinx.coroutines.delay

/**
 * YouTube TV-style Multiview Screen.
 *
 * UX MATCHES YTTV:
 * - 2x2 grid of live streams (or 2x1 if only 2 channels)
 * - D-pad navigates between quadrants; audio follows focus automatically
 * - White border indicates which view has audio
 * - OK/Select = expand focused view to fullscreen
 * - Back = return to grid (or exit multiview if already in grid)
 * - Long-press OK = open channel picker for focused slot
 * - CH+/CH- = cycle channel in focused slot
 * - Minimal overlay: channel name shown briefly, then auto-hides
 * - No help bar, no slot numbers, no layout indicator
 */
@Composable
fun MultiviewScreenV2(
    initialChannelIds: List<String> = emptyList(),
    onBack: () -> Unit,
    onFullScreen: (Channel) -> Unit,
    viewModel: MultiviewViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    var showChannelPicker by remember { mutableStateOf(false) }
    var okHeldStartTime by remember { mutableLongStateOf(0L) }

    // Initialize slots
    LaunchedEffect(uiState.allChannels) {
        if (uiState.allChannels.isNotEmpty() && uiState.slots.isEmpty()) {
            viewModel.initializeSlots(initialChannelIds)
        }
    }

    // Auto-hide overlay after 3 seconds (YTTV behavior)
    LaunchedEffect(uiState.showOverlay) {
        if (uiState.showOverlay) {
            delay(3000)
            viewModel.hideOverlay()
        }
    }

    val screenFocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        delay(100)
        screenFocusRequester.requestFocus()
    }

    // 2x2 grid navigation
    fun getSlotInDirection(current: Int, direction: Int): Int {
        val slotCount = uiState.slots.size
        val is2x2 = slotCount == 4

        return when (direction) {
            0 -> { // Up
                if (is2x2 && current >= 2) current - 2 else current
            }
            1 -> { // Down
                if (is2x2 && current < 2 && current + 2 < slotCount) current + 2 else current
            }
            2 -> { // Left
                if (is2x2) {
                    when (current) { 1 -> 0; 3 -> 2; else -> current }
                } else if (current > 0) current - 1 else current
            }
            3 -> { // Right
                if (is2x2) {
                    when (current) { 0 -> 1; 2 -> 3.coerceAtMost(slotCount - 1); else -> current }
                } else if (current < slotCount - 1) current + 1 else current
            }
            else -> current
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(screenFocusRequester)
            .focusable()
            .onPreviewKeyEvent { event ->
                val current = uiState.focusedSlotIndex

                // Track OK button hold time for long-press detection
                if (event.key == Key.Enter || event.key == Key.DirectionCenter) {
                    if (event.type == KeyEventType.KeyDown) {
                        if (okHeldStartTime == 0L) okHeldStartTime = System.currentTimeMillis()
                    } else if (event.type == KeyEventType.KeyUp) {
                        val holdDuration = System.currentTimeMillis() - okHeldStartTime
                        okHeldStartTime = 0L

                        if (holdDuration > 500 && !showChannelPicker) {
                            // Long-press = open channel picker
                            showChannelPicker = true
                            return@onPreviewKeyEvent true
                        }
                    }
                }

                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false

                // Any key press shows the overlay briefly
                viewModel.showOverlay()

                when (event.key) {
                    Key.Escape, Key.Back -> {
                        when {
                            showChannelPicker -> { showChannelPicker = false; true }
                            uiState.isFullscreen -> { viewModel.exitFullscreen(); true }
                            else -> { onBack(); true }
                        }
                    }

                    // D-PAD: Navigate between quadrants. Audio follows focus.
                    Key.DirectionUp -> {
                        if (showChannelPicker) return@onPreviewKeyEvent false
                        if (uiState.isFullscreen) return@onPreviewKeyEvent true
                        val next = getSlotInDirection(current, 0)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }
                    Key.DirectionDown -> {
                        if (showChannelPicker) return@onPreviewKeyEvent false
                        if (uiState.isFullscreen) return@onPreviewKeyEvent true
                        val next = getSlotInDirection(current, 1)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }
                    Key.DirectionLeft -> {
                        if (showChannelPicker) return@onPreviewKeyEvent false
                        if (uiState.isFullscreen) return@onPreviewKeyEvent true
                        val next = getSlotInDirection(current, 2)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }
                    Key.DirectionRight -> {
                        if (showChannelPicker) return@onPreviewKeyEvent false
                        if (uiState.isFullscreen) return@onPreviewKeyEvent true
                        val next = getSlotInDirection(current, 3)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }

                    // OK/Select = fullscreen (YTTV behavior)
                    Key.Enter, Key.DirectionCenter -> {
                        when {
                            showChannelPicker -> return@onPreviewKeyEvent false
                            uiState.isFullscreen -> {
                                // Already fullscreen - exit back to grid
                                viewModel.exitFullscreen()
                            }
                            else -> {
                                // Enter fullscreen for focused slot
                                viewModel.enterFullscreen()
                            }
                        }
                        true
                    }

                    // CH+/CH- = cycle channel in focused slot
                    Key.PageUp, Key.ChannelUp, Key.MediaPrevious -> {
                        val target = uiState.fullscreenSlotIndex ?: current
                        viewModel.changeChannelInSlot(target, -1)
                        true
                    }
                    Key.PageDown, Key.ChannelDown, Key.MediaNext -> {
                        val target = uiState.fullscreenSlotIndex ?: current
                        viewModel.changeChannelInSlot(target, 1)
                        true
                    }

                    // Hardware remote buttons
                    Key.Info, Key(android.view.KeyEvent.KEYCODE_INFO.toLong()) -> {
                        viewModel.showOverlay()
                        true
                    }
                    Key.Guide, Key(android.view.KeyEvent.KEYCODE_GUIDE.toLong()),
                    Key(android.view.KeyEvent.KEYCODE_TV_DATA_SERVICE.toLong()) -> {
                        onBack()
                        true
                    }

                    else -> {
                        val nativeCode = event.nativeKeyEvent.keyCode
                        Log.d("MultiviewV2", "Unhandled key: ${event.key}, nativeCode=$nativeCode")
                        when (nativeCode) {
                            166, 188 -> {
                                val target = uiState.fullscreenSlotIndex ?: current
                                viewModel.changeChannelInSlot(target, -1)
                                true
                            }
                            167, 189 -> {
                                val target = uiState.fullscreenSlotIndex ?: current
                                viewModel.changeChannelInSlot(target, 1)
                                true
                            }
                            else -> false
                        }
                    }
                }
            }
    ) {
        // Main grid / fullscreen view
        if (uiState.isFullscreen) {
            // FULLSCREEN: Show only the selected slot
            val fsIndex = uiState.fullscreenSlotIndex ?: uiState.focusedSlotIndex
            uiState.slots.getOrNull(fsIndex)?.let { slot ->
                MultiviewSlotView(
                    slot = slot,
                    index = fsIndex,
                    player = viewModel.getPlayer(fsIndex),
                    hasAudio = true,
                    isFocused = true,
                    showOverlay = uiState.showOverlay,
                    isFullscreen = true,
                    modifier = Modifier.fillMaxSize()
                )
            }
        } else {
            // GRID: 2x2 (or 2x1 / 3-grid depending on slot count)
            MultiviewGrid(
                slots = uiState.slots,
                focusedSlotIndex = uiState.focusedSlotIndex,
                audioSlotIndex = uiState.audioSlotIndex,
                showOverlay = uiState.showOverlay,
                viewModel = viewModel
            )
        }

        // Channel picker overlay (long-press OK)
        if (showChannelPicker) {
            ChannelPickerOverlay(
                channels = uiState.allChannels,
                currentChannel = uiState.slots.getOrNull(uiState.focusedSlotIndex)?.channel,
                onSelect = { channel ->
                    val target = if (uiState.isFullscreen)
                        uiState.fullscreenSlotIndex ?: uiState.focusedSlotIndex
                    else
                        uiState.focusedSlotIndex
                    viewModel.swapChannel(target, channel)
                    showChannelPicker = false
                },
                onDismiss = { showChannelPicker = false }
            )
        }
    }
}

// ── Grid Layout ──────────────────────────────────────────────────────────────

@Composable
private fun MultiviewGrid(
    slots: List<MultiviewSlot>,
    focusedSlotIndex: Int,
    audioSlotIndex: Int,
    showOverlay: Boolean,
    viewModel: MultiviewViewModel
) {
    when (slots.size) {
        0 -> { /* Empty */ }
        1 -> {
            MultiviewSlotView(
                slot = slots[0],
                index = 0,
                player = viewModel.getPlayer(0),
                hasAudio = audioSlotIndex == 0,
                isFocused = focusedSlotIndex == 0,
                showOverlay = showOverlay,
                modifier = Modifier.fillMaxSize()
            )
        }
        2 -> {
            // Side by side
            Row(modifier = Modifier.fillMaxSize()) {
                slots.forEachIndexed { index, slot ->
                    MultiviewSlotView(
                        slot = slot,
                        index = index,
                        player = viewModel.getPlayer(index),
                        hasAudio = audioSlotIndex == index,
                        isFocused = focusedSlotIndex == index,
                        showOverlay = showOverlay,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    )
                }
            }
        }
        3 -> {
            // 2 top, 1 bottom
            Column(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.take(2).forEachIndexed { index, slot ->
                        MultiviewSlotView(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            hasAudio = audioSlotIndex == index,
                            isFocused = focusedSlotIndex == index,
                            showOverlay = showOverlay,
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                        )
                    }
                }
                MultiviewSlotView(
                    slot = slots[2],
                    index = 2,
                    player = viewModel.getPlayer(2),
                    hasAudio = audioSlotIndex == 2,
                    isFocused = focusedSlotIndex == 2,
                    showOverlay = showOverlay,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                )
            }
        }
        else -> {
            // 2x2 grid (YTTV default)
            Column(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.take(2).forEachIndexed { index, slot ->
                        MultiviewSlotView(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            hasAudio = audioSlotIndex == index,
                            isFocused = focusedSlotIndex == index,
                            showOverlay = showOverlay,
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                        )
                    }
                }
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.drop(2).take(2).forEachIndexed { index, slot ->
                        val actualIndex = index + 2
                        MultiviewSlotView(
                            slot = slot,
                            index = actualIndex,
                            player = viewModel.getPlayer(actualIndex),
                            hasAudio = audioSlotIndex == actualIndex,
                            isFocused = focusedSlotIndex == actualIndex,
                            showOverlay = showOverlay,
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                        )
                    }
                }
            }
        }
    }
}

// ── Slot View ────────────────────────────────────────────────────────────────

@Composable
private fun MultiviewSlotView(
    slot: MultiviewSlot,
    index: Int,
    player: MultiviewPlayer?,
    hasAudio: Boolean,
    isFocused: Boolean,
    showOverlay: Boolean,
    isFullscreen: Boolean = false,
    modifier: Modifier = Modifier
) {
    val isBuffering by player?.isBuffering?.collectAsState() ?: remember { mutableStateOf(false) }

    // YTTV-style: white border on audio source, thin gap between views
    val borderWidth by animateDpAsState(
        targetValue = if (hasAudio && !isFullscreen) 3.dp else 0.dp,
        animationSpec = tween(150),
        label = "borderWidth"
    )

    Box(
        modifier = modifier
            .padding(if (isFullscreen) 0.dp else 2.dp) // Thin black gap between views
            .then(
                if (hasAudio && !isFullscreen) {
                    Modifier.border(
                        width = borderWidth,
                        color = Color.White,
                        shape = RoundedCornerShape(0.dp)
                    )
                } else Modifier
            )
            .background(Color(0xFF111111))
    ) {
        // Video surface
        if (player != null) {
            AndroidView(
                factory = { ctx ->
                    SurfaceView(ctx).also { player.setSurfaceView(it) }
                },
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Box(
                modifier = Modifier.fillMaxSize().background(Color(0xFF111111)),
                contentAlignment = Alignment.Center
            ) {
                LoadingDots()
            }
        }

        // Buffering spinner
        if (isBuffering) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                LoadingDots()
            }
        }

        // Channel info overlay (YTTV-style: brief, minimal, bottom-left)
        AnimatedVisibility(
            visible = showOverlay || (isFocused && !isFullscreen),
            enter = fadeIn(tween(200)),
            exit = fadeOut(tween(400)),
            modifier = Modifier.align(Alignment.BottomStart)
        ) {
            ChannelInfoBadge(
                slot = slot,
                hasAudio = hasAudio,
                isFullscreen = isFullscreen
            )
        }

        // Audio indicator - small white speaker icon (top-right, YTTV-style)
        AnimatedVisibility(
            visible = hasAudio && !isFullscreen,
            enter = fadeIn(tween(200)),
            exit = fadeOut(tween(300)),
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.Black.copy(alpha = 0.6f))
                    .padding(6.dp)
            ) {
                Icon(
                    Icons.Default.VolumeUp,
                    contentDescription = "Audio active",
                    tint = Color.White,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

// ── Channel Info Badge ───────────────────────────────────────────────────────

@Composable
private fun ChannelInfoBadge(
    slot: MultiviewSlot,
    hasAudio: Boolean,
    isFullscreen: Boolean
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f))
                )
            )
            .padding(
                start = if (isFullscreen) 24.dp else 12.dp,
                end = if (isFullscreen) 24.dp else 12.dp,
                top = 24.dp,
                bottom = if (isFullscreen) 16.dp else 10.dp
            )
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            // Channel logo
            slot.channel.logoUrl?.let { url ->
                Box(
                    modifier = Modifier
                        .size(if (isFullscreen) 44.dp else 32.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color(0xFF222222)),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = url,
                        contentDescription = null,
                        modifier = Modifier.size(if (isFullscreen) 36.dp else 26.dp),
                        contentScale = ContentScale.Fit
                    )
                }
                Spacer(modifier = Modifier.width(if (isFullscreen) 12.dp else 8.dp))
            }

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    slot.channel.number?.let { num ->
                        Text(
                            text = num,
                            color = Color.White.copy(alpha = 0.7f),
                            fontSize = if (isFullscreen) 16.sp else 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                    }
                    Text(
                        text = slot.channel.name,
                        color = Color.White,
                        fontSize = if (isFullscreen) 18.sp else 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                slot.channel.nowPlaying?.let { program ->
                    Text(
                        text = program.title,
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = if (isFullscreen) 14.sp else 11.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // LIVE badge
            if (isFullscreen) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(
                            if (slot.isTimeshifted) Color(0xFF8B5CF6) else Color(0xFFFF3B5C)
                        )
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = if (slot.isTimeshifted) "DVR" else "LIVE",
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

// ── Channel Picker (long-press overlay) ──────────────────────────────────────

@Composable
private fun ChannelPickerOverlay(
    channels: List<Channel>,
    currentChannel: Channel?,
    onSelect: (Channel) -> Unit,
    onDismiss: () -> Unit
) {
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        delay(100)
        focusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .onKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown && event.key == Key.Back) {
                    onDismiss()
                    true
                } else false
            },
        contentAlignment = Alignment.CenterEnd
    ) {
        // Side panel (YTTV-style - slides in from right)
        Column(
            modifier = Modifier
                .width(400.dp)
                .fillMaxHeight()
                .background(Color(0xFF1A1A1A))
                .padding(20.dp)
        ) {
            Text(
                text = "Change Channel",
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "${channels.size} channels available",
                color = Color.White.copy(alpha = 0.5f),
                fontSize = 13.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                items(channels, key = { it.id }) { channel ->
                    val isCurrent = channel.id == currentChannel?.id
                    val isFirst = channels.indexOf(channel) == 0

                    Surface(
                        onClick = { onSelect(channel) },
                        modifier = if (isFirst) Modifier.focusRequester(focusRequester) else Modifier,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = if (isCurrent) Color.White.copy(alpha = 0.15f)
                            else Color.Transparent,
                            focusedContainerColor = Color.White.copy(alpha = 0.2f)
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, Color.White),
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
                            // Logo
                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(Color(0xFF222222)),
                                contentAlignment = Alignment.Center
                            ) {
                                channel.logoUrl?.let { url ->
                                    AsyncImage(
                                        model = url,
                                        contentDescription = null,
                                        modifier = Modifier.size(32.dp),
                                        contentScale = ContentScale.Fit
                                    )
                                } ?: Icon(
                                    Icons.Default.Tv,
                                    contentDescription = null,
                                    tint = Color.White.copy(alpha = 0.4f)
                                )
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    channel.number?.let { num ->
                                        Text(
                                            text = num,
                                            color = Color.White.copy(alpha = 0.6f),
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                    }
                                    Text(
                                        text = channel.name,
                                        color = Color.White,
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Medium,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                                channel.nowPlaying?.let { program ->
                                    Text(
                                        text = program.title,
                                        color = Color.White.copy(alpha = 0.4f),
                                        fontSize = 12.sp,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }

                            if (isCurrent) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = "Current",
                                    tint = Color.White,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// ── Loading Animation ────────────────────────────────────────────────────────

@Composable
private fun LoadingDots() {
    val infiniteTransition = rememberInfiniteTransition(label = "loading")
    Row {
        repeat(3) { i ->
            val alpha by infiniteTransition.animateFloat(
                initialValue = 0.3f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(500, delayMillis = i * 100),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dot$i"
            )
            Box(
                modifier = Modifier
                    .padding(horizontal = 3.dp)
                    .size(8.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.White.copy(alpha = alpha))
            )
        }
    }
}
