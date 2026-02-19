import axios, { type AxiosError, type AxiosInstance } from 'axios'
import type {
  User,
  UserProfile,
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  Library,
  CreateLibraryRequest,
  LibraryStats,
  FilesystemBrowseResponse,
  M3USource,
  EPGSource,
  EPGChannel,
  ProgramsResponse,
  GuideResponse,
  Recording,
  SeriesRule,
  ServerStatus,
  XtreamSource,
  ConflictResponse,
  RecordingStatsResponse,
  CommercialsResponse,
  MapNumbersResult,
  ChannelGroup,
  ChannelGroupMember,
  DuplicateGroup,
} from '../types'

const TOKEN_KEY = 'openflix_token'

class ApiClient {
  client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: '',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    // Add auth token to requests
    this.client.interceptors.request.use((config) => {
      const token = this.getToken()
      if (token) {
        config.headers['X-Plex-Token'] = token
      }
      return config
    })

    // Handle 401 responses
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401) {
          this.clearToken()
          window.location.href = '/ui/login'
        }
        return Promise.reject(error)
      }
    )
  }

  // Token management
  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY)
  }

  setToken(token: string): void {
    localStorage.setItem(TOKEN_KEY, token)
  }

  clearToken(): void {
    localStorage.removeItem(TOKEN_KEY)
  }

  isAuthenticated(): boolean {
    return !!this.getToken()
  }

  // Auth endpoints
  async login(data: LoginRequest): Promise<LoginResponse> {
    const response = await this.client.post<LoginResponse>('/auth/login', data)
    this.setToken(response.data.authToken)
    return response.data
  }

  async register(data: RegisterRequest): Promise<User> {
    const response = await this.client.post<User>('/auth/register', data)
    return response.data
  }

  async logout(): Promise<void> {
    try {
      await this.client.post('/auth/logout')
    } finally {
      this.clearToken()
    }
  }

  async getCurrentUser(): Promise<User> {
    const response = await this.client.get<User>('/auth/user')
    return response.data
  }

  // User management (admin)
  async getUsers(): Promise<User[]> {
    const response = await this.client.get<{ users: User[] }>('/admin/users')
    return response.data.users || []
  }

  async createUser(data: { username: string; email: string; password: string; isAdmin?: boolean }): Promise<User> {
    const response = await this.client.post<User>('/auth/register', data)
    return response.data
  }

  async updateUser(id: number, data: Partial<User>): Promise<User> {
    const response = await this.client.put<User>(`/admin/users/${id}`, data)
    return response.data
  }

  async deleteUser(id: number): Promise<void> {
    await this.client.delete(`/admin/users/${id}`)
  }

  // Profile endpoints
  async getProfiles(): Promise<UserProfile[]> {
    const response = await this.client.get<{ profiles: UserProfile[] }>('/profiles')
    return response.data.profiles || []
  }

  async getUserProfiles(userId: number): Promise<UserProfile[]> {
    const response = await this.client.get<{ profiles: UserProfile[] }>(`/admin/users/${userId}/profiles`)
    return response.data.profiles || []
  }

  async createProfile(data: { name: string; isKid?: boolean }): Promise<UserProfile> {
    const response = await this.client.post<UserProfile>('/profiles', data)
    return response.data
  }

  async deleteProfile(id: number): Promise<void> {
    await this.client.delete(`/profiles/${id}`)
  }

  // Library endpoints
  async getLibraries(): Promise<Library[]> {
    const response = await this.client.get<{ libraries: Library[] }>('/admin/libraries')
    return response.data.libraries || []
  }

  async createLibrary(data: CreateLibraryRequest): Promise<Library> {
    const response = await this.client.post<Library>('/admin/libraries', data)
    return response.data
  }

  async updateLibrary(id: number, data: Partial<Library>): Promise<Library> {
    const response = await this.client.put<Library>(`/admin/libraries/${id}`, data)
    return response.data
  }

  async deleteLibrary(id: number): Promise<void> {
    await this.client.delete(`/admin/libraries/${id}`)
  }

  async scanLibrary(id: number): Promise<void> {
    await this.client.post(`/admin/libraries/${id}/scan`)
  }

  async addLibraryPath(libraryId: number, path: string): Promise<void> {
    await this.client.post(`/admin/libraries/${libraryId}/paths`, { path })
  }

  async removeLibraryPath(libraryId: number, pathId: number): Promise<void> {
    await this.client.delete(`/admin/libraries/${libraryId}/paths/${pathId}`)
  }

  async getLibraryStats(libraryId: number): Promise<LibraryStats> {
    const response = await this.client.get<LibraryStats>(`/admin/libraries/${libraryId}/stats`)
    return response.data
  }

  async browseFilesystem(path?: string): Promise<FilesystemBrowseResponse> {
    const response = await this.client.get<FilesystemBrowseResponse>('/admin/filesystem/browse', {
      params: path ? { path } : undefined
    })
    return response.data
  }

  // Live TV endpoints
  async getM3USources(): Promise<M3USource[]> {
    const response = await this.client.get<{ sources: M3USource[] }>('/livetv/sources')
    return response.data.sources || []
  }

  async createM3USource(data: {
    name: string
    url: string
    importVod?: boolean
    importSeries?: boolean
    vodLibraryId?: number
    seriesLibraryId?: number
  }): Promise<M3USource> {
    const response = await this.client.post<M3USource>('/livetv/sources', data)
    return response.data
  }

  async updateM3USource(id: number, data: {
    name?: string
    url?: string
    importVod?: boolean
    importSeries?: boolean
    vodLibraryId?: number
    seriesLibraryId?: number
  }): Promise<M3USource> {
    const response = await this.client.put<M3USource>(`/livetv/sources/${id}`, data)
    return response.data
  }

  async deleteM3USource(id: number): Promise<void> {
    await this.client.delete(`/livetv/sources/${id}`)
  }

  async refreshM3USource(id: number): Promise<void> {
    await this.client.post(`/livetv/sources/${id}/refresh`)
  }

  async importM3UVOD(id: number): Promise<{ added: number; updated: number; errors: number; duration: string }> {
    const response = await this.client.post(`/livetv/sources/${id}/import-vod`)
    return response.data
  }

  async importM3USeries(id: number): Promise<{ status: string; message: string }> {
    const response = await this.client.post(`/livetv/sources/${id}/import-series`)
    return response.data
  }

  async mapChannelNumbers(data: {
    url?: string;
    content?: string;
    preview?: boolean;
    manualMappings?: Array<{ m3uName: string; m3uNumber: number; channelId: number }>;
  }): Promise<MapNumbersResult> {
    const response = await this.client.post<MapNumbersResult>('/livetv/channels/map-numbers', data)
    return response.data
  }

  // Configuration Export/Import
  async exportConfig(): Promise<Blob> {
    const response = await this.client.get('/config/export', {
      responseType: 'blob',
    })
    return response.data
  }

  async getConfigStats(): Promise<ConfigStats> {
    const response = await this.client.get<ConfigStats>('/config/stats')
    return response.data
  }

  async importConfig(data: unknown, preview: boolean = false): Promise<ImportResult> {
    const url = preview ? '/config/import?preview=true' : '/config/import'
    const response = await this.client.post<ImportResult>(url, data)
    return response.data
  }

  // Channel Groups (Failover)
  async getChannelGroups(): Promise<ChannelGroup[]> {
    const response = await this.client.get<{ groups: ChannelGroup[] }>('/livetv/channel-groups')
    return response.data.groups || []
  }

  async createChannelGroup(data: { name: string; displayNumber?: number; logo?: string; channelId?: string }): Promise<ChannelGroup> {
    const response = await this.client.post<ChannelGroup>('/livetv/channel-groups', data)
    return response.data
  }

  async updateChannelGroup(id: number, data: Partial<{ name: string; displayNumber: number; logo: string; channelId: string; enabled: boolean }>): Promise<ChannelGroup> {
    const response = await this.client.put<ChannelGroup>(`/livetv/channel-groups/${id}`, data)
    return response.data
  }

  async deleteChannelGroup(id: number): Promise<void> {
    await this.client.delete(`/livetv/channel-groups/${id}`)
  }

  async addChannelToGroup(groupId: number, channelId: number, priority?: number): Promise<ChannelGroupMember> {
    const response = await this.client.post<ChannelGroupMember>(`/livetv/channel-groups/${groupId}/members`, {
      channelId,
      priority: priority ?? 0,
    })
    return response.data
  }

  async updateGroupMemberPriority(groupId: number, channelId: number, priority: number): Promise<ChannelGroupMember> {
    const response = await this.client.put<ChannelGroupMember>(`/livetv/channel-groups/${groupId}/members/${channelId}`, { priority })
    return response.data
  }

  async removeChannelFromGroup(groupId: number, channelId: number): Promise<void> {
    await this.client.delete(`/livetv/channel-groups/${groupId}/members/${channelId}`)
  }

  async autoDetectDuplicates(): Promise<{ duplicates: DuplicateGroup[] }> {
    const response = await this.client.post<{ duplicates: DuplicateGroup[] }>('/livetv/channel-groups/auto-detect')
    return response.data
  }

  async getEPGSources(): Promise<EPGSource[]> {
    const response = await this.client.get<{ sources: EPGSource[] }>('/livetv/epg/sources')
    return response.data.sources || []
  }

  async previewEPGSource(data: {
    postalCode: string
    affiliate?: string
    hours?: number
  }): Promise<{
    affiliate: string
    postalCode: string
    totalChannels: number
    totalPrograms: number
    previewChannels: Array<{
      channelId: string
      callSign: string
      channelNo: string
      affiliateName: string
      programCount: number
    }>
  }> {
    const response = await this.client.post('/livetv/epg/sources/preview', data)
    return response.data
  }

  async createEPGSource(data: {
    name: string
    providerType: 'xmltv' | 'gracenote'
    url?: string
    gracenoteAffiliate?: string
    gracenotePostalCode?: string
    gracenoteHours?: number
  }): Promise<EPGSource> {
    const response = await this.client.post<EPGSource>('/livetv/epg/sources', data)
    return response.data
  }

  async deleteEPGSource(id: number): Promise<void> {
    await this.client.delete(`/livetv/epg/sources/${id}`)
  }

  async updateEPGSource(id: number, data: {
    name?: string
    url?: string
    gracenoteAffiliate?: string
    gracenotePostalCode?: string
    gracenoteHours?: number
    enabled?: boolean
  }): Promise<EPGSource> {
    const response = await this.client.put<EPGSource>(`/livetv/epg/sources/${id}`, data)
    return response.data
  }

  async refreshEPG(): Promise<void> {
    await this.client.post('/livetv/epg/refresh')
  }

  async getGuide(): Promise<GuideResponse> {
    const response = await this.client.get<GuideResponse>('/livetv/guide')
    return response.data
  }

  async getOnNow(): Promise<OnNowChannel[]> {
    const response = await this.client.get<{ channels: OnNowChannel[] }>('/livetv/now')
    return response.data.channels || []
  }

  async getEPGPrograms(params?: {
    page?: number
    limit?: number
    epgSourceId?: number
    channelId?: string
  }): Promise<ProgramsResponse> {
    const response = await this.client.get<ProgramsResponse>('/livetv/epg/programs', { params })
    return response.data
  }

  async getEPGChannels(epgSourceId?: number): Promise<EPGChannel[]> {
    const response = await this.client.get<{ channels: EPGChannel[] }>('/livetv/epg/channels', {
      params: epgSourceId ? { epgSourceId } : undefined
    })
    return response.data.channels || []
  }

  async discoverProviders(postalCode: string): Promise<ProviderDiscoveryResponse> {
    const response = await this.client.get<ProviderDiscoveryResponse>('/livetv/gracenote/providers', {
      params: { postalCode }
    })
    return response.data
  }

  // Xtream Codes API endpoints
  async getXtreamSources(): Promise<XtreamSource[]> {
    const response = await this.client.get<{ sources: XtreamSource[] }>('/livetv/xtream/sources')
    return response.data.sources || []
  }

  async createXtreamSource(data: {
    name: string
    serverUrl: string
    username: string
    password: string
    enabled?: boolean
    importLive?: boolean
    importVod?: boolean
    importSeries?: boolean
    vodLibraryId?: number
    seriesLibraryId?: number
  }): Promise<XtreamSource> {
    const response = await this.client.post<XtreamSource>('/livetv/xtream/sources', data)
    return response.data
  }

  async updateXtreamSource(id: number, data: Partial<{
    name: string
    serverUrl: string
    username: string
    password: string
    enabled: boolean
    importLive: boolean
    importVod: boolean
    importSeries: boolean
    vodLibraryId: number
    seriesLibraryId: number
  }>): Promise<XtreamSource> {
    const response = await this.client.put<XtreamSource>(`/livetv/xtream/sources/${id}`, data)
    return response.data
  }

  async deleteXtreamSource(id: number): Promise<void> {
    await this.client.delete(`/livetv/xtream/sources/${id}`)
  }

  async testXtreamSource(id: number): Promise<XtreamTestResult> {
    const response = await this.client.post<XtreamTestResult>(`/livetv/xtream/sources/${id}/test`)
    return response.data
  }

  async refreshXtreamSource(id: number): Promise<{ added: number; updated: number; total: number }> {
    const response = await this.client.post<{ added: number; updated: number; total: number }>(
      `/livetv/xtream/sources/${id}/refresh`
    )
    return response.data
  }

  async parseXtreamFromM3U(url: string): Promise<XtreamParseResult> {
    const response = await this.client.post<XtreamParseResult>('/livetv/xtream/parse-m3u', { url })
    return response.data
  }

  async importXtreamVOD(id: number): Promise<XtreamImportResult> {
    const response = await this.client.post<XtreamImportResult>(`/livetv/xtream/sources/${id}/import-vod`)
    return response.data
  }

  async importXtreamSeries(id: number): Promise<XtreamImportResult> {
    const response = await this.client.post<XtreamImportResult>(`/livetv/xtream/sources/${id}/import-series`)
    return response.data
  }

  async importAllXtreamContent(id: number): Promise<{ vod?: XtreamImportResult; series?: XtreamImportResult }> {
    const response = await this.client.post<{ vod?: XtreamImportResult; series?: XtreamImportResult }>(
      `/livetv/xtream/sources/${id}/import-all`
    )
    return response.data
  }

  // DVR endpoints
  async getRecordings(): Promise<Recording[]> {
    const response = await this.client.get<{ recordings: Recording[] }>('/dvr/recordings')
    return response.data.recordings || []
  }

  async deleteRecording(id: number): Promise<void> {
    await this.client.delete(`/dvr/recordings/${id}`)
  }

  async getSeriesRules(): Promise<SeriesRule[]> {
    const response = await this.client.get<{ rules: SeriesRule[] }>('/dvr/rules')
    return response.data.rules || []
  }

  async createSeriesRule(data: Partial<SeriesRule>): Promise<SeriesRule> {
    const response = await this.client.post<SeriesRule>('/dvr/rules', data)
    return response.data
  }

  async updateSeriesRule(id: number, data: Partial<SeriesRule>): Promise<SeriesRule> {
    const response = await this.client.put<SeriesRule>(`/dvr/rules/${id}`, data)
    return response.data
  }

  async deleteSeriesRule(id: number): Promise<void> {
    await this.client.delete(`/dvr/rules/${id}`)
  }

  // DVR conflict endpoints
  async getRecordingConflicts(): Promise<ConflictResponse> {
    const response = await this.client.get<ConflictResponse>('/dvr/conflicts')
    return response.data
  }

  async resolveConflict(keepId: number, cancelId: number): Promise<void> {
    await this.client.post('/dvr/conflicts/resolve', {
      keepRecordingId: keepId,
      cancelRecordingId: cancelId,
    })
  }

  async getRecordingStats(): Promise<RecordingStatsResponse> {
    const response = await this.client.get<RecordingStatsResponse>('/dvr/recordings/stats')
    return response.data
  }

  async getRecordingCommercials(recordingId: number): Promise<CommercialsResponse> {
    const response = await this.client.get<CommercialsResponse>(`/dvr/recordings/${recordingId}/commercials`)
    return response.data
  }

  async getCommercialDetectionStatus(): Promise<{ enabled: boolean }> {
    const response = await this.client.get<{ enabled: boolean }>('/dvr/commercials/status')
    return response.data
  }

  async runCommercialDetection(recordingId: number): Promise<void> {
    await this.client.post(`/dvr/recordings/${recordingId}/commercials/detect`)
  }

  // EDL Export - triggers download of EDL file for recording commercial segments
  getRecordingEDLUrl(recordingId: number, format: 'standard' | 'mplayer' = 'standard'): string {
    const token = localStorage.getItem('openflix_token') || ''
    const base = this.client.defaults.baseURL || ''
    return `${base}/dvr/recordings/${recordingId}/export.edl?format=${format}&X-Plex-Token=${token}`
  }

  // EDL Export for DVR v2 files
  getFileEDLUrl(fileId: number, format: 'standard' | 'mplayer' = 'standard', types: string = 'commercial'): string {
    const token = localStorage.getItem('openflix_token') || ''
    const base = this.client.defaults.baseURL || ''
    return `${base}/dvr/v2/files/${fileId}/export.edl?format=${format}&types=${types}&X-Plex-Token=${token}`
  }

  async getRecordingStreamUrl(recordingId: number): Promise<string> {
    const response = await this.client.get<{ url: string }>(`/dvr/recordings/${recordingId}/stream`)
    return response.data.url
  }

  async updateRecordingProgress(recordingId: number, viewOffset: number): Promise<void> {
    await this.client.put(`/dvr/recordings/${recordingId}/progress`, { viewOffset })
  }

  // Recordings Manager endpoints
  async getRecordingsManager(params?: {
    contentType?: string
    sortBy?: string
    sortDir?: string
    search?: string
    watched?: string
    favorite?: string
    contentRating?: string
    showTitle?: string
    status?: string
  }): Promise<RecordingsManagerResponse> {
    const response = await this.client.get<RecordingsManagerResponse>('/dvr/recordings/manager', { params })
    return response.data
  }

  async toggleRecordingWatched(id: number, watched?: boolean): Promise<{ id: number; isWatched: boolean }> {
    const response = await this.client.put<{ id: number; isWatched: boolean }>(
      `/dvr/recordings/${id}/watched`,
      watched !== undefined ? { watched } : {}
    )
    return response.data
  }

  async toggleRecordingFavorite(id: number, favorite?: boolean): Promise<{ id: number; isFavorite: boolean }> {
    const response = await this.client.put<{ id: number; isFavorite: boolean }>(
      `/dvr/recordings/${id}/favorite`,
      favorite !== undefined ? { favorite } : {}
    )
    return response.data
  }

  async toggleRecordingKeep(id: number, keepForever?: boolean): Promise<{ id: number; keepForever: boolean }> {
    const response = await this.client.put<{ id: number; keepForever: boolean }>(
      `/dvr/recordings/${id}/keep`,
      keepForever !== undefined ? { keepForever } : {}
    )
    return response.data
  }

  async trashRecording(id: number): Promise<void> {
    await this.client.delete(`/dvr/recordings/${id}/trash`)
  }

  async bulkRecordingAction(ids: number[], action: string): Promise<{ action: string; affected: number }> {
    const response = await this.client.post<{ action: string; affected: number }>(
      '/dvr/recordings/bulk',
      { ids, action }
    )
    return response.data
  }

  // DVR Management (Passes, Schedule, Calendar)
  async getDVRPasses(): Promise<DVRPass[]> {
    const response = await this.client.get<{ passes: DVRPass[] }>('/dvr/passes')
    return response.data.passes || []
  }

  async pauseDVRPass(id: number, type: string): Promise<void> {
    await this.client.put(`/dvr/passes/${id}/pause`, null, { params: { type } })
  }

  async resumeDVRPass(id: number, type: string): Promise<void> {
    await this.client.put(`/dvr/passes/${id}/resume`, null, { params: { type } })
  }

  async getDVRSchedule(): Promise<DVRScheduleResponse> {
    const response = await this.client.get<DVRScheduleResponse>('/dvr/schedule')
    return response.data
  }

  async getDVRCalendar(date?: string): Promise<DVRCalendarResponse> {
    const response = await this.client.get<DVRCalendarResponse>('/dvr/calendar', {
      params: date ? { date } : undefined,
    })
    return response.data
  }

  // DVR Settings
  async getDVRSettings(): Promise<DVRSettings> {
    const response = await this.client.get<{ settings: DVRSettings }>('/dvr/settings')
    return response.data.settings
  }

  async updateDVRSettings(data: Partial<DVRSettings>): Promise<DVRSettings> {
    const response = await this.client.put<{ settings: DVRSettings }>('/dvr/settings', data)
    return response.data.settings
  }

  // Server admin endpoints
  async getServerStatus(): Promise<ServerStatus> {
    const response = await this.client.get<ServerStatus>('/api/status')
    return response.data
  }

  async getDashboardData(): Promise<DashboardData> {
    const response = await this.client.get<DashboardData>('/api/dashboard')
    return response.data
  }

  // Diagnostics & System Status
  async runHealthChecks(): Promise<HealthCheckResponse> {
    const response = await this.client.get<HealthCheckResponse>('/api/diagnostics/health-check')
    return response.data
  }

  async getSystemStatus(): Promise<SystemStatusResponse> {
    const response = await this.client.get<SystemStatusResponse>('/api/system/status')
    return response.data
  }

  async getServerConfig(): Promise<ServerSettings> {
    const response = await this.client.get<{ settings: ServerSettings }>('/admin/settings')
    return response.data.settings
  }

  async updateServerConfig(data: Partial<ServerSettings>): Promise<ServerSettings> {
    const response = await this.client.put<{ settings: ServerSettings }>('/admin/settings', data)
    return response.data.settings
  }

  // Guide data management
  async refreshGuideData(): Promise<{ message: string; status: string }> {
    const response = await this.client.post<{ message: string; status: string }>('/api/guide/refresh')
    return response.data
  }

  async rebuildGuideData(): Promise<{ message: string; status: string }> {
    const response = await this.client.post<{ message: string; status: string }>('/api/guide/rebuild')
    return response.data
  }

  // Global client settings overrides
  async getGlobalClientSettings(): Promise<Record<string, string>> {
    const response = await this.client.get<{ overrides: Record<string, string> }>('/api/client-settings')
    return response.data.overrides || {}
  }

  async updateGlobalClientSetting(key: string, value: string): Promise<void> {
    await this.client.put('/api/client-settings', { key, value })
  }

  async deleteGlobalClientSetting(key: string): Promise<void> {
    await this.client.delete(`/api/client-settings/${key}`)
  }

  // Media management endpoints
  async getAdminMedia(params: {
    search?: string
    type?: string
    libraryId?: number
    page?: number
    resolution?: string
    unmatched?: boolean
  }): Promise<MediaListResponse> {
    const response = await this.client.get<MediaListResponse>('/admin/media', { params })
    return response.data
  }

  async refreshMediaMetadata(id: number): Promise<void> {
    await this.client.post(`/admin/media/${id}/refresh`)
  }

  async updateMediaMetadata(id: number, data: Partial<AdminMediaItem>): Promise<AdminMediaItem> {
    const response = await this.client.put<AdminMediaItem>(`/admin/media/${id}`, data)
    return response.data
  }

  async searchTMDB(query: string, mediaType: string): Promise<TMDBSearchResult[]> {
    const response = await this.client.get<{ results: TMDBSearchResult[] }>('/admin/media/search-tmdb', {
      params: { query, media_type: mediaType }
    })
    return response.data.results || []
  }

  async applyMediaMatch(id: number, tmdbId: number, mediaType: string): Promise<void> {
    await this.client.post(`/admin/media/${id}/match`, { tmdb_id: tmdbId, media_type: mediaType })
  }

  async applyRecordingMatch(id: number, tmdbId: number, mediaType: string, title?: string, poster?: string, backdrop?: string): Promise<void> {
    await this.client.post(`/dvr/recordings/${id}/match`, {
      tmdb_id: tmdbId,
      media_type: mediaType,
      title: title || '',
      poster: poster || '',
      backdrop: backdrop || '',
    })
  }

  // VOD endpoints
  vod = {
    testConnection: async (url?: string): Promise<VODConnectionStatus> => {
      const params = url ? { url } : {}
      const response = await this.client.get<VODConnectionStatus>('/api/vod/test-connection', { params })
      return response.data
    },

    getProviders: async (): Promise<VODProvider[]> => {
      const response = await this.client.get<VODProvider[]>('/api/vod/providers')
      return response.data
    },

    getMovies: async (provider: string): Promise<VODMovie[]> => {
      const response = await this.client.get<VODMovie[]>(`/api/vod/${provider}/movies`)
      return response.data
    },

    getShows: async (provider: string): Promise<VODShow[]> => {
      const response = await this.client.get<VODShow[]>(`/api/vod/${provider}/shows`)
      return response.data
    },

    getGenres: async (provider: string): Promise<string[]> => {
      const response = await this.client.get<string[]>(`/api/vod/${provider}/genres`)
      return response.data
    },

    getMovie: async (provider: string, id: string): Promise<VODMovie> => {
      const response = await this.client.get<VODMovie>(`/api/vod/${provider}/movie/${id}`)
      return response.data
    },

    getShow: async (provider: string, id: string): Promise<VODShowDetails> => {
      const response = await this.client.get<VODShowDetails>(`/api/vod/${provider}/show/${id}`)
      return response.data
    },

    startDownload: async (provider: string, contentId: string, type: 'movie' | 'episode'): Promise<void> => {
      await this.client.post(`/api/vod/${provider}/download`, { contentId, type })
    },

    getQueue: async (): Promise<VODDownloadQueue> => {
      const response = await this.client.get<VODDownloadQueue>('/api/vod/queue')
      return response.data
    },

    cancelDownload: async (id: string): Promise<void> => {
      await this.client.delete(`/api/vod/queue/${id}`)
    },
  }

  // ============ Admin Playlists API ============

  async getAdminPlaylists(): Promise<AdminPlaylist[]> {
    const response = await this.client.get<{ playlists: AdminPlaylist[] }>('/api/playlists')
    return response.data.playlists || []
  }

  async createAdminPlaylist(data: { name: string; description: string }): Promise<AdminPlaylist> {
    const response = await this.client.post<AdminPlaylist>('/api/playlists', data)
    return response.data
  }

  async getAdminPlaylist(id: number): Promise<AdminPlaylistDetail> {
    const response = await this.client.get<AdminPlaylistDetail>(`/api/playlists/${id}`)
    return response.data
  }

  async updateAdminPlaylist(id: number, data: { name?: string; description?: string }): Promise<AdminPlaylist> {
    const response = await this.client.put<AdminPlaylist>(`/api/playlists/${id}`, data)
    return response.data
  }

  async deleteAdminPlaylist(id: number): Promise<void> {
    await this.client.delete(`/api/playlists/${id}`)
  }

  async addItemsToAdminPlaylist(id: number, mediaIds: number[]): Promise<{ added: number }> {
    const response = await this.client.post<{ added: number }>(`/api/playlists/${id}/items`, { mediaIds })
    return response.data
  }

  async removeItemFromAdminPlaylist(playlistId: number, itemId: number): Promise<void> {
    await this.client.delete(`/api/playlists/${playlistId}/items/${itemId}`)
  }

  async reorderAdminPlaylistItems(playlistId: number, itemIds: number[]): Promise<void> {
    await this.client.put(`/api/playlists/${playlistId}/items/reorder`, { itemIds })
  }

  // ============ Personal Sections API ============

  async getPersonalSections(): Promise<PersonalSection[]> {
    const response = await this.client.get<{ sections: PersonalSection[] }>('/api/sections')
    return response.data.sections || []
  }

  async createPersonalSection(data: {
    name: string
    description: string
    sectionType: string
    smartFilter?: string
  }): Promise<PersonalSection> {
    const response = await this.client.post<PersonalSection>('/api/sections', data)
    return response.data
  }

  async getPersonalSection(id: number): Promise<PersonalSectionDetail> {
    const response = await this.client.get<PersonalSectionDetail>(`/api/sections/${id}`)
    return response.data
  }

  async updatePersonalSection(id: number, data: {
    name?: string
    description?: string
    smartFilter?: string
  }): Promise<PersonalSection> {
    const response = await this.client.put<PersonalSection>(`/api/sections/${id}`, data)
    return response.data
  }

  async deletePersonalSection(id: number): Promise<void> {
    await this.client.delete(`/api/sections/${id}`)
  }

  async addItemsToPersonalSection(sectionId: number, mediaIds: number[]): Promise<{ added: number }> {
    const response = await this.client.post<{ added: number }>(`/api/sections/${sectionId}/items`, { mediaIds })
    return response.data
  }

  async removeItemFromPersonalSection(sectionId: number, itemId: number): Promise<void> {
    await this.client.delete(`/api/sections/${sectionId}/items/${itemId}`)
  }

  async reorderPersonalSectionItems(sectionId: number, itemIds: number[]): Promise<void> {
    await this.client.put(`/api/sections/${sectionId}/reorder`, { itemIds })
  }

  async previewSmartFilter(smartFilter: string, limit?: number): Promise<SmartFilterPreview> {
    const response = await this.client.post<SmartFilterPreview>('/api/sections/preview', {
      smartFilter,
      limit: limit || 50,
    })
    return response.data
  }

  async getAvailableGenres(): Promise<string[]> {
    const response = await this.client.get<{ genres: string[] }>('/api/sections/genres')
    return response.data.genres || []
  }
}

