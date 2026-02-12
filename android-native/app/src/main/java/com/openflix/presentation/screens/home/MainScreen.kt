package com.openflix.presentation.screens.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.data.local.LastWatchedService
import com.openflix.player.LiveTVPlayer
import com.openflix.player.MpvPlayer
import com.openflix.presentation.screens.catchup.CatchupScreen
import com.openflix.presentation.screens.dvr.DVRScreen
import com.openflix.presentation.screens.watchstats.WatchStatsScreen
import com.openflix.presentation.screens.epg.EPGGuideScreenModern
import com.openflix.presentation.screens.movies.MoviesScreen
import com.openflix.presentation.screens.movies.MoviesScreenModern
import com.openflix.presentation.screens.onlater.OnLaterScreen
import com.openflix.presentation.screens.settings.SettingsScreen
import com.openflix.presentation.screens.teampass.TeamPassScreen
import com.openflix.presentation.screens.tvshows.TVShowsScreen
import com.openflix.presentation.screens.tvshows.TVShowsScreenModern
import com.openflix.presentation.screens.watchlist.WatchlistScreen
import com.openflix.presentation.screens.playlist.PlaylistsScreen
import com.openflix.presentation.theme.OpenFlixColors

/**
 * Main screen with modern Fubo-style sidebar navigation.
 * Sidebar collapses to icons and expands on focus.
 */
