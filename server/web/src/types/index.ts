// User types
export interface User {
  id: number
  uuid: string
  username: string
  email: string
  title: string  // displayName in API
  thumb?: string
  admin: boolean
  restricted: boolean
  hasPassword: boolean
  createdAt: string
  updatedAt: string
}

export interface UserProfile {
  id: number
  uuid: string
  name: string
  thumb?: string
  isKid: boolean
  maxRating?: string
}

// Auth types
export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  authToken: string
  user: User
}

export interface AuthUser {
  id: number
  uuid: string
  username: string
  email: string
  displayName: string
  isAdmin: boolean
}

// Library types
export interface Library {
  id: number
  uuid: string
  title: string
  type: 'movie' | 'show' | 'music' | 'photo'
  agent: string
  scanner: string
  language: string
  hidden: boolean
  paths: LibraryPath[]
  createdAt: string
  updatedAt: string
  scannedAt?: string
}

export interface LibraryPath {
  id: number
  path: string
}

export interface CreateLibraryRequest {
  title: string
  type: 'movie' | 'show' | 'music' | 'photo'
  paths: string[]
  language?: string
}

export interface LibraryStats {
  libraryId: number
  movieCount: number
  showCount: number
  seasonCount: number
  episodeCount: number
  fileCount: number
  totalSize: number
  totalDuration: number
}

export interface FilesystemEntry {
  name: string
  path: string
  isDir: boolean
  size?: number
  modTime?: number
}

export interface FilesystemBrowseResponse {
  path: string
  parentPath?: string
  entries: FilesystemEntry[]
}

// Live TV types
export interface M3USource {
  id: number
  name: string
  url: string
  channelCount: number
  lastRefresh?: string
  createdAt: string
}

export interface EPGSource {
  id: number
  name: string
  url: string
  lastRefresh?: string
  createdAt: string
}

export interface Channel {
  id: number
  number: string
  name: string
  logo?: string
  sourceId: number
}

// DVR types
export interface Recording {
  id: number
  title: string
  channelId: number
  channelName: string
  startTime: string
  endTime: string
  duration: number
  status: 'scheduled' | 'recording' | 'completed' | 'failed'
  filePath?: string
  fileSize?: number
  createdAt: string
}

export interface SeriesRule {
  id: number
  title: string
  channelId?: number
  anyChannel: boolean
  anyTime: boolean
  startTime?: string
  endTime?: string
  keepCount: number
  priority: number
  prePadding: number
  postPadding: number
  enabled: boolean
  createdAt: string
}

// Server types
export interface ServerStatus {
  version: string
  uptime: number
  activeSessions: number
  libraryCount: number
  recordingCount: number
}

export interface ServerConfig {
  server: {
    host: string
    port: number
  }
  auth: {
    allowSignup: boolean
    tokenExpiry: number
  }
  library: {
    scanInterval: number
    metadataLang: string
    tmdbApiKey: string
    tvdbApiKey: string
  }
  livetv: {
    enabled: boolean
    epgInterval: number
  }
  dvr: {
    enabled: boolean
    recordingDir: string
    prePadding: number
    postPadding: number
  }
  transcode: {
    enabled: boolean
    ffmpegPath: string
    hardwareAccel: string
    tempDir: string
    maxSessions: number
  }
}

// API Response wrappers
export interface MediaContainer<T> {
  MediaContainer: {
    size: number
    totalSize?: number
    offset?: number
    Metadata?: T[]
    Directory?: T[]
  }
}
