package com.openflix.presentation.screens.livetv

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.*

private val CHANNEL_COL_WIDTH = 76.dp
private val ROW_HEIGHT = 74.dp
private val TIME_HEADER_HEIGHT = 36.dp
private val PX_PER_MIN = 5.dp

// Category colors — uses the app's defined theme palette
private fun categoryColor(program: Program): Color = when {
    program.isSports -> OpenFlixColors.SportsColor
    program.isMovie  -> OpenFlixColors.MoviesColor
    program.isKids   -> OpenFlixColors.KidsColor
    program.genres.any { it.contains("news", ignoreCase = true) } -> OpenFlixColors.NewsColor
    else             -> OpenFlixColors.Primary
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun XfinityLiveTVScreen(
    onChannelSelected: (String) -> Unit,
    onNavigateToGuide: () -> Unit = {},
    onNavigateToSurfing: () -> Unit = {},
    onNavigateToCatchup: () -> Unit = {},
    onNavigateToOnLater: () -> Unit = {},
    onNavigateToTeamPass: () -> Unit = {},
    onNavigateToGroups: () -> Unit = {},
    onNavigateToMultiview: () -> Unit = {},
    onArchivePlayback: (channelId: String, startTime: Long) -> Unit = { _, _ -> },
    viewModel: XfinityLiveTVViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    var selectedDayOffset by remember { mutableStateOf(0) }
    var selectedGroup by remember { mutableStateOf<String?>(null) }
    var selectedProgram by remember { mutableStateOf<Program?>(null) }
    var selectedChannelForDetail by remember { mutableStateOf<Channel?>(null) }
    var showProgramDetail by remember { mutableStateOf(false) }

    val windowStartTime = remember(selectedDayOffset) {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, selectedDayOffset)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        cal.timeInMillis / 1000
    }

    var viewOffsetMinutes by remember(selectedDayOffset) {
        mutableStateOf(
            if (selectedDayOffset == 0) {
                val now = System.currentTimeMillis() / 1000
                val cal = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                }
                val midnight = cal.timeInMillis / 1000
                ((now - midnight) / 60).toInt().coerceAtLeast(0)
            } else 0
        )
    }

    val guideStart = windowStartTime + (viewOffsetMinutes * 60)
    val guideEnd = guideStart + (3 * 60 * 60)

    LaunchedEffect(selectedDayOffset, viewOffsetMinutes) {
        viewModel.loadGuideForWindow(guideStart, guideEnd)
    }

    // Derive available groups from guide
    val availableGroups = remember(uiState.guide) {
        uiState.guide.mapNotNull { it.channel.group }.distinct().sorted()
    }

    // Filtered guide by selected group
    val filteredGuide = remember(uiState.guide, selectedGroup) {
        if (selectedGroup == null) uiState.guide
        else uiState.guide.filter { it.channel.group == selectedGroup }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        EPGTopBar()
        EPGFilterBar()
        EPGDayPicker(
            selectedDayOffset = selectedDayOffset,
            onDaySelected = { selectedDayOffset = it }
        )
        EPGCategoryTabs(
            groups = availableGroups,
            selectedGroup = selectedGroup,
            onGroupSelected = { selectedGroup = it }
        )

        when {
            uiState.isLoading -> {
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = OpenFlixColors.Primary)
                }
            }
            uiState.error != null -> {
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(uiState.error ?: "Error", color = OpenFlixColors.Error, fontSize = 15.sp)
                        Spacer(Modifier.height(8.dp))
                        TextButton(onClick = { viewModel.loadGuideForWindow(guideStart, guideEnd) }) {
                            Text("Retry", color = OpenFlixColors.Primary)
                        }
                    }
                }
            }
            else -> {
                EPGGrid(
                    channels = filteredGuide,
                    guideStart = guideStart,
                    guideEnd = guideEnd,
                    viewOffsetMinutes = viewOffsetMinutes,
                    onOffsetChange = { viewOffsetMinutes = it },
                    onChannelClick = { onChannelSelected(it.channel.id) },
                    onProgramClick = { cwp, program ->
                        selectedProgram = program
                        selectedChannelForDetail = cwp.channel
                        showProgramDetail = true
                    },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }

    // Recording toast
    val recordingSuccess = uiState.recordingSuccess
    if (recordingSuccess != null) {
        LaunchedEffect(recordingSuccess) { /* toast shown via snackbar or overlay if desired */ }
    }

    // Program detail bottom sheet
    if (showProgramDetail) {
        val program = selectedProgram
        val channel = selectedChannelForDetail
        if (program != null && channel != null) {
            ModalBottomSheet(
                onDismissRequest = { showProgramDetail = false },
                containerColor = Color(0xFF1A142E),
                sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
            ) {
                ProgramDetailSheet(
                    program = program,
                    channel = channel,
                    onWatch = {
                        showProgramDetail = false
                        onChannelSelected(channel.id)
                    },
                    onRecord = {
                        viewModel.scheduleRecording(channelId = channel.id, program = program)
                        showProgramDetail = false
                    },
                    onCreatePass = {
                        viewModel.scheduleRecording(channelId = channel.id, program = program, recordSeries = true)
                        showProgramDetail = false
                    },
                    onDismiss = { showProgramDetail = false }
                )
            }
        }
    }
}

