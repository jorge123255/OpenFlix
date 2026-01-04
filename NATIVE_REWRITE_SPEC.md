# OpenFlix Native Android TV Rewrite Specification

## Overview
Complete rewrite from Flutter to Native Android using:
- **Language**: Kotlin
- **UI**: Jetpack Compose for TV + Material 3 TV
- **Video Player**: mpv (like Channels DVR)
- **Architecture**: MVVM + Clean Architecture
- **DI**: Hilt
- **Navigation**: Compose Navigation for TV

---

## SCREENS (37 total)

### Authentication & Setup
1. **AuthScreen** - Server connection, login/register, QR code auth
2. **FirstTimeSetupScreen** - Initial server discovery and configuration
3. **ProfileSelectionScreen** - User profile selection
4. **AddProfileScreen** - Create new profile
5. **AvatarSelectionScreen** - Choose profile avatar
6. **ProfileSwitchScreen** - Quick profile switching

### Main Navigation
7. **MainScreen** - Bottom/side navigation host (Home, Live TV, DVR, Search, Settings)
8. **DiscoverScreen** - Home screen with hubs, continue watching, recommendations
9. **SearchScreen** - Search with filters, voice input
10. **LibrariesScreen** - Library browser

### Media Browsing
11. **MediaDetailScreen** - Movie/show details, play button, related content
12. **SeasonDetailScreen** - Season episode list
13. **HubDetailScreen** - Full hub content view
14. **CollectionDetailScreen** - Collection items
15. **PlaylistDetailScreen** - Playlist items
16. **BaseMediaListDetailScreen** - Reusable media list

### Live TV
17. **LiveTVScreen** - Channel grid/list
18. **LiveTVPlayerScreen** - Live TV playback with mini guide
19. **LiveTVGuideScreen** - Full EPG grid
20. **EPGGuideScreen** - Alternative EPG view
21. **TVGuideScreen** - TV-optimized guide
22. **ChannelSurfingScreen** - Quick channel flip mode
23. **LiveTVMultiviewScreen** - Picture-in-picture multi-channel

### DVR
24. **DVRScreen** - Recordings list, scheduled, series
25. **DVRPlayerScreen** - DVR playback with skip controls
26. **VirtualChannelsScreen** - Virtual channel management

### Video Playback
27. **VideoPlayerScreen** - Full video player with controls

### Utility Screens
28. **SettingsScreen** - All app settings
29. **SubtitleStylingScreen** - Subtitle customization
30. **AboutScreen** - App info
31. **LicensesScreen** - Open source licenses
32. **LogsScreen** - Debug logs viewer
33. **WatchStatsScreen** - Viewing statistics
34. **WatchlistScreen** - User watchlist
35. **DownloadsScreen** - Offline downloads
36. **CatchupScreen** - Catch-up TV content
37. **ScreensaverScreen** - Idle screensaver

---

## SERVICES (36 total)

### Core Services
1. **StorageService** - SharedPreferences wrapper, tokens, server URLs
2. **SettingsService** - All app settings (60+ settings)
3. **OpenflixAuthService** - Authentication, JWT tokens
4. **PlexAuthService** - Plex authentication (legacy)

### Media Services
5. **DataAggregationService** - Multi-server data aggregation
6. **MultiServerManager** - Multiple server connections
7. **ServerRegistryService** - Server registration
8. **ServerDiscoveryService** - mDNS server discovery
9. **TMDBService** - TMDB metadata fetching
10. **GracenoteEPGService** - EPG data from Gracenote

### Playback Services
11. **PlaybackInitializationService** - Video playback setup
12. **PlaybackProgressTracker** - Watch progress tracking
13. **EpisodeNavigationService** - Next episode logic
14. **TrackSelectionService** - Audio/subtitle track preferences
15. **SleepTimerService** - Sleep timer functionality
16. **MediaControlsManager** - OS media controls integration
17. **VideoFilterManager** - Video filters (brightness, contrast)
18. **VideoPreviewService** - Video thumbnail previews
19. **PIPService** - Picture-in-picture

### Live TV Services
20. **ChannelHistoryService** - Recently watched channels
21. **CatchupService** - Catch-up TV functionality
22. **TunerSharingService** - Tuner sharing between clients
23. **LiveTVAspectRatioManager** - Aspect ratio handling

### Social Features
24. **WatchPartyService** - Watch together functionality
25. **WatchStatsService** - Viewing statistics
26. **WatchlistService** - User watchlist
27. **SportsScoresService** - Live sports scores

### Utility Services
28. **DownloadService** - Offline downloads
29. **UpdateService** - App update checking
30. **RemoteAccessService** - Remote server access
31. **VoiceControlService** - Voice commands
32. **KeyboardShortcutsService** - Keyboard bindings
33. **ProfileStorageService** - Profile data
34. **FullscreenStateManager** - Fullscreen handling
35. **MacOSTitlebarService** - (N/A for Android)
36. **FullscreenWindowDelegate** - (N/A for Android)

---

## MODELS (25 total)

