package com.openflix.presentation.screens.livetv

import android.view.SurfaceView
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.vector.ImageVector
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

// Tivimate-style colors for multiview
private object MultiviewColors {
    val Background = Color(0xFF0A0A0F)
    val Surface = Color(0xFF1A1A24)
    val SurfaceLight = Color(0xFF2A2A38)
    val Accent = Color(0xFF00D9FF)
    val AccentGlow = Color(0xFF00D9FF).copy(alpha = 0.3f)
    val AccentRed = Color(0xFFFF3B5C)
    val AccentGreen = Color(0xFF10B981)
    val AccentGold = Color(0xFFFFB800)
    val AccentPurple = Color(0xFF8B5CF6)
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0C0)
    val TextMuted = Color(0xFF707088)
    val FocusBorder = Color(0xFF00D9FF)
}

/**
 * Tivimate-style Multi-view screen with proper TV focus handling.
 * Shows 2-4 channels simultaneously with D-pad navigation.
 */
@Composable
fun MultiviewScreen(
    initialChannelIds: List<String> = emptyList(),
    onBack: () -> Unit,
    onFullScreen: (Channel) -> Unit,
    viewModel: MultiviewViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Initialize slots when channels are loaded
    LaunchedEffect(uiState.allChannels) {
        if (uiState.allChannels.isNotEmpty() && uiState.slots.isEmpty()) {
            viewModel.initializeSlots(initialChannelIds)
        }
    }

    // Auto-hide controls timer
    LaunchedEffect(uiState.showControls) {
        if (uiState.showControls) {
            delay(8000)
            viewModel.hideControls()
        }
    }

    // Track whether we're in action bar mode or slot mode
    var isInActionBar by remember { mutableStateOf(false) }
    var actionBarButtonIndex by remember { mutableIntStateOf(0) }

    // Make the whole screen focusable to capture all key events
    val screenFocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        delay(100)
        screenFocusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MultiviewColors.Background)
            .focusRequester(screenFocusRequester)
            .focusable()
            .onPreviewKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown) {
                    viewModel.showControls()

                    // Calculate number of action buttons based on slots
                    // Buttons: Back, Fullscreen, Layout, StartOver/GoLive, [Add], [Remove], Swap, Mute
                    val maxButtonIndex = 4 + // Back, Fullscreen, Layout, StartOver/GoLive
                        (if (uiState.slots.size < 4) 1 else 0) + // Add
                        (if (uiState.slots.size > 1) 1 else 0) + // Remove
                        2 // Swap, Mute

                    // Grid-aware navigation for 2x2 layout
                    // Layout: [0][1]
                    //         [2][3]
                    val currentSlot = uiState.focusedSlotIndex
                    val slotCount = uiState.slots.size
                    val is2x2 = uiState.layout == MultiviewLayout.TWO_BY_TWO && slotCount == 4
                    val isThreeGrid = uiState.layout == MultiviewLayout.THREE_GRID && slotCount >= 3

                    fun getSlotLeft(): Int {
                        return when {
                            is2x2 -> when (currentSlot) {
                                1 -> 0
                                3 -> 2
                                else -> currentSlot
                            }
                            isThreeGrid -> when (currentSlot) {
                                1 -> 0
                                else -> currentSlot
                            }
                            else -> (currentSlot - 1).coerceAtLeast(0)
                        }
                    }

                    fun getSlotRight(): Int {
                        return when {
                            is2x2 -> when (currentSlot) {
                                0 -> 1
                                2 -> 3
                                else -> currentSlot
                            }
                            isThreeGrid -> when (currentSlot) {
                                0 -> 1
                                else -> currentSlot
                            }
                            else -> (currentSlot + 1).coerceAtMost(slotCount - 1)
                        }
                    }

                    fun getSlotUp(): Int? {
                        return when {
                            is2x2 -> when (currentSlot) {
                                2 -> 0
                                3 -> 1
                                else -> null // Already in top row
                            }
                            isThreeGrid -> when (currentSlot) {
                                2 -> 0 // Bottom slot goes to top-left
                                else -> null
                            }
                            else -> null
                        }
                    }

                    fun getSlotDown(): Int? {
                        return when {
                            is2x2 -> when (currentSlot) {
                                0 -> 2
                                1 -> 3
                                else -> null // Already in bottom row
                            }
                            isThreeGrid -> when (currentSlot) {
                                0, 1 -> 2 // Top row goes to bottom slot
                                else -> null
                            }
                            else -> null
                        }
                    }

                    when (event.key) {
                        Key.Escape, Key.Back -> {
                            if (isInActionBar) {
                                isInActionBar = false
                                true
                            } else {
                                onBack()
                                true
                            }
                        }
                        Key.DirectionUp -> {
                            if (isInActionBar) {
                                // Exit action bar, back to slots
                                isInActionBar = false
                            } else {
                                // Grid navigation: try to move up first, otherwise channel up
                                val slotUp = getSlotUp()
                                if (slotUp != null) {
                                    viewModel.setFocusedSlot(slotUp)
                                } else {
                                    // Channel up in current slot
                                    viewModel.changeChannelInSlot(currentSlot, -1)
                                }
                            }
                            true
                        }
                        Key.DirectionDown -> {
                            if (isInActionBar) {
                                // Already at bottom, do nothing
                            } else {
                                // Grid navigation: try to move down first
                                val slotDown = getSlotDown()
                                if (slotDown != null) {
                                    viewModel.setFocusedSlot(slotDown)
                                } else if (uiState.showControls) {
                                    // At bottom row with controls visible, enter action bar
                                    isInActionBar = true
                                    actionBarButtonIndex = 1 // Start at Fullscreen button
                                } else {
                                    // Channel down in current slot
                                    viewModel.changeChannelInSlot(currentSlot, 1)
                                }
                            }
                            true
                        }
                        Key.DirectionLeft -> {
                            if (isInActionBar) {
                                actionBarButtonIndex = (actionBarButtonIndex - 1).coerceAtLeast(0)
                            } else {
                                val newIndex = getSlotLeft()
                                if (newIndex != currentSlot) {
                                    viewModel.setFocusedSlot(newIndex)
                                }
                            }
                            true
                        }
                        Key.DirectionRight -> {
                            if (isInActionBar) {
                                actionBarButtonIndex = (actionBarButtonIndex + 1).coerceAtMost(maxButtonIndex - 1)
                            } else {
                                val newIndex = getSlotRight()
                                if (newIndex != currentSlot) {
                                    viewModel.setFocusedSlot(newIndex)
                                }
                            }
                            true
                        }
                        // Channel up/down with Page keys (alternative for channel surfing)
                        Key.PageUp, Key.ChannelUp -> {
                            viewModel.changeChannelInSlot(currentSlot, -1)
                            true
                        }
                        Key.PageDown, Key.ChannelDown -> {
                            viewModel.changeChannelInSlot(currentSlot, 1)
                            true
                        }
                        Key.Enter, Key.DirectionCenter -> {
                            if (isInActionBar) {
                                // Execute action based on button index
                                // Button order: Back, Fullscreen, Layout, StartOver/GoLive, [Add], [Remove], Swap, Mute
                                val hasAdd = uiState.slots.size < 4
                                val hasRemove = uiState.slots.size > 1
                                val focusedSlot = uiState.slots.getOrNull(currentSlot)
                                val isTimeshifted = focusedSlot?.isTimeshifted ?: false

                                when (actionBarButtonIndex) {
                                    0 -> onBack()
                                    1 -> focusedSlot?.let { onFullScreen(it.channel) }
                                    2 -> viewModel.cycleLayout()
                                    3 -> {
                                        // Start Over / Go Live
                                        if (isTimeshifted) {
                                            viewModel.goLiveSlot(currentSlot)
                                        } else {
                                            viewModel.startOverSlot(currentSlot)
                                        }
                                    }
                                    4 -> {
                                        if (hasAdd) viewModel.addSlot()
                                        else if (hasRemove) viewModel.removeSlot(currentSlot)
                                        else viewModel.showChannelPicker(currentSlot)
                                    }
                                    5 -> {
                                        if (hasAdd && hasRemove) viewModel.removeSlot(currentSlot)
                                        else if (hasAdd || hasRemove) viewModel.showChannelPicker(currentSlot)
                                        else viewModel.toggleMuteOnSlot(currentSlot)
                                    }
                                    6 -> {
                                        if (hasAdd && hasRemove) viewModel.showChannelPicker(currentSlot)
                                        else viewModel.toggleMuteOnSlot(currentSlot)
                                    }
                                    7 -> viewModel.toggleMuteOnSlot(currentSlot)
                                }
                                isInActionBar = false
                            } else {
                                // Go fullscreen on focused slot
                                uiState.slots.getOrNull(currentSlot)?.let { onFullScreen(it.channel) }
                            }
                            true
                        }
                        Key.M -> {
                            viewModel.toggleMuteOnSlot(currentSlot)
                            true
                        }
                        Key.G, Key.Menu -> {
                            isInActionBar = !isInActionBar
                            if (isInActionBar) actionBarButtonIndex = 1
                            true
                        }
                        // Number keys for quick channel change in slot
                        Key.Zero, Key.One, Key.Two, Key.Three, Key.Four,
                        Key.Five, Key.Six, Key.Seven, Key.Eight, Key.Nine -> {
                            // Could implement number channel entry here
                            false
                        }
                        else -> false
                    }
                } else false
            }
    ) {
        // Multiview grid - key handling is centralized at screen level
        MultiviewGridTV(
            slots = uiState.slots,
            layout = uiState.layout,
            focusedSlotIndex = uiState.focusedSlotIndex,
            showControls = uiState.showControls,
            viewModel = viewModel
        )

        // Bottom action bar - Tivimate style
        AnimatedVisibility(
            visible = uiState.showControls,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            MultiviewActionBar(
                slots = uiState.slots,
                focusedSlotIndex = uiState.focusedSlotIndex,
                layout = uiState.layout,
                isInActionBar = isInActionBar,
                actionBarButtonIndex = actionBarButtonIndex
            )
        }

        // Channel picker overlay
        if (uiState.channelPickerSlotIndex != null) {
            ChannelPickerOverlay(
                channels = uiState.allChannels,
                currentChannel = uiState.slots.getOrNull(uiState.channelPickerSlotIndex!!)?.channel,
                onChannelSelected = { channel ->
                    viewModel.swapChannel(uiState.channelPickerSlotIndex!!, channel)
                    viewModel.hideChannelPicker()
                },
                onDismiss = { viewModel.hideChannelPicker() }
            )
        }

        // Slot number indicators (top-left of each slot)
        if (uiState.showControls && uiState.slots.isNotEmpty()) {
            SlotNumberIndicators(
                slots = uiState.slots,
                layout = uiState.layout,
                focusedIndex = uiState.focusedSlotIndex
            )
        }
    }
}

