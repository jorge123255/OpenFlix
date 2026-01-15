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

export interface RegisterRequest {
  username: string
  email: string
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
  providerType: 'xmltv' | 'gracenote'
  // XMLTV fields
  url?: string
  // Gracenote fields
  gracenoteAffiliate?: string
  gracenotePostalCode?: string
  gracenoteHours?: number
  // Common fields
  lastFetched?: string
  programCount?: number
  channelCount?: number
  enabled: boolean
  createdAt: string
  updatedAt: string
}

export interface XtreamSource {
  id: number
  name: string
  serverUrl: string
  username: string
  enabled: boolean
  lastFetched?: string
  lastError?: string
  expirationDate?: string
  maxConnections?: number
  activeConns?: number
  importLive: boolean
  importVod: boolean
  importSeries: boolean
  vodLibraryId?: number
  seriesLibraryId?: number
  channelCount: number
  vodCount: number
  seriesCount: number
  createdAt: string
  updatedAt: string
}

export interface Channel {
  id: number
  number: string
  name: string
  logo?: string
  sourceId: number
  epgSourceId?: number
  channelId?: string // EPG channel ID for mapping
}

export interface EPGChannel {
  channelId: string
  sampleTitle: string
}

export interface Program {
  id: number
  channelId: string
  title: string
  description?: string
  start: string
  end: string
  icon?: string
  category?: string
  episodeNum?: string
  channelName?: string
  // Episode status flags
  isNew?: boolean
  isPremiere?: boolean
  isLive?: boolean
  isFinale?: boolean
  // Content type flags
  isMovie?: boolean
  isSports?: boolean
  isKids?: boolean
  isNews?: boolean
}

export interface ProgramsResponse {
  programs: Program[]
  total: number
  page: number
  limit: number
  pages: number
}

export interface GuideResponse {
  start: string
  end: string
  channels: Channel[]
  programs: { [channelId: string]: Program[] }
}

// DVR types
export interface Recording {
  id: number
  title: string
  description?: string
  summary?: string
  channelId: number
  channelName?: string
  channelLogo?: string
  startTime: string
  endTime: string
  duration?: number
  status: 'scheduled' | 'recording' | 'completed' | 'failed'
  filePath?: string
  fileSize?: number
  category?: string
  episodeNum?: string
  seriesRecord?: boolean
  seriesRuleId?: number
  programId?: number
  createdAt: string
  // TMDB metadata fields
  thumb?: string
  art?: string
  seasonNumber?: number
  episodeNumber?: number
  genres?: string
  contentRating?: string
  year?: number
  rating?: number
  isMovie?: boolean
  isLive?: boolean
  viewOffset?: number  // milliseconds - for resume playback
}

export interface CommercialSegment {
  id: number
  recordingId: number
  startTime: number  // seconds from beginning
  endTime: number    // seconds from beginning
  duration: number   // seconds
}

export interface CommercialsResponse {
  recordingId: number
  segments: CommercialSegment[]
  totalCommercials: number
  commercialSeconds: number
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
  server: {
    name: string
    version: string
    hostname: string
    machineIdentifier: string
    platform: string
    arch: string
    goVersion: string
    uptime: string
  }
  sessions: {
    active: number
  }
  libraries: {
    count: number
    movies: number
    shows: number
    episodes: number
  }
  livetv: {
    channels: number
    timeshiftChannels: number
    timeshiftEnabled: boolean
  }
  dvr: {
    scheduled: number
    recording: number
    completed: number
    commercialDetect: boolean
  }
  system: {
    goroutines: number
    memAllocMB: number
    memTotalMB: number
    numCPU: number
  }
  logging: {
    level: string
    json: boolean
  }
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

// DVR Conflict types
export interface ConflictGroup {
  recordings: Recording[]
}

export interface ConflictResponse {
  conflicts: ConflictGroup[]
  hasConflicts: boolean
  totalCount: number
}

// Live Recording Stats types
export interface RecordingStats {
  id: number
  title: string
  fileSize: number
  fileSizeFormatted: string
  elapsedSeconds: number
  elapsedFormatted: string
  totalSeconds: number
  remainingSeconds: number
  progressPercent: number
  bitrate?: string
  isHealthy: boolean
  isFailed: boolean
  failureReason?: string
}

export interface RecordingStatsResponse {
  stats: RecordingStats[]
  activeCount: number
}

// On Later types
export interface OnLaterProgram {
  id: number
  channelId: string
  title: string
  subtitle?: string
  description?: string
  start: string
  end: string
  icon?: string
  art?: string
  category?: string
  episodeNum?: string
  seasonNumber?: number
  episodeNumber?: number
  rating?: string
  isMovie?: boolean
  isSports?: boolean
  isKids?: boolean
  isNews?: boolean
  isPremiere?: boolean
  isNew?: boolean
  isLive?: boolean
  isFinale?: boolean
  teams?: string
  league?: string
  seriesId?: string
  programId?: string
}

export interface OnLaterChannel {
  id: number
  channelId: string
  name: string
  logo?: string
  number?: number
}

export interface OnLaterItem {
  program: OnLaterProgram
  channel?: OnLaterChannel
  hasRecording: boolean
  recordingId?: number
}

export interface OnLaterResponse {
  items: OnLaterItem[]
  totalCount: number
  startTime: string
  endTime: string
}

export interface OnLaterStats {
  movies: number
  sports: number
  kids: number
  news: number
  premieres: number
}

export interface SportsTeam {
  name: string
  city: string
  nickname: string
  league?: string
  aliases: string[]
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
