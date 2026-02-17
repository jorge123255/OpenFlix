package com.openflix.presentation.screens.livetv

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.tv.material3.*
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.ArchiveProgram
import com.openflix.player.MpvPlayer
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

/**
 * Archive/Catch-up Player screen for playing recorded programs.
 */
@Composable
fun ArchivePlayerScreen(
    channelId: String,
    programStartTime: Long,
    onBack: () -> Unit,
    viewModel: ArchivePlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }
    var showOverlay by remember { mutableStateOf(true) }

    // Auto-hide overlay
    LaunchedEffect(showOverlay) {
        if (showOverlay) {
            delay(5000)
            showOverlay = false
        }
    }

    // Load archive program
    LaunchedEffect(channelId, programStartTime) {
        viewModel.loadArchiveProgram(channelId, programStartTime)
    }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
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
                        Key.Back, Key.Escape -> {
                            viewModel.stop()
                            onBack()
                            true
                        }
                        Key.DirectionCenter, Key.Enter -> {
                            viewModel.togglePlayPause()
                            showOverlay = true
                            true
                        }
                        Key.DirectionLeft -> {
                            viewModel.seekBackward()
                            showOverlay = true
                            true
                        }
                        Key.DirectionRight -> {
                            viewModel.seekForward()
                            showOverlay = true
                            true
                        }
                        else -> {
                            showOverlay = true
                            false
                        }
                    }
                } else false
            }
    ) {
        // Video player
        AndroidView(
            factory = { context ->
                android.view.SurfaceView(context).also { surfaceView ->
                    viewModel.attachSurface(surfaceView)
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // Loading indicator
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                androidx.compose.material3.CircularProgressIndicator(
                    color = Color.White,
                    modifier = Modifier.size(48.dp)
                )
            }
        }

        // Error state
        uiState.error?.let { error ->
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Error",
                        color = Color.Red,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = error,
                        color = Color.White,
                        fontSize = 16.sp
                    )
                }
            }
        }

        // Overlay with program info
        AnimatedVisibility(
            visible = showOverlay && uiState.currentProgram != null,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.7f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            ) {
                // Top bar - CATCH-UP badge
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .background(Color(0xFF8B5CF6), RoundedCornerShape(4.dp))
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = "CATCH-UP",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // Bottom bar - Program info and playback controls
                uiState.currentProgram?.let { program ->
                    Column(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .padding(24.dp)
                    ) {
                        Text(
                            text = program.title,
                            color = Color.White,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        )

                        program.description?.let { desc ->
                            Text(
                                text = desc,
                                color = Color.White.copy(alpha = 0.7f),
                                fontSize = 14.sp,
                                maxLines = 2,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Time info
                        val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                        val dateFormat = SimpleDateFormat("MMM d", Locale.getDefault())
                        val startDate = Date(program.startTime * 1000)
                        Text(
                            text = "${dateFormat.format(startDate)} at ${timeFormat.format(startDate)} • ${program.durationMinutes} min",
                            color = Color.White.copy(alpha = 0.6f),
                            fontSize = 12.sp
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        // Progress bar
                        val progress = if (uiState.duration > 0) {
                            (uiState.position.toFloat() / uiState.duration).coerceIn(0f, 1f)
                        } else 0f

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(4.dp)
                                .background(Color.White.copy(alpha = 0.3f), RoundedCornerShape(2.dp))
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(progress)
                                    .fillMaxHeight()
                                    .background(Color(0xFF8B5CF6), RoundedCornerShape(2.dp))
                            )
                        }

                        Spacer(modifier = Modifier.height(4.dp))

                        // Time display
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = formatDuration(uiState.position),
                                color = Color.White.copy(alpha = 0.7f),
                                fontSize = 12.sp
                            )
                            Text(
                                text = formatDuration(uiState.duration),
                                color = Color.White.copy(alpha = 0.7f),
                                fontSize = 12.sp
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Play/Pause indicator
                        Text(
                            text = if (uiState.isPlaying) "▶ Playing" else "⏸ Paused",
                            color = Color.White.copy(alpha = 0.8f),
                            fontSize = 14.sp
                        )
                    }
                }
            }
        }
    }
}

private fun formatDuration(ms: Long): String {
    val seconds = ms / 1000
    val hours = seconds / 3600
    val minutes = (seconds % 3600) / 60
    val secs = seconds % 60
    return if (hours > 0) {
        String.format("%d:%02d:%02d", hours, minutes, secs)
    } else {
        String.format("%d:%02d", minutes, secs)
    }
}

data class ArchivePlayerUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val currentProgram: ArchiveProgram? = null,
    val streamUrl: String? = null,
    val isPlaying: Boolean = false,
    val position: Long = 0L,
    val duration: Long = 0L
)

@HiltViewModel
class ArchivePlayerViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository,
    private val mpvPlayer: MpvPlayer
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArchivePlayerUiState())
    val uiState: StateFlow<ArchivePlayerUiState> = _uiState.asStateFlow()

    init {
        // Observe player state
        viewModelScope.launch {
            mpvPlayer.isPlaying.collect { playing ->
                _uiState.value = _uiState.value.copy(isPlaying = playing)
            }
        }
        viewModelScope.launch {
            mpvPlayer.position.collect { pos ->
                _uiState.value = _uiState.value.copy(position = pos)
            }
        }
        viewModelScope.launch {
            mpvPlayer.duration.collect { dur ->
                _uiState.value = _uiState.value.copy(duration = dur)
            }
        }
    }

    fun loadArchiveProgram(channelId: String, programStartTime: Long) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            try {
                // Get archived programs for this channel
                val result = liveTVRepository.getArchivedPrograms(channelId)

                if (result.isSuccess) {
                    val archivedInfo = result.getOrNull()
                    // Find the program that matches the start time
                    val program = archivedInfo?.programs?.find {
                        it.startTime == programStartTime
                    }

                    if (program != null && program.isAvailable) {
                        // Get the stream URL
                        val streamResult = liveTVRepository.getArchiveStreamUrl(program.id)
                        if (streamResult.isSuccess) {
                            val url = streamResult.getOrNull()
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                currentProgram = program,
                                streamUrl = url
                            )

                            // Start playback
                            if (url != null) {
                                playStream(url)
                            }
                        } else {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to get stream URL"
                            )
                        }
                    } else {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = "Program not found in archive"
                        )
                    }
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = result.exceptionOrNull()?.message ?: "Failed to load archive"
                    )
                }
            } catch (e: Exception) {
                Timber.e(e, "Error loading archive program")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Unknown error"
                )
            }
        }
    }

    private fun playStream(url: String) {
        try {
            if (!mpvPlayer.isInitialized) {
                mpvPlayer.initialize()
            }
            mpvPlayer.play(url)
        } catch (e: Exception) {
            Timber.e(e, "Error playing stream")
            _uiState.value = _uiState.value.copy(error = "Failed to play: ${e.message}")
        }
    }

    fun attachSurface(surfaceView: android.view.SurfaceView) {
        mpvPlayer.attachSurface(surfaceView)
    }

    fun togglePlayPause() {
        mpvPlayer.togglePlayPause()
    }

    fun seekForward() {
        mpvPlayer.seekRelative(30) // 30 seconds forward
    }

    fun seekBackward() {
        mpvPlayer.seekRelative(-15) // 15 seconds backward
    }

    fun stop() {
        mpvPlayer.stop()
    }

    override fun onCleared() {
        super.onCleared()
        mpvPlayer.stop()
    }
}
