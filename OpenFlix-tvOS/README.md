# OpenFlix tvOS

Native tvOS app for Apple TV with full feature parity to the Android app.

## Requirements

- Xcode 15.0+
- tvOS 17.0+
- Swift 5.9+

## Project Structure

```
OpenFlix-tvOS/
├── OpenFlixApp.swift              # App entry point
├── ContentView.swift              # Root navigation
├── Info.plist                     # App configuration
│
├── Core/
│   ├── Network/
│   │   ├── OpenFlixAPI.swift      # API client (actor-based)
│   │   ├── APIEndpoint.swift      # All endpoint definitions
│   │   └── NetworkError.swift     # Error handling
│   ├── Storage/
│   │   ├── UserDefaults+Extensions.swift  # Settings storage
│   │   └── KeychainHelper.swift   # Secure token storage
│   └── Extensions/
│       ├── String+Extensions.swift
│       └── URL+Extensions.swift
│
├── Models/
│   ├── DTOs/                      # API response models
│   │   ├── AuthDTOs.swift
│   │   ├── MediaDTOs.swift
│   │   ├── LiveTVDTOs.swift
│   │   └── MiscDTOs.swift
│   └── Domain/                    # App domain models
│       ├── MediaItem.swift
│       ├── Channel.swift
│       ├── Program.swift
│       ├── Profile.swift
│       ├── Recording.swift
│       ├── LibrarySection.swift
│       ├── Source.swift
│       └── TeamPass.swift
│
├── Repositories/
│   ├── AuthRepository.swift
│   ├── MediaRepository.swift
│   ├── LiveTVRepository.swift
│   ├── DVRRepository.swift
│   ├── ProfileRepository.swift
│   ├── PlaylistRepository.swift
│   ├── WatchlistRepository.swift
│   └── SourceRepository.swift
│
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── DiscoverViewModel.swift
│   ├── MediaDetailViewModel.swift
│   ├── LiveTVViewModel.swift
│   ├── PlayerViewModel.swift
│   ├── DVRViewModel.swift
│   ├── SearchViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── WatchlistViewModel.swift
│   └── SettingsViewModel.swift
│
├── Views/
│   ├── Components/                # Reusable UI components
│   │   ├── MediaCard.swift
│   │   ├── ChannelRow.swift
│   │   ├── ProgramCell.swift
│   │   ├── HubSection.swift
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── ProfileSelectionView.swift
│   ├── Home/
│   │   └── DiscoverView.swift
│   ├── Media/
│   │   ├── MoviesView.swift
│   │   └── MediaDetailView.swift
│   ├── LiveTV/
│   │   ├── LiveTVView.swift
│   │   └── EPGGuideView.swift
│   ├── Player/
│   │   └── VideoPlayerView.swift
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

### Option 1: Create Xcode Project Manually

1. Open Xcode and create a new tvOS App project
2. Set Bundle Identifier: `com.openflix.tvos`
3. Set Deployment Target: tvOS 14.0
4. Select SwiftUI lifecycle
5. Copy all files from this directory into the project
6. Build and run

### Option 2: Using Swift Package Manager

1. Open the folder in Xcode
2. Xcode will recognize it as a Swift Package
3. Build and run on Apple TV Simulator or device

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

### Video Playback
- AVKit-based HLS streaming
- Progress tracking with server sync
- Subtitle selection
- Audio track selection
- TV remote controls (play/pause, seek)
- Resume playback support

### Live TV
- Channel list with logos
- Now Playing information
- EPG/TV Guide
- Channel surfing with D-pad
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

## TV Remote Controls

| Button | Action |
|--------|--------|
| Select | Play/Select |
| Play/Pause | Toggle playback |
| Menu | Back/Show controls |
| Up/Down | Channel surf (Live TV) |
| Left/Right | Seek -/+ 10 seconds |
| Swipe | Navigate |

## Architecture

- **MVVM Pattern**: ViewModels handle business logic, Views handle UI
- **Actor-based API**: Thread-safe network layer using Swift actors
- **Async/Await**: Modern concurrency throughout
- **Repository Pattern**: Data access abstraction
- **Environment Objects**: Shared state management

## API Compatibility

The app is designed to work with the OpenFlix server API:
- Authentication: JWT-based
- Media: Plex-compatible endpoints
- Live TV: Custom endpoints for channels, guide, sources
- DVR: Recording management and playback

## License

Proprietary - OpenFlix
