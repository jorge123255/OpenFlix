package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.currentTimeMs
import com.openflix.ui.viewmodel.GuideDay
import com.openflix.ui.viewmodel.LiveTVViewModel
import org.koin.compose.viewmodel.koinViewModel

// Xfinity-style colors
private val BgColor = Color(0xFF110C21)
private val AccentPurple = Color(0xFF6138F5)
private val CardBg = Color(0xFF1A142E)
private val SurfaceColor = Color(0xFF1E1636)
private val NowCellBg = Color(0xFF2A1860)   // Opaque dark purple for "now" cells (no bleed-through)
private val NowLineColor = Color(0xFFFF4081)

// Dimensions
private val CHANNEL_WIDTH = 110.dp
private val SLOT_WIDTH = 200.dp  // Width per hour
private val ROW_HEIGHT = 72.dp
private val HEADER_HEIGHT = 36.dp

@Composable
fun LiveTVScreen(
    onChannelClick: (Channel) -> Unit = {},
    onGuideClick: () -> Unit = {},
    viewModel: LiveTVViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val guide = uiState.guide
    val horizontalScroll = rememberScrollState()
    val density = LocalDensity.current

    LaunchedEffect(Unit) {
        viewModel.ensureGuideLoaded()
    }

    val selectedDay = uiState.guideDays.getOrNull(uiState.selectedDayIndex)
    val isToday = uiState.selectedDayIndex == 0

    // For today: calculate the start hour (current hour floor) so we don't show past
    val nowMs = currentTimeMs()
    val nowSec = nowMs / 1000

    // The visible window start for today: current hour (floored)
    val viewStartSec: Long = if (isToday && selectedDay != null) {
        val hoursSinceStart = ((nowSec - selectedDay.startSec) / 3600L)
        selectedDay.startSec + hoursSinceStart * 3600L
    } else {
        selectedDay?.startSec ?: 0L
    }
    val viewEndSec: Long = selectedDay?.endSec ?: 0L

    // Hours to display
    val hoursToShow: Int = if (selectedDay != null) {
        ((viewEndSec - viewStartSec) / 3600L).toInt().coerceIn(1, 24)
    } else 24

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
    ) {
        // Day picker — extra left padding for hamburger button
        if (uiState.guideDays.isNotEmpty()) {
            LazyRow(
                contentPadding = PaddingValues(start = 56.dp, end = 12.dp, top = 10.dp, bottom = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.guideDays.size) { index ->
                    val day = uiState.guideDays[index]
                    val isSelected = index == uiState.selectedDayIndex
                    DayChip(
                        day = day,
                        isSelected = isSelected,
                        onClick = { viewModel.selectGuideDay(index) }
                    )
                }
            }
        }

        when {
            uiState.isLoading && guide.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(color = AccentPurple, modifier = Modifier.size(32.dp))
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Loading channels...", color = Color.Gray, fontSize = 14.sp)
                    }
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text("Failed to load", color = Color.White, fontSize = 16.sp)
                        Text(uiState.error ?: "", color = Color.Gray, fontSize = 13.sp)
                        TextButton(onClick = { viewModel.refresh() }) {
                            Text("Retry", color = AccentPurple)
                        }
                    }
                }
            }
            uiState.channels.isEmpty() && !uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No channels available", color = Color.Gray, fontSize = 16.sp)
                }
            }
            else -> {
                // Loading bar for day switching
                if (uiState.isGuideLoading) {
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth().height(2.dp),
                        color = AccentPurple,
                        trackColor = Color.Transparent
                    )
                }

                // Now line offset (relative to viewStartSec)
                val nowOffsetDp: Dp? = if (isToday && selectedDay != null) {
                    val elapsedHours = ((nowSec - viewStartSec).toFloat() / 3600f).coerceAtLeast(0f)
                    (elapsedHours * SLOT_WIDTH.value).dp
                } else null

                // Time ruler header
                Row(modifier = Modifier.fillMaxWidth()) {
                    Box(
                        modifier = Modifier
                            .width(CHANNEL_WIDTH)
                            .height(HEADER_HEIGHT)
                            .background(BgColor),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Text(
                            text = "Channel",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.Gray,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(HEADER_HEIGHT)
                            .horizontalScroll(horizontalScroll)
                    ) {
                        Row(modifier = Modifier.background(BgColor)) {
                            TimeRuler(
                                startSec = viewStartSec,
                                hours = hoursToShow,
                                isToday = isToday
                            )
                        }
                        if (nowOffsetDp != null) {
                            Box(
                                modifier = Modifier
                                    .offset(x = nowOffsetDp)
                                    .width(2.dp)
                                    .fillMaxHeight()
                                    .background(NowLineColor)
                            )
                        }
                    }
                }

                // EPG Grid
                val displayData = if (guide.isNotEmpty()) {
                    guide
                } else {
                    uiState.channels.map { ChannelWithPrograms(it, emptyList()) }
                }

                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(displayData, key = { it.id }) { channelWithPrograms ->
                        Row(modifier = Modifier.fillMaxWidth()) {
                            GuideChannelCell(
                                channel = channelWithPrograms.channel,
                                onClick = { onChannelClick(channelWithPrograms.channel) }
                            )

                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(ROW_HEIGHT)
                                    .horizontalScroll(horizontalScroll)
                            ) {
                                GuideProgramRow(
                                    programs = channelWithPrograms.programs,
                                    viewStartSec = viewStartSec,
                                    viewEndSec = viewEndSec,
                                    hoursToShow = hoursToShow,
                                    isToday = isToday,
                                    onProgramClick = { }
                                )
                                if (nowOffsetDp != null) {
                                    Box(
                                        modifier = Modifier
                                            .offset(x = nowOffsetDp)
                                            .width(1.dp)
                                            .fillMaxHeight()
                                            .background(NowLineColor.copy(alpha = 0.5f))
                                    )
                                }
                            }
                        }

                        HorizontalDivider(
                            color = Color.White.copy(alpha = 0.05f),
                            thickness = 0.5.dp
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Day Chip

@Composable
private fun DayChip(
    day: GuideDay,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(
                when {
                    isFocused -> AccentPurple.copy(alpha = 0.6f)
                    isSelected -> AccentPurple
                    else -> CardBg
                }
            )
            .then(
                if (isFocused) Modifier.border(2.dp, Color.White, RoundedCornerShape(10.dp))
                else Modifier
            )
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = day.label,
                fontSize = 14.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                color = if (isSelected) Color.White else Color.White.copy(alpha = 0.6f)
            )
            Text(
                text = day.dateLabel,
                fontSize = 11.sp,
                color = if (isSelected) Color.White.copy(alpha = 0.8f) else Color.White.copy(alpha = 0.35f)
            )
        }
    }
}

