package com.openflix.presentation.screens.livetv

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
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
import com.openflix.player.LiveTVPlayer
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * Channel Surfing Screen - Quick channel preview mode.
 *
 * Features:
 * - Full-screen preview of focused channel
 * - Horizontal channel strip at bottom
 * - Quick navigation with left/right
 * - Auto-advance mode for hands-free browsing
 * - Press OK to watch full screen
 */
@Composable
fun ChannelSurfingScreen(
    onBack: () -> Unit,
    onChannelSelected: (String) -> Unit,
    viewModel: ChannelSurfingViewModel = hiltViewModel(),
    liveTVPlayer: LiveTVPlayer
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()

    // Track overlay visibility
    var showOverlay by remember { mutableStateOf(true) }
    var channelNumberInput by remember { mutableStateOf("") }

    // Auto-hide overlay
    LaunchedEffect(showOverlay) {
        if (showOverlay) {
            delay(5000)
            showOverlay = false
        }
    }

    // Handle channel number input
    LaunchedEffect(channelNumberInput) {
        if (channelNumberInput.isNotEmpty()) {
            delay(1500)
            val number = channelNumberInput.toIntOrNull()
            if (number != null) {
                viewModel.jumpToChannel(number)
            }
            channelNumberInput = ""
        }
    }

    // Scroll to focused channel
    LaunchedEffect(uiState.currentIndex) {
        if (uiState.hasChannels) {
            coroutineScope.launch {
                listState.animateScrollToItem(
                    index = maxOf(0, uiState.currentIndex - 2)
                )
            }
        }
    }

    // Start preview when channel changes
    LaunchedEffect(uiState.previewChannel) {
        uiState.previewChannel?.let { channel ->
            channel.streamUrl?.let { url ->
                liveTVPlayer.play(url)
            }
        }
    }

    // Request focus
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
                    when (event.key) {
                        // Navigation
                        Key.DirectionLeft -> {
                            viewModel.previousChannel()
                            showOverlay = true
                            true
                        }
                        Key.DirectionRight -> {
                            viewModel.nextChannel()
                            showOverlay = true
                            true
                        }
                        Key.DirectionUp, Key.DirectionDown -> {
                            showOverlay = true
                            true
                        }

                        // Channel buttons
                        Key.ChannelUp, Key.PageUp -> {
                            viewModel.nextChannel()
                            showOverlay = true
                            true
                        }
                        Key.ChannelDown, Key.PageDown -> {
                            viewModel.previousChannel()
                            showOverlay = true
                            true
                        }

                        // Select channel
                        Key.Enter, Key.DirectionCenter -> {
                            viewModel.selectCurrentChannel()?.let { channel ->
                                onChannelSelected(channel.id)
                            }
                            true
                        }

                        // Toggle auto-advance
                        Key.A, Key.MediaPlayPause -> {
                            viewModel.toggleAutoAdvance()
                            showOverlay = true
                            true
                        }

                        // Toggle favorites filter
                        Key.F, Key(android.view.KeyEvent.KEYCODE_PROG_RED.toLong()) -> {
                            viewModel.toggleFavoritesFilter()
                            showOverlay = true
                            true
                        }

                        // Show/hide overlay
                        Key.Info -> {
                            showOverlay = !showOverlay
                            true
                        }

                        // Back
                        Key.Escape, Key.Back -> {
                            liveTVPlayer.stop()
                            onBack()
                            true
                        }

                        // Number keys
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
        // Video preview
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

        // Loading state
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(color = OpenFlixColors.Primary)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Loading channels...",
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color.White
                    )
                }
            }
        }

        // Error state
        uiState.error?.let { error ->
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Failed to load channels",
                        style = MaterialTheme.typography.headlineSmall,
                        color = OpenFlixColors.Error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodyMedium,
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

        // Auto-advance indicator
        AnimatedVisibility(
            visible = uiState.isAutoAdvancing,
            enter = fadeIn() + slideInVertically { -it },
            exit = fadeOut() + slideOutVertically { -it },
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(24.dp)
        ) {
            Box(
                modifier = Modifier
                    .background(
                        OpenFlixColors.Primary.copy(alpha = 0.9f),
                        RoundedCornerShape(8.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(text = "▶", fontSize = 16.sp, color = Color.White)
                    Text(
                        text = "AUTO SURFING",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }

        // Preview loading indicator
        AnimatedVisibility(
            visible = uiState.isPreviewLoading,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            CircularProgressIndicator(
                color = OpenFlixColors.Primary,
                modifier = Modifier.size(48.dp)
            )
        }

        // Bottom overlay with channel strip
        AnimatedVisibility(
            visible = showOverlay && uiState.hasChannels,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            ChannelSurfingOverlay(
                channels = viewModel.getFilteredChannels(),
                currentChannel = uiState.focusedChannel,
                currentPosition = uiState.currentPosition,
                isAutoAdvancing = uiState.isAutoAdvancing,
                showFavoritesOnly = uiState.showFavoritesOnly,
                listState = listState,
                onChannelFocused = { viewModel.focusChannel(it) },
                onChannelSelected = { channel ->
                    onChannelSelected(channel.id)
                }
            )
        }

        // Help hint (top right when overlay hidden)
        AnimatedVisibility(
            visible = !showOverlay && uiState.hasChannels,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.6f),
                        RoundedCornerShape(8.dp)
                    )
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Text(
                    text = "←/→ Change • OK Watch",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }
        }
    }
}

@Composable
private fun ChannelSurfingOverlay(
    channels: List<Channel>,
    currentChannel: Channel?,
    currentPosition: String,
    isAutoAdvancing: Boolean,
    showFavoritesOnly: Boolean,
    listState: androidx.compose.foundation.lazy.LazyListState,
    onChannelFocused: (Channel) -> Unit,
    onChannelSelected: (Channel) -> Unit
) {
    val timeFormat = remember { SimpleDateFormat("h:mm a", Locale.getDefault()) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.7f),
                        Color.Black.copy(alpha = 0.95f)
                    )
                )
            )
            .padding(24.dp)
    ) {
        Column {
            // Current channel info
            currentChannel?.let { channel ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Channel logo
                    AsyncImage(
                        model = channel.logoUrl,
                        contentDescription = channel.name,
                        modifier = Modifier
                            .size(72.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(OpenFlixColors.SurfaceVariant),
                        contentScale = ContentScale.Fit
                    )

                    Spacer(modifier = Modifier.width(20.dp))

                    // Channel details
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
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )

                            // HD badge
                            if (channel.hd) {
                                Spacer(modifier = Modifier.width(12.dp))
                                Box(
                                    modifier = Modifier
                                        .background(OpenFlixColors.Info, RoundedCornerShape(4.dp))
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

                            // Favorite star
                            if (channel.favorite) {
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "★",
                                    fontSize = 20.sp,
                                    color = Color(0xFFF59E0B)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Now playing
                        channel.nowPlaying?.let { program ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .background(OpenFlixColors.LiveIndicator, RoundedCornerShape(4.dp))
                                        .padding(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = "NOW",
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = program.displayTitle,
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = Color.White,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }

                            // Progress bar
                            Spacer(modifier = Modifier.height(8.dp))
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(0.5f)
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

                        // Up next
                        channel.upNext?.let { program ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "NEXT",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = OpenFlixColors.TextTertiary
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = "${timeFormat.format(Date(program.startTime * 1000))} - ${program.title}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = OpenFlixColors.TextSecondary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }

                    // Position indicator
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = currentPosition,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.TextSecondary
                        )
                        if (showFavoritesOnly) {
                            Text(
                                text = "★ Favorites",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color(0xFFF59E0B)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Channel strip
            LazyRow(
                state = listState,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(horizontal = 8.dp)
            ) {
                items(
                    items = channels,
                    key = { it.id }
                ) { channel ->
                    ChannelSurfingCard(
                        channel = channel,
                        isSelected = channel.id == currentChannel?.id,
                        onFocused = { onChannelFocused(channel) },
                        onSelected = { onChannelSelected(channel) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Controls hint
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "←/→ Browse • OK Watch • A Auto-surf${if (isAutoAdvancing) " (ON)" else ""} • F Favorites • Back Exit",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }
    }
}

@Composable
private fun ChannelSurfingCard(
    channel: Channel,
    isSelected: Boolean,
    onFocused: () -> Unit,
    onSelected: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    LaunchedEffect(isFocused) {
        if (isFocused) {
            onFocused()
        }
    }

    Surface(
        onClick = onSelected,
        modifier = Modifier
            .width(160.dp)
            .height(100.dp)
            .onFocusChanged {
                isFocused = it.isFocused
            },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                isSelected -> OpenFlixColors.Primary.copy(alpha = 0.3f)
                else -> OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
            },
            focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.4f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(3.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(12.dp)
            ),
            border = if (isSelected) {
                Border(
                    border = BorderStroke(2.dp, OpenFlixColors.Primary.copy(alpha = 0.6f)),
                    shape = RoundedCornerShape(12.dp)
                )
            } else {
                Border.None
            }
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.08f)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Channel logo
            AsyncImage(
                model = channel.logoUrl,
                contentDescription = channel.name,
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(4.dp)),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Channel number
            channel.number?.let { number ->
                Text(
                    text = number,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isSelected) OpenFlixColors.Primary else Color.White
                )
            }

            // Channel name (truncated)
            Text(
                text = channel.name,
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )

            // Favorite indicator
            if (channel.favorite) {
                Text(
                    text = "★",
                    fontSize = 12.sp,
                    color = Color(0xFFF59E0B)
                )
            }
        }
    }
}

@Composable
private fun CircularProgressIndicator(
    color: Color,
    modifier: Modifier = Modifier
) {
    androidx.compose.material3.CircularProgressIndicator(
        color = color,
        modifier = modifier
    )
}