// Admin Playlist types
export interface AdminPlaylist {
  ID: number
  guid: string
  userId: number
  title: string
  summary: string
  playlistType: string
  smart: boolean
  leafCount: number
  duration: number
  addedAt: string
  updatedAt: string
}

export interface AdminPlaylistItem {
  id: number
  playlistId: number
  mediaId: number
  position: number
  title: string
  type: string
  year?: number
  thumb?: string
  duration?: number
  summary?: string
}

export interface AdminPlaylistDetail {
  playlist: AdminPlaylist
  items: AdminPlaylistItem[]
}

// Personal Section types
export interface PersonalSection {
  id: number
  userId: number
  name: string
  description: string
  sectionType: string
  smartFilter: string
  position: number
  itemCount: number
  createdAt: string
  updatedAt: string
}

export interface PersonalSectionItem {
  id: number
  mediaId: number
  position: number
  title: string
  type: string
  year?: number
  thumb?: string
  duration?: number
  summary?: string
}

export interface PersonalSectionDetail {
  section: PersonalSection
  items: PersonalSectionItem[]
}

export interface SmartFilterPreview {
  items: Array<{
    id: number
    title: string
    type: string
    year?: number
    thumb?: string
    duration?: number
  }>
  total: number
}

// Server settings (from /admin/settings endpoint)
export interface ServerSettings {
  // Metadata
  tmdb_api_key?: string
  tvdb_api_key?: string
  metadata_lang?: string
  scan_interval?: number
  vod_api_url?: string

