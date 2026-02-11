package com.openflix.presentation.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.openflix.data.local.LastWatchedService
import com.openflix.player.LiveTVPlayer
import com.openflix.player.MpvPlayer
import com.openflix.presentation.screens.auth.AuthScreen
import com.openflix.presentation.screens.auth.AuthViewModel
import com.openflix.presentation.screens.dvr.DVRPlaybackMode
import com.openflix.presentation.screens.dvr.DVRPlayerScreen
import com.openflix.presentation.screens.dvr.DVRScreen
import com.openflix.presentation.screens.home.DiscoverScreen
import com.openflix.presentation.screens.home.MainScreen
import com.openflix.presentation.screens.epg.EPGGuideScreen
import com.openflix.presentation.screens.livetv.ArchivePlayerScreen
import com.openflix.presentation.screens.livetv.ChannelGroupsScreen
import com.openflix.presentation.screens.livetv.ChannelLogoEditorScreen
import com.openflix.presentation.screens.livetv.LiveTVGuideScreen
import com.openflix.presentation.screens.livetv.ChannelSurfingScreen
import com.openflix.presentation.screens.livetv.LiveTVPlayerScreen
import com.openflix.presentation.screens.livetv.LiveTVScreen
import com.openflix.presentation.screens.livetv.MultiviewScreen
import com.openflix.presentation.screens.media.MediaDetailScreen
import com.openflix.presentation.screens.onlater.OnLaterScreen
import com.openflix.presentation.screens.player.VideoPlayerScreen
import com.openflix.presentation.screens.allmedia.AllMediaScreen
import com.openflix.presentation.screens.search.SearchScreen
import com.openflix.presentation.screens.settings.RemoteMappingScreen
import com.openflix.presentation.screens.settings.RemoteStreamingSettingsScreen
import com.openflix.presentation.screens.settings.SettingsScreen
import com.openflix.presentation.screens.teampass.TeamPassScreen
import com.openflix.presentation.screens.catchup.CatchupScreen
import com.openflix.presentation.screens.watchlist.WatchlistScreen
import com.openflix.presentation.screens.profile.ProfileSelectionScreen
import com.openflix.presentation.screens.sources.AddM3USourceScreen
import com.openflix.presentation.screens.sources.AddXtreamSourceScreen
import com.openflix.presentation.screens.sources.SourcesScreen

/**
 * Main navigation host for OpenFlix.
 * Handles all navigation between screens with TV-optimized transitions.
 */
