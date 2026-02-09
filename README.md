<h1>
  <img src="assets/openflix.png" alt="OpenFlix Logo" height="24" style="vertical-align: middle;" />
  OpenFlix
</h1>

OpenFlix is an open-source media server with Live TV/IPTV and DVR capabilities. It provides a complete self-hosted streaming solution with native clients for Android TV, Apple TV, and a Go-powered backend.

## Project Structure

```
openflix/
├── android-native/      # Native Android/Android TV app (Kotlin/Compose)
├── OpenFlix-tvOS/       # Native tvOS/Apple TV app (Swift/SwiftUI)
├── server/              # Go backend server
│   ├── cmd/server/      # Server entrypoint
│   ├── web/             # React web admin interface
│   └── internal/        # Server modules
│       ├── api/         # HTTP handlers
│       ├── auth/        # JWT authentication
│       ├── db/          # Database layer
│       ├── library/     # Media scanning
│       ├── metadata/    # TMDB/TVDB agents
│       ├── livetv/      # M3U, EPG, channels
│       ├── dvr/         # Recording engine
│       └── transcode/   # FFmpeg wrapper
└── assets/              # Shared assets
```

## Features

### Server
- Plex-compatible API endpoints
- Media library scanning and metadata fetching (TMDB/TVDB)
- Multi-user authentication with profiles
- Live TV / IPTV support (M3U playlists, XMLTV EPG)
- DVR recording with scheduling
- Series recording rules
- Commercial detection (Comskip integration)
- Hardware-accelerated transcoding (FFmpeg)
- Web-based admin interface

### Android TV Client
- Native Kotlin with Jetpack Compose for TV
- Hero carousel with auto-rotation and TMDB trailers
- Genre-based content discovery
- MPV-powered video playback (HEVC, AV1, VP9, Dolby Vision)
- Live TV guide with EPG grid
- Channel surfing with instant switch
- DVR management and playback
- Subtitle support (ASS/SSA)
- D-pad optimized navigation

### Apple TV Client
- Native Swift with SwiftUI
- Hero carousel with featured content
- Genre hub sections
- AVPlayer with custom overlay controls
- Live TV with EPG and channel surfing
- DVR playback with commercial skip
- Siri Remote optimized

## Quick Start

### Prerequisites
- Go 1.21+ (for server)
- Android Studio (for Android TV app)
- Xcode 15+ (for Apple TV app)
- FFmpeg (for transcoding)
- Comskip (optional, for commercial detection)

### Run the Server

```bash
cd server

# Copy and configure
cp config.yaml.example config.yaml
# Edit config.yaml with your settings

# Build and run
go build -o openflix-server ./cmd/server
./openflix-server
```

The server runs on `http://localhost:32400` by default.

### Build Android TV App

```bash
cd android-native

# Build debug APK
./gradlew assembleDebug

# Install to device
adb install app/build/outputs/apk/debug/app-debug.apk
```

### Build Apple TV App

```bash
cd OpenFlix-tvOS

# Open in Xcode
open OpenFlix.xcodeproj

# Build and run on Apple TV simulator or device
```

### Docker

```bash
cd server
docker build -t openflix-server .
docker run -p 32400:32400 -v ~/.openflix:/data openflix-server
```

## Configuration

See `server/config.yaml.example` for all configuration options:

```yaml
server:
  port: 32400
  host: "0.0.0.0"

database:
  path: "~/.openflix/openflix.db"

media:
  libraries:
    - name: "Movies"
      path: "/media/movies"
      type: "movie"
    - name: "TV Shows"
      path: "/media/tv"
      type: "show"

livetv:
  m3u_sources:
    - name: "IPTV"
      url: "http://example.com/playlist.m3u"
  epg_sources:
    - url: "http://example.com/epg.xml"

dvr:
  storage_path: "/recordings"
  comskip_path: "/usr/local/bin/comskip"
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `GET /api/user` - Get current user

### Library
- `GET /library/sections` - List libraries
- `GET /library/sections/{id}/all` - Library content
- `GET /library/metadata/{key}` - Item details
- `GET /hubs/search` - Global search

### Live TV
- `GET /livetv/channels` - List channels
- `GET /livetv/guide` - EPG grid
- `GET /livetv/now` - Currently playing
- `POST /livetv/sources` - Add M3U source

### DVR
- `GET /dvr/recordings` - List recordings
- `POST /dvr/recordings` - Schedule recording
- `GET /dvr/recordings/{id}/commercials` - Commercial segments
- `GET /dvr/stream/{id}` - Stream recording

## Development

### Server
```bash
cd server
go build ./...
go test ./...
```

### Android TV
```bash
cd android-native
./gradlew build
./gradlew test
```

### Apple TV
```bash
cd OpenFlix-tvOS
xcodebuild -scheme OpenFlix -destination 'platform=tvOS Simulator,name=Apple TV'
```

## Building for Production

### Server
```bash
cd server
CGO_ENABLED=0 go build -o openflix-server ./cmd/server
```

### Android TV
```bash
cd android-native
./gradlew assembleRelease
```

### Apple TV
Build via Xcode with Release configuration or:
```bash
xcodebuild -scheme OpenFlix -configuration Release archive
```

## Acknowledgments

- Built with [Kotlin](https://kotlinlang.org), [Swift](https://swift.org), and [Go](https://golang.org)
- Android playback powered by [MPV](https://mpv.io)
- Apple TV playback via AVPlayer
- Commercial detection by [Comskip](https://github.com/erikkaashoek/Comskip)
- Metadata from [TMDB](https://www.themoviedb.org)

## License

MIT License - see [LICENSE](LICENSE) for details.