  // Server
  server_name?: string
  server_port?: number
  log_level?: string
  data_dir?: string

  // Transcoding
  hardware_accel?: string
  max_transcode_sessions?: number
  transcode_temp_dir?: string
  default_video_codec?: string
  default_audio_codec?: string

  // Live TV
  livetv_max_streams?: number
  timeshift_buffer_hrs?: number
  epg_refresh_interval?: number
  channel_switch_buffer?: number
  tuner_sharing?: boolean

  // DVR (extended)
  recording_dir?: string
  pre_padding?: number
  post_padding?: number
  commercial_detect?: boolean
  auto_delete_days?: number
  max_record_quality?: string

  // Live TV & DVR (dedicated settings page)
  recording_pre_padding?: number
  recording_post_padding?: number
  recording_quality?: string
  keep_rule?: string
  auto_delete_watched?: boolean
  commercial_detection_enabled?: boolean
  commercial_detection_mode?: string
  auto_skip_commercials?: boolean
  guide_refresh_interval?: number
  guide_data_source?: string
  deinterlacing_mode?: string
  livetv_buffer_size?: string

  // Remote Access
  remote_access_enabled?: boolean
  tailscale_status?: string
  external_url?: string

  // Playback Defaults
  default_playback_speed?: string
  frame_rate_match_mode?: string
  default_subtitle_language?: string
  default_audio_language?: string