@Composable
fun OpenFlixNavHost(
    navController: NavHostController = rememberNavController(),
    mpvPlayer: MpvPlayer,
    liveTVPlayer: LiveTVPlayer,
    lastWatchedService: LastWatchedService? = null,
    onPlayerScreenChanged: (Boolean) -> Unit = {}
) {
    val authViewModel: AuthViewModel = hiltViewModel()
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()

    // Determine start destination based on auth state
    val startDestination = if (isAuthenticated) {
        NavRoutes.Main.route
    } else {
        NavRoutes.Auth.route
    }

    NavHost(
        navController = navController,
        startDestination = startDestination,
        enterTransition = {
            fadeIn(animationSpec = tween(200)) +
                    slideIntoContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Left,
                        animationSpec = tween(200)
                    )
        },
        exitTransition = {
            fadeOut(animationSpec = tween(200))
        },
        popEnterTransition = {
            fadeIn(animationSpec = tween(200))
        },
        popExitTransition = {
            fadeOut(animationSpec = tween(200)) +
                    slideOutOfContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Right,
                        animationSpec = tween(200)
                    )
        }
    ) {
        // === Authentication ===
        composable(NavRoutes.Auth.route) {
            AuthScreen(
                onAuthSuccess = {
                    navController.navigate(NavRoutes.Main.route) {
                        popUpTo(NavRoutes.Auth.route) { inclusive = true }
                    }
                }
            )
        }

        // === Main Screen (with bottom/side navigation) ===
        composable(NavRoutes.Main.route) {
            MainScreen(
                onNavigateToMediaDetail = { mediaId ->
                    navController.navigate(NavRoutes.MediaDetail.createRoute(mediaId))
                },
                onNavigateToPlayer = { mediaId ->
                    navController.navigate(NavRoutes.VideoPlayer.createRoute(mediaId))
                },
                onNavigateToLiveTVPlayer = { channelId ->
                    navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channelId))
                },
                onNavigateToDVRPlayer = { recordingId, mode ->
                    navController.navigate(NavRoutes.DVRPlayer.createRoute(recordingId, mode))
                },
                onNavigateToSettings = {
                    navController.navigate(NavRoutes.Settings.route)
                },
                onNavigateToSearch = {
                    navController.navigate(NavRoutes.Search.route)
                },
                onNavigateToMultiview = {
                    navController.navigate(NavRoutes.Multiview.route)
                },
                onNavigateToChannelSurfing = {
                    navController.navigate(NavRoutes.ChannelSurfing.route)
                },
                onNavigateToCatchup = {
                    navController.navigate(NavRoutes.Catchup.route)
                },
                onNavigateToChannelGroups = {
                    navController.navigate(NavRoutes.ChannelGroups.route)
                },
                onNavigateToArchivePlayer = { channelId, startTime ->
                    navController.navigate(NavRoutes.ArchivePlayer.createRoute(channelId, startTime))
                },
                onNavigateToBrowseAll = { libraryId, mediaType ->
                    navController.navigate(NavRoutes.AllMedia.createRoute(libraryId, mediaType))
                },
                mpvPlayer = mpvPlayer,
                liveTVPlayer = liveTVPlayer,
                lastWatchedService = lastWatchedService
            )
        }

        // === Media Detail ===
        composable(
            route = NavRoutes.MediaDetail.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_MEDIA_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val mediaId = backStackEntry.arguments?.getString(NavRoutes.ARG_MEDIA_ID) ?: return@composable
            MediaDetailScreen(
                mediaId = mediaId,
                onBack = { navController.popBackStack() },
                onPlayMedia = { id ->
                    navController.navigate(NavRoutes.VideoPlayer.createRoute(id))
                },
                onNavigateToSeason = { showId, seasonNumber ->
                    navController.navigate(NavRoutes.SeasonDetail.createRoute(showId, seasonNumber))
                }
            )
        }

        // === Season Detail ===
        composable(
            route = NavRoutes.SeasonDetail.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_SHOW_ID) { type = NavType.StringType },
                navArgument(NavRoutes.ARG_SEASON_NUMBER) { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val showId = backStackEntry.arguments?.getString(NavRoutes.ARG_SHOW_ID) ?: return@composable
            val seasonNumber = backStackEntry.arguments?.getInt(NavRoutes.ARG_SEASON_NUMBER) ?: 1
            // TODO: SeasonDetailScreen
        }

        // === Video Player ===
        composable(
            route = NavRoutes.VideoPlayer.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_MEDIA_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val mediaId = backStackEntry.arguments?.getString(NavRoutes.ARG_MEDIA_ID) ?: return@composable

            // Track player screen for PiP
            DisposableEffect(Unit) {
                onPlayerScreenChanged(true)
                onDispose { onPlayerScreenChanged(false) }
            }

            VideoPlayerScreen(
                mediaId = mediaId,
                onBack = { navController.popBackStack() },
                mpvPlayer = mpvPlayer
            )
        }

        // === Live TV Player ===
        composable(
            route = NavRoutes.LiveTVPlayer.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_CHANNEL_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val channelId = backStackEntry.arguments?.getString(NavRoutes.ARG_CHANNEL_ID) ?: return@composable

            // Track player screen for PiP
            DisposableEffect(Unit) {
                onPlayerScreenChanged(true)
                onDispose { onPlayerScreenChanged(false) }
            }

            LiveTVPlayerScreen(
                channelId = channelId,
                onBack = { navController.popBackStack() },
                onMultiview = {
                    navController.navigate(NavRoutes.Multiview.route)
                },
                onEPGGuide = {
                    navController.navigate(NavRoutes.EPGGuide.route)
                },
                onCatchup = {
                    navController.navigate(NavRoutes.Catchup.route)
                },
                liveTVPlayer = liveTVPlayer
            )
        }

        // === Live TV Guide ===
        composable(NavRoutes.LiveTVGuide.route) {
            LiveTVGuideScreen(
                onBack = { navController.popBackStack() },
                onChannelSelected = { channelId ->
                    navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channelId))
                },
                liveTVPlayer = liveTVPlayer
            )
        }

        // === EPG Guide ===
        composable(NavRoutes.EPGGuide.route) {
            EPGGuideScreen(
                onBack = { navController.popBackStack() },
                onChannelSelected = { channelId ->
                    navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channelId))
                },
                onArchivePlayback = { channelId, startTime ->
                    navController.navigate(NavRoutes.ArchivePlayer.createRoute(channelId, startTime))
                }
            )
        }

        // === Channel Surfing ===
        composable(NavRoutes.ChannelSurfing.route) {
            // Track player screen for PiP
            DisposableEffect(Unit) {
                onPlayerScreenChanged(true)
                onDispose { onPlayerScreenChanged(false) }
            }

            ChannelSurfingScreen(
                onBack = { navController.popBackStack() },
                onChannelSelected = { channelId ->
                    navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channelId))
                },
                liveTVPlayer = liveTVPlayer
            )
        }

        // === DVR Player ===
        composable(
            route = NavRoutes.DVRPlayer.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_RECORDING_ID) { type = NavType.StringType },
                navArgument(NavRoutes.ARG_PLAYBACK_MODE) {
                    type = NavType.StringType
                    defaultValue = "default"
                }
            )
        ) { backStackEntry ->
            val recordingId = backStackEntry.arguments?.getString(NavRoutes.ARG_RECORDING_ID) ?: return@composable
            val modeString = backStackEntry.arguments?.getString(NavRoutes.ARG_PLAYBACK_MODE) ?: "default"
            val playbackMode = when (modeString.lowercase()) {
                "live" -> DVRPlaybackMode.LIVE
                "start" -> DVRPlaybackMode.START
                else -> DVRPlaybackMode.DEFAULT
            }

            // Track player screen for PiP
            DisposableEffect(Unit) {
                onPlayerScreenChanged(true)
                onDispose { onPlayerScreenChanged(false) }
            }

            DVRPlayerScreen(
                recordingId = recordingId,
                playbackMode = playbackMode,
                onBack = { navController.popBackStack() },
                mpvPlayer = mpvPlayer
            )
        }

        // === Archive/Catch-up Player ===
        composable(
            route = NavRoutes.ArchivePlayer.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_CHANNEL_ID) { type = NavType.StringType },
                navArgument(NavRoutes.ARG_START_TIME) { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val channelId = backStackEntry.arguments?.getString(NavRoutes.ARG_CHANNEL_ID) ?: return@composable
            val startTime = backStackEntry.arguments?.getLong(NavRoutes.ARG_START_TIME) ?: return@composable
            ArchivePlayerScreen(
                channelId = channelId,
                programStartTime = startTime,
                onBack = { navController.popBackStack() }
            )
        }

        // === Search ===
        composable(NavRoutes.Search.route) {
            SearchScreen(
                onBack = { navController.popBackStack() },
                onMediaSelected = { mediaId ->
                    navController.navigate(NavRoutes.MediaDetail.createRoute(mediaId))
                }
            )
        }

        // === All Media (Browse All) ===
        composable(
            route = NavRoutes.AllMedia.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_LIBRARY_ID) { type = NavType.StringType },
                navArgument(NavRoutes.ARG_MEDIA_TYPE) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            AllMediaScreen(
                onBackClick = { navController.popBackStack() },
                onMediaClick = { mediaId ->
                    navController.navigate(NavRoutes.MediaDetail.createRoute(mediaId))
                }
            )
        }

        // === Settings ===
        composable(NavRoutes.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onNavigateToSubtitleStyling = {
                    navController.navigate(NavRoutes.SubtitleStyling.route)
                },
                onNavigateToChannelLogoEditor = {
                    navController.navigate(NavRoutes.ChannelLogoEditor.route)
                },
                onNavigateToRemoteMapping = {
                    navController.navigate(NavRoutes.RemoteMapping.route)
                },
                onNavigateToRemoteStreaming = {
                    navController.navigate(NavRoutes.RemoteStreaming.route)
                },
                onNavigateToAbout = {
                    navController.navigate(NavRoutes.About.route)
                },
                onNavigateToLogs = {
                    navController.navigate(NavRoutes.Logs.route)
                },
                onNavigateToSources = {
                    navController.navigate(NavRoutes.Sources.route)
                },
                onSignOut = {
                    navController.navigate(NavRoutes.Auth.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        // === Source Management ===
        composable(NavRoutes.Sources.route) {
            SourcesScreen(
                onBack = { navController.popBackStack() },
                onAddXtreamSource = {
                    navController.navigate(NavRoutes.AddXtreamSource.route)
                },
                onAddM3USource = {
                    navController.navigate(NavRoutes.AddM3USource.route)
                },
                onEditXtreamSource = { sourceId ->
                    navController.navigate(NavRoutes.EditXtreamSource.createRoute(sourceId))
                },
                onEditM3USource = { sourceId ->
                    navController.navigate(NavRoutes.EditM3USource.createRoute(sourceId))
                }
            )
        }

        composable(NavRoutes.AddXtreamSource.route) {
            AddXtreamSourceScreen(
                onBack = { navController.popBackStack() },
                onSuccess = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.AddM3USource.route) {
            AddM3USourceScreen(
                onBack = { navController.popBackStack() },
                onSuccess = { navController.popBackStack() }
            )
        }

        composable(
            route = NavRoutes.EditXtreamSource.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_SOURCE_ID) { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val sourceId = backStackEntry.arguments?.getInt(NavRoutes.ARG_SOURCE_ID) ?: return@composable
            AddXtreamSourceScreen(
                onBack = { navController.popBackStack() },
                onSuccess = { navController.popBackStack() },
                editSourceId = sourceId
            )
        }

        composable(
            route = NavRoutes.EditM3USource.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_SOURCE_ID) { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val sourceId = backStackEntry.arguments?.getInt(NavRoutes.ARG_SOURCE_ID) ?: return@composable
            AddM3USourceScreen(
                onBack = { navController.popBackStack() },
                onSuccess = { navController.popBackStack() },
                editSourceId = sourceId
            )
        }

        // === Channel Logo Editor ===
        composable(NavRoutes.ChannelLogoEditor.route) {
            ChannelLogoEditorScreen(
                onBack = { navController.popBackStack() }
            )
        }

        // === Remote Mapping ===
        composable(NavRoutes.RemoteMapping.route) {
            RemoteMappingScreen(
                onBack = { navController.popBackStack() }
            )
        }

        // === Remote Streaming Settings ===
        composable(NavRoutes.RemoteStreaming.route) {
            RemoteStreamingSettingsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        // === Subtitle Styling ===
        composable(NavRoutes.SubtitleStyling.route) {
            // TODO: SubtitleStylingScreen
        }

        // === About ===
        composable(NavRoutes.About.route) {
            // TODO: AboutScreen
        }

        // === Logs ===
        composable(NavRoutes.Logs.route) {
            // TODO: LogsScreen
        }

        // === Watch Stats ===
        composable(NavRoutes.WatchStats.route) {
            // TODO: WatchStatsScreen
        }

        // === Watchlist ===
        composable(NavRoutes.Watchlist.route) {
            WatchlistScreen(
                onBack = { navController.popBackStack() },
                onMediaClick = { mediaId ->
                    navController.navigate(NavRoutes.MediaDetail.createRoute(mediaId))
                },
                onPlayClick = { mediaId ->
                    navController.navigate(NavRoutes.VideoPlayer.createRoute(mediaId))
                }
            )
        }

        // === Downloads ===
        composable(NavRoutes.Downloads.route) {
            // TODO: DownloadsScreen
        }

        // === Screensaver ===
        composable(NavRoutes.Screensaver.route) {
            // TODO: ScreensaverScreen
        }

        // === Hub Detail ===
        composable(
            route = NavRoutes.HubDetail.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_HUB_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val hubId = backStackEntry.arguments?.getString(NavRoutes.ARG_HUB_ID) ?: return@composable
            // TODO: HubDetailScreen
        }

        // === Collection Detail ===
        composable(
            route = NavRoutes.CollectionDetail.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_COLLECTION_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val collectionId = backStackEntry.arguments?.getString(NavRoutes.ARG_COLLECTION_ID) ?: return@composable
            // TODO: CollectionDetailScreen
        }

        // === Playlist Detail ===
        composable(
            route = NavRoutes.PlaylistDetail.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_PLAYLIST_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val playlistId = backStackEntry.arguments?.getString(NavRoutes.ARG_PLAYLIST_ID) ?: return@composable
            // TODO: PlaylistDetailScreen
        }

        // === Profile Selection ===
        composable(NavRoutes.ProfileSelection.route) {
            ProfileSelectionScreen(
                onProfileSelected = {
                    navController.navigate(NavRoutes.Main.route) {
                        popUpTo(NavRoutes.ProfileSelection.route) { inclusive = true }
                    }
                }
            )
        }

        // === Add Profile ===
        composable(NavRoutes.AddProfile.route) {
            // TODO: AddProfileScreen
        }

        // === Avatar Selection ===
        composable(
            route = NavRoutes.AvatarSelection.route,
            arguments = listOf(
                navArgument(NavRoutes.ARG_PROFILE_ID) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val profileId = backStackEntry.arguments?.getString(NavRoutes.ARG_PROFILE_ID) ?: return@composable
            // TODO: AvatarSelectionScreen
        }

        // === Virtual Channels ===
        composable(NavRoutes.VirtualChannels.route) {
            // TODO: VirtualChannelsScreen
        }

        // === Multiview ===
        composable(NavRoutes.Multiview.route) {
            // Track player screen for PiP
            DisposableEffect(Unit) {
                onPlayerScreenChanged(true)
                onDispose { onPlayerScreenChanged(false) }
            }

            MultiviewScreen(
                onBack = { navController.popBackStack() },
                onFullScreen = { channel ->
                    navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channel.id))
                }
            )
        }

        // === Channel Groups ===
        composable(NavRoutes.ChannelGroups.route) {
            ChannelGroupsScreen(
                onBack = { navController.popBackStack() },
                onPlayGroup = { groupId ->
                    // For now, navigate back - TODO: implement group playback
                    navController.popBackStack()
                }
            )
        }

        // === Catchup ===
        composable(NavRoutes.Catchup.route) {
            CatchupScreen(
                onBack = { navController.popBackStack() },
                onPlayProgram = { channelId, startTime ->
                    navController.navigate(NavRoutes.ArchivePlayer.createRoute(channelId, startTime))
                }
            )
        }

        // === On Later ===
        composable(NavRoutes.OnLater.route) {
            OnLaterScreen(
                onProgramClick = { item ->
                    // Navigate to live TV player for that channel
                    item.channel?.let { channel ->
                        navController.navigate(NavRoutes.LiveTVPlayer.createRoute(channel.id.toString()))
                    }
                }
            )
        }

        // === Team Pass ===
        composable(NavRoutes.TeamPass.route) {
            TeamPassScreen()
        }
    }
}
