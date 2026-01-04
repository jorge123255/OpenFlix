import axios, { type AxiosError, type AxiosInstance } from 'axios'
import type {
  User,
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
  Recording,
  SeriesRule,
  ServerStatus,
  XtreamSource,
} from '../types'

const TOKEN_KEY = 'openflix_token'

class ApiClient {
  private client: AxiosInstance

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

  async createM3USource(data: { name: string; url: string }): Promise<M3USource> {
    const response = await this.client.post<M3USource>('/livetv/sources', data)
    return response.data
  }

  async updateM3USource(id: number, data: { name?: string; url?: string }): Promise<M3USource> {
    const response = await this.client.put<M3USource>(`/livetv/sources/${id}`, data)
    return response.data
  }

  async deleteM3USource(id: number): Promise<void> {
    await this.client.delete(`/livetv/sources/${id}`)
  }

  async refreshM3USource(id: number): Promise<void> {
    await this.client.post(`/livetv/sources/${id}/refresh`)
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

  async refreshEPG(): Promise<void> {
    await this.client.post('/livetv/epg/refresh')
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

  // Server admin endpoints
  async getServerStatus(): Promise<ServerStatus> {
    const response = await this.client.get<ServerStatus>('/api/status')
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

  // Media management endpoints
  async getAdminMedia(params: {
    search?: string
    type?: string
    libraryId?: number
    page?: number
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
}

// Server settings (from /admin/settings endpoint)
export interface ServerSettings {
  tmdb_api_key?: string
  tvdb_api_key?: string
  metadata_lang?: string
  scan_interval?: number
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

export const api = new ApiClient()