  // Advanced: Transcoder
  transcoder_type?: string
  deinterlacer_mode?: string
  livetv_buffer_secs?: number

  // Advanced: Web Player
  playback_quality?: string
  client_buffer_secs?: number

  // Advanced: Integrations
  edl_export?: boolean
  m3u_channel_ids?: boolean
  vlc_links?: boolean
  http_logging?: boolean

  // Advanced: Experimental
  experimental_hdr?: boolean
  experimental_low_latency?: boolean
  experimental_ai_metadata?: boolean
}

// Provider discovery types
export interface Provider {
  headendId: string
  name: string
  type: string  // "Cable", "Satellite", "Antenna"
  location: string
  lineupId?: string
}

export interface ProviderGroup {
  type: string
  providers: Provider[]
}

export interface ProviderDiscoveryResponse {
  postalCode: string
  providers: Provider[]
  grouped: ProviderGroup[]
  total: number
}

// Media management types
export interface AdminMediaItem {
  id: number
  uuid: string
  type: string
  title: string
  sort_title: string
  original_title?: string
  year?: number
  thumb?: string
  art?: string
  summary?: string
  rating?: number
  content_rating?: string
  studio?: string
  duration?: number
  added_at: string
  updated_at: string
  library_id: number
  library_name?: string
  tmdb_id?: string
  child_count?: number
}

