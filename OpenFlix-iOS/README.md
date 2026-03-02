# OpenFlix iOS

Native iOS app for iPhone with full feature parity to the tvOS and Android apps.

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

## Features

### Authentication
- Server URL configuration with auto-discovery
- Username/password login
- Multi-profile support with PIN protection
- Secure token storage in Keychain

### Media Library
- Browse Movies and TV Shows
- Continue Watching / On Deck
- Recently Added
- Hubs and recommendations
- Search across all libraries
- Detailed media information
- Season/Episode navigation for TV shows
- Watchlist management

### Video Playback
- AVKit-based HLS streaming
- Progress tracking with server sync
- Subtitle selection
- Audio track selection
- Picture-in-Picture support
- AirPlay support
- Resume playback support

### Live TV
- Channel list with logos and numbers
- Now Playing information
- EPG/TV Guide with grid view
- Channel surfing with swipe gestures
- Favorites management
- Group filtering

### DVR
- View completed recordings
- Scheduled recordings management
- Series recording rules
- Commercial skip support
- Recording playback with progress

### Settings
- Server information
- Profile management
- Source management (M3U, Xtream, EPG)
- Playback preferences
- Display settings

## Project Structure

```
OpenFlix-iOS/
├── OpenFlixApp.swift              # App entry point
├── ContentView.swift              # Root navigation + Tab bar
├── Info.plist                     # App configuration
│
├── Core/                          # Shared with tvOS
│   ├── Network/
│   │   ├── OpenFlixAPI.swift      # API client (actor-based)
│   │   ├── APIEndpoint.swift      # All endpoint definitions
│   │   └── NetworkError.swift     # Error handling
│   ├── Storage/
│   │   ├── UserDefaults+Extensions.swift
│   │   └── KeychainHelper.swift
│   └── Extensions/
│       ├── String+Extensions.swift
│       └── URL+Extensions.swift
│
├── Models/                        # Shared with tvOS
│   └── Domain/
│       ├── MediaItem.swift
│       ├── Channel.swift
│       ├── Program.swift
│       ├── Profile.swift
│       ├── Recording.swift
│       └── Source.swift
│
├── Repositories/                  # Shared with tvOS
│   ├── AuthRepository.swift
│   ├── MediaRepository.swift
│   ├── LiveTVRepository.swift
│   ├── DVRRepository.swift
│   └── ...
│
├── ViewModels/                    # Shared with tvOS
│   ├── AuthViewModel.swift
│   ├── DiscoverViewModel.swift
│   ├── MediaDetailViewModel.swift
│   ├── LiveTVViewModel.swift
│   ├── PlayerViewModel.swift
│   ├── DVRViewModel.swift
│   ├── SearchViewModel.swift
│   └── SettingsViewModel.swift
│
├── Views/                         # iOS-specific UI
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── ProfileSelectionView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Media/
│   │   ├── MoviesView.swift
│   │   ├── TVShowsView.swift
│   │   └── MediaDetailView.swift
│   ├── LiveTV/
│   │   ├── LiveTVView.swift
│   │   └── EPGGuideView.swift
│   ├── Player/
│   │   └── PlayerView.swift
│   ├── DVR/
│   │   └── DVRView.swift
│   ├── Search/
│   │   └── SearchView.swift
│   ├── Watchlist/
│   │   └── WatchlistView.swift
│   └── Settings/
│       └── SettingsView.swift
│
└── Resources/
    ├── Assets.xcassets            # App icons, images
    └── Localizable.strings        # Localization
```

## Setup Instructions

### Option 1: Create Xcode Project

1. Open Xcode and create a new iOS App project
2. Set Bundle Identifier: `com.openflix.ios`
3. Set Deployment Target: iOS 17.0
4. Select SwiftUI lifecycle
5. Copy all files from this directory into the project
6. Build and run

### Option 2: Using Swift Package Manager

1. Open the folder in Xcode
2. Xcode will recognize it as a Swift Package
3. Build and run on iOS Simulator or device

## Architecture

- **MVVM Pattern**: ViewModels handle business logic, Views handle UI
- **Actor-based API**: Thread-safe network layer using Swift actors
- **Async/Await**: Modern concurrency throughout
- **Repository Pattern**: Data access abstraction
- **Environment Objects**: Shared state management

## Code Sharing with tvOS

The iOS app shares the following code with the tvOS app:
- **Core/**: Network layer, storage, extensions
- **Models/**: All domain models
- **Repositories/**: Data access layer
- **ViewModels/**: Business logic

Only the **Views/** directory is iOS-specific, optimized for:
- Touch-based navigation (vs TV remote)
- Smaller screen with scrolling content
- Tab bar navigation
- Swipe gestures

## Touch Gestures

| Gesture | Action |
|---------|--------|
| Tap | Select/Play |
| Swipe Left/Right | Seek (in player) |
| Swipe Up/Down | Channel surf (Live TV) |
| Pull down | Refresh |
| Long press | Context menu |

## API Compatibility

The app is designed to work with the OpenFlix server API:
- Authentication: JWT-based
- Media: Plex-compatible endpoints
- Live TV: Custom endpoints for channels, guide, sources
- DVR: Recording management and playback

## License

Proprietary - OpenFlix
