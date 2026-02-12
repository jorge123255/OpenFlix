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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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

// Clean colors
private object MV2Colors {
    val Background = Color(0xFF0A0A0F)
    val Surface = Color(0xFF1A1A24)
    val SurfaceGlass = Color(0xFF1A1A24).copy(alpha = 0.85f)
    val Accent = Color(0xFF00D4AA) // OpenFlix teal
    val AccentGlow = Color(0xFF00D4AA).copy(alpha = 0.4f)
    val Live = Color(0xFFFF3B5C)
    val Audio = Color(0xFF10B981)
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0C0)
    val TextMuted = Color(0xFF606070)
    val FocusBorder = Color(0xFF00D4AA)
}

/**
 * Multiview V2 - Simplified controls
 * 
 * NAVIGATION:
 * - D-pad arrows: Move between slots (never changes channel)
 * - OK/Select: Open channel picker for focused slot
 * - CH+/CH- or Page Up/Down: Change channel in focused slot
 * - Back: Exit multiview
 * 
 * QUICK ACTIONS:
 * - M: Toggle mute/unmute on focused slot
 * - 1-4: Jump audio to slot number
 * - Double-tap OK: Go fullscreen
 * - Long-press OK (500ms): Enter swap mode
 */
@Composable
fun MultiviewScreenV2(
    initialChannelIds: List<String> = emptyList(),
    onBack: () -> Unit,
    onFullScreen: (Channel) -> Unit,
    viewModel: MultiviewViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // UI state
    var showChannelPicker by remember { mutableStateOf(false) }
    var showQuickStrip by remember { mutableStateOf(false) }
    var quickStripIndex by remember { mutableIntStateOf(0) }
    var swapMode by remember { mutableStateOf(false) }
    var swapSourceSlot by remember { mutableIntStateOf(-1) }
    var lastOkPressTime by remember { mutableLongStateOf(0L) }
    var okHeldStartTime by remember { mutableLongStateOf(0L) }
    
    // Initialize
    LaunchedEffect(uiState.allChannels) {
        if (uiState.allChannels.isNotEmpty() && uiState.slots.isEmpty()) {
            viewModel.initializeSlots(initialChannelIds)
        }
    }
    
    // Auto-hide controls
    LaunchedEffect(uiState.showControls) {
        if (uiState.showControls) {
            delay(5000)
            viewModel.hideControls()
        }
    }
    
    // Auto-hide quick strip
    LaunchedEffect(showQuickStrip) {
        if (showQuickStrip) {
            delay(4000)
            showQuickStrip = false
        }
    }
    
    val screenFocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        delay(100)
        screenFocusRequester.requestFocus()
    }
    
    // Grid navigation helpers
    fun getSlotInDirection(current: Int, direction: Int): Int {
        val slots = uiState.slots.size
        val is2x2 = uiState.layout == MultiviewLayout.TWO_BY_TWO && slots == 4
        
        return when (direction) {
            0 -> { // Up
                if (is2x2 && current >= 2) current - 2
                else current
            }
            1 -> { // Down
                if (is2x2 && current < 2 && current + 2 < slots) current + 2
                else current
            }
            2 -> { // Left
                if (is2x2) {
                    when (current) { 1 -> 0; 3 -> 2; else -> current }
                } else (current - 1).coerceAtLeast(0)
            }
            3 -> { // Right
                if (is2x2) {
                    when (current) { 0 -> 1; 2 -> 3.coerceAtMost(slots - 1); else -> current }
                } else (current + 1).coerceAtMost(slots - 1)
            }
            else -> current
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MV2Colors.Background)
            .focusRequester(screenFocusRequester)
            .focusable()
            .onPreviewKeyEvent { event ->
                val current = uiState.focusedSlotIndex
                
                // Track OK button hold time
                if (event.key == Key.Enter || event.key == Key.DirectionCenter) {
                    if (event.type == KeyEventType.KeyDown) {
                        if (okHeldStartTime == 0L) okHeldStartTime = System.currentTimeMillis()
                    } else if (event.type == KeyEventType.KeyUp) {
                        val holdDuration = System.currentTimeMillis() - okHeldStartTime
                        okHeldStartTime = 0L
                        
                        // Long press = swap mode
                        if (holdDuration > 500 && !showChannelPicker) {
                            if (!swapMode) {
                                swapMode = true
                                swapSourceSlot = current
                            } else {
                                // Complete swap
                                viewModel.swapSlots(swapSourceSlot, current)
                                swapMode = false
                                swapSourceSlot = -1
                            }
                            return@onPreviewKeyEvent true
                        }
                    }
                }
                
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                
                viewModel.showControls()
                
                when (event.key) {
                    Key.Escape, Key.Back -> {
                        when {
                            showChannelPicker -> { showChannelPicker = false; true }
                            showQuickStrip -> { showQuickStrip = false; true }
                            swapMode -> { swapMode = false; swapSourceSlot = -1; true }
                            else -> { onBack(); true }
                        }
                    }
                    
                    // NAVIGATION - D-pad moves between slots, never changes channel
                    Key.DirectionUp -> {
                        if (showChannelPicker || showQuickStrip) return@onPreviewKeyEvent false
                        val next = getSlotInDirection(current, 0)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }
                    Key.DirectionDown -> {
                        if (showChannelPicker || showQuickStrip) return@onPreviewKeyEvent false
                        val next = getSlotInDirection(current, 1)
                        if (next != current) viewModel.setFocusedSlot(next)
                        true
                    }
                    Key.DirectionLeft -> {
                        when {
                            showQuickStrip -> {
                                quickStripIndex = (quickStripIndex - 1).coerceAtLeast(0)
                            }
                            showChannelPicker -> return@onPreviewKeyEvent false
                            else -> {
                                val next = getSlotInDirection(current, 2)
                                if (next != current) viewModel.setFocusedSlot(next)
                            }
                        }
                        true
                    }
                    Key.DirectionRight -> {
                        when {
                            showQuickStrip -> {
                                quickStripIndex = (quickStripIndex + 1).coerceAtMost(uiState.allChannels.size - 1)
                            }
                            showChannelPicker -> return@onPreviewKeyEvent false
                            else -> {
                                val next = getSlotInDirection(current, 3)
                                if (next != current) viewModel.setFocusedSlot(next)
                            }
                        }
                        true
                    }
                    
                    // CHANNEL CHANGE - CH+/-, Page keys, or media keys
                    // Many TV remotes send different keycodes - handle them all
                    Key.PageUp, Key.ChannelUp, Key.MediaPrevious -> {
                        if (showQuickStrip) {
                            val channel = uiState.allChannels.getOrNull(quickStripIndex)
                            if (channel != null) viewModel.swapChannel(current, channel)
                            showQuickStrip = false
                        } else {
                            viewModel.changeChannelInSlot(current, -1)
                        }
                        true
                    }
                    Key.PageDown, Key.ChannelDown, Key.MediaNext -> {
                        if (showQuickStrip) {
                            val channel = uiState.allChannels.getOrNull(quickStripIndex)
                            if (channel != null) viewModel.swapChannel(current, channel)
                            showQuickStrip = false
                        } else {
                            viewModel.changeChannelInSlot(current, 1)
                        }
                        true
                    }
                    
                    // SELECT - Open channel picker
                    Key.Enter, Key.DirectionCenter -> {
                        val now = System.currentTimeMillis()
                        when {
                            showQuickStrip -> {
                                val channel = uiState.allChannels.getOrNull(quickStripIndex)
                                if (channel != null) viewModel.swapChannel(current, channel)
                                showQuickStrip = false
                            }
                            showChannelPicker -> return@onPreviewKeyEvent false
                            swapMode -> {
                                // Handled in KeyUp
                            }
                            now - lastOkPressTime < 300 -> {
                                // Double-tap = fullscreen
                                uiState.slots.getOrNull(current)?.let { onFullScreen(it.channel) }
                            }
                            else -> {
                                // Single tap = channel picker
                                showChannelPicker = true
                            }
                        }
                        lastOkPressTime = now
                        true
                    }
                    
                    // QUICK ACTIONS
                    Key.M -> {
                        viewModel.toggleMuteOnSlot(current)
                        true
                    }
                    Key.G -> {
                        // Show quick strip for fast channel browse
                        val currentChannel = uiState.slots.getOrNull(current)?.channel
                        quickStripIndex = uiState.allChannels.indexOfFirst { it.id == currentChannel?.id }
                            .coerceAtLeast(0)
                        showQuickStrip = true
                        true
                    }
                    Key.L -> {
                        viewModel.cycleLayout()
                        true
                    }
                    Key.One -> { viewModel.setAudioSlot(0); true }
                    Key.Two -> { viewModel.setAudioSlot(1); true }
                    Key.Three -> { viewModel.setAudioSlot(2); true }
                    Key.Four -> { viewModel.setAudioSlot(3); true }
                    
                    // Catch-all for raw keycodes (some TV remotes)
                    else -> {
                        // KEYCODE_CHANNEL_UP = 166, KEYCODE_CHANNEL_DOWN = 167
                        val nativeCode = event.nativeKeyEvent.keyCode
                        Log.d("MultiviewV2", "Unhandled key: ${event.key}, nativeCode=$nativeCode")
                        when (nativeCode) {
                            166, 188 -> { // CHANNEL_UP variants
                                if (!showQuickStrip && !showChannelPicker) {
                                    viewModel.changeChannelInSlot(current, -1)
                                }
                                true
                            }
                            167, 189 -> { // CHANNEL_DOWN variants  
                                if (!showQuickStrip && !showChannelPicker) {
                                    viewModel.changeChannelInSlot(current, 1)
                                }
                                true
                            }
                            else -> false
                        }
                    }
                }
            }
    ) {
        // Main grid
        MultiviewGridV2(
            slots = uiState.slots,
            layout = uiState.layout,
            focusedSlotIndex = uiState.focusedSlotIndex,
            swapMode = swapMode,
            swapSourceSlot = swapSourceSlot,
            showControls = uiState.showControls,
            viewModel = viewModel
        )
        
        // Help overlay (top)
        AnimatedVisibility(
            visible = uiState.showControls && !showChannelPicker && !showQuickStrip,
            enter = fadeIn() + slideInVertically { -it },
            exit = fadeOut() + slideOutVertically { -it },
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            HelpBar(swapMode = swapMode)
        }
        
        // Layout indicator (bottom-left)
        AnimatedVisibility(
            visible = uiState.showControls,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp)
        ) {
            LayoutIndicator(
                layout = uiState.layout,
                slotCount = uiState.slots.size,
                onClick = { viewModel.cycleLayout() }
            )
        }
        
        // Quick strip (bottom)
        AnimatedVisibility(
            visible = showQuickStrip,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            QuickChannelStrip(
                channels = uiState.allChannels,
                selectedIndex = quickStripIndex,
                onSelect = { channel ->
                    viewModel.swapChannel(uiState.focusedSlotIndex, channel)
                    showQuickStrip = false
                }
            )
        }
        
        // Full channel picker
        if (showChannelPicker) {
            ChannelPickerV2(
                channels = uiState.allChannels,
                currentChannel = uiState.slots.getOrNull(uiState.focusedSlotIndex)?.channel,
                onSelect = { channel ->
                    viewModel.swapChannel(uiState.focusedSlotIndex, channel)
                    showChannelPicker = false
                },
                onDismiss = { showChannelPicker = false }
            )
        }
    }
}