// MARK: - Time Ruler

@Composable
private fun TimeRuler(startSec: Long, hours: Int, isToday: Boolean) {
    val nowSec = currentTimeMs() / 1000

    for (h in 0 until hours) {
        val slotSec = startSec + (h * 3600L)
        val isNowHour = isToday && slotSec <= nowSec && nowSec < slotSec + 3600L
        val label = if (isNowHour) "Now" else formatEpochTimeSec(slotSec)

        Box(
            modifier = Modifier
                .width(SLOT_WIDTH)
                .height(HEADER_HEIGHT),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = if (isNowHour) FontWeight.Bold else FontWeight.Medium,
                color = if (isNowHour) NowLineColor else Color.Gray,
                modifier = Modifier.padding(start = 8.dp)
            )
        }
    }
}

// MARK: - Channel Cell

@Composable
private fun GuideChannelCell(
    channel: Channel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier
            .width(CHANNEL_WIDTH)
            .height(ROW_HEIGHT)
            .background(if (isFocused) AccentPurple.copy(alpha = 0.2f) else BgColor)
            .then(
                if (isFocused) Modifier.border(2.dp, AccentPurple)
                else Modifier
            )
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .clickable(onClick = onClick)
            .padding(horizontal = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        if (channel.logo != null) {
            AsyncImage(
                model = channel.logo,
                contentDescription = channel.name,
                modifier = Modifier.size(width = 32.dp, height = 22.dp),
                contentScale = ContentScale.Fit
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            channel.number?.let { number ->
                Text(
                    text = number.toString(),
                    fontSize = 10.sp,
                    color = Color.Gray
                )
            }
            Text(
                text = channel.name,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Program Row

@Composable
private fun GuideProgramRow(
    programs: List<Program>,
    viewStartSec: Long,
    viewEndSec: Long,
    hoursToShow: Int,
    isToday: Boolean,
    onProgramClick: (Program) -> Unit
) {
    val now = currentTimeMs()
    val viewStartMs = viewStartSec * 1000L
    val viewEndMs = viewEndSec * 1000L
    val totalWidth = SLOT_WIDTH * hoursToShow

    // Only show programs that overlap with the visible window
    val visiblePrograms = programs.filter { it.endTimeMs > viewStartMs && it.startTimeMs < viewEndMs }

    Box(
        modifier = Modifier
            .width(totalWidth)
            .height(ROW_HEIGHT)
    ) {
        if (visiblePrograms.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(vertical = 4.dp, horizontal = 1.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(SurfaceColor.copy(alpha = 0.3f)),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(
                    text = "No listings",
                    fontSize = 11.sp,
                    color = Color.Gray.copy(alpha = 0.4f),
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }

        // Draw non-now cells first, then now cells on top so they're not obscured
        val sortedPrograms = visiblePrograms.sortedBy { program ->
            if (isToday && program.startTimeMs <= now && program.endTimeMs > now) 1 else 0
        }

        sortedPrograms.forEach { program ->
            // Clamp to visible window
            val clampedStartMs = maxOf(program.startTimeMs, viewStartMs)
            val clampedEndMs = minOf(program.endTimeMs, viewEndMs)

            val startHours = (clampedStartMs - viewStartMs).toFloat() / 3_600_000f
            val durationHours = (clampedEndMs - clampedStartMs).toFloat() / 3_600_000f

            val xOffset = SLOT_WIDTH * startHours
            val width = maxOf(SLOT_WIDTH * durationHours, 50.dp)

            val isNow = isToday && program.startTimeMs <= now && program.endTimeMs > now
            val progress = if (isNow) {
                ((now - program.startTimeMs).toFloat() / (program.endTimeMs - program.startTimeMs).toFloat()).coerceIn(0f, 1f)
            } else 0f

            // Now cells use opaque background so underlying cell text doesn't bleed through
            val cellBg = if (isNow) NowCellBg else SurfaceColor

            var cellFocused by remember { mutableStateOf(false) }
            Box(
                modifier = Modifier
                    .offset(x = xOffset)
                    .width(width)
                    .height(ROW_HEIGHT - 4.dp)
                    .padding(vertical = 2.dp, horizontal = 1.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .clipToBounds()
                    .background(if (cellFocused) AccentPurple.copy(alpha = 0.5f) else cellBg)
                    .then(
                        when {
                            cellFocused -> Modifier.border(2.dp, Color.White, RoundedCornerShape(6.dp))
                            isNow -> Modifier.border(1.dp, AccentPurple.copy(alpha = 0.7f), RoundedCornerShape(6.dp))
                            else -> Modifier.border(0.5.dp, Color.White.copy(alpha = 0.05f), RoundedCornerShape(6.dp))
                        }
                    )
                    .onFocusChanged { cellFocused = it.isFocused }
                    .focusable()
                    .clickable { onProgramClick(program) }
                    .padding(horizontal = 8.dp, vertical = 6.dp)
            ) {
                Column(
                    modifier = Modifier.fillMaxHeight(),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = program.title,
                        fontSize = 13.sp,
                        fontWeight = if (isNow) FontWeight.SemiBold else FontWeight.Normal,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(2.dp))

                    if (isNow) {
                        // Progress bar
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(3.dp)
                                .clip(RoundedCornerShape(999.dp))
                                .background(Color.White.copy(alpha = 0.15f))
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(progress)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(999.dp))
                                    .background(AccentPurple)
                            )
                        }
                    } else {
                        Text(
                            text = formatEpochTime(program.startTimeMs),
                            fontSize = 10.sp,
                            color = Color.White.copy(alpha = 0.4f)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Time Formatting

private fun formatEpochTime(epochMs: Long): String {
    return formatEpochTimeSec(epochMs / 1000)
}

private fun formatEpochTimeSec(epochSec: Long): String {
    val totalMinutes = (epochSec / 60) % (24 * 60)
    val hour24 = (totalMinutes / 60).toInt()
    val minute = (totalMinutes % 60).toInt()
    val hour12 = when {
        hour24 == 0 -> 12
        hour24 > 12 -> hour24 - 12
        else -> hour24
    }
    val amPm = if (hour24 < 12) "am" else "pm"
    return if (minute == 0) "${hour12}${amPm}" else "${hour12}:${minute.toString().padStart(2, '0')}${amPm}"
}