@Composable
fun MainScreen(
    onNavigateToMediaDetail: (String) -> Unit,
    onNavigateToPlayer: (String) -> Unit,
    onNavigateToLiveTVPlayer: (String) -> Unit,
    onNavigateToDVRPlayer: (recordingId: String, mode: String) -> Unit = { id, _ -> },
    onNavigateToSettings: () -> Unit,
    onNavigateToSearch: () -> Unit,
    onNavigateToMultiview: () -> Unit = {},
    onNavigateToChannelSurfing: () -> Unit = {},
    onNavigateToCatchup: () -> Unit = {},
    onNavigateToChannelGroups: () -> Unit = {},
    onNavigateToArchivePlayer: (channelId: String, startTime: Long) -> Unit = { _, _ -> },
    onNavigateToBrowseAll: (libraryId: String, mediaType: String) -> Unit = { _, _ -> },
    mpvPlayer: MpvPlayer,
    liveTVPlayer: LiveTVPlayer,
    lastWatchedService: LastWatchedService? = null
) {
    var selectedTab by remember { mutableStateOf(MainTab.HOME) }
    var isSidebarExpanded by remember { mutableStateOf(false) }
    var isSidebarFocused by remember { mutableStateOf(false) }
    var isLiveTVFullscreen by remember { mutableStateOf(false) }
    val sidebarFocusRequester = remember { FocusRequester() }

    // Auto-expand sidebar when any item is focused
    val sidebarWidth by animateDpAsState(
        targetValue = if (isSidebarExpanded || isSidebarFocused) 220.dp else 72.dp,
        animationSpec = tween(200),
        label = "sidebarWidth"
    )

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        // Modern Sidebar - hide when Live TV is fullscreen
        if (!isLiveTVFullscreen) {
            ModernSidebar(
                selectedTab = selectedTab,
                isExpanded = isSidebarExpanded || isSidebarFocused,
                width = sidebarWidth,
                onTabSelected = { selectedTab = it },
                onSearchClick = onNavigateToSearch,
                onFocusChanged = { isSidebarFocused = it },
                focusRequester = sidebarFocusRequester
            )
        }

        // Content Area
        Box(
            modifier = Modifier
                .fillMaxSize()
                .weight(1f)
        ) {
            when (selectedTab) {
                MainTab.HOME -> DiscoverScreenModern(
                    onMediaClick = onNavigateToMediaDetail,
                    onPlayClick = onNavigateToPlayer,
                    onNavigateToLiveTVPlayer = onNavigateToLiveTVPlayer,
                    onNavigateToGuide = { selectedTab = MainTab.GUIDE },
                    onNavigateToMultiview = onNavigateToMultiview,
                    onNavigateToSports = null // TODO: Add sports screen navigation
                )
                MainTab.MOVIES -> MoviesScreenModern(
                    onMediaClick = onNavigateToMediaDetail,
                    onPlayClick = onNavigateToPlayer,
                    onBrowseAll = { onNavigateToBrowseAll("all", "movie") }
                )
                MainTab.TV_SHOWS -> TVShowsScreenModern(
                    onMediaClick = onNavigateToMediaDetail,
                    onPlayClick = onNavigateToPlayer,
                    onBrowseAll = { onNavigateToBrowseAll("all", "show") }
                )
                MainTab.GUIDE -> EPGGuideScreenModern(
                    onBack = { selectedTab = MainTab.HOME },
                    onChannelSelected = onNavigateToLiveTVPlayer,
                    onArchivePlayback = { channelId, startTime ->
                        onNavigateToArchivePlayer(channelId, startTime)
                    }
                )
                MainTab.CATCHUP -> CatchupScreen(
                    onBack = { selectedTab = MainTab.GUIDE },
                    onPlayProgram = { channelId, startTime ->
                        onNavigateToArchivePlayer(channelId, startTime)
                    }
                )
                MainTab.ON_LATER -> OnLaterScreen(
                    onProgramClick = { item ->
                        // Navigate to Live TV player with the channel
                        item.channel?.let { channel ->
                            onNavigateToLiveTVPlayer(channel.id.toString())
                        }
                    }
                )
                MainTab.TEAM_PASS -> TeamPassScreen()
                MainTab.DVR -> DVRScreen(
                    onRecordingClick = { recordingId, mode ->
                        onNavigateToDVRPlayer(recordingId, mode)
                    }
                )
                MainTab.WATCHLIST -> WatchlistScreen(
                    onBack = { selectedTab = MainTab.HOME },
                    onMediaClick = onNavigateToMediaDetail,
                    onPlayClick = onNavigateToPlayer
                )
                MainTab.PLAYLISTS -> PlaylistsScreen(
                    onBack = { selectedTab = MainTab.HOME },
                    onMediaClick = onNavigateToMediaDetail,
                    onPlayClick = onNavigateToPlayer
                )
                MainTab.WATCH_STATS -> WatchStatsScreen(
                    onBack = { selectedTab = MainTab.HOME }
                )
                MainTab.SETTINGS -> SettingsScreen(
                    onBack = { selectedTab = MainTab.HOME },
                    onNavigateToSubtitleStyling = { /* TODO */ },
                    onNavigateToChannelLogoEditor = { /* TODO */ },
                    onNavigateToRemoteMapping = { /* TODO */ },
                    onNavigateToAbout = { /* TODO */ },
                    onNavigateToLogs = { /* TODO */ },
                    onNavigateToSources = { /* TODO: Navigate to sources screen */ },
                    onSignOut = { /* TODO */ }
                )
            }
        }
    }
}

@Composable
private fun ModernSidebar(
    selectedTab: MainTab,
    isExpanded: Boolean,
    width: androidx.compose.ui.unit.Dp,
    onTabSelected: (MainTab) -> Unit,
    onSearchClick: () -> Unit,
    onFocusChanged: (Boolean) -> Unit,
    focusRequester: FocusRequester = remember { FocusRequester() }
) {
    var hasFocusedChild by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .focusRequester(focusRequester)
            .background(
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        OpenFlixColors.SidebarBackground,
                        OpenFlixColors.SidebarBackground.copy(alpha = 0.95f)
                    )
                )
            )
            .padding(vertical = 20.dp)
            .onFocusChanged { focusState ->
                hasFocusedChild = focusState.hasFocus
                onFocusChanged(focusState.hasFocus)
            },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Logo / Profile Avatar
        Box(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .size(40.dp)
                .clip(CircleShape)
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            OpenFlixColors.Primary,
                            OpenFlixColors.PrimaryDark
                        )
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            // Could be profile image or logo icon
            Text(
                text = "O",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Navigation Items - scrollable for all tabs
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
        ) {
            MainTab.entries.forEach { tab ->
                SidebarNavItem(
                    tab = tab,
                    isSelected = selectedTab == tab,
                    isExpanded = isExpanded,
                    onClick = { onTabSelected(tab) }
                )
            }

            // Search button at bottom of scrollable area
            SidebarNavItem(
                icon = Icons.Outlined.Search,
                selectedIcon = Icons.Filled.Search,
                label = "Search",
                isSelected = false,
                isExpanded = isExpanded,
                onClick = onSearchClick
            )
        }
    }
}

