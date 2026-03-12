package com.openflix.presentation.screens.livetv

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Snackbar
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.presentation.components.livetv.*
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun XfinityLiveTVScreen(
    onChannelSelected: (String) -> Unit,
    onNavigateToGuide: () -> Unit,
    onNavigateToSurfing: () -> Unit,
    onNavigateToCatchup: () -> Unit,
    onNavigateToOnLater: () -> Unit,
    onNavigateToTeamPass: () -> Unit,
    onNavigateToGroups: () -> Unit,
    onNavigateToMultiview: () -> Unit,
    onArchivePlayback: (channelId: String, startTime: Long) -> Unit = { _, _ -> },
    viewModel: XfinityLiveTVViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val favoriteIds by viewModel.favoriteChannelIds.collectAsState()
    val configuration = LocalConfiguration.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    var selectedCategory by remember { mutableStateOf(LiveTVCategory.ALL) }
    var selectedProgram by remember { mutableStateOf<Program?>(null) }
    var selectedChannelForSheet by remember { mutableStateOf<ChannelWithPrograms?>(null) }
    var showDetailSheet by remember { mutableStateOf(false) }

    val filteredChannels = remember(uiState.guide, selectedCategory, favoriteIds) {
        viewModel.filterChannels(selectedCategory, favoriteIds)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        when {
            uiState.isLoading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = OpenFlixColors.Primary)
                }
            }
            uiState.error != null -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = uiState.error ?: "Error loading channels",
                            color = OpenFlixColors.Error,
                            fontSize = 16.sp
                        )
                        Spacer(Modifier.height(12.dp))
                        TextButton(onClick = { viewModel.refresh() }) {
                            Text("Retry", color = OpenFlixColors.Primary)
                        }
                    }
                }
            }
            isLandscape -> {
                // Landscape: EPG grid
                LandscapeEPGGrid(
                    channels = filteredChannels,
                    startTime = uiState.guideStartTime,
                    endTime = uiState.guideEndTime,
                    onProgramClick = { cwp, program ->
                        selectedChannelForSheet = cwp
                        selectedProgram = program
                        showDetailSheet = true
                    },
                    onChannelClick = { cwp ->
                        onChannelSelected(cwp.channel.id)
                    }
                )
            }
            else -> {
                // Portrait: Xfinity-style channel list
                PortraitLiveTVContent(
                    channels = filteredChannels,
                    favoriteIds = favoriteIds,
                    selectedCategory = selectedCategory,
                    onCategorySelected = { selectedCategory = it },
                    onFeatureAction = { action ->
                        when (action) {
                            FeatureAction.GUIDE -> onNavigateToGuide()
                            FeatureAction.SURFING -> onNavigateToSurfing()
                            FeatureAction.CATCH_UP -> onNavigateToCatchup()
                            FeatureAction.ON_LATER -> onNavigateToOnLater()
                            FeatureAction.TEAM_PASS -> onNavigateToTeamPass()
                            FeatureAction.GROUPS -> onNavigateToGroups()
                            FeatureAction.MULTI_VIEW -> onNavigateToMultiview()
                        }
                    },
                    onChannelClick = { cwp -> onChannelSelected(cwp.channel.id) },
                    onProgramClick = { cwp, program ->
                        selectedChannelForSheet = cwp
                        selectedProgram = program
                        showDetailSheet = true
                    },
                    onFavoriteToggle = { channelId -> viewModel.toggleFavorite(channelId) }
                )
            }
        }

        // Recording success/error snackbar
        uiState.recordingSuccess?.let { msg ->
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                containerColor = OpenFlixColors.Success.copy(alpha = 0.9f)
            ) {
                Text(msg, color = OpenFlixColors.TextPrimary)
            }
        }
        uiState.recordingError?.let { msg ->
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                containerColor = OpenFlixColors.Error.copy(alpha = 0.9f),
                action = {
                    TextButton(onClick = { viewModel.clearRecordingError() }) {
                        Text("Dismiss", color = OpenFlixColors.TextPrimary)
                    }
                }
            ) {
                Text(msg, color = OpenFlixColors.TextPrimary)
            }
        }
    }

    // Program detail bottom sheet
    if (showDetailSheet && selectedProgram != null) {
        ProgramDetailSheet(
            program = selectedProgram!!,
            channel = selectedChannelForSheet?.channel,
            onDismiss = { showDetailSheet = false },
            onPlay = {
                showDetailSheet = false
                selectedChannelForSheet?.let { cwp ->
                    onChannelSelected(cwp.channel.id)
                }
            },
            onRecord = {
                selectedChannelForSheet?.channel?.id?.let { channelId ->
                    viewModel.scheduleRecording(channelId, selectedProgram!!, recordSeries = false)
                }
            },
            onSeriesRecord = {
                selectedChannelForSheet?.channel?.id?.let { channelId ->
                    viewModel.scheduleRecording(channelId, selectedProgram!!, recordSeries = true)
                }
            },
            isSchedulingRecording = uiState.isSchedulingRecording
        )
    }
}

@Composable
private fun PortraitLiveTVContent(
    channels: List<ChannelWithPrograms>,
    favoriteIds: Set<String>,
    selectedCategory: LiveTVCategory,
    onCategorySelected: (LiveTVCategory) -> Unit,
    onFeatureAction: (FeatureAction) -> Unit,
    onChannelClick: (ChannelWithPrograms) -> Unit,
    onProgramClick: (ChannelWithPrograms, Program) -> Unit,
    onFavoriteToggle: (String) -> Unit
) {
    Column(Modifier.fillMaxSize()) {
        // Header
        Text(
            text = "Live TV",
            color = OpenFlixColors.TextPrimary,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, top = 16.dp, bottom = 4.dp)
        )

        // Feature bar
        FeatureBar(onAction = onFeatureAction)

        // Category filter
        CategoryFilterBar(
            selectedCategory = selectedCategory,
            onCategorySelected = onCategorySelected
        )

        // Channel count
        Text(
            text = "${channels.size} channels",
            color = OpenFlixColors.TextTertiary,
            fontSize = 12.sp,
            modifier = Modifier.padding(start = 16.dp, top = 4.dp, bottom = 8.dp)
        )

        // Channel list
        if (channels.isEmpty()) {
            Box(
                Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (selectedCategory == LiveTVCategory.FAVORITES)
                        "No favorite channels yet. Tap the star on any channel to add it."
                    else
                        "No channels found for this category.",
                    color = OpenFlixColors.TextSecondary,
                    fontSize = 15.sp
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                items(channels, key = { it.channel.id }) { cwp ->
                    XfinityChannelRow(
                        channel = cwp.channel,
                        isFavorite = cwp.channel.id in favoriteIds || cwp.channel.favorite,
                        onFavoriteToggle = { onFavoriteToggle(cwp.channel.id) },
                        onChannelClick = { onChannelClick(cwp) },
                        onProgramClick = { program -> onProgramClick(cwp, program) }
                    )
                }
            }
        }
    }
}
