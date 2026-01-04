package com.openflix.presentation.screens.epg

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.IconButton
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.material3.*
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.ProgramBadge
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

// EPG Grid dimensions
private val CHANNEL_WIDTH = 180.dp
private val ROW_HEIGHT = 72.dp
private val TIME_HEADER_HEIGHT = 50.dp
private val TIME_SLOT_WIDTH = 150.dp // Width for 30 minutes
private val SIDEBAR_WIDTH = 200.dp
private val PROGRAM_DETAIL_HEIGHT = 160.dp

/**
 * EPG Guide Screen - TV-style program guide grid.
 */
@Composable
fun EPGGuideScreen(
    onBack: () -> Unit,
    onChannelSelected: (String) -> Unit,
    onArchivePlayback: (channelId: String, programStartTime: Long) -> Unit = { _, _ -> },  // Catch-up playback
    viewModel: EPGGuideViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }
    val coroutineScope = rememberCoroutineScope()

    // Scroll states
    val channelListState = rememberLazyListState()
    val horizontalScrollState = rememberScrollState()

    // Request focus
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    // Scroll to now when requested
    LaunchedEffect(uiState.scrollToNow) {
        if (uiState.scrollToNow) {
            // Calculate scroll position for current time
            val now = System.currentTimeMillis() / 1000
            val minutesSinceStart = ((now - uiState.startTimeSeconds) / 60).toInt()
            val pixelsPerMinute = with(LocalDensity) { TIME_SLOT_WIDTH.value / 30 }
            val scrollOffset = (minutesSinceStart * pixelsPerMinute - 200).coerceAtLeast(0f).toInt()
            horizontalScrollState.animateScrollTo(scrollOffset)
            viewModel.clearScrollToNow()
        }
    }

    // Scroll to focused channel
    LaunchedEffect(uiState.focusedChannelIndex) {
        coroutineScope.launch {
            channelListState.animateScrollToItem(uiState.focusedChannelIndex)
        }
    }

    // Channel number input timeout
    LaunchedEffect(uiState.channelNumberInput) {
        if (uiState.channelNumberInput.isNotEmpty()) {
            kotlinx.coroutines.delay(2000)
            viewModel.jumpToChannelNumber()
        }
    }

    // Timeline scroll
    LaunchedEffect(uiState.scrollToTimeOffset) {
        uiState.scrollToTimeOffset?.let { offset ->
            val pixelsPerMinute = with(LocalDensity) { TIME_SLOT_WIDTH.value / 30 }
            val scrollOffset = (offset * pixelsPerMinute).toInt()
            horizontalScrollState.animateScrollTo(scrollOffset)
            viewModel.clearTimelineScrollOffset()
        }
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
                        // ========== NAVIGATION ==========
                        Key.DirectionUp -> {
                            viewModel.moveFocusUp()
                            true
                        }
                        Key.DirectionDown -> {
                            viewModel.moveFocusDown()
                            true
                        }
                        Key.DirectionLeft -> {
                            viewModel.moveFocusLeft()
                            true
                        }
                        Key.DirectionRight -> {
                            viewModel.moveFocusRight()
                            true
                        }

                        // ========== PAGE NAVIGATION ==========
                        Key.PageUp, Key.ChannelUp -> {
                            viewModel.pageUp()
                            true
                        }
                        Key.PageDown, Key.ChannelDown -> {
                            viewModel.pageDown()
                            true
                        }

                        // ========== SELECT ==========
                        Key.Enter, Key.NumPadEnter -> {
                            viewModel.getFocusedChannel()?.let { channel ->
                                onChannelSelected(channel.channel.id)
                            }
                            true
                        }
                        Key.Escape, Key.Back -> {
                            onBack()
                            true
                        }

                        // ========== DATE NAVIGATION ==========
                        Key.LeftBracket, Key.Minus -> {
                            viewModel.previousDay()
                            true
                        }
                        Key.RightBracket, Key.Equals -> {
                            viewModel.nextDay()
                            true
                        }
                        Key.T -> {
                            viewModel.goToToday()
                            true
                        }

                        // ========== TIME NAVIGATION ==========
                        Key.N -> {
                            viewModel.scrollToNow()
                            true
                        }
                        Key.P -> {
                            viewModel.jumpToPrimeTime()
                            true
                        }
                        Key.Comma -> {
                            viewModel.jumpTimelineByHours(-1) // 1 hour back
                            true
                        }
                        Key.Period -> {
                            viewModel.jumpTimelineByHours(1) // 1 hour forward
                            true
                        }

                        // ========== SIDEBAR/FILTER ==========
                        Key.Tab -> {
                            viewModel.toggleSidebar()
                            true
                        }
                        Key.F -> {
                            viewModel.toggleFavoritesOnly()
                            true
                        }

                        // ========== COLOR BUTTONS (Record/Reminder) ==========
                        Key.R -> { // Red - Record
                            viewModel.showRecordDialog()
                            true
                        }
                        Key.G -> { // Green - Reminder
                            viewModel.showReminderDialog()
                            true
                        }

                        // ========== NUMBER KEYS (channel jump) ==========
                        Key.Zero, Key.NumPad0 -> { viewModel.appendChannelNumber('0'); true }
                        Key.One, Key.NumPad1 -> { viewModel.appendChannelNumber('1'); true }
                        Key.Two, Key.NumPad2 -> { viewModel.appendChannelNumber('2'); true }
                        Key.Three, Key.NumPad3 -> { viewModel.appendChannelNumber('3'); true }
                        Key.Four, Key.NumPad4 -> { viewModel.appendChannelNumber('4'); true }
                        Key.Five, Key.NumPad5 -> { viewModel.appendChannelNumber('5'); true }
                        Key.Six, Key.NumPad6 -> { viewModel.appendChannelNumber('6'); true }
                        Key.Seven, Key.NumPad7 -> { viewModel.appendChannelNumber('7'); true }
                        Key.Eight, Key.NumPad8 -> { viewModel.appendChannelNumber('8'); true }
                        Key.Nine, Key.NumPad9 -> { viewModel.appendChannelNumber('9'); true }

                        else -> false
                    }
                } else false
            }
    ) {
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Color.White)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Error,
                            contentDescription = null,
                            tint = Color.Red,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error ?: "Error loading guide",
                            color = Color.White
                        )
                    }
                }
            }
            uiState.channelsWithPrograms.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Tv,
                            contentDescription = null,
                            tint = Color.Gray,
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No EPG data available",
                            color = Color.Gray,
                            fontSize = 16.sp
                        )
                    }
                }
            }
            else -> {
                EPGContent(
                    uiState = uiState,
                    viewModel = viewModel,
                    channelListState = channelListState,
                    horizontalScrollState = horizontalScrollState,
                    onChannelSelected = onChannelSelected,
                    onArchivePlayback = onArchivePlayback
                )
            }
        }

        // Channel number input overlay
        if (uiState.channelNumberInput.isNotEmpty()) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(40.dp)
                    .background(Color.Black.copy(alpha = 0.9f), RoundedCornerShape(8.dp))
                    .padding(horizontal = 24.dp, vertical = 16.dp)
            ) {
                Text(
                    text = uiState.channelNumberInput,
                    color = Color.White,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Keyboard shortcuts hint bar at bottom
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(Color.Black.copy(alpha = 0.8f))
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                KeyboardHint(key = "[ ]", action = "Day")
                KeyboardHint(key = "N", action = "Now")
                KeyboardHint(key = "P", action = "Prime")
                KeyboardHint(key = "< >", action = "±1hr")
                KeyboardHint(key = "T", action = "Today")
                KeyboardHint(key = "R", action = "Record")
                KeyboardHint(key = "G", action = "Remind")
                KeyboardHint(key = "F", action = "Favs")
            }
        }

        // Record dialog
        if (uiState.showRecordDialog && uiState.selectedProgramForAction != null) {
            RecordReminderDialog(
                program = uiState.selectedProgramForAction!!,
                isRecord = true,
                onConfirm = {
                    // TODO: Implement recording
                    viewModel.dismissDialogs()
                },
                onDismiss = { viewModel.dismissDialogs() }
            )
        }

        // Reminder dialog
        if (uiState.showReminderDialog && uiState.selectedProgramForAction != null) {
            RecordReminderDialog(
                program = uiState.selectedProgramForAction!!,
                isRecord = false,
                onConfirm = {
                    // TODO: Implement reminder
                    viewModel.dismissDialogs()
                },
                onDismiss = { viewModel.dismissDialogs() }
            )
        }
    }
}