export interface MediaListResponse {
  items: AdminMediaItem[]
  total: number
  page: number
  page_size: number
}

export interface TMDBSearchResult {
  id: number
  title: string
  original_title?: string
  release_date?: string
  first_air_date?: string
  overview?: string
  poster_path?: string
  backdrop_path?: string
  vote_average?: number
  media_type: string
}

// Xtream API types
export interface XtreamTestResult {
  success: boolean
  error?: string
  userInfo?: {
    username: string
    status: string
    expDate: string
    maxConnections: string
    activeConns: string
  }
  serverInfo?: {
    url: string
    port: string
    timezone: string
  }
}

export interface XtreamParseResult {
  success: boolean
  error?: string
  serverUrl?: string
  username?: string
  password?: string
  name?: string
  userInfo?: {
    status: string
    expDate: string
    maxConnections: string
  }
}

export interface XtreamImportResult {
  added: number
  updated: number
  skipped: number
  errors: number
  total: number
  duration: string
}

// VOD types
export interface VODConnectionStatus {
  connected: boolean
  error?: string
  providerCount?: number
  providers?: VODProvider[]
}

export interface VODProvider {
  id: string
  name: string
  description?: string
  logo?: string
}

export interface VODMovie {
  id: string
  title: string
  description?: string
  year?: number
  runtime?: number
  rating?: string
  genres?: string[]
  poster?: string
  downloadUrl?: string
}

