package com.openflix.presentation.navigation

/**
 * Navigation routes for OpenFlix app.
 * All screen destinations are defined here for type-safe navigation.
 */
sealed class NavRoutes(val route: String) {

    // === Authentication & Setup ===
    data object Auth : NavRoutes("auth")
    data object FirstTimeSetup : NavRoutes("first_time_setup")
    data object ProfileSelection : NavRoutes("profile_selection")
    data object AddProfile : NavRoutes("add_profile")
    data object AvatarSelection : NavRoutes("avatar_selection/{profileId}") {
        fun createRoute(profileId: String) = "avatar_selection/$profileId"
    }

    // === Main Navigation ===
    data object Main : NavRoutes("main")
    data object Discover : NavRoutes("discover")
    data object Search : NavRoutes("search")
    data object Libraries : NavRoutes("libraries")

    // === Media Browsing ===
    data object AllMedia : NavRoutes("all_media/{libraryId}/{mediaType}") {
        fun createRoute(libraryId: String, mediaType: String) = "all_media/$libraryId/$mediaType"
    }
    data object MediaDetail : NavRoutes("media/{mediaId}") {
        fun createRoute(mediaId: String) = "media/$mediaId"
    }
    data object SeasonDetail : NavRoutes("season/{showId}/{seasonNumber}") {
        fun createRoute(showId: String, seasonNumber: Int) = "season/$showId/$seasonNumber"
    }
    data object HubDetail : NavRoutes("hub/{hubId}") {
        fun createRoute(hubId: String) = "hub/$hubId"
    }
    data object CollectionDetail : NavRoutes("collection/{collectionId}") {
        fun createRoute(collectionId: String) = "collection/$collectionId"
    }
    data object PlaylistDetail : NavRoutes("playlist/{playlistId}") {
        fun createRoute(playlistId: String) = "playlist/$playlistId"
    }

    // === Live TV ===
    data object LiveTV : NavRoutes("livetv")
    data object LiveTVPlayer : NavRoutes("livetv/player/{channelId}") {
        fun createRoute(channelId: String) = "livetv/player/$channelId"
    }
    data object LiveTVGuide : NavRoutes("livetv/guide")
    data object EPGGuide : NavRoutes("epg")
    data object ChannelSurfing : NavRoutes("livetv/surfing")
    data object Multiview : NavRoutes("livetv/multiview")

    // === On Later ===
    data object OnLater : NavRoutes("onlater")

    // === Team Pass ===
    data object TeamPass : NavRoutes("teampass")

    // === DVR ===
    data object DVR : NavRoutes("dvr")
    data object DVRPlayer : NavRoutes("dvr/player/{recordingId}?mode={mode}") {
        fun createRoute(recordingId: String, mode: String = "default") = "dvr/player/$recordingId?mode=$mode"
    }
    data object VirtualChannels : NavRoutes("dvr/virtual_channels")

    // === Archive/Catch-up ===
    data object ArchivePlayer : NavRoutes("archive/player/{channelId}/{startTime}") {
        fun createRoute(channelId: String, startTime: Long) = "archive/player/$channelId/$startTime"
    }

    // === Video Playback ===
    data object VideoPlayer : NavRoutes("player/{mediaId}") {
        fun createRoute(mediaId: String) = "player/$mediaId"
    }

    // === Settings & Utility ===
    data object Settings : NavRoutes("settings")
    data object SubtitleStyling : NavRoutes("settings/subtitles")
    data object ChannelLogoEditor : NavRoutes("settings/channel_logos")
    data object RemoteMapping : NavRoutes("settings/remote_mapping")
    data object About : NavRoutes("settings/about")
    data object Licenses : NavRoutes("settings/licenses")
    data object Logs : NavRoutes("settings/logs")
    data object WatchStats : NavRoutes("stats")
    data object Watchlist : NavRoutes("watchlist")
    data object Downloads : NavRoutes("downloads")
    data object Catchup : NavRoutes("catchup")
    data object Screensaver : NavRoutes("screensaver")

    companion object {
        // Navigation argument keys
        const val ARG_MEDIA_ID = "mediaId"
        const val ARG_CHANNEL_ID = "channelId"
        const val ARG_RECORDING_ID = "recordingId"
        const val ARG_PLAYBACK_MODE = "mode"
        const val ARG_START_TIME = "startTime"
        const val ARG_SHOW_ID = "showId"
        const val ARG_SEASON_NUMBER = "seasonNumber"
        const val ARG_HUB_ID = "hubId"
        const val ARG_COLLECTION_ID = "collectionId"
        const val ARG_PLAYLIST_ID = "playlistId"
        const val ARG_PROFILE_ID = "profileId"
        const val ARG_LIBRARY_ID = "libraryId"
        const val ARG_MEDIA_TYPE = "mediaType"
    }
}
