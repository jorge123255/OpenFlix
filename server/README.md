# OpenFlix Server

Open-source media server with Live TV/IPTV and DVR capabilities. Compatible with the OpenFlix Flutter client.

## Features

- **Media Library** - Movies, TV Shows, Music
- **Transcoding** - FFmpeg-based with hardware acceleration
- **Live TV** - M3U playlist support with EPG/XMLTV
- **DVR** - Record live TV with series rules
- **Multi-User** - Profiles with parental controls
- **Plex-Compatible API** - Works with existing Plex clients

## Quick Start

### Using Docker

```bash
docker-compose up -d
```

### From Source

```bash
# Install Go 1.22+
go build -o openflix-server ./cmd/server
./openflix-server
```

Server will start on `http://localhost:32400`

## Configuration

Copy `config.yaml.example` to `config.yaml` and edit:

```yaml
server:
  host: "0.0.0.0"
  port: 32400

database:
  driver: "sqlite"
  dsn: "~/.openflix/openflix.db"

library:
  tmdb_api_key: "your-key"  # For metadata
```

Or use environment variables:

```bash
export OPENFLIX_PORT=32400
export OPENFLIX_TMDB_API_KEY=your-key
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `GET /auth/user` - Get current user

### Libraries
- `GET /library/sections` - List libraries
- `GET /library/sections/:id/all` - Get library content
- `GET /library/metadata/:key` - Get item details

### Live TV
- `GET /livetv/channels` - List channels
- `GET /livetv/guide` - Get EPG data
- `POST /livetv/sources` - Add M3U playlist

### DVR
- `GET /dvr/recordings` - List recordings
- `POST /dvr/recordings` - Schedule recording
- `POST /dvr/rules` - Create series rule

## Development

```bash
# Run with hot reload
go run ./cmd/server

# Build
go build -o openflix-server ./cmd/server

# Test
go test ./...
```

## License

MIT
