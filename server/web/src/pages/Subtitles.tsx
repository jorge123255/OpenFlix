import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Captions, Search, Download, Trash2, Save, Globe, Film } from 'lucide-react'
import { api } from '../api/client'

interface SubtitleResult {
  id: string
  fileName: string
  language: string
  languageName: string
  format: string
  downloads: number
  rating: number
  hearingImpaired: boolean
  machineTranslated: boolean
  uploadDate: string
}

interface DownloadedSubtitle {
  id: number
  mediaId: number
  mediaTitle: string
  language: string
  fileName: string
  filePath: string
  source: string
  downloadedAt: string
}

interface SubtitleConfig {
  apiKey: string
  autoSearch: boolean
  preferredLanguages: string[]
}

const LANGUAGES = [
  { code: 'en', name: 'English' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'it', name: 'Italian' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'nl', name: 'Dutch' },
  { code: 'pl', name: 'Polish' },
  { code: 'ru', name: 'Russian' },
  { code: 'ja', name: 'Japanese' },
  { code: 'ko', name: 'Korean' },
  { code: 'zh', name: 'Chinese' },
  { code: 'ar', name: 'Arabic' },
  { code: 'hi', name: 'Hindi' },
  { code: 'sv', name: 'Swedish' },
  { code: 'da', name: 'Danish' },
  { code: 'no', name: 'Norwegian' },
  { code: 'fi', name: 'Finnish' },
  { code: 'tr', name: 'Turkish' },
  { code: 'he', name: 'Hebrew' },
]

