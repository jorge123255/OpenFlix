package com.openflix.presentation.components.livetv

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
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
import com.openflix.domain.model.ProgramBadge
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun XfinityChannelRow(
    channel: Channel,
    isFavorite: Boolean,
    onFavoriteToggle: () -> Unit,
    onChannelClick: () -> Unit,
    onProgramClick: (Program) -> Unit,
    modifier: Modifier = Modifier
) {
    val nowPlaying = channel.nowPlaying
    val upNext = channel.upNext

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(OpenFlixColors.Surface)
            .clickable(onClick = onChannelClick)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Favorite star
        IconButton(
            onClick = onFavoriteToggle,
            modifier = Modifier.size(32.dp)
        ) {
            Icon(
                imageVector = if (isFavorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                contentDescription = if (isFavorite) "Remove from favorites" else "Add to favorites",
                tint = if (isFavorite) Color(0xFFFFB800) else OpenFlixColors.TextTertiary,
                modifier = Modifier.size(20.dp)
            )
        }

        Spacer(modifier = Modifier.width(8.dp))

        // Channel logo + number
        Column(
            modifier = Modifier.width(56.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (channel.logoUrl != null) {
                AsyncImage(
                    model = channel.logoUrl,
                    contentDescription = channel.name,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(6.dp)),
                    contentScale = ContentScale.Fit
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(OpenFlixColors.SurfaceVariant),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = channel.name.take(2).uppercase(),
                        color = OpenFlixColors.TextSecondary,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            if (!channel.number.isNullOrBlank()) {
                Text(
                    text = channel.number,
                    color = OpenFlixColors.TextTertiary,
                    fontSize = 10.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Now playing + up next
        Column(
            modifier = Modifier.weight(1f)
        ) {
            // Now playing
            if (nowPlaying != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(4.dp))
                        .clickable { onProgramClick(nowPlaying) }
                        .padding(vertical = 2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = nowPlaying.title,
                                color = OpenFlixColors.TextPrimary,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f, fill = false)
                            )
                            // Badges
                            nowPlaying.badges.take(2).forEach { badge ->
                                ProgramBadgeChip(badge)
                            }
                        }

                        // Progress bar
                        if (nowPlaying.isAiring) {
                            LinearProgressIndicator(
                                progress = nowPlaying.progress,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 4.dp)
                                    .height(3.dp)
                                    .clip(RoundedCornerShape(2.dp)),
                                color = OpenFlixColors.Primary,
                                trackColor = OpenFlixColors.ProgressBackground
                            )
                        }
                    }
                }
            } else {
                Text(
                    text = channel.name,
                    color = OpenFlixColors.TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Up next
            if (upNext != null) {
                Row(
                    modifier = Modifier
                        .padding(top = 4.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .clickable { onProgramClick(upNext) }
                        .padding(vertical = 1.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Next: ",
                        color = OpenFlixColors.TextTertiary,
                        fontSize = 12.sp
                    )
                    Text(
                        text = upNext.title,
                        color = OpenFlixColors.TextSecondary,
                        fontSize = 12.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    Text(
                        text = " ${formatTime(upNext.startTime)}",
                        color = OpenFlixColors.TextTertiary,
                        fontSize = 11.sp
                    )
                }
            }
        }
    }
}

@Composable
fun ProgramBadgeChip(badge: ProgramBadge) {
    val (text, color) = when (badge) {
        ProgramBadge.NEW -> "NEW" to OpenFlixColors.Success
        ProgramBadge.LIVE -> "LIVE" to OpenFlixColors.LiveIndicator
        ProgramBadge.PREMIERE -> "PREMIERE" to OpenFlixColors.Warning
        ProgramBadge.FINALE -> "FINALE" to OpenFlixColors.Warning
        ProgramBadge.SPORTS -> "SPORTS" to OpenFlixColors.Sports
        ProgramBadge.MOVIE -> "MOVIE" to OpenFlixColors.Info
        ProgramBadge.RECORDING -> "REC" to OpenFlixColors.Error
        ProgramBadge.CATCHUP -> "CATCHUP" to Color(0xFF8B5CF6)
    }

    Box(
        modifier = Modifier
            .background(color, RoundedCornerShape(4.dp))
            .padding(horizontal = 5.dp, vertical = 1.dp)
    ) {
        Text(
            text = text,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            fontSize = 9.sp
        )
    }
}

private fun formatTime(unixSeconds: Long): String {
    val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
    return sdf.format(Date(unixSeconds * 1000))
}
