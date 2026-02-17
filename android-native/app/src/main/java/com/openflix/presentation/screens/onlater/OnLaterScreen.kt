package com.openflix.presentation.screens.onlater

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.OnLaterCategory
import com.openflix.domain.model.OnLaterItem
import com.openflix.domain.model.OnLaterStats
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun OnLaterScreen(
    onProgramClick: (OnLaterItem) -> Unit = {},
    viewModel: OnLaterViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val selectedLeague by viewModel.selectedLeague.collectAsState()
    val recordingProgramId by viewModel.recordingProgramId.collectAsState()

    // State for recording options dialog
    var recordingDialogItem by remember { mutableStateOf<OnLaterItem?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadCategory(OnLaterCategory.TONIGHT)
    }

    // Recording Options Dialog
    recordingDialogItem?.let { item ->
        RecordingOptionsDialog(
            item = item,
            onDismiss = { recordingDialogItem = null },
            onRecordSingle = {
                viewModel.recordProgram(item, seriesRecord = false)
                recordingDialogItem = null
            },
            onRecordSeries = {
                viewModel.recordProgram(item, seriesRecord = true)
                recordingDialogItem = null
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header
        Text(
            text = "On Later",
            style = MaterialTheme.typography.displaySmall,
            color = OpenFlixColors.OnSurface
        )
        Text(
            text = "Browse upcoming content from your EPG",
            style = MaterialTheme.typography.bodyLarge,
            color = OpenFlixColors.TextSecondary,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Stats Bar
        uiState.stats?.let { stats ->
            StatsRow(stats = stats)
            Spacer(modifier = Modifier.height(20.dp))
        }

        // Category Tabs
        CategoryTabs(
            selectedCategory = selectedCategory,
            onCategorySelected = { viewModel.selectCategory(it) }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // League Filter (only for Sports)
        if (selectedCategory == OnLaterCategory.SPORTS && uiState.leagues.isNotEmpty()) {
            LeagueFilter(
                leagues = uiState.leagues,
                selectedLeague = selectedLeague,
                onLeagueSelected = { viewModel.selectLeague(it) }
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Content
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading...", color = OpenFlixColors.TextSecondary)
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
                        Button(onClick = { viewModel.loadCategory(selectedCategory) }) {
                            Text("Retry")
                        }
                    }
                }
            }
            uiState.items.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.Tv,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = OpenFlixColors.TextTertiary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No upcoming content",
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.TextPrimary
                        )
                        Text(
                            text = "Check back later or try a different category",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            }
            else -> {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(minSize = 280.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(uiState.items) { item ->
                        OnLaterCard(
                            item = item,
                            onClick = { onProgramClick(item) },
                            onRecord = { recordingDialogItem = item },
                            isRecording = recordingProgramId == item.program.id
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StatsRow(stats: OnLaterStats) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        StatCard(
            icon = Icons.Outlined.Movie,
            count = stats.movies,
            label = "Movies",
            color = OpenFlixColors.MoviesColor
        )
        StatCard(
            icon = Icons.Outlined.SportsFootball,
            count = stats.sports,
            label = "Sports",
            color = OpenFlixColors.SportsColor
        )
        StatCard(
            icon = Icons.Outlined.ChildCare,
            count = stats.kids,
            label = "Kids",
            color = OpenFlixColors.KidsColor
        )
        StatCard(
            icon = Icons.Outlined.Newspaper,
            count = stats.news,
            label = "News",
            color = OpenFlixColors.NewsColor
        )
        StatCard(
            icon = Icons.Outlined.Star,
            count = stats.premieres,
            label = "Premieres",
            color = OpenFlixColors.Warning
        )
    }
}

@Composable
private fun StatCard(
    icon: ImageVector,
    count: Int,
    label: String,
    color: Color
) {
    Surface(
        modifier = Modifier.height(80.dp),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface
        ),
        onClick = {}
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            Column {
                Text(
                    text = count.toString(),
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = OpenFlixColors.TextPrimary
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun CategoryTabs(
    selectedCategory: OnLaterCategory,
    onCategorySelected: (OnLaterCategory) -> Unit
) {
    val categories = listOf(
        CategoryInfo(OnLaterCategory.TONIGHT, "Tonight", Icons.Outlined.Schedule, OpenFlixColors.Primary),
        CategoryInfo(OnLaterCategory.MOVIES, "Movies", Icons.Outlined.Movie, OpenFlixColors.MoviesColor),
        CategoryInfo(OnLaterCategory.SPORTS, "Sports", Icons.Outlined.SportsFootball, OpenFlixColors.SportsColor),
        CategoryInfo(OnLaterCategory.KIDS, "Kids", Icons.Outlined.ChildCare, OpenFlixColors.KidsColor),
        CategoryInfo(OnLaterCategory.NEWS, "News", Icons.Outlined.Newspaper, OpenFlixColors.NewsColor),
        CategoryInfo(OnLaterCategory.PREMIERES, "Premieres", Icons.Outlined.Star, OpenFlixColors.Warning),
        CategoryInfo(OnLaterCategory.WEEK, "This Week", Icons.Outlined.CalendarMonth, OpenFlixColors.Info)
    )

    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(categories) { category ->
            CategoryButton(
                category = category,
                isSelected = selectedCategory == category.type,
                onClick = { onCategorySelected(category.type) }
            )
        }
    }
}

private data class CategoryInfo(
    val type: OnLaterCategory,
    val label: String,
    val icon: ImageVector,
    val color: Color
)

@Composable
private fun CategoryButton(
    category: CategoryInfo,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) category.color else OpenFlixColors.Surface,
            focusedContainerColor = if (isSelected) category.color else OpenFlixColors.SurfaceVariant
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = category.icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = if (isSelected) OpenFlixColors.OnPrimary else OpenFlixColors.TextPrimary
            )
            Text(
                text = category.label,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                color = if (isSelected) OpenFlixColors.OnPrimary else OpenFlixColors.TextPrimary
            )
        }
    }
}

@Composable
private fun LeagueFilter(
    leagues: List<String>,
    selectedLeague: String?,
    onLeagueSelected: (String?) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            LeagueChip(
                label = "All Leagues",
                isSelected = selectedLeague == null,
                onClick = { onLeagueSelected(null) }
            )
        }
        items(leagues) { league ->
            LeagueChip(
                label = league,
                isSelected = selectedLeague == league,
                onClick = { onLeagueSelected(league) }
            )
        }
    }
}

@Composable
private fun LeagueChip(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(20.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) OpenFlixColors.SportsColor else OpenFlixColors.Surface,
            focusedContainerColor = if (isSelected) OpenFlixColors.SportsColor else OpenFlixColors.SurfaceVariant
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            color = if (isSelected) OpenFlixColors.OnPrimary else OpenFlixColors.TextPrimary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
    }
}

@Composable
private fun OnLaterCard(
    item: OnLaterItem,
    onClick: () -> Unit,
    onRecord: () -> Unit = {},
    isRecording: Boolean = false
) {
    var isFocused by remember { mutableStateOf(false) }
    val program = item.program

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Primary),
                        RoundedCornerShape(12.dp)
                    )
                } else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.SurfaceVariant
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Column {
            // Image/Thumbnail
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .background(OpenFlixColors.SurfaceVariant)
            ) {
                if (program.icon != null || program.art != null) {
                    AsyncImage(
                        model = program.icon ?: program.art,
                        contentDescription = program.title,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Tv,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = OpenFlixColors.TextTertiary
                        )
                    }
                }

                // Badges overlay
                Row(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(8.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (program.isLive) {
                        Badge(text = "LIVE", color = OpenFlixColors.Live)
                    }
                    if (program.isNew) {
                        Badge(text = "NEW", color = OpenFlixColors.Success)
                    }
                    if (program.isPremiere) {
                        Badge(text = "PREMIERE", color = OpenFlixColors.Warning)
                    }
                }

                // Recording indicator
                if (item.hasRecording) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(8.dp)
                            .background(
                                color = OpenFlixColors.Live,
                                shape = RoundedCornerShape(4.dp)
                            )
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.FiberManualRecord,
                                contentDescription = null,
                                modifier = Modifier.size(10.dp),
                                tint = Color.White
                            )
                            Text(
                                text = "REC",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }

                // Duration
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(8.dp)
                        .background(
                            color = Color.Black.copy(alpha = 0.7f),
                            shape = RoundedCornerShape(4.dp)
                        )
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = formatDuration(program.durationMinutes),
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White
                    )
                }
            }

            // Content
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                // Title row with record button
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = program.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = OpenFlixColors.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    // Record button
                    if (item.channel != null) {
                        Spacer(modifier = Modifier.width(8.dp))
                        RecordButton(
                            hasRecording = item.hasRecording,
                            isRecording = isRecording,
                            onClick = onRecord
                        )
                    }
                }

                program.subtitle?.let { subtitle ->
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Time and Channel
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = formatDateTime(program.start),
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = OpenFlixColors.Primary
                    )
                    item.channel?.let { channel ->
                        Text(
                            text = channel.name,
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextTertiary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                // Tags row
                if (program.category != null || program.league != null || program.rating != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        program.category?.let {
                            TagChip(text = it)
                        }
                        program.league?.let {
                            TagChip(text = it, color = OpenFlixColors.SportsColor)
                        }
                        program.rating?.let {
                            TagChip(text = it)
                        }
                    }
                }

                // Teams (for sports)
                program.teams?.let { teams ->
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = teams,
                        style = MaterialTheme.typography.labelSmall,
                        color = OpenFlixColors.TextTertiary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
}

@Composable
private fun RecordButton(
    hasRecording: Boolean,
    isRecording: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = {
            if (!hasRecording && !isRecording) {
                onClick()
            }
        },
        modifier = Modifier
            .size(32.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(CircleShape),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = when {
                hasRecording -> OpenFlixColors.Live
                isRecording -> OpenFlixColors.SurfaceVariant
                else -> OpenFlixColors.SurfaceHighlight
            },
            focusedContainerColor = when {
                hasRecording -> OpenFlixColors.Live
                isRecording -> OpenFlixColors.SurfaceVariant
                else -> OpenFlixColors.Live
            }
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            when {
                isRecording -> {
                    // Loading spinner
                    Icon(
                        imageVector = Icons.Outlined.HourglassEmpty,
                        contentDescription = "Scheduling...",
                        modifier = Modifier.size(16.dp),
                        tint = OpenFlixColors.TextTertiary
                    )
                }
                hasRecording -> {
                    Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = "Recording scheduled",
                        modifier = Modifier.size(16.dp),
                        tint = Color.White
                    )
                }
                else -> {
                    Icon(
                        imageVector = Icons.Filled.FiberManualRecord,
                        contentDescription = "Record this program",
                        modifier = Modifier.size(16.dp),
                        tint = if (isFocused) Color.White else OpenFlixColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun Badge(text: String, color: Color) {
    Box(
        modifier = Modifier
            .background(color = color, shape = RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (text == "LIVE") {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .background(Color.White, CircleShape)
                )
            }
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
    }
}

@Composable
private fun TagChip(text: String, color: Color = OpenFlixColors.SurfaceHighlight) {
    Box(
        modifier = Modifier
            .background(color = color.copy(alpha = 0.2f), shape = RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = OpenFlixColors.TextSecondary
        )
    }
}

private fun formatDuration(minutes: Int): String {
    val hours = minutes / 60
    val mins = minutes % 60
    return if (hours > 0) {
        if (mins > 0) "${hours}h ${mins}m" else "${hours}h"
    } else {
        "${mins}m"
    }
}

private fun formatDateTime(timestamp: Long): String {
    val date = Date(timestamp * 1000)
    val now = Date()
    val cal = Calendar.getInstance()
    val todayCal = Calendar.getInstance()

    cal.time = date
    todayCal.time = now

    val isToday = cal.get(Calendar.DAY_OF_YEAR) == todayCal.get(Calendar.DAY_OF_YEAR) &&
            cal.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR)

    todayCal.add(Calendar.DAY_OF_YEAR, 1)
    val isTomorrow = cal.get(Calendar.DAY_OF_YEAR) == todayCal.get(Calendar.DAY_OF_YEAR) &&
            cal.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR)

    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
    val dateFormat = SimpleDateFormat("EEE, MMM d", Locale.getDefault())

    return when {
        isToday -> "Today ${timeFormat.format(date)}"
        isTomorrow -> "Tomorrow ${timeFormat.format(date)}"
        else -> "${dateFormat.format(date)} ${timeFormat.format(date)}"
    }
}

@Composable
private fun RecordingOptionsDialog(
    item: OnLaterItem,
    onDismiss: () -> Unit,
    onRecordSingle: () -> Unit,
    onRecordSeries: () -> Unit
) {
    var singleFocused by remember { mutableStateOf(false) }
    var seriesFocused by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.7f)),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            modifier = Modifier
                .width(400.dp)
                .padding(24.dp),
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = OpenFlixColors.Surface
            ),
            onClick = {}
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
            ) {
                // Header
                Text(
                    text = "Record Program",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.TextPrimary
                )
                Text(
                    text = item.program.title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary,
                    modifier = Modifier.padding(top = 4.dp)
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Record Single Episode
                Surface(
                    onClick = onRecordSingle,
                    modifier = Modifier
                        .fillMaxWidth()
                        .onFocusChanged { singleFocused = it.isFocused },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.Primary
                    ),
                    scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .background(
                                    if (singleFocused) OpenFlixColors.OnPrimary.copy(alpha = 0.2f) else OpenFlixColors.Primary,
                                    RoundedCornerShape(8.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Filled.FiberManualRecord,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp),
                                tint = if (singleFocused) OpenFlixColors.OnPrimary else Color.White
                            )
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Record This Episode",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium,
                                color = if (singleFocused) OpenFlixColors.OnPrimary else OpenFlixColors.TextPrimary
                            )
                            Text(
                                text = "Record only this airing",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (singleFocused) OpenFlixColors.OnPrimary.copy(alpha = 0.7f) else OpenFlixColors.TextSecondary
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Record Series
                Surface(
                    onClick = onRecordSeries,
                    modifier = Modifier
                        .fillMaxWidth()
                        .onFocusChanged { seriesFocused = it.isFocused },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.MoviesColor
                    ),
                    scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .background(
                                    if (seriesFocused) OpenFlixColors.OnPrimary.copy(alpha = 0.2f) else OpenFlixColors.MoviesColor,
                                    RoundedCornerShape(8.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Repeat,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp),
                                tint = if (seriesFocused) OpenFlixColors.OnPrimary else Color.White
                            )
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Record Series",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium,
                                color = if (seriesFocused) OpenFlixColors.OnPrimary else OpenFlixColors.TextPrimary
                            )
                            Text(
                                text = "Record all future episodes with this title",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (seriesFocused) OpenFlixColors.OnPrimary.copy(alpha = 0.7f) else OpenFlixColors.TextSecondary
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Cancel button
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.align(Alignment.CenterHorizontally),
                    colors = ButtonDefaults.colors(
                        containerColor = Color.Transparent,
                        contentColor = OpenFlixColors.TextSecondary
                    )
                ) {
                    Text("Cancel")
                }
            }
        }
    }
}
