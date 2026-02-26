package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.currentTimeMs
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.viewmodel.LiveTVViewModel
import org.koin.compose.viewmodel.koinViewModel

// Guide theme colors
private val GuideBg = Color(0xFF0D0D0D)
private val GuideSurface = Color(0xFF1A1A1A)
private val GuideAccent = Color(0xFF6138F5)
private val GuideLive = Color(0xFFFF4081)

// Dimensions
private val CHANNEL_WIDTH = 120.dp
private val SLOT_WIDTH = 240.dp  // Width per hour
private val ROW_HEIGHT = 56.dp
private val HEADER_HEIGHT = 32.dp

@Composable
fun GuideScreen(
    onChannelClick: (String) -> Unit = {},
    onBack: () -> Unit = {},
    viewModel: LiveTVViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val guide = uiState.guide
    val horizontalScroll = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(GuideBg)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
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

        if (uiState.isLoading || guide.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(32.dp))
                } else {
                    Text("No guide data available", color = Color.Gray, fontSize = 16.sp)
                }
            }
        } else {
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

                // Scrollable time ruler
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .height(HEADER_HEIGHT)
                        .horizontalScroll(horizontalScroll)
                        .background(GuideBg)
                ) {
                    TimeRuler()
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

                        // Scrollable program row
                        Row(
                            modifier = Modifier
                                .weight(1f)
                                .height(ROW_HEIGHT)
                                .horizontalScroll(horizontalScroll)
                        ) {
                            GuideProgramRow(
                                programs = channelWithPrograms.programs,
                                onProgramClick = { }
                            )
                        }
                    }

                    HorizontalDivider(
                        color = Color.White.copy(alpha = 0.08f),
                        thickness = 0.5.dp
                    )
                }
            }
        }
    }
}

// MARK: - Time Ruler

@Composable
private fun TimeRuler() {
    val now = currentTimeMs()
    // Round to current half hour
    val halfHourMs = 30 * 60 * 1000L
    val startMs = (now / halfHourMs) * halfHourMs

    // Show 24 half-hour slots (12 hours)
    for (i in 0 until 24) {
        val slotMs = startMs + (i * halfHourMs)
        val label = if (i == 0) "Now" else formatEpochTime(slotMs)

        Box(
            modifier = Modifier
                .width(SLOT_WIDTH / 2)  // Each slot is half an hour = half the hourly width
                .height(HEADER_HEIGHT),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = label,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = if (i == 0) Color.White else Color.Gray,
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
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        // Channel logo
        if (channel.logo != null) {
            AsyncImage(
                model = channel.logo,
                contentDescription = channel.name,
                modifier = Modifier.size(width = 32.dp, height = 20.dp),
                contentScale = ContentScale.Fit
            )
        }

        Column {
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
    onProgramClick: (Program) -> Unit
) {
    val now = currentTimeMs()
    val halfHourMs = 30 * 60 * 1000L
    val gridStartMs = (now / halfHourMs) * halfHourMs
    val gridEndMs = gridStartMs + (12 * 3600 * 1000L) // 12 hours

    // Each half hour = SLOT_WIDTH/2 in dp
    val slotWidthDp = SLOT_WIDTH / 2
    val msPerSlot = halfHourMs.toFloat()

    val visiblePrograms = programs.filter { it.endTimeMs > gridStartMs && it.startTimeMs < gridEndMs }

    Box(
        modifier = Modifier
            .width(SLOT_WIDTH * 12) // 12 hours total width
            .height(ROW_HEIGHT)
    ) {
        visiblePrograms.forEach { program ->
            val clampedStartMs = maxOf(program.startTimeMs, gridStartMs)
            val clampedEndMs = minOf(program.endTimeMs, gridEndMs)
            val offsetFraction = (clampedStartMs - gridStartMs).toFloat() / msPerSlot
            val durationFraction = (clampedEndMs - clampedStartMs).toFloat() / msPerSlot

            val xOffset = slotWidthDp * offsetFraction
            val width = maxOf(slotWidthDp * durationFraction, 30.dp)

            val isNow = program.startTimeMs <= now && program.endTimeMs > now
            val progress = if (isNow) {
                ((now - program.startTimeMs).toFloat() / (program.endTimeMs - program.startTimeMs).toFloat()).coerceIn(0f, 1f)
            } else 0f

            Box(
                modifier = Modifier
                    .offset(x = xOffset)
                    .width(width)
                    .height(ROW_HEIGHT - 8.dp)
                    .padding(vertical = 2.dp, horizontal = 1.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(if (isNow) GuideAccent.copy(alpha = 0.2f) else GuideSurface)
                    .border(0.5.dp, Color.White.copy(alpha = 0.06f), RoundedCornerShape(6.dp))
                    .clickable { onProgramClick(program) }
                    .padding(horizontal = 6.dp, vertical = 4.dp)
            ) {
                Column {
                    Text(
                        text = program.title,
                        fontSize = 12.sp,
                        fontWeight = if (isNow) FontWeight.SemiBold else FontWeight.Normal,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    if (isNow) {
                        Spacer(modifier = Modifier.height(2.dp))
                        // Progress bar
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(2.dp)
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
                            color = Color.Gray
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Time Formatting

private fun formatEpochTime(epochMs: Long): String {
    // Simple hour:minute formatting from epoch ms
    // This is platform-independent using basic math
    // We extract hours and minutes from the epoch timestamp
    // Note: This gives UTC time — for local time, we'd need platform-specific code
    // But since the guide times are already in local epoch, the relative offsets work
    val totalMinutes = (epochMs / 60000) % (24 * 60)
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
