package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.openflix.domain.model.Channel
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.util.PlatformBackHandler
import com.openflix.ui.viewmodel.HomeViewModel
import com.openflix.ui.viewmodel.LibraryViewModel
import com.openflix.ui.viewmodel.LiveTVViewModel
import com.openflix.ui.viewmodel.SearchViewModel
import kotlinx.coroutines.launch
import org.koin.compose.viewmodel.koinViewModel

object ChannelStore {
    var lastChannel: Channel? = null
}

enum class Tab(val label: String, val icon: ImageVector) {
    HOME("Home", Icons.Default.Home),
    LIVE_TV("Live TV", Icons.Default.PlayArrow),
    LIBRARY("Library", Icons.AutoMirrored.Filled.List),
    BROWSE("Browse", Icons.Default.Menu),
    SEARCH("Search", Icons.Default.Search)
}

private val DrawerBg = Color(0xFF110C21)

@Composable
fun MainScreen(navController: NavController) {
    var selectedTab by remember { mutableStateOf(Tab.HOME) }
    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    val homeViewModel: HomeViewModel = koinViewModel()
    val liveTVViewModel: LiveTVViewModel = koinViewModel()
    val libraryViewModel: LibraryViewModel = koinViewModel()
    val searchViewModel: SearchViewModel = koinViewModel()

    // Back behavior:
    // 1st Back (drawer closed) → open drawer
    // 2nd Back (drawer open)  → exit app (don't consume → system handles)
    // canOpenDrawer resets when user navigates via drawer or hamburger
    var canOpenDrawer by remember { mutableStateOf(true) }

    PlatformBackHandler(enabled = drawerState.isClosed && canOpenDrawer) {
        scope.launch { drawerState.open() }
        canOpenDrawer = false // Next back after drawer closes will exit
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(
                drawerContainerColor = DrawerBg,
                modifier = Modifier.width(280.dp)
            ) {
                DrawerContent(
                    selectedTab = selectedTab,
                    onTabSelect = { tab ->
                        selectedTab = tab
                        canOpenDrawer = true // Reset — user navigated, back should open drawer again
                        scope.launch { drawerState.close() }
                    }
                )
            }
        },
        scrimColor = Color.Black.copy(alpha = 0.6f)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(OpenFlixColors.Background)
                .onPreviewKeyEvent { event ->
                    // Menu button toggles drawer
                    if (event.type == KeyEventType.KeyDown && event.key == Key.Menu) {
                        scope.launch {
                            if (drawerState.isClosed) drawerState.open() else drawerState.close()
                        }
                        canOpenDrawer = true
                        true
                    } else false
                }
        ) {
            // Content — full screen
            when (selectedTab) {
                Tab.HOME -> HomeScreen(
                    onMediaClick = { mediaId ->
                        navController.navigate("player/$mediaId")
                    },
                    onChannelClick = { channel ->
                        // Switch to Live TV tab then navigate — keeps live TV flow separate from media flow
                        selectedTab = Tab.LIVE_TV
                        ChannelStore.lastChannel = channel
                        navController.navigate("live/${channel.id}") {
                            popUpTo("main") { saveState = false }
                            launchSingleTop = true
                        }
                    },
                    viewModel = homeViewModel
                )
                Tab.LIVE_TV -> LiveTVScreen(
                    onChannelClick = { channel ->
                        ChannelStore.lastChannel = channel
                        navController.navigate("live/${channel.id}") {
                            popUpTo("main") { saveState = false }
                            launchSingleTop = true
                        }
                    },
                    viewModel = liveTVViewModel
                )
                Tab.LIBRARY -> LibraryScreen(
                    onMediaClick = { mediaId ->
                        navController.navigate("player/$mediaId")
                    },
                    viewModel = libraryViewModel
                )
                Tab.BROWSE -> BrowseScreen(
                    onNavigateToSearch = { selectedTab = Tab.SEARCH },
                    onCategoryClick = { }
                )
                Tab.SEARCH -> SearchScreen(
                    onMediaClick = { mediaId ->
                        navController.navigate("player/$mediaId")
                    },
                    viewModel = searchViewModel
                )
            }

            // Hamburger button — top left, focusable for d-pad
            var isFocused by remember { mutableStateOf(false) }
            Box(
                modifier = Modifier
                    .statusBarsPadding()
                    .padding(start = 12.dp, top = 8.dp)
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.5f))
                    .then(
                        if (isFocused) Modifier.border(2.dp, OpenFlixColors.Primary, CircleShape)
                        else Modifier
                    )
                    .onFocusChanged { isFocused = it.isFocused }
                    .focusable()
                    .clickable {
                        canOpenDrawer = true // Reset — user used hamburger
                        scope.launch { drawerState.open() }
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Menu,
                    contentDescription = "Menu",
                    tint = if (isFocused) OpenFlixColors.Primary else Color.White,
                    modifier = Modifier.size(22.dp)
                )
            }
        }
    }
}

@Composable
private fun DrawerContent(
    selectedTab: Tab,
    onTabSelect: (Tab) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxHeight()
            .padding(vertical = 16.dp)
    ) {
        Box(
            modifier = Modifier
                .statusBarsPadding()
                .padding(horizontal = 24.dp, vertical = 16.dp)
        ) {
            Text(
                text = "OpenFlix",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.Primary
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Tab.entries.forEach { tab ->
            val isSelected = selectedTab == tab
            DrawerNavItem(
                icon = tab.icon,
                label = tab.label,
                isSelected = isSelected,
                onClick = { onTabSelect(tab) }
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        HorizontalDivider(
            color = Color.White.copy(alpha = 0.08f),
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
        )

        DrawerNavItem(
            icon = Icons.Default.Settings,
            label = "Settings",
            isSelected = false,
            onClick = { /* TODO */ }
        )
    }
}

@Composable
private fun DrawerNavItem(
    icon: ImageVector,
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(
                when {
                    isFocused -> OpenFlixColors.Primary.copy(alpha = 0.25f)
                    isSelected -> OpenFlixColors.Primary.copy(alpha = 0.15f)
                    else -> Color.Transparent
                }
            )
            .then(
                if (isFocused) Modifier.border(1.5.dp, OpenFlixColors.Primary, RoundedCornerShape(12.dp))
                else Modifier
            )
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = when {
                isFocused -> OpenFlixColors.Primary
                isSelected -> OpenFlixColors.Primary
                else -> Color.White.copy(alpha = 0.6f)
            },
            modifier = Modifier.size(22.dp)
        )
        Text(
            text = label,
            fontSize = 16.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal,
            color = when {
                isFocused -> OpenFlixColors.Primary
                isSelected -> OpenFlixColors.Primary
                else -> Color.White.copy(alpha = 0.85f)
            }
        )
    }
}