// MARK: - Top Bar

@Composable
private fun EPGTopBar() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(OpenFlixColors.SurfaceVariant),
            contentAlignment = Alignment.Center
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(4.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                repeat(3) {
                    Box(Modifier.width(16.dp).height(2.dp).background(Color.White))
                }
            }
        }

        Text(
            text = "OpenFlix",
            color = OpenFlixColors.Primary,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f).padding(horizontal = 12.dp),
            textAlign = TextAlign.Center
        )

        Icon(
            Icons.Default.Person,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(OpenFlixColors.SurfaceVariant)
                .padding(6.dp)
        )
        Spacer(Modifier.width(8.dp))
        Icon(
            Icons.Default.Settings,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(OpenFlixColors.SurfaceVariant)
                .padding(6.dp)
        )
    }
}

// MARK: - Filter Bar

@Composable
private fun EPGFilterBar() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(20.dp))
                .background(OpenFlixColors.Surface)
                .padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text("All channels", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Medium)
            Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
        }

        Box(
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(OpenFlixColors.Surface),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.Search, contentDescription = "Search", tint = Color.White, modifier = Modifier.size(20.dp))
        }
    }
}

// MARK: - Day Picker

@Composable
private fun EPGDayPicker(
    selectedDayOffset: Int,
    onDaySelected: (Int) -> Unit
) {
    val scrollState = rememberScrollState()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(scrollState)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        (-1..5).forEach { offset ->
            val cal = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, offset) }
            val isSelected = offset == selectedDayOffset
            val dayLabel = when (offset) {
                0 -> "Today"
                else -> SimpleDateFormat("EEE", Locale.getDefault()).format(cal.time)
            }
            val dateLabel = SimpleDateFormat("d", Locale.getDefault()).format(cal.time)

            Column(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (isSelected) OpenFlixColors.Primary.copy(alpha = 0.2f) else Color.Transparent)
                    .clickable { onDaySelected(offset) }
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = dayLabel,
                    color = if (isSelected) Color.White else OpenFlixColors.TextTertiary,
                    fontSize = 12.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                )
                if (offset != 0) {
                    Text(
                        text = dateLabel,
                        color = if (isSelected) Color.White else OpenFlixColors.TextTertiary,
                        fontSize = 11.sp
                    )
                }
                if (isSelected) {
                    Box(
                        Modifier
                            .padding(top = 3.dp)
                            .size(5.dp)
                            .clip(CircleShape)
                            .background(OpenFlixColors.Primary)
                    )
                }
            }
        }
    }
}

// MARK: - Category Tabs

@Composable
private fun EPGCategoryTabs(
    groups: List<String>,
    selectedGroup: String?,
    onGroupSelected: (String?) -> Unit
) {
    if (groups.isEmpty()) return
    val scrollState = rememberScrollState()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(scrollState)
            .background(Color(0xFF0D0A1F))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        EPGCategoryPill("All Channels", selectedGroup == null) { onGroupSelected(null) }
        groups.forEach { group ->
            EPGCategoryPill(group, selectedGroup == group) { onGroupSelected(group) }
        }
    }
}

@Composable
private fun EPGCategoryPill(label: String, isSelected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (isSelected) OpenFlixColors.Primary else Color.White.copy(alpha = 0.08f))
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = label,
            color = Color.White,
            fontSize = 13.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
        )
    }
}

// MARK: - EPG Grid

