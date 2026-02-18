package api

const openAPISpec = `{
  "openapi": "3.0.3",
  "info": {
    "title": "OpenFlix Server API",
    "description": "Complete API for OpenFlix media server - a self-hosted media platform with Live TV, DVR, and media library management.",
    "version": "1.0.0",
    "license": { "name": "MIT" }
  },
  "servers": [{ "url": "/", "description": "This server" }],
  "components": {
    "securitySchemes": {
      "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" },
      "tokenParam": { "type": "apiKey", "in": "query", "name": "X-Plex-Token" }
    },
    "schemas": {
      "Error": { "type": "object", "properties": { "error": { "type": "string" } } },
      "Success": { "type": "object", "properties": { "success": { "type": "boolean" }, "message": { "type": "string" } } }
    }
  },
  "security": [{ "bearerAuth": [] }, { "tokenParam": [] }],
  "tags": [
    { "name": "Auth", "description": "Authentication and user management" },
    { "name": "Libraries", "description": "Media library management" },
    { "name": "Media", "description": "Media items, metadata, and playback" },
    { "name": "Live TV", "description": "Live TV channels, EPG, and streaming" },
    { "name": "DVR", "description": "Recording management (legacy)" },
    { "name": "DVR v2", "description": "DVR Jobs, Files, Groups, Rules" },
    { "name": "Playlists", "description": "Playlist and collection management" },
    { "name": "Search", "description": "Full-text search" },
    { "name": "Profiles", "description": "User profiles" },
    { "name": "Watchlist", "description": "User watchlist" },
    { "name": "Sports", "description": "Live sports scores and overlays" },
    { "name": "Multiview", "description": "Multi-stream viewing sessions" },
    { "name": "Commercial Skip", "description": "Commercial detection and skipping" },
    { "name": "Instant Switch", "description": "Channel prebuffering for instant switching" },
    { "name": "Watch Party", "description": "Synchronized group viewing" },
    { "name": "Subtitles", "description": "OpenSubtitles search and download" },
    { "name": "Notifications", "description": "Webhook and notification management" },
    { "name": "Health", "description": "Stream health monitoring" },
    { "name": "Scheduler", "description": "Background task scheduling" },
    { "name": "Bookmarks", "description": "Media bookmarks" },
    { "name": "Clips", "description": "Video clip extraction" },
    { "name": "Chapters", "description": "Chapter markers for recordings" },
    { "name": "Playback", "description": "Playback decisions and bandwidth" },
    { "name": "Tuners", "description": "HDHomeRun tuner management" },
    { "name": "Admin", "description": "Server administration" },
    { "name": "Speed Test", "description": "Network speed testing" }
  ],
  "paths": {
    "/auth/login": {
      "post": {
        "tags": ["Auth"], "summary": "Login with username and password",
        "requestBody": { "required": true, "content": { "application/json": { "schema": { "type": "object", "required": ["username", "password"], "properties": { "username": { "type": "string" }, "password": { "type": "string" } } } } } },
        "responses": { "200": { "description": "JWT token and user info" }, "401": { "description": "Invalid credentials" } }
      }
    },
    "/auth/register": {
      "post": {
        "tags": ["Auth"], "summary": "Register a new user",
        "requestBody": { "required": true, "content": { "application/json": { "schema": { "type": "object", "required": ["username", "password", "email"], "properties": { "username": { "type": "string" }, "password": { "type": "string" }, "email": { "type": "string" } } } } } },
        "responses": { "201": { "description": "User created" }, "409": { "description": "Username already exists" } }
      }
    },
    "/auth/refresh": {
      "post": { "tags": ["Auth"], "summary": "Refresh JWT token", "responses": { "200": { "description": "New JWT token" } } }
    },

    "/api/libraries": {
      "get": { "tags": ["Libraries"], "summary": "List all libraries", "responses": { "200": { "description": "Array of libraries" } } },
      "post": { "tags": ["Libraries"], "summary": "Create a new library", "responses": { "201": { "description": "Library created" } } }
    },
    "/api/libraries/{id}": {
      "get": { "tags": ["Libraries"], "summary": "Get library details", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Library details with items" } } },
      "put": { "tags": ["Libraries"], "summary": "Update library", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Library updated" } } },
      "delete": { "tags": ["Libraries"], "summary": "Delete library", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Library deleted" } } }
    },
    "/api/libraries/{id}/scan": {
      "post": { "tags": ["Libraries"], "summary": "Trigger library scan", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Scan results" } } }
    },

    "/api/media": {
      "get": {
        "tags": ["Media"], "summary": "List media items",
        "parameters": [
          { "name": "type", "in": "query", "schema": { "type": "string", "enum": ["movie", "show", "season", "episode"] } },
          { "name": "library_id", "in": "query", "schema": { "type": "integer" } },
          { "name": "page", "in": "query", "schema": { "type": "integer" } },
          { "name": "limit", "in": "query", "schema": { "type": "integer" } }
        ],
        "responses": { "200": { "description": "Paginated media items" } }
      }
    },
    "/api/media/{id}": {
      "get": { "tags": ["Media"], "summary": "Get media item details", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Full media item with files, streams, and cast" } } }
    },

    "/api/livetv/channels": {
      "get": { "tags": ["Live TV"], "summary": "List all channels", "parameters": [{ "name": "group", "in": "query", "schema": { "type": "string" } }], "responses": { "200": { "description": "Array of channels" } } }
    },
    "/api/livetv/channels/{id}/stream": {
      "get": { "tags": ["Live TV"], "summary": "Get channel stream URL", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Stream URL and format info" } } }
    },
    "/api/livetv/epg": {
      "get": { "tags": ["Live TV"], "summary": "Get EPG guide data", "parameters": [{ "name": "start", "in": "query", "schema": { "type": "string", "format": "date-time" } }, { "name": "end", "in": "query", "schema": { "type": "string", "format": "date-time" } }], "responses": { "200": { "description": "EPG program data" } } }
    },
    "/api/livetv/sources/m3u": {
      "get": { "tags": ["Live TV"], "summary": "List M3U sources", "responses": { "200": { "description": "Array of M3U sources" } } },
      "post": { "tags": ["Live TV"], "summary": "Add M3U source", "responses": { "201": { "description": "Source created and channels imported" } } }
    },
    "/api/livetv/sources/xtream": {
      "get": { "tags": ["Live TV"], "summary": "List Xtream sources", "responses": { "200": { "description": "Array of Xtream sources" } } },
      "post": { "tags": ["Live TV"], "summary": "Add Xtream source", "responses": { "201": { "description": "Source created" } } }
    },
    "/api/livetv/groups": {
      "get": { "tags": ["Live TV"], "summary": "List channel groups", "responses": { "200": { "description": "Array of channel groups" } } },
      "post": { "tags": ["Live TV"], "summary": "Create channel group", "responses": { "201": { "description": "Group created" } } }
    },

    "/dvr/recordings": {
      "get": { "tags": ["DVR"], "summary": "List recordings (legacy)", "responses": { "200": { "description": "Array of recordings" } } },
      "post": { "tags": ["DVR"], "summary": "Schedule a recording (legacy)", "responses": { "201": { "description": "Recording scheduled" } } }
    },
    "/dvr/recordings/{id}": {
      "get": { "tags": ["DVR"], "summary": "Get recording details", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Recording details" } } },
      "delete": { "tags": ["DVR"], "summary": "Delete/cancel recording", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Recording deleted" } } }
    },

    "/dvr/v2/jobs": {
      "get": { "tags": ["DVR v2"], "summary": "List DVR jobs", "responses": { "200": { "description": "Array of DVR jobs" } } },
      "post": { "tags": ["DVR v2"], "summary": "Create DVR job", "responses": { "201": { "description": "Job created" } } }
    },
    "/dvr/v2/jobs/{id}": {
      "get": { "tags": ["DVR v2"], "summary": "Get DVR job", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Job details" } } },
      "put": { "tags": ["DVR v2"], "summary": "Update DVR job", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Job updated" } } },
      "delete": { "tags": ["DVR v2"], "summary": "Cancel/delete DVR job", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Job deleted" } } }
    },
    "/dvr/v2/files": {
      "get": { "tags": ["DVR v2"], "summary": "List completed recording files", "responses": { "200": { "description": "Array of DVR files" } } }
    },
    "/dvr/v2/files/{id}": {
      "get": { "tags": ["DVR v2"], "summary": "Get recording file", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "File details" } } },
      "put": { "tags": ["DVR v2"], "summary": "Update file metadata", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "File updated" } } },
      "delete": { "tags": ["DVR v2"], "summary": "Delete recording file", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "File deleted" } } }
    },
    "/dvr/v2/files/{id}/stream": {
      "get": { "tags": ["DVR v2"], "summary": "Stream recording file", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Video stream" } } }
    },
    "/dvr/v2/files/{id}/chapters": {
      "get": { "tags": ["Chapters"], "summary": "Get chapter markers for a file", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Array of chapter markers" } } },
      "post": { "tags": ["Chapters"], "summary": "Add chapter marker", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "201": { "description": "Chapter created" } } }
    },
    "/dvr/v2/files/{id}/chapters/detect": {
      "post": { "tags": ["Chapters"], "summary": "Auto-detect chapters via scene detection", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Detected chapters" } } }
    },
    "/dvr/v2/groups": {
      "get": { "tags": ["DVR v2"], "summary": "List recording groups", "responses": { "200": { "description": "Array of DVR groups" } } }
    },
    "/dvr/v2/rules": {
      "get": { "tags": ["DVR v2"], "summary": "List DVR rules", "responses": { "200": { "description": "Array of DVR rules" } } },
      "post": { "tags": ["DVR v2"], "summary": "Create DVR rule with query DSL", "responses": { "201": { "description": "Rule created" } } }
    },

    "/api/playlists": {
      "get": { "tags": ["Playlists"], "summary": "List playlists", "responses": { "200": { "description": "Array of playlists" } } },
      "post": { "tags": ["Playlists"], "summary": "Create playlist", "responses": { "201": { "description": "Playlist created" } } }
    },

    "/api/search": {
      "get": {
        "tags": ["Search"], "summary": "Search media, channels, and recordings",
        "parameters": [{ "name": "q", "in": "query", "required": true, "schema": { "type": "string" } }, { "name": "type", "in": "query", "schema": { "type": "string" } }],
        "responses": { "200": { "description": "Search results grouped by type" } }
      }
    },

    "/api/profiles": {
      "get": { "tags": ["Profiles"], "summary": "List user profiles", "responses": { "200": { "description": "Array of profiles" } } },
      "post": { "tags": ["Profiles"], "summary": "Create profile", "responses": { "201": { "description": "Profile created" } } }
    },

    "/api/watchlist": {
      "get": { "tags": ["Watchlist"], "summary": "Get watchlist items", "responses": { "200": { "description": "Array of watchlist items" } } },
      "post": { "tags": ["Watchlist"], "summary": "Add to watchlist", "responses": { "201": { "description": "Item added" } } }
    },

    "/api/sports/scores": {
      "get": { "tags": ["Sports"], "summary": "Get live sports scores", "parameters": [{ "name": "sport", "in": "query", "schema": { "type": "string" } }], "responses": { "200": { "description": "Live game scores" } } }
    },
    "/api/sports/overlay": {
      "get": { "tags": ["Sports"], "summary": "Get sports overlay data for TV display", "responses": { "200": { "description": "Overlay-formatted score data" } } }
    },

    "/api/multiview/sessions": {
      "get": { "tags": ["Multiview"], "summary": "List multiview sessions", "responses": { "200": { "description": "Active sessions" } } },
      "post": { "tags": ["Multiview"], "summary": "Create multiview session", "responses": { "201": { "description": "Session created" } } }
    },

    "/api/instant/status": {
      "get": { "tags": ["Instant Switch"], "summary": "Get prebuffer status", "responses": { "200": { "description": "Prebuffer statistics" } } }
    },

    "/api/commercial/detect": {
      "post": { "tags": ["Commercial Skip"], "summary": "Trigger commercial detection", "responses": { "200": { "description": "Detection started" } } }
    },
    "/api/commercial/get": {
      "get": { "tags": ["Commercial Skip"], "summary": "Get detected commercials", "parameters": [{ "name": "recording_id", "in": "query", "required": true, "schema": { "type": "string" } }], "responses": { "200": { "description": "Commercial segments" } } }
    },

    "/watchparty": {
      "get": { "tags": ["Watch Party"], "summary": "List active watch parties", "responses": { "200": { "description": "Active parties" } } },
      "post": { "tags": ["Watch Party"], "summary": "Create watch party", "responses": { "201": { "description": "Party created with invite code" } } }
    },

    "/api/subtitles/search": {
      "get": {
        "tags": ["Subtitles"], "summary": "Search OpenSubtitles",
        "parameters": [{ "name": "media_id", "in": "query", "schema": { "type": "integer" } }, { "name": "language", "in": "query", "schema": { "type": "string" } }],
        "responses": { "200": { "description": "Subtitle search results" } }
      }
    },
    "/api/subtitles/download": {
      "post": { "tags": ["Subtitles"], "summary": "Download subtitle file", "responses": { "200": { "description": "Subtitle downloaded" } } }
    },

    "/api/notifications/config": {
      "get": { "tags": ["Notifications"], "summary": "Get notification config", "responses": { "200": { "description": "Current notification configuration" } } },
      "put": { "tags": ["Notifications"], "summary": "Update notification config", "responses": { "200": { "description": "Config updated" } } }
    },
    "/api/notifications/test": {
      "post": { "tags": ["Notifications"], "summary": "Send test notification", "responses": { "200": { "description": "Test sent" } } }
    },
    "/api/notifications/history": {
      "get": { "tags": ["Notifications"], "summary": "Get notification history", "responses": { "200": { "description": "Recent notifications" } } }
    },

    "/api/health/streams": {
      "get": { "tags": ["Health"], "summary": "List active stream health metrics", "responses": { "200": { "description": "Stream health data" } } }
    },
    "/api/health/streams/{id}": {
      "get": { "tags": ["Health"], "summary": "Get stream health details", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }], "responses": { "200": { "description": "Detailed stream metrics" } } }
    },
    "/api/health/streams/{id}/report": {
      "post": { "tags": ["Health"], "summary": "Report stream health from client", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }], "responses": { "200": { "description": "Report accepted" } } }
    },
    "/api/health/alerts": {
      "get": { "tags": ["Health"], "summary": "Get health alerts (admin)", "responses": { "200": { "description": "Active alerts" } } }
    },
    "/api/health/summary": {
      "get": { "tags": ["Health"], "summary": "Get system health summary (admin)", "responses": { "200": { "description": "Overall health summary" } } }
    },

    "/api/scheduler/tasks": {
      "get": { "tags": ["Scheduler"], "summary": "List scheduled tasks", "responses": { "200": { "description": "Array of scheduled tasks with status" } } }
    },
    "/api/scheduler/tasks/{id}": {
      "get": { "tags": ["Scheduler"], "summary": "Get task details", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }], "responses": { "200": { "description": "Task details with run history" } } },
      "put": { "tags": ["Scheduler"], "summary": "Update task config", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }], "responses": { "200": { "description": "Task updated" } } }
    },
    "/api/scheduler/tasks/{id}/run": {
      "post": { "tags": ["Scheduler"], "summary": "Trigger task execution", "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }], "responses": { "202": { "description": "Task triggered" } } }
    },
    "/api/scheduler/history": {
      "get": { "tags": ["Scheduler"], "summary": "Get task execution history", "parameters": [{ "name": "limit", "in": "query", "schema": { "type": "integer", "default": 50 } }], "responses": { "200": { "description": "Execution history" } } }
    },

    "/api/bookmarks": {
      "get": { "tags": ["Bookmarks"], "summary": "List bookmarks", "responses": { "200": { "description": "Array of bookmarks" } } },
      "post": { "tags": ["Bookmarks"], "summary": "Create bookmark", "responses": { "201": { "description": "Bookmark created" } } }
    },
    "/api/clips": {
      "get": { "tags": ["Clips"], "summary": "List clips", "responses": { "200": { "description": "Array of clips" } } },
      "post": { "tags": ["Clips"], "summary": "Create clip from media", "responses": { "201": { "description": "Clip created" } } }
    },

    "/api/playback/decide/{fileId}": {
      "get": { "tags": ["Playback"], "summary": "Get playback decision for a file", "parameters": [{ "name": "fileId", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Playback decision (direct play, transcode, etc.)" } } }
    },
    "/api/playback/{fileId}/markers": {
      "get": { "tags": ["Playback"], "summary": "Get skip markers (intro/outro)", "parameters": [{ "name": "fileId", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Skip marker positions" } } }
    },
    "/api/playback/bandwidth": {
      "post": { "tags": ["Playback"], "summary": "Report client bandwidth measurement", "responses": { "200": { "description": "Bandwidth recorded" } } }
    },

    "/api/tuners": {
      "get": { "tags": ["Tuners"], "summary": "List HDHomeRun tuners", "responses": { "200": { "description": "Array of tuners" } } },
      "post": { "tags": ["Tuners"], "summary": "Add tuner manually", "responses": { "201": { "description": "Tuner added" } } }
    },
    "/api/tuners/discover": {
      "post": { "tags": ["Tuners"], "summary": "Discover tuners on network", "responses": { "200": { "description": "Discovered tuners" } } }
    },

    "/api/speedtest/ping": {
      "get": { "tags": ["Speed Test"], "summary": "Ping test for latency measurement", "responses": { "200": { "description": "Pong response with timestamp" } } }
    },
    "/api/speedtest/download": {
      "get": { "tags": ["Speed Test"], "summary": "Download test data for speed measurement", "responses": { "200": { "description": "Random data payload" } } }
    },

    "/admin/libraries": {
      "get": { "tags": ["Admin"], "summary": "List all libraries (admin)", "responses": { "200": { "description": "Libraries with paths" } } }
    },
    "/admin/users": {
      "get": { "tags": ["Admin"], "summary": "List all users (admin)", "responses": { "200": { "description": "Array of users" } } }
    },
    "/admin/settings": {
      "get": { "tags": ["Admin"], "summary": "Get server settings", "responses": { "200": { "description": "Server configuration" } } },
      "put": { "tags": ["Admin"], "summary": "Update server settings", "responses": { "200": { "description": "Settings updated" } } }
    },
    "/admin/backups": {
      "get": { "tags": ["Admin"], "summary": "List database backups", "responses": { "200": { "description": "Available backups" } } },
      "post": { "tags": ["Admin"], "summary": "Create database backup", "responses": { "201": { "description": "Backup created" } } }
    },

    "/library/parts/{partId}/file": {
      "get": { "tags": ["Media"], "summary": "Stream media file directly", "parameters": [{ "name": "partId", "in": "path", "required": true, "schema": { "type": "integer" } }], "responses": { "200": { "description": "Media stream" } } }
    },
    "/video/-/transcode/universal/start.m3u8": {
      "get": { "tags": ["Media"], "summary": "Start HLS transcode session", "responses": { "200": { "description": "HLS master playlist" } } }
    },
    "/video/-/transcode/dash/start.mpd": {
      "get": { "tags": ["Media"], "summary": "Start DASH transcode session", "responses": { "200": { "description": "DASH manifest" } } }
    }
  }
}`
