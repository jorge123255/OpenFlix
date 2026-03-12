package com.openflix.presentation.components.livetv

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.*

private val CHANNEL_COL_WIDTH = 160.dp
private val PX_PER_MIN = 4.dp
private val ROW_HEIGHT = 56.dp
private val TIME_HEADER_HEIGHT = 32.dp

@Composable
fun LandscapeEPGGrid(
    channels: List<ChannelWithPrograms>,
    startTime: Long,
    endTime: Long,
    onProgramClick: (ChannelWithPrograms, Program) -> Unit,
    onChannelClick: (ChannelWithPrograms) -> Unit,
    modifier: Modifier = Modifier
) {
    val now = remember { System.currentTimeMillis() / 1000 }
    val totalMinutes = ((endTime - startTime) / 60).toInt()
    val timeSlots = remember(startTime, endTime) {
        (0 until totalMinutes / 30).map { startTime + (it * 30 * 60) }
    }
    val nowOffset = remember(now, startTime) {
        ((now - startTime) / 60f) * PX_PER_MIN.value
    }
    val scrollState = rememberScrollState()

    Column(modifier = modifier.fillMaxSize()) {
        // Time header row
        Row(Modifier.fillMaxWidth()) {
            // Channel column spacer
            Box(
                Modifier
                    .width(CHANNEL_COL_WIDTH)
                    .height(TIME_HEADER_HEIGHT)
                    .background(OpenFlixColors.Background)
            )

            // Time slots
            Row(
                Modifier
                    .weight(1f)
                    .horizontalScroll(scrollState)
                    .height(TIME_HEADER_HEIGHT)
                    .background(OpenFlixColors.Background)
            ) {
                timeSlots.forEach { slotTime ->
                    Box(
                        modifier = Modifier
                            .width(PX_PER_MIN * 30)
                            .fillMaxHeight(),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Text(
                            text = formatTimeSlot(slotTime),
                            color = OpenFlixColors.TextTertiary,
                            fontSize = 11.sp,
                            modifier = Modifier.padding(start = 4.dp)
                        )
                    }
                }
            }
        }

        // Grid rows
        LazyColumn(Modifier.weight(1f)) {
            items(channels, key = { it.channel.id }) { cwp ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .height(ROW_HEIGHT)
                ) {
                    // Fixed channel column
                    ChannelCell(
                        cwp = cwp,
                        onClick = { onChannelClick(cwp) }
                    )

                    // Program cells (scrolls horizontally)
                    Row(
                        Modifier
                            .weight(1f)
                            .horizontalScroll(scrollState)
                    ) {
                        Box {
                            Row {
                                cwp.programs
                                    .filter { it.endTime > startTime && it.startTime < endTime }
                                    .forEach { program ->
                                        val progStart = maxOf(program.startTime, startTime)
                                        val progEnd = minOf(program.endTime, endTime)
                                        val durationMins = ((progEnd - progStart) / 60f)
                                        val offsetMins = ((progStart - startTime) / 60f)
                                        val cellWidth = (durationMins * PX_PER_MIN.value).dp

                                        if (cellWidth > 0.dp) {
                                            ProgramCell(
                                                program = program,
                                                width = cellWidth,
                                                now = now,
                                                onClick = { onProgramClick(cwp, program) }
                                            )
                                        }
                                    }
                            }

                            // Now line
                            if (nowOffset > 0 && nowOffset < totalMinutes * PX_PER_MIN.value) {
                                Box(
                                    Modifier
                                        .offset(x = nowOffset.dp)
                                        .width(2.dp)
                                        .fillMaxHeight()
                                        .background(
                                            Brush.verticalGradient(
                                                listOf(
                                                    OpenFlixColors.LiveIndicator,
                                                    OpenFlixColors.LiveIndicator.copy(0.5f)
                                                )
                                            )
                                        )
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ChannelCell(
    cwp: ChannelWithPrograms,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .width(CHANNEL_COL_WIDTH)
            .fillMaxHeight()
            .background(OpenFlixColors.Surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (cwp.channel.logoUrl != null) {
            AsyncImage(
                model = cwp.channel.logoUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(4.dp)),
                contentScale = ContentScale.Fit
            )
            Spacer(Modifier.width(6.dp))
        }
        Column(Modifier.weight(1f)) {
            if (!cwp.channel.number.isNullOrBlank()) {
                Text(
                    text = cwp.channel.number,
                    color = OpenFlixColors.TextTertiary,
                    fontSize = 10.sp
                )
            }
            Text(
                text = cwp.channel.name,
                color = OpenFlixColors.TextPrimary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun ProgramCell(
    program: Program,
    width: Dp,
    now: Long,
    onClick: () -> Unit
) {
    val isAiring = now in program.startTime..program.endTime
    val isPast = now > program.endTime
    val bgColor = when {
        isAiring -> OpenFlixColors.Primary.copy(alpha = 0.12f)
        isPast -> OpenFlixColors.SurfaceVariant.copy(alpha = 0.6f)
        else -> OpenFlixColors.SurfaceVariant
    }

    Box(
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .padding(0.5.dp)
            .clip(RoundedCornerShape(4.dp))
            .background(bgColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 6.dp, vertical = 4.dp)
    ) {
        Column {
            Text(
                text = program.title,
                color = if (isPast) OpenFlixColors.TextTertiary else OpenFlixColors.TextPrimary,
                fontSize = 11.sp,
                fontWeight = if (isAiring) FontWeight.SemiBold else FontWeight.Normal,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            if (program.episodeTitle != null && width > 80.dp) {
                Text(
                    text = program.episodeTitle,
                    color = OpenFlixColors.TextTertiary,
                    fontSize = 10.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        // Badges
        if (program.isLive || program.isNew) {
            Row(
                modifier = Modifier.align(Alignment.TopEnd),
                horizontalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                if (program.isLive) {
                    Box(
                        Modifier
                            .background(OpenFlixColors.LiveIndicator, RoundedCornerShape(2.dp))
                            .padding(horizontal = 3.dp, vertical = 1.dp)
                    ) {
                        Text("LIVE", color = Color.White, fontSize = 7.sp, fontWeight = FontWeight.Bold)
                    }
                }
                if (program.isNew) {
                    Box(
                        Modifier
                            .background(OpenFlixColors.Success, RoundedCornerShape(2.dp))
                            .padding(horizontal = 3.dp, vertical = 1.dp)
                    ) {
                        Text("NEW", color = Color.White, fontSize = 7.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

private fun formatTimeSlot(unixSeconds: Long): String {
    val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
    return sdf.format(Date(unixSeconds * 1000))
}
