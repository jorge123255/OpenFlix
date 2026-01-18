package com.openflix.presentation.screens.teampass

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import coil.request.ImageRequest
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.layout.ContentScale
import com.openflix.domain.model.SportsTeam
import com.openflix.domain.model.TeamPass
import com.openflix.domain.model.TeamPassStats
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.*

private val LEAGUES = listOf("NFL", "NBA", "MLB", "NHL", "MLS")

@Composable
fun TeamPassScreen(
    viewModel: TeamPassViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val selectedLeague by viewModel.selectedLeague.collectAsState()
    val selectedTeamPass by viewModel.selectedTeamPass.collectAsState()

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
            Column {
                Text(
                    text = "Team Pass",
                    style = MaterialTheme.typography.displaySmall,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = "Auto-record games for your favorite teams",
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.TextSecondary
                )
            }

            Button(
                onClick = { viewModel.showAddDialog() },
                colors = ButtonDefaults.colors(
                    containerColor = OpenFlixColors.Success
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Team")
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Stats Bar
        uiState.stats?.let { stats ->
            StatsRow(stats = stats)
            Spacer(modifier = Modifier.height(20.dp))
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
                        Button(onClick = { viewModel.loadTeamPasses() }) {
                            Text("Retry")
                        }
                    }
                }
            }
            uiState.teamPasses.isEmpty() -> {
                EmptyState(onAddClick = { viewModel.showAddDialog() })
            }
            else -> {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.teamPasses) { pass ->
                        TeamPassCard(
                            pass = pass,
                            onToggle = { viewModel.toggleTeamPass(pass.id) },
                            onDelete = { viewModel.deleteTeamPass(pass.id) },
                            onViewGames = { viewModel.selectTeamPassForDetails(pass) }
                        )
                    }
                }
            }
        }
    }

    // Add Team Dialog
    if (uiState.showAddDialog) {
        AddTeamDialog(
            teams = if (uiState.searchResults.isNotEmpty()) uiState.searchResults else uiState.teams,
            selectedLeague = selectedLeague,
            isLoading = uiState.isLoadingTeams,
            isSaving = uiState.isSaving,
            onLeagueChange = { viewModel.selectLeague(it) },
            onSearch = { viewModel.searchTeams(it) },
            onAddTeam = { team ->
                viewModel.createTeamPass(
                    teamName = team.name,
                    league = team.league ?: selectedLeague
                )
            },
            onDismiss = { viewModel.hideAddDialog() }
        )
    }

    // Upcoming Games Dialog
    selectedTeamPass?.let { pass ->
        UpcomingGamesDialog(
            teamPass = pass,
            games = uiState.upcomingGames,
            isLoading = uiState.isLoadingGames,
            onDismiss = { viewModel.clearSelectedTeamPass() }
        )
    }
}

@Composable
private fun StatsRow(stats: TeamPassStats) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        StatCard(
            icon = Icons.Outlined.SportsFootball,
            count = stats.totalPasses,
            label = "Team Passes",
            color = OpenFlixColors.SportsColor,
            modifier = Modifier.weight(1f)
        )
        StatCard(
            icon = Icons.Outlined.PowerSettingsNew,
            count = stats.activePasses,
            label = "Active",
            color = OpenFlixColors.Success,
            modifier = Modifier.weight(1f)
        )
        StatCard(
            icon = Icons.Outlined.CalendarMonth,
            count = stats.upcomingGames,
            label = "Upcoming",
            color = OpenFlixColors.Info,
            modifier = Modifier.weight(1f)
        )
        StatCard(
            icon = Icons.Outlined.Schedule,
            count = stats.scheduledRecordings,
            label = "Scheduled",
            color = OpenFlixColors.Live,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun StatCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    count: Int,
    label: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.height(80.dp),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface),
        onClick = {}
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
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
private fun EmptyState(onAddClick: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Outlined.SportsFootball,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = OpenFlixColors.TextTertiary
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "No Team Passes",
                style = MaterialTheme.typography.titleMedium,
                color = OpenFlixColors.TextPrimary
            )
            Text(
                text = "Add your favorite teams to auto-record their games",
                style = MaterialTheme.typography.bodyMedium,
                color = OpenFlixColors.TextSecondary
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = onAddClick,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Success)
            ) {
                Text("Add Your First Team")
            }
        }
    }
}