1. **MediaItem** - Movie/episode/clip data
2. **Hub** - Content hub (Continue Watching, etc.)
3. **Library** - Media library
4. **LiveTVChannel** - Live TV channel
5. **DVR** - DVR recording
6. **Playlist** - Playlist data
7. **UserProfile** - User profile
8. **HomeUser** - Home user for multi-user
9. **Home** - Home data response
10. **Role** - User roles/permissions
11. **MediaInfo** - Media metadata
12. **MediaVersion** - Different versions of media
13. **FileInfo** - File details
14. **Filter** - Filter options
15. **Sort** - Sort options
16. **VideoPlaybackData** - Playback state
17. **PlayQueueResponse** - Play queue
18. **UserSwitchResponse** - Profile switch response
19. **DownloadItem** - Download progress

---

## VIDEO PLAYER FEATURES

### Controls
- Play/Pause/Stop
- Seek (small/large configurable)
- Volume control
- Mute toggle
- Playback speed (0.5x - 3.0x)
- Skip intro/credits buttons
- Next/previous episode
- Chapter navigation
- Timeline scrubbing with thumbnails

### Track Selection
- Audio track selection
- Subtitle track selection (with styling)
- Video version selection (4K, HDR, etc.)
- Remember selections per show

### Subtitle Styling
- Font size
- Text color
- Border size/color
- Background color/opacity
- Position

### Advanced Features
- Picture-in-picture (PiP)
- Stats for nerds overlay
- Sleep timer
- Audio sync offset
- Subtitle sync offset
- Video filters (brightness, contrast, saturation)
- Hardware decoding toggle
- Buffer size configuration

---

## LIVE TV FEATURES

### Channel Navigation
- Channel grid view
- Channel list view
- Favorites
- Recent channels
- Channel search
- Channel groups/categories

### EPG Guide
- 7-day program guide
- Program details
- Record button
- Catch-up playback
- Now/Next display

### Playback
- Mini channel guide overlay
- Quick channel switching (up/down)
- Channel surfing mode
- Multi-view (2-4 channels)
- Timeshift (pause/rewind live)
- Aspect ratio switching

### DVR
- One-touch recording
- Series recording rules
- Recording management
- Commercial skip markers

---

## SETTINGS (60+ options)

### Appearance
- Theme (System/Light/Dark)
- Language (6 languages)
- Library density (Compact/Normal/Comfortable)
- View mode (Grid/List)
- Use season posters
- Show hero section

### Video Playback
- Hardware decoding
- Buffer size (16-512 MB)
- Small skip duration (5-30s)
- Large skip duration (15-120s)
- Default sleep timer
- Remember track selections
- Auto skip intro
- Auto skip credits
- Auto skip delay
- Video upscaler

### Subtitles
- Font size
- Text color
- Border size
- Border color
- Background color
- Background opacity

### Shuffle Play
- Unwatched only
- Shuffle order navigation
- Loop shuffle queue

### Parental Controls
- Enable parental controls
- PIN code
- Max movie rating
- Max TV rating
- Kids mode

### Advanced
- Debug logging
- TMDB API key
- Screensaver (enable, idle time)
- Keyboard shortcuts customization

---

## UI COMPONENTS (50+ widgets)

### Navigation
- Hub section (horizontal scrollable)
- Media card (poster + title)
- Focus indicator (TV navigation)
- Horizontal scroll with arrows

### Home Sections
- Continue watching section
- Featured collection section
- Brand hub section
- Top 10 section
- Just added section
- Your next watch section
- Because you watched section
- Mood collection section
- Calendar view section
- Live TV home section

### Video Controls
- Desktop video controls
- Mobile video controls
- Timeline slider
- Volume control
- Track/chapter controls
- Sleep timer widget
- Sync offset control

### Live TV
- Channel list item
- Channel preview overlay
- Mini channel guide
- Program details sheet
- Quick record button

### Dialogs & Sheets
- Filters bottom sheet
- Sort bottom sheet
- Track selection sheets (audio, subtitle, chapter)
- Video settings sheet
- Version selection sheet
- Pin entry dialog

### Media
- Media context menu
- Netflix preview card
- Playlist item card
- Content badge (NEW, LIVE, etc.)
- Download button
- Random picker button
- Trailer preview

### Overlays
- Stats for nerds
- Sports scores
- Watch party
- Voice control button

---

## API ENDPOINTS (from server)

### Auth
- POST /auth/register
- POST /auth/login
- POST /auth/logout
- GET /auth/user
- PUT /auth/user
- PUT /auth/user/password

### Libraries
- GET /libraries
- GET /libraries/:id/hubs
- GET /libraries/:id/all
- GET /libraries/:id/search

### Media
- GET /media/:id
- GET /media/:id/children
- GET /media/:id/related
- GET /shows/:id/seasons
- GET /seasons/:id/episodes

### Playback
- GET /video/:/transcode/universal/start
- PUT /:/progress
- DELETE /:/unscrobble

### Live TV
- GET /livetv/channels
- GET /livetv/guide
- GET /livetv/epg
- POST /livetv/recordings

