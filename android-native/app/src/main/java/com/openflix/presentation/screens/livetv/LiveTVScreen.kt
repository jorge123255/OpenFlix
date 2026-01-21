package com.openflix.presentation.screens.livetv

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun LiveTVScreen(
    onChannelClick: (String) -> Unit,
    onGuideClick: () -> Unit,
    onCatchupClick: () -> Unit = {},
    onChannelGroupsClick: () -> Unit = {},
    viewModel: LiveTVViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadChannels()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Live TV",
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = onChannelGroupsClick) {
                    Text("Groups")
                }
                Button(onClick = onCatchupClick) {
                    Text("Catch Up")
                }
                Button(onClick = onGuideClick) {
                    Text("Guide")
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Channel List
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading channels...", color = OpenFlixColors.TextSecondary)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(uiState.error!!, color = OpenFlixColors.Error)
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = viewModel::loadChannels) {
                            Text("Retry")
                        }
                    }
                }
            }
            else -> {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.channels) { channel ->
                        ChannelListItem(
                            channel = channel,
                            onClick = { onChannelClick(channel.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChannelListItem(
    channel: Channel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Primary),
                        MaterialTheme.shapes.medium
                    )
                } else {
                    Modifier
                }
            ),
        shape = ClickableSurfaceDefaults.shape(MaterialTheme.shapes.medium),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel Logo
            AsyncImage(
                model = channel.logoUrl,
                contentDescription = channel.name,
                modifier = Modifier
                    .size(60.dp)
                    .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.width(16.dp))

            // Channel Info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    channel.number?.let { number ->
                        Text(
                            text = number,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.Primary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.titleMedium,
                        color = OpenFlixColors.OnSurface
                    )
                    // Provider badge
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.extraSmall)
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = channel.providerName,
                            style = MaterialTheme.typography.labelSmall,
                            color = OpenFlixColors.TextTertiary
                        )
                    }
                    if (channel.hd) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .background(OpenFlixColors.Info, MaterialTheme.shapes.extraSmall)
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text("HD", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.OnPrimary)
                        }
                    }
                }

                // Now Playing
                channel.nowPlaying?.let { program ->
                    Spacer(modifier = Modifier.height(4.dp))
                    ProgramInfo(program = program, label = "Now")
                }

                // Up Next
                channel.upNext?.let { program ->
                    Spacer(modifier = Modifier.height(4.dp))
                    ProgramInfo(program = program, label = "Next")
                }
            }

            // Live indicator
            if (channel.nowPlaying?.isLive == true) {
                Box(
                    modifier = Modifier
                        .background(OpenFlixColors.LiveIndicator, MaterialTheme.shapes.extraSmall)
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text("LIVE", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.OnPrimary)
                }
            }
        }
    }
}

@Composable
private fun ProgramInfo(
    program: Program,
    label: String
) {
    Row {
        Text(
            text = "$label: ",
            style = MaterialTheme.typography.bodySmall,
            color = OpenFlixColors.TextTertiary
        )
        Text(
            text = program.title,
            style = MaterialTheme.typography.bodySmall,
            color = OpenFlixColors.TextSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Progress for current program
        if (label == "Now" && program.isAiring) {
            Spacer(modifier = Modifier.width(8.dp))
            Box(
                modifier = Modifier
                    .width(60.dp)
                    .height(4.dp)
                    .background(OpenFlixColors.ProgressBackground, MaterialTheme.shapes.extraSmall)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(program.progress)
                        .fillMaxHeight()
                        .background(OpenFlixColors.ProgressFill, MaterialTheme.shapes.extraSmall)
                )
            }
        }
    }
}