@Composable
private fun HelpBar(swapMode: Boolean) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Black.copy(alpha = 0.85f),
                        Color.Transparent
                    )
                )
            )
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (swapMode) {
                Text(
                    text = "🔄 SWAP MODE - Navigate to target slot, press OK to swap",
                    color = MV2Colors.Accent,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            } else {
                HelpItem(icon = "⬆⬇⬅➡", text = "Navigate")
                Spacer(modifier = Modifier.width(24.dp))
                HelpItem(icon = "OK", text = "Change Ch", highlight = true)
                Spacer(modifier = Modifier.width(24.dp))
                HelpItem(icon = "2×OK", text = "Fullscreen")
                Spacer(modifier = Modifier.width(24.dp))
                HelpItem(icon = "CH±", text = "Next/Prev")
                Spacer(modifier = Modifier.width(24.dp))
                HelpItem(icon = "M", text = "Mute")
            }
        }
    }
}

@Composable
private fun HelpItem(icon: String, text: String, highlight: Boolean = false) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(4.dp))
                .background(if (highlight) MV2Colors.Accent else MV2Colors.Surface)
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                text = icon,
                color = if (highlight) Color.Black else Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = text,
            color = MV2Colors.TextSecondary,
            fontSize = 12.sp
        )
    }
}

@Composable
private fun MultiviewGridV2(
    slots: List<MultiviewSlot>,
    layout: MultiviewLayout,
    focusedSlotIndex: Int,
    swapMode: Boolean,
    swapSourceSlot: Int,
    showControls: Boolean,
    viewModel: MultiviewViewModel
) {
    when (layout) {
        MultiviewLayout.SINGLE -> {
            if (slots.isNotEmpty()) {
                SlotV2(
                    slot = slots[0],
                    index = 0,
                    player = viewModel.getPlayer(0),
                    isFocused = focusedSlotIndex == 0,
                    isSwapSource = swapMode && swapSourceSlot == 0,
                    isSwapTarget = swapMode && swapSourceSlot != 0,
                    showInfo = showControls,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
        MultiviewLayout.TWO_BY_ONE -> {
            Row(modifier = Modifier.fillMaxSize()) {
                slots.take(2).forEachIndexed { index, slot ->
                    SlotV2(
                        slot = slot,
                        index = index,
                        player = viewModel.getPlayer(index),
                        isFocused = focusedSlotIndex == index,
                        isSwapSource = swapMode && swapSourceSlot == index,
                        isSwapTarget = swapMode && swapSourceSlot != index,
                        showInfo = showControls,
                        modifier = Modifier.weight(1f).fillMaxHeight()
                    )
                }
            }
        }
        MultiviewLayout.ONE_BY_TWO -> {
            Column(modifier = Modifier.fillMaxSize()) {
                slots.take(2).forEachIndexed { index, slot ->
                    SlotV2(
                        slot = slot,
                        index = index,
                        player = viewModel.getPlayer(index),
                        isFocused = focusedSlotIndex == index,
                        isSwapSource = swapMode && swapSourceSlot == index,
                        isSwapTarget = swapMode && swapSourceSlot != index,
                        showInfo = showControls,
                        modifier = Modifier.weight(1f).fillMaxWidth()
                    )
                }
            }
        }
        MultiviewLayout.THREE_GRID -> {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.take(2).forEachIndexed { index, slot ->
                        SlotV2(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            isFocused = focusedSlotIndex == index,
                            isSwapSource = swapMode && swapSourceSlot == index,
                            isSwapTarget = swapMode && swapSourceSlot != index,
                            showInfo = showControls,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
                if (slots.size > 2) {
                    SlotV2(
                        slot = slots[2],
                        index = 2,
                        player = viewModel.getPlayer(2),
                        isFocused = focusedSlotIndex == 2,
                        isSwapSource = swapMode && swapSourceSlot == 2,
                        isSwapTarget = swapMode && swapSourceSlot != 2,
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
                        SlotV2(
                            slot = slot,
                            index = index,
                            player = viewModel.getPlayer(index),
                            isFocused = focusedSlotIndex == index,
                            isSwapSource = swapMode && swapSourceSlot == index,
                            isSwapTarget = swapMode && swapSourceSlot != index,
                            showInfo = showControls,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
                Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    slots.drop(2).take(2).forEachIndexed { index, slot ->
                        val actualIndex = index + 2
                        SlotV2(
                            slot = slot,
                            index = actualIndex,
                            player = viewModel.getPlayer(actualIndex),
                            isFocused = focusedSlotIndex == actualIndex,
                            isSwapSource = swapMode && swapSourceSlot == actualIndex,
                            isSwapTarget = swapMode && swapSourceSlot != actualIndex,
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
private fun SlotV2(
    slot: MultiviewSlot,
    index: Int,
    player: MultiviewPlayer?,
    isFocused: Boolean,
    isSwapSource: Boolean,
    isSwapTarget: Boolean,
    showInfo: Boolean,
    modifier: Modifier = Modifier
) {
    val isBuffering by player?.isBuffering?.collectAsState() ?: remember { mutableStateOf(false) }
    val isMuted by player?.isMuted?.collectAsState() ?: remember { mutableStateOf(true) }
    
    // Animation for focus
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.0f else 0.98f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f),
        label = "scale"
    )
    
    val borderColor by animateColorAsState(
        targetValue = when {
            isSwapSource -> MV2Colors.Accent
            isSwapTarget && isFocused -> Color(0xFFFFB800)
            isFocused -> MV2Colors.FocusBorder
            else -> Color.Transparent
        },
        animationSpec = tween(200),
        label = "border"
    )
    
    Box(
        modifier = modifier
            .padding(3.dp)
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(MV2Colors.Surface)
            .border(
                width = if (isFocused || isSwapSource) 3.dp else 0.dp,
                color = borderColor,
                shape = RoundedCornerShape(12.dp)
            )
    ) {
        // Video
        if (player != null) {
            AndroidView(
                factory = { ctx ->
                    SurfaceView(ctx).also { player.setSurfaceView(it) }
                },
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Box(
                modifier = Modifier.fillMaxSize().background(MV2Colors.Surface),
                contentAlignment = Alignment.Center
            ) {
                LoadingDotsV2()
            }
        }
        
        // Buffering overlay
        if (isBuffering) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.6f)),
                contentAlignment = Alignment.Center
            ) {
                LoadingDotsV2()
            }
        }
        
        // Swap mode indicators
        if (isSwapSource) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MV2Colors.Accent.copy(alpha = 0.2f))
            )
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .clip(RoundedCornerShape(8.dp))
                    .background(MV2Colors.Accent)
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Text(
                    text = "SOURCE",
                    color = Color.Black,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
        }
        
        if (isSwapTarget && isFocused) {
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFFFFB800))
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Text(
                    text = "SWAP HERE",
                    color = Color.Black,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
        }
        
        // Slot number badge (top-left)
        Box(
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(8.dp)
                .size(28.dp)
                .clip(CircleShape)
                .background(
                    if (isFocused) MV2Colors.Accent else Color.Black.copy(alpha = 0.7f)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "${index + 1}",
                color = if (isFocused) Color.Black else Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp
            )
        }
        
        // Audio indicator (top-right)
        if (!isMuted) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(MV2Colors.Audio)
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.VolumeUp,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "AUDIO",
                        color = Color.White,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
        
        // Channel info (bottom)
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
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.9f))
                        )
                    )
                    .padding(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Logo
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(MV2Colors.Surface),
                        contentAlignment = Alignment.Center
                    ) {
                        slot.channel.logoUrl?.let { url ->
                            AsyncImage(
                                model = url,
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
                    
                    Spacer(modifier = Modifier.width(10.dp))
                    
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            slot.channel.number?.let {
                                Text(
                                    text = it,
                                    color = MV2Colors.Accent,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                            }
                            Text(
                                text = slot.channel.name,
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 13.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        slot.channel.nowPlaying?.let { program ->
                            Text(
                                text = program.title,
                                color = MV2Colors.TextSecondary,
                                fontSize = 11.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                    
                    // LIVE badge
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(
                                if (slot.isTimeshifted) Color(0xFF8B5CF6) else MV2Colors.Live
                            )
                            .padding(horizontal = 6.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = if (slot.isTimeshifted) "DVR" else "LIVE",
                            color = Color.White,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LayoutIndicator(
    layout: MultiviewLayout,
    slotCount: Int,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = MV2Colors.SurfaceGlass,
            focusedContainerColor = MV2Colors.Accent.copy(alpha = 0.3f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, MV2Colors.Accent),
                shape = RoundedCornerShape(8.dp)
            )
        )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.GridView,
                contentDescription = null,
                tint = MV2Colors.TextSecondary,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = when (layout) {
                    MultiviewLayout.SINGLE -> "1×1"
                    MultiviewLayout.TWO_BY_ONE -> "2×1"
                    MultiviewLayout.ONE_BY_TWO -> "1×2"
                    MultiviewLayout.THREE_GRID -> "2+1"
                    MultiviewLayout.TWO_BY_TWO -> "2×2"
                },
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "L",
                color = MV2Colors.TextMuted,
                fontSize = 10.sp
            )
        }
    }
}

@Composable
private fun QuickChannelStrip(
    channels: List<Channel>,
    selectedIndex: Int,
    onSelect: (Channel) -> Unit
) {
    val listState = rememberLazyListState()
    
    LaunchedEffect(selectedIndex) {
        listState.animateScrollToItem(
            index = (selectedIndex - 2).coerceAtLeast(0),
            scrollOffset = 0
        )
    }
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.95f))
                )
            )
            .padding(vertical = 16.dp)
    ) {
        Column {
            Text(
                text = "◀ ▶ Browse  •  OK Select  •  Back Cancel",
                color = MV2Colors.TextMuted,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            LazyRow(
                state = listState,
                contentPadding = PaddingValues(horizontal = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(channels, key = { it.id }) { channel ->
                    val isSelected = channels.indexOf(channel) == selectedIndex
                    QuickChannelCard(
                        channel = channel,
                        isSelected = isSelected,
                        onClick = { onSelect(channel) }
                    )
                }
            }
        }
    }
}

@Composable
private fun QuickChannelCard(
    channel: Channel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1.1f else 1f,
        animationSpec = spring(dampingRatio = 0.7f),
        label = "scale"
    )
    
    Box(
        modifier = Modifier
            .scale(scale)
            .width(120.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (isSelected) MV2Colors.Accent.copy(alpha = 0.3f) else MV2Colors.Surface)
            .border(
                width = if (isSelected) 2.dp else 0.dp,
                color = if (isSelected) MV2Colors.Accent else Color.Transparent,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(8.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(MV2Colors.Background),
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
                    tint = MV2Colors.TextMuted,
                    modifier = Modifier.size(24.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(6.dp))
            
            Text(
                text = channel.number ?: "",
                color = MV2Colors.Accent,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = channel.name,
                color = Color.White,
                fontSize = 11.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun ChannelPickerV2(
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
            .background(Color.Black.copy(alpha = 0.92f))
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
                .width(600.dp)
                .fillMaxHeight(0.85f)
                .clip(RoundedCornerShape(16.dp))
                .background(MV2Colors.Surface)
                .padding(20.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Select Channel",
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${channels.size} channels",
                    color = MV2Colors.TextMuted,
                    fontSize = 14.sp
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Channel list
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(channels, key = { it.id }) { channel ->
                    val isSelected = channel.id == currentChannel?.id
                    val isFirst = channels.indexOf(channel) == 0
                    
                    Surface(
                        onClick = { onSelect(channel) },
                        modifier = if (isFirst) Modifier.focusRequester(focusRequester) else Modifier,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = if (isSelected) MV2Colors.Accent.copy(alpha = 0.2f)
                                           else MV2Colors.Background,
                            focusedContainerColor = MV2Colors.Accent.copy(alpha = 0.3f)
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, MV2Colors.Accent),
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
                            // Logo
                            Box(
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(MV2Colors.Surface),
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
                                    tint = MV2Colors.TextMuted
                                )
                            }
                            
                            Spacer(modifier = Modifier.width(12.dp))
                            
                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    channel.number?.let {
                                        Text(
                                            text = it,
                                            color = MV2Colors.Accent,
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
                                        color = MV2Colors.TextSecondary,
                                        fontSize = 12.sp,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }
                            
                            if (isSelected) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = "Current",
                                    tint = MV2Colors.Accent,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Cancel button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                Surface(
                    onClick = onDismiss,
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = MV2Colors.Background,
                        focusedContainerColor = Color(0xFFFF3B5C).copy(alpha = 0.3f)
                    ),
                    border = ClickableSurfaceDefaults.border(
                        focusedBorder = Border(
                            border = BorderStroke(2.dp, Color(0xFFFF3B5C)),
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
}

@Composable
private fun LoadingDotsV2() {
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
                    .clip(CircleShape)
                    .background(MV2Colors.Accent.copy(alpha = alpha))
            )
        }
    }
}