### DVR
- GET /dvr/recordings
- GET /dvr/scheduled
- POST /dvr/record
- DELETE /dvr/recordings/:id

### Client Logs
- POST /api/client-logs
- GET /api/client-logs

---

## ARCHITECTURE

```
app/
├── src/main/
│   ├── java/com/openflix/
│   │   ├── OpenFlixApp.kt
│   │   ├── MainActivity.kt
│   │   │
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   ├── PreferencesManager.kt
│   │   │   │   └── dao/
│   │   │   ├── remote/
│   │   │   │   ├── api/
│   │   │   │   │   ├── OpenFlixApi.kt
│   │   │   │   │   └── AuthInterceptor.kt
│   │   │   │   └── dto/
│   │   │   └── repository/
│   │   │       ├── AuthRepository.kt
│   │   │       ├── MediaRepository.kt
│   │   │       ├── LiveTVRepository.kt
│   │   │       └── DVRRepository.kt
│   │   │
│   │   ├── domain/
│   │   │   ├── model/
│   │   │   │   ├── MediaItem.kt
│   │   │   │   ├── Channel.kt
│   │   │   │   └── ...
│   │   │   └── usecase/
│   │   │       ├── GetHomeDataUseCase.kt
│   │   │       ├── PlayMediaUseCase.kt
│   │   │       └── ...
│   │   │
│   │   ├── presentation/
│   │   │   ├── navigation/
│   │   │   │   └── NavGraph.kt
│   │   │   ├── theme/
│   │   │   │   ├── Theme.kt
│   │   │   │   ├── Color.kt
│   │   │   │   └── Type.kt
│   │   │   ├── components/
│   │   │   │   ├── MediaCard.kt
│   │   │   │   ├── HubSection.kt
│   │   │   │   ├── FocusableCard.kt
│   │   │   │   └── ...
│   │   │   └── screens/
│   │   │       ├── home/
│   │   │       ├── player/
│   │   │       ├── livetv/
│   │   │       ├── dvr/
│   │   │       ├── settings/
│   │   │       └── ...
│   │   │
│   │   ├── player/
│   │   │   ├── MpvPlayer.kt
│   │   │   ├── PlayerViewModel.kt
│   │   │   └── controls/
│   │   │
│   │   └── di/
│   │       ├── AppModule.kt
│   │       ├── NetworkModule.kt
│   │       └── PlayerModule.kt
│   │
│   └── res/
│       ├── values/
│       │   └── strings.xml (884 strings)
│       └── drawable/
│
└── build.gradle.kts
```

---

## IMPLEMENTATION ORDER

### Phase 1: Core Infrastructure
1. Project setup with Compose TV
2. Hilt dependency injection
3. Network layer (Retrofit + OkHttp)
4. Local storage (DataStore)
5. Navigation graph
6. Theme + styling

### Phase 2: Authentication
7. Auth screens (login, register)
8. Server discovery
9. Token management
10. Profile selection

### Phase 3: Home & Browsing
11. Main screen with navigation
12. Home/Discover screen
13. Hub sections
14. Media cards with focus
15. Media detail screen
16. Search screen

### Phase 4: Video Player
17. mpv integration
18. Player controls UI
19. Track selection
20. Subtitle styling
21. Progress tracking

### Phase 5: Live TV
22. Channel list/grid
23. EPG guide
24. Live player
25. Mini guide overlay
26. DVR recording

### Phase 6: DVR & Advanced
27. DVR screen
28. DVR player
29. Virtual channels
30. Multi-view

### Phase 7: Settings & Polish
31. All settings screens
32. Parental controls
33. Downloads
34. Watch stats
35. Final testing

---

## DEPENDENCIES

```kotlin
// Compose TV
implementation("androidx.tv:tv-foundation:1.0.0-alpha10")
implementation("androidx.tv:tv-material:1.0.0-alpha10")

// Compose
implementation("androidx.compose.ui:ui:1.6.0")
implementation("androidx.compose.material3:material3:1.2.0")
implementation("androidx.activity:activity-compose:1.8.2")
implementation("androidx.navigation:navigation-compose:2.7.6")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

// Hilt
implementation("com.google.dagger:hilt-android:2.50")
kapt("com.google.dagger:hilt-compiler:2.50")
implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

// Network
implementation("com.squareup.retrofit2:retrofit:2.9.0")
implementation("com.squareup.retrofit2:converter-gson:2.9.0")
implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

// Image Loading
implementation("io.coil-kt:coil-compose:2.5.0")

// DataStore
implementation("androidx.datastore:datastore-preferences:1.0.0")

// mpv
implementation("dev.jdtech.mpv:libmpv:0.5.1")

// Leanback (for some TV utilities)
implementation("androidx.leanback:leanback:1.2.0-alpha04")
```

---

## NOTES

- Keep same server API - no backend changes needed
- Maintain feature parity - every Flutter feature must exist
- TV-first design - optimize for D-pad navigation
- Performance - target 60fps scrolling
- Memory - efficient image caching
- Offline - support downloads where Flutter did
