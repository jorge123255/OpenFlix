package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
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

// Guide theme colors
private val GuideBg = Color(0xFF0D0D0D)
private val GuideSurface = Color(0xFF1A1A1A)
private val GuideAccent = Color(0xFF6C3DF8)
private val GuideLive = Color(0xFFFF4081)
private val NowLineColor = Color(0xFFFF4081)

// Dimensions
private val CHANNEL_WIDTH = 110.dp
private val SLOT_WIDTH = 240.dp  // Width per hour
private val ROW_HEIGHT = 64.dp
private val HEADER_HEIGHT = 36.dp

@Composable
fun GuideScreen(
    onChannelClick: (String) -> Unit = {},
    onBack: () -> Unit = {},
    viewModel: LiveTVViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val guide = uiState.guide
    val horizontalScroll = rememberScrollState()
    val density = LocalDensity.current

    // Load guide data when screen opens
    LaunchedEffect(Unit) {
        viewModel.ensureGuideLoaded()
    }

    val selectedDay = uiState.guideDays.getOrNull(uiState.selectedDayIndex)
    val isToday = uiState.selectedDayIndex == 0

    // Auto-scroll to "now" for today, or to start for other days
    LaunchedEffect(guide, uiState.selectedDayIndex) {
        if (guide.isNotEmpty() && selectedDay != null) {
            if (isToday) {
                val nowSec = currentTimeMs() / 1000
                val elapsedHours = ((nowSec - selectedDay.startSec).toFloat() / 3600f).coerceAtLeast(0f)
                // Center "now" in the view — scroll so now is ~1/3 from left
                val nowDp = elapsedHours * SLOT_WIDTH.value
                val scrollTarget = with(density) { ((nowDp - 80f) * density.density).toInt() }
                if (scrollTarget > 0) {
                    horizontalScroll.animateScrollTo(scrollTarget.coerceAtMost(horizontalScroll.maxValue))
                }
            } else {
                // Scroll to beginning for non-today days
                horizontalScroll.animateScrollTo(0)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(GuideBg)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "TV Guide",
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "✕",
                fontSize = 20.sp,
                color = Color.White,
                modifier = Modifier
                    .clip(RoundedCornerShape(999.dp))
                    .clickable(onClick = onBack)
                    .padding(8.dp)
            )
        }

        // Day picker — always show
        if (uiState.guideDays.isNotEmpty()) {
            LazyRow(
                contentPadding = PaddingValues(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 10.dp)
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

        // Loading overlay for initial load
        if (uiState.isLoading && guide.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(32.dp))
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Loading guide...", color = Color.Gray, fontSize = 14.sp)
                }
            }
        } else if (guide.isEmpty() && !uiState.isGuideLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("No guide data available", color = Color.Gray, fontSize = 16.sp)
            }
        } else {
            // Loading bar for day switching
            if (uiState.isGuideLoading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth().height(2.dp),
                    color = GuideAccent,
                    trackColor = Color.Transparent
                )
            }

            // Calculate "now" position for the red line
            val nowOffsetDp: Dp? = if (isToday && selectedDay != null) {
                val nowSec = currentTimeMs() / 1000
                val elapsedHours = ((nowSec - selectedDay.startSec).toFloat() / 3600f).coerceAtLeast(0f)
                (elapsedHours * SLOT_WIDTH.value).dp
            } else null

            // Time ruler header
            Row(modifier = Modifier.fillMaxWidth()) {
                // Channel column header
                Box(
                    modifier = Modifier
                        .width(CHANNEL_WIDTH)
                        .height(HEADER_HEIGHT)
                        .background(GuideBg),
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

                // Scrollable time ruler with now-line
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(HEADER_HEIGHT)
                        .horizontalScroll(horizontalScroll)
                ) {
                    Row(
                        modifier = Modifier.background(GuideBg)
                    ) {
                        if (selectedDay != null) {
                            TimeRuler(dayStartSec = selectedDay.startSec, isToday = isToday)
                        }
                    }
                    // Now line in header
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

            // Channel rows + program grid
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(guide, key = { it.id }) { channelWithPrograms ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        // Fixed channel cell
                        GuideChannelCell(
                            channel = channelWithPrograms.channel,
                            onClick = { onChannelClick(channelWithPrograms.channel.id) }
                        )

                        // Scrollable program row with now-line overlay
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(ROW_HEIGHT)
                                .horizontalScroll(horizontalScroll)
                        ) {
                            if (selectedDay != null) {
                                GuideProgramRow(
                                    programs = channelWithPrograms.programs,
                                    dayStartSec = selectedDay.startSec,
                                    dayEndSec = selectedDay.endSec,
                                    isToday = isToday,
                                    onProgramClick = { }
                                )
                            }
                            // Now line in each row
                            if (nowOffsetDp != null) {
                                Box(
                                    modifier = Modifier
                                        .offset(x = nowOffsetDp)
                                        .width(1.dp)
                                        .fillMaxHeight()
                                        .background(NowLineColor.copy(alpha = 0.6f))
                                )
                            }
                        }
                    }

                    HorizontalDivider(
                        color = Color.White.copy(alpha = 0.06f),
                        thickness = 0.5.dp
                    )
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
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (isSelected) GuideAccent else GuideSurface)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = day.label,
                fontSize = 14.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                color = if (isSelected) Color.White else Color.White.copy(alpha = 0.7f)
            )
            Text(
                text = day.dateLabel,
                fontSize = 11.sp,
                color = if (isSelected) Color.White.copy(alpha = 0.8f) else Color.White.copy(alpha = 0.4f)
            )
        }
    }
}