export interface VODShow {
  id: string
  title: string
  description?: string
  year?: number
  rating?: string
  genres?: string[]
  poster?: string
  seasonCount?: number
}

export interface VODEpisode {
  id: string
  episodeNumber: number
  title: string
  description?: string
  runtime?: number
  downloadUrl?: string
}

export interface VODSeason {
  seasonNumber: number
  episodes?: VODEpisode[]
}

export interface VODShowDetails extends VODShow {
  seasons?: VODSeason[]
}

export interface VODDownloadItem {
  id: string
  contentId: string
  title: string
  provider: string
  status: string
  progress: number
  filePath?: string
  error?: string
}

export interface VODDownloadQueue {
  items: VODDownloadItem[]
}

// DVR Settings
export interface DVRSettings {
  maxConcurrentRecordings: number  // 0 = unlimited
}

// DVR Management types
export interface DVRPass {
  id: number
  type: 'series' | 'team'
  name: string
  thumb?: string
  enabled: boolean
  keepCount: number
  priority: number
  prePadding: number
  postPadding: number
  jobCount: number
  createdAt: string
  updatedAt: string
  // Series-specific
  keywords?: string
  channelId?: number
  timeSlot?: string
  daysOfWeek?: string
  // Team-specific
  teamName?: string
  league?: string
}