export function SubtitlesPage() {
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState<'search' | 'downloaded' | 'config'>('search')
  const [searchQuery, setSearchQuery] = useState('')
  const [searchLang, setSearchLang] = useState('en')
  const [saved, setSaved] = useState(false)

  const [config, setConfig] = useState<SubtitleConfig>({
    apiKey: '',
    autoSearch: false,
    preferredLanguages: ['en'],
  })

  // Load config
  const { data: configData } = useQuery({
    queryKey: ['subtitleConfig'],
    queryFn: async () => {
      const res = await api.client.get('/api/subtitles/config')
      return res.data
    },
  })

  useEffect(() => {
    if (configData?.config) {
      setConfig(prev => ({ ...prev, ...configData.config }))
    }
  }, [configData])

  // Search results
  const searchMutation = useMutation({
    mutationFn: async ({ query, language }: { query: string; language: string }) => {
      const res = await api.client.get('/api/subtitles/search', { params: { query, language } })
      return res.data?.results || []
    },
  })

  // Downloaded subtitles
  const { data: downloaded } = useQuery({
    queryKey: ['downloadedSubtitles'],
    queryFn: async () => {
      const res = await api.client.get('/api/subtitles/downloaded')
      return res.data?.subtitles || []
    },
    enabled: activeTab === 'downloaded',
  })

  // Download subtitle
  const downloadMutation = useMutation({
    mutationFn: async (subtitle: SubtitleResult) => {
      await api.client.post('/api/subtitles/download', {
        fileId: subtitle.id,
        language: subtitle.language,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['downloadedSubtitles'] })
    },
  })

  // Delete subtitle
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await api.client.delete(`/api/subtitles/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['downloadedSubtitles'] })
    },
  })

  // Save config
  const saveConfig = useMutation({
    mutationFn: async (cfg: SubtitleConfig) => {
      await api.client.put('/api/subtitles/config', cfg)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['subtitleConfig'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    },
  })

  const handleSearch = () => {
    if (searchQuery.trim()) {
      searchMutation.mutate({ query: searchQuery, language: searchLang })
    }
  }

  const toggleLanguage = (code: string) => {
    setConfig(prev => ({
      ...prev,
      preferredLanguages: prev.preferredLanguages.includes(code)
        ? prev.preferredLanguages.filter(l => l !== code)
        : [...prev.preferredLanguages, code],
    }))
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Subtitles</h1>
          <p className="text-gray-400 mt-1">Search and manage subtitles via OpenSubtitles</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-gray-800 rounded-lg p-1 w-fit">
        {[
          { id: 'search' as const, label: 'Search', icon: Search },
          { id: 'downloaded' as const, label: 'Downloaded', icon: Download },
          { id: 'config' as const, label: 'Settings', icon: Globe },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === tab.id ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
          >
            <tab.icon className="h-4 w-4" /> {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'search' && (
        <div className="space-y-6">
          {/* Search Bar */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4">Search OpenSubtitles</h2>
            <div className="flex gap-3">
              <input
                type="text"
                placeholder="Movie or TV show title..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleSearch()}
                className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <select
                value={searchLang}
                onChange={e => setSearchLang(e.target.value)}
                className="px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              >
                {LANGUAGES.map(l => (
                  <option key={l.code} value={l.code}>{l.name}</option>
                ))}
              </select>
              <button
                onClick={handleSearch}
                disabled={searchMutation.isPending || !searchQuery.trim()}
                className="flex items-center gap-2 px-6 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg transition-colors"
              >
                <Search className="h-4 w-4" />
                {searchMutation.isPending ? 'Searching...' : 'Search'}
              </button>
            </div>
          </div>

          {/* Results */}
          {searchMutation.data && (
            <div className="bg-gray-800 rounded-xl p-6">
              <h2 className="text-lg font-semibold text-white mb-4">
                Results ({(searchMutation.data as SubtitleResult[]).length})
              </h2>
              {(searchMutation.data as SubtitleResult[]).length === 0 ? (
                <p className="text-gray-500">No subtitles found. Try a different search.</p>
              ) : (
                <div className="space-y-2">
                  {(searchMutation.data as SubtitleResult[]).map(sub => (
                    <div key={sub.id} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg hover:bg-gray-700 transition-colors">
                      <div className="flex items-center gap-3 flex-1 min-w-0">
                        <Captions className="h-5 w-5 text-indigo-400 flex-shrink-0" />
                        <div className="min-w-0">
                          <p className="text-white text-sm font-medium truncate">{sub.fileName}</p>
                          <div className="flex items-center gap-3 text-xs text-gray-400 mt-0.5">
                            <span>{sub.languageName}</span>
                            <span>{sub.format.toUpperCase()}</span>
                            <span>{sub.downloads.toLocaleString()} downloads</span>
                            {sub.hearingImpaired && <span className="text-yellow-400">HI</span>}
                          </div>
                        </div>
                      </div>
                      <button
                        onClick={() => downloadMutation.mutate(sub)}
                        disabled={downloadMutation.isPending}
                        className="flex items-center gap-1 px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors flex-shrink-0"
                      >
                        <Download className="h-3 w-3" /> Download
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {activeTab === 'downloaded' && (
        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Downloaded Subtitles</h2>
          {!downloaded || (downloaded as DownloadedSubtitle[]).length === 0 ? (
            <div className="text-center py-12">
              <Captions className="h-12 w-12 text-gray-600 mx-auto mb-3" />
              <p className="text-gray-500">No subtitles downloaded yet</p>
              <p className="text-gray-600 text-sm mt-1">Use the Search tab to find and download subtitles</p>
            </div>
          ) : (
            <div className="space-y-2">
              {(downloaded as DownloadedSubtitle[]).map(sub => (
                <div key={sub.id} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <Film className="h-5 w-5 text-gray-400 flex-shrink-0" />
                    <div>
                      <p className="text-white text-sm font-medium">{sub.mediaTitle}</p>
                      <div className="flex items-center gap-2 text-xs text-gray-400 mt-0.5">
                        <span>{sub.language}</span>
                        <span>{sub.fileName}</span>
                        <span>{new Date(sub.downloadedAt).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={() => deleteMutation.mutate(sub.id)}
                    className="p-2 text-red-400 hover:text-red-300 transition-colors"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeTab === 'config' && (
        <div className="space-y-6">
          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4">OpenSubtitles API</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">API Key</label>
                <p className="text-xs text-gray-500 mb-2">Get a free API key at opensubtitles.com</p>
                <input
                  type="password"
                  placeholder="Your OpenSubtitles API key"
                  value={config.apiKey}
                  onChange={e => setConfig(prev => ({ ...prev, apiKey: e.target.value }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-white font-medium">Auto-search subtitles</span>
                  <p className="text-sm text-gray-400">Automatically search for subtitles when new media is added</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.autoSearch}
                    onChange={e => setConfig(prev => ({ ...prev, autoSearch: e.target.checked }))}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
                </label>
              </div>
            </div>
          </div>

          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4">Preferred Languages</h2>
            <p className="text-sm text-gray-400 mb-4">Select languages to prioritize when auto-searching</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2">
              {LANGUAGES.map(lang => (
                <label
                  key={lang.code}
                  className={`flex items-center gap-2 p-2.5 rounded-lg cursor-pointer transition-colors ${config.preferredLanguages.includes(lang.code) ? 'bg-indigo-600/20 border border-indigo-500' : 'bg-gray-700/50 border border-transparent hover:bg-gray-700'}`}
                >
                  <input
                    type="checkbox"
                    checked={config.preferredLanguages.includes(lang.code)}
                    onChange={() => toggleLanguage(lang.code)}
                    className="sr-only"
                  />
                  <span className={`text-sm ${config.preferredLanguages.includes(lang.code) ? 'text-indigo-300 font-medium' : 'text-gray-300'}`}>
                    {lang.name}
                  </span>
                </label>
              ))}
            </div>
          </div>

          <div className="flex justify-end">
            <button
              onClick={() => saveConfig.mutate(config)}
              className="flex items-center gap-2 px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
            >
              <Save className="h-4 w-4" />
              {saveConfig.isPending ? 'Saving...' : saved ? 'Saved!' : 'Save Settings'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