@Composable
private fun EPGGrid(
    channels: List<ChannelWithPrograms>,
    guideStart: Long,
    guideEnd: Long,
    viewOffsetMinutes: Int,
    onOffsetChange: (Int) -> Unit,
    onChannelClick: (ChannelWithPrograms) -> Unit,
    onProgramClick: (ChannelWithPrograms, Program) -> Unit,
    modifier: Modifier = Modifier
) {
    val now = remember { System.currentTimeMillis() / 1000 }
    val totalMinutes = ((guideEnd - guideStart) / 60).toInt()
    val hScrollState = rememberScrollState(initial = 0)

    val timeSlots = remember(guideStart, totalMinutes) {
        (0 until totalMinutes / 30).map { guideStart + it * 30 * 60 }
    }

    val nowOffsetDp = remember(now, guideStart) {
        val minutesSinceStart = ((now - guideStart) / 60f).coerceAtLeast(0f)
        minutesSinceStart * PX_PER_MIN.value
    }

    Column(modifier = modifier.fillMaxSize()) {
        // Time header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(TIME_HEADER_HEIGHT)
                .background(Color(0xFF0D0A1F)),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(Modifier.width(CHANNEL_COL_WIDTH).fillMaxHeight())

            // Left arrow
            Box(
                Modifier
                    .size(TIME_HEADER_HEIGHT)
                    .clickable { onOffsetChange((viewOffsetMinutes - 30).coerceAtLeast(0)) },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.ChevronLeft, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }

            // Synchronized time labels
            Row(
                Modifier
                    .weight(1f)
                    .horizontalScroll(hScrollState)
                    .fillMaxHeight(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                timeSlots.forEach { slotTime ->
                    Box(
                        Modifier.width(PX_PER_MIN * 30).fillMaxHeight(),
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

            // Right arrow
            Box(
                Modifier
                    .size(TIME_HEADER_HEIGHT)
                    .clickable { onOffsetChange((viewOffsetMinutes + 30).coerceAtMost(totalMinutes - 90)) },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
        }

        // Channel rows
        LazyColumn(Modifier.weight(1f)) {
            items(channels, key = { it.channel.id }) { cwp ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .height(ROW_HEIGHT)
                ) {
                    // Fixed channel column
                    Column(
                        modifier = Modifier
                            .width(CHANNEL_COL_WIDTH)
                            .fillMaxHeight()
                            .background(Color(0xFF0D0A1F))
                            .clickable { onChannelClick(cwp) }
                            .padding(horizontal = 6.dp, vertical = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        val logoUrl = cwp.channel.logoUrl
                        if (logoUrl != null) {
                            AsyncImage(
                                model = logoUrl,
                                contentDescription = null,
                                modifier = Modifier
                                    .size(width = 44.dp, height = 26.dp)
                                    .clip(RoundedCornerShape(3.dp)),
                                contentScale = ContentScale.Fit
                            )
                            Spacer(Modifier.height(2.dp))
                        }
                        if (!cwp.channel.number.isNullOrBlank()) {
                            Text(
                                cwp.channel.number!!,
                                color = Color(0xFF00E5FF),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Text(
                            cwp.channel.name,
                            color = OpenFlixColors.TextSecondary,
                            fontSize = 9.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    // Program cells — shared horizontal scroll
                    Box(
                        Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .horizontalScroll(hScrollState)
                    ) {
                        Row(
                            Modifier.fillMaxHeight(),
                            horizontalArrangement = Arrangement.spacedBy(1.dp)
                        ) {
                            cwp.programs
                                .filter { it.endTime > guideStart && it.startTime < guideEnd }
                                .forEach { program ->
                                    val progStart = maxOf(program.startTime, guideStart)
                                    val progEnd = minOf(program.endTime, guideEnd)
                                    val durationMins = (progEnd - progStart) / 60f
                                    val cellWidth = (durationMins * PX_PER_MIN.value).dp
                                    if (cellWidth > 4.dp) {
                                        EPGProgramCell(
                                            program = program,
                                            width = cellWidth,
                                            now = now,
                                            onClick = { onProgramClick(cwp, program) }
                                        )
                                    }
                                }
                        }

                        // Now-line
                        if (nowOffsetDp > 0f && nowOffsetDp < totalMinutes * PX_PER_MIN.value) {
                            Box(
                                Modifier
                                    .offset(x = nowOffsetDp.dp)
                                    .width(2.dp)
                                    .fillMaxHeight()
                                    .background(
                                        Brush.verticalGradient(
                                            colors = listOf(Color.Red, Color.Red.copy(alpha = 0.5f))
                                        )
                                    )
                            )
                        }
                    }
                }

                // Row divider
                Box(Modifier.fillMaxWidth().height(1.dp).background(OpenFlixColors.Border))
            }
        }
    }
}

// MARK: - Program Cell

@Composable
private fun EPGProgramCell(
    program: Program,
    width: Dp,
    now: Long,
    onClick: () -> Unit
) {
    val isAiring = now in program.startTime..program.endTime
    val isPast = now > program.endTime
    val catColor = categoryColor(program)
    val artUrl = program.thumb ?: program.art

    Box(
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .clip(RoundedCornerShape(4.dp))
            .clickable(onClick = onClick)
    ) {
        // Artwork background
        if (artUrl != null) {
            AsyncImage(
                model = artUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        }

        // Category gradient overlay (always present — heavier when no artwork)
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            catColor.copy(alpha = if (artUrl != null) 0.35f else 0.55f),
                            Color.Black.copy(alpha = if (artUrl != null) 0.72f else 0.90f)
                        )
                    )
                )
        )

        // Extra vertical darkening at bottom for text legibility
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.65f))
                    )
                )
        )

        // Left category stripe
        Box(
            Modifier
                .width(4.dp)
                .fillMaxHeight()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(catColor, catColor.copy(alpha = 0.35f))
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(start = 9.dp, end = 6.dp, top = 6.dp, bottom = 5.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                // Badges
                val hasBadge = program.isNew || program.isLive || program.isPremiere || program.isFinale
                if (hasBadge) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        if (program.isLive) EPGLiveBadge()
                        if (program.isNew) EPGBadge("NEW", Color(0xFF4CAF50))
                        if (program.isPremiere && !program.isNew) EPGBadge("PREMIERE", Color(0xFFFF9800))
                        if (program.isFinale) EPGBadge("FINALE", Color(0xFF9C27B0))
                    }
                    Spacer(Modifier.height(3.dp))
                }

                Text(
                    text = program.title,
                    color = if (isPast) Color.White.copy(alpha = 0.45f) else Color.White,
                    fontSize = 13.sp,
                    fontWeight = if (isAiring) FontWeight.SemiBold else FontWeight.Normal,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    lineHeight = 16.sp
                )
            }

            // Time + duration + progress bar
            Column {
                val durMins = ((program.endTime - program.startTime) / 60).toInt()
                Text(
                    text = "${formatTimeSlot(program.startTime)} · ${durMins}m",
                    color = Color.White.copy(alpha = 0.55f),
                    fontSize = 10.sp,
                    maxLines = 1
                )

                if (isAiring && program.progress > 0f) {
                    Spacer(Modifier.height(4.dp))
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(3.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(Color.White.copy(alpha = 0.18f))
                    ) {
                        Box(
                            Modifier
                                .fillMaxHeight()
                                .fillMaxWidth(program.progress)
                                .background(
                                    Brush.horizontalGradient(
                                        colors = listOf(catColor, catColor.copy(alpha = 0.6f))
                                    )
                                )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - LIVE Badge (pulsing)

@Composable
private fun EPGLiveBadge() {
    val infiniteTransition = rememberInfiniteTransition(label = "live_pulse")
    val dotAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.25f,
        animationSpec = infiniteRepeatable(
            animation = tween(750, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "dot_alpha"
    )

    Row(
        modifier = Modifier
            .background(Color(0xFFE53935).copy(alpha = 0.85f), RoundedCornerShape(3.dp))
            .padding(horizontal = 5.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Box(
            Modifier
                .size(5.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = dotAlpha))
        )
        Text("LIVE", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
    }
}

// MARK: - Badge

@Composable
private fun EPGBadge(label: String, color: Color) {
    Box(
        Modifier
            .background(color, RoundedCornerShape(3.dp))
            .padding(horizontal = 5.dp, vertical = 2.dp)
    ) {
        Text(label, color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
    }
}

// MARK: - Program Detail Sheet

@Composable
fun ProgramDetailSheet(
    program: Program,
    channel: Channel,
    onWatch: () -> Unit,
    onRecord: () -> Unit,
    onCreatePass: () -> Unit,
    onDismiss: () -> Unit
) {
    val accentPurple = Color(0xFF6138F5)
    val artUrl = program.thumb ?: program.art

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(bottom = 8.dp)
    ) {
        // Drag handle
        Box(
            Modifier
                .align(Alignment.CenterHorizontally)
                .padding(top = 8.dp, bottom = 12.dp)
                .width(36.dp)
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(Color.White.copy(alpha = 0.3f))
        )

        // Artwork + title header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Thumbnail 160×90
            Box(
                Modifier
                    .width(160.dp)
                    .height(90.dp)
                    .clip(RoundedCornerShape(8.dp))
            ) {
                if (artUrl != null) {
                    AsyncImage(
                        model = artUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Box(
                        Modifier
                            .fillMaxSize()
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(
                                        categoryColor(program).copy(alpha = 0.6f),
                                        Color.Black.copy(alpha = 0.8f)
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            if (program.isSports) Icons.Default.SportsScore else Icons.Default.Tv,
                            contentDescription = null,
                            tint = Color.White.copy(alpha = 0.4f),
                            modifier = Modifier.size(36.dp)
                        )
                    }
                }
                // Bottom gradient overlay
                Box(
                    Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.55f))
                            )
                        )
                )
            }

            // Title + subtitle + date
            Column(
                Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = program.title,
                    color = Color.White,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                if (!program.episodeTitle.isNullOrBlank()) {
                    Text(
                        text = program.episodeTitle!!,
                        color = Color.White.copy(alpha = 0.8f),
                        fontSize = 14.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                val epInfo = program.episodeInfo
                if (epInfo != null) {
                    Text(epInfo, color = Color.Gray, fontSize = 13.sp)
                }
            }
        }

        // Duration · time · channel
        Row(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val durationMins = ((program.endTime - program.startTime) / 60).toInt()
            Text(
                text = "$durationMins min",
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold
            )
            Box(Modifier.size(4.dp).clip(CircleShape).background(Color.Gray))
            Text(
                text = formatTimeSlot(program.startTime),
                color = Color.Gray,
                fontSize = 14.sp
            )
            Box(Modifier.size(4.dp).clip(CircleShape).background(Color.Gray))
            Text(
                text = channel.name,
                color = accentPurple,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        // Badge pills
        val hasBadges = program.isNew || program.isLive || program.isPremiere ||
                program.isFinale || !program.rating.isNullOrBlank()
        if (hasBadges) {
            Row(
                modifier = Modifier
                    .padding(horizontal = 20.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                if (program.isLive) EPGBadge("LIVE", Color(0xFFE53935))
                if (program.isNew) EPGBadge("NEW", Color(0xFF4CAF50))
                if (program.isPremiere) EPGBadge("PREMIERE", Color(0xFFFF9800))
                if (program.isFinale) EPGBadge("FINALE", Color(0xFF9C27B0))
                if (!program.rating.isNullOrBlank()) {
                    EPGBadge(program.rating!!, Color.White.copy(alpha = 0.15f))
                }
            }
        }

        // Description
        if (!program.description.isNullOrBlank()) {
            Text(
                text = program.description!!,
                color = Color.White.copy(alpha = 0.8f),
                fontSize = 14.sp,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
                maxLines = 4,
                overflow = TextOverflow.Ellipsis
            )
        }

        // Progress bar if currently airing
        if (program.isAiring && program.progress > 0f) {
            Column(Modifier.padding(horizontal = 20.dp, vertical = 6.dp)) {
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(Color.White.copy(alpha = 0.15f))
                ) {
                    Box(
                        Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(program.progress)
                            .background(accentPurple)
                    )
                }
                Spacer(Modifier.height(4.dp))
                val nowSec = System.currentTimeMillis() / 1000
                val remainingMins = ((program.endTime - nowSec) / 60).toInt().coerceAtLeast(0)
                Text(
                    "${(program.progress * 100).toInt()}% complete · $remainingMins min remaining",
                    color = Color.Gray,
                    fontSize = 12.sp
                )
            }
        }

        // Action buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Watch
            Button(
                onClick = onWatch,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White.copy(alpha = 0.1f),
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("Watch", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }

            // Record (only if not already recorded and not past)
            if (!program.hasRecording && !program.isPast) {
                Button(
                    onClick = onRecord,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White.copy(alpha = 0.1f),
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Default.RadioButtonChecked, contentDescription = null,
                        modifier = Modifier.size(18.dp), tint = Color(0xFFE53935))
                    Spacer(Modifier.width(4.dp))
                    Text("Record", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            // Pass
            Button(
                onClick = onCreatePass,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White.copy(alpha = 0.1f),
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.DateRange, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("Pass", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// MARK: - Helpers

private fun formatTimeSlot(unixSeconds: Long): String =
    SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(unixSeconds * 1000))