export interface DVRScheduleItem {
  id: number
  title: string
  subtitle?: string
  channelName?: string
  channelLogo?: string
  startTime: string
  endTime: string
  status: 'scheduled' | 'recording' | 'conflict'
  priority: number
  category?: string
  episodeNum?: string
  thumb?: string
  art?: string
  isMovie: boolean
  day: string
}

export interface DVRScheduleResponse {
  schedule: DVRScheduleItem[]
  totalCount: number
}

export interface DVRCalendarItem {
  id: number
  title: string
  channelName?: string
  startTime: string
  endTime: string
  status: 'scheduled' | 'recording' | 'completed'
  day: string
}

export interface DVRCalendarResponse {
  items: DVRCalendarItem[]
  weekStart: string
  weekEnd: string
}

// Configuration Export/Import
export interface ConfigStats {
  settings: number
  m3uSources: number
  xtreamSources: number
  epgSources: number
  channels: number
  channelGroups: number
  seriesRules: number
  teamPasses: number
  recordings: number
  libraries: number
  users: number
  watchHistory: number
  playQueues: number
  playlists: number
  collections: number
}

export interface ImportResult {
  success?: boolean
  preview?: boolean
  counts?: ConfigStats
  imported?: Record<string, number>
  errors?: string[]
  version?: string
  exportedAt?: string
}