@Composable
private fun KeyboardHint(key: String, action: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .background(Color.Gray.copy(alpha = 0.3f), RoundedCornerShape(4.dp))
                .padding(horizontal = 6.dp, vertical = 2.dp)
        ) {
            Text(
                text = key,
                color = Color.White,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }
        Text(
            text = action,
            color = Color.Gray,
            fontSize = 11.sp
        )
    }
}

@Composable
private fun RecordReminderDialog(
    program: Program,
    isRecord: Boolean,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Color(0xFF1a1a2e),
        title = {
            Text(
                text = if (isRecord) "Record Program" else "Set Reminder",
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = program.displayTitle,
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "${timeFormat.format(Date(program.startTime * 1000))} - ${timeFormat.format(Date(program.endTime * 1000))}",
                    color = Color.Gray,
                    fontSize = 14.sp
                )
                if (isRecord) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "This will record the program to your DVR.",
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                } else {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "You will be notified when the program starts.",
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(
                    text = if (isRecord) "Record" else "Set Reminder",
                    color = if (isRecord) Color.Red else Color(0xFF10B981)
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = "Cancel", color = Color.Gray)
            }
        }
    )
}

@Composable
private fun DateNavigationHeader(
    dateString: String,
    canGoBack: Boolean,
    canGoForward: Boolean,
    isToday: Boolean,
    onPreviousDay: () -> Unit,
    onNextDay: () -> Unit,
    onGoToday: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFF0f0f1a))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Left arrow
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            IconButton(
                onClick = onPreviousDay,
                enabled = canGoBack,
                modifier = Modifier.size(32.dp)
            ) {
                Icon(
                    Icons.Default.ChevronLeft,
                    contentDescription = "Previous day",
                    tint = if (canGoBack) Color.White else Color.Gray.copy(alpha = 0.3f)
                )
            }

            // Date display
            Text(
                text = dateString,
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )

            IconButton(
                onClick = onNextDay,
                enabled = canGoForward,
                modifier = Modifier.size(32.dp)
            ) {
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = "Next day",
                    tint = if (canGoForward) Color.White else Color.Gray.copy(alpha = 0.3f)
                )
            }
        }

        // Today button (only show if not on today)
        if (!isToday) {
            Surface(
                onClick = onGoToday,
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.clickable { onGoToday() }
            ) {
                Text(
                    text = "Today",
                    color = MaterialTheme.colorScheme.primary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun EPGContent(
    uiState: EPGGuideUiState,
    viewModel: EPGGuideViewModel,
    channelListState: androidx.compose.foundation.lazy.LazyListState,
    horizontalScrollState: ScrollState,
    onChannelSelected: (String) -> Unit,
    onArchivePlayback: (channelId: String, programStartTime: Long) -> Unit
) {
    val filteredChannels = viewModel.getFilteredChannels()

    Row(modifier = Modifier.fillMaxSize()) {
        // Sidebar (categories)
        if (uiState.sidebarExpanded) {
            EPGSidebar(
                categories = uiState.categories,
                selectedCategory = uiState.selectedCategory,
                showFavoritesOnly = uiState.showFavoritesOnly,
                onCategorySelected = { viewModel.setCategory(it) },
                onToggleFavorites = { viewModel.toggleFavoritesOnly() }
            )
        }

        // Main EPG content
        Column(modifier = Modifier.weight(1f)) {
            // Date navigation header
            DateNavigationHeader(
                dateString = viewModel.getDisplayDateString(),
                canGoBack = uiState.currentDateOffset > -7,
                canGoForward = uiState.currentDateOffset < 7,
                isToday = uiState.currentDateOffset == 0,
                onPreviousDay = { viewModel.previousDay() },
                onNextDay = { viewModel.nextDay() },
                onGoToday = { viewModel.goToToday() }
            )

            // Program details panel
            ProgramDetailsPanel(
                program = viewModel.getFocusedProgram(),
                channel = viewModel.getFocusedChannel()?.channel
            )

            // EPG Grid
            Row(modifier = Modifier.weight(1f)) {
                // Channel column (fixed)
                ChannelColumn(
                    channels = filteredChannels,
                    focusedIndex = uiState.focusedChannelIndex,
                    channelListState = channelListState
                )

                // Time header and program grid
                Column(modifier = Modifier.weight(1f)) {
                    // Time header
                    TimeHeader(
                        startTimeSeconds = uiState.startTimeSeconds,
                        endTimeSeconds = uiState.endTimeSeconds,
                        scrollState = horizontalScrollState
                    )

                    // Program grid
                    ProgramGrid(
                        channels = filteredChannels,
                        startTimeSeconds = uiState.startTimeSeconds,
                        endTimeSeconds = uiState.endTimeSeconds,
                        focusedChannelIndex = uiState.focusedChannelIndex,
                        focusedProgramIndex = uiState.focusedProgramIndex,
                        horizontalScrollState = horizontalScrollState,
                        channelListState = channelListState,
                        onProgramClick = { channelId, program, hasCatchup ->
                            if (program.isPast && hasCatchup) {
                                // Play catch-up/archived program
                                onArchivePlayback(channelId, program.startTime)
                            } else {
                                // Tune to live channel
                                onChannelSelected(channelId)
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun EPGSidebar(
    categories: List<String>,
    selectedCategory: String,
    showFavoritesOnly: Boolean,
    onCategorySelected: (String) -> Unit,
    onToggleFavorites: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(SIDEBAR_WIDTH)
            .fillMaxHeight()
            .background(
                Brush.horizontalGradient(
                    colors = listOf(
                        Color(0xFF1a1a2e),
                        Color(0xFF16213e)
                    )
                )
            )
            .padding(8.dp)
    ) {
        Text(
            text = "Categories",
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(8.dp)
        )

        // Favorites filter
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
                .clickable { onToggleFavorites() },
            color = if (showFavoritesOnly) MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
            else Color.Transparent,
            shape = RoundedCornerShape(8.dp)
        ) {
            Row(
                modifier = Modifier.padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Star,
                    contentDescription = null,
                    tint = if (showFavoritesOnly) Color.Yellow else Color.Gray,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Favorites",
                    color = Color.White,
                    fontSize = 14.sp
                )
            }
        }

        Divider(
            color = Color.Gray.copy(alpha = 0.3f),
            modifier = Modifier.padding(vertical = 8.dp)
        )

        // Category list
        LazyColumn {
            items(categories.size) { index ->
                val category = categories[index]
                val isSelected = category == selectedCategory

                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 2.dp)
                        .clickable { onCategorySelected(category) },
                    color = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                    else Color.Transparent,
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = category,
                        color = if (isSelected) MaterialTheme.colorScheme.primary else Color.White,
                        fontSize = 14.sp,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun ProgramDetailsPanel(
    program: Program?,
    channel: com.openflix.domain.model.Channel?
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(PROGRAM_DETAIL_HEIGHT)
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF1a1a2e),
                        Color.Black
                    )
                )
            )
            .padding(16.dp)
    ) {
        if (program != null && channel != null) {
            Row(
                modifier = Modifier.fillMaxSize(),
                verticalAlignment = Alignment.Top
            ) {
                // Program thumb or channel logo
                val imageUrl = program.thumb ?: program.art ?: channel.logoUrl
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .size(120.dp)
                            .clip(RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                }

                Column(modifier = Modifier.weight(1f)) {
                    // Channel name
                    Text(
                        text = channel.displayName,
                        color = Color.Gray,
                        fontSize = 12.sp
                    )

                    // Program title
                    Text(
                        text = program.displayTitle,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    // Time
                    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                    val startStr = timeFormat.format(Date(program.startTime * 1000))
                    val endStr = timeFormat.format(Date(program.endTime * 1000))
                    Text(
                        text = "$startStr - $endStr",
                        color = Color.Gray,
                        fontSize = 14.sp
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Badges
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        program.badges.take(4).forEach { badge ->
                            ProgramBadgeChip(badge)
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Description
                    if (program.description != null) {
                        Text(
                            text = program.description,
                            color = Color.Gray,
                            fontSize = 13.sp,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        } else {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Select a program to see details",
                    color = Color.Gray,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun ProgramBadgeChip(badge: ProgramBadge) {
    val (text, color) = when (badge) {
        ProgramBadge.NEW -> "NEW" to Color(0xFF10B981)
        ProgramBadge.LIVE -> "LIVE" to Color.Red
        ProgramBadge.PREMIERE -> "PREMIERE" to Color(0xFF8B5CF6)
        ProgramBadge.FINALE -> "FINALE" to Color(0xFFF97316)
        ProgramBadge.SPORTS -> "SPORTS" to Color(0xFF10B981)
        ProgramBadge.MOVIE -> "MOVIE" to Color(0xFF8B5CF6)
        ProgramBadge.RECORDING -> "REC" to Color.Red
        ProgramBadge.CATCHUP -> "CATCHUP" to Color(0xFF8B5CF6)  // Purple for catch-up
    }

    Surface(
        color = color.copy(alpha = 0.2f),
        shape = RoundedCornerShape(4.dp)
    ) {
        Text(
            text = text,
            color = color,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
        )
    }
}

@Composable
private fun ChannelColumn(
    channels: List<ChannelWithPrograms>,
    focusedIndex: Int,
    channelListState: androidx.compose.foundation.lazy.LazyListState
) {
    LazyColumn(
        state = channelListState,
        modifier = Modifier
            .width(CHANNEL_WIDTH)
            .background(Color(0xFF0a0a14))
    ) {
        // Time header spacer
        item {
            Spacer(modifier = Modifier.height(TIME_HEADER_HEIGHT))
        }

        itemsIndexed(channels) { index, channelWithPrograms ->
            val channel = channelWithPrograms.channel
            val isFocused = index == focusedIndex

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(ROW_HEIGHT)
                    .background(
                        if (isFocused) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                        else Color.Transparent
                    )
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Channel logo
                AsyncImage(
                    model = channel.logoUrl,
                    contentDescription = null,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    contentScale = ContentScale.Fit
                )

                Spacer(modifier = Modifier.width(8.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = channel.number ?: "",
                        color = Color.Gray,
                        fontSize = 11.sp
                    )
                    Text(
                        text = channel.name,
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (channel.favorite) {
                    Icon(
                        Icons.Default.Star,
                        contentDescription = null,
                        tint = Color.Yellow,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun TimeHeader(
    startTimeSeconds: Long,
    endTimeSeconds: Long,
    scrollState: ScrollState
) {
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
    val durationMinutes = ((endTimeSeconds - startTimeSeconds) / 60).toInt()
    val numSlots = durationMinutes / 30

    Row(
        modifier = Modifier
            .height(TIME_HEADER_HEIGHT)
            .horizontalScroll(scrollState)
            .background(Color(0xFF16213e))
    ) {
        repeat(numSlots) { index ->
            val slotTimeMs = (startTimeSeconds + (index * 30 * 60)) * 1000
            val timeStr = timeFormat.format(Date(slotTimeMs))

            Box(
                modifier = Modifier
                    .width(TIME_SLOT_WIDTH)
                    .fillMaxHeight()
                    .border(
                        width = 0.5.dp,
                        color = Color.Gray.copy(alpha = 0.3f)
                    ),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(
                    text = timeStr,
                    color = Color.White,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }
    }

    // Current time indicator line
    CurrentTimeIndicator(
        startTimeSeconds = startTimeSeconds,
        scrollState = scrollState
    )
}

@Composable
private fun CurrentTimeIndicator(
    startTimeSeconds: Long,
    scrollState: ScrollState
) {
    val now = System.currentTimeMillis() / 1000
    if (now < startTimeSeconds) return

    val minutesSinceStart = ((now - startTimeSeconds) / 60).toInt()
    val pixelsPerMinute = with(LocalDensity.current) { TIME_SLOT_WIDTH.toPx() / 30 }
    val offsetPx = minutesSinceStart * pixelsPerMinute - scrollState.value

    if (offsetPx > 0) {
        Box(
            modifier = Modifier
                .offset(x = with(LocalDensity.current) { offsetPx.toDp() })
                .width(2.dp)
                .fillMaxHeight()
                .background(Color.Red)
        )
    }
}

@Composable
private fun ProgramGrid(
    channels: List<ChannelWithPrograms>,
    startTimeSeconds: Long,
    endTimeSeconds: Long,
    focusedChannelIndex: Int,
    focusedProgramIndex: Int,
    horizontalScrollState: ScrollState,
    channelListState: androidx.compose.foundation.lazy.LazyListState,
    onProgramClick: (channelId: String, program: Program, hasCatchup: Boolean) -> Unit
) {
    val pixelsPerMinute = TIME_SLOT_WIDTH.value / 30

    LazyColumn(
        state = channelListState,
        modifier = Modifier.fillMaxSize()
    ) {
        itemsIndexed(channels) { channelIndex, channelWithPrograms ->
            val isChannelFocused = channelIndex == focusedChannelIndex

            Row(
                modifier = Modifier
                    .height(ROW_HEIGHT)
                    .horizontalScroll(horizontalScrollState)
            ) {
                val programs = channelWithPrograms.programs
                if (programs.isEmpty()) {
                    // No programs - show empty row
                    val durationMinutes = ((endTimeSeconds - startTimeSeconds) / 60).toInt()
                    val width = (durationMinutes * pixelsPerMinute).dp

                    Box(
                        modifier = Modifier
                            .width(width)
                            .fillMaxHeight()
                            .background(Color(0xFF1f1f3d))
                            .border(0.5.dp, Color.Gray.copy(alpha = 0.2f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No program info",
                            color = Color.Gray,
                            fontSize = 12.sp
                        )
                    }
                } else {
                    programs.forEachIndexed { programIndex, program ->
                        val programStart = program.startTime.coerceAtLeast(startTimeSeconds)
                        val programEnd = program.endTime.coerceAtMost(endTimeSeconds)

                        if (programEnd > programStart) {
                            val durationMinutes = ((programEnd - programStart) / 60).toInt()
                            val width = (durationMinutes * pixelsPerMinute).dp

                            val isFocused = isChannelFocused && programIndex == focusedProgramIndex
                            val genreColor = Color(EPGGenreColors.getColor(program.genres.firstOrNull()))

                            ProgramCell(
                                program = program,
                                width = width,
                                isFocused = isFocused,
                                genreColor = genreColor,
                                hasCatchup = channelWithPrograms.channel.archiveEnabled,
                                onClick = {
                                    onProgramClick(
                                        channelWithPrograms.channel.id,
                                        program,
                                        channelWithPrograms.channel.archiveEnabled
                                    )
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ProgramCell(
    program: Program,
    width: Dp,
    isFocused: Boolean,
    genreColor: Color,
    hasCatchup: Boolean = false,  // Whether channel has archive enabled
    onClick: () -> Unit
) {
    val progress = program.progress
    val isAiring = program.isAiring

    Box(
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .padding(1.dp)
            .clip(RoundedCornerShape(4.dp))
            .background(
                if (isFocused) genreColor.copy(alpha = 0.5f)
                else genreColor.copy(alpha = 0.2f)
            )
            .border(
                width = if (isFocused) 2.dp else 0.dp,
                color = if (isFocused) MaterialTheme.colorScheme.primary else Color.Transparent,
                shape = RoundedCornerShape(4.dp)
            )
            .clickable { onClick() }
            .padding(8.dp)
    ) {
        Column {
            Text(
                text = program.title,
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            if (program.episodeInfo != null) {
                Text(
                    text = program.episodeInfo!!,
                    color = Color.Gray,
                    fontSize = 11.sp
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Progress bar for currently airing
            if (isAiring && progress > 0) {
                @Suppress("DEPRECATION")
                LinearProgressIndicator(
                    progress = progress,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .clip(RoundedCornerShape(2.dp)),
                    color = genreColor,
                    trackColor = Color.Gray.copy(alpha = 0.3f)
                )
            }
        }

        // Badges in top-right
        Row(
            modifier = Modifier.align(Alignment.TopEnd),
            horizontalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            if (program.isLive) {
                Surface(
                    color = Color.Red,
                    shape = RoundedCornerShape(2.dp)
                ) {
                    Text(
                        text = "LIVE",
                        color = Color.White,
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                    )
                }
            }
            if (program.isNew) {
                Surface(
                    color = Color(0xFF10B981),
                    shape = RoundedCornerShape(2.dp)
                ) {
                    Text(
                        text = "NEW",
                        color = Color.White,
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                    )
                }
            }
            // CATCHUP badge for past programs with archive available
            if (program.isPast && hasCatchup) {
                Surface(
                    color = Color(0xFF8B5CF6),  // Purple
                    shape = RoundedCornerShape(2.dp)
                ) {
                    Text(
                        text = "CATCHUP",
                        color = Color.White,
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                    )
                }
            }
        }
    }
}
