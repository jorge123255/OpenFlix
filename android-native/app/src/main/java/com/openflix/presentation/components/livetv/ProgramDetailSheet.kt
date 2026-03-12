package com.openflix.presentation.components.livetv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProgramDetailSheet(
    program: Program,
    channel: Channel?,
    onDismiss: () -> Unit,
    onPlay: () -> Unit,
    onRecord: () -> Unit,
    onSeriesRecord: () -> Unit,
    isSchedulingRecording: Boolean = false
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = OpenFlixColors.Surface,
        contentColor = OpenFlixColors.TextPrimary,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 12.dp, bottom = 8.dp)
                    .width(32.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(OpenFlixColors.TextTertiary)
            )
        }
    ) {
        ProgramDetailContent(
            program = program,
            channel = channel,
            onPlay = onPlay,
            onRecord = onRecord,
            onSeriesRecord = onSeriesRecord,
            isSchedulingRecording = isSchedulingRecording
        )
    }
}

@Composable
fun ProgramDetailContent(
    program: Program,
    channel: Channel?,
    onPlay: () -> Unit,
    onRecord: () -> Unit,
    onSeriesRecord: () -> Unit,
    isSchedulingRecording: Boolean = false
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 32.dp)
    ) {
        // Program art if available
        program.art?.let { artUrl ->
            AsyncImage(
                model = artUrl,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .clip(RoundedCornerShape(12.dp)),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Title
        Text(
            text = program.title,
            color = OpenFlixColors.TextPrimary,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )

        // Episode info
        program.episodeInfo?.let { epInfo ->
            Text(
                text = epInfo,
                color = OpenFlixColors.TextSecondary,
                fontSize = 14.sp,
                modifier = Modifier.padding(top = 2.dp)
            )
        }

        // Subtitle / episode title
        program.episodeTitle?.let { subtitle ->
            Text(
                text = subtitle,
                color = OpenFlixColors.TextSecondary,
                fontSize = 15.sp,
                modifier = Modifier.padding(top = 4.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Air time + channel
        val timeStr = "${formatTime(program.startTime)} - ${formatTime(program.endTime)}"
        val channelStr = channel?.let { " on ${it.name}" } ?: ""
        Text(
            text = timeStr + channelStr,
            color = OpenFlixColors.TextTertiary,
            fontSize = 13.sp
        )

        // Progress bar for currently airing
        if (program.isAiring) {
            LinearProgressIndicator(
                progress = program.progress,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp)),
                color = OpenFlixColors.Primary,
                trackColor = OpenFlixColors.ProgressBackground
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Badges
        if (program.badges.isNotEmpty()) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                program.badges.forEach { badge ->
                    ProgramBadgeChip(badge)
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Rating
        program.rating?.let { rating ->
            Text(
                text = rating,
                color = OpenFlixColors.TextTertiary,
                fontSize = 12.sp,
                modifier = Modifier.padding(bottom = 8.dp)
            )
        }

        // Description
        program.description?.let { desc ->
            Text(
                text = desc,
                color = OpenFlixColors.TextSecondary,
                fontSize = 14.sp,
                lineHeight = 20.sp,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }

        // Genres
        if (program.genres.isNotEmpty()) {
            Text(
                text = program.genres.joinToString(" | "),
                color = OpenFlixColors.TextTertiary,
                fontSize = 12.sp,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }

        // Action buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Play button
            if (program.isAiring) {
                Button(
                    onClick = onPlay,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OpenFlixColors.Primary,
                        contentColor = Color.Black
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Icon(
                        Icons.Default.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Watch", fontWeight = FontWeight.Bold)
                }
            }

            // Record button
            Button(
                onClick = onRecord,
                modifier = Modifier.weight(1f),
                enabled = !isSchedulingRecording && !program.hasRecording,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (program.hasRecording) OpenFlixColors.SurfaceVariant
                        else OpenFlixColors.Error.copy(alpha = 0.9f),
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                if (isSchedulingRecording) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        Icons.Default.FiberManualRecord,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    if (program.hasRecording) "Scheduled" else "Record",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
            }
        }

        // Series pass button (if it has a series ID)
        if (program.seriesId != null) {
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(
                onClick = onSeriesRecord,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isSchedulingRecording,
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = OpenFlixColors.Primary
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Icon(
                    Icons.Default.Repeat,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("Series Pass", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

private fun formatTime(unixSeconds: Long): String {
    val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
    return sdf.format(Date(unixSeconds * 1000))
}
