<h1>
  <img src="assets/openflix.png" alt="OpenFlix Logo" height="24" style="vertical-align: middle;" />
  OpenFlix
</h1>

OpenFlix is an open-source media server with Live TV/IPTV and DVR capabilities. It provides a complete self-hosted streaming solution with a modern Flutter client and a Go-powered backend.

## Project Structure

```
openflix/
├── lib/                 # Flutter client source
├── server/              # Go backend server
│   ├── cmd/server/      # Server entrypoint
│   └── internal/        # Server modules
│       ├── api/         # HTTP handlers
│       ├── auth/        # JWT authentication
│       ├── db/          # Database layer
│       ├── library/     # Media scanning
│       ├── metadata/    # TMDB/TVDB agents
│       ├── livetv/      # M3U, EPG, channels
│       ├── dvr/         # Recording engine
│       └── transcode/   # FFmpeg wrapper
├── android/             # Android app
├── ios/                 # iOS app
├── macos/               # macOS app
├── windows/             # Windows app
└── linux/               # Linux app
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

### Client
- Cross-platform (iOS, Android, macOS, Windows, Linux)
- Rich media browsing with metadata
- Advanced video playback (HEVC, AV1, VP9)
- Live TV guide with EPG grid
- Channel surfing
- DVR management and playback
- Commercial skip (auto/manual)
- Subtitle support (ASS/SSA)
- Playback progress sync

## Quick Start

### Prerequisites
- Go 1.21+ (for server)
- Flutter SDK 3.8.1+ (for client)
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

### Run the Client

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build

# Run
flutter run
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

### Client
```bash
flutter analyze
flutter test
dart format .
```

## Building for Production

### Server
```bash
cd server
CGO_ENABLED=0 go build -o openflix-server ./cmd/server
```

### Client
```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
flutter build apk --release
flutter build ios --release
```

## Acknowledgments

- Client forked from [Plezy](https://github.com/edde746/plezy)
- Built with [Flutter](https://flutter.dev) and [Go](https://golang.org)
- Media playback powered by [MediaKit](https://github.com/media-kit/media-kit)
- Commercial detection by [Comskip](https://github.com/erikkaashoek/Comskip)

## License

MIT License - see [LICENSE](LICENSE) for details.