@Composable
private fun MultiviewGridTV(
    slots: List<MultiviewSlot>,
    layout: MultiviewLayout,
    focusedSlotIndex: Int,
    showControls: Boolean,
    viewModel: MultiviewViewModel
) {
    when (layout) {
        MultiviewLayout.SINGLE -> {
            if (slots.isNotEmpty()) {
                FocusableSlot(
                    slot = slots[0],
                    index = 0,
                    player = viewModel.getPlayer(0),
                    isFocused = focusedSlotIndex == 0,
                    showInfo = showControls,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
        MultiviewLayout.TWO_BY_ONE -> {
            Row(modifier = Modifier.fillMaxSize()) {
                slots.take(2).forEachIndexed { index, slot ->
                    FocusableSlot(
                        slot = slot,
                        index = index,
                        player = viewModel.getPlayer(index),
                        isFocused = focusedSlotIndex == index,
                        showInfo = showControls,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    )
                }
            }
        }
        MultiviewLayout.ONE_BY_TWO -> {
            Column(modifier = Modifier.fillMaxSize()) {
                slots.take(2).forEachIndexed { index, slot ->
                    FocusableSlot(
                        slot = slot,
                        index = index,
                        player = viewModel.getPlayer(index),
                        isFocused = focusedSlotIndex == index,
                        showInfo = showControls,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                    )
                }
            }
        }
        MultiviewLayout.THREE_GRID -> {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.take(2).forEachIndexed { index, slot ->
                        FocusableSlot(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            isFocused = focusedSlotIndex == index,
                            showInfo = showControls,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
                if (slots.size > 2) {
                    FocusableSlot(
                        slot = slots[2],
                        index = 2,
                        player = viewModel.getPlayer(2),
                        isFocused = focusedSlotIndex == 2,
                        showInfo = showControls,
                        modifier = Modifier.weight(1f).fillMaxWidth()
                    )
                }
            }
        }
        MultiviewLayout.TWO_BY_TWO -> {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.take(2).forEachIndexed { index, slot ->
                        FocusableSlot(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            isFocused = focusedSlotIndex == index,
                            showInfo = showControls,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.drop(2).take(2).forEachIndexed { index, slot ->
                        val actualIndex = index + 2
                        FocusableSlot(
                            slot = slot,
                            index = actualIndex,
                            player = viewModel.getPlayer(actualIndex),
                            isFocused = focusedSlotIndex == actualIndex,
                            showInfo = showControls,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FocusableSlot(
    slot: MultiviewSlot,
    index: Int,
    player: MultiviewPlayer?,
    isFocused: Boolean,
    showInfo: Boolean,
    modifier: Modifier = Modifier
) {
    val isBuffering by player?.isBuffering?.collectAsState() ?: remember { mutableStateOf(false) }
    val isMuted by player?.isMuted?.collectAsState() ?: remember { mutableStateOf(true) }

    // Don't use focusable here - main screen handles all key events
    Box(
        modifier = modifier
            .padding(2.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(MultiviewColors.Surface)
            .border(
                width = if (isFocused) 3.dp else 1.dp,
                color = if (isFocused) MultiviewColors.FocusBorder else Color.Gray.copy(alpha = 0.3f),
                shape = RoundedCornerShape(8.dp)
            )
    ) {
            // Video surface
            if (player != null) {
                AndroidView(
                    factory = { ctx ->
                        SurfaceView(ctx).also { surface ->
                            player.setSurfaceView(surface)
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MultiviewColors.Surface),
                    contentAlignment = Alignment.Center
                ) {
                    LoadingIndicator()
                }
            }

            // Buffering indicator
            if (isBuffering) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.5f)),
                    contentAlignment = Alignment.Center
                ) {
                    LoadingIndicator()
                }
            }

            // Focus glow overlay
            if (isFocused) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .border(3.dp, MultiviewColors.FocusBorder, RoundedCornerShape(8.dp))
                )
            }

            // Channel info overlay (bottom)
            AnimatedVisibility(
                visible = showInfo || isFocused,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier.align(Alignment.BottomCenter)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Color.Black.copy(alpha = 0.9f)
                                )
                            )
                        )
                        .padding(12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Channel logo
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(6.dp))
                                .background(MultiviewColors.Surface),
                            contentAlignment = Alignment.Center
                        ) {
                            slot.channel.logoUrl?.let { logoUrl ->
                                AsyncImage(
                                    model = logoUrl,
                                    contentDescription = null,
                                    modifier = Modifier.size(32.dp),
                                    contentScale = ContentScale.Fit
                                )
                            } ?: Text(
                                text = slot.channel.number ?: "${index + 1}",
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                slot.channel.number?.let {
                                    Text(
                                        text = it,
                                        color = MultiviewColors.Accent,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                }
                                Text(
                                    text = slot.channel.name,
                                    color = Color.White,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 14.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                            slot.channel.nowPlaying?.let { program ->
                                Text(
                                    text = program.title,
                                    color = MultiviewColors.TextSecondary,
                                    fontSize = 12.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }

                        // Status indicators
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (!isMuted) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(4.dp))
                                        .background(MultiviewColors.AccentGreen)
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Icon(
                                        Icons.Default.VolumeUp,
                                        contentDescription = "Audio On",
                                        tint = Color.White,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                            }

                            // LIVE or START OVER badge
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(
                                        if (slot.isTimeshifted) MultiviewColors.AccentPurple
                                        else MultiviewColors.AccentRed
                                    )
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = if (slot.isTimeshifted) "START OVER" else "LIVE",
                                    color = Color.White,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }

            // Channel up/down hints when focused
            if (isFocused && showInfo) {
                Column(
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Default.KeyboardArrowUp,
                        contentDescription = "Channel Up",
                        tint = Color.White.copy(alpha = 0.7f),
                        modifier = Modifier.size(24.dp)
                    )
                    Text(
                        text = "CH",
                        color = Color.White.copy(alpha = 0.5f),
                        fontSize = 10.sp
                    )
                    Icon(
                        Icons.Default.KeyboardArrowDown,
                        contentDescription = "Channel Down",
                        tint = Color.White.copy(alpha = 0.7f),
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }

@Composable
private fun MultiviewActionBar(
    slots: List<MultiviewSlot>,
    focusedSlotIndex: Int,
    layout: MultiviewLayout,
    isInActionBar: Boolean,
    actionBarButtonIndex: Int
) {
    val focusedSlot = slots.getOrNull(focusedSlotIndex)
    val isMuted = focusedSlot?.isMuted ?: true

    // Build the list of action buttons dynamically
    data class ActionButtonData(
        val icon: ImageVector,
        val label: String,
        val color: Color
    )

    // Check if focused slot is timeshifted
    val isTimeshifted = focusedSlot?.isTimeshifted ?: false

    val buttons = buildList {
        add(ActionButtonData(Icons.Default.ArrowBack, "Back", MultiviewColors.TextSecondary))
        add(ActionButtonData(Icons.Default.Fullscreen, "Fullscreen", MultiviewColors.Accent))
        add(ActionButtonData(
            Icons.Default.GridView,
            when (layout) {
                MultiviewLayout.SINGLE -> "1x1"
                MultiviewLayout.TWO_BY_ONE -> "2x1"
                MultiviewLayout.ONE_BY_TWO -> "1x2"
                MultiviewLayout.THREE_GRID -> "2+1"
                MultiviewLayout.TWO_BY_TWO -> "2x2"
            },
            MultiviewColors.TextSecondary
        ))
        // Start Over / Go Live button
        if (isTimeshifted) {
            add(ActionButtonData(Icons.Default.PlayArrow, "Go Live", MultiviewColors.AccentGold))
        } else {
            add(ActionButtonData(Icons.Default.Replay, "Start Over", MultiviewColors.AccentPurple))
        }
        if (slots.size < 4) {
            add(ActionButtonData(Icons.Default.Add, "Add", MultiviewColors.AccentGreen))
        }
        if (slots.size > 1) {
            add(ActionButtonData(Icons.Default.Remove, "Remove", MultiviewColors.AccentRed))
        }
        add(ActionButtonData(Icons.Default.SwapHoriz, "Swap", MultiviewColors.TextSecondary))
        add(ActionButtonData(
            if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
            if (isMuted) "Unmute" else "Mute",
            if (!isMuted) MultiviewColors.AccentGreen else MultiviewColors.TextSecondary
        ))
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.95f)
                    )
                )
            )
            .padding(16.dp)
    ) {
        Column {
            // Hint text - shows different hints based on mode
            Text(
                text = if (isInActionBar) "◀ ▶ Select Button  •  ▲ Back to Slots  •  OK Confirm"
                       else "D-Pad Navigate Slots  •  CH+/- Change Channel  •  OK Fullscreen",
                color = MultiviewColors.TextMuted,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                buttons.forEachIndexed { index, button ->
                    if (index > 0) Spacer(modifier = Modifier.width(8.dp))
                    ActionButton(
                        icon = button.icon,
                        label = button.label,
                        color = button.color,
                        isHighlighted = isInActionBar && actionBarButtonIndex == index
                    )
                }
            }
        }
    }
}

@Composable
private fun ActionButton(
    icon: ImageVector,
    label: String,
    color: Color = MultiviewColors.TextSecondary,
    isHighlighted: Boolean = false
) {
    // Use visual highlight instead of Compose focus for action bar
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (isHighlighted) MultiviewColors.SurfaceLight else MultiviewColors.Surface)
            .border(
                width = if (isHighlighted) 2.dp else 0.dp,
                color = if (isHighlighted) MultiviewColors.Accent else Color.Transparent,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = if (isHighlighted) MultiviewColors.Accent else color,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = label,
                color = if (isHighlighted) Color.White else MultiviewColors.TextPrimary,
                fontSize = 11.sp,
                fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.Medium
            )
        }
    }
}

@Composable
private fun SlotNumberIndicators(
    slots: List<MultiviewSlot>,
    layout: MultiviewLayout,
    focusedIndex: Int
) {
    // Overlay slot numbers based on layout
    Box(modifier = Modifier.fillMaxSize()) {
        when (layout) {
            MultiviewLayout.TWO_BY_ONE -> {
                Row(modifier = Modifier.fillMaxSize()) {
                    repeat(minOf(2, slots.size)) { index ->
                        Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                            SlotNumberBadge(
                                number = index + 1,
                                isFocused = focusedIndex == index,
                                modifier = Modifier
                                    .align(Alignment.TopStart)
                                    .padding(12.dp)
                            )
                        }
                    }
                }
            }
            MultiviewLayout.TWO_BY_TWO -> {
                Column(modifier = Modifier.fillMaxSize()) {
                    Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                        repeat(minOf(2, slots.size)) { index ->
                            Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                                SlotNumberBadge(
                                    number = index + 1,
                                    isFocused = focusedIndex == index,
                                    modifier = Modifier
                                        .align(Alignment.TopStart)
                                        .padding(12.dp)
                                )
                            }
                        }
                    }
                    if (slots.size > 2) {
                        Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                            repeat(minOf(2, slots.size - 2)) { index ->
                                val actualIndex = index + 2
                                Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                                    SlotNumberBadge(
                                        number = actualIndex + 1,
                                        isFocused = focusedIndex == actualIndex,
                                        modifier = Modifier
                                            .align(Alignment.TopStart)
                                            .padding(12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            else -> {} // Other layouts don't need indicators for now
        }
    }
}

@Composable
private fun SlotNumberBadge(
    number: Int,
    isFocused: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(28.dp)
            .clip(CircleShape)
            .background(
                if (isFocused) MultiviewColors.Accent
                else Color.Black.copy(alpha = 0.7f)
            )
            .then(
                if (isFocused) Modifier.border(2.dp, Color.White, CircleShape)
                else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "$number",
            color = if (isFocused) Color.Black else Color.White,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun ChannelPickerOverlay(
    channels: List<Channel>,
    currentChannel: Channel?,
    onChannelSelected: (Channel) -> Unit,
    onDismiss: () -> Unit
) {
    val firstItemFocusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        delay(100)
        firstItemFocusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.9f))
            .onKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown && event.key == Key.Back) {
                    onDismiss()
                    true
                } else false
            },
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .width(500.dp)
                .fillMaxHeight(0.8f)
                .clip(RoundedCornerShape(16.dp))
                .background(MultiviewColors.Surface)
                .padding(20.dp)
        ) {
            Text(
                text = "Select Channel",
                color = Color.White,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(channels, key = { it.id }) { channel ->
                    val isSelected = channel.id == currentChannel?.id
                    val isFirst = channels.indexOf(channel) == 0

                    Surface(
                        onClick = { onChannelSelected(channel) },
                        modifier = if (isFirst) Modifier.focusRequester(firstItemFocusRequester) else Modifier,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = if (isSelected) MultiviewColors.Accent.copy(alpha = 0.2f)
                                           else MultiviewColors.SurfaceLight,
                            focusedContainerColor = MultiviewColors.Accent.copy(alpha = 0.3f)
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, MultiviewColors.Accent),
                                shape = RoundedCornerShape(8.dp)
                            )
                        )
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Channel logo
                            Box(
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(MultiviewColors.Background),
                                contentAlignment = Alignment.Center
                            ) {
                                channel.logoUrl?.let { url ->
                                    AsyncImage(
                                        model = url,
                                        contentDescription = null,
                                        modifier = Modifier.size(40.dp),
                                        contentScale = ContentScale.Fit
                                    )
                                } ?: Icon(
                                    Icons.Default.Tv,
                                    contentDescription = null,
                                    tint = MultiviewColors.TextMuted
                                )
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    channel.number?.let {
                                        Text(
                                            text = it,
                                            color = MultiviewColors.Accent,
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                    }
                                    Text(
                                        text = channel.name,
                                        color = Color.White,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Medium,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                                channel.nowPlaying?.let { program ->
                                    Text(
                                        text = program.title,
                                        color = MultiviewColors.TextSecondary,
                                        fontSize = 12.sp,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }

                            if (isSelected) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = "Selected",
                                    tint = MultiviewColors.Accent,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Surface(
                onClick = onDismiss,
                modifier = Modifier.align(Alignment.End),
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = MultiviewColors.SurfaceLight,
                    focusedContainerColor = MultiviewColors.AccentRed.copy(alpha = 0.3f)
                ),
                border = ClickableSurfaceDefaults.border(
                    focusedBorder = Border(
                        border = BorderStroke(2.dp, MultiviewColors.AccentRed),
                        shape = RoundedCornerShape(8.dp)
                    )
                )
            ) {
                Text(
                    text = "Cancel",
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                )
            }
        }
    }
}

@Composable
private fun LoadingIndicator() {
    val infiniteTransition = rememberInfiniteTransition(label = "loading")
    Row {
        repeat(3) { i ->
            val alpha by infiniteTransition.animateFloat(
                initialValue = 0.3f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(
                        durationMillis = 600,
                        delayMillis = i * 150,
                        easing = LinearEasing
                    ),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dot$i"
            )
            Box(
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .size(10.dp)
                    .clip(RoundedCornerShape(5.dp))
                    .background(Color.White.copy(alpha = alpha))
            )
        }
    }
}