@Composable
private fun TeamPassCard(
    pass: TeamPass,
    onToggle: () -> Unit,
    onDelete: () -> Unit,
    onViewGames: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onViewGames,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.SurfaceVariant
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Team logo or league icon fallback
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .background(
                        color = getLeagueColor(pass.league),
                        shape = RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (!pass.logoUrl.isNullOrEmpty()) {
                    AsyncImage(
                        model = ImageRequest.Builder(LocalContext.current)
                            .data(pass.logoUrl)
                            .crossfade(true)
                            .build(),
                        contentDescription = "${pass.teamName} logo",
                        modifier = Modifier
                            .size(44.dp)
                            .padding(4.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.SportsFootball,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(28.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Team info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = pass.teamName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = OpenFlixColors.TextPrimary
                    )
                    if (!pass.enabled) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "DISABLED",
                            style = MaterialTheme.typography.labelSmall,
                            color = OpenFlixColors.TextTertiary,
                            modifier = Modifier
                                .background(
                                    OpenFlixColors.SurfaceVariant,
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = pass.league,
                        style = MaterialTheme.typography.labelMedium,
                        color = getLeagueColor(pass.league),
                        modifier = Modifier
                            .background(
                                getLeagueColor(pass.league).copy(alpha = 0.2f),
                                RoundedCornerShape(4.dp)
                            )
                            .padding(horizontal = 8.dp, vertical = 2.dp)
                    )

                    pass.upcomingCount?.let { count ->
                        if (count > 0) {
                            Text(
                                text = "$count upcoming",
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.Info
                            )
                        }
                    }
                }

                // Settings row
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Start ${pass.prePadding}m early",
                        style = MaterialTheme.typography.labelSmall,
                        color = OpenFlixColors.TextTertiary
                    )
                    Text(
                        text = "Extend ${pass.postPadding}m",
                        style = MaterialTheme.typography.labelSmall,
                        color = OpenFlixColors.TextTertiary
                    )
                    if (pass.keepCount > 0) {
                        Text(
                            text = "Keep ${pass.keepCount}",
                            style = MaterialTheme.typography.labelSmall,
                            color = OpenFlixColors.TextTertiary
                        )
                    }
                }
            }

            // Actions
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                IconButton(onClick = onViewGames) {
                    Icon(
                        imageVector = Icons.Outlined.CalendarMonth,
                        contentDescription = "View games",
                        tint = OpenFlixColors.TextSecondary
                    )
                }
                IconButton(onClick = onToggle) {
                    Icon(
                        imageVector = if (pass.enabled) Icons.Filled.PowerSettingsNew else Icons.Outlined.PowerSettingsNew,
                        contentDescription = if (pass.enabled) "Disable" else "Enable",
                        tint = if (pass.enabled) OpenFlixColors.Success else OpenFlixColors.TextTertiary
                    )
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        imageVector = Icons.Outlined.Delete,
                        contentDescription = "Delete",
                        tint = OpenFlixColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun AddTeamDialog(
    teams: List<SportsTeam>,
    selectedLeague: String,
    isLoading: Boolean,
    isSaving: Boolean,
    onLeagueChange: (String) -> Unit,
    onSearch: (String) -> Unit,
    onAddTeam: (SportsTeam) -> Unit,
    onDismiss: () -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.8f)
                .fillMaxHeight(0.8f),
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
            colors = ClickableSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface),
            onClick = {}
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Add Team Pass",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.TextPrimary
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = OpenFlixColors.TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // League tabs
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(LEAGUES) { league ->
                        LeagueChip(
                            league = league,
                            isSelected = selectedLeague == league,
                            onClick = {
                                onLeagueChange(league)
                                searchQuery = ""
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Search
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(8.dp))
                        .padding(12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = null,
                            tint = OpenFlixColors.TextTertiary,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        BasicTextField(
                            value = searchQuery,
                            onValueChange = {
                                searchQuery = it
                                onSearch(it)
                            },
                            textStyle = MaterialTheme.typography.bodyLarge.copy(
                                color = OpenFlixColors.TextPrimary
                            ),
                            cursorBrush = SolidColor(OpenFlixColors.Primary),
                            modifier = Modifier.weight(1f),
                            decorationBox = { innerTextField ->
                                if (searchQuery.isEmpty()) {
                                    Text(
                                        "Search teams...",
                                        color = OpenFlixColors.TextTertiary
                                    )
                                }
                                innerTextField()
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Teams grid
                if (isLoading) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("Loading teams...", color = OpenFlixColors.TextSecondary)
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        items(teams) { team ->
                            TeamSelectCard(
                                team = team,
                                isSaving = isSaving,
                                onClick = { onAddTeam(team) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun LeagueChip(
    league: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier.onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) getLeagueColor(league) else OpenFlixColors.SurfaceVariant,
            focusedContainerColor = if (isSelected) getLeagueColor(league) else OpenFlixColors.SurfaceHighlight
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Text(
            text = league,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) Color.White else OpenFlixColors.TextPrimary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
    }
}

@Composable
private fun TeamSelectCard(
    team: SportsTeam,
    isSaving: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        enabled = !isSaving,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.SurfaceVariant,
            focusedContainerColor = OpenFlixColors.SurfaceHighlight
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(8.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Team logo
            if (!team.logoUrl.isNullOrEmpty()) {
                AsyncImage(
                    model = ImageRequest.Builder(LocalContext.current)
                        .data(team.logoUrl)
                        .crossfade(true)
                        .build(),
                    contentDescription = "${team.name} logo",
                    modifier = Modifier.size(32.dp),
                    contentScale = ContentScale.Fit
                )
                Spacer(modifier = Modifier.width(12.dp))
            }

            Column {
                Text(
                    text = team.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = OpenFlixColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = team.city,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun UpcomingGamesDialog(
    teamPass: TeamPass,
    games: List<com.openflix.domain.model.OnLaterItem>,
    isLoading: Boolean,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.8f)
                .fillMaxHeight(0.7f),
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
            colors = ClickableSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface),
            onClick = {}
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = teamPass.teamName,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = OpenFlixColors.TextPrimary
                        )
                        Text(
                            text = "Upcoming Games",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = OpenFlixColors.TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                when {
                    isLoading -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Loading games...", color = OpenFlixColors.TextSecondary)
                        }
                    }
                    games.isEmpty() -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(
                                    imageVector = Icons.Outlined.CalendarMonth,
                                    contentDescription = null,
                                    modifier = Modifier.size(48.dp),
                                    tint = OpenFlixColors.TextTertiary
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = "No upcoming games found",
                                    color = OpenFlixColors.TextSecondary
                                )
                            }
                        }
                    }
                    else -> {
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(games) { game ->
                                GameCard(game = game)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun GameCard(game: com.openflix.domain.model.OnLaterItem) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant),
        onClick = {}
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = game.program.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = OpenFlixColors.TextPrimary
            )
            game.program.teams?.let { teams ->
                Text(
                    text = teams,
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = formatDateTime(game.program.start),
                    style = MaterialTheme.typography.labelMedium,
                    color = OpenFlixColors.Info
                )
                game.channel?.let { channel ->
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.labelSmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }
        }
    }
}

private fun getLeagueColor(league: String): Color {
    return when (league.uppercase()) {
        "NFL" -> Color(0xFF0033A0)
        "NBA" -> Color(0xFFFF6B00)
        "MLB" -> Color(0xFFE31937)
        "NHL" -> Color(0xFF555555)
        "MLS" -> Color(0xFF00A651)
        else -> Color(0xFF9C27B0)
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
