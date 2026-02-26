package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import com.openflix.domain.model.Program
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.viewmodel.ChannelFilter
import com.openflix.ui.viewmodel.LiveTVViewModel
import org.koin.compose.viewmodel.koinViewModel

// Xfinity colors
private val BgColor = Color(0xFF110C21)
private val AccentPurple = Color(0xFF6138F5)
private val CardBg = Color(0xFF1A142E)

@Composable
fun LiveTVScreen(
    onChannelClick: (String) -> Unit = {},
    onGuideClick: () -> Unit = {},
    viewModel: LiveTVViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadChannels()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
    ) {
        // Feature Bar
        FeatureBar()

        // Filter Bar
        FilterBar(
            selectedFilter = uiState.selectedFilter,
            onFilterChange = { viewModel.setFilter(it) }
        )

        // Time Header
        TimeHeader()

        // Channel List
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(32.dp))
                }
            }
            uiState.error != null -> ErrorScreen(uiState.error!!, onRetry = viewModel::refresh)
            else -> {
                val channels = viewModel.filteredChannels()
                if (channels.isEmpty()) {
                    EmptyChannelsState()
                } else {
                    ChannelList(
                        channels = channels,
                        viewModel = viewModel,
                        onChannelClick = onChannelClick
                    )
                }
            }
        }
    }
}

// MARK: - Feature Bar

@Composable
private fun FeatureBar() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        FeatureChip(icon = "↻", title = "Catch Up")
        FeatureChip(icon = "⏱", title = "On Later")
        FeatureChip(icon = "⚽", title = "Team Pass")
        FeatureChip(icon = "▤", title = "Groups")
        FeatureChip(icon = "↔", title = "Surfing")
    }
}

@Composable
private fun FeatureChip(
    icon: String,
    title: String,
    onClick: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(AccentPurple.copy(alpha = 0.3f))
            .border(1.dp, AccentPurple.copy(alpha = 0.6f), RoundedCornerShape(999.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = icon,
            fontSize = 11.sp,
            color = Color.White
        )
        Text(
            text = title,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White
        )
    }
}

// MARK: - Filter Bar

@Composable
private fun FilterBar(
    selectedFilter: ChannelFilter,
    onFilterChange: (ChannelFilter) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Filter dropdown
        var expanded by remember { mutableStateOf(false) }
        Box {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(CardBg)
                    .clickable { expanded = true }
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = "Filter",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.White
                )
                Text(
                    text = "▾",
                    fontSize = 10.sp,
                    color = Color.White
                )
            }

            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                containerColor = CardBg
            ) {
                ChannelFilter.entries.forEach { filter ->
                    DropdownMenuItem(
                        text = {
                            Row(
                                horizontalArrangement = Arrangement.SpaceBetween,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(filter.label, color = Color.White)
                                if (selectedFilter == filter) {
                                    Text("✓", color = AccentPurple)
                                }
                            }
                        },
                        onClick = {
                            onFilterChange(filter)
                            expanded = false
                        }
                    )
                }
            }
        }

        // Day selector
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            DayButton(text = "Today", isSelected = true)
            DayButton(text = "Tomorrow", isSelected = false)
        }
    }
}

@Composable
private fun DayButton(text: String, isSelected: Boolean) {
    Text(
        text = text,
        fontSize = 14.sp,
        fontWeight = FontWeight.Medium,
        color = if (isSelected) Color.White else Color.Gray,
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(if (isSelected) CardBg else Color.Transparent)
            .clickable { }
            .padding(horizontal = 14.dp, vertical = 8.dp)
    )
}

// MARK: - Time Header

@Composable
private fun TimeHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(40.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Channel column spacer
        Spacer(modifier = Modifier.width(140.dp))

        // Time slots
        Row(modifier = Modifier.weight(1f)) {
            val timeSlots = remember { generateTimeSlots() }
            timeSlots.forEach { slot ->
                Text(
                    text = slot,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.Gray,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

private fun generateTimeSlots(): List<String> {
    // Use platform-available time: just return placeholder labels
    // The exact times would need platform-specific Calendar APIs
    return listOf("Now", "Next", "Later", "Tonight")
}

// MARK: - Channel List

@Composable
private fun ChannelList(
    channels: List<Channel>,
    viewModel: LiveTVViewModel,
    onChannelClick: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize()
    ) {
        items(channels, key = { it.id }) { channel ->
            val currentProgram = viewModel.currentProgram(channel.id)
            val nextProgram = viewModel.nextProgram(channel.id)

            ChannelRow(
                channel = channel,
                currentProgram = currentProgram,
                nextProgram = nextProgram,
                onChannelClick = { onChannelClick(channel.id) }
            )

            HorizontalDivider(
                color = Color.White.copy(alpha = 0.1f),
                thickness = 0.5.dp
            )
        }
    }
}

@Composable
private fun ChannelRow(
    channel: Channel,
    currentProgram: Program?,
    nextProgram: Program?,
    onChannelClick: () -> Unit
) {
    val progress = currentProgram?.progress?.toFloat() ?: 0f

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onChannelClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Channel info area (left side, fixed width)
        Row(
            modifier = Modifier.width(140.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Favorite star
            Text(
                text = if (channel.isFavorite) "★" else "☆",
                fontSize = 14.sp,
                color = if (channel.isFavorite) Color(0xFFFFD700) else Color.Gray.copy(alpha = 0.5f)
            )

            // Channel logo
            Box(
                modifier = Modifier.size(width = 40.dp, height = 24.dp),
                contentAlignment = Alignment.Center
            ) {
                if (channel.logo != null) {
                    AsyncImage(
                        model = channel.logo,
                        contentDescription = channel.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.name.take(3).uppercase(),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            // Channel number
            channel.number?.let { number ->
                Text(
                    text = number.toString(),
                    fontSize = 13.sp,
                    color = Color.Gray
                )
            }
        }

        // Program area (right side)
        Row(modifier = Modifier.weight(1f)) {
            // Current program
            Column(
                modifier = Modifier.weight(1f).padding(end = 16.dp)
            ) {
                Text(
                    text = currentProgram?.title ?: "No data",
                    fontSize = 15.sp,
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                // Progress bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(Color.White.copy(alpha = 0.2f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(progress)
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(999.dp))
                            .background(AccentPurple)
                    )
                }
            }

            // Next program
            Text(
                text = nextProgram?.title ?: "",
                fontSize = 15.sp,
                color = Color.Gray,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

// MARK: - Empty State

@Composable
private fun EmptyChannelsState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "📺",
                fontSize = 48.sp
            )
            Text(
                text = "No channels available",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White
            )
            Text(
                text = "Check your server connection",
                fontSize = 14.sp,
                color = Color.Gray
            )
        }
    }
}