// On Now types
export interface OnNowProgram {
  id: number
  channelId: string
  title: string
  description?: string
  start: string
  end: string
  icon?: string
  category?: string
  episodeNum?: string
  isNew?: boolean
  isPremiere?: boolean
  isLive?: boolean
  isFinale?: boolean
  isMovie?: boolean
  isSports?: boolean
  isKids?: boolean
  isNews?: boolean
}

export interface OnNowChannel {
  id: number
  sourceId: number
  channelId: string
  number: number
  name: string
  logo?: string
  group?: string
  streamUrl: string
  enabled: boolean
  isFavorite: boolean
  hasEpgData: boolean
  nowPlaying?: OnNowProgram
  nextProgram?: OnNowProgram
}

// Dashboard types
export interface DashboardUpNextItem {
  id: number
  title: string
  type: string
  thumb: string
  art: string
  year?: number
  duration?: number
  viewOffset: number
  grandparentTitle?: string
  parentIndex?: number
  index?: number
  grandparentThumb?: string
  parentThumb?: string
  summary?: string
}

export interface DashboardRecentShow {
  id: number
  title: string
  thumb: string
  art: string
  year?: number
  childCount?: number
  leafCount?: number
  updatedAt: string
  summary?: string
}

export interface DashboardRecentMovie {
  id: number
  title: string
  thumb: string
  art: string
  year?: number
  summary?: string
  rating?: number
  studio?: string
}

export interface DashboardRecentRecording {
  id: number
  title: string
  thumb: string
  art: string
  channelName?: string
  duration?: number
  year?: number
  isMovie?: boolean
}

export interface DashboardData {
  upNext: DashboardUpNextItem[]
  recentShows: DashboardRecentShow[]
  recentMovies: DashboardRecentMovie[]
  recentRecordings: DashboardRecentRecording[]
}

// Recordings Manager types
export interface RecordingsManagerResponse {
  recordings: Recording[]
  totalCount: number
  showTitles: string[]
  contentRatings: string[]
}

// Health Check types
export interface HealthCheckResult {
  name: string
  status: 'ok' | 'warning' | 'error'
  message: string
  details?: string
}

export interface HealthCheckResponse {
  timestamp: string
  duration: string
  summary: string
  checks: HealthCheckResult[]
}

// System Status types
export interface SystemStatusServer {
  version: string
  uptime: string
  uptimeSec: number
  startedAt: string
  os: string
  arch: string
  goVersion: string
  hostname: string
}

export interface DiskUsageInfo {
  path: string
  label: string
  total: number
  used: number
  free: number
  percent: number
}

export interface SystemStatusResources {
  cpuCores: number
  memUsedMB: number
  memTotalMB: number
  memPercent: number
  goroutines: number
  diskUsage: DiskUsageInfo[]
}

export interface SystemStatusDatabase {
  sizeMB: number
  libraries: number
  channels: number
  recordings: number
  passes: number
  users: number
  mediaItems: number
  programs: number
}

export interface SystemStatusComponents {
  ffmpegVersion: string
  chromeVersion: string
  comskipAvailable: boolean
  transcodeHW: string
}

export interface SystemStatusResponse {
  server: SystemStatusServer
  resources: SystemStatusResources
  database: SystemStatusDatabase
  components: SystemStatusComponents
}

export const api = new ApiClient()