// MARK: - Time Ruler

@Composable
private fun TimeRuler(dayStartSec: Long, isToday: Boolean) {
    val nowMs = currentTimeMs()
    val nowSec = nowMs / 1000

    // 24 hours of slots
    for (hour in 0 until 24) {
        val slotSec = dayStartSec + (hour * 3600L)
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
    Row(
        modifier = Modifier
            .width(CHANNEL_WIDTH)
            .height(ROW_HEIGHT)
            .background(GuideBg)
            .clickable(onClick = onClick)
            .padding(horizontal = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        // Channel logo
        if (channel.logo != null) {
            AsyncImage(
                model = channel.logo,
                contentDescription = channel.name,
                modifier = Modifier.size(width = 28.dp, height = 20.dp),
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
    dayStartSec: Long,
    dayEndSec: Long,
    isToday: Boolean,
    onProgramClick: (Program) -> Unit
) {
    val now = currentTimeMs()
    val dayStartMs = dayStartSec * 1000L
    val dayEndMs = dayEndSec * 1000L

    // Total width = 24 hours * SLOT_WIDTH per hour
    val totalWidth = SLOT_WIDTH * 24

    val visiblePrograms = programs.filter { it.endTimeMs > dayStartMs && it.startTimeMs < dayEndMs }

    Box(
        modifier = Modifier
            .width(totalWidth)
            .height(ROW_HEIGHT)
    ) {
        if (visiblePrograms.isEmpty()) {
            // Show empty placeholder
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(vertical = 4.dp, horizontal = 1.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(GuideSurface.copy(alpha = 0.3f)),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(
                    text = "No listings",
                    fontSize = 11.sp,
                    color = Color.Gray.copy(alpha = 0.5f),
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }

        visiblePrograms.forEach { program ->
            val clampedStartMs = maxOf(program.startTimeMs, dayStartMs)
            val clampedEndMs = minOf(program.endTimeMs, dayEndMs)

            // Position based on hours from day start
            val startHours = (clampedStartMs - dayStartMs).toFloat() / 3_600_000f
            val durationHours = (clampedEndMs - clampedStartMs).toFloat() / 3_600_000f

            val xOffset = SLOT_WIDTH * startHours
            val width = maxOf(SLOT_WIDTH * durationHours, 40.dp)

            val isNow = isToday && program.startTimeMs <= now && program.endTimeMs > now
            val isPast = isToday && program.endTimeMs <= now
            val progress = if (isNow) {
                ((now - program.startTimeMs).toFloat() / (program.endTimeMs - program.startTimeMs).toFloat()).coerceIn(0f, 1f)
            } else 0f

            Box(
                modifier = Modifier
                    .offset(x = xOffset)
                    .width(width)
                    .height(ROW_HEIGHT - 4.dp)
                    .padding(vertical = 2.dp, horizontal = 1.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(
                        when {
                            isNow -> GuideAccent.copy(alpha = 0.25f)
                            isPast -> GuideSurface.copy(alpha = 0.4f)
                            else -> GuideSurface
                        }
                    )
                    .then(
                        if (isNow) Modifier.border(1.dp, GuideAccent.copy(alpha = 0.5f), RoundedCornerShape(6.dp))
                        else Modifier.border(0.5.dp, Color.White.copy(alpha = 0.06f), RoundedCornerShape(6.dp))
                    )
                    .clickable { onProgramClick(program) }
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Column(
                    modifier = Modifier.fillMaxHeight(),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = program.title,
                        fontSize = 12.sp,
                        fontWeight = if (isNow) FontWeight.SemiBold else FontWeight.Normal,
                        color = if (isPast) Color.Gray else Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    if (isNow) {
                        Spacer(modifier = Modifier.height(3.dp))
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
                                    .background(GuideAccent)
                            )
                        }
                    } else {
                        Text(
                            text = formatEpochTime(program.startTimeMs),
                            fontSize = 10.sp,
                            color = Color.Gray.copy(alpha = 0.7f)
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