@Composable
private fun SidebarNavItem(
    tab: MainTab,
    isSelected: Boolean,
    isExpanded: Boolean,
    onClick: () -> Unit
) {
    SidebarNavItem(
        icon = tab.icon,
        selectedIcon = tab.selectedIcon,
        label = tab.title,
        isSelected = isSelected,
        isExpanded = isExpanded,
        onClick = onClick
    )
}

@Composable
private fun SidebarNavItem(
    icon: ImageVector,
    selectedIcon: ImageVector,
    label: String,
    isSelected: Boolean,
    isExpanded: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val backgroundColor by animateColorAsState(
        targetValue = when {
            isSelected -> OpenFlixColors.SidebarSelected
            isFocused -> OpenFlixColors.SidebarHover
            else -> Color.Transparent
        },
        label = "navItemBg"
    )

    val iconColor by animateColorAsState(
        targetValue = when {
            isSelected -> OpenFlixColors.Primary
            isFocused -> OpenFlixColors.TextPrimary
            else -> OpenFlixColors.TextSecondary
        },
        label = "iconColor"
    )

    val textColor by animateColorAsState(
        targetValue = when {
            isSelected -> OpenFlixColors.TextPrimary
            isFocused -> OpenFlixColors.TextPrimary
            else -> OpenFlixColors.TextSecondary
        },
        label = "textColor"
    )

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = backgroundColor,
            focusedContainerColor = OpenFlixColors.SidebarHover
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, OpenFlixColors.FocusBorder),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = if (isSelected) selectedIcon else icon,
                contentDescription = label,
                tint = iconColor,
                modifier = Modifier.size(24.dp)
            )

            AnimatedVisibility(
                visible = isExpanded,
                enter = expandHorizontally(),
                exit = shrinkHorizontally()
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    color = textColor,
                    modifier = Modifier.padding(start = 16.dp)
                )
            }
        }
    }
}

enum class MainTab(
    val title: String,
    val icon: ImageVector,
    val selectedIcon: ImageVector
) {
    HOME("Home", Icons.Outlined.Home, Icons.Filled.Home),
    MOVIES("Movies", Icons.Outlined.Movie, Icons.Filled.Movie),
    TV_SHOWS("TV Shows", Icons.Outlined.Tv, Icons.Filled.Tv),
    GUIDE("Guide", Icons.Outlined.GridView, Icons.Filled.GridView),
    CATCHUP("Catch Up", Icons.Outlined.History, Icons.Filled.History),
    ON_LATER("On Later", Icons.Outlined.Schedule, Icons.Filled.Schedule),
    TEAM_PASS("Team Pass", Icons.Outlined.SportsFootball, Icons.Filled.SportsFootball),
    DVR("DVR", Icons.Outlined.FiberManualRecord, Icons.Filled.FiberManualRecord),
    WATCHLIST("Watchlist", Icons.Outlined.Bookmarks, Icons.Filled.Bookmarks),
    PLAYLISTS("Playlists", Icons.Outlined.PlaylistPlay, Icons.Filled.PlaylistPlay),
    WATCH_STATS("Stats", Icons.Outlined.Analytics, Icons.Filled.Analytics),
    SETTINGS("Settings", Icons.Outlined.Settings, Icons.Filled.Settings)
}
